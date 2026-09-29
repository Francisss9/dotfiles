#!/usr/bin/env bash

set -euo pipefail

readonly DOTFILES="$HOME/.dotfiles"

info() {
    printf "\033[1;34m[INFO]\033[0m %s\n" "$1"
}

success() {
    printf "\033[1;32m[SUCCESS]\033[0m %s\n" "$1"
}

warn() {
    printf "\033[1;33m[WARNING]\033[0m %s\n" "$1"
}

error() {
    printf "\033[1;31m[ERROR]\033[0m %s\n" "$1"
}

require() {
    command -v "$1" >/dev/null 2>&1 || {
        error "$1 is not installed."
        exit 1
    }
}
