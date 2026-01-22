---
allowed-tools: Bash(bash:~/.claude/hooks/spawn-terminal.sh *)
description: Spawn multiple Claude Code terminals with communication enabled
---

Spawn multiple terminals. Usage: `/spawn <terminal1> <terminal2> ...`

Execute the spawn script with terminal names. The script will:
1. Spawn new terminal windows/tabs
2. Enable inter-terminal communication
3. Register each terminal with its unique name
4. Start Claude Code in each terminal

Example: `/spawn T1 T2 T3` will run:
```bash
bash ~/.claude/hooks/spawn-terminal.sh T1 T2 T3
```
