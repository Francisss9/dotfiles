#!/usr/bin/env bash

set -euo pipefail

echo "Updating package lists..."

./scripts/update/packages_update.sh

echo
echo "Syncing repository..."

./scripts/update/sync.sh
