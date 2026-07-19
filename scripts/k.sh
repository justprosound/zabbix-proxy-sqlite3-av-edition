#!/bin/bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=validate.sh
source "${SCRIPT_DIR}/validate.sh"

# Input validation
if [[ $# -eq 0 ]]; then
    echo "Usage: $0 <kubectl-command> [args...]" >&2
    exit 1
fi

# Security: Validate kubectl is available
validate_tool_exists "kubectl"

# Security: Validate kubectl operation
KUBECTL_CMD="$1"
validate_kubectl_operation "$KUBECTL_CMD"

# Execute with timeout to prevent hanging
execute_with_timeout 30 kubectl "$@"
