# Claude Code Hooks - Multi-Language Validation

A comprehensive post-tool-use hook for Claude Code that automatically validates Python, JavaScript/TypeScript, Shell scripts, and R code after edits, providing immediate feedback for syntax errors, type issues, linting problems, and test failures.

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

### Shell Script Validation
- **Syntax checking** (bash -n) - Validates shell script syntax
- **ShellCheck** - Catches common scripting errors, security issues, and best practices violations

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

**Shell script tools:**
```bash
# Ubuntu/Debian
apt-get install shellcheck

# macOS
brew install shellcheck

# Or download static binary (works anywhere)
# https://github.com/koalaman/shellcheck/releases
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

1. Claude edits/writes a Python, JavaScript/TypeScript, Shell script, or R file
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

## Configuration

### Hook Modes

Control which checks run using the `CLAUDE_HOOK_MODE` environment variable:

**Full mode (default):**
```bash
export CLAUDE_HOOK_MODE="full"
```
- Runs all checks: syntax, type checking, linting, formatting, tests
- Best for production-quality code
- Higher token usage (~15-25% increase)

**Syntax-only mode:**
```bash
export CLAUDE_HOOK_MODE="syntax-only"
```
- Only runs syntax checking and critical error detection
- Skips type checking, linting, formatting, and tests
- Minimal token usage (~5-10% increase)
- Fastest validation

**Setting permanently:**
Add to your `~/.bashrc` or `~/.zshrc`:
```bash
echo 'export CLAUDE_HOOK_MODE="syntax-only"' >> ~/.bashrc
```

## Session-Start Hook

The session-start hook runs when Claude Code starts and provides:

- Hook configuration status
- Git repository info and uncommitted changes
- Available development tools (Python, Node.js, ShellCheck, R)
- Project type detection (Python, TypeScript, Node.js, R)
- Helpful tips and reminders

### Setup Session-Start Hook

Add to `~/.claude/settings.json`:
```json
{
  "hooks": {
    "SessionStart": [
      {
        "hooks": [
          {
            "type": "command",
            "command": "~/.claude/hooks/session-start.sh"
          }
        ]
      }
    ],
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
