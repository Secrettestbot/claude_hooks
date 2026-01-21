#!/bin/bash
# Auto-accept trust dialogs for spawned terminals
# Usage: auto-accept-trust.sh <terminal_name>

TERM_NAME="$1"

# Wait for Claude to start and show the trust dialog
# Give it enough time for the dialog to fully render
sleep 4

# Send Enter to accept the dialog multiple times with small delays
# This handles timing variations and ensures acceptance
for i in {1..3}; do
  # Try all possible window locations
  tmux send-keys -t "claude-T1:0" Enter 2>/dev/null
  tmux send-keys -t "claude-T1:1" Enter 2>/dev/null
  tmux send-keys -t "claude-$TERM_NAME:0" Enter 2>/dev/null
  sleep 0.5
done

exit 0
