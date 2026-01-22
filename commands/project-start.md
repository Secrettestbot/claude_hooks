---
allowed-tools: Bash(~/.claude/hooks/project-start.sh:*)
description: Start a saved project with multiple terminals
---

## Task

Start a Claude Code project with multiple pre-configured terminals.

## Usage

```
/project-start <project-name>
```

**Arguments:**
- `<project-name>` (required): Name of the project to start

## What this does

1. Loads project configuration from `~/.claude/projects/<project-name>.json`
2. Spawns all configured terminals with their working directories
3. Enables inter-terminal communication automatically
4. Loads context files from `~/.claude/context/<project-name>/`
5. Applies custom system prompts to each terminal

## Example

To start a project called "webapp":
```
/project-start webapp
```

This will:
- Open all terminals defined in the project
- Set correct working directories
- Load context files into each terminal's system prompt
- Enable communication between terminals

## Available Projects

Use `/project-list` to see all available projects.

## Notes

- Terminals will automatically detect your terminal emulator
- In VS Code, terminals may be created as tmux sessions
- Each terminal will have communication enabled with its configured name
