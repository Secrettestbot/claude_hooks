#!/bin/bash
# Track a file write/edit in this terminal's CLAUDE.md file registry.
# Called automatically by post-tool-use.sh; can also be called manually to set purposes.
#
# Usage:
#   track-file.sh <file_path>             # Auto-track (purpose = pending)
#   track-file.sh <file_path> "<purpose>" # Set or update purpose
#
# Outputs exactly one word to stdout: "new" or "updated" (used by post-tool-use.sh).
# All other output goes to stderr.

set -o pipefail

FILE_PATH="${1:-}"
PURPOSE="${2:-}"

# Exit silently if no file path
[[ -z "$FILE_PATH" ]] && exit 0

# --- Resolve to absolute path ---
if [[ ! "$FILE_PATH" = /* ]]; then
  FILE_PATH="$(pwd)/$FILE_PATH"
fi
FILE_PATH=$(realpath "$FILE_PATH" 2>/dev/null || echo "$FILE_PATH")

# --- Skip files we must never track (prevent recursion / self-reference) ---
# 1. Any file literally named CLAUDE.md
# 2. Any file inside ~/.claude/context/ (our per-terminal registry files)
if [[ "$(basename "$FILE_PATH")" == "CLAUDE.md" ]]; then
  exit 0
fi
if [[ "$FILE_PATH" == "$HOME/.claude/context/"* ]]; then
  exit 0
fi

# --- Determine project root (for relative paths in the registry) ---
FILE_DIR=$(dirname "$FILE_PATH")
PROJECT_ROOT=$(git -C "$FILE_DIR" rev-parse --show-toplevel 2>/dev/null)
[[ -z "$PROJECT_ROOT" ]] && PROJECT_ROOT="$(pwd)"

# --- Compute relative path ---
REL_PATH="${FILE_PATH#"$PROJECT_ROOT"/}"

# --- Determine project identifier ---
PROJECT_ID="${CLAUDE_PROJECT_ID:-}"
if [[ -z "$PROJECT_ID" ]]; then
  PROJECT_ID=$(basename "$PROJECT_ROOT")
fi

# --- Determine terminal name ---
TERM_NAME="${CLAUDE_TERMINAL_NAME:-}"
if [[ -z "$TERM_NAME" ]]; then
  TTY_MAP="$HOME/.claude/terminal-comm/tty_map.json"
  if [[ -f "$TTY_MAP" ]]; then
    MY_TTY=$(tty 2>/dev/null | sed 's#/dev/##')
    [[ -n "$MY_TTY" ]] && TERM_NAME=$(jq -r --arg t "$MY_TTY" '.[$t] // empty' "$TTY_MAP" 2>/dev/null)
  fi
fi
TERM_NAME="${TERM_NAME:-main}"

# --- Target CLAUDE.md location ---
CONTEXT_DIR="$HOME/.claude/context"
TARGET_DIR="$CONTEXT_DIR/$PROJECT_ID"
CLAUDEMD="$TARGET_DIR/${TERM_NAME}.md"
mkdir -p "$TARGET_DIR"

# --- Timestamp and purpose defaults ---
TIMESTAMP=$(date +"%Y-%m-%d %H:%M")
[[ -z "$PURPOSE" ]] && PURPOSE="*(pending)*"

# --- Acquire per-terminal lock (different terminals don't block each other) ---
LOCK_FILE="$TARGET_DIR/.${TERM_NAME}.lock"
exec 9>"$LOCK_FILE"
flock -x -w 10 9 || { echo "Warning: Could not acquire lock for CLAUDE.md update" >&2; exit 1; }

# --- Ensure CLAUDE.md exists with a registry section ---
if [[ ! -f "$CLAUDEMD" ]]; then
  cat > "$CLAUDEMD" <<EOF
# Terminal: ${TERM_NAME} | Project: ${PROJECT_ID}

Files created or modified by this terminal. Update the "Purpose" column to describe each file's role in the project.

<!-- FILE_REGISTRY_START -->
## File Registry

| File Path | Purpose | Last Modified |
|-----------|---------|---------------|
<!-- FILE_REGISTRY_END -->
EOF
elif ! grep -q "<!-- FILE_REGISTRY_START -->" "$CLAUDEMD"; then
  cat >> "$CLAUDEMD" <<'EOF'

---
<!-- FILE_REGISTRY_START -->
## File Registry

| File Path | Purpose | Last Modified |
|-----------|---------|---------------|
<!-- FILE_REGISTRY_END -->
EOF
fi

# --- Single-pass rebuild: update existing row or append new one ---
TEMP=$(mktemp "${CLAUDEMD}.XXXXXX")
chmod 644 "$TEMP"
FOUND=false
IN_REGISTRY=false
PAST_SEPARATOR=false

while IFS= read -r line || [[ -n "$line" ]]; do
  # Detect registry start marker
  if [[ "$line" == *"<!-- FILE_REGISTRY_START -->"* ]]; then
    IN_REGISTRY=true
    PAST_SEPARATOR=false
    echo "$line" >> "$TEMP"
    continue
  fi

  # Detect registry end marker — append new row here if file wasn't found
  if [[ "$line" == *"<!-- FILE_REGISTRY_END -->"* ]]; then
    if [[ "$FOUND" == false ]]; then
      echo "| $REL_PATH | $PURPOSE | $TIMESTAMP |" >> "$TEMP"
    fi
    IN_REGISTRY=false
    echo "$line" >> "$TEMP"
    continue
  fi

  if [[ "$IN_REGISTRY" == true ]]; then
    # Detect the table separator row (|---|---|...)
    if [[ "$PAST_SEPARATOR" == false ]] && [[ "$line" == "|"* ]] && [[ "$line" == *"---"* ]]; then
      PAST_SEPARATOR=true
      echo "$line" >> "$TEMP"
      continue
    fi

    # Process data rows (lines starting with | after the separator)
    if [[ "$PAST_SEPARATOR" == true ]] && [[ "$line" == "|"* ]]; then
      ROW_FILE=$(echo "$line" | awk -F'|' '{print $2}' | sed 's/^[[:space:]]*//;s/[[:space:]]*$//')
      if [[ "$ROW_FILE" == "$REL_PATH" ]]; then
        FOUND=true
        if [[ "$PURPOSE" != "*(pending)*" ]]; then
          # Caller explicitly provided a purpose — use it
          echo "| $REL_PATH | $PURPOSE | $TIMESTAMP |" >> "$TEMP"
        else
          # Auto-track (no purpose given) — preserve existing purpose, bump timestamp
          OLD_PURPOSE=$(echo "$line" | awk -F'|' '{print $3}' | sed 's/^[[:space:]]*//;s/[[:space:]]*$//')
          echo "| $REL_PATH | $OLD_PURPOSE | $TIMESTAMP |" >> "$TEMP"
        fi
        continue
      fi
    fi
  fi

  # Default: pass line through unchanged
  echo "$line" >> "$TEMP"
done < "$CLAUDEMD"

# Atomic replace
mv "$TEMP" "$CLAUDEMD"

# Release lock
flock -u 9

# Signal result to caller
if [[ "$FOUND" == true ]]; then
  echo "updated"
else
  echo "new"
fi

exit 0
