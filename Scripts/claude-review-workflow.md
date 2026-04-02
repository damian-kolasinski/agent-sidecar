# Claude Code Review Workflow with AgentSidecar

This document describes how to integrate AgentSidecar into a Claude Code workflow for interactive diff review.

## Overview

AgentSidecar provides a GitHub-like diff review UI that Claude can trigger via deeplinks. The user reviews diffs visually, leaves inline comments, and those comments are persisted as structured JSON that Claude can read and act on.

AgentSidecar also supports reviewing any local text file. This is useful for artifacts like `tmp/analysis.md`, plans, specs, or generated notes that need a human review loop outside the terminal.

## Workflow Steps

### 1. Claude makes code changes

Claude edits files as part of normal coding work.

### 2. Claude opens AgentSidecar for review

```bash
open "agentsidecar://open?repo=$(git rev-parse --show-toplevel)&scope=workingTree&bundle=.agent-review/pending.json"
```

For staged changes:
```bash
open "agentsidecar://open?repo=$(git rev-parse --show-toplevel)&scope=staged&bundle=.agent-review/pending.json"
```

For branch diff against main:
```bash
open "agentsidecar://open?repo=$(git rev-parse --show-toplevel)&scope=branch&base=main&bundle=.agent-review/pending.json"
```

### 3. User reviews in AgentSidecar

- Browse changed files in the sidebar
- View colored diffs with line numbers
- Click the "+" icon on any line gutter to leave an inline comment
- Submit comments — they appear in collapsible threads below the line
- Use Cmd+S or the Save button to persist comments

### 4. Claude reads the review

```bash
cat .agent-review/pending.json
```

The JSON structure:
```json
{
  "version": 1,
  "repoPath": "/Users/damian/Developer/my-project",
  "scope": "workingTree",
  "createdAt": "2026-03-07T14:30:00Z",
  "comments": [
    {
      "id": "A1B2C3D4-...",
      "filePath": "Sources/App/main.swift",
      "lineAnchor": "_:15",
      "diffScope": "workingTree",
      "body": "Add a guard clause here for input validation.",
      "author": "human",
      "createdAt": "2026-03-07T14:31:00Z",
      "resolved": false
    }
  ]
}
```

### 5. Claude addresses each comment

For each comment, Claude:
1. Locates the file via `filePath`
2. Identifies the line via `lineAnchor` (format: `oldLineNumber:newLineNumber`, `_` for absent)
3. Makes the requested change
4. Marks the comment as `resolved: true` in the JSON

### 6. Claude marks comments as resolved

```bash
# Read and update the JSON, setting resolved=true for addressed comments
```

## Local File Review Workflow

### 1. Claude prepares a file for review

For example:

```bash
cat > /tmp/analysis.md <<'EOF'
# Analysis

## Recommendation
Draft recommendation text.
EOF
```

### 2. Claude opens AgentSidecar in file review mode

```bash
FILE_PATH="/tmp/analysis.md"
REVIEW_PATH="/tmp/analysis.review.json"

ENCODED_FILE=$(python3 -c 'import sys, urllib.parse; print(urllib.parse.quote(sys.argv[1]))' "$FILE_PATH")
ENCODED_REVIEW=$(python3 -c 'import sys, urllib.parse; print(urllib.parse.quote(sys.argv[1]))' "$REVIEW_PATH")

open "agentsidecar://file?file=${ENCODED_FILE}&review=${ENCODED_REVIEW}"
```

### 3. User reviews the file in AgentSidecar

- Browse the file line by line
- Hover a line to reveal the `+` gutter action
- Add a command describing the change needed on that line
- Click **Request Changes** to submit commands, or **Approve** to accept the file as-is

### 4. Claude reads the file review JSON

```bash
cat /tmp/analysis.review.json
```

The JSON structure:

