---
allowed-tools: Bash(~/.claude/hooks/spawn-terminal.sh:*)
description: Spawn multiple Claude Code terminals with communication enabled
---

## Task

Spawn multiple Claude Code terminals with automatic inter-terminal communication setup.

## Usage

```
/spawn <terminal1> <terminal2> [terminal3] ...
```

**Arguments:**
- One or more terminal names (space-separated)

## What this does

1. Spawns new terminal windows/tabs
2. Automatically enables inter-terminal communication
3. Registers each terminal with its unique name
4. Sets up the current working directory for each terminal
5. Starts Claude Code in each terminal

## Examples

Spawn two terminals:
```
/spawn T1 T2
```

Spawn multiple terminals:
```
/spawn Frontend Backend Database Tests
```

Spawn five worker terminals:
```
/spawn Worker1 Worker2 Worker3 Worker4 Worker5
```

## Features

- **Auto-detection**: Automatically detects your terminal emulator (gnome-terminal, konsole, kitty, xterm, etc.)
- **VS Code support**: Creates tmux sessions in VS Code if tmux is available
- **Communication**: Terminals can send messages to each other using `/terminal-send`
- **Auto-registration**: Terminals are automatically registered and can discover each other

## Next Steps

After spawning:
- Terminals will start with communication enabled
- Use `/terminal-send <to> <message>` to coordinate
- Save the setup with `/project-save <name>` for later reuse

## Terminal Emulator Support

Supported terminal emulators:
- gnome-terminal
- konsole (KDE)
- kitty
- alacritty
- xterm
- terminator
- tilix
- xfce4-terminal
- mate-terminal
- VS Code (with tmux)
