#!/bin/bash
# Wrapper to start Claude with terminal communication environment variables

# Export the variables that should have been set
export CLAUDE_SESSION_ID="${CLAUDE_SESSION_ID:-$$}"
export CLAUDE_TERMINAL_NAME="${CLAUDE_TERMINAL_NAME}"

# Start Claude Code
exec claude "$@"
