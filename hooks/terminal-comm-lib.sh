#!/bin/bash
# Terminal Communication Library for Claude Code
# Provides core functions for inter-terminal messaging

COMM_DIR="$HOME/.claude/terminal-comm"
SESSIONS_DIR="$COMM_DIR/sessions"
MESSAGES_DIR="$COMM_DIR/messages"
REGISTRY_FILE="$COMM_DIR/terminals.json"

# ===== SESSION MANAGEMENT =====

# Get unique session ID for this Claude instance
get_session_id() {
  # First check if CLAUDE_SESSION_ID env var is set (most reliable)
  if [[ -n "$CLAUDE_SESSION_ID" ]]; then
    echo "$CLAUDE_SESSION_ID"
    return 0
  fi

  # Fall back to PPID (parent process ID) as session identifier
  echo "$PPID"
}

# Get session config file path
get_session_config() {
  local session_id=$(get_session_id)
  echo "$SESSIONS_DIR/${session_id}.json"
}

# Check if terminal communication is enabled for this session
is_comm_enabled() {
  local config_file=$(get_session_config)

  # Check session config file first
  if [[ -f "$config_file" ]]; then
    local enabled=$(jq -r '.enabled // false' "$config_file" 2>/dev/null)
    [[ "$enabled" == "true" ]] && return 0
  fi

  # Fall back to environment variable
  [[ "$CLAUDE_TERMINAL_COMM" == "enabled" ]] && return 0

  return 1
}

# Get terminal name for this session
get_terminal_name() {
  local config_file=$(get_session_config)

  # Check session config file first
  if [[ -f "$config_file" ]]; then
    local name=$(jq -r '.name // empty' "$config_file" 2>/dev/null)
    [[ -n "$name" ]] && echo "$name" && return 0
  fi

  # Fall back to environment variable
  if [[ -n "$CLAUDE_TERMINAL_NAME" ]]; then
    echo "$CLAUDE_TERMINAL_NAME"
    return 0
  fi

  return 1
}

# ===== REGISTRY MANAGEMENT =====

# Initialize registry if it doesn't exist
init_registry() {
  if [[ ! -f "$REGISTRY_FILE" ]]; then
    echo '{"terminals":[]}' > "$REGISTRY_FILE"
  fi
}

# Register this terminal in the shared registry
register_terminal() {
  local name="$1"
  local session_id=$(get_session_id)
  local timestamp=$(date -u +"%Y-%m-%dT%H:%M:%SZ")

  init_registry

  # Remove any existing entry with same session_id or name
  local temp_file=$(mktemp)
  jq --arg sid "$session_id" --arg name "$name" \
    '.terminals |= map(select(.session_id != $sid and .name != $name))' \
    "$REGISTRY_FILE" > "$temp_file" && mv "$temp_file" "$REGISTRY_FILE"

  # Add new entry
  jq --arg sid "$session_id" \
     --arg name "$name" \
     --arg ts "$timestamp" \
     --arg pid "$$" \
     '.terminals += [{"session_id": $sid, "name": $name, "pid": $pid, "registered_at": $ts}]' \
     "$REGISTRY_FILE" > "$temp_file" && mv "$temp_file" "$REGISTRY_FILE"
}

# Unregister this terminal from the registry
unregister_terminal() {
  local session_id=$(get_session_id)

  if [[ ! -f "$REGISTRY_FILE" ]]; then
    return 0
  fi

  local temp_file=$(mktemp)
  jq --arg sid "$session_id" \
    '.terminals |= map(select(.session_id != $sid))' \
    "$REGISTRY_FILE" > "$temp_file" && mv "$temp_file" "$REGISTRY_FILE"
}

# Clean up stale terminals (registered more than 24 hours ago)
cleanup_stale_terminals() {
  if [[ ! -f "$REGISTRY_FILE" ]]; then
    return 0
  fi

  local cutoff_time=$(date -u -d '24 hours ago' +"%Y-%m-%dT%H:%M:%SZ" 2>/dev/null || date -u -v-24H +"%Y-%m-%dT%H:%M:%SZ" 2>/dev/null)

  local temp_file=$(mktemp)
  jq --arg cutoff "$cutoff_time" \
    '.terminals |= map(select(.registered_at > $cutoff))' \
    "$REGISTRY_FILE" > "$temp_file" && mv "$temp_file" "$REGISTRY_FILE"
}

