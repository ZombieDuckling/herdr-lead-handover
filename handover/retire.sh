#!/bin/bash
# retire.sh [seconds] — the LAST command a retiring lead runs, after the successor's ack exists and just before its final message to the user.
# It marks this generation retired and closes this session's own herdr tab after a delay (default 90 s), so the final message is delivered first.
grep -qx "${HERDR_WORKSPACE_ID:-none}" "$HOME/.claude/handover/workspaces" 2>/dev/null || { echo "the handover protocol does not apply in this herdr workspace"; exit 1; }
H="$HOME/.claude/handover"; delay="${1:-90}"; tab="${HERDR_TAB_ID:?no herdr tab id}"
succ=$(tail -1 "$H/lead-sessions"); [ "$succ" != "${CLAUDE_CODE_SESSION_ID:-}" ] || { echo "no successor is registered yet; do not retire"; exit 1; }
grep -vx "${CLAUDE_CODE_SESSION_ID:-none}" "$H/lead-sessions" > "$H/l.tmp" && mv "$H/l.tmp" "$H/lead-sessions"
echo "$(date '+%Y-%m-%d %H:%M') retired ${CLAUDE_CODE_SESSION_ID:-?} tab=$tab closes in ${delay}s" >> "$H/log.md"
nohup sh -c "sleep $delay; herdr tab close '$tab'" >/dev/null 2>&1 &
echo "this tab ($tab) closes in ${delay}s; send the final message now and do nothing else"
