#!/bin/bash
# Post-tool-use hook for multi-language code validation
# Provides feedback to Claude after code changes

# Configuration via environment variables
# CLAUDE_HOOK_MODE: "full" (default) or "syntax-only"
# Example: export CLAUDE_HOOK_MODE="syntax-only"
HOOK_MODE="${CLAUDE_HOOK_MODE:-full}"

# Only run on Edit/Write operations
if [[ "$TOOL" != "Edit" && "$TOOL" != "Write" ]]; then
  exit 0
fi

# Get the file path from the tool parameters
FILE_PATH="$FILE_PATH"

# Skip if no file path or file doesn't exist
if [[ -z "$FILE_PATH" ]] || [[ ! -f "$FILE_PATH" ]]; then
  exit 0
fi

# Determine file type
EXTENSION="${FILE_PATH##*.}"
ERRORS_FOUND=false
FEEDBACK=""

# ===== PYTHON VALIDATION =====
if [[ "$EXTENSION" == "py" ]]; then
  FEEDBACK="=== Python Code Validation for $FILE_PATH ===\n"

  # 1. Syntax check
  python3 -m py_compile "$FILE_PATH" 2>/dev/null
  if [ $? -ne 0 ]; then
    FEEDBACK+="\n❌ SYNTAX ERROR:\n"
    FEEDBACK+="$(python3 -m py_compile "$FILE_PATH" 2>&1)\n"
    ERRORS_FOUND=true
  else
    FEEDBACK+="✓ Syntax check passed\n"
  fi

  # Skip additional checks in syntax-only mode
  if [[ "$HOOK_MODE" == "full" ]]; then
    # 2. Type checking with mypy (if installed)
    if command -v mypy &> /dev/null; then
      MYPY_OUTPUT=$(mypy "$FILE_PATH" 2>&1)
      if [[ $? -ne 0 ]]; then
        FEEDBACK+="\n⚠️  Type checking issues:\n$MYPY_OUTPUT\n"
      else
        FEEDBACK+="✓ Type checking passed\n"
      fi
    fi

    # 3. Linting with flake8 (if installed)
    if command -v flake8 &> /dev/null; then
      FLAKE8_OUTPUT=$(flake8 "$FILE_PATH" --max-line-length=100 2>&1)
      if [[ $? -ne 0 ]]; then
        FEEDBACK+="\n⚠️  Linting issues:\n$FLAKE8_OUTPUT\n"
      else
        FEEDBACK+="✓ Linting passed\n"
      fi
    fi

    # 4. Code formatting check with black (if installed)
    if command -v black &> /dev/null; then
      BLACK_OUTPUT=$(black --check "$FILE_PATH" 2>&1)
      if [[ $? -ne 0 ]]; then
        FEEDBACK+="\n⚠️  Formatting issues (run 'black $FILE_PATH' to fix):\n$BLACK_OUTPUT\n"
      else
        FEEDBACK+="✓ Formatting check passed\n"
      fi
    fi
  fi

  # 5. Run tests if this is a test file (only in full mode)
  if [[ "$HOOK_MODE" == "full" ]]; then
    DIR_PATH=$(dirname "$FILE_PATH")
    if [[ "$FILE_PATH" == *"test_"* ]] || [[ "$FILE_PATH" == *"_test.py" ]]; then
      if command -v pytest &> /dev/null; then
        FEEDBACK+="\n--- Running tests ---\n"
        TEST_OUTPUT=$(pytest "$FILE_PATH" -v 2>&1)
        if [[ $? -ne 0 ]]; then
          FEEDBACK+="\n❌ TESTS FAILED:\n$TEST_OUTPUT\n"
          ERRORS_FOUND=true
        else
          FEEDBACK+="✓ All tests passed\n"
        fi
      fi
    fi
  fi

# ===== JAVASCRIPT/TYPESCRIPT VALIDATION =====
elif [[ "$EXTENSION" == "js" ]] || [[ "$EXTENSION" == "jsx" ]] || [[ "$EXTENSION" == "ts" ]] || [[ "$EXTENSION" == "tsx" ]]; then
  FEEDBACK="=== JavaScript/TypeScript Code Validation for $FILE_PATH ===\n"

  # 1. Syntax check with Node.js
  if command -v node &> /dev/null; then
    NODE_CHECK=$(node --check "$FILE_PATH" 2>&1)
    if [[ $? -ne 0 ]]; then
      FEEDBACK+="\n❌ SYNTAX ERROR:\n$NODE_CHECK\n"
      ERRORS_FOUND=true
    else
      FEEDBACK+="✓ Syntax check passed\n"
    fi
  fi

  # Skip additional checks in syntax-only mode
  if [[ "$HOOK_MODE" == "full" ]]; then
    # 2. TypeScript type checking (for .ts/.tsx files)
    if [[ "$EXTENSION" == "ts" ]] || [[ "$EXTENSION" == "tsx" ]]; then
      if command -v tsc &> /dev/null; then
        # Check if tsconfig.json exists in project
        TSCONFIG=$(find . -name "tsconfig.json" -type f 2>/dev/null | head -1)
        if [[ -n "$TSCONFIG" ]]; then
          TSC_OUTPUT=$(tsc --noEmit "$FILE_PATH" 2>&1)
          if [[ $? -ne 0 ]]; then
            FEEDBACK+="\n⚠️  Type checking issues:\n$TSC_OUTPUT\n"
          else
            FEEDBACK+="✓ Type checking passed\n"
          fi
        fi
      fi
    fi

    # 3. Linting with ESLint (if installed)
    if command -v eslint &> /dev/null; then
      ESLINT_OUTPUT=$(eslint "$FILE_PATH" 2>&1)
      if [[ $? -ne 0 ]]; then
        FEEDBACK+="\n⚠️  Linting issues:\n$ESLINT_OUTPUT\n"
      else
        FEEDBACK+="✓ Linting passed\n"
      fi
    fi

    # 4. Code formatting check with Prettier (if installed)
    if command -v prettier &> /dev/null; then
      PRETTIER_OUTPUT=$(prettier --check "$FILE_PATH" 2>&1)
      if [[ $? -ne 0 ]]; then
        FEEDBACK+="\n⚠️  Formatting issues (run 'prettier --write $FILE_PATH' to fix):\n$PRETTIER_OUTPUT\n"
      else
        FEEDBACK+="✓ Formatting check passed\n"
      fi
    fi
  fi

  # 5. Run tests if this is a test file (only in full mode)
  if [[ "$HOOK_MODE" == "full" ]]; then
    BASENAME=$(basename "$FILE_PATH")
    if [[ "$BASENAME" == *.test.* ]] || [[ "$BASENAME" == *.spec.* ]]; then
      # Try Jest first
      if command -v jest &> /dev/null; then
        FEEDBACK+="\n--- Running tests with Jest ---\n"
        TEST_OUTPUT=$(jest "$FILE_PATH" --no-coverage 2>&1)
        if [[ $? -ne 0 ]]; then
          FEEDBACK+="\n❌ TESTS FAILED:\n$TEST_OUTPUT\n"
          ERRORS_FOUND=true
        else
          FEEDBACK+="✓ All tests passed\n"
        fi
      # Try Vitest if Jest not available
      elif command -v vitest &> /dev/null; then
        FEEDBACK+="\n--- Running tests with Vitest ---\n"
        TEST_OUTPUT=$(vitest run "$FILE_PATH" 2>&1)
        if [[ $? -ne 0 ]]; then
          FEEDBACK+="\n❌ TESTS FAILED:\n$TEST_OUTPUT\n"
          ERRORS_FOUND=true
        else
          FEEDBACK+="✓ All tests passed\n"
        fi
      fi
    fi
  fi

