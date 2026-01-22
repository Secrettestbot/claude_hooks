---
allowed-tools: Bash(bash:~/.claude/hooks/project-start.sh *)
description: Start a saved project with multiple terminals
---

Start a saved project. Usage: `/project-start <name>`

Execute the project start script with the project name. The script will:
1. Load configuration from `~/.claude/projects/<name>.json`
2. Spawn all configured terminals
3. Enable inter-terminal communication
4. Load context files from `~/.claude/context/<name>/`

Example: `/project-start webapp` will run:
```bash
bash ~/.claude/hooks/project-start.sh webapp
```
