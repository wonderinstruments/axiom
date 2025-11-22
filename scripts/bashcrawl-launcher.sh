#!/usr/bin/env bash

BASHCRAWL_DIR="$HOME/bashcrawl"
SAVE_POINT_FILE="$HOME/.local/share/axiom/bashcrawl-save"
CANONICAL_DIR="$HOME/.local/share/axiom/bashcrawl"

# Restore bashcrawl if it doesn't exist
if [ ! -d "$BASHCRAWL_DIR" ]; then
    echo "Bashcrawl not found. Restoring from canonical copy..."
    if [ -d "$CANONICAL_DIR" ]; then
        cp -r "$CANONICAL_DIR" "$BASHCRAWL_DIR"
        echo "Bashcrawl restored!"
    else
        echo "Error: Canonical bashcrawl directory not found at $CANONICAL_DIR"
        read -p "Press Enter to exit..."
        exit 1
    fi
fi

# Determine starting location
if [ -f "$SAVE_POINT_FILE" ]; then
    SAVE_POINT=$(cat "$SAVE_POINT_FILE")
    # Verify the save point exists and is within bashcrawl
    if [[ "$SAVE_POINT" == "$BASHCRAWL_DIR"* ]] && [ -d "$SAVE_POINT" ]; then
        START_DIR="$SAVE_POINT"
    else
        START_DIR="$BASHCRAWL_DIR/entrance"
    fi
else
    START_DIR="$BASHCRAWL_DIR/entrance"
fi

# Navigate to starting directory
cd "$START_DIR" || exit 1

# Print initial instructions
echo "Welcome to Bashcrawl!"
echo "Type 'cat scroll' to read the instructions."
echo ""

# Set up PROMPT_COMMAND to save location on directory change
save_location() {
    local current_dir="$(pwd)"
    # Only save if we're within bashcrawl
    if [[ "$current_dir" == "$BASHCRAWL_DIR"* ]]; then
        echo "$current_dir" > "$SAVE_POINT_FILE"
    fi
}

# Add save_location to PROMPT_COMMAND
if [[ "$PROMPT_COMMAND" != *"save_location"* ]]; then
    PROMPT_COMMAND="save_location${PROMPT_COMMAND:+;$PROMPT_COMMAND}"
fi

# Start an interactive bash shell
exec bash
