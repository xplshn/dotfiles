#!/usr/bin/awk -f
# Reads /tmp every second
# Writes to /tmp everytime the song changes
# Make sure your /tmp is NOT on your storage
# IT WILL WRECK IT

function getCmd(cmd,    line, ret) {
    ret = ""
    if ((cmd | getline line) > 0) {
        ret = line
    }
    close(cmd)
    return ret
}

BEGIN {
    scrollWhilePaused = 0

    if (ENVIRON["TMPDIR"] != "") {
        tmpDir = ENVIRON["TMPDIR"]
    } else {
        tmpDir = "/tmp"
    }

    stateFile = tmpDir "/mpris-scroll.state"
    maxLen = 20
    scrollDelay = 1
    textWidth = maxLen - 2

    status = getCmd("playerctl status 2>/dev/null")
    if (status == "") status = "Stopped"

    artist = getCmd("playerctl metadata xesam:artist 2>/dev/null")
    title = getCmd("playerctl metadata xesam:title 2>/dev/null")

    player = ""
    while ((getline line < "playerctl -l 2>/dev/null") > 0) {
        if (player == "") player = line
    }
    close("playerctl -l 2>/dev/null")

    icon = ""
    if (index(player, "mpv") > 0) icon = ""
    else if (index(player, "brave") > 0) icon = ""
    else if (index(player, "chromium") > 0) icon = ""
    else if (index(player, "discord") > 0) icon = ""
    else if (index(player, "telegram") > 0) icon = ""
    else if (index(player, "youtube") > 0) icon = "󰗃"

    pausedIcon = ""

    track = artist " - " title
    if (track == " - " || track == "") exit

    cachedTrack = ""
    startEpoch = 0
    if ((getline line < stateFile) > 0) {
        cachedTrack = line
        close(stateFile)
        if ((getline line < stateFile) > 0) {
            startEpoch = line + 0
            close(stateFile)
        }
    }

    if (track != cachedTrack) {
        "date +%s" | getline now
        close("date +%s")
        startEpoch = now + 0
        cmd = "printf \"%s\\n%s\\n\" \"" track "\" \"" startEpoch "\" > \"" stateFile "\""
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
        "date +%s" | getline now
        close("date +%s")
    }

    elapsed = now - startEpoch
    shift = int(elapsed / scrollDelay)
    shift = shift % (trackLen + 3)

    scrollText = track " ~ " track

    start = shift + 1
    if (start > length(scrollText)) start = 1

    out = substr(scrollText, start, textWidth)
    while (length(out) < textWidth) {
        out = out " "
    }

    if (status == "Paused") {
        printf "%s <i>%s</i>\n", pausedIcon, out
    } else {
        printf "%s %s\n", icon, out
    }

    exit
}
