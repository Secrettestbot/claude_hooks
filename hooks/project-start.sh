#!/bin/bash
# Start a Claude Code project with multiple pre-configured terminals
# Usage: project-start.sh <project-name>

PROJECTS_DIR="$HOME/.claude/projects"
CONTEXT_DIR="$HOME/.claude/context"

# Check arguments
if [[ -z "$1" ]]; then
  echo "Error: Project name required" >&2
  echo "Usage: $0 <project-name>" >&2
  echo "" >&2
  echo "Available projects:" >&2
  bash "$HOME/.claude/hooks/project-list.sh" 2>&1 | grep "^  •" >&2
  exit 1
fi

PROJECT_NAME="$1"
PROJECT_FILE="$PROJECTS_DIR/${PROJECT_NAME}.json"

# Check if project exists
if [[ ! -f "$PROJECT_FILE" ]]; then
  echo "Error: Project '$PROJECT_NAME' not found" >&2
  echo "Expected file: $PROJECT_FILE" >&2
  echo "" >&2
  echo "Available projects:" >&2
  bash "$HOME/.claude/hooks/project-list.sh" 2>&1 | grep "^  •" >&2
  exit 1
fi

# Validate JSON
if ! jq empty "$PROJECT_FILE" 2>/dev/null; then
  echo "Error: Invalid JSON in project file: $PROJECT_FILE" >&2
  exit 1
fi

# Source communication library for directory setup
source "$HOME/.claude/hooks/terminal-comm-lib.sh"
mkdir -p "$COMM_DIR" "$SESSIONS_DIR" "$MESSAGES_DIR"

# Get project info
PROJECT_DESC=$(jq -r '.description // "No description"' "$PROJECT_FILE")
TERMINAL_COUNT=$(jq '.terminals | length' "$PROJECT_FILE")

echo "=========================================="
echo "Starting Project: $PROJECT_NAME"
echo "=========================================="
echo "Description: $PROJECT_DESC"
echo "Terminals: $TERMINAL_COUNT"
echo ""

# Detect terminal emulator (same logic as spawn-terminal.sh)
detect_terminal() {
  # Skip vscode/IDE environments - fall back to system terminal
  if [[ -n "$TERM_PROGRAM" ]] && [[ "$TERM_PROGRAM" != "vscode" ]]; then
    echo "$TERM_PROGRAM"
    return 0
  fi

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
    *)
      for term in gnome-terminal konsole xterm alacritty kitty; do
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
  exit 1
fi

