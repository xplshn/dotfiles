#!/bin/sh -e
chosen=$(pa l | rofi -dmenu -i -p "Select Key")
if [ -z "$chosen" ]; then
    exit 0
fi
if command -v wl-copy >/dev/null 2>&1; then
    pa show "$chosen" | wl-copy
    clip="wl-copy"
elif command -v xclip >/dev/null 2>&1; then
    pa show "$chosen" | xclip -selection clipboard
    clip="xclip"
else
    # If neither tool is found, send an error notification and exit.
    notify-send -t 2500 "rofiPa.sh: Missing dependency" "No clipboard tool found. Please install wl-copy or xclip."
    exit 1
fi

notify-send -t 2500 "rofiPa.sh: Copied selection" "Copied key [$chosen]' to clipboard via [$clip]"
