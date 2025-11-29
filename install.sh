#!/usr/bin/env bash
set -euo pipefail

# Local install script for nix-config
# Copies the repo to /etc/nixos (preserving hardware-configuration.nix) and rebuilds

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo "Formatting..."
treefmt

echo "Copying to /etc/nixos (preserving hardware-configuration.nix)..."
# Use rsync to copy everything except hardware-configuration.nix
sudo rsync -av --delete \
    --exclude 'hardware-configuration.nix' \
    --exclude '.git' \
    "$SCRIPT_DIR/" /etc/nixos/

# Re-initialize git in /etc/nixos for flake support
# Flakes require the directory to be a git repo to properly resolve paths
if [ ! -d /etc/nixos/.git ]; then
    echo "Initializing git repo in /etc/nixos for flake support..."
    sudo git -C /etc/nixos init
fi
sudo git -C /etc/nixos add -A

echo "Rebuilding system..."
sudo nixos-rebuild switch --flake /etc/nixos#axiom

echo "Done!"
