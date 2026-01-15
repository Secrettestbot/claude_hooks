#!/bin/bash
# Send a message to another terminal
# Usage: terminal-comm-send.sh <to_terminal> <message>

# Source the library
source "$HOME/.claude/hooks/terminal-comm-lib.sh"

# Check if communication is enabled
if ! is_comm_enabled; then
  echo "Error: Terminal communication is not enabled for this session" >&2
  echo "Enable it first by telling Claude: 'Enable terminal communication as <name>'" >&2
  exit 1
fi

# Check arguments
if [[ -z "$1" ]] || [[ -z "$2" ]]; then
  echo "Error: Missing arguments" >&2
  echo "Usage: $0 <to_terminal> <message>" >&2
  exit 1
fi

TO_TERMINAL="$1"
MESSAGE="$2"

# Send the message
send_message "$TO_TERMINAL" "$MESSAGE"

exit 0
