#!/bin/zsh

# Check if NTFY_URL is set
if [[ -z "${NTFY_URL}" ]]; then
    echo "Error: NTFY_URL environment variable is not set"
    exit 1
fi

# Get failed/degraded units
failed_units=$(systemctl list-units --state=failed,degraded --no-legend --plain)

if [[ -n "$failed_units" ]]; then
    # Format the message
    message="System Alert: Problematic systemd units detected\n\n"
    while IFS= read -r unit; do
        unit_name=$(echo "$unit" | awk '{print $1}')
        unit_status=$(systemctl status "$unit_name" --no-pager | head -n 3)
        message+="Unit: $unit_name\n$unit_status\n\n"
    done <<< "$failed_units"

    # Send notification via ntfy
    curl -H "Priority: high" \
         -H "Tags: warning" \
         -d "$message" \
         "$NTFY_URL"
fi
