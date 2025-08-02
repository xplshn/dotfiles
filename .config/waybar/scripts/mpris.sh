#!/bin/sh
# Reads /tmp every second
# Writes to /tmp everytime the song changes
# Make sure your /tmp is NOT on your storage
# IT WILL WRECK IT

scrollWhilePaused=0
stateFile="${TMP:-/tmp}/mpris-scroll.state"
maxLen=20
scrollDelay=1

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

pausedIcon=""
track="${artist} - ${title}"
[ -z "$track" ] || [ "$track" = " - " ] && exit 0

if [ -f "$stateFile" ]; then
    cachedTrack=$(sed -n '1p' "$stateFile")
    startEpoch=$(sed -n '2p' "$stateFile")
else
    cachedTrack=""
    startEpoch=0
fi

if [ "$track" != "$cachedTrack" ]; then
    now=$(date +%s)
    printf "%s\n%s\n" "$track" "$now" > "$stateFile"
    startEpoch=$now
fi

textWidth=$((maxLen - 2))
trackLen=$(printf "%s" "$track" | awk '{ print length }')

if [ "$trackLen" -le "$textWidth" ]; then
    printf "%s %-${textWidth}s\n" "$icon" "$track"
    exit 0
fi

if [ "$status" = "Paused" ] && [ "$scrollWhilePaused" -eq 0 ]; then
    now=$startEpoch
else
    now=$(date +%s)
fi

elapsed=$((now - startEpoch))
shift=$((elapsed / scrollDelay))
shift=$((shift % (trackLen + 3)))

scrollText="$track ~ $track"

textOut=$(printf "%s\n" "$scrollText" |
    awk -v start="$shift" -v width="$textWidth" '
        {
            s = $0
            start = start + 1
            if (start > length(s)) start = 1
            out = substr(s, start, width)
            while (length(out) < width) out = out " "
            print out
        }')

if [ "$status" = "Paused" ]; then
    printf "%s <i>%s</i>\n" "$pausedIcon" "$textOut"
else
    printf "%s %s\n" "$icon" "$textOut"
fi
