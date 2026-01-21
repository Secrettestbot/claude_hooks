#!/bin/bash
# Enable terminal communication for this Claude Code session
# Usage: terminal-comm-enable.sh <terminal_name>

# Source the library
source "$HOME/.claude/hooks/terminal-comm-lib.sh"

# Check arguments
if [[ -z "$1" ]]; then
  echo "Error: Terminal name required" >&2
  echo "Usage: $0 <terminal_name>" >&2
  exit 1
fi

TERMINAL_NAME="$1"

# Use PPID as session ID and store it
SESSION_ID="$PPID"
export CLAUDE_SESSION_ID="$SESSION_ID"
export CLAUDE_TERMINAL_NAME="$TERMINAL_NAME"

CONFIG_FILE="$SESSIONS_DIR/${SESSION_ID}.json"

# Create session config
jq -n --arg name "$TERMINAL_NAME" \
      --arg sid "$SESSION_ID" \
      '{
        enabled: true,
        name: $name,
        session_id: $sid,
        enabled_at: (now | strftime("%Y-%m-%dT%H:%M:%SZ"))
      }' > "$CONFIG_FILE"

# Output export command for the user to run
echo "export CLAUDE_SESSION_ID=$SESSION_ID" > "$HOME/.claude/terminal-comm/env_export.sh"

# Register in the shared registry
register_terminal "$TERMINAL_NAME"

echo "✓ Terminal communication enabled"
echo "  Terminal name: $TERMINAL_NAME"
echo "  Session ID: $SESSION_ID"
echo ""

# Show other active terminals
list_terminals

return 0
