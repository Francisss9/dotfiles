#!/usr/bin/env bash

set -euo pipefail

DOTFILES="$HOME/.dotfiles"

mkdir -p "$DOTFILES/packages"

echo "Exporting official packages..."
pacman -Qqen > "$DOTFILES/packages/official.txt"

echo "Exporting AUR packages..."
pacman -Qqem > "$DOTFILES/packages/aur.txt"

echo
echo "✓ Package lists updated."
