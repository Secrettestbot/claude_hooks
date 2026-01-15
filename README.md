# Claude Code Hooks Collection

A collection of useful hooks for Claude Code to improve development workflow, code quality, and safety.

## Available Hooks

### 1. post-tool-use.sh - Python & R Validation

Creates a **feedback loop** that improves Claude Code's output quality by 2-3x. When Claude edits or writes Python/R files, the hook automatically:

- Validates syntax
- Runs type checkers
- Checks code style/linting
- Runs tests (if applicable)
- Provides immediate feedback to Claude so it can self-correct

### 2. session-start.sh - Development Environment Info

Displays useful context at the start of every Claude Code session:

- Hook mode configuration
- Git repository info (branch, uncommitted changes)
- Available development tools (Python, Node.js, R, ShellCheck, etc.)
- Project type detection (Python, Node.js, TypeScript, R)
- Helpful usage tips

### 3. pre-tool-use.sh - Smart Tool Execution Control

Adds safety checks and auto-approves safe operations before tool execution:

**Auto-approved (no prompts):**
- Read-only tools (Read, Glob, Grep)
- Safe bash commands (ls, pwd, git status/log/diff, version checks)
- Package manager info commands

**Automatically blocked:**
- Destructive commands (rm -rf /, mkfs, malicious pipes)
- Sensitive file edits (.env, credentials, keys, passwords)

**Asks for confirmation:**
- Git force push to main/master
- System config edits (.bashrc, .zshrc, .gitconfig)

## Features

### Python Validation
- **Syntax checking** - Catches syntax errors immediately
- **Type checking** (mypy) - Finds type-related issues
- **Linting** (flake8) - Ensures code quality standards
- **Formatting** (black) - Checks code formatting
- **Testing** (pytest) - Automatically runs tests for test files

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

1. **Copy the hooks to your Claude Code hooks directory:**
   ```bash
   mkdir -p ~/.claude/hooks
   cp *.sh ~/.claude/hooks/
   chmod +x ~/.claude/hooks/*.sh
   ```

2. **Enable the hooks in your Claude Code settings:**

   Edit `~/.claude/settings.json` and add:
   ```json
   {
     "hooks": {
       "PreToolUse": [
         {
           "hooks": [
             {
               "type": "command",
               "command": "~/.claude/hooks/pre-tool-use.sh"
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
       ],
       "SessionStart": [
         {
           "hooks": [
             {
               "type": "command",
               "command": "~/.claude/hooks/session-start.sh"
             }
           ]
         }
       ]
     }
   }
   ```

3. **Restart Claude Code** for the hooks to take effect

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

### post-tool-use.sh
- Add more validation tools
- Adjust linting rules
- Skip certain checks
- Add custom project-specific validations

### pre-tool-use.sh
- Change auto-approval rules
- Add custom blocked commands
- Modify sensitive file patterns
- Adjust default behavior (allow vs ask)

### session-start.sh
- Add/remove tool checks
- Customize project type detection
- Add custom environment checks

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
