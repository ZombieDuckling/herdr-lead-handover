#!/bin/bash
# handover.sh <handover-doc.md> — start the successor lead session in a new herdr tab and brief it. Prints the successor's tab id.
# The successor registers itself as lead, takes the "bossman" label, focuses its tab, and retires this one (see the skill).
# Scope: only the herdr workspaces listed in ~/.claude/handover/workspaces (one id per line).
grep -qx "${HERDR_WORKSPACE_ID:-none}" "$HOME/.claude/handover/workspaces" 2>/dev/null || { echo "the handover protocol does not apply in this herdr workspace (${HERDR_WORKSPACE_ID:-none}); it is scoped to: $(tr '\n' ' ' < $HOME/.claude/handover/workspaces)"; exit 1; }
set -u
H="$HOME/.claude/handover"; DOC="${1:?handover document path}"; [ -s "$DOC" ] || { echo "handover document missing or empty: $DOC"; exit 1; }
[ "${HERDR_ENV:-}" = 1 ] || { echo "not inside herdr"; exit 1; }
gen=$(( $(cat "$H/generation" 2>/dev/null || echo 1) + 1 )); name="bossman-g$gen"
out=$(herdr tab create --workspace "$HERDR_WORKSPACE_ID" --cwd "$HOME" --label "$name" --no-focus)
P=$(echo "$out" | grep -oE '"pane_id":"[^"]*"' | head -1 | cut -d'"' -f4); T=$(echo "$out" | grep -oE '"tab_id":"[^"]*"' | head -1 | cut -d'"' -f4)
[ -n "$P" ] || { echo "could not create a tab: $out"; exit 1; }
old_tab=$(herdr agent list | python3 -c "import sys,json,os;print(next((a['tab_id'] for a in json.load(sys.stdin)['result']['agents'] if a.get('pane_id')==os.environ.get('HERDR_PANE_ID')),''))")
herdr agent start "$name" --kind claude --pane "$P" --timeout 60000 -- --dangerously-skip-permissions >/dev/null 2>&1
# Claude may stop on the folder-trust prompt (cursor starts on "No, exit"). The agent is not registered until it is answered, so drive the pane.
for i in 1 2 3 4 5 6; do sleep 4
  if herdr pane read "$P" 2>/dev/null | grep -q 'Yes, I trust this folder'; then herdr pane send-keys "$P" down enter >/dev/null 2>&1; sleep 6; fi
  herdr agent get "$name" 2>/dev/null | grep -q '"agent_status":"idle"' && break
done
herdr agent get "$name" 2>/dev/null | grep -q '"agent_status"' || { echo "successor did not start; read the pane: herdr pane read $P"; exit 1; }
cat > "$H/docs/brief-g$gen.md" <<BRIEF
You are generation $gen of the lead ("bossman") session for the user. The previous lead (session ${CLAUDE_CODE_SESSION_ID:-unknown}, herdr tab ${old_tab:-unknown}) tripped its handover canary and is handing its whole job to you. You replace it.

Do these in order before anything else:
1. Run:  echo "\$CLAUDE_CODE_SESSION_ID" >> ~/.claude/handover/lead-sessions && echo $gen > ~/.claude/handover/generation
2. Read ~/.claude/skills/header-handover/SKILL.md completely. Its canaries and its handover procedure now bind you, and every lead after you.
3. Read ~/.claude/skills/herdr-orchestration/SKILL.md, then the handover document: $DOC . Read it completely. Verify its claims about running jobs and repo state with commands before relying on them.
4. Run:  herdr tab rename ${old_tab:-OLD_TAB} retired-g$((gen-1)) ; herdr tab rename $T bossman ; herdr tab focus $T
5. Write one line to ~/.claude/handover/docs/ack-g$gen.txt saying what you understand the open work to be.
6. Tell the user in two or three sentences that you have taken over, what is in flight, and what you will do next. Then continue the work in the handover document.
7. The retired lead closes its own tab (${old_tab:-OLD_TAB}) about 90 seconds after it retires. Two minutes after your acknowledgement, run herdr tab list; if that tab is still open, close it yourself: herdr tab close ${old_tab:-OLD_TAB} . A retired lead never stays open.
BRIEF
herdr agent prompt "$name" "$(cat "$H/docs/brief-g$gen.md")" >/dev/null 2>&1 || { echo "could not prompt the successor; tab $T is open, brief at $H/docs/brief-g$gen.md"; exit 1; }
echo "$(date '+%Y-%m-%d %H:%M') g$((gen-1)) (${CLAUDE_CODE_SESSION_ID:-?}) -> g$gen tab=$T doc=$DOC reason=$("$H/canary.sh" --check 2>/dev/null | head -1)" >> "$H/log.md"
echo "successor $name started in tab $T; ack will appear at $H/docs/ack-g$gen.txt"
