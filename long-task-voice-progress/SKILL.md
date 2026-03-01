---
name: long-task-voice-progress
description: Emit clear progress updates by default for most non-trivial tasks and speak milestone status. Use whenever work has multiple phases, may include long-running commands or tests, involves waiting on tools or agents, or benefits from hands-free audible status.
---

# Long Task Voice Progress

## Overview

Emit concise milestone updates aligned to real execution state so progress reports stay trustworthy.

## Trigger Heuristics

Use this skill by default for non-trivial work, especially when any of the following are true:

- The task has `>=2` phases (for example: discovery, implementation, validation, completion).
- You are about to run commands or tests that may take `>30s`.
- You are waiting on tools, background jobs, or sub-agents and progress may otherwise appear stalled.

## Workflow

1. Announce the interpreted task and first action.
2. Announce each major phase transition (context, implementation, validation, completion).
3. Announce blockers with the blocked step and immediate recovery action.
4. When user input is required, emit a spoken "input needed" cue before prompting.
5. Announce completion with what changed and what verification ran.

## Mode Compatibility

This skill is valid in both collaboration modes.

- In `Default` mode, ask the user directly when input is required.
- In `Plan` mode, use `request_user_input` for structured choices when possible.
- In both modes, emit the same voice/text progress milestones.

## Input Needed Cues

Whenever you need the user to decide or provide missing information:

1. Announce the need first:
   `bash scripts/say-progress.sh "Input needed: choose deployment target"`
2. Then request the input using the active mode:
   - `Plan` mode: call `request_user_input`.
   - `Default` mode: ask a concise direct question in chat.
3. If waiting may exceed 60 seconds, emit a brief waiting update every 60 seconds.

## Message Rules

- Keep spoken messages short (target under 18 words).
- Use present-tense action verbs and include the next concrete action.
- Mention concrete artifacts when relevant (`file`, `service`, `test suite`, `migration`).
- Avoid filler or generic status text.

## Invocation

Run the helper script via Bash to emit an audible progress update:

```
bash scripts/say-progress.sh "Starting test suite for auth module"
```

The script path is relative to this skill directory. Use the full path when invoking from elsewhere:

The script always emits a `[progress]` text line to stdout regardless of audio availability, so progress is visible even when muted or on a headless machine.
