#!/bin/bash
# Spawn multiple Claude Code terminals with communication enabled
# Usage: spawn-terminal.sh [--workdir DIR] T1 T2 T3 ...

# Source the library for directory setup
source "$HOME/.claude/hooks/terminal-comm-lib.sh"

# Ensure communication directories exist
mkdir -p "$COMM_DIR" "$SESSIONS_DIR" "$MESSAGES_DIR"

# Parse optional --workdir argument
WORK_DIR=""
if [[ "$1" == "--workdir" ]]; then
  WORK_DIR="$2"
  shift 2
fi

# Check if terminal names were provided
if [[ $# -eq 0 ]]; then
  echo "Error: No terminal names provided" >&2
  echo "Usage: $0 [--workdir DIR] <terminal1> <terminal2> ..." >&2
  exit 1
fi

# Get current working directory to pass to spawned terminals if not specified
if [[ -z "$WORK_DIR" ]]; then
  WORK_DIR="$(pwd)"
fi

# Detect terminal emulator
detect_terminal() {
  # Check TERM_PROGRAM first, but skip vscode/IDE environments
  # (they can't spawn independent terminals, so fall back to system terminal)
  if [[ -n "$TERM_PROGRAM" ]] && [[ "$TERM_PROGRAM" != "vscode" ]]; then
    echo "$TERM_PROGRAM"
    return 0
  fi

  # Check parent process name
  PARENT_CMD=$(ps -o comm= -p $PPID 2>/dev/null)

  case "$PARENT_CMD" in
    *gnome-terminal*) echo "gnome-terminal" ;;
    *konsole*) echo "konsole" ;;
    *xterm*) echo "xterm" ;;
    *alacritty*) echo "alacritty" ;;
    *kitty*) echo "kitty" ;;
    *terminator*) echo "terminator" ;;
    *tilix*) echo "tilix" ;;
    *xfce4-terminal*) echo "xfce4-terminal" ;;
    *mate-terminal*) echo "mate-terminal" ;;
    *urxvt*) echo "urxvt" ;;
    *)
      # Fallback: check if any known terminal is available
      for term in gnome-terminal konsole xterm alacritty kitty terminator; do
        if command -v "$term" &> /dev/null; then
          echo "$term"
          return 0
        fi
      done
      echo "unknown"
      ;;
  esac
}

TERMINAL=$(detect_terminal)

# Special handling for VS Code
if [[ "$TERM_PROGRAM" == "vscode" ]]; then
  TERMINAL="vscode"
fi

if [[ "$TERMINAL" == "unknown" ]]; then
  echo "Error: Could not detect terminal emulator" >&2
  echo "Please set TERMINAL_EMULATOR environment variable" >&2
  exit 1
fi

echo "Detected terminal: $TERMINAL"
echo "Spawning ${#@} terminal(s) in working directory: $WORK_DIR"

