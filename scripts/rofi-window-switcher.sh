#!/usr/bin/env bash
# Rofi window switcher with close action

# Get i3 workspace info for all windows
I3_TREE=$(i3-msg -t get_tree)

# Build window list: each line is "DISPLAY<TAB>WINDOW_ID<TAB>ICON_NAME<TAB>WORKSPACE_NUM"
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
    
    # Numeric workspace key for sorting; unknown => 999
    if [[ "$WORKSPACE" =~ ^[0-9]+$ ]]; then
        WS_KEY=$WORKSPACE
    else
        WS_KEY=999
    fi

    # Append: DISPLAY, WINDOW_ID, ICON_NAME, WORKSPACE_NUM
    WINDOW_LIST+="${WORKSPACE} · ${CLASS} · ${TITLE}"$'\t'"${WIN_ID}"$'\t'"${CLASS,,}"$'\t'"${WS_KEY}"
    WINDOW_LIST+=$'\n'

done < <(wmctrl -l)

if [ -z "$WINDOW_LIST" ]; then
    exit 0
fi

# Sort by workspace number (field 4) and remove any blank lines
SORTED_LIST=$(echo "$WINDOW_LIST" | LC_ALL=C sort -t $'\t' -k4,4n | sed '/^$/d')

# Run rofi in dmenu mode with help message
# Generate input with icon escape sequences: text\0icon\x1ficon_name
# Exit codes: 0 = selected with Enter, 10 = kb-custom-1, 1 = cancelled
SELECTED=$(echo "$SORTED_LIST" | awk -F'\t' '{printf "%s%cicon%c%s\n", $1, 0, 31, $3}' | rofi -dmenu -config ~/.config/rofi/window-switcher.rasi -mesg "j/k: navigate  l: switch  d: close  1-9/0: workspace" -format 'i' -selected-row 0)
EXIT_CODE=$?

# SELECTED is the 0-based index, or empty if cancelled
if [ "$SELECTED" = "" ]; then
    exit 0
fi

# Extract window ID from the sorted list using the index (add 1 for sed line numbers)
WINDOW_ID=$(echo "$SORTED_LIST" | sed -n "$((SELECTED + 1))p" | cut -f2 | tr -d ' ')

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
        WINDOW_NAME=$(echo "$SORTED_LIST" | sed -n "$((SELECTED + 1))p" | cut -f1)
        CONFIRM=$(printf "No\nYes" | rofi -dmenu -config ~/.config/rofi/confirm-dialog.rasi -p "Close window?" -mesg "$WINDOW_NAME")
        if [ "$CONFIRM" = "Yes" ]; then
            wmctrl -i -a "$WINDOW_ID"
            sleep 0.1
            i3-msg kill
        fi
        ;;
    11) i3-msg workspace number 1 >/dev/null ;;
    12) i3-msg workspace number 2 >/dev/null ;;
    13) i3-msg workspace number 3 >/dev/null ;;
    14) i3-msg workspace number 4 >/dev/null ;;
    15) i3-msg workspace number 5 >/dev/null ;;
    16) i3-msg workspace number 6 >/dev/null ;;
    17) i3-msg workspace number 7 >/dev/null ;;
    18) i3-msg workspace number 8 >/dev/null ;;
    19) i3-msg workspace number 9 >/dev/null ;;
    20) i3-msg workspace number 10 >/dev/null ;;
    *)
        # Other exit codes - do nothing
        exit 0
        ;;
esac
