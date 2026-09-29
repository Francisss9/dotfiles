#!/usr/bin/env bash

set -uo pipefail

echo "Cleaning up..."

echo "→ Removing orphaned AUR/yay cache..."
yay -Yc --noconfirm || true

echo "→ Cleaning pacman package cache..."
sudo pacman -Sc --noconfirm || true

echo "→ Rebuilding font cache..."
fc-cache -fv

echo
echo "✓ Cleanup complete."
