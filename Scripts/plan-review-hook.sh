#!/usr/bin/env bash
set -euo pipefail

PLANS_DIR="$HOME/.claude/plans"
POLL_INTERVAL=2
TIMEOUT=600  # 10 minutes

# Read hook input from stdin
INPUT="$(cat)"

# Require jq — exit 0 (non-blocking) if missing
if ! command -v jq &>/dev/null; then
  echo "plan-review-hook: jq required. Install: brew install jq" >&2
  exit 0
fi

# Guard: only intercept ExitPlanMode
TOOL_NAME="$(echo "$INPUT" | jq -r '.tool_name // empty')"
[[ "$TOOL_NAME" != "ExitPlanMode" ]] && exit 0

# Find the most recently modified plan file
PLAN_FILE="$(ls -t "$PLANS_DIR"/*.md 2>/dev/null | head -1 || true)"
[[ -z "$PLAN_FILE" ]] && exit 0

# Derive review file path
SLUG="$(basename "$PLAN_FILE" .md)"
REVIEW_FILE="$PLANS_DIR/${SLUG}.review.json"

# Clean stale review file
rm -f "$REVIEW_FILE"

# Open sidecar app (fails gracefully if plan route not implemented yet)
ENCODED_PATH="$(python3 -c "import urllib.parse,sys; print(urllib.parse.quote(sys.argv[1]))" "$PLAN_FILE")"
open "agentsidecar://plan?file=${ENCODED_PATH}" 2>/dev/null || true

# Poll for review
ELAPSED=0
while [[ $ELAPSED -lt $TIMEOUT ]]; do
  if [[ -f "$REVIEW_FILE" ]]; then
    STATUS="$(jq -r '.status // empty' "$REVIEW_FILE")"
    if [[ "$STATUS" == "approved" ]]; then
      rm -f "$REVIEW_FILE"
      exit 0
    elif [[ "$STATUS" == "changes_requested" ]]; then
      COMMENTS="$(jq -r '
        if (.comments | length) > 0 then
          (.comments | map(
            "> " + .line + "\n" + .comment
          ) | join("\n\n"))
        else
          "(no specific comments)"
        end
      ' "$REVIEW_FILE")"
      rm -f "$REVIEW_FILE"
      REASON="$(printf 'Plan review — changes requested:\n\n%s\n\nPlease revise the plan to address these comments before exiting plan mode.' "$COMMENTS")"
      jq -n --arg reason "$REASON" '{
        hookSpecificOutput: {
          hookEventName: "PreToolUse",
          permissionDecision: "deny",
          permissionDecisionReason: $reason
        }
      }'
      exit 0
    fi
  fi
  sleep "$POLL_INTERVAL"
  ELAPSED=$((ELAPSED + POLL_INTERVAL))
done

# Timeout
rm -f "$REVIEW_FILE"
jq -n '{
  hookSpecificOutput: {
    hookEventName: "PreToolUse",
    permissionDecision: "deny",
    permissionDecisionReason: "Plan review timed out after 10 minutes. Please review and try again."
  }
}'
exit 0
