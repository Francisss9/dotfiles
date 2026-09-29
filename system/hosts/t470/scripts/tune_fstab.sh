#!/usr/bin/env bash

set -euo pipefail

# Applies T470-specific fstab tuning without hardcoding UUIDs.
#
# Why: /etc/fstab lines are keyed by UUID, which is different on every
# fresh install/disk. Instead of shipping a static fstab (which would
# need manual UUID surgery each reinstall), this script edits whatever
# fstab already exists, matching lines by MOUNTPOINT and adding the
# missing options in place. Idempotent — safe to run every install.

FSTAB="/etc/fstab"
BACKUP="/etc/fstab.pre-t470-tuning.bak"

echo "Tuning /etc/fstab for T470 (SSD SATA)..."

[[ -f "$FSTAB" ]] || { echo "  ERROR: $FSTAB not found, skipping."; exit 1; }

# One-time backup, only if we haven't already made one
if [[ ! -f "$BACKUP" ]]; then
    sudo cp "$FSTAB" "$BACKUP"
    echo "  Backup saved to $BACKUP"
fi

add_option_to_mountpoint() {
    local mountpoint="$1" option="$2"
    # Match the fstab line whose 2nd field (mountpoint) is exactly $mountpoint,
    # is not a comment, and doesn't already have $option in its options field.
    local awk_prog
    awk_prog=$(cat <<AWK
\$1 !~ /^#/ && \$2 == "$mountpoint" && \$4 !~ /(^|,)$option(,|\$)/ {
    \$4 = \$4 ",$option"
}
{ print }
AWK
)
    if sudo awk -v OFS='\t' "$awk_prog" "$FSTAB" | sudo tee "${FSTAB}.tmp" > /dev/null; then
        if ! cmp -s "$FSTAB" "${FSTAB}.tmp"; then
            sudo mv "${FSTAB}.tmp" "$FSTAB"
            echo "  → Added '$option' to $mountpoint"
        else
            sudo rm -f "${FSTAB}.tmp"
            echo "  ✓ $mountpoint already has '$option'"
        fi
    fi
}

add_option_to_mountpoint "/" "lazytime"
add_option_to_mountpoint "/home" "lazytime"
add_option_to_mountpoint "/var/cache/pacman/pkg" "lazytime"
add_option_to_mountpoint "/var/log" "lazytime"

# tmpfs for /tmp — append only if no /tmp entry exists yet
if ! awk '$1 !~ /^#/ && $2 == "/tmp"' "$FSTAB" | grep -q .; then
    echo -e "tmpfs\t/tmp\ttmpfs\tdefaults,noatime,mode=1777,size=4G\t0\t0" | sudo tee -a "$FSTAB" > /dev/null
    echo "  → Added tmpfs entry for /tmp"
else
    echo "  ✓ /tmp entry already present, leaving as-is"
fi

echo
echo "  Remounting affected filesystems..."
sudo mount -o remount / 2>/dev/null || true
sudo mount -o remount /home 2>/dev/null || true
sudo mount /tmp 2>/dev/null || true

echo "✓ fstab tuning applied."
