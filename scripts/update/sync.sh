#!/usr/bin/env bash
#
# sync.sh — commit local dotfiles changes, then pull --rebase and push.
#
# Fully unattended: it never prompts and never waits for the keyboard.
# Fail-closed: if anything looks unsafe it stops, unstages, writes to the
# log and (when available) sends a desktop notification. Nothing is pushed.
#
# Usage: sync.sh [--dry-run]     (--dry-run runs every check, commits nothing)

set -euo pipefail

DOTFILES="${DOTFILES:-$HOME/.dotfiles}"
SYSTEM_DIR="$DOTFILES/system"
HOSTS_MAP="$SYSTEM_DIR/hosts.map"
LOG_FILE="${XDG_STATE_HOME:-$HOME/.local/state}/dotfiles-sync.log"

DRY_RUN=0
if [[ "${1:-}" == "--dry-run" ]]; then
    DRY_RUN=1
fi

# ---------------------------------------------------------------------
# Guard settings — edit these if you legitimately outgrow them
# ---------------------------------------------------------------------
# Only these paths may ever be staged. Anything else blocks the sync.
ALLOWED_PATHS='^(config/|home/|system/|packages/|scripts/|README\.md$|install\.sh$|bootstrap\.sh$|update\.sh$|\.gitignore$)'
MAX_FILE_KB=512      # a single staged file above this blocks the sync
MAX_NEW_FILES=15     # more brand-new files than this in one sync blocks it
# Personal-data patterns checked on ADDED lines only (/home/user is exempt)
PII_REGEX='@(gmail|outlook|hotmail|yahoo|icloud|proton)\.[a-z]+|/home/[A-Za-z0-9._-]+|/Users/[A-Za-z0-9._-]+'

# ---------------------------------------------------------------------
# Never wait for the keyboard: fail instead of prompting
# ---------------------------------------------------------------------
export GIT_TERMINAL_PROMPT=0
export GIT_EDITOR=true
export GIT_SSH_COMMAND="${GIT_SSH_COMMAND:-ssh -o BatchMode=yes}"

REPO_READY=0

log() {
    printf '%s %s\n' "$(date '+%Y-%m-%d %H:%M:%S')" "$*" >> "$LOG_FILE"
}

die() {
    echo "✗ BLOCKED: $*" >&2
    log "BLOCKED: $*"
    if command -v notify-send >/dev/null 2>&1; then
        notify-send -u critical "Dotfiles sync blocked" "$*" || true
    fi
    exit 1
}

# On ANY non-zero exit, leave nothing staged (working files are untouched)
cleanup() {
    local rc=$?
    if (( rc != 0 )) && (( REPO_READY == 1 )); then
        git reset -q 2>/dev/null || true
        log "FAILED (exit $rc)"
    fi
}
trap cleanup EXIT

mkdir -p "$(dirname "$LOG_FILE")"
cd "$DOTFILES"
REPO_READY=1

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo " Dotfiles Sync"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

