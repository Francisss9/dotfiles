#!/usr/bin/env bash

set -euo pipefail

# Copies system-level (root-owned) configs from the repo's system/ dir
# into their real locations (/etc, /usr/local, etc). These live outside
# $HOME so GNU Stow can't manage them — this script handles them instead.
#
# Layout:
#   system/common/etc/foo   -> /etc/foo   (applied on every machine)
#   system/hosts/<id>/etc/foo -> /etc/foo (applied only on matching hardware)
#
# Which <id> applies is decided by system/hosts.map, matched against
# this machine's DMI sys_vendor + product_name.

DOTFILES="$HOME/.dotfiles"
SYSTEM_DIR="$DOTFILES/system"
HOSTS_MAP="$SYSTEM_DIR/hosts.map"

echo "Applying system configs..."

if [[ ! -d "$SYSTEM_DIR" ]]; then
    echo "  (no system/ dir found, skipping)"
    exit 0
fi

# ---------------------------------------------------------------------
# Detect this machine's host id via DMI, using hosts.map
# ---------------------------------------------------------------------
detect_host_id() {
    local vendor product identity line pattern id

    vendor="$(cat /sys/class/dmi/id/sys_vendor 2>/dev/null || echo "")"
    product="$(cat /sys/class/dmi/id/product_name 2>/dev/null || echo "")"
    identity="$vendor $product"

    [[ -f "$HOSTS_MAP" ]] || return 0

    while IFS= read -r line; do
        # skip comments / blank lines
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

HOST_ID="$(detect_host_id)"

if [[ -n "$HOST_ID" ]]; then
    echo "  Detected machine: $HOST_ID"
else
    echo "  Detected machine: (no match in hosts.map — only common/ will apply)"
fi

# ---------------------------------------------------------------------
# Apply a system/<layer> tree to /
# ---------------------------------------------------------------------
changed=0

apply_layer() {
    local layer_dir="$1"
    [[ -d "$layer_dir" ]] || return 0

    while IFS= read -r -d '' src; do
        local rel target
        rel="${src#"$layer_dir"/}"
        target="/$rel"

        sudo mkdir -p "$(dirname "$target")"

        if [[ ! -f "$target" ]] || ! cmp -s "$src" "$target"; then
            echo "  → Installing $target"
            sudo cp "$src" "$target"
            changed=1
        else
            echo "  ✓ $target already up to date"
        fi
    done < <(find "$layer_dir" -type f -print0)
}

apply_layer "$SYSTEM_DIR/common"
[[ -n "$HOST_ID" ]] && apply_layer "$SYSTEM_DIR/hosts/$HOST_ID"

if [[ "$changed" -eq 1 ]]; then
    echo
    echo "  Restarting tlp/tlp-pd to apply changes..."
    sudo systemctl restart tlp tlp-pd 2>/dev/null || true
fi

echo "✓ System configs applied."

# ---------------------------------------------------------------------
# Run host-specific scripts (e.g. fstab tuning that can't be a plain
# file copy because it depends on live UUIDs).
# Location: system/hosts/<id>/scripts/*.sh
# ---------------------------------------------------------------------
if [[ -n "$HOST_ID" ]]; then
    SCRIPTS_DIR="$SYSTEM_DIR/hosts/$HOST_ID/scripts"
    if [[ -d "$SCRIPTS_DIR" ]]; then
        echo
        echo "Running host scripts for $HOST_ID..."
        for script in "$SCRIPTS_DIR"/*.sh; do
            [[ -f "$script" ]] || continue
            echo "  → $script"
            bash "$script"
        done
    fi
fi

# Reload zram config if present for this host
if systemctl list-unit-files systemd-zram-setup@.service &>/dev/null && [[ -f /etc/systemd/zram-generator.conf ]]; then
    sudo systemctl daemon-reload
    sudo systemctl restart systemd-zram-setup@zram0.service 2>/dev/null || true
fi
