#!/usr/bin/env bash
# Run a command in a new (empty) i3 workspace.
# Usage: new-workspace <command> [args...]
set -euo pipefail

if [ $# -eq 0 ]; then
  echo "Usage: new-workspace <command> [args...]" >&2
  exit 1
fi

# Check if current workspace has any windows
current_ws=$(i3-msg -t get_workspaces | jq -r '.[] | select(.focused==true) | .num')
window_count=$(i3-msg -t get_tree | jq "[.. | select(.type? == \"workspace\" and .num == $current_ws) | .nodes, .floating_nodes] | flatten | length")

if [ "$window_count" -eq 0 ]; then
  # Current workspace is empty, use it
  nohup "$@" >/dev/null 2>&1 & disown
  exit 0
fi

# Get the full workspace tree to check for windows
tree=$(i3-msg -t get_tree)

# Get list of occupied workspaces (numbers only)
occupied=$(i3-msg -t get_workspaces | jq -r '.[].num' | sort -n || true)

# Find the first empty workspace in 1..10, else highest+1, else 1
# A workspace is empty if it either doesn't exist or has no windows
new_ws=""
for i in {1..10}; do
  if ! grep -qx "$i" <<<"$occupied"; then
    # Workspace doesn't exist, it's empty
    new_ws=$i
    break
  else
    # Workspace exists, check if it has any windows
    ws_window_count=$(jq "[.. | select(.type? == \"workspace\" and .num == $i) | .nodes, .floating_nodes] | flatten | length" <<<"$tree")
    if [ "$ws_window_count" -eq 0 ]; then
      new_ws=$i
      break
    fi
  fi
done

if [ -z "$new_ws" ]; then
  if [ -n "$occupied" ]; then
    highest=$(tail -n1 <<<"$occupied")
    new_ws=$((highest + 1))
  else
    new_ws=1
  fi
fi

# Switch, then launch the command detached so this script can exit
i3-msg "workspace number $new_ws" >/dev/null
nohup "$@" >/dev/null 2>&1 & disown
