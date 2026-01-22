---
allowed-tools: Bash(~/.claude/hooks/terminal-comm-send.sh:*)
description: Send a message to another terminal
---

## Task

Send a message to another Claude Code terminal for coordination and communication.

## Usage

```
/terminal-send <to-terminal> <message>
```

**Arguments:**
- `<to-terminal>` (required): Name of the destination terminal
- `<message>` (required): Message to send

## What this does

1. Validates that communication is enabled for this session
2. Creates a message in `~/.claude/terminal-comm/messages/`
3. Message will be delivered to the recipient terminal via PreToolUse hook
4. Recipient will see the message before their next tool execution

## Examples

Send a simple message:
```
/terminal-send Backend Database schema is ready
```

Request an action:
```
/terminal-send Frontend Please update the API endpoint to use v2
```

Notify of completion:
```
/terminal-send T1 Tests passed, ready for merge
```

## Message Delivery

Messages are delivered when the recipient terminal:
- Executes any tool (triggers PreToolUse hook)
- Starts a new session (session-start hook checks for messages)

Messages appear in the recipient's terminal like:
```
📨 New message from Frontend:
   "Database schema is ready"
```

## Prerequisites

- This terminal must have communication enabled (`/terminal-enable`)
- The recipient terminal must exist and be registered
- Both terminals must be part of the same communication network

## Coordination Patterns

**Sequential work:**
```
T1: Complete task A
T1: /terminal-send T2 Task A complete, start task B
T2: (receives message and starts task B)
```

**Parallel coordination:**
```
Coordinator: /terminal-send Worker1 Process dataset 1
Coordinator: /terminal-send Worker2 Process dataset 2
Coordinator: /terminal-send Worker3 Process dataset 3
```

**Status updates:**
```
Backend: /terminal-send Frontend API is now ready on port 8000
Frontend: /terminal-send Tests Integration tests can now run
```

## Tips

- Keep messages concise and actionable
- Include specific details (file paths, URLs, commands)
- Use consistent naming conventions for terminals
- Messages are queued until the recipient checks them
