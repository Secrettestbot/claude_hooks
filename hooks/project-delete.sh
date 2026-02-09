#!/bin/bash
# Delete a Claude Code project
# Usage: project-delete.sh <project-name> [--force]

PROJECTS_DIR="$HOME/.claude/projects"
CONTEXT_DIR="$HOME/.claude/context"

# Check arguments
if [[ -z "$1" ]]; then
  echo "Error: Project name required" >&2
  echo "Usage: $0 <project-name> [--force]" >&2
  exit 1
fi

PROJECT_NAME="$1"
FORCE_DELETE=false

# Check for --force flag
if [[ "$2" == "--force" ]]; then
  FORCE_DELETE=true
fi

PROJECT_FILE="$PROJECTS_DIR/${PROJECT_NAME}.json"
PROJECT_CONTEXT_DIR="$CONTEXT_DIR/$PROJECT_NAME"

# Check if project exists
if [[ ! -f "$PROJECT_FILE" ]]; then
  echo "Error: Project '$PROJECT_NAME' not found" >&2
  echo "Available projects:" >&2
  ls -1 "$PROJECTS_DIR"/*.json 2>/dev/null | xargs -n1 basename | sed 's/.json$//' | sed 's/^/  • /' >&2
  exit 1
fi

# Show project details
echo "=========================================="
echo "Delete Project: $PROJECT_NAME"
echo "=========================================="
echo ""

# Validate and display project info
if jq empty "$PROJECT_FILE" 2>/dev/null; then
  description=$(jq -r '.description // "No description"' "$PROJECT_FILE")
  terminal_count=$(jq '.terminals | length' "$PROJECT_FILE")
  terminal_names=$(jq -r '.terminals[].name' "$PROJECT_FILE" | tr '\n', ', ' | sed 's/,$//')

  echo "Description: $description"
  echo "Terminals: $terminal_count ($terminal_names)"
else
  echo "⚠ Warning: Project file is invalid JSON"
fi

# Check for context files
context_file_count=0
if [[ -d "$PROJECT_CONTEXT_DIR" ]]; then
  context_file_count=$(find "$PROJECT_CONTEXT_DIR" -maxdepth 1 -name "*.md" -type f 2>/dev/null | wc -l)

  if [[ $context_file_count -gt 0 ]]; then
    echo "Context files: $context_file_count"
    find "$PROJECT_CONTEXT_DIR" -maxdepth 1 -name "*.md" -type f -exec basename {} \; 2>/dev/null | sed 's/^/  • /'
  else
    echo "Context files: None"
  fi
else
  echo "Context files: None"
fi

echo ""
echo "Files to be deleted:"
echo "  • $PROJECT_FILE"
if [[ -d "$PROJECT_CONTEXT_DIR" ]]; then
  echo "  • $PROJECT_CONTEXT_DIR/ (directory and all contents)"
fi
echo ""

# Confirm deletion unless --force is used
if [[ "$FORCE_DELETE" != true ]]; then
  echo "⚠  WARNING: This action cannot be undone!"
  echo ""
  read -r -p "Type the project name '$PROJECT_NAME' to confirm deletion: " confirmation

  if [[ "$confirmation" != "$PROJECT_NAME" ]]; then
    echo ""
    echo "Deletion cancelled (name did not match)"
    exit 0
  fi
fi

# Perform deletion
echo ""
echo "Deleting project..."

# Delete project file
if rm "$PROJECT_FILE" 2>/dev/null; then
  echo "✓ Deleted project configuration: $PROJECT_FILE"
else
  echo "✗ Failed to delete project configuration: $PROJECT_FILE" >&2
  exit 1
fi

# Delete context directory if it exists
if [[ -d "$PROJECT_CONTEXT_DIR" ]]; then
  if rm -rf "$PROJECT_CONTEXT_DIR" 2>/dev/null; then
    echo "✓ Deleted context directory: $PROJECT_CONTEXT_DIR"
  else
    echo "⚠ Warning: Failed to delete context directory: $PROJECT_CONTEXT_DIR" >&2
  fi
fi

echo ""
echo "=========================================="
echo "Project '$PROJECT_NAME' has been deleted"
echo "=========================================="
echo ""
echo "Remaining projects:"
bash "$HOME/.claude/hooks/project-list.sh" 2>/dev/null || echo "  (none)"

exit 0
