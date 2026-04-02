---
name: sidecar-file-review
description: Open AgentSidecar to review any local text file. The user leaves line-specific commands in the sidecar, then Claude reads the review JSON and revises the file until it is approved.
disable-model-invocation: true
argument-hint: "<file-path>"
---

# Local File Review Workflow

Open AgentSidecar for the user to review a local file, then read and apply the resulting review JSON.

## Step 1: Resolve the file path

Require a file path in `$ARGUMENTS`. Resolve it to an absolute path and derive the review JSON path next to the file:

```bash
FILE_PATH="$(python3 -c 'from pathlib import Path; import sys; print(Path(sys.argv[1]).expanduser().resolve())' "$ARGUMENTS")"
REVIEW_PATH="$(python3 -c 'from pathlib import Path; import sys; p = Path(sys.argv[1]).expanduser().resolve(); print(p.with_name(p.stem + ".review.json"))' "$ARGUMENTS")"
```

If the file does not exist, stop and tell the user.

## Step 2: Clear any stale review JSON

```bash
rm -f "$REVIEW_PATH"
```

## Step 3: Open AgentSidecar

```bash
ENCODED_FILE=$(python3 -c 'import sys, urllib.parse; print(urllib.parse.quote(sys.argv[1]))' "$FILE_PATH")
ENCODED_REVIEW=$(python3 -c 'import sys, urllib.parse; print(urllib.parse.quote(sys.argv[1]))' "$REVIEW_PATH")
open "agentsidecar://file?file=${ENCODED_FILE}&review=${ENCODED_REVIEW}"
```

## Step 4: Wait for the user

After opening AgentSidecar, tell the user:

> AgentSidecar is open. Review the file, add commands on any lines you want changed, then submit the review. Tell me when you're done.

Do NOT proceed until the user confirms they are done reviewing.

## Step 5: Read the review JSON

```bash
cat "$REVIEW_PATH"
```

The JSON format is:

```json
{
  "version": 1,
  "filePath": "/tmp/analysis.md",
  "status": "changes_requested",
  "commands": [
    {
      "lineNumber": 7,
      "line": "## Recommendation",
      "command": "Rename this section to `## Proposed Approach` and reduce it to three bullets."
    }
  ],
  "reviewedAt": "2026-04-02T12:00:00Z"
}
```

If the user approves the file, the JSON will instead contain:

```json
{
  "version": 1,
  "filePath": "/tmp/analysis.md",
  "status": "approved",
  "commands": [],
  "reviewedAt": "2026-04-02T12:05:00Z"
}
```

## Step 6: Apply the review

If `status` is `approved`, stop and tell the user the file is approved.

If `status` is `changes_requested`:
1. Read each entry in `commands`
2. Use `lineNumber` and `line` together to locate the context
3. Apply the requested changes to the file
4. Summarize what changed
5. Offer to open AgentSidecar again for another review round
