# Claude Handoff System

This repository is the central record for all Claude Code sessions. It captures:

- **Session logs** — prompts, responses, and tool usage per session
- **Session summaries** — what changed and why, written at the end of each session
- **Code changes** — any files created or edited during sessions

## Structure

```
claude-handoff/
├── sessions/
│   ├── YYYY-MM-DD_HH-MM-SS/
│   │   ├── summary.md        # What was done this session
│   │   └── changes.md        # Files changed and why
├── README.md
└── CHANGELOG.md
```

## How it works

Claude Code hooks automatically commit and push changes here after each session.
The `sessions/` folder gives a full audit trail across all chats.