# ---------------------------------------------------------------------
# Detect this machine's host id via DMI, using hosts.map
# (same logic as scripts/install/system_configs.sh — kept in sync)
# ---------------------------------------------------------------------
detect_host_id() {
    local vendor product identity line pattern id

    vendor="$(cat /sys/class/dmi/id/sys_vendor 2>/dev/null || echo "")"
    product="$(cat /sys/class/dmi/id/product_name 2>/dev/null || echo "")"
    identity="$vendor $product"

    [[ -f "$HOSTS_MAP" ]] || return 0

    while IFS= read -r line; do
        [[ "$line" =~ ^[[:space:]]*# ]] && continue
        [[ -z "${line// }" ]] && continue

        pattern="$(echo "$line" | cut -d'|' -f1 | xargs)"
        id="$(echo "$line" | cut -d'|' -f2 | xargs)"

        [[ -z "$pattern" || -z "$id" ]] && continue

        if echo "$identity" | grep -qiE "$pattern"; then
            echo "$id"
            return 0
        fi
    done < "$HOSTS_MAP"

    return 0
}

# ---------------------------------------------------------------------
# Pull live /etc (and other system) files back into the repo before
# committing, so manual edits made directly on the system don't get
# silently lost. Only files already tracked as layer files are pulled
# back — never new, untracked paths from the live system.
#
# No sudo on purpose: sudo would ask for a password (= keyboard). These
# files are world-readable; anything unreadable is skipped with a warning.
# ---------------------------------------------------------------------
capture_layer() {
    local layer_dir="$1"
    [[ -d "$layer_dir" ]] || return 0

    while IFS= read -r -d '' repo_file; do
        local rel live_file
        rel="${repo_file#"$layer_dir"/}"
        live_file="/$rel"

        if [[ -f "$live_file" ]] && ! cmp -s "$live_file" "$repo_file"; then
            echo "  ← Capturing changes from $live_file"
            cp -- "$live_file" "$repo_file" \
                || echo "  ! Could not read $live_file (permissions?) — skipped"
        fi
    done < <(find "$layer_dir" -type f -print0)
}

# ---------------------------------------------------------------------
# Guards
# ---------------------------------------------------------------------
guard_identity() {
    local email
    email="$(git config user.email || true)"
    [[ "$email" == *@users.noreply.github.com ]] \
        || die "git user.email is '${email:-<unset>}' — expected a GitHub noreply address"
}

guard_staged() {
    local f size mode target new_count bin pii

    # Per-file checks: allowed path, size, absolute symlinks
    while IFS= read -r -d '' f; do
        [[ "$f" =~ $ALLOWED_PATHS ]] \
            || die "unexpected path staged: $f"

        size="$(git cat-file -s ":$f")"
        (( size <= MAX_FILE_KB * 1024 )) \
            || die "file too large ($((size / 1024)) KB > ${MAX_FILE_KB} KB): $f"

        mode="$(git ls-files -s -- "$f" | awk '{print $1; exit}')"
        if [[ "$mode" == "120000" ]]; then
            target="$(git cat-file -p ":$f")"
            [[ "$target" != /* ]] \
                || die "symlink with absolute target staged: $f -> $target"
        fi
    done < <(git diff --cached --name-only -z --diff-filter=ACMR)

    # Too many brand-new files at once (typical of an app dumping files)
    new_count="$(git diff --cached --name-only --diff-filter=A | wc -l)"
    (( new_count <= MAX_NEW_FILES )) \
        || die "$new_count new files staged (limit $MAX_NEW_FILES)"

    # Binary files
    bin="$(git diff --cached --numstat --diff-filter=ACMR \
            | awk -F'\t' '$1=="-" && $2=="-" {print $3; exit}')"
    [[ -z "$bin" ]] || die "binary file staged: $bin"

    # Personal-data patterns on added lines only
    pii="$(git diff --cached -U0 --diff-filter=ACMR \
            | grep -E '^\+' | grep -vE '^\+\+\+ ' \
            | grep -E "$PII_REGEX" | grep -v '/home/user' || true)"
    [[ -z "$pii" ]] \
        || die "personal-data pattern in staged changes: $(head -n1 <<<"$pii" | cut -c1-80)"

    # Secrets
    command -v gitleaks >/dev/null 2>&1 \
        || die "gitleaks not installed (sudo pacman -S gitleaks) — refusing to push unscanned changes"
    gitleaks git --pre-commit --staged --redact --no-banner >> "$LOG_FILE" 2>&1 \
        || die "gitleaks flagged the staged changes (details in $LOG_FILE)"
}

guard_push_range() {
    local range="$1" bad_id

    # Every commit about to be pushed must use a noreply identity
    bad_id="$(git log "$range" --format='%ae%n%ce' \
                | sort -u | grep -v '^$' \
                | grep -v '@users\.noreply\.github\.com$' || true)"
    [[ -z "$bad_id" ]] \
        || die "commits to push use a non-noreply email: $(head -n1 <<<"$bad_id")"

    # And every one of them must pass gitleaks (covers manual commits too)
    gitleaks git --redact --no-banner --log-opts="$range" >> "$LOG_FILE" 2>&1 \
        || die "gitleaks flagged commits about to be pushed (details in $LOG_FILE)"
}

# ---------------------------------------------------------------------
# Main flow
# ---------------------------------------------------------------------
guard_identity

if [[ -d "$SYSTEM_DIR" ]]; then
    echo "→ Checking for live system config changes..."
    HOST_ID="$(detect_host_id)"

    capture_layer "$SYSTEM_DIR/common"
    if [[ -n "$HOST_ID" ]]; then
        capture_layer "$SYSTEM_DIR/hosts/$HOST_ID"
    fi
fi

git add -A

if git diff --cached --quiet; then
    echo "✓ No local changes to commit."
else
    guard_staged

    echo
    echo "→ Changes detected:"
    git diff --cached --stat

    if (( DRY_RUN == 1 )); then
        git reset -q
        echo
        echo "✓ Dry run: all checks passed, nothing committed."
        log "DRY-RUN OK"
        exit 0
    fi

    git commit -q -m "Auto-sync: $(date '+%Y-%m-%d %H:%M:%S')"
    log "Committed local changes"
fi

if (( DRY_RUN == 1 )); then
    echo "✓ Dry run: nothing to check."
    exit 0
fi

UPSTREAM_SHA=""
git rev-parse --abbrev-ref --symbolic-full-name '@{u}' >/dev/null 2>&1 \
    || die "current branch has no upstream (run once: git push -u origin main)"

echo
echo "→ Pulling latest changes..."
if ! git pull --rebase --quiet; then
    git rebase --abort >/dev/null 2>&1 || true
    die "pull --rebase failed (conflict or network). Local commit kept, nothing pushed."
fi

UPSTREAM_SHA="$(git rev-parse '@{u}')"
RANGE="${UPSTREAM_SHA}..HEAD"

if [[ -z "$(git rev-list "$RANGE")" ]]; then
    echo "✓ Nothing to push."
    log "OK: nothing to push"
    exit 0
fi

command -v gitleaks >/dev/null 2>&1 \
    || die "gitleaks not installed (sudo pacman -S gitleaks) — refusing to push unscanned commits"
guard_push_range "$RANGE"

echo "→ Pushing..."
git push --quiet || die "git push failed (network, auth, or rejected)"

log "OK: pushed $(git rev-list --count "$RANGE" 2>/dev/null || echo '?') commit(s)"
echo
echo "✓ Dotfiles successfully synchronized."
