---
allowed-tools: Bash(bash:~/.claude/hooks/terminal-comm-enable.sh *)
description: Enable inter-terminal communication for this session
---

Enable terminal communication. Usage: `/terminal-enable <name>`

Execute the enable communication script with the terminal name. The script will:
1. Register this terminal with the given name
2. Create session configuration
3. Enable message sending/receiving
4. Make this terminal discoverable

Example: `/terminal-enable Frontend` will run:
```bash
bash ~/.claude/hooks/terminal-comm-enable.sh Frontend
```
