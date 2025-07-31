#!/bin/sh

##
# Maps an application name to a Nerd Font glyph.
# Customize the icons for your applications here.
#
# @param $1 - The application name string.
# @return   - The corresponding Nerd Font glyph.
##
getIconForApp() {
    local appNameLower
    appNameLower=$(command printf "%s" "$1" | command tr '[:upper:]' '[:lower:]')

    case "$appNameLower" in
        *google*) command printf "";;
        *youtube*) command printf "󰗃";;
        *firefox*|*librewolf*|*floorp*) command printf "";;
        *chrom*|*brave*) command printf "";;
        *terminal*|*kitty*|*wezterm*|*alacritty*|*foot*) command printf "";;
        *discord*) command printf "󰙯";;
        *slack*) command printf "";;
        *telegram*) command printf "";;
        *thunderbird*|*geary*|*mail*) command printf "";;
        *spotify*) command printf "";;
        *mpd*|*ncmpcpp*) command printf "󰼄";;
        *nemo*|*thunar*|*files*|*nautilus*) command printf "";;
        *code*|*vscode*|*vscodium*) command printf "";;
        notify-send) command printf "";;
        *) command printf "";; # Default fallback icon
    esac
}

##
# Reads notification data and generates lists for rofi's active/urgent rows.
# Mako urgencies: 'low', 'normal', 'critical'. We'll treat 'low'/'normal' as active.
#
# @param $1 - The tab-separated notification data.
##
generateRofiLists() {
    local notificationData="$1"
    local count=0
    activeList=""
    urgentList=""

    # The 5th field in our data is the urgency level
    command printf "%s\n" "$notificationData" | while IFS=$(printf '\t') read -r _id _appName _summary _body urgency; do
        case "$urgency" in
            low|normal) activeList="${activeList}${activeList:+,}$count";;
            critical) urgentList="${urgentList}${urgentList:+,}$count";;
        esac
        count=$((count + 1))
    done
}

##
# Processes tab-separated data into a single string formatted for rofi.
#
# @param $1 - The tab-separated notification data.
# @return   - A formatted string with entries separated by '\x0f'.
##
processLogEntries() {
    local notificationData="$1"
    
    command printf "%s\n" "$notificationData" | while IFS=$(printf '\t') read -r id appName summary _body _urgency; do
        local iconGlyph summaryEsc bodyEsc appLine

        iconGlyph=$(getIconForApp "$appName")
        summaryEsc=$(command printf "%s" "$summary" | command sed 's/&/\&amp;/g; s/</\&lt;/g; s/>/\&gt;/g;')
        # Embed the notification ID in a non-visible Pango markup comment
        bodyEsc=$(command printf "<!-- %s -->" "$id")
        appLine=$(command printf "%s <b>%s</b>" "$iconGlyph" "$appName")

        command printf "%s\n%s\n%s\x0f" "$appLine" "$summaryEsc" "$bodyEsc"
    done
}

##
# Handles the user's action on a selected notification.
# Prompts the user via rofi to confirm dismissal.
#
# @param $1 - The notification string selected from rofi.
##
handleSelectedNotification() {
    local selectedEntry="$1"
    local notificationId

    # Extract the hidden ID from the Pango markup comment
    notificationId=$(command printf "%s" "$selectedEntry" | command sed -n 's/.*<!-- \([0-9]\{1,\}\) -->.*/\1/p')

    if [ -z "$notificationId" ]; then
        return 1 # Exit if ID extraction fails
    fi

    # Use rofi to create a confirmation dialog
    local choice
    choice=$(command printf "Cancel\nDismiss" | command rofi -dmenu -i -p "Action for ID ${notificationId}:" -lines 2 -no-custom)

    case "$choice" in
        Dismiss)
            command makoctl dismiss -n "$notificationId"
            ;;
        *)
            # Do nothing if "Cancel" or anything else is chosen
            ;;
    esac
}

##
# Main execution function.
##
main() {
    # Default mode is to list active notifications.
    # Accepts 'history' as an argument to view historical notifications.
    local mode="list"
    if [ "$1" = "history" ]; then
        mode="history"
    fi

    local ERR_NO_NOTIFICATIONS="makoRofi: no notifications"

    # Use awk to parse the plain text output of `makoctl list` or `makoctl history`
    # into a consistent, tab-separated format: ID\tAppName\tSummary\tBody\tUrgency
    local notificationData
    notificationData=$(command makoctl "$mode" | command awk '
        # This awk script is written to be POSIX-compliant.
        function print_record() {
            if (id) {
                # Print the captured data, with an empty field for body
                printf "%s\t%s\t%s\t\t%s\n", id, app, sum, urg
            }
        }
        /^Notification/ {
            print_record() # Print the previous record before starting a new one
            
            # POSIX-compliant parsing for: Notification ID: Summary
            id = $2
            sub(/:$/, "", id)
            sum = $3
            for (i = 4; i <= NF; i++) { sum = sum " " $i }
        }
        /App name:/ { sub(/^.*App name: /, ""); app = $0 }
        /Urgency:/ { sub(/^.*Urgency: /, ""); urg = $0 }
        END { print_record() } # Print the very last record
    ')

    # Filter out our own "no notifications" message, in case it was historized.
    # Use -F for fixed string matching, which is safer and faster.
    notificationData=$(command printf "%s\n" "$notificationData" | command grep -vF "$ERR_NO_NOTIFICATIONS")

    # Exit if there are no notifications
    if [ -z "$notificationData" ]; then
        echo "No notifications in '$mode' view."
        # Send a notification that the view is empty, regardless of mode.
        notify-send -u low -et 1000 "$ERR_NO_NOTIFICATIONS"
        return 0
    fi

    generateRofiLists "$notificationData"
    
    local rofiEntries
    rofiEntries=$(processLogEntries "$notificationData")

    local selectedEntry
    selectedEntry=$(command printf "%s" "$rofiEntries" | command rofi -markup-rows \
        -dmenu -eh 2 -a "$activeList" -u "$urgentList" \
        -sep '\x0f' -p "Notification Center ($mode)" -no-fixed-num-lines \
        -lines 8 -i -no-config)

    if [ -n "$selectedEntry" ]; then
        handleSelectedNotification "$selectedEntry"
    fi
}

# Run the script with all arguments passed from the command line
main "$@"