```json
{
  "version": 1,
  "filePath": "/tmp/analysis.md",
  "status": "changes_requested",
  "commands": [
    {
      "lineNumber": 3,
      "line": "## Recommendation",
      "command": "Rename this heading to `## Proposed Approach`."
    }
  ],
  "reviewedAt": "2026-04-02T12:00:00Z"
}
```

### 5. Claude applies each command

For each command, Claude:
1. Locates the target using both `lineNumber` and `line`
2. Revises the file accordingly
3. Summarizes the applied changes
4. Reopens AgentSidecar for the next review round if needed

### 6. Approval ends the loop

An approved review writes:

```json
{
  "version": 1,
  "filePath": "/tmp/analysis.md",
  "status": "approved",
  "commands": [],
  "reviewedAt": "2026-04-02T12:05:00Z"
}
```

At that point Claude can stop iterating unless the user asks for more changes.

## Line Anchor Format

The `lineAnchor` field uses the format `old:new` where:
- `"10:10"` — a context line at line 10 in both old and new
- `"5:_"` — a deleted line (was line 5 in old file)
- `"_:8"` — an added line (is line 8 in new file)

## Claude Code Hook Integration

### Diff Review Hook (post-edit)

You can set up a post-edit hook in `.claude/settings.json`:

```json
{
  "hooks": {
    "postToolUse": [
      {
        "tools": ["write", "edit"],
        "command": "echo 'Review changes: open agentsidecar://open?repo='$(git rev-parse --show-toplevel)'&scope=workingTree'"
      }
    ]
  }
}
```

### Plan Review Hook (pre-approval)

The plan review hook intercepts Claude's `ExitPlanMode` tool call, opens AgentSidecar for plan review, and blocks until you approve or request changes. This gives you a visual review step before Claude starts implementing.

#### Setup

1. **Copy the hook script** into your project:

```bash
mkdir -p Scripts
curl -o Scripts/plan-review-hook.sh \
  https://raw.githubusercontent.com/nicekode/agent-sidecar/main/Scripts/plan-review-hook.sh
chmod +x Scripts/plan-review-hook.sh
```

2. **Add the hook to `.claude/settings.json`** (create the file if it doesn't exist):

```json
{
  "hooks": {
    "PreToolUse": [
      {
        "matcher": "ExitPlanMode",
        "hooks": [
          {
            "type": "command",
            "command": "./Scripts/plan-review-hook.sh",
            "timeout": 660000
          }
        ]
      }
    ]
  }
}
```

The timeout (660s) is slightly longer than the script's internal 600s timeout so the script handles expiry gracefully.

3. **Ensure `jq` is installed** (the hook requires it):

```bash
brew install jq
```

#### How it works

1. Claude enters plan mode, writes a plan, and calls `ExitPlanMode`
2. The hook intercepts the call and opens AgentSidecar via `agentsidecar://plan?file=...`
3. The hook polls `~/.claude/plans/{slug}.review.json` every 2 seconds
4. You review the plan in AgentSidecar and submit your decision
5. **Approved** → hook exits, Claude proceeds to implement
6. **Changes requested** → hook sends your comments back to Claude, which revises the plan and tries again

#### Review JSON format

AgentSidecar writes the review file to `~/.claude/plans/{slug}.review.json` where `{slug}` is the plan filename without `.md`.

**Approved:**
```json
{
  "status": "approved",
  "comments": [],
  "reviewedAt": "2026-03-15T10:30:00Z"
}
```

**Changes requested:**
```json
{
  "status": "changes_requested",
  "comments": [
    {
      "line": "2. Call NetworkService.fetch() to get user data",
      "comment": "Use a guard clause instead of if-let here"
    }
  ],
  "reviewedAt": "2026-03-15T10:32:00Z"
}
```

Each comment includes a `line` field quoting the exact plan text it refers to, so Claude can locate the context.

#### Manual testing (without AgentSidecar UI)

You can test the hook by writing the review JSON manually in another terminal:

```bash
# Find the current plan slug
SLUG=$(ls -t ~/.claude/plans/*.md | head -1 | xargs basename | sed 's/.md$//')

# Approve
echo '{"status":"approved","comments":[]}' > ~/.claude/plans/${SLUG}.review.json

# Request changes
echo '{"status":"changes_requested","comments":[{"line":"Some plan text","comment":"Needs rework"}]}' > ~/.claude/plans/${SLUG}.review.json
```

## Tips

- Comments are persisted even if AgentSidecar is closed
- Multiple scope views (Working Tree, Staged, Branch) are available
- Binary files are detected but not displayed
- The `.agent-review/` directory can be added to `.gitignore`
