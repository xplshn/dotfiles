#!/bin/sh -eu

# generates a themed lock screen for Hyprland using swaylock, ImageMagick, and grim.
# It captures a screenshot, blurs it, and overlays it with user-configurable text
# and images.

# Defaults
#
# ImageMagick effects
hueEffect='-level 0%,100%,0.6'
blurEffect='-filter Gaussian -resize 20% -define filter:sigma=1.5 -resize 500%'
# Font and text for the password prompt
font="Mononoki-Nerd-Font-Regular"
text="Type password to unlock"
# Default centered text
centeredText='󰦝'
# Paths to optional SVG files
whiteSvgPath=""
blackSvgPath=""
# Custom text colors, default to empty
customPromptColor=""
customCenteredColor=""

# For state and command options
minimizeWindows=""
swaylockOptions=""
paramOptions=""

# Help
#
#
options="Options:
    -h                  This help menu.
    -d                  Attempt to minimize all windows before locking.
    -g                  Set background to greyscale instead of color.
    -p                  Pixelate the background instead of blurring (faster).
    -f <fontname>       Set a custom font.
    -t <text>           Set a custom text prompt.
    -c <text>           Set a custom centered text (defaults to '󰦝').
    -w <path/to/svg>    Set a centered white SVG. Autopick color based on brightness.
    -b <path/to/svg>    Set a centered black SVG. Autopick color based on brightness.
    -M <hex_color>      Set a custom color for the prompt text.
    -N <hex_color>      Set a custom color for the centered text/icon.
    -l                  Display a list of possible fonts and exit.
    -F                  Show failed authentication attempts.
    -e                  Ignore empty passwords.
    -L                  Disable the Caps Lock text.
    -K                  Hide keyboard layout.
    -D                  Daemonize (detach from terminal after locking)."

# Cleanup and Trapping
#
# String to keep track of temporary files for cleanup
tempFiles=""
# Setup a trap to remove temporary files on script exit
trap 'rm -f $tempFiles' EXIT HUP INT QUIT TERM

# Argument Parsing
#
#
while getopts 'hdgpDelt:f:lc:w:b:M:N:FK' opt; do
    case "$opt" in
        h) printf "Usage: %s [options]\n\n%s\n\n" "${0##*/}" "$options"; exit 0 ;;
        d) minimizeWindows=$(command -v wmctrl) ;;
        g) hueEffect='-set colorspace Gray -evaluate-sequence Mean' ;;
        p) blurEffect='-scale 10% -scale 1000%' ;;
        f) font="$OPTARG" ;;
        t) text="$OPTARG" ;;
        c) centeredText="$OPTARG" ;;
        w) whiteSvgPath="$OPTARG" ;;
        b) blackSvgPath="$OPTARG" ;;
        M) customPromptColor="$OPTARG" ;;
        N) customCenteredColor="$OPTARG" ;;
        l) magick -list font | awk -F: '/Font: / { print $2 }' | sort -u | ${PAGER:-less} ; exit 0 ;;
        F|e|L|K) swaylockOptions="$swaylockOptions -$opt" ;;
        D) swaylockOptions="$swaylockOptions --daemonize" ;; # getopts doesn't do long options
        '?') printf "Invalid option: '-%s'\n" "$OPTARG" >&2; exit 1 ;;
    esac
done

# Check for mutually exclusive SVG options
if [ -n "$whiteSvgPath" ] && [ -n "$blackSvgPath" ]; then
    printf "Error: Cannot use both -w and -b flags at the same time.\n" >&2
    exit 1
fi

# Main
#
#
outputs=$(hyprctl -j monitors | jq -r '.[] | .name')

