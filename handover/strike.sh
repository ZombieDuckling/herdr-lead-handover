#!/bin/bash
# strike.sh "<what went wrong>" — the lead records its own sloppiness. Three strikes trips the canary.
# Scope: only the herdr workspaces listed in ~/.claude/handover/workspaces (one id per line).
grep -qx "${HERDR_WORKSPACE_ID:-none}" "$HOME/.claude/handover/workspaces" 2>/dev/null || { echo "the handover protocol does not apply in this herdr workspace (${HERDR_WORKSPACE_ID:-none}); it is scoped to: $(tr '\n' ' ' < $HOME/.claude/handover/workspaces)"; exit 1; }
H="$HOME/.claude/handover"; sid="${CLAUDE_CODE_SESSION_ID:?no session id}"
echo "$(date '+%Y-%m-%d %H:%M') $*" >> "$H/strikes/$sid.log"; "$H/canary.sh" --check "$sid"
