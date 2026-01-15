#!/bin/bash
# Disable terminal communication for this Claude Code session

# Source the library
source "$HOME/.claude/hooks/terminal-comm-lib.sh"

SESSION_ID=$(get_session_id)
CONFIG_FILE=$(get_session_config)
TERMINAL_NAME=$(get_terminal_name)

# Unregister from shared registry
unregister_terminal

# Remove session config
if [[ -f "$CONFIG_FILE" ]]; then
  rm -f "$CONFIG_FILE"
fi

if [[ -n "$TERMINAL_NAME" ]]; then
  echo "✓ Terminal communication disabled for: $TERMINAL_NAME"
else
  echo "✓ Terminal communication disabled"
fi

exit 0
