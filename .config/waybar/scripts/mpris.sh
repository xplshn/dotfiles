#!/bin/sh
# Reads /tmp every second
# Writes to /tmp everytime the song changes
# Make sure your /tmp is NOT on your storage
# IT WILL WRECK IT

TMPDIR="${TMPDIR:-/tmp}"
scrollWhilePaused=0
maxLen=20
scrollDelay=1
textWidth=$((maxLen - 2))
pausedIcon=""
stateFile="$TMPDIR/mpris-scroll.state"
tagsAndIcons='[YouTube]:󰗃 [Discord]: [Telegram]:'

[ -f "$TMPDIR/no-mpris" ] && exit 0

trim() {
	# Remove leading
	set -- "${1#"${1%%[![:space:]]*}"}"
	# Remove trailing
	printf %s "${1%"${1##*[![:space:]]}"}"
}

stripTag() {
	for entry in $tagsAndIcons; do
		tag=${entry%%:*}
		case "$1" in
			*"$tag") printf %s "${1%"$tag"}"; return ;;
		esac
	done
	printf %s "$1"
}

iconForTitle() {
	title=$1 player=$2
	for entry in $tagsAndIcons; do
		tag=${entry%%:*}
		icon=${entry#*:}
		case "$title" in
			*"$tag"*) echo "$icon"; return ;;
		esac
	done

	case "$player" in
		*mpv*) echo "" ;;
		*brave*|*chromium*) echo "" ;;
		*telegram*) echo "" ;;
		*) echo "" ;;
	esac
}

status=$(playerctl status 2>/dev/null)
[ -z "$status" ] && status="Stopped"

artist=$(playerctl metadata xesam:artist 2>/dev/null)
title=$(playerctl metadata xesam:title 2>/dev/null)
player=$(playerctl -l 2>/dev/null | sed -n 1p)

icon=$(iconForTitle "$title" "$player")
title=$(trim "$(stripTag "$(trim "$title")")")
track="$artist - $title"
[ -z "$track" ] || [ "$track" = " - " ] && exit 0

if [ -f "$stateFile" ]; then
	i=0
	while IFS= read -r line && [ $i -lt 2 ]; do
		case $i in
			0) cachedTrack=$line ;;
			1) startEpoch=$line ;;
		esac
		i=$((i + 1))
	done < "$stateFile"
fi

if [ "$track" != "$cachedTrack" ]; then
	startEpoch=$(date +%s)
	printf "%s\n%s\n%s\n" "$track" "$startEpoch" "$icon" > "$stateFile"
fi

trackLen=${#track}
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
shiftBy=$((elapsed / scrollDelay))
shiftBy=$((shiftBy % (trackLen + 3)))
scrollText="$track ~ $track"
scrollLen=${#scrollText}

[ "$shiftBy" -ge "$scrollLen" ] && shiftBy=0

# Build substring
i=0 idx=0 textOut= ch=
while [ "$i" -lt "$scrollLen" ]; do
	ch=${scrollText%"${scrollText#?}"}
	[ "$idx" -ge "$shiftBy" ] && [ "${#textOut}" -lt "$textWidth" ] && textOut="$textOut$ch"
	scrollText=${scrollText#?}
	i=$((i + 1))
	idx=$((idx + 1))
	[ "${#textOut}" -ge "$textWidth" ] && break
done

# Pad if needed
while [ "${#textOut}" -lt "$textWidth" ]; do
	textOut="$textOut "
done

if [ "$status" = "Paused" ]; then
	printf "%s <i>%s</i>\n" "$pausedIcon" "$textOut"
else
	printf "%s %s\n" "$icon" "$textOut"
fi
