#!/usr/bin/env bash

set -euo pipefail

# Links only the dotfiles configs via Stow, skipping package installation.
# Use this when you already have your packages installed (or don't want
# this machine to install anything) and just want the config files.

DOTFILES="$HOME/.dotfiles"

echo "======================================"
echo " Linking Dotfiles (configs only)"
echo "======================================"

if ! command -v stow >/dev/null 2>&1; then
    echo "✗ GNU Stow is not installed. Install it first:"
    echo "  sudo pacman -S --needed stow"
    exit 1
fi

mkdir -p ~/.config

"$DOTFILES/scripts/install/stow.sh"
"$DOTFILES/scripts/install/system_configs.sh"

echo
echo "✓ Configs linked. No packages were installed."
echo "  Run ./scripts/utils/doctor.sh to verify."
