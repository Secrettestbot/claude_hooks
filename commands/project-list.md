---
allowed-tools: Bash(~/.claude/hooks/project-list.sh:*)
description: List all available Claude Code projects
---

## Task

List all available Claude Code projects with their configurations.

## Usage

```
/project-list
```

**No arguments required**

## What this shows

For each project, displays:
- Project name
- Description
- Number of terminals
- Terminal names
- Number of context files
- Context file names (if any)

## Example Output

```
Available Projects:

  • webapp
    Description: My web application project
    Terminals: 3 (Frontend, Backend, Tests)
    Context files: 2 (README.md, api-docs.md)

  • ml-project
    Description: Machine learning pipeline
    Terminals: 5 (T1, T2, T3, T4, Tester)
    Context files: 3 (task_assignments.md, README.md, results.md)
```

## Next Steps

After viewing the list:
- Start a project with `/project-start <name>`
- Create a new project with `/project-save <name>`
- Edit project configuration in `~/.claude/projects/`
- Edit context files in `~/.claude/context/<project-name>/`

## JSON Output

For programmatic use, the underlying script supports `--json` flag:
```bash
~/.claude/hooks/project-list.sh --json
```
