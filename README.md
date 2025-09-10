# Systemd Outage Notifier

A simple shell script that monitors systemd units and sends notifications via ntfy when it detects failed or degraded services.

## Features

- Monitors systemd units for failed or degraded states
- Sends detailed notifications including unit status via ntfy
- Configurable notification endpoint
- High priority notifications with warning tags

## Prerequisites

- zsh shell
- systemd
- curl
- An ntfy server or subscription (for notifications)

## Setup

1. Clone this repository
2. Make the script executable:
   ```bash
   chmod +x ntfy_sydtemd_outages.sh
   ```

## Usage

Run the script manually by passing your ntfy url/topic as an argument:
```bash
./ntfy_sydtemd_outages.sh ntfy.sh/your-topic
```

To test without sending notifications, use 'print':
```bash
./ntfy_sydtemd_outages.sh print
```

For automated monitoring, set up a cron job or systemd timer.

Example crontab entry (check every 5 minutes):
```
*/5 * * * * /path/to/ntfy_sydtemd_outages.sh ntfy.sh/your-topic
```

## Notifications

When a problematic unit is detected, you'll receive a notification with:
- Unit name
- Current status
- Detailed information from systemctl
- High priority flag
- Warning tag for visibility

## License

GPLv3

## Contributing

Feel free to open issues or submit pull requests for improvements.
