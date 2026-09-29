#!/usr/bin/env bash

set -euo pipefail

echo "======================================"
echo " Installing Dotfiles"
echo "======================================"

./scripts/install/packages_install.sh
./scripts/install/stow.sh
./scripts/install/system_configs.sh

./scripts/utils/doctor.sh

echo
echo "Installation complete."
