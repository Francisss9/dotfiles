#!/usr/bin/env bash

set -uo pipefail

DOTFILES="$HOME/.dotfiles"
FAIL=0

echo "Checking system..."
echo

echo "-- Tools --"
for cmd in git yay stow; do
    if command -v "$cmd" >/dev/null 2>&1; then
        echo "✓ $cmd"
    else
        echo "✗ $cmd missing"
        FAIL=1
    fi
done

echo
echo "-- Stow symlinks --"
# Spot-check that key config paths are symlinks pointing into $DOTFILES
CHECK_PATHS=(
    "$HOME/.zshrc"
    "$HOME/.bashrc"
    "$HOME/.config/hypr/hyprland.conf"
    "$HOME/.config/waybar/config.jsonc"
    "$HOME/.config/nvim/init.lua"
    "$HOME/.config/kitty/kitty.conf"
    "$HOME/.config/ghostty/config"
    "$HOME/.config/git/config"
    "$HOME/.config/tmux/tmux.conf"
    "$HOME/.config/btop/btop.conf"
    "$HOME/.config/lazygit/config.yml"
    "$HOME/.config/walker/config.toml"
    "$HOME/.config/doom/init.el"
    "$HOME/.config/fastfetch/config.jsonc"
)

for path in "${CHECK_PATHS[@]}"; do
    if [[ -L "$path" ]]; then
        target="$(readlink -f -- "$path")"
        case "$target" in
            "$DOTFILES"/*)
                echo "✓ $path -> linked"
                ;;
            *)
                echo "✗ $path is a symlink but NOT pointing into $DOTFILES"
                FAIL=1
                ;;
        esac
    elif [[ -e "$path" ]]; then
        echo "✗ $path exists but is a REAL file, not a symlink (stow didn't take)"
        FAIL=1
    else
        echo "✗ $path missing entirely"
        FAIL=1
    fi
done

echo
echo "-- Package lists --"
if [[ -f "$DOTFILES/packages/official.txt" ]]; then
    missing=0
    while IFS= read -r pkg; do
        [[ -z "$pkg" ]] && continue
        pacman -Qi "$pkg" >/dev/null 2>&1 || { echo "✗ official pkg not installed: $pkg"; missing=1; }
    done < "$DOTFILES/packages/official.txt"
    [[ "$missing" -eq 0 ]] && echo "✓ all official packages installed"
    [[ "$missing" -eq 1 ]] && FAIL=1
else
    echo "✗ packages/official.txt not found"
    FAIL=1
fi

if [[ -f "$DOTFILES/packages/aur.txt" ]]; then
    missing=0
    while IFS= read -r pkg; do
        [[ -z "$pkg" ]] && continue
        pacman -Qi "$pkg" >/dev/null 2>&1 || { echo "✗ AUR pkg not installed: $pkg"; missing=1; }
    done < "$DOTFILES/packages/aur.txt"
    [[ "$missing" -eq 0 ]] && echo "✓ all AUR packages installed"
    [[ "$missing" -eq 1 ]] && FAIL=1
else
    echo "✗ packages/aur.txt not found"
    FAIL=1
fi

echo
if [[ "$FAIL" -eq 0 ]]; then
    echo "System looks healthy."
else
    echo "Some checks failed — see ✗ above."
    exit 1
fi