# List all active terminals
list_terminals() {
  cleanup_stale_terminals

  if [[ ! -f "$REGISTRY_FILE" ]]; then
    echo "No active terminals"
    return 0
  fi

  local count=$(jq '.terminals | length' "$REGISTRY_FILE" 2>/dev/null)
  if [[ "$count" == "0" ]]; then
    echo "No active terminals"
    return 0
  fi

  echo "Active terminals:"
  jq -r '.terminals[] | "  • \(.name) (session: \(.session_id), registered: \(.registered_at))"' "$REGISTRY_FILE"
}

# Get session_id for a terminal by name
get_terminal_session_id() {
  local name="$1"

  if [[ ! -f "$REGISTRY_FILE" ]]; then
    return 1
  fi

  jq -r --arg name "$name" \
    '.terminals[] | select(.name == $name) | .session_id' \
    "$REGISTRY_FILE" 2>/dev/null
}

# ===== MESSAGE MANAGEMENT =====

# Send a message to another terminal
send_message() {
  local to_terminal="$1"
  local message="$2"
  local from_terminal=$(get_terminal_name)
  local from_session=$(get_session_id)

  if [[ -z "$from_terminal" ]]; then
    echo "Error: This terminal is not registered for communication" >&2
    return 1
  fi

  # Get recipient session ID
  local to_session=$(get_terminal_session_id "$to_terminal")
  if [[ -z "$to_session" ]]; then
    echo "Error: Terminal '$to_terminal' not found in registry" >&2
    return 1
  fi

  # Create message file
  local timestamp=$(date -u +"%Y-%m-%dT%H:%M:%SZ")
  local message_id="${from_session}_${to_session}_$(date +%s%N)"
  local message_file="$MESSAGES_DIR/${message_id}.json"

  jq -n --arg from "$from_terminal" \
        --arg from_sid "$from_session" \
        --arg to "$to_terminal" \
        --arg to_sid "$to_session" \
        --arg msg "$message" \
        --arg ts "$timestamp" \
        --arg mid "$message_id" \
        '{
          message_id: $mid,
          from: $from,
          from_session_id: $from_sid,
          to: $to,
          to_session_id: $to_sid,
          message: $msg,
          timestamp: $ts,
          delivered: false
        }' > "$message_file"

  echo "Message sent to $to_terminal"
}

# Check for messages addressed to this terminal
check_messages() {
  local session_id=$(get_session_id)
  local terminal_name=$(get_terminal_name)

  if [[ -z "$terminal_name" ]]; then
    return 0
  fi

  local messages=()

  # Find all message files for this session
  for msg_file in "$MESSAGES_DIR"/*.json; do
    [[ ! -f "$msg_file" ]] && continue

    local to_session=$(jq -r '.to_session_id // empty' "$msg_file" 2>/dev/null)

    if [[ "$to_session" == "$session_id" ]]; then
      messages+=("$msg_file")
    fi
  done

  # Return message content
  if [[ ${#messages[@]} -gt 0 ]]; then
    for msg_file in "${messages[@]}"; do
      local from=$(jq -r '.from' "$msg_file")
      local message=$(jq -r '.message' "$msg_file")
      local timestamp=$(jq -r '.timestamp' "$msg_file")

      echo "[$timestamp] Message from $from: $message"

      # Mark as delivered and delete
      rm -f "$msg_file"
    done
    return 0
  fi

  return 1
}

# Get count of pending messages
get_message_count() {
  local session_id=$(get_session_id)
  local count=0

  for msg_file in "$MESSAGES_DIR"/*.json; do
    [[ ! -f "$msg_file" ]] && continue

    local to_session=$(jq -r '.to_session_id // empty' "$msg_file" 2>/dev/null)
    if [[ "$to_session" == "$session_id" ]]; then
      ((count++))
    fi
  done

  echo "$count"
}
