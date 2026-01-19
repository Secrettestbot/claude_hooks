#!/bin/bash
# Save current multi-terminal setup as a project configuration
# Usage: project-save.sh <project-name> [description]

PROJECTS_DIR="$HOME/.claude/projects"

# Check arguments
if [[ -z "$1" ]]; then
  echo "Error: Project name required" >&2
  echo "Usage: $0 <project-name> [description]" >&2
  exit 1
fi

PROJECT_NAME="$1"
PROJECT_DESC="${2:-Project created on $(date +'%Y-%m-%d')}"
PROJECT_FILE="$PROJECTS_DIR/${PROJECT_NAME}.json"

# Ensure projects directory exists
mkdir -p "$PROJECTS_DIR"

# Source communication library
source "$HOME/.claude/hooks/terminal-comm-lib.sh"

# Check if there are any active terminals
if [[ ! -f "$REGISTRY_FILE" ]]; then
  echo "Error: No active terminals found in registry" >&2
  echo "Start terminals with communication enabled first" >&2
  exit 1
fi

TERMINAL_COUNT=$(jq '.terminals | length' "$REGISTRY_FILE" 2>/dev/null)

if [[ -z "$TERMINAL_COUNT" ]] || [[ "$TERMINAL_COUNT" == "0" ]]; then
  echo "Error: No active terminals found in registry" >&2
  echo "Start terminals with communication enabled first" >&2
  exit 1
fi

# Warn if project file already exists
if [[ -f "$PROJECT_FILE" ]]; then
  echo "Warning: Project '$PROJECT_NAME' already exists and will be overwritten"
  echo "Press Ctrl+C to cancel, or Enter to continue..."
  read -r
fi

# Get current working directory
CURRENT_DIR="$(pwd)"

echo "=========================================="
echo "Saving Project: $PROJECT_NAME"
echo "=========================================="
echo "Description: $PROJECT_DESC"
echo "Active terminals: $TERMINAL_COUNT"
echo ""

# Build terminals array from registry
TERMINALS_JSON=$(jq -r '.terminals[] | @json' "$REGISTRY_FILE" | while read -r term_entry; do
  term_name=$(echo "$term_entry" | jq -r '.name')

  # Create terminal config with defaults
  jq -n --arg name "$term_name" \
        --arg workdir "$CURRENT_DIR" \
        '{
          name: $name,
          workdir: $workdir,
          context_files: [],
          system_prompt: ""
        }'
done | jq -s '.')

# Create project JSON
jq -n --arg name "$PROJECT_NAME" \
      --arg desc "$PROJECT_DESC" \
      --argjson terminals "$TERMINALS_JSON" \
      '{
        name: $name,
        description: $desc,
        terminals: $terminals
      }' > "$PROJECT_FILE"

echo "Project configuration saved to: $PROJECT_FILE"
echo ""
echo "Terminal configuration:"
jq -r '.terminals[] | "  • \(.name) (workdir: \(.workdir))"' "$PROJECT_FILE"
echo ""
echo "To customize this project:"
echo "  1. Edit: $PROJECT_FILE"
echo "  2. Update working directories for each terminal"
echo "  3. Add context_files (e.g., [\"@src/main.py\", \"@README.md\"])"
echo "  4. Add system_prompt for custom instructions"
echo ""
echo "To start this project later, say:"
echo "  'Start working on project $PROJECT_NAME'"

exit 0