# Function to spawn a terminal with project configuration
spawn_project_terminal() {
  local index=$1
  local config=$(jq -c ".terminals[$index]" "$PROJECT_FILE")

  local term_name=$(echo "$config" | jq -r '.name')
  local workdir=$(echo "$config" | jq -r '.workdir')
  local context_files=$(echo "$config" | jq -r '.context_files[]?' 2>/dev/null)
  local system_prompt=$(echo "$config" | jq -r '.system_prompt // empty')

  # Expand ~ in workdir
  workdir="${workdir/#\~/$HOME}"

  # Validate workdir exists
  if [[ ! -d "$workdir" ]]; then
    echo "  ⚠ Warning: Directory does not exist: $workdir" >&2
    echo "    Creating directory..." >&2
    mkdir -p "$workdir"
  fi

  local setup_script="/tmp/claude-project-${PROJECT_NAME}-${term_name}-$$.sh"

  # Build initial prompt: project context files + per-terminal file registry
  local initial_prompt=""
  local project_context_dir="$CONTEXT_DIR/$PROJECT_NAME"

  # Ensure context directory exists and auto-create this terminal's CLAUDE.md
  mkdir -p "$project_context_dir"
  local terminal_claudemd="$project_context_dir/${term_name}.md"
  if [[ ! -f "$terminal_claudemd" ]]; then
    cat > "$terminal_claudemd" <<SKEL
# Terminal: ${term_name} | Project: ${PROJECT_NAME}

Files created or modified by this terminal. Update the "Purpose" column to describe each file's role in the project.

<!-- FILE_REGISTRY_START -->
## File Registry

| File Path | Purpose | Last Modified |
|-----------|---------|---------------|
<!-- FILE_REGISTRY_END -->
SKEL
  fi

  # Load project context files (if any)
  if [[ -n "$context_files" ]] && [[ -d "$project_context_dir" ]]; then
    initial_prompt+="=== PROJECT CONTEXT ===\n\n"

    while IFS= read -r context_file; do
      # Strip leading @ for backward compatibility with older project files
      context_file="${context_file#@}"
      local context_file_path="$project_context_dir/$context_file"

      if [[ -f "$context_file_path" ]]; then
        initial_prompt+="--- Context: $context_file ---\n"
        initial_prompt+="$(cat "$context_file_path")\n\n"
      fi
    done <<< "$context_files"

    initial_prompt+="=== END CONTEXT ===\n\n"
  fi

  # Always load this terminal's file registry (persists across sessions)
  if [[ -f "$terminal_claudemd" ]]; then
    initial_prompt+="--- Your File Registry (${term_name}.md) ---\n"
    initial_prompt+="$(cat "$terminal_claudemd")\n"
  fi

  # Create setup script
  cat > "$setup_script" <<EOF
#!/bin/bash
# Auto-generated setup script for project terminal: $term_name

# Change to working directory
cd "$workdir" || exit 1

# Set terminal name and project identifier
export CLAUDE_TERMINAL_NAME="$term_name"
export CLAUDE_PROJECT_ID="$PROJECT_NAME"

# Enable communication
bash "$HOME/.claude/hooks/terminal-comm-enable.sh" "$term_name" 2>/dev/null

# Clear screen
clear

# Print header
echo "=========================================="
echo "  Project: $PROJECT_NAME"
echo "  Terminal: $term_name"
echo "=========================================="
echo ""
echo "Working directory: $workdir"
echo "Communication: ENABLED"
echo ""
EOF

  # Add system prompt and initial context handling
  if [[ -n "$system_prompt" ]]; then
    cat >> "$setup_script" <<EOF
echo "Custom instructions: $system_prompt"
echo ""
EOF
  fi

  # Show context files if any
  if [[ -n "$context_files" ]]; then
    cat >> "$setup_script" <<EOF
echo "Context files loaded:"
EOF
    while IFS= read -r context_file; do
      cat >> "$setup_script" <<EOF
echo "  • $context_file"
EOF
    done <<< "$context_files"
    cat >> "$setup_script" <<EOF
echo ""
EOF
  fi

  # Build enhanced system prompt: role instructions + actual context content
  local enhanced_system_prompt="$system_prompt"

  if [[ -n "$initial_prompt" ]]; then
    if [[ -n "$enhanced_system_prompt" ]]; then
      enhanced_system_prompt+="$initial_prompt"
    else
      enhanced_system_prompt="$initial_prompt"
    fi
  fi

  # Start Claude with enhanced system prompt if we have one
  if [[ -n "$enhanced_system_prompt" ]]; then
    # Escape special characters for the command line
    local escaped_prompt=$(printf '%s' "$enhanced_system_prompt" | sed 's/"/\\"/g')
    cat >> "$setup_script" <<EOF
# Start Claude with enhanced system prompt
exec claude --append-system-prompt "$escaped_prompt"
EOF
  else
    cat >> "$setup_script" <<EOF
# Start Claude
exec claude
EOF
  fi

  # Add cleanup
  cat >> "$setup_script" <<EOF

# Clean up setup script
rm -f "$setup_script"
EOF

  chmod +x "$setup_script"

  # Launch terminal
  case "$TERMINAL" in
    vscode)
      # VS Code specific: Use tmux if available, otherwise provide manual instructions
      if command -v tmux &> /dev/null; then
        tmux new-window -n "$PROJECT_NAME:$term_name" "bash $setup_script; exec bash" 2>/dev/null ||
        tmux new-session -d -s "claude-${PROJECT_NAME}-$term_name" -n "$term_name" "bash $setup_script; exec bash" 2>/dev/null
        echo "  ✓ Created tmux window: $term_name"
      else
        local launcher="/tmp/claude-project-${PROJECT_NAME}-${term_name}.sh"
        cp "$setup_script" "$launcher"
        chmod +x "$launcher"
        echo "  📋 Terminal $term_name ready"
        echo "$launcher" >> "/tmp/claude-vscode-project-${PROJECT_NAME}-$$.txt"
      fi
      ;;
    gnome-terminal)
      gnome-terminal --title "Claude: $PROJECT_NAME - $term_name" -- bash -c "$setup_script; exec bash" &
      ;;
    konsole)
      konsole --new-tab -p tabtitle="$PROJECT_NAME - $term_name" -e bash -c "$setup_script; exec bash" &
      ;;
    xterm)
      xterm -title "$PROJECT_NAME - $term_name" -e bash -c "$setup_script; exec bash" &
      ;;
    alacritty)
      alacritty -t "$PROJECT_NAME - $term_name" -e bash -c "$setup_script; exec bash" &
      ;;
    kitty)
      kitty --title "$PROJECT_NAME - $term_name" bash -c "$setup_script; exec bash" &
      ;;
    terminator)
      terminator --new-tab --title "$PROJECT_NAME - $term_name" -e "bash -c '$setup_script; exec bash'" &
      ;;
    tilix)
      tilix --new-window --title "$PROJECT_NAME - $term_name" -e "bash -c '$setup_script; exec bash'" &
      ;;
    xfce4-terminal)
      xfce4-terminal --tab --title "$PROJECT_NAME - $term_name" -e "bash -c '$setup_script; exec bash'" &
      ;;
    mate-terminal)
      mate-terminal --tab --title "$PROJECT_NAME - $term_name" -e "bash -c '$setup_script; exec bash'" &
      ;;
    *)
      echo "Error: Terminal '$TERMINAL' not supported" >&2
      rm -f "$setup_script"
      return 1
      ;;
  esac

  if [[ "$TERMINAL" != "vscode" ]]; then
    echo "  ✓ Spawned: $term_name (workdir: $workdir)"
  fi
  sleep 0.5
}

# Spawn all terminals
for i in $(seq 0 $((TERMINAL_COUNT - 1))); do
  spawn_project_terminal $i
done

echo ""
echo "=========================================="
echo "Project '$PROJECT_NAME' started successfully!"

if [[ "$TERMINAL" == "vscode" ]]; then
  if command -v tmux &> /dev/null; then
    echo "All tmux windows created!"
    echo ""
    echo "To access your project terminals:"
    echo "  • List sessions: tmux ls"
    echo "  • Attach: tmux attach -t claude-${PROJECT_NAME}-<terminal>"
    echo "  • Switch windows: Ctrl+b w"
  else
    echo "Terminal launchers created!"
    echo ""
    echo "To start your project terminals in VS Code:"
    echo "  1. Press Ctrl+Shift+\` to open a new terminal"
    echo "  2. Run these commands:"
    echo ""
    if [[ -f "/tmp/claude-vscode-project-${PROJECT_NAME}-$$.txt" ]]; then
      cat "/tmp/claude-vscode-project-${PROJECT_NAME}-$$.txt"
      rm -f "/tmp/claude-vscode-project-${PROJECT_NAME}-$$.txt"
    fi
  fi
else
  echo "All terminals are now running."
fi
echo "=========================================="

exit 0
