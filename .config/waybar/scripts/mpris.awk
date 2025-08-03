#!/usr/bin/awk -f
# Reads /tmp every second
# Writes to /tmp everytime the song changes
# Make sure your /tmp is NOT on your storage
# IT WILL WRECK IT

function getCmd(cmd,    line, out) {
    out = ""
    if ((cmd | getline line) > 0) out = line
    close(cmd)
    return out
}

function trim(str) {
    sub(/^[ \t\r\n]+/, "", str)
    sub(/[ \t\r\n]+$/, "", str)
    return str
}

function stripTag(str,    i, tag, tagsLen) {
    tagsLen = split(tagsAndIcons, tags, " ")
    for (i = 1; i <= tagsLen; ++i) {
        split(tags[i], pair, ":")
        tag = pair[1]
        if (match(str, tag "$")) {
            return substr(str, 1, RLENGTH - length(tag))
        }
    }
    return str
}

function iconForTitle(title, player,    i, tag, ico, tagsLen) {
    tagsLen = split(tagsAndIcons, tags, " ")
    for (i = 1; i <= tagsLen; ++i) {
        split(tags[i], pair, ":")
        tag = pair[1]
        ico = pair[2]
        if (index(title, tag) > 0) return ico
    }

    if (index(player, "mpv")) return ""
    if (index(player, "brave") || index(player, "chromium")) return ""
    if (index(player, "telegram")) return ""
    return ""
}

BEGIN {
    scrollWhilePaused = 0
    stateFile = (ENVIRON["TMP"] ? ENVIRON["TMP"] : "/tmp") "/mpris-scroll.state"
    maxLen = 20
    scrollDelay = 1
    textWidth = maxLen - 2
    pausedIcon = ""

    tagsAndIcons = "[YouTube]:󰗃 [Discord]: [Telegram]:"

    status = getCmd("playerctl status 2>/dev/null")
    if (status == "") status = "Stopped"

    artist = getCmd("playerctl metadata xesam:artist 2>/dev/null")
    title = getCmd("playerctl metadata xesam:title 2>/dev/null")
    title = trim(stripTag(trim(title)))

    player = getCmd("playerctl -l 2>/dev/null | head -n1")

    icon = iconForTitle(title, player)

    track = artist " - " title
    if (track == "" || track == " - ") exit

    cachedTrack = ""
    startEpoch = 0

    if ((getline line < stateFile) > 0) {
        cachedTrack = line
        if ((getline line < stateFile) > 0) {
            startEpoch = line + 0
        }
        close(stateFile)
    }

    if (track != cachedTrack) {
        now = getCmd("date +%s")
        startEpoch = now + 0
        cmd = "printf \"%s\\n%s\\n%s\\n\" \"" track "\" \"" startEpoch "\" \"" icon "\" > \"" stateFile "\""
        system(cmd)
    }

    trackLen = length(track)
    if (trackLen <= textWidth) {
        printf "%s %-" textWidth "s\n", icon, track
        exit
    }

    if (status == "Paused" && scrollWhilePaused == 0) {
        now = startEpoch
    } else {
        now = getCmd("date +%s") + 0
    }

    elapsed = now - startEpoch
    shift = int(elapsed / scrollDelay)
    shift %= (trackLen + 3)

    scrollText = track " ~ " track
    scrollLen = length(scrollText)

    if (shift >= scrollLen) shift = 0

    out = substr(scrollText, shift + 1, textWidth)
    while (length(out) < textWidth) out = out " "

    if (status == "Paused") {
        printf "%s <i>%s</i>\n", pausedIcon, out
    } else {
        printf "%s %s\n", icon, out
    }

    exit
}
