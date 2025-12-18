#!/bin/bash
set -euo pipefail

# Security: Log all command executions for audit trail
readonly LOGFILE="${PASS_TO_SHELL_LOGFILE:-/var/log/zabbix/shell-commands.log}"
readonly MAX_CMD_LENGTH=1024

# Input validation
if [[ $# -ne 1 ]]; then
    echo "Usage: $0 <command>" >&2
    exit 1
fi

COMMAND="$1"

# Validate command length
if [[ ${#COMMAND} -gt $MAX_CMD_LENGTH ]]; then
    echo "Error: Command too long (max $MAX_CMD_LENGTH characters)" >&2
    exit 1
fi

# Normalize whitespace to single spaces for reliable matching
COMMAND=$(echo "$COMMAND" | tr -s ' ')

# Security: Block dangerous commands
# Using regex to catch variants
readonly BLOCKED_Patterns=(
    "rm[[:space:]]+.*-rf"
    "dd[[:space:]]+if="
    "mkfs"
    "fdisk"
    "parted"
    "crontab"
    "sudo"
    "su[[:space:]]+-"
    "passwd"
    "userdel"
    "usermod"
    "chmod[[:space:]]+777"
    "chown[[:space:]]+root"
)

for pattern in "${BLOCKED_Patterns[@]}"; do
    if [[ "$COMMAND" =~ $pattern ]]; then
        echo "Error: Blocked command detected: $pattern" >&2
        echo "$(date): BLOCKED: $COMMAND" >> "$LOGFILE" 2>/dev/null
        exit 1
    fi
done

# Log command execution (best effort, don't fail if logging fails)
echo "$(date): EXEC: $COMMAND" >> "$LOGFILE" 2>/dev/null

# Execute with restricted environment
exec env -i PATH="/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin" bash -c "$COMMAND"
