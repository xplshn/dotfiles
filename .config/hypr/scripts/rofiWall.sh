#!/bin/sh -e

SLIDESHOW_INTERVAL=300
ROFI_THEME="fullscreen-preview" 
IMAGE_MODE="fill"

SCRIPT_PATH=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)/$(basename -- "$0")

usage() {
    echo "Usage: $(basename "$0") [options]"
    echo
    echo "A POSIX-compliant wallpaper selector and slideshow manager for Sway."
    echo
    echo "Options:"
    echo "  -d, --dir <path>        Specify the starting directory."
    echo "  -s, --slideshow <mode>  Start a slideshow directly in the specified/default directory."
    echo "  -s list                 List available slideshow modes and exit."
    echo "  -h, --help              Show this help message and exit."
    echo
    echo "Slideshow Modes: shuffle, alpha, newerFirst, olderFirst"
    exit 0
}

# Portable way to get file modification time (epoch seconds)
get_mtime() {
    # First, try Linux (Busybox, GNU, Toybox) stat format.
    if mtime=$(stat -c %Y "$1" 2>/dev/null); then
        echo "$mtime"
    # Else, try BSD stat format.
    elif mtime=$(stat -f %m "$1" 2>/dev/null); then
        echo "$mtime"
    else
        # TODO: emit error here
        # add log function, receives color and message
        # add log_error function, receives messages, calls log function passing red color and exits 1
        false
    fi
}

get_runtime_path() {
    D=".rofiWall-$(id -u)"
    if [ -n "$XDG_RUNTIME_DIR" ]; then
        echo "$XDG_RUNTIME_DIR/$D"
    else
        echo "/tmp/$D"
    fi
}

RUNTIME_DIR="$(get_runtime_path)" && mkdir -p "$RUNTIME_DIR"
STATE_FILE="$RUNTIME_DIR/rofiWall_state"
PID_FILE="$RUNTIME_DIR/rofiWall.pid"

write_state() {
    tmp_state_file="$STATE_FILE.$$"
    printf '%s\n%s\n%s\n%s\n' "$1" "$2" "$3" "$4" > "$tmp_state_file"
    mv -f "$tmp_state_file" "$STATE_FILE"
}

# Kill the currently running slideshow process, if any
kill_existing_slideshow() {
    if [ -f "$STATE_FILE" ]; then
        old_pid="$(sed -n '4p' "$STATE_FILE" 2>/dev/null)"
        if [ -n "$old_pid" ] && kill -0 "$old_pid" 2>/dev/null; then
            kill "$old_pid"
            sleep 0.1
        fi
        # Clean up state file regardless of whether the process was found.
        rm -f "$STATE_FILE"
    fi
}

run_slideshow() {
    SLIDESHOW_DIR="$1"
    ORDER="$2"
    PID=$$
    SWAYBG_PID=""
    PLAYLIST_FILE="$RUNTIME_DIR/rofiWall_playlist.$$"

    trap 'rm -f "$PID_FILE" "$STATE_FILE" "$PLAYLIST_FILE"; [ -n "$SWAYBG_PID" ] && kill "$SWAYBG_PID" 2>/dev/null; exit' INT TERM HUP

    generate_playlist() {
        dir="$1"
        order_mode="$2"

        stat_file="$RUNTIME_DIR/rofiWall_stat.$$"
        trap 'rm -f "$stat_file"' INT TERM HUP EXIT

        # 1. Find all images and write "timestamp<TAB>filepath" to a temp file.
        find "$dir" -maxdepth 1 -type f \( -iname '*.jpg' -o -iname '*.jpeg' -o -iname '*.png' -o -iname '*.webp' \) -print |
        while IFS= read -r f; do
            printf '%s\t%s\n' "$(get_mtime "$f")" "$f"
        done > "$stat_file"

        # 2. Sort the temp file based on the desired order.
        case "$order_mode" in
            alpha)      sort -t "$(printf '\t')" -k2 "$stat_file" | cut -f2- ;;
            newerFirst) sort -t "$(printf '\t')" -k1,1nr "$stat_file" | cut -f2- ;;
            olderFirst) sort -t "$(printf '\t')" -k1,1n "$stat_file" | cut -f2- ;;
            *)
                # POSIX-compliant shuffle using awk and sort.
                awk 'BEGIN{srand()} {print rand() "\t" $0}' "$stat_file" | sort -n | cut -f2- | cut -f2-
                ;;
        esac
    }

    while true; do
        # Generate a fresh playlist for each full cycle.
        generate_playlist "$SLIDESHOW_DIR" "$ORDER" > "$PLAYLIST_FILE"

        if ! [ -s "$PLAYLIST_FILE" ]; then
            echo "Error: No images found in '$(basename "$SLIDESHOW_DIR")'. Slideshow stopped." >&2
            exit 1
        fi

        # Read the newline-delimited playlist file entry by entry.
        while IFS= read -r wallpaper; do
            [ -z "$wallpaper" ] && continue # Skip empty lines.

            swaybg -i "$wallpaper" -m "$IMAGE_MODE" < /dev/null &
            SWAYBG_PID=$!
            write_state "$SLIDESHOW_DIR" "$ORDER" "$wallpaper" "$PID"
            sleep "$SLIDESHOW_INTERVAL"
            kill "$SWAYBG_PID" 2>/dev/null
            wait "$SWAYBG_PID" 2>/dev/null || true # Prevent 'set -e' from exiting.
        done < "$PLAYLIST_FILE"
    done
}

