#!/bin/bash
# canary.sh — tripwires for a lead ("header") Claude session. Two uses:
#   as a UserPromptSubmit hook: reads the hook JSON on stdin, prints a notice into the session only when a canary is warm or tripped
#   by hand:  canary.sh --check [session-id]     prints the measurements and OK | WARN | TRIP
# Only sessions registered in ~/.claude/handover/lead-sessions are checked. Everything else exits silently.
# Scope: only the herdr workspaces listed in ~/.claude/handover/workspaces (one id per line).
grep -qx "${HERDR_WORKSPACE_ID:-none}" "$HOME/.claude/handover/workspaces" 2>/dev/null || exit 0
H="$HOME/.claude/handover"
if [ "${1:-}" = "--check" ]; then sid="${2:-${CLAUDE_CODE_SESSION_ID:-}}"; tp=""; mode=check
else in=$(cat 2>/dev/null); sid=$(printf '%s' "$in" | python3 -c "import sys,json;print(json.load(sys.stdin).get('session_id',''))" 2>/dev/null); tp=$(printf '%s' "$in" | python3 -c "import sys,json;print(json.load(sys.stdin).get('transcript_path',''))" 2>/dev/null); mode=hook; fi
[ -n "$sid" ] || exit 0
grep -qx "$sid" "$H/lead-sessions" 2>/dev/null || { [ "$mode" = check ] && echo "session $sid is not a registered lead"; exit 0; }
[ -f "$tp" ] || tp=$(ls "$HOME"/.claude/projects/*/"$sid".jsonl 2>/dev/null | head -1)
[ -f "$tp" ] || exit 0
compactions=$(grep -c '"subtype":"compact_boundary"' "$tp" 2>/dev/null); compactions=${compactions:-0}
# live context size in thousands of tokens, from the newest usage record in the transcript
ctx=$(tail -c 3000000 "$tp" | python3 -c "
import sys,json
k=0
for line in sys.stdin.buffer.read().decode('utf-8','replace').split('\n'):
    if '\"usage\"' not in line: continue
    try: u=json.loads(line).get('message',{}).get('usage') or {}
    except Exception: continue
    t=(u.get('input_tokens') or 0)+(u.get('cache_read_input_tokens') or 0)+(u.get('cache_creation_input_tokens') or 0)
    if t: k=t//1000
print(k)" 2>/dev/null); ctx=${ctx:-0}
strikes=$(grep -c . "$H/strikes/$sid.log" 2>/dev/null); strikes=${strikes:-0}
state=OK; why=""
[ "$ctx" -ge 350 ] && { state=WARN; why="context ${ctx}k tokens"; }
[ "$strikes" -ge 2 ] && { state=WARN; why="$why; $strikes sloppiness strikes"; }
[ "$ctx" -ge 500 ] && { state=TRIP; why="context ${ctx}k tokens"; }
[ "$compactions" -ge 1 ] && { state=TRIP; why="$why; context was compacted $compactions time(s)"; }
[ "$strikes" -ge 3 ] && { state=TRIP; why="$why; $strikes sloppiness strikes"; }
line="context=${ctx}k compactions=$compactions strikes=$strikes -> $state${why:+ (${why#; })}"
if [ "$mode" = check ]; then echo "$line"; [ "$strikes" -gt 0 ] && sed 's/^/  strike: /' "$H/strikes/$sid.log"; exit 0; fi
[ "$state" = OK ] && exit 0
if [ "$state" = WARN ]; then echo "[handover canary] WARN: $line. Finish the current step carefully; write the handover document early. Skill: header-handover."
else echo "[handover canary] TRIPPED: $line. You are the lead session and your own tripwire has fired. Finish only the step in progress, then hand over to a fresh Claude session now, following the header-handover skill (~/.claude/skills/header-handover/SKILL.md). Tell the user in one line that you are doing so. Do not start new work in this session."; fi
exit 0
