#!/bin/bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=validate.sh
source "${SCRIPT_DIR}/validate.sh"

if [[ $# -ne 1 ]]; then
    echo "Usage: $0 <command>" >&2
    exit 1
fi

COMMAND="$1"

validate_command_length "$COMMAND"
validate_command_safety "$COMMAND"
log_execution "$COMMAND"
execute_restricted "$COMMAND"
