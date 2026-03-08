# Claude Code Review Workflow with AgentSidecar

This document describes how to integrate AgentSidecar into a Claude Code workflow for interactive diff review.

## Overview

AgentSidecar provides a GitHub-like diff review UI that Claude can trigger via deeplinks. The user reviews diffs visually, leaves inline comments, and those comments are persisted as structured JSON that Claude can read and act on.

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

## Line Anchor Format

The `lineAnchor` field uses the format `old:new` where:
- `"10:10"` — a context line at line 10 in both old and new
- `"5:_"` — a deleted line (was line 5 in old file)
- `"_:8"` — an added line (is line 8 in new file)

## Claude Code Hook Integration

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

## Tips

- Comments are persisted even if AgentSidecar is closed
- Multiple scope views (Working Tree, Staged, Branch) are available
- Binary files are detected but not displayed
- The `.agent-review/` directory can be added to `.gitignore`
