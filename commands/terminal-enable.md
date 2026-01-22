---
allowed-tools: Bash(~/.claude/hooks/terminal-comm-enable.sh:*)
description: Enable inter-terminal communication for this session
---

## Task

Enable inter-terminal communication for the current Claude Code session.

## Usage

```
/terminal-enable <terminal-name>
```

**Arguments:**
- `<terminal-name>` (required): A unique name for this terminal

## What this does

1. Registers this terminal with the given name
2. Creates a session configuration in `~/.claude/terminal-comm/sessions/`
3. Enables message sending and receiving
4. Makes this terminal discoverable by other terminals

## Example

Enable communication with name "Frontend":
```
/terminal-enable Frontend
```

## After Enabling

Once enabled, you can:
- Send messages to other terminals using `/terminal-send`
- Receive messages from other terminals (shown in PreToolUse hook)
- Coordinate work across multiple Claude instances

## Check Status

The session-start hook will show if communication is enabled:
```
💬 Inter-Terminal Communication: ENABLED
   Terminal name: Frontend
```

## Terminal Names

Choose descriptive names that reflect the terminal's purpose:
- Frontend, Backend, Database
- T1, T2, T3, T4
- Worker1, Worker2, Worker3
- Dev, Test, Deploy

Names must be unique across active terminals.

## Notes

- Terminals spawned with `/spawn` have communication auto-enabled
- Projects started with `/project-start` have communication auto-enabled
- Session data auto-cleans after 24 hours of inactivity
