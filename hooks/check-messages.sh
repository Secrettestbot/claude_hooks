#!/bin/bash
# Manually check for pending messages in the current terminal

source "$HOME/.claude/hooks/terminal-comm-lib.sh"

if ! is_comm_enabled; then
  echo "Terminal communication is not enabled for this session."
  echo "Enable it by telling Claude: 'Enable terminal communication as <name>'"
  exit 1
fi

TERMINAL_NAME=$(get_terminal_name)
MESSAGE_COUNT=$(get_message_count)

if [[ "$MESSAGE_COUNT" -eq 0 ]]; then
  echo "No pending messages for terminal: $TERMINAL_NAME"
  exit 0
fi

echo "========================================"
echo "  Messages for: $TERMINAL_NAME"
echo "========================================"
echo ""
echo "📨 You have $MESSAGE_COUNT pending message(s):"
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
check_messages
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
