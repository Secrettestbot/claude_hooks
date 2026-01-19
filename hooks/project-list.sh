#!/bin/bash
# List all available Claude Code projects
# Usage: project-list.sh [--json]

PROJECTS_DIR="$HOME/.claude/projects"

# Check if projects directory exists
if [[ ! -d "$PROJECTS_DIR" ]]; then
  echo "No projects directory found at: $PROJECTS_DIR"
  echo "Create one with: mkdir -p $PROJECTS_DIR"
  exit 0
fi

# Find all .json files (excluding example.json for cleaner output)
PROJECT_FILES=("$PROJECTS_DIR"/*.json)

# Check if any projects exist
if [[ ! -f "${PROJECT_FILES[0]}" ]]; then
  echo "No projects found in: $PROJECTS_DIR"
  echo "Create a project configuration file (see $PROJECTS_DIR/README.md)"
  exit 0
fi

# JSON output mode
if [[ "$1" == "--json" ]]; then
  echo "["
  first=true
  for project_file in "${PROJECT_FILES[@]}"; do
    if [[ -f "$project_file" ]] && jq empty "$project_file" 2>/dev/null; then
      if [[ "$first" == true ]]; then
        first=false
      else
        echo ","
      fi
      jq -c '.' "$project_file"
    fi
  done
  echo "]"
  exit 0
fi

# Human-readable output
echo "Available Projects:"
echo ""

for project_file in "${PROJECT_FILES[@]}"; do
  if [[ ! -f "$project_file" ]]; then
    continue
  fi

  # Validate JSON
  if ! jq empty "$project_file" 2>/dev/null; then
    basename=$(basename "$project_file")
    echo "  ⚠ $basename (invalid JSON)"
    continue
  fi

  # Extract project info
  name=$(jq -r '.name // "unknown"' "$project_file")
  description=$(jq -r '.description // "No description"' "$project_file")
  terminal_count=$(jq '.terminals | length' "$project_file")

  # Get terminal names
  terminal_names=$(jq -r '.terminals[].name' "$project_file" | tr '\n' ', ' | sed 's/,$//')

  echo "  • $name"
  echo "    Description: $description"
  echo "    Terminals: $terminal_count ($terminal_names)"
  echo ""
done

echo "To start a project, say: 'Start working on project <name>'"
echo "To save current setup: 'Save this as project <name>'"

exit 0
