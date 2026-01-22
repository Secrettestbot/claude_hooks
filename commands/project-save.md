---
allowed-tools: Bash(~/.claude/hooks/project-save.sh:*)
description: Save current multi-terminal setup as a project
---

## Task

Save the current multi-terminal setup as a project configuration.

## Usage

```
/project-save <project-name> [description]
```

**Arguments:**
- `<project-name>` (required): Name for the project
- `[description]` (optional): Brief description of the project

## What this does

1. Saves the current terminal configuration to `~/.claude/projects/<project-name>.json`
2. Prompts you to specify context files to include
3. Copies context files to `~/.claude/context/<project-name>/`
4. Stores terminal names, working directories, and configurations

## Example

To save a project called "webapp":
```
/project-save webapp "My web application project"
```

You will then be prompted to enter context files for each terminal.

## Next Steps

After saving, you can:
- Start the project later with `/project-start webapp`
- List all projects with `/project-list`
- Edit context files in `~/.claude/context/webapp/`
