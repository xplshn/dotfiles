#!/bin/sh

STATE_FILE="${TMP:-/tmp}/mpris-scroll.state"
MAXLEN=20
SCROLL_DELAY=1

status=$(playerctl status 2>/dev/null || echo "Stopped")
artist=$(playerctl metadata xesam:artist 2>/dev/null)
title=$(playerctl metadata xesam:title 2>/dev/null)
player=$(playerctl -l 2>/dev/null | head -n1)

case "$player" in
  *mpv*) icon="" ;;
  *brave*) icon="" ;;
  *chromium*) icon="" ;;
  *discord*) icon="" ;;
  *telegram*) icon="" ;;
  *youtube*) icon="󰗃" ;;
  *) icon="" ;;
esac

paused_icon=""

track="${artist} - ${title}"
[ -z "$track" ] && exit 0

if [ -f "$STATE_FILE" ]; then
    cached_track=$(sed -n '1p' "$STATE_FILE")
    start_epoch=$(sed -n '2p' "$STATE_FILE")
else
    cached_track=""
    start_epoch=0
fi

if [ "$track" != "$cached_track" ]; then
    now=$(date +%s)
    printf "%s\n%s\n" "$track" "$now" > "$STATE_FILE"
    start_epoch=$now
fi

TEXT_WIDTH=$((MAXLEN - 2))
track_len=$(printf "%s" "$track" | awk '{ print length }')

if [ "$track_len" -le "$TEXT_WIDTH" ]; then
    # Pad track with spaces to fixed width
    printf "%s %-${TEXT_WIDTH}s\n" "$icon" "$track"
    exit 0
fi

now=$(date +%s)
elapsed=$((now - start_epoch))
shift=$((elapsed / SCROLL_DELAY))
shift=$((shift % (track_len + 3)))

scroll_text="$track ~ $track"

text_out=$(printf "%s\n" "$scroll_text" |
    awk -v start="$shift" -v width="$TEXT_WIDTH" '
        {
            s = $0
            # Adjust start to 1-based for awk substr
            start = start + 1
            if (start > length(s)) start = 1
            out = substr(s, start, width)
            while (length(out) < width) out = out " "
            print out
        }')

if [ "$status" = "Paused" ]; then
    printf "%s <i>%s</i>\n" "$paused_icon" "$text_out"
else
    printf "%s %s\n" "$icon" "$text_out"
fi
