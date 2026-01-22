---
allowed-tools: Bash(bash:~/.claude/hooks/terminal-comm-send.sh * *)
description: Send a message to another terminal
---

Send a message to another terminal. Usage: `/terminal-send <to> <message>`

Execute the send message script with the destination terminal and message. The script will:
1. Validate communication is enabled
2. Create message in `~/.claude/terminal-comm/messages/`
3. Message will be delivered via recipient's PreToolUse hook

Example: `/terminal-send Backend Database is ready` will run:
```bash
bash ~/.claude/hooks/terminal-comm-send.sh Backend "Database is ready"
```

Note: Multi-word messages should be quoted.
