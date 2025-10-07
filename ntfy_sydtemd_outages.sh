#!/bin/zsh

NTFY_URLTOPIC=$1
NTFY_TITLE="Systemd Failed Notifier"
# Default exclusions
EXCLUDE_UNITS="pulseaudio,systemd-suspend,tracker-miner-fs"
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

# Initialize message and counter for combined notification
message=""
unit_count=0

# Get failed/degraded system units
failed_units=$(systemctl list-units --state=failed,degraded --no-legend --plain)

if [[ -n "$failed_units" ]]; then
    # Add system units section if there are any
    message+="=== System Units ===\r\r"
    
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
        unit_count=$((unit_count + 1))
    done <<< "$failed_units"
fi

# Get failed/degraded user units
failed_units=$(systemctl --user list-units --state=failed,degraded --no-legend --plain)

if [[ -n "$failed_units" ]]; then
    # Add user units section if there are any
    message+="\r=== User Units ===\r\r"
    
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
        unit_count=$((unit_count + 1))
    done <<< "$failed_units"
fi

# Send a single notification if there are any units to report
if [[ $unit_count -gt 0 ]]; then
    if [[ "$NTFY_URLTOPIC" == "print" ]]; then
        echo "$message"
    else
        apprise --title "$unit_count Systemd Outage(s)" --body "$message" "ntfys://$NTFY_URLTOPIC"
    fi
fi
