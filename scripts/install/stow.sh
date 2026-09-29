#!/usr/bin/env bash

set -euo pipefail

DOTFILES="$HOME/.dotfiles"

cd "$DOTFILES"

echo "Installing dotfiles with GNU Stow..."

# Remove any conflicting real files/dirs under a package before stowing,
# so existing configs get fully replaced with no backup, no prompts.
force_clean() {
    local package="$1"

    while IFS= read -r -d '' src; do
        rel="${src#"$package"/}"
        target="$HOME/$rel"

          if [[ -f "$src" ]]; then
            if [[ -e "$target" || -L "$target" ]] && [[ ! -L "$target" ]]; then
                real_target="$(readlink -f -- "$target" 2>/dev/null || true)"
                real_src="$(readlink -f -- "$src" 2>/dev/null || true)"
                if [[ "$real_target" == "$real_src" ]]; then
                    continue
                fi
                echo "  ✗ Removing existing $target"
                rm -rf -- "$target"
            elif [[ -L "$target" ]]; then
                real_link="$(readlink -f -- "$target" 2>/dev/null || true)"
                real_src="$(readlink -f -- "$src" 2>/dev/null || true)"
                if [[ "$real_link" != "$real_src" ]]; then
                    echo "  ✗ Replacing stale symlink $target"
                    rm -f -- "$target"
                fi
            fi
        fi
    done < <(find "$package" -type f -print0)
}

for package in */ ; do
    package="${package%/}"

    case "$package" in
        scripts|packages|assets|docs|.git)
            continue
            ;;
    esac

    echo "→ Stowing $package"
    force_clean "$package"
    stow --restow "$package"
done

echo
echo "✓ All dotfiles linked successfully."
