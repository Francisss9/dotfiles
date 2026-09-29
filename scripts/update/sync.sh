#!/usr/bin/env bash

set -euo pipefail

DOTFILES="$HOME/.dotfiles"
SYSTEM_DIR="$DOTFILES/system"
HOSTS_MAP="$SYSTEM_DIR/hosts.map"

cd "$DOTFILES"

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
# Pull live /etc (and other root-owned) files back into the repo
# before committing, so manual edits made directly on the system
# (e.g. `sudo nvim /etc/tlp.d/01-t470.conf`) don't get silently lost.
#
# Only pulls back files that already exist as tracked layer files —
# never introduces new, untracked paths from the live system.
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
            sudo cp "$live_file" "$repo_file"
            sudo chown "$(id -u):$(id -g)" "$repo_file"
        fi
    done < <(find "$layer_dir" -type f -print0)
}

if [[ -d "$SYSTEM_DIR" ]]; then
    echo "→ Checking for live system config changes..."
    HOST_ID="$(detect_host_id)"

    capture_layer "$SYSTEM_DIR/common"
    [[ -n "$HOST_ID" ]] && capture_layer "$SYSTEM_DIR/hosts/$HOST_ID"
fi

git add -A

if git diff --cached --quiet; then
    echo "✓ No local changes to commit."
else
    echo
    echo "→ Changes detected:"
    git status --short

    MESSAGE="Auto-sync: $(date '+%Y-%m-%d %H:%M:%S')"
    git commit -m "$MESSAGE"
fi

echo
echo "→ Pulling latest changes..."
git pull --rebase

echo "→ Pushing..."
git push

echo
echo "✓ Dotfiles successfully synchronized."
