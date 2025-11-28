#!/usr/bin/env bash
# Axiom Config Reset Script
# Resets user configuration to template defaults

set -e

TEMPLATE_DIR="/etc/nixos/templates"
USER_CONFIG_DIR="$HOME/.config/axiom"
USER_CONFIG="$USER_CONFIG_DIR/config.toml"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

usage() {
    echo "Usage: axiom-reset-config [OPTIONS]"
    echo ""
    echo "Reset Axiom user configuration to template defaults."
    echo ""
    echo "Options:"
    echo "  -f, --force    Skip confirmation prompt"
    echo "  -b, --backup   Create backup before reset (default: yes)"
    echo "  --no-backup    Don't create backup"
    echo "  -h, --help     Show this help message"
    echo ""
    echo "Your config file: $USER_CONFIG"
    echo "Template source:  $TEMPLATE_DIR/user-config.toml"
}

FORCE=false
BACKUP=true

while [[ $# -gt 0 ]]; do
    case $1 in
        -f|--force)
            FORCE=true
            shift
            ;;
        -b|--backup)
            BACKUP=true
            shift
            ;;
        --no-backup)
            BACKUP=false
            shift
            ;;
        -h|--help)
            usage
            exit 0
            ;;
        *)
            echo -e "${RED}Unknown option: $1${NC}"
            usage
            exit 1
            ;;
    esac
done

# Check if template exists
if [ ! -f "$TEMPLATE_DIR/user-config.toml" ]; then
    echo -e "${RED}Error: Template not found at $TEMPLATE_DIR/user-config.toml${NC}"
    echo "Make sure you're running this on an Axiom system with the nix-config in /etc/nixos"
    exit 1
fi

# Confirm unless forced
if [ "$FORCE" = false ]; then
    echo -e "${YELLOW}This will reset your Axiom user configuration to defaults.${NC}"
    if [ -f "$USER_CONFIG" ]; then
        echo "Current config: $USER_CONFIG"
    fi
    read -p "Continue? [y/N] " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        echo "Aborted."
        exit 0
    fi
fi

# Create backup if requested and file exists
if [ "$BACKUP" = true ] && [ -f "$USER_CONFIG" ]; then
    BACKUP_FILE="$USER_CONFIG.backup.$(date +%Y%m%d_%H%M%S)"
    cp "$USER_CONFIG" "$BACKUP_FILE"
    echo -e "${GREEN}Backup created: $BACKUP_FILE${NC}"
fi

# Create directory if needed
mkdir -p "$USER_CONFIG_DIR"

# Copy template
cp "$TEMPLATE_DIR/user-config.toml" "$USER_CONFIG"
chmod 644 "$USER_CONFIG"

echo -e "${GREEN}Config reset to defaults: $USER_CONFIG${NC}"
echo ""
echo "Next steps:"
echo "  1. Edit $USER_CONFIG to customize your settings"
echo "  2. Run: sudo nixos-rebuild switch --flake /etc/nixos#axiom"
