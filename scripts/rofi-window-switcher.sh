#!/usr/bin/env bash
# Rofi window switcher with close action

# Run rofi in window mode with help message
# Exit codes: 0 = selected with Enter, 10 = kb-custom-1, 1 = cancelled
WINDOW_ID=$(rofi -show window -config ~/.config/rofi/window-switcher.rasi -mesg "j/k: navigate  l: switch  d: close")
EXIT_CODE=$?

if [ -z "$WINDOW_ID" ]; then
    # No selection or cancelled
    exit 0
fi

case $EXIT_CODE in
    0)
        # Normal selection - switch to window
        wmctrl -i -a "$WINDOW_ID"
        ;;
    10)
        # Custom key 1 (d) - close window
        wmctrl -i -c "$WINDOW_ID"
        ;;
    *)
        # Other exit codes - do nothing
        exit 0
        ;;
esac
