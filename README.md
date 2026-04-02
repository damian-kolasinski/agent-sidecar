# AgentSidecar

A macOS sidecar app for reviewing code changes and local text files produced by AI coding agents in the terminal.

When you work with tools like Claude Code or Codex CLI, code and draft artifacts get written fast, but reviewing them in the terminal is painful. AgentSidecar gives you a GitHub-like diff review UI and a line-by-line file review mode that run alongside your terminal, so you can visually inspect output, leave structured feedback, and send it back to the agent.

## How it works

1. **Agent makes changes** in your terminal
2. **You open AgentSidecar** via deeplink for either a diff or a local file
3. **You review** and leave inline comments or commands on specific lines
4. **Agent reads your feedback** from a JSON file and addresses it
5. **Repeat** until you're happy

## Features

- Unified diff view with syntax-highlighted additions/deletions
- Three diff scopes: working tree, staged, or branch comparison
- Inline commenting with line-anchored threads
- Comment resolution tracking
- Deeplink integration (`agentsidecar://open?repo=...`)
- Persistent review bundles (`.agent-review/pending.json`)
- Local file review mode for plans, analyses, and other text artifacts (`agentsidecar://file?file=...`)
- Structured file-review JSON with per-line commands and approval status

## Deeplink usage

```bash
# Working tree changes
open "agentsidecar://open?repo=$(git rev-parse --show-toplevel)&scope=workingTree&bundle=.agent-review/pending.json"

# Staged changes
open "agentsidecar://open?repo=$(git rev-parse --show-toplevel)&scope=staged&bundle=.agent-review/pending.json"

# Branch diff against main
open "agentsidecar://open?repo=$(git rev-parse --show-toplevel)&scope=branch&base=main&bundle=.agent-review/pending.json"
```

### Local file review

```bash
FILE_PATH="/tmp/analysis.md"
REVIEW_PATH="/tmp/analysis.review.json"

ENCODED_FILE=$(python3 -c 'import sys, urllib.parse; print(urllib.parse.quote(sys.argv[1]))' "$FILE_PATH")
ENCODED_REVIEW=$(python3 -c 'import sys, urllib.parse; print(urllib.parse.quote(sys.argv[1]))' "$REVIEW_PATH")

open "agentsidecar://file?file=${ENCODED_FILE}&review=${ENCODED_REVIEW}"
```

## Claude Code integration

Copy `Scripts/sidecar-review-skill.md` to `~/.claude/skills/sidecar-review/SKILL.md` to get a `/sidecar-review` slash command. Then:

```
/sidecar-review          # review working tree changes
/sidecar-review staged   # review staged changes
/sidecar-review branch   # review branch diff vs main
```

Copy `Scripts/sidecar-file-review-skill.md` to `~/.claude/skills/sidecar-file-review/SKILL.md` to get a `/sidecar-file-review` slash command for local text files:

```
/sidecar-file-review /tmp/analysis.md
```

See `Scripts/claude-review-workflow.md` for the full workflow description, including local file review.

## Requirements

- macOS 15.0+
- Xcode 16+
- Git

## License

MIT
