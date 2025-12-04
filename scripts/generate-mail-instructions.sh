#!/usr/bin/env bash
set -euo pipefail

if [[ $# -ne 1 ]]; then
    echo "Usage: $0 <username>"
    echo "Example: $0 alice"
    exit 1
fi

USERNAME="$1"
EMAIL="${USERNAME}@clan.lol"

# Get password using clan vars
PASSWORD=$(clan vars get web01 "${USERNAME}-mail/${USERNAME}-password" 2>/dev/null)

if [[ -z "$PASSWORD" ]]; then
    echo "Error: Could not retrieve password for user ${USERNAME}"
    echo "Make sure the user exists and secrets have been generated."
    echo "Try running: clan vars generate web01"
    exit 1
fi

cat <<EOF
EMAIL ACCOUNT INSTRUCTIONS

ACCOUNT DETAILS:
----------------
Email Address: ${EMAIL}
Password:      ${PASSWORD}

SERVER SETTINGS:
----------------
Incoming Mail (IMAP):
  Server:   mail.clan.lol
  Port:     993 (SSL/TLS)
  Username: ${EMAIL}

Incoming Mail (POP3):
  Server:   mail.clan.lol
  Port:     995 (SSL/TLS)
  Username: ${EMAIL}

Outgoing Mail (SMTP):
  Server:   mail.clan.lol
  Port:     465 (SSL/TLS)
  Username: ${EMAIL}
  Authentication: Required

AUTO-CONFIGURATION:
-------------------
Many email clients support automatic configuration.
Simply enter your email address (${EMAIL}) and password.
The client should detect the settings automatically via:
https://clan.lol/.well-known/autoconfig/mail/config-v1.1.xml

SECURITY NOTES:
---------------
- Your password is randomly generated for security
- Please store it in a password manager
- All connections use implicit TLS (SSL/TLS from connection start)
- Modern email clients automatically configure these ports
EOF
