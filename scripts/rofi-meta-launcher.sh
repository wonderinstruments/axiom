#!/usr/bin/env bash
# Rofi meta-launcher - select which launcher to use

# Define launchers with display names and their commands
# Format: "Display Name|Command"
LAUNCHERS=(
    "Applications|rofi -show drun -config ~/.config/rofi/app-launcher.rasi"
    "Windows|~/.local/bin/rofi-window-switcher"
)

# Build the list for display (just the names)
LAUNCHER_NAMES=""
for launcher in "${LAUNCHERS[@]}"; do
    NAME="${launcher%%|*}"
    LAUNCHER_NAMES+="${NAME}"$'\n'
done

# Show rofi with the launcher list
SELECTED=$(echo -n "$LAUNCHER_NAMES" | rofi -dmenu -config ~/.config/rofi/meta-launcher.rasi -mesg "j/k: navigate  l: select" -format 's' -p "Launcher")

# If nothing selected, exit
if [ -z "$SELECTED" ]; then
    exit 0
fi

# Find the command for the selected launcher
for launcher in "${LAUNCHERS[@]}"; do
    NAME="${launcher%%|*}"
    COMMAND="${launcher#*|}"
    
    if [ "$NAME" = "$SELECTED" ]; then
        # Execute the selected launcher
        eval "$COMMAND"
        exit 0
    fi
done