# Function to spawn a single terminal
spawn_single() {
  local term_name="$1"
  local setup_script="/tmp/claude-spawn-${term_name}-$$.sh"

  # Derive project identifier and ensure per-terminal CLAUDE.md exists
  local spawn_project_id="${CLAUDE_PROJECT_ID:-}"
  if [[ -z "$spawn_project_id" ]]; then
    local spawn_git_root=$(git -C "$WORK_DIR" rev-parse --show-toplevel 2>/dev/null)
    if [[ -n "$spawn_git_root" ]]; then
      spawn_project_id=$(basename "$spawn_git_root")
    else
      spawn_project_id=$(basename "$WORK_DIR")
    fi
  fi
  local spawn_context_dir="$HOME/.claude/context/$spawn_project_id"
  mkdir -p "$spawn_context_dir"
  local spawn_claudemd="$spawn_context_dir/${term_name}.md"
  if [[ ! -f "$spawn_claudemd" ]]; then
    cat > "$spawn_claudemd" <<SKEL
# Terminal: ${term_name} | Project: ${spawn_project_id}

Files created or modified by this terminal. Update the "Purpose" column to describe each file's role in the project.

<!-- FILE_REGISTRY_START -->
## File Registry

| File Path | Purpose | Last Modified |
|-----------|---------|---------------|
<!-- FILE_REGISTRY_END -->
SKEL
  fi

  # Create a setup script that will run in the new terminal
  cat > "$setup_script" <<EOF
#!/bin/bash
# Auto-generated setup script for terminal: $term_name

# Change to the correct working directory
cd "$WORK_DIR" || exit 1

# Set terminal name and project identifier
export CLAUDE_TERMINAL_NAME="$term_name"
export CLAUDE_PROJECT_ID="$spawn_project_id"

# Enable communication - use source to export variables to current shell
source "$HOME/.claude/hooks/terminal-comm-enable.sh" "$term_name"

# Export the session ID for Claude to use
export CLAUDE_SESSION_ID="\$PPID"

# Clear the screen
clear

# Print welcome message
echo "========================================"
echo "  Claude Code Terminal: $term_name"
echo "========================================"
echo ""
echo "Terminal communication is enabled."
echo "You can communicate with other terminals."
echo ""

# Check for pending messages
source "$HOME/.claude/hooks/terminal-comm-lib.sh"
if is_comm_enabled; then
  MESSAGE_COUNT=\$(get_message_count)

  if [[ "\$MESSAGE_COUNT" -gt 0 ]]; then
    echo "📨 You have \$MESSAGE_COUNT pending message(s):"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo ""
    check_messages
    echo ""
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo ""
    echo "Press Enter to start Claude Code..."
    read
  fi
fi

# Start Claude Code with environment variables properly set
# Export the session ID and terminal name for Claude to use
export CLAUDE_SESSION_ID="\$PPID"
export CLAUDE_TERMINAL_NAME="$term_name"

# Register this terminal's TTY in the TTY mapping file for hook auto-approval
MY_TTY=\$(tty | sed 's#/dev/##')
TTY_MAP_FILE="\$HOME/.claude/terminal-comm/tty_map.json"
if [[ -f "\$TTY_MAP_FILE" ]]; then
  # Update existing mapping
  jq --arg tty "\$MY_TTY" --arg name "$term_name" '.[\$tty] = \$name' "\$TTY_MAP_FILE" > "\${TTY_MAP_FILE}.tmp" && mv "\${TTY_MAP_FILE}.tmp" "\$TTY_MAP_FILE"
else
  # Create new mapping file
  mkdir -p "\$(dirname "\$TTY_MAP_FILE")"
  echo '{}' | jq --arg tty "\$MY_TTY" --arg name "$term_name" '.[\$tty] = \$name' > "\$TTY_MAP_FILE"
fi

# Load per-terminal file registry and start Claude
_REGISTRY_FILE="\$HOME/.claude/context/\$CLAUDE_PROJECT_ID/\$CLAUDE_TERMINAL_NAME.md"
if [[ -f "\$_REGISTRY_FILE" ]]; then
  _REGISTRY=\$(cat "\$_REGISTRY_FILE")
  exec claude --append-system-prompt "--- Your File Registry (\$CLAUDE_TERMINAL_NAME) ---
\$_REGISTRY"
else
  exec claude
fi

# Clean up the setup script after use
rm -f "$setup_script"
EOF

  chmod +x "$setup_script"

  # Launch terminal with the setup script
  case "$TERMINAL" in
    vscode)
      # VS Code specific: Use tmux if available, otherwise provide manual instructions
      if command -v tmux &> /dev/null; then
        # Using tmux - works perfectly in VS Code
        # Create a new tmux window with the terminal name
        tmux new-window -n "Claude:$term_name" "bash $setup_script; exec bash" 2>/dev/null ||
        tmux new-session -d -s "claude-$term_name" -n "$term_name" "bash $setup_script; exec bash" 2>/dev/null

        # Auto-accept trust dialog by sending Enter after a short delay
        bash "$HOME/.claude/hooks/auto-accept-trust.sh" "$term_name" &

        echo "  ✓ Created tmux window: $term_name"
        echo "    To attach: tmux attach -t claude-$term_name"
      else
        # No tmux - create launcher script and print instructions
        local launcher="/tmp/claude-launch-${term_name}.sh"
        cp "$setup_script" "$launcher"
        chmod +x "$launcher"

        echo "  📋 Terminal $term_name ready to launch"
        echo "     Open a new VS Code terminal (Ctrl+Shift+\`) and run:"
        echo "     $launcher"
        echo ""

        # Store the launcher path for later reference
        echo "$launcher" >> "/tmp/claude-vscode-terminals-$$.txt"
      fi
      ;;
    gnome-terminal)
      gnome-terminal --title "Claude: $term_name" -- bash -c "$setup_script; exec bash" &
      ;;
    konsole)
      konsole --new-tab -p tabtitle="Claude: $term_name" -e bash -c "$setup_script; exec bash" &
      ;;
    xterm)
      xterm -title "Claude: $term_name" -e bash -c "$setup_script; exec bash" &
      ;;
    alacritty)
      alacritty -t "Claude: $term_name" -e bash -c "$setup_script; exec bash" &
      ;;
    kitty)
      kitty --title "Claude: $term_name" bash -c "$setup_script; exec bash" &
      ;;
    terminator)
      terminator --new-tab --title "Claude: $term_name" -e "bash -c '$setup_script; exec bash'" &
      ;;
    tilix)
      tilix --new-window --title "Claude: $term_name" -e "bash -c '$setup_script; exec bash'" &
      ;;
    xfce4-terminal)
      xfce4-terminal --tab --title "Claude: $term_name" -e "bash -c '$setup_script; exec bash'" &
      ;;
    mate-terminal)
      mate-terminal --tab --title "Claude: $term_name" -e "bash -c '$setup_script; exec bash'" &
      ;;
    *)
      echo "Error: Terminal '$TERMINAL' not supported for spawning" >&2
      rm -f "$setup_script"
      return 1
      ;;
  esac

  echo "  ✓ Spawned terminal: $term_name"

  # Give the terminal time to start
  sleep 0.5
}

# Spawn each terminal
for term_name in "$@"; do
  spawn_single "$term_name"
done

echo ""

# VS Code specific summary
if [[ "$TERMINAL" == "vscode" ]]; then
  if command -v tmux &> /dev/null; then
    echo "✓ All tmux windows created!"
    echo ""
    echo "To access your terminals:"
    echo "  • List sessions: tmux ls"
    echo "  • Attach to session: tmux attach -t claude-<name>"
    echo "  • Switch windows: Ctrl+b w"
    echo ""
  else
    echo "📋 Terminal launchers created!"
    echo ""
    echo "To start your Claude terminals in VS Code:"
    echo "  1. Press Ctrl+Shift+\` to open a new terminal"
    echo "  2. Run one of these commands:"
    echo ""
    if [[ -f "/tmp/claude-vscode-terminals-$$.txt" ]]; then
      cat "/tmp/claude-vscode-terminals-$$.txt" | while read launcher; do
        term_name=$(basename "$launcher" | sed 's/claude-launch-//; s/.sh$//')
        echo "     $launcher  # For terminal: $term_name"
      done
      rm -f "/tmp/claude-vscode-terminals-$$.txt"
    fi
    echo ""
    echo "Each script will set up communication and start Claude Code."
  fi
else
  echo "All terminals spawned successfully!"
  echo "They will auto-register with communication enabled."
fi

exit 0
