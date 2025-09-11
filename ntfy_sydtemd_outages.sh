#!/bin/zsh

NTFY_URLTOPIC=$1
NTFY_TITLE="Systemd Failed Notifier"
# Default exclusions
EXCLUDE_UNITS="pulseaudio,systemd-suspend"
#EXCLUDE_UNITS="pulseaudio,bluetooth"

if [[ -z "$NTFY_URLTOPIC" ]]
then
    echo "You need to pass in a ntfy topic as argument or 'print' to just echo the output"
    exit 1
fi

# Check for exclusion parameter
if [[ "$2" == "--exclude" && -n "$3" ]]; then
    EXCLUDE_UNITS="$3"
fi

# Get failed/degraded units
failed_units=$(systemctl list-units --state=failed,degraded --no-legend --plain)

if [[ -n "$failed_units" ]]; then
    # Format the message
    message="Problematic systemd units detected\n\n"
    has_units_to_report=0
    
    while IFS= read -r unit; do
        unit_name=$(echo "$unit" | awk '{print $1}')
        
        # Skip excluded units
        skip=0
        for exclude in ${(s:,:)EXCLUDE_UNITS}; do
            if [[ "$unit_name" == *"$exclude"* ]]; then
                skip=1
                break
            fi
        done
        
        if [[ $skip -eq 1 ]]; then
            continue
        fi
        
        unit_status=$(systemctl status "$unit_name" --no-pager | head -n 3)
        message+="Unit: $unit_name
$unit_status

"
        has_units_to_report=1
    done <<< "$failed_units"

    # Only send notification if there are actual units to report
    if [[ $has_units_to_report -eq 1 ]]; then
        if [[ "$NTFY_URLTOPIC" == "print" ]]; then
            echo "$message"
        else
            apprise --title "Systemd outage" --body "$message" "ntfys://$NTFY_URLTOPIC"
        fi
    fi
fi


# now same for user units
failed_units=$(systemctl --user list-units --state=failed,degraded --no-legend --plain)

if [[ -n "$failed_units" ]]; then
    # Format the message
    message="Problematic systemd user units detected\n\n"
    has_units_to_report=0
    
    while IFS= read -r unit; do
        unit_name=$(echo "$unit" | awk '{print $1}')
        
        # Skip excluded units
        skip=0
        for exclude in ${(s:,:)EXCLUDE_UNITS}; do
            if [[ "$unit_name" == *"$exclude"* ]]; then
                skip=1
                break
            fi
        done
        
        if [[ $skip -eq 1 ]]; then
            continue
        fi
        
        unit_status=$(systemctl --user status "$unit_name" --no-pager | head -n 3)
        message+="Unit: $unit_name
$unit_status

"
        has_units_to_report=1
    done <<< "$failed_units"

    # Only send notification if there are actual units to report
    if [[ $has_units_to_report -eq 1 ]]; then
        if [[ "$NTFY_URLTOPIC" == "print" ]]; then
            echo "$message"
        else
            apprise --title "Systemd outage" --body "$message" "ntfys://$NTFY_URLTOPIC"
        fi
    fi
fi
