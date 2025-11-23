#!/usr/bin/env bash
# Run a command in a new (empty) i3 workspace.
# Usage: new-workspace <command> [args...]
set -euo pipefail

if [ $# -eq 0 ]; then
  echo "Usage: new-workspace <command> [args...]" >&2
  exit 1
fi

# Get list of occupied workspaces (numbers only)
occupied=$(i3-msg -t get_workspaces | jq -r '.[].num' | sort -n || true)

# Find the first empty workspace in 1..10, else highest+1, else 1
new_ws=""
for i in {1..10}; do
  if ! grep -qx "$i" <<<"$occupied"; then
    new_ws=$i
    break
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