print_entry() {
    printf '%s\0icon\x1f%s\n' "$1" "$2"
}

print_rofi_menu() {
    # Navigation and static options
    [ "$CURRENT_DIR" != "/" ] && print_entry ".." "folder"

    if [ -f "$STATE_FILE" ]; then
        slideshow_pid=$(sed -n '4p' "$STATE_FILE" 2>/dev/null)
        if [ -n "$slideshow_pid" ] && kill -0 "$slideshow_pid" 2>/dev/null; then
            print_entry "Stop Slideshow" "media-playback-stop-symbolic"
        fi
    fi
    print_entry "Slideshow" "video-display"

    # Directories
    for item in *; do
        [ -d "$item" ] && print_entry "$item" "folder-pictures"
    done | sort

    for pattern in '*.png' '*.jpg' '*.jpeg' '*.webp'; do
        for file in $pattern; do
            [ -f "$file" ] && print_entry "$file" "thumbnail://$CURRENT_DIR/$file"
        done
    done
}

TARGET_DIR="${HOME}/Pictures"
SLIDESHOW_MODE=""

while [ "$#" -gt 0 ]; do
    case "$1" in
        -h|--help)
            usage
            ;;
        -d|--dir)
            [ -n "$2" ] && TARGET_DIR="$2" && shift 2 || { echo "Error: '$1' requires a path argument." >&2; exit 1; }
            ;;
        -s|--slideshow)
            [ -n "$2" ] && SLIDESHOW_MODE="$2" && shift 2 || { echo "Error: '$1' requires a mode argument." >&2; exit 1; }
            ;;
        --)
            shift
            break
            ;;
        -*)
            echo "Error: Unknown option '$1'" >&2
            usage
            ;;
        *)
            break
            ;;
    esac
done

# Main ->

# If a slideshow mode was passed as an argument, run directly.
if [ -n "$SLIDESHOW_MODE" ]; then
    if [ "$SLIDESHOW_MODE" = "list" ]; then
        echo "Available slideshow modes: shuffle, alpha, newerFirst, olderFirst"
        exit 0
    fi

    # Validate the slideshow mode.
    case "$SLIDESHOW_MODE" in
        shuffle|alpha|newerFirst|olderFirst)
            ;; # Mode is valid
        *)
            echo "Error: Invalid slideshow mode '$SLIDESHOW_MODE'." >&2
            echo "Use '-s list' to see available modes." >&2
            exit 1
            ;;
    esac

    if ! cd -P "$TARGET_DIR"; then
        echo "Error: Could not access directory '$TARGET_DIR'" >&2
        exit 1
    fi
    CURRENT_DIR="$PWD"

    echo "Starting slideshow in '$CURRENT_DIR' with '$SLIDESHOW_MODE' mode."
    kill_existing_slideshow
    # This function takes over the current process and becomes the daemon.
    run_slideshow "$CURRENT_DIR" "$SLIDESHOW_MODE"

# Otherwise, run in interactive rofi mode.
else
    # Ensure only one interactive instance runs at a time using a PID file lock.
    if [ -f "$PID_FILE" ]; then
        OLD_PID=$(cat "$PID_FILE")
        if [ -n "$OLD_PID" ] && kill -0 "$OLD_PID" 2>/dev/null; then
            if [ "$OLD_PID" != $$ ]; then
                kill "$OLD_PID"
                sleep 0.1
            fi
        fi
    fi
    echo $$ > "$PID_FILE"
    trap 'rm -f "$PID_FILE"' INT TERM EXIT

    if ! cd -P "$TARGET_DIR"; then
        rofi -e "Error: Could not access directory '$TARGET_DIR'"
        exit 1
    fi
    CURRENT_DIR="$PWD"

    # Launch rofi and get the user's selection.
    SELECTION=$(print_rofi_menu | rofi -dmenu -i -no-config -show-icons -format s -p " wallpaper" -theme "$ROFI_THEME")

    case "$SELECTION" in
        "") exit 0 ;;

        "..")
            rm -f "$PID_FILE" # Remove lock before executing
            exec "$SCRIPT_PATH" --dir "$(dirname "$CURRENT_DIR")"
            ;;

        "Stop Slideshow")
            kill_existing_slideshow
            exit 0
            ;;

        "Slideshow")
            CHOSEN_ORDER=$(rofi -dmenu -i -p "Order" -selected-row 0 <<EOF
Shuffle
Alphabetical Order
Newer First
Older First
EOF
            )

            case "$CHOSEN_ORDER" in
                "Shuffle")            ORDER_ARG="shuffle" ;;
                "Alphabetical Order") ORDER_ARG="alpha" ;;
                "Newer First")        ORDER_ARG="newerFirst" ;;
                "Older First")        ORDER_ARG="olderFirst" ;;
                *)                    exit 0 ;;
            esac

            kill_existing_slideshow
            run_slideshow "$CURRENT_DIR" "$ORDER_ARG"
            ;;

        *)
            if [ -d "$SELECTION" ]; then
                rm -f "$PID_FILE" # Remove lock before executing
                exec "$SCRIPT_PATH" --dir "$CURRENT_DIR/$SELECTION"
            elif [ -f "$SELECTION" ]; then
                kill_existing_slideshow
                swaybg -i "$CURRENT_DIR/$SELECTION" -m "$IMAGE_MODE" &
                write_state "$CURRENT_DIR" "single" "$CURRENT_DIR/$SELECTION" ""
                exit 0
            else
                rofi -e "Error: Selection '$SELECTION' not found."
                exit 1
            fi
            ;;
    esac
fi
