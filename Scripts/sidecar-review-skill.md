---
name: sidecar-review
description: Open AgentSidecar to review code changes. User reviews diffs visually, leaves inline comments, then Claude reads and addresses them.
disable-model-invocation: true
argument-hint: "[scope: workingTree|staged|branch]"
---

# Review Workflow

Open AgentSidecar for the user to review your changes, then read and address their feedback.

## Step 1: Determine scope

The user may pass a scope as `$ARGUMENTS`. Valid scopes: `workingTree` (default), `staged`, `branch`.

If no argument is given, default to `workingTree`.

## Step 2: Open AgentSidecar

Run the appropriate deeplink command based on scope:

**workingTree** (default):
```bash
open "agentsidecar://open?repo=$(git rev-parse --show-toplevel)&scope=workingTree&bundle=.agent-review/pending.json"
```

**staged**:
```bash
open "agentsidecar://open?repo=$(git rev-parse --show-toplevel)&scope=staged&bundle=.agent-review/pending.json"
```

**branch**:
```bash
open "agentsidecar://open?repo=$(git rev-parse --show-toplevel)&scope=branch&base=main&bundle=.agent-review/pending.json"
```

## Step 3: Wait for the user

After opening AgentSidecar, tell the user:

> AgentSidecar is open. Review the diff, leave inline comments on any lines you want changed, then **Cmd+S** to save. Tell me when you're done.

Do NOT proceed until the user confirms they are done reviewing.

## Step 4: Read review comments

```bash
cat "$(git rev-parse --show-toplevel)/.agent-review/pending.json"
```

Parse the JSON. For each comment where `resolved` is `false`:
1. Read the `filePath` and `lineAnchor` (format: `oldLine:newLine`, `_` means absent)
2. Read the `body` for what the user wants changed
3. Make the requested change
4. After addressing all comments, update the JSON file setting `resolved: true` for each addressed comment

## Step 5: Confirm

After addressing all comments, tell the user what you changed and offer to open AgentSidecar again for a follow-up review.
