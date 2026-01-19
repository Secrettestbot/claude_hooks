#!/bin/bash
# Session-start hook for Claude Code
# Runs when a new Claude Code session starts
# Checks environment, tools, and provides helpful context

echo "=== Claude Code Session Start ==="
echo ""

# ===== HOOK CONFIGURATION =====
HOOK_MODE="${CLAUDE_HOOK_MODE:-full}"
echo "📋 Hook Mode: $HOOK_MODE"
if [[ "$HOOK_MODE" == "syntax-only" ]]; then
  echo "   (Syntax checking only - fast, low token usage)"
else
  echo "   (Full validation - type checking, linting, formatting, tests)"
fi
echo ""

# ===== GIT REPOSITORY INFO =====
if git rev-parse --git-dir > /dev/null 2>&1; then
  echo "📁 Git Repository: $(basename "$(git rev-parse --show-toplevel)")"

  CURRENT_BRANCH=$(git branch --show-current 2>/dev/null)
  if [[ -n "$CURRENT_BRANCH" ]]; then
    echo "   Branch: $CURRENT_BRANCH"
  fi

  # Check for uncommitted changes
  if ! git diff-index --quiet HEAD -- 2>/dev/null; then
    MODIFIED_COUNT=$(git diff --name-only | wc -l | tr -d ' ')
    STAGED_COUNT=$(git diff --cached --name-only | wc -l | tr -d ' ')
    echo "   ⚠️  Uncommitted changes: $MODIFIED_COUNT modified, $STAGED_COUNT staged"
  else
    echo "   ✓ Working tree clean"
  fi
  echo ""
fi

# ===== TOOL AVAILABILITY CHECK =====
echo "🔧 Development Tools:"

# Python tools
if command -v python3 &> /dev/null; then
  PYTHON_VERSION=$(python3 --version 2>&1 | cut -d' ' -f2)
  echo "   ✓ Python $PYTHON_VERSION"

  PYTHON_TOOLS=()
  command -v mypy &> /dev/null && PYTHON_TOOLS+=("mypy")
  command -v flake8 &> /dev/null && PYTHON_TOOLS+=("flake8")
  command -v black &> /dev/null && PYTHON_TOOLS+=("black")
  command -v pytest &> /dev/null && PYTHON_TOOLS+=("pytest")

  if [ ${#PYTHON_TOOLS[@]} -gt 0 ]; then
    echo "     Tools: ${PYTHON_TOOLS[*]}"
  fi
else
  echo "   ○ Python not found"
fi

# Node.js / JavaScript tools
if command -v node &> /dev/null; then
  NODE_VERSION=$(node --version)
  echo "   ✓ Node.js $NODE_VERSION"

  JS_TOOLS=()
  command -v tsc &> /dev/null && JS_TOOLS+=("typescript")
  command -v eslint &> /dev/null && JS_TOOLS+=("eslint")
  command -v prettier &> /dev/null && JS_TOOLS+=("prettier")
  command -v jest &> /dev/null && JS_TOOLS+=("jest")
  command -v vitest &> /dev/null && JS_TOOLS+=("vitest")

  if [ ${#JS_TOOLS[@]} -gt 0 ]; then
    echo "     Tools: ${JS_TOOLS[*]}"
  fi
else
  echo "   ○ Node.js not found"
fi

# Shell script tools
if command -v shellcheck &> /dev/null; then
  SHELLCHECK_VERSION=$(shellcheck --version | grep "^version:" | cut -d' ' -f2)
  echo "   ✓ ShellCheck $SHELLCHECK_VERSION"
else
  echo "   ○ ShellCheck not found (install: apt-get install shellcheck)"
fi

# R
if command -v R &> /dev/null; then
  R_VERSION=$(R --version | head -1 | cut -d' ' -f3)
  echo "   ✓ R $R_VERSION"

  # Check for lintr
  if Rscript -e "requireNamespace('lintr', quietly=TRUE)" &> /dev/null; then
    echo "     Tools: lintr"
  fi
else
  echo "   ○ R not found"
fi

echo ""

# ===== PROJECT-SPECIFIC DETECTION =====
echo "📦 Project Type:"

PROJECT_TYPES=()

# Detect Python project
if [[ -f "requirements.txt" ]] || [[ -f "setup.py" ]] || [[ -f "pyproject.toml" ]]; then
  PROJECT_TYPES+=("Python")
fi

# Detect Node.js project
if [[ -f "package.json" ]]; then
  PROJECT_TYPES+=("Node.js")

  # Show package manager
  if [[ -f "package-lock.json" ]]; then
    echo "   📦 npm project"
  elif [[ -f "yarn.lock" ]]; then
    echo "   📦 yarn project"
  elif [[ -f "pnpm-lock.yaml" ]]; then
    echo "   📦 pnpm project"
  fi
fi

# Detect TypeScript
if [[ -f "tsconfig.json" ]]; then
  PROJECT_TYPES+=("TypeScript")
fi

# Detect R project
if [[ -f "DESCRIPTION" ]] || ls *.Rproj &> /dev/null; then
  PROJECT_TYPES+=("R")
fi

if [ ${#PROJECT_TYPES[@]} -gt 0 ]; then
  echo "   Detected: ${PROJECT_TYPES[*]}"
else
  echo "   No specific project type detected"
fi

echo ""

# ===== INTER-TERMINAL COMMUNICATION =====
# Source communication library if it exists
if [[ -f "$HOME/.claude/hooks/terminal-comm-lib.sh" ]]; then
  source "$HOME/.claude/hooks/terminal-comm-lib.sh"

  # Auto-enable communication if CLAUDE_TERMINAL_NAME is set
  if [[ -n "$CLAUDE_TERMINAL_NAME" ]] && ! is_comm_enabled; then
    # Enable communication automatically
    SESSION_ID=$(get_session_id)
    export CLAUDE_SESSION_ID="$SESSION_ID"

    CONFIG_FILE="$SESSIONS_DIR/${SESSION_ID}.json"

    # Create session config
    jq -n --arg name "$CLAUDE_TERMINAL_NAME" \
          --arg sid "$SESSION_ID" \
          '{
            enabled: true,
            name: $name,
            session_id: $sid,
            enabled_at: (now | strftime("%Y-%m-%dT%H:%M:%SZ"))
          }' > "$CONFIG_FILE" 2>/dev/null

    # Register in the shared registry
    register_terminal "$CLAUDE_TERMINAL_NAME" 2>/dev/null
  fi

  if is_comm_enabled; then
    TERMINAL_NAME=$(get_terminal_name)
    echo "💬 Inter-Terminal Communication: ENABLED"
    echo "   Terminal name: $TERMINAL_NAME"
    echo ""
    list_terminals
    echo ""
  else
    echo "💬 Inter-Terminal Communication: Available"
    echo "   To enable: Tell Claude 'Enable terminal communication as <name>'"
    echo ""
  fi
fi

# ===== HELPFUL TIPS =====
echo "💡 Tips:"
echo "   • To use syntax-only mode: export CLAUDE_HOOK_MODE=\"syntax-only\""
echo "   • To disable hooks: Remove PostToolUse from ~/.claude/settings.json"
echo "   • View hook logs: Run Claude with verbose mode"
echo ""

# Exit successfully (don't block session start)
exit 0
