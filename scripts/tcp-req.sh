#!/bin/bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=validate.sh
source "${SCRIPT_DIR}/validate.sh"

if [[ $# -ne 3 ]]; then
    echo "Usage: $0 <message> <host> <port>" >&2
    exit 1
fi

MESSAGE="$1"
HOST="$2"
PORT="$3"

validate_message_length "$MESSAGE"
validate_hostname "$HOST"
validate_port "$PORT"
validate_tool_exists "nc"

echo -n "$MESSAGE" | timeout 5 nc -w1 "$HOST" "$PORT"
exit_code=$?

if [[ $exit_code -eq 124 ]]; then
    echo "Error: Connection timed out" >&2
    exit 1
elif [[ $exit_code -ne 0 ]]; then
    echo "Error: Connection failed" >&2
    exit 1
fi
