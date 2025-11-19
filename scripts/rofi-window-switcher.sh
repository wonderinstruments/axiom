#!/usr/bin/env bash
# Rofi window switcher with close action

# Get i3 workspace info for all windows
I3_TREE=$(i3-msg -t get_tree)

# Build window list: each line is "WS · CLASS · TITLE|||WINDOW_ID"
WINDOW_LIST=""
while IFS= read -r line; do
    WIN_ID=$(echo "$line" | awk '{print $1}')
    TITLE=$(echo "$line" | awk '{for(i=4;i<=NF;i++) printf "%s ", $i}')
    
    # Get window class
    CLASS_LINE=$(xprop -id "$WIN_ID" WM_CLASS 2>/dev/null)
    if [[ $CLASS_LINE =~ \"[^\"]+\",\ \"([^\"]+)\" ]]; then
        CLASS="${BASH_REMATCH[1]}"
    else
        CLASS="Unknown"
    fi
    
    # Get workspace from i3 tree (convert hex window ID to decimal for i3)
    WIN_ID_DEC=$((WIN_ID))
    WORKSPACE=$(echo "$I3_TREE" | jq -r --arg id "$WIN_ID_DEC" '
        .. | objects | select(.window? == ($id | tonumber)) | 
        .workspace? // empty
    ' | head -1)
    
    # If workspace not found via .workspace, find it by traversing up
    if [ -z "$WORKSPACE" ]; then
        WORKSPACE=$(echo "$I3_TREE" | jq -r --arg id "$WIN_ID_DEC" '
            .. | objects | select(.nodes[]?.window? == ($id | tonumber) or .floating_nodes[]?.window? == ($id | tonumber)) | 
            select(.type == "workspace") | .num
        ' | head -1)
    fi
    
    # Fallback to "?" if workspace not found
    WORKSPACE=${WORKSPACE:-"?"}
    
    # Format: "WS · CLASS · TITLE<TAB>WINDOW_ID"
    WINDOW_LIST+="${WORKSPACE} · ${CLASS} · ${TITLE}	${WIN_ID}"
    WINDOW_LIST+=$'\n'
done < <(wmctrl -l)

if [ -z "$WINDOW_LIST" ]; then
    exit 0
fi

# Show only the display part (before tab) to user
DISPLAY_LIST=$(echo "$WINDOW_LIST" | cut -f1)

# Run rofi in dmenu mode with help message
# Exit codes: 0 = selected with Enter, 10 = kb-custom-1, 1 = cancelled
SELECTED=$(echo "$DISPLAY_LIST" | rofi -dmenu -config ~/.config/rofi/window-switcher.rasi -mesg "j/k: navigate  l: switch  d: close" -format 'i' -selected-row 0)
EXIT_CODE=$?

# SELECTED is the 0-based index, or empty if cancelled
if [ "$SELECTED" = "" ]; then
    exit 0
fi

# Extract window ID from the full list using the index (add 1 for sed line numbers)
WINDOW_ID=$(echo "$WINDOW_LIST" | sed -n "$((SELECTED + 1))p" | cut -f2 | tr -d ' ')

if [ -z "$WINDOW_ID" ]; then
    exit 0
fi

case $EXIT_CODE in
    0)
        # Normal selection - switch to window
        wmctrl -i -a "$WINDOW_ID"
        ;;
    10)
        # Custom key 1 (d) - confirm then close window
        WINDOW_NAME=$(echo "$DISPLAY_LIST" | sed -n "$((SELECTED + 1))p")
        CONFIRM=$(printf "No\nYes" | rofi -dmenu -config ~/.config/rofi/confirm-dialog.rasi -p "Close window?" -mesg "$WINDOW_NAME")
        if [ "$CONFIRM" = "Yes" ]; then
            wmctrl -i -a "$WINDOW_ID"
            sleep 0.1
            i3-msg kill
        fi
        ;;
    *)
        # Other exit codes - do nothing
        exit 0
        ;;
esac
