#!/usr/bin/env bash
# Launch rofi in drun mode and open selected app in a new workspace

# Get list of occupied workspaces
occupied=$(i3-msg -t get_workspaces | jq -r '.[].num' | sort -n)

# Find the first empty workspace (1-10)
new_workspace=""
for i in {1..10}; do
  if ! echo "$occupied" | grep -q "^${i}$"; then
    new_workspace=$i
    break
  fi
done

# If all workspaces 1-10 are occupied, find the highest workspace and add 1
if [ -z "$new_workspace" ]; then
  highest=$(echo "$occupied" | tail -1)
  new_workspace=$((highest + 1))
fi

# Export a custom run command that switches workspace before launching
export ROFI_RUN_COMMAND="i3-msg 'workspace number $new_workspace; exec {cmd}'"

# Launch rofi
rofi -show drun -config ~/.config/rofi/app-launcher.rasi
