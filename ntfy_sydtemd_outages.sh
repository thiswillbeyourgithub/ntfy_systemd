#!/bin/zsh

NTFY_TOPIC=$1
NTFY_TITLE="Systemd Failed Notifier"
# Default exclusions
EXCLUDE_UNITS="pulseaudio"

if [[ -z "$NTFY_TOPIC" ]]
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
    done <<< "$failed_units"

    if [[ "$NTFY_TOPIC" == "print" ]]
    then
        echo "$message"
    else
        ntfy publish --quiet --priority=high --tags=warning $NTFY_TOPIC "$message"
    fi
fi


# now same for user units
failed_units=$(systemctl --user list-units --state=failed,degraded --no-legend --plain)

if [[ -n "$failed_units" ]]; then
    # Format the message
    message="Problematic systemd user units detected\n\n"
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
    done <<< "$failed_units"

    if [[ "$NTFY_TOPIC" == "print" ]]
    then
        echo "$message"
    else
        ntfy publish --quiet --priority=high --tags=warning $NTFY_TOPIC "$message"
    fi
fi
