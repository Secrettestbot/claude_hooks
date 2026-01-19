# Claude Code Terminal Spawning & Project Management Guide

Your Claude Code installation now supports natural language terminal spawning and project management!

## Terminal Spawning

### Basic Usage

Simply ask Claude in natural language to spawn terminals:

```
"Claude spawn two minions named T1 and T2"
"Spawn terminals named Backend, Frontend, and Database"
"Create 3 terminals called Worker1, Worker2, and Worker3"
```

Claude will recognize your intent and call the spawn script automatically.

### What Happens

1. New terminal windows/tabs open (detects your terminal emulator automatically)
2. Each terminal starts with communication enabled
3. Terminals auto-register with their assigned names
4. All terminals can immediately communicate with each other

### Supported Terminal Emulators

**Standalone terminals:**
- gnome-terminal
- konsole
- xterm
- alacritty
- kitty
- terminator
- tilix
- xfce4-terminal
- mate-terminal

**VS Code:**
- Detects VS Code automatically
- **With tmux** (recommended): Creates tmux windows/sessions automatically
- **Without tmux**: Creates launcher scripts you run in new VS Code terminals
- Install tmux for best experience: `sudo apt-get install tmux`

## Project Management

### Listing Projects

Ask Claude:
```
"What projects do I have?"
"List my projects"
"Show available projects"
```

Or run directly:
```bash
~/.claude/hooks/project-list.sh
```

### Starting a Project

Ask Claude:
```
"Start working on project example"
"Load the example project"
"Begin project myapp"
```

This will:
- Spawn all configured terminals for the project
- Set each terminal's working directory
- Load context files (if configured)
- Apply custom system prompts (if configured)
- Enable inter-terminal communication

### Saving a Project

First, spawn and configure your terminals. Then ask Claude:
```
"Save this as project myapp"
"Save the current terminal setup as webdev"
```

Or run directly:
```bash
~/.claude/hooks/project-save.sh myapp "My web development project"
```

This creates a project configuration file at `~/.claude/projects/myapp.json` with all currently active terminals.

### Customizing Projects

Edit the generated JSON files in `~/.claude/projects/`:

```json
{
  "name": "myapp",
  "description": "My application project",
  "terminals": [
    {
      "name": "Backend",
      "workdir": "~/projects/myapp/backend",
      "context_files": ["@src/api", "@tests", "@README.md"],
      "system_prompt": "You are working on the backend API. Focus on Python and FastAPI."
    },
    {
      "name": "Frontend",
      "workdir": "~/projects/myapp/frontend",
      "context_files": ["@src/components", "@package.json"],
      "system_prompt": "You are working on the React frontend. Focus on TypeScript and UI components."
    }
  ]
}
```

**Fields:**
- `name`: Terminal identifier for communication
- `workdir`: Starting directory (supports ~ expansion)
- `context_files`: Files/directories to include using @ syntax
- `system_prompt`: Custom instructions for this terminal

## Inter-Terminal Communication

Once terminals are spawned, they can communicate:

```
In Terminal T1:
"Send a message to T2: Check the API endpoint status"

In Terminal T2:
(Receives message automatically via PreToolUse hook)
"Send a message to T1: API is running on port 8000"
```

Messages appear automatically when terminals perform actions.

## Example Workflow

1. **Create a new project setup:**
   ```
   You: "Claude spawn terminals named Backend, Frontend, and Tests"
   Claude: (spawns 3 terminals)

   You: "Save this as project webapp"
   Claude: (creates webapp.json)
   ```

2. **Customize the project:**
   ```bash
   nano ~/.claude/projects/webapp.json
   # Edit working directories and context files
   ```

3. **Restart project later:**
   ```
   You: "Start working on project webapp"
   Claude: (spawns all 3 terminals with configs)
   ```

4. **Coordinate work:**
   ```
   In Backend terminal:
   "Send a message to Frontend: API schema updated, check /docs"

   In Frontend terminal:
   (Receives message and can update accordingly)
   ```

## Files Created

- `~/.claude/hooks/spawn-terminal.sh` - Terminal spawner
- `~/.claude/hooks/project-start.sh` - Project loader
- `~/.claude/hooks/project-list.sh` - Project lister
- `~/.claude/hooks/project-save.sh` - Project saver
- `~/.claude/hooks/session-start.sh` - Enhanced with auto-communication
- `~/.claude/projects/` - Project configurations directory
- `~/.claude/projects/README.md` - Project config format reference

## VS Code Specific Usage

When running in VS Code, the spawn system works differently:

### Option 1: With tmux (Recommended)

Install tmux for seamless terminal spawning:
```bash
sudo apt-get install tmux  # Debian/Ubuntu
# or
brew install tmux          # macOS
```

With tmux installed, spawned terminals appear as tmux sessions:
- `tmux ls` - List all sessions
- `tmux attach -t claude-T1` - Attach to terminal T1
- `Ctrl+b w` - Switch between windows

### Option 2: Without tmux (Manual Launch)

Without tmux, launcher scripts are created:
1. Say: "Claude spawn two minions named T1 and T2"
2. Claude creates `/tmp/claude-launch-T1.sh` and `/tmp/claude-launch-T2.sh`
3. Open new VS Code terminals (Ctrl+Shift+\`)
4. Run the launcher scripts: `/tmp/claude-launch-T1.sh`

Each launcher automatically:
- Sets up the terminal name
- Enables communication
- Starts Claude Code

## Troubleshooting

**Terminals not spawning in VS Code:**
- Install tmux for automatic spawning: `sudo apt-get install tmux`
- Without tmux, manually run the printed launcher scripts in new terminals
- Check launcher scripts exist: `ls /tmp/claude-launch-*.sh`

**Terminals not spawning (standalone):**
- Check that your terminal emulator is supported
- Verify scripts are executable: `chmod +x ~/.claude/hooks/*.sh`
- Set `TERMINAL_EMULATOR` environment variable if auto-detection fails

**Communication not working:**
- Verify terminals are registered: Check `~/.claude/terminal-comm/terminals.json`
- Ensure jq is installed: `sudo apt-get install jq`
- Check session configs in `~/.claude/terminal-comm/sessions/`

**Project not found:**
- List projects: `~/.claude/hooks/project-list.sh`
- Check file exists: `ls ~/.claude/projects/`
- Validate JSON: `jq empty ~/.claude/projects/yourproject.json`

## Tips

- Use descriptive terminal names for easier communication
- Keep project configs in version control (exclude from .gitignore)
- Test new projects with the example config first
- Terminals auto-cleanup stale registrations after 24 hours
- You can manually edit `~/.claude/terminal-comm/terminals.json` if needed

Enjoy your multi-terminal Claude Code workflow!
