---
allowed-tools: Bash(bash:~/.claude/hooks/project-save.sh *)
description: Save current multi-terminal setup as a project
---

Save the current terminal setup as a project. Usage: `/project-save <name> [description]`

Execute the project save script with the provided arguments. The script will:
1. Save terminal configuration to `~/.claude/projects/<name>.json`
2. Prompt for context files to include
3. Copy context files to `~/.claude/context/<name>/`

Example: `/project-save webapp "My web application"` will run:
```bash
bash ~/.claude/hooks/project-save.sh webapp "My web application"
```
