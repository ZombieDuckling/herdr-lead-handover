---
name: header-handover
description: For the lead ("bossman") Claude session of a herdr workspace that is opted in (its id is listed in ~/.claude/handover/workspaces); it does NOT apply to leads in any other workspace. Use there at the start of such a session, whenever a "[handover canary]" notice appears, after any mistake you make, or when the user says you are getting sloppy, heavy, or should hand over. Defines the tripwires that force a lead session to replace itself with a fresh one, and the handover procedure. Binds every successor.
---

# Lead-session canaries and self-handover

**Scope: opted-in workspaces only.** This applies when `$HERDR_WORKSPACE_ID` is listed in
`~/.claude/handover/workspaces` (one id per line). If you are a lead in any other
workspace, this skill does not bind you: do not
register as a lead, do not record strikes, do not hand over because of it. The scripts refuse to
run elsewhere. The user extends the scope by adding a workspace id to that file; nobody else does.

The user's rule: the lead session sets tripwires for itself. When one fires, it creates a
fresh Claude session, hands everything over, and is replaced by it. **The same tripwires bind the
successor, and its successor, without end.** A lead never argues with a tripped canary and never
loosens a threshold for itself. Only the user changes thresholds.

## The canaries

Measured by `~/.claude/handover/canary.sh`, which runs as a hook on every user message for
registered lead sessions and prints `[handover canary] WARN` or `TRIPPED` into the session.
Check by hand at any time: `~/.claude/handover/canary.sh --check`.

| Canary | Warn | Trip |
|---|---|---|
| Live context size | 350k tokens | 500k tokens |
| Context compactions in this session | | 1 |
| Sloppiness strikes | 2 | 3 |

**Strikes.** Record each one the moment it happens: `~/.claude/handover/strike.sh "<what happened>"`.
Be strict with yourself; an unrecorded strike defeats the point. A strike is any of:

1. You repeat a mistake that a skill, a memory or this conversation already warned about (zsh
   word-splitting, uppercase herdr names, a field or format you did not read before parsing it).
2. The same command or approach fails twice because you did not read the first failure.
3. You tell the user something as fact and later have to retract it.
4. The user rejects a tool call, or has to repeat an instruction, or says you are not doing what they asked.
5. You start a duplicate of something already running, or lose track of a job, tab, branch or agent.
6. You report work as done that was not verified, or skip a step and do not say so.
7. You catch yourself re-deriving something already settled, or unable to recall a standing rule
   without searching for it.

**Judgement canary.** If you notice the feel of it before the numbers do (answers getting longer,
checks getting skipped, hunting for state you should know), hand over anyway and say why.

## When a canary trips

1. Finish only the step in progress. Start nothing new. Leave running jobs running.
2. Tell the user in one line: which canary, and that you are handing over.
3. Write the handover document (layout below) to `~/.claude/handover/docs/handover-g<N+1>.md`.
   Write it from verified state: run the commands, do not trust your memory of them.
4. Run `~/.claude/handover/handover.sh <that document>`. It opens a new herdr tab, starts the
   successor with the same permissions, and briefs it to register itself, read this skill, take
   the `bossman` label, focus its tab and retire yours.
5. Wait for `~/.claude/handover/docs/ack-g<N+1>.txt`. If it does not appear in five minutes, read
   the successor's pane and fix the cause; do not start a second successor while one exists.
6. Hand any background shell the successor still needs over to it (tell it the command), because
   your tab is about to close and everything running in it dies.
7. Run `~/.claude/handover/retire.sh` as your LAST command. It unregisters you and closes your own
   tab after 90 seconds. **A retired lead never stays open**.
8. Final message to the user, immediately: the successor's tab, what is in flight, and that this tab
   closes itself in a minute. Do nothing further.

## Handover document layout

1. **Who and what**: the user, the projects in play, the role of the lead.
2. **Standing rules**: every instruction of the user's still in force, quoted where short. Include
   the rules that live only in this conversation.
3. **State, verified now**: repos and branches, deploys, open pull requests, CMS state.
4. **In flight**: every running job, agent, tab and background process, with how to check and stop each.
5. **Open work, in order**: the next action for each item, and what is blocked on the user.
6. **Where things are**: reports, scripts, the old scratchpad path, briefs, logs.
7. **Traps met this generation**: mistakes made and the strikes ledger, so they are not repeated.
8. **Questions awaiting the user's answer.**

## As the successor

Follow the brief you were started with: register (`lead-sessions`), read this skill and
`herdr-orchestration`, read the handover document, verify its claims, take the label, acknowledge,
tell the user. **Closing the retired lead is part of taking over:** two minutes after your acknowledgement, check `herdr tab list`; if the retired tab is still open, close it with `herdr tab close <tab>` and say so. Your strike count starts at zero. Your canaries are the same.
`~/.claude/handover/log.md` records every generation.
