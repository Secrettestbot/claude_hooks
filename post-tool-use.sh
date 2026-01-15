#!/bin/bash
# Post-tool-use hook for Python and R code validation
# Provides feedback to Claude after code changes

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

  # 5. Run tests if this is a test file or if tests exist
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
