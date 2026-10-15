# herdr lead handover

Two [Claude Code](https://claude.com/claude-code) skills and four shell scripts for running a long-lived
"lead" Claude session inside the herdr terminal multiplexer:

- **`skills/herdr-orchestration`**: how a lead session picks worker agents (OpenCode, Codex, Claude),
  launches them in herdr tabs, briefs them, monitors them without polling, verifies their work and
  tidies up. `brief-template.md` is a Simplified Technical English brief for literal local models.
- **`skills/header-handover`**: tripwires ("canaries") that make the lead replace itself with a fresh
  session before it degrades, and the handover procedure each generation follows. Every successor is
  bound by the same tripwires.
- **`handover/`**: the scripts the handover skill drives.

| Script | What it does |
|---|---|
| `canary.sh` | `UserPromptSubmit` hook. Measures live context size, compactions and recorded strikes for registered lead sessions, and prints a WARN or TRIPPED notice into the session. `canary.sh --check` prints the numbers. |
| `strike.sh "<what happened>"` | The lead records one of its own mistakes. Three strikes trips the canary. |
| `handover.sh <doc.md>` | Opens a new herdr tab, starts the successor Claude session and briefs it with the handover document. |
| `retire.sh [seconds]` | The old lead's last command: unregisters it and closes its tab after a delay. |

Thresholds (in `canary.sh`): warn at 350k tokens of context or 2 strikes; trip at 500k tokens,
1 compaction, or 3 strikes.

## Install

```sh
mkdir -p ~/.claude/skills ~/.claude/handover/docs ~/.claude/handover/strikes
cp -R skills/* ~/.claude/skills/
cp handover/*.sh ~/.claude/handover/ && chmod +x ~/.claude/handover/*.sh
echo 1 > ~/.claude/handover/generation
touch ~/.claude/handover/lead-sessions
# opt a herdr workspace in (one id per line); nothing runs anywhere else
echo "$HERDR_WORKSPACE_ID" >> ~/.claude/handover/workspaces
```

Register the hook in `~/.claude/settings.json`:

```json
{
  "hooks": {
    "UserPromptSubmit": [
      { "hooks": [ { "type": "command", "command": "bash ~/.claude/handover/canary.sh" } ] }
    ]
  }
}
```

Then, in the lead session, register it as the first generation:
`echo "$CLAUDE_CODE_SESSION_ID" >> ~/.claude/handover/lead-sessions`.

## Notes

- `handover.sh` starts the successor with `--dangerously-skip-permissions`, so it has the same
  unattended permissions as a lead started that way. Remove the flag if your lead runs with prompts.
- Requires bash, python3 and the `herdr` CLI. Tested on macOS.
- Handover documents, strike logs and the generation log stay under `~/.claude/handover/`; nothing
  is sent anywhere.

## License

MIT, see `LICENSE`.
