# Claude Code Hooks - Multi-Language Validation

A comprehensive post-tool-use hook for Claude Code that automatically validates Python, JavaScript/TypeScript, and R code after edits, providing immediate feedback for syntax errors, type issues, linting problems, and test failures.

## What This Does

This hook creates a **feedback loop** that improves Claude Code's output quality by 2-3x. When Claude edits or writes code files, the hook automatically:

- Validates syntax
- Runs type checkers
- Checks code style/linting
- Runs tests (if applicable)
- Provides immediate feedback to Claude so it can self-correct

## Features

### Python Validation
- **Syntax checking** - Catches syntax errors immediately
- **Type checking** (mypy) - Finds type-related issues
- **Linting** (flake8) - Ensures code quality standards
- **Formatting** (black) - Checks code formatting
- **Testing** (pytest) - Automatically runs tests for test files

### JavaScript/TypeScript Validation
- **Syntax checking** (Node.js) - Catches syntax errors immediately
- **Type checking** (tsc) - TypeScript type validation
- **Linting** (ESLint) - Ensures code quality standards
- **Formatting** (Prettier) - Checks code formatting
- **Testing** (Jest/Vitest) - Automatically runs tests for test files

### R Validation
- **Syntax checking** - Validates R syntax
- **Linting** (lintr) - Code quality checks
- **Predictive algorithm checks** - Warns if train/test split is missing in ML code

## Installation

### Prerequisites

**Python tools:**
```bash
pip install mypy flake8 black pytest
```

**JavaScript/TypeScript tools:**
```bash
npm install -g typescript eslint prettier jest
# or
yarn global add typescript eslint prettier jest
```

**R tools:**
```bash
# Install R
sudo apt-get install r-base  # Ubuntu/Debian
# or
brew install r  # macOS

# Install lintr (optional)
Rscript -e "install.packages('lintr')"
```

### Setup

1. **Copy the hook to your Claude Code hooks directory:**
   ```bash
   mkdir -p ~/.claude/hooks
   cp post-tool-use.sh ~/.claude/hooks/
   chmod +x ~/.claude/hooks/post-tool-use.sh
   ```

2. **Enable the hook in your Claude Code settings:**

   Edit `~/.claude/settings.json` and add:
   ```json
   {
     "hooks": {
       "PostToolUse": [
         {
           "hooks": [
             {
               "type": "command",
               "command": "~/.claude/hooks/post-tool-use.sh"
             }
           ]
         }
       ]
     }
   }
   ```

3. **Restart Claude Code** for the hook to take effect

## How It Works

### Feedback Mechanism

The hook uses **exit codes** to communicate with Claude:

- **Exit 0**: Success - validation passed
- **Exit 2**: Blocking error - Claude receives the error message and can fix it automatically
- **Other exits**: Non-blocking warnings shown in verbose mode

### Workflow

1. Claude edits/writes a Python or R file
2. Hook automatically runs validation checks
3. If errors are found:
   - Hook exits with code 2
   - Error details sent to Claude via stderr
   - Claude sees the feedback and fixes the issues
4. If validation passes:
   - Hook exits with code 0
   - Claude continues

This creates the loop: **think → act → observe → correct**

## Example

When Claude writes Python code with a syntax error:

```
❌ SYNTAX ERROR:
  File "script.py", line 23
    if running  # missing colon
               ^
SyntaxError: expected ':'
```

Claude receives this feedback immediately and fixes it before telling you it's done.

## Customization

You can modify `post-tool-use.sh` to:

- Add more validation tools
- Adjust linting rules
- Skip certain checks
- Add custom project-specific validations

## Requirements

- Claude Code (with hooks support)
- Bash shell
- Python 3.x (for Python validation)
- R (for R validation)

## License

MIT License - Feel free to modify and use as needed

## Credits

Based on the Claude Code hooks system. Inspired by the principle that feedback loops improve AI output quality by 2-3x.

## Contributing

Feel free to submit issues or pull requests with improvements!
