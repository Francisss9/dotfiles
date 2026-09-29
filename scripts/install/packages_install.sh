#!/usr/bin/env bash

set -euo pipefail

DOTFILES="$HOME/.dotfiles"

echo "Installing official packages..."

sudo pacman -S --needed - < "$DOTFILES/packages/official.txt"

echo

echo "Installing AUR packages..."

yay -S --needed - < "$DOTFILES/packages/aur.txt"

echo

echo "✓ Packages installed."
