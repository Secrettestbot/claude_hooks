#!/bin/bash
# PreToolUse hook - Smart tool execution control
# Auto-approves safe tools, blocks dangerous operations, adds safety checks
# Checks for inter-terminal messages

# Read JSON input from stdin
INPUT=$(cat)

# Parse tool name and input
TOOL_NAME=$(echo "$INPUT" | jq -r '.tool_name // empty')
TOOL_INPUT=$(echo "$INPUT" | jq -r '.tool_input // {}')

# If jq fails or no tool name, exit early
if [[ -z "$TOOL_NAME" ]]; then
  exit 0
fi

# ===== CHECK FOR INTER-TERMINAL MESSAGES =====
# Source communication library if it exists
if [[ -f "$HOME/.claude/hooks/terminal-comm-lib.sh" ]]; then
  source "$HOME/.claude/hooks/terminal-comm-lib.sh"

  # Only check if communication is enabled
  if is_comm_enabled; then
    MESSAGE_COUNT=$(get_message_count)

    if [[ "$MESSAGE_COUNT" -gt 0 ]]; then
      # Get messages
      MESSAGES=$(check_messages)

      if [[ -n "$MESSAGES" ]]; then
        # Inject messages into Claude's context
        echo "📨 Inter-terminal messages received:" >&2
        echo "$MESSAGES" >&2
        echo "" >&2
        echo "You can respond by telling Claude to send messages to other terminals." >&2
      fi
    fi
  fi
fi

# ===== AUTO-APPROVE SAFE READ-ONLY TOOLS =====
case "$TOOL_NAME" in
  Read|Glob|Grep)
    # Always auto-approve read-only operations
    echo '{"hookSpecificOutput":{"hookEventName":"PreToolUse","decision":{"behavior":"allow"}}}'
    exit 0
    ;;
esac

# ===== BASH COMMAND SAFETY CHECKS =====
if [[ "$TOOL_NAME" == "Bash" ]]; then
  COMMAND=$(echo "$TOOL_INPUT" | jq -r '.command // empty')

  # Auto-approve safe read-only commands
  if [[ "$COMMAND" =~ ^(ls|pwd|which|git\ status|git\ log|git\ diff|git\ branch|node\ --version|python.*--version|npm\ list) ]]; then
    echo '{"hookSpecificOutput":{"hookEventName":"PreToolUse","decision":{"behavior":"allow"}}}'
    exit 0
  fi

  # Block obviously dangerous commands
  if [[ "$COMMAND" =~ (rm\ -rf\ /|mkfs|dd\ if=|:\(\)\{|curl.*\|.*sh|wget.*\|.*sh) ]]; then
    echo "🚫 BLOCKED: Potentially destructive command detected" >&2
    exit 2
  fi

  # Warn about git push to main/master
  if [[ "$COMMAND" =~ git\ push.*--force ]] && [[ "$COMMAND" =~ (main|master) ]]; then
    echo "⚠️  Warning: Force push to main/master detected - requesting confirmation" >&2
    echo '{"hookSpecificOutput":{"hookEventName":"PreToolUse","decision":{"behavior":"ask"}}}'
    exit 0
  fi
fi

# ===== WRITE/EDIT SAFETY CHECKS =====
if [[ "$TOOL_NAME" == "Write" ]] || [[ "$TOOL_NAME" == "Edit" ]]; then
  FILE_PATH=$(echo "$TOOL_INPUT" | jq -r '.file_path // empty')

  # Block editing sensitive files
  if [[ "$FILE_PATH" =~ (\.env$|credentials|secrets|\.pem$|\.key$|id_rsa) ]]; then
    echo "🚫 BLOCKED: Attempting to edit sensitive file: $FILE_PATH" >&2
    echo "Sensitive files should be edited manually for security." >&2
    exit 2
  fi

  # Warn about editing config files
  if [[ "$FILE_PATH" =~ (\.bashrc|\.zshrc|\.ssh/config|\.gitconfig) ]]; then
    echo "⚠️  Warning: Editing system config file: $FILE_PATH - requesting confirmation" >&2
    echo '{"hookSpecificOutput":{"hookEventName":"PreToolUse","decision":{"behavior":"ask"}}}'
    exit 0
  fi
fi

# ===== DEFAULT: ALLOW ALL OTHER OPERATIONS =====
# You can change this to "ask" if you want to be prompted for everything else
echo '{"hookSpecificOutput":{"hookEventName":"PreToolUse","decision":{"behavior":"allow"}}}'
exit 0
