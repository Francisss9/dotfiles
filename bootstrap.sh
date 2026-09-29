#!/usr/bin/env bash

set -euo pipefail

GREEN="\033[1;32m"
BLUE="\033[1;34m"
RED="\033[1;31m"
YELLOW="\033[1;33m"
RESET="\033[0m"

info() {
    printf "${BLUE}[INFO]${RESET} %s\n" "$1"
}

success() {
    printf "${GREEN}[ OK ]${RESET} %s\n" "$1"
}

warn() {
    printf "${YELLOW}[WARN]${RESET} %s\n" "$1"
}

error() {
    printf "${RED}[FAIL]${RESET} %s\n" "$1"
}

require_root() {
    if [[ $EUID -eq 0 ]]; then
        error "Don't run this script as root."
        exit 1
    fi
}

install_pkg() {
    if ! pacman -Qi "$1" &>/dev/null; then
        info "Installing $1..."
        sudo pacman -S --needed --noconfirm "$1"
    else
        success "$1 already installed."
    fi
}

require_root

if [[ ! -f /etc/arch-release ]]; then
    error "This script only supports Arch Linux."
    exit 1
fi

info "Updating system..."
sudo pacman -Syu --noconfirm

install_pkg git
install_pkg curl
install_pkg wget
install_pkg base-devel

if ! command -v yay &>/dev/null; then
    info "Installing yay..."

    cd /tmp

    git clone https://aur.archlinux.org/yay.git

    cd yay

    makepkg -si --noconfirm

    cd ..

    rm -rf yay

    success "yay installed."
else
    success "yay already installed."
fi

if [[ ! -f "./install.sh" ]]; then
    error "install.sh not found in current directory."
    error "Run this script from inside your cloned dotfiles repo, e.g.:"
    error "  cd ~/.dotfiles && ./bootstrap.sh"
    exit 1
fi

chmod +x install.sh

info "Starting installer..."

./install.sh
