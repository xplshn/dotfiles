#!/usr/bin/awk -f
# Reads /tmp every second
# Writes to /tmp everytime the song changes
# Make sure your /tmp is NOT on your storage
# IT WILL WRECK IT

function getcmd(cmd,    line, ret) {
    ret = ""
    if ((cmd | getline line) > 0) {
        ret = line
    }
    close(cmd)
    return ret
}

BEGIN {
    if (ENVIRON["TMPDIR"] != "") {
        TMPDIR = ENVIRON["TMPDIR"]
    } else {
        TMPDIR = "/tmp"
    }

    STATE_FILE = TMPDIR "/mpris-scroll.state"
    MAXLEN = 20
    SCROLL_DELAY = 1
    TEXT_WIDTH = MAXLEN - 2

    status = getcmd("playerctl status 2>/dev/null")
    if (status == "") status = "Stopped"

    artist = getcmd("playerctl metadata xesam:artist 2>/dev/null")
    title = getcmd("playerctl metadata xesam:title 2>/dev/null")

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

    paused_icon = ""

    track = artist " - " title
    if (track == " - " || track == "") {
        exit
    }

    cached_track = ""
    start_epoch = 0
    if ((getline line < STATE_FILE) > 0) {
        cached_track = line
        close(STATE_FILE)
        if ((getline line < STATE_FILE) > 0) {
            start_epoch = line + 0
            close(STATE_FILE)
        }
    }

    if (track != cached_track) {
        "date +%s" | getline now
        close("date +%s")
        start_epoch = now + 0
        cmd = "printf \"%s\\n%s\\n\" \"" track "\" \"" start_epoch "\" > \"" STATE_FILE "\""
        system(cmd)
    }

    track_len = length(track)

    if (track_len <= TEXT_WIDTH) {
        printf "%s %-" TEXT_WIDTH "s\n", icon, track
        exit
    }

    "date +%s" | getline now
    close("date +%s")

    elapsed = now - start_epoch
    shift = int(elapsed / SCROLL_DELAY)
    shift = shift % (track_len + 3)

    scroll_text = track " ~ " track

    start = shift + 1
    if (start > length(scroll_text)) start = 1

    out = substr(scroll_text, start, TEXT_WIDTH)
    while (length(out) < TEXT_WIDTH) {
        out = out " "
    }

    if (status == "Paused") {
        printf "%s <i>%s</i>\n", paused_icon, out
    } else {
        printf "%s %s\n", icon, out
    }

    exit
}
