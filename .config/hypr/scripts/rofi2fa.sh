#!/bin/sh -e
chosen=$(2fa list | rofi -dmenu -i -p "Select Key")
if [ -z "$chosen" ]; then
    exit 0
fi
if command -v wl-copy >/dev/null 2>&1; then
    2fa show "$chosen" | wl-copy
    clip="wl-copy"
elif command -v xclip >/dev/null 2>&1; then
    2fa show "$chosen" | xclip -selection clipboard
    clip="xclip"
else
    # If neither tool is found, send an error notification and exit.
    notify-send -t 2500 "rofi2fa.sh: Missing dependency" "No clipboard tool found. Please install wl-copy or xclip."
    exit 1
fi

notify-send -t 2500 "rofi2fa.sh: Copied selection" "Copied key [$chosen]' to clipboard via [$clip]"