# Process each monitor
for output in $outputs; do
    # Create a temporary file for the screenshot and schedule it for cleanup
    img="$(mktemp)"
    tempFiles="$tempFiles $img"

    # Take a screenshot of the specific output
    grim -o "$output" "$img"

    # Per-monitor theme and SVG setup
    #
    # Variables for theme colors
    localPromptColor=""
    localCenteredColor=""
    localTheme=""
    localSvg=""
    localParamOptions=""

    # Check image brightness to decide on black/white theme
    # Get brightness (0-100) from a 100x100px crop in the center of the image
    color=$(magick "$img" -gravity center -crop 100x100+0+0 +repage -resize 1x1 \
        -colorspace hsb txt:- | awk -F '[%$]' 'NR==2{gsub(",",""); printf "%.0f\n", $(NF-1)}')

    # Autopick colors unless custom colors are specified
    if [ -z "$customPromptColor" ] || [ -z "$customCenteredColor" ]; then
        if [ "$color" -gt 60 ]; then # Light background -> dark text/elements
            localTheme="black"
            localParamOptions="--inside-color=0000001c --ring-color=0000003e \
                --line-color=00000000 --key-hl-color=ffffff80 --ring-ver-color=ffffff00 \
                --separator-color=22222260 --inside-ver-color=ff99441c \
                --ring-clear-color=ff994430 --inside-clear-color=ff994400 \
                --ring-wrong-color=00000055 --inside-wrong-color=0000001c"
        else # Dark background -> light text/elements
            localTheme="white"
            localParamOptions="--inside-color=ffffff1c --ring-color=ffffff3e \
                --line-color=ffffff00 --key-hl-color=00000080 --ring-ver-color=00000000 \
                --separator-color=22222260 --inside-ver-color=0000001c \
                --ring-clear-color=ff994430 --inside-clear-color=ff994400 \
                --ring-wrong-color=00000055 --inside-wrong-color=0000001c"
        fi
    fi

    # Set final text colors
    localPromptColor="${customPromptColor:-#000000}"
    localCenteredColor="${customCenteredColor:-#000000}"
    if [ "$localTheme" = "white" ]; then
        localPromptColor="${customPromptColor:-#FFFFFF}"
        localCenteredColor="${customCenteredColor:-#FFFFFF}"
    fi

    # Process SVG based on theme
    if [ -n "$whiteSvgPath" ]; then
        if [ "$localTheme" = "black" ]; then
            # Invert white SVG to black for light backgrounds
            tempSvg=$(mktemp --suffix=".svg")
            tempFiles="$tempFiles $tempSvg"
            magick "$whiteSvgPath" -negate "$tempSvg"
            localSvg="$tempSvg"
        else
            localSvg="$whiteSvgPath"
        fi
    elif [ -n "$blackSvgPath" ]; then
        if [ "$localTheme" = "white" ]; then
            # Invert black SVG to white for dark backgrounds
            tempSvg=$(mktemp --suffix=".svg")
            tempFiles="$tempFiles $tempSvg"
            magick "$blackSvgPath" -negate "$tempSvg"
            localSvg="$tempSvg"
        else
            localSvg="$blackSvgPath"
        fi
    fi

    # Apply effects to the screenshot
    magick "$img" $hueEffect $blurEffect "$img"

    # Add SVG if specified
    if [ -n "$localSvg" ]; then
        magick "$img" "$localSvg" -geometry 'x200' -gravity center -composite "$img"
    fi

    # Add centered text/lock icon
    magick "$img" -font "$font" -pointsize 100 -fill "$localCenteredColor" \
        -gravity center -annotate +0+0 "$centeredText" "$img"

    # Add password prompt text
    magick "$img" -font "$font" -pointsize 26 -fill "$localPromptColor" \
        -gravity center -annotate +0+160 "$text" "$img"

    # Add the processed image and parameters to swaylock's parameter string
    paramOptions="$paramOptions $localParamOptions --text-color=$localPromptColor -i $output:$img"
done

# Add a few more default swaylock parameters common to all screens
paramOptions="$paramOptions --indicator-radius 85 --text-ver-color=00000000 \
--text-wrong-color=00000000 --text-caps-lock-color=00000000 \
--text-clear-color=00000000 --line-clear-color=00000000 \
--line-wrong-color=00000000 --line-ver-color=00000000"


# If -d was used, minimize all windows before locking
if [ -n "$minimizeWindows" ]; then
    "$minimizeWindows" -k on
fi

# Try to run swaylock with the generated parameters.
# Use 'eval' to correctly parse the command string with its arguments.
if ! eval "swaylock $swaylockOptions $paramOptions" >/dev/null 2>&1; then
    # If the themed lock fails, fall back to a simpler swaylock command
    eval "swaylock $swaylockOptions"
fi

# If -d was used, restore the windows after unlocking
if [ -n "$minimizeWindows" ]; then
    "$minimizeWindows" -k off
fi
