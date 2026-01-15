#!/bin/bash
# Check for incoming messages for this terminal

# Source the library
source "$HOME/.claude/hooks/terminal-comm-lib.sh"

# Check if communication is enabled
if ! is_comm_enabled; then
  exit 0
fi

# Check for messages
check_messages

exit 0
