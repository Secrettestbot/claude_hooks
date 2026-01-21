# Claude Code Hooks Collection

A comprehensive collection of hooks for Claude Code that enables multi-terminal coordination, project management, code validation, and enhanced safety features.

## Recent Changes

### January 2026 - Major Feature Additions
- **Terminal Spawning System**: Spawn multiple Claude Code terminals with natural language commands
- **Inter-Terminal Communication**: Enable coordination between multiple Claude instances
- **Project Management**: Save and restore terminal configurations with working directories and context
- **Auto-Accept Trust**: Automatically handle trust dialogs for spawned terminals
- **Enhanced Session Start**: Auto-detect project types and show comprehensive environment info

### Earlier Updates
- Added PreToolUse hook for smart tool execution control
- Enhanced Python/R validation with testing support
- Added comprehensive development tool detection

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

### 4. spawn-terminal.sh - Multi-Terminal Management

Spawns multiple Claude Code terminals with automatic communication setup:

**Features:**
- Natural language terminal spawning ("spawn terminals named T1 and T2")
- Auto-detects terminal emulator (gnome-terminal, konsole, kitty, VS Code, etc.)
- Automatic inter-terminal communication setup
- TTY mapping for auto-approval of cross-terminal operations
- Works with tmux in VS Code for seamless experience

### 5. terminal-comm-*.sh - Inter-Terminal Communication

Enables multiple Claude Code instances to communicate and coordinate:

**Components:**
- `terminal-comm-enable.sh` - Enable communication for a terminal
- `terminal-comm-disable.sh` - Disable communication
- `terminal-comm-check.sh` - Check communication status
- `terminal-comm-send.sh` - Send messages to other terminals
- `terminal-comm-lib.sh` - Shared library functions
- `check-messages.sh` - Check and display pending messages

**Features:**
- Register terminals with unique names
- Send/receive messages between terminals
- Auto-cleanup of stale sessions (24 hours)
- Session tracking with JSON metadata
- Integration with PreToolUse hook for message delivery

### 6. project-*.sh - Project Management System

Save and restore multi-terminal project configurations:

**Components:**
- `project-save.sh` - Save current terminal setup as a project
- `project-start.sh` - Load and start a saved project
- `project-list.sh` - List available projects

**Features:**
- Save terminal names, working directories, and configurations
- Auto-spawn all project terminals on load
- Support for context files and custom system prompts per terminal
- Natural language project management ("start project webapp")
- JSON-based project configs in `~/.claude/projects/`

### 7. auto-accept-trust.sh - Automated Trust Dialog Handling

Automatically accepts trust dialogs for spawned terminals:

**Features:**
- Handles tmux-based terminal spawning
- Automatic retry with timing variations
- Ensures Claude Code starts without manual intervention

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

**System requirements:**
```bash
# Required for all hooks
sudo apt-get install jq  # JSON processing (required for terminal communication)

# Optional but recommended
sudo apt-get install tmux  # For VS Code terminal spawning
sudo apt-get install shellcheck  # Shell script linting
```

**Python tools (for code validation):**
```bash
pip install mypy flake8 black pytest
```

**R tools (for R validation):**
```bash
# Install R
sudo apt-get install r-base  # Ubuntu/Debian
# or
brew install r  # macOS

# Install lintr (optional)
Rscript -e "install.packages('lintr')"
```

### Setup

1. **Clone or copy the hooks to your Claude Code directory:**
   ```bash
   git clone https://github.com/Secrettestbot/claude_hooks.git ~/.claude-hooks-temp
   cp -r ~/.claude-hooks-temp/hooks ~/.claude/
   cp ~/.claude-hooks-temp/*.sh ~/.claude/
   cp ~/.claude-hooks-temp/TERMINAL_SPAWNING_GUIDE.md ~/.claude/
   rm -rf ~/.claude-hooks-temp
   chmod +x ~/.claude/*.sh
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

## Usage Guide

### Terminal Spawning

Spawn multiple Claude Code terminals with natural language:

```
"Claude spawn two terminals named T1 and T2"
"Spawn terminals named Backend, Frontend, and Tests"
"Create 3 terminals called Worker1, Worker2, Worker3"
```

The spawner automatically:
- Detects your terminal emulator
- Creates new terminal windows/tabs
- Enables inter-terminal communication
- Registers terminals for coordination

See `TERMINAL_SPAWNING_GUIDE.md` for detailed VS Code and tmux usage.

### Inter-Terminal Communication

Once terminals are spawned, coordinate between them:

```
In Terminal T1:
"Send a message to T2: Run the test suite"

In Terminal T2:
(Automatically receives message via PreToolUse hook)
"Send a message to T1: All tests passed!"
```

### Project Management

**Save current terminal setup:**
```
"Save this as project myapp"
```

**List available projects:**
```
"What projects do I have?"
```

**Start a saved project:**
```
"Start working on project myapp"
```

Projects are saved as JSON in `~/.claude/projects/` and can include:
- Terminal names and working directories
- Context files to auto-load
- Custom system prompts per terminal

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

**Essential:**
- Claude Code (with hooks support)
- Bash shell
- `jq` (JSON processor - required for terminal communication)

**Optional:**
- Python 3.x with mypy, flake8, black, pytest (for Python validation)
- R with lintr (for R validation)
- tmux (recommended for VS Code terminal spawning)
- ShellCheck (for shell script validation)

## License

MIT License - Feel free to modify and use as needed

## Credits

- Based on the Claude Code hooks system
- Terminal spawning and inter-terminal communication inspired by tmux and multi-agent workflows
- Code validation inspired by the principle that feedback loops improve AI output quality by 2-3x
- Project management inspired by IDE workspace concepts

## Contributing

Contributions are welcome! Areas for improvement:

- Support for additional terminal emulators
- Enhanced project templates
- Additional validation tools (Go, Rust, etc.)
- Message queue improvements
- Better VS Code integration

Feel free to submit issues or pull requests at https://github.com/Secrettestbot/claude_hooks

## Additional Documentation

- `TERMINAL_SPAWNING_GUIDE.md` - Comprehensive guide for terminal spawning and project management
- `~/.claude/projects/README.md` - Project configuration format reference
- Hook source files contain detailed inline documentation
