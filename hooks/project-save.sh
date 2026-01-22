#!/bin/bash
# Save current multi-terminal setup as a project configuration
# Usage: project-save.sh <project-name> [description]

PROJECTS_DIR="$HOME/.claude/projects"
CONTEXT_DIR="$HOME/.claude/context"

# Check arguments
if [[ -z "$1" ]]; then
  echo "Error: Project name required" >&2
  echo "Usage: $0 <project-name> [description]" >&2
  exit 1
fi

PROJECT_NAME="$1"
PROJECT_DESC="${2:-Project created on $(date +'%Y-%m-%d')}"
PROJECT_FILE="$PROJECTS_DIR/${PROJECT_NAME}.json"

# Ensure directories exist
mkdir -p "$PROJECTS_DIR"
mkdir -p "$CONTEXT_DIR"

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

# Function to copy context files to Claude directory
copy_context_files() {
  local term_name="$1"
  local context_files=()

  echo "Context files for terminal '$term_name':"
  echo "Enter file paths to include as context (one per line, empty line to finish):"
  echo "(Files will be copied to ~/.claude/context/$PROJECT_NAME/)"
  echo ""

  while true; do
    read -r -p "File path (or press Enter to finish): " file_path

    # Break on empty input
    if [[ -z "$file_path" ]]; then
      break
    fi

    # Expand ~ and relative paths
    file_path="${file_path/#\~/$HOME}"

    # Convert relative path to absolute
    if [[ ! "$file_path" = /* ]]; then
      file_path="$CURRENT_DIR/$file_path"
    fi

    # Check if file exists
    if [[ ! -f "$file_path" ]]; then
      echo "  ⚠ Warning: File not found: $file_path" >&2
      echo "  Do you want to add it anyway? (y/n): "
      read -r response
      if [[ ! "$response" =~ ^[Yy]$ ]]; then
        continue
      fi
    fi

    context_files+=("$file_path")
    echo "  ✓ Added: $file_path"
  done

  # Copy files to context directory if any were specified
  if [[ ${#context_files[@]} -gt 0 ]]; then
    local project_context_dir="$CONTEXT_DIR/$PROJECT_NAME"
    mkdir -p "$project_context_dir"

    local saved_files=()
    for file_path in "${context_files[@]}"; do
      if [[ -f "$file_path" ]]; then
        # Get base filename and ensure .md extension
        local base_name=$(basename "$file_path")
        local context_file_name="${base_name%.md}.md"

        # Copy file to context directory
        cp "$file_path" "$project_context_dir/$context_file_name" 2>/dev/null

        if [[ $? -eq 0 ]]; then
          saved_files+=("$context_file_name")
          echo "  ✓ Copied to: $project_context_dir/$context_file_name"
        else
          echo "  ⚠ Failed to copy: $file_path" >&2
        fi
      else
        # File doesn't exist yet - just save the reference
        local base_name=$(basename "$file_path")
        local context_file_name="${base_name%.md}.md"
        saved_files+=("$context_file_name")
        echo "  📋 Reference added (file will be created): $context_file_name"
      fi
    done

    # Return JSON array of saved filenames
    printf '%s\n' "${saved_files[@]}" | jq -R . | jq -s .
  else
    echo "[]"
  fi
}

# Build terminals array from registry
TERMINALS_JSON=$(jq -r '.terminals[] | @json' "$REGISTRY_FILE" | while read -r term_entry; do
  term_name=$(echo "$term_entry" | jq -r '.name')

  echo "" >&2
  echo "Configuring terminal: $term_name" >&2
  echo "----------------------------------------" >&2

  # Get context files for this terminal
  context_files_json=$(copy_context_files "$term_name")

  # Create terminal config with context files
  jq -n --arg name "$term_name" \
        --arg workdir "$CURRENT_DIR" \
        --argjson context_files "$context_files_json" \
        '{
          name: $name,
          workdir: $workdir,
          context_files: $context_files,
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
echo "  3. Edit context files in: $CONTEXT_DIR/$PROJECT_NAME/"
echo "  4. Add system_prompt for custom instructions"
echo ""
echo "Context files are stored as markdown in: $CONTEXT_DIR/$PROJECT_NAME/"
echo ""
echo "To start this project later, say:"
echo "  'Start working on project $PROJECT_NAME'"

exit 0
