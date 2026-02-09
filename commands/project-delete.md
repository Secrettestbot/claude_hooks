---
allowed-tools: Bash(bash:~/.claude/hooks/project-delete.sh *)
description: Delete a Claude Code project
---

Delete a project configuration and its associated context files. Usage: `/project-delete <name> [--force]`

Execute the project delete script with the provided project name. The script will:
1. Display project details (description, terminals, context files)
2. Show all files that will be deleted
3. Ask for confirmation (type project name to confirm)
4. Delete project configuration from `~/.claude/projects/<name>.json`
5. Delete context directory `~/.claude/context/<name>/` if it exists

Example: `/project-delete webapp` will run:
```bash
bash ~/.claude/hooks/project-delete.sh webapp
```

To skip confirmation prompt, use `--force` flag:
```bash
bash ~/.claude/hooks/project-delete.sh webapp --force
```

**Warning:** This action cannot be undone. All project configuration and context files will be permanently deleted.