# ===== SHELL SCRIPT VALIDATION =====
elif [[ "$EXTENSION" == "sh" ]] || [[ "$EXTENSION" == "bash" ]]; then
  FEEDBACK="=== Shell Script Validation for $FILE_PATH ===\n"

  # 1. Syntax check with bash -n
  BASH_CHECK=$(bash -n "$FILE_PATH" 2>&1)
  if [[ $? -ne 0 ]]; then
    FEEDBACK+="\n❌ SYNTAX ERROR:\n$BASH_CHECK\n"
    ERRORS_FOUND=true
  else
    FEEDBACK+="✓ Syntax check passed\n"
  fi

  # 2. ShellCheck validation (if installed)
  if command -v shellcheck &> /dev/null; then
    SHELLCHECK_OUTPUT=$(shellcheck "$FILE_PATH" 2>&1)
    if [[ $? -ne 0 ]]; then
      # Check if there are errors (not just warnings/info)
      if echo "$SHELLCHECK_OUTPUT" | grep -q "error:"; then
        FEEDBACK+="\n❌ SHELLCHECK ERRORS:\n$SHELLCHECK_OUTPUT\n"
        ERRORS_FOUND=true
      else
        FEEDBACK+="\n⚠️  ShellCheck warnings:\n$SHELLCHECK_OUTPUT\n"
      fi
    else
      FEEDBACK+="✓ ShellCheck validation passed\n"
    fi
  fi

# ===== R VALIDATION =====
elif [[ "$EXTENSION" == "R" ]] || [[ "$EXTENSION" == "r" ]]; then
  FEEDBACK="=== R Code Validation for $FILE_PATH ===\n"

  # 1. Syntax check
  R_SYNTAX_CHECK=$(Rscript -e "tryCatch(parse('$FILE_PATH'), error=function(e) { cat('ERROR:', e\$message); quit(status=1) })" 2>&1)
  if [[ $? -ne 0 ]]; then
    FEEDBACK+="\n❌ SYNTAX ERROR:\n$R_SYNTAX_CHECK\n"
    ERRORS_FOUND=true
  else
    FEEDBACK+="✓ Syntax check passed\n"
  fi

  # Skip additional checks in syntax-only mode
  if [[ "$HOOK_MODE" == "full" ]]; then
    # 2. Linting with lintr (if installed)
    if command -v Rscript &> /dev/null; then
      LINTR_CHECK=$(Rscript -e "if (requireNamespace('lintr', quietly=TRUE)) { lintr::lint('$FILE_PATH') } else { cat('lintr not installed') }" 2>&1)
      if [[ "$LINTR_CHECK" != *"lintr not installed"* ]] && [[ -n "$LINTR_CHECK" ]]; then
        FEEDBACK+="\n⚠️  Linting issues:\n$LINTR_CHECK\n"
      elif [[ "$LINTR_CHECK" != *"lintr not installed"* ]]; then
        FEEDBACK+="✓ Linting passed\n"
      fi
    fi

    # 3. Check for common predictive algorithm issues
    if grep -q "library(caret)\|library(randomForest)\|library(xgboost)" "$FILE_PATH"; then
      FEEDBACK+="✓ Predictive modeling libraries detected\n"

      # Check for train/test split
      if ! grep -q "createDataPartition\|sample\|train_test_split" "$FILE_PATH"; then
        FEEDBACK+="\n⚠️  Warning: No train/test split detected. Consider adding data partitioning.\n"
      fi
    fi
  fi

else
  # Not a Python or R file, exit silently
  exit 0
fi

# Output feedback
if [[ "$ERRORS_FOUND" == true ]]; then
  echo -e "$FEEDBACK" >&2
  exit 2  # Block and provide feedback to Claude
else
  echo -e "$FEEDBACK"
  exit 0  # Success
fi
