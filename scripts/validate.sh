#!/bin/bash
# validate.sh - Shared validation functions for Zabbix external scripts
# Provides common input validation, command blocking, and logging utilities
set -euo pipefail

# Constants
readonly VALIDATE_MAX_CMD_LENGTH=1024
readonly VALIDATE_MAX_MESSAGE_LENGTH=4096
readonly VALIDATE_MAX_HOST_LENGTH=253
readonly VALIDATE_LOGFILE="${PASS_TO_SHELL_LOGFILE:-/var/log/zabbix/shell-commands.log}"

# Block list: dangerous shell patterns (regex)
readonly VALIDATE_BLOCKED_PATTERNS=(
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

# Block list: dangerous kubectl operations
readonly VALIDATE_BLOCKED_KUBECTL=(
    "delete"
    "create"
    "apply"
    "replace"
    "patch"
    "edit"
    "exec"
    "proxy"
    "port-forward"
)

# Allow list: safe kubectl operations
readonly VALIDATE_ALLOWED_KUBECTL=(
    "get"
    "describe"
    "logs"
    "top"
    "version"
    "cluster-info"
    "config"
    "api-resources"
    "api-versions"
)

# --- Validation Functions ---

# Validate command is not too long
validate_command_length() {
    local cmd="$1"
    local max_length="${2:-$VALIDATE_MAX_CMD_LENGTH}"
    
    if [[ ${#cmd} -gt "$max_length" ]]; then
        echo "Error: Command too long (max $max_length characters)" >&2
        return 1
    fi
    return 0
}

# Validate message is not too long
validate_message_length() {
    local message="$1"
    local max_length="${2:-$VALIDATE_MAX_MESSAGE_LENGTH}"
    
    if [[ ${#message} -gt "$max_length" ]]; then
        echo "Error: Message too long (max $max_length characters)" >&2
        return 1
    fi
    return 0
}

# Validate hostname/IP (basic check)
validate_hostname() {
    local host="$1"
    
    if [[ -z "$host" ]] || [[ ${#host} -gt "$VALIDATE_MAX_HOST_LENGTH" ]]; then
        echo "Error: Invalid hostname" >&2
        return 1
    fi
    return 0
}

# Validate port is numeric and in valid range
validate_port() {
    local port="$1"
    
    if ! [[ "$port" =~ ^[0-9]+$ ]] || [[ "$port" -lt 1 ]] || [[ "$port" -gt 65535 ]]; then
        echo "Error: Port must be a number between 1 and 65535" >&2
        return 1
    fi
    return 0
}

# Validate command against block list (shell commands)
validate_command_safety() {
    local cmd="$1"
    
    # Normalize whitespace
    cmd=$(echo "$cmd" | tr -s ' ')
    
    for pattern in "${VALIDATE_BLOCKED_PATTERNS[@]}"; do
        if [[ "$cmd" =~ $pattern ]]; then
            echo "Error: Blocked command detected: $pattern" >&2
            log_command "BLOCKED" "$cmd"
            return 1
        fi
    done
    return 0
}

# Validate kubectl command against block list
validate_kubectl_operation() {
    local operation="$1"
    
    # Check blocked operations
    for blocked in "${VALIDATE_BLOCKED_KUBECTL[@]}"; do
        if [[ "$operation" == "$blocked" ]]; then
            echo "Error: kubectl $blocked operation is not permitted for security reasons" >&2
            return 1
        fi
    done
    
    # Check allow list
    local found=false
    for allowed in "${VALIDATE_ALLOWED_KUBECTL[@]}"; do
        if [[ "$operation" == "$allowed" ]]; then
            found=true
            break
        fi
    done
    
    if [[ "$found" == "false" ]]; then
        echo "Error: kubectl $operation operation is not in the allowed list" >&2
        echo "Allowed operations: ${VALIDATE_ALLOWED_KUBECTL[*]}" >&2
        return 1
    fi
    
    return 0
}

# Validate tool is available
validate_tool_exists() {
    local tool="$1"
    
    if ! command -v "$tool" >/dev/null 2>&1; then
        echo "Error: $tool not found" >&2
        return 1
    fi
    return 0
}

# --- Logging Functions ---

# Log command execution
log_command() {
    local action="$1"
    local command="$2"
    
    echo "$(date): $action: $command" >> "$VALIDATE_LOGFILE" 2>/dev/null || true
}

# Log execution (for pass-to-shell.sh)
log_execution() {
    local command="$1"
    
    log_command "EXEC" "$command"
}

# --- Utility Functions ---

# Execute command with timeout
execute_with_timeout() {
    local timeout_seconds="$1"
    shift
    
    timeout "$timeout_seconds" "$@"
}

# Execute command in restricted environment
execute_restricted() {
    local command="$1"
    
    exec env -i PATH="/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin" bash -c "$command"
}
