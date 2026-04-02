#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd -- "$SCRIPT_DIR/.." && pwd)"
TMP_ROOT="${TMPDIR:-/tmp}/agent-sidecar-smoke"
ANALYSIS_FILE="$TMP_ROOT/analysis draft.md"
ANALYSIS_REVIEW_FILE="$TMP_ROOT/custom-output/analysis draft.review.json"
PLAN_DIR="$HOME/.claude/plans"
PLAN_FILE="$PLAN_DIR/agent-sidecar-smoke-plan.md"
PLAN_REVIEW_FILE="$PLAN_DIR/agent-sidecar-smoke-plan.review.json"
DIFF_REVIEW_BUNDLE="$REPO_ROOT/.agent-review/pending.json"

encode() {
  python3 -c 'import sys, urllib.parse; print(urllib.parse.quote(sys.argv[1]))' "$1"
}

section() {
  printf '\n== %s ==\n' "$1"
}

note() {
  printf '%s\n' "$1"
}

wait_for_user() {
  printf '\nPress Enter when you are done with this step...'
  read -r _
}

show_json_if_present() {
  local path="$1"
  if [[ -f "$path" ]]; then
    section "Captured JSON"
    cat "$path"
  else
    section "Captured JSON"
    note "No file found at: $path"
  fi
}

prepare_fixtures() {
  mkdir -p "$TMP_ROOT/custom-output" "$PLAN_DIR"

  cat > "$ANALYSIS_FILE" <<'EOF'
# Analysis

## Recommendation
Draft recommendation text.

- Point one
- Point two
EOF

  cat > "$PLAN_FILE" <<'EOF'
# Smoke Test Plan

1. Validate file review deeplink
2. Validate plan review submission
3. Validate diff review routing
EOF

  rm -f "$ANALYSIS_REVIEW_FILE" "$PLAN_REVIEW_FILE"
}

open_file_review() {
  local encoded_file encoded_review
  encoded_file="$(encode "$ANALYSIS_FILE")"
  encoded_review="$(encode "$ANALYSIS_REVIEW_FILE")"

  section "Step 1: Local File Review"
  note "Opening AgentSidecar with a markdown file whose path contains spaces."
  note "File:   $ANALYSIS_FILE"
  note "Review: $ANALYSIS_REVIEW_FILE"
  note "Check:"
  note "- The file-review screen opens, not the diff screen."
  note "- Hovering non-empty lines shows the + gutter action."
  note "- You can add and remove commands."
  note "- Request Changes stays disabled until a command exists."
  note "- Submit once with Request Changes, then reopen and test Approve."

  open "agentsidecar://file?file=${encoded_file}&review=${encoded_review}"
  wait_for_user
  show_json_if_present "$ANALYSIS_REVIEW_FILE"
}

open_plan_review() {
  local encoded_file
  encoded_file="$(encode "$PLAN_FILE")"

  section "Step 2: Plan Review Regression"
  note "Opening the existing plan-review route."
  note "Plan:   $PLAN_FILE"
  note "Review: $PLAN_REVIEW_FILE"
  note "Check:"
  note "- The plan-review screen opens."
  note "- You can add a comment to a line."
  note "- Request Changes writes a review JSON next to the plan."
  note "- Reopening and clicking Approve writes status approved."

  open "agentsidecar://plan?file=${encoded_file}"
  wait_for_user
  show_json_if_present "$PLAN_REVIEW_FILE"
}

open_diff_review() {
  local repo_root bundle
  if ! repo_root="$(git -C "$REPO_ROOT" rev-parse --show-toplevel 2>/dev/null)"; then
    section "Step 3: Diff Review Regression"
    note "Skipped: $REPO_ROOT is not inside a git repository."
    return
  fi

  bundle="$(encode "$DIFF_REVIEW_BUNDLE")"

  section "Step 3: Diff Review Regression"
  note "Opening the existing diff-review route against this repository."
  note "Repo:   $repo_root"
  note "Bundle: $DIFF_REVIEW_BUNDLE"
  note "Check:"
  note "- The split diff view opens."
  note "- Sidebar and detail panes both render."
  note "- Scope switching still works."
  note "- Saving review comments still writes the diff bundle."

  open "agentsidecar://open?repo=$(encode "$repo_root")&scope=workingTree&bundle=${bundle}"
  wait_for_user
  show_json_if_present "$DIFF_REVIEW_BUNDLE"
}

section "AgentSidecar Pre-Deploy Smoke Test"
note "Repo root: $REPO_ROOT"
note "This script prepares fixtures, opens each deeplink route, and pauses for manual verification."
note "Launch the app from Xcode first, then continue here."

prepare_fixtures
open_file_review
open_plan_review
open_diff_review

section "Done"
note "Artifacts kept for inspection:"
note "- $ANALYSIS_FILE"
note "- $ANALYSIS_REVIEW_FILE"
note "- $PLAN_FILE"
note "- $PLAN_REVIEW_FILE"
