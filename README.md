# AgentSidecar

A macOS sidecar app for reviewing code changes made by AI coding agents in the terminal.

When you work with tools like Claude Code or Codex CLI, code gets written fast — but reviewing diffs in the terminal is painful. AgentSidecar gives you a GitHub-like diff review UI that runs alongside your terminal, so you can visually inspect changes, leave inline comments, and send structured feedback back to the agent.

## How it works

1. **Agent makes changes** in your terminal
2. **You open AgentSidecar** via deeplink — it shows a colored diff view
3. **You review** and leave inline comments on specific lines
4. **Agent reads your comments** from a JSON file and addresses them
5. **Repeat** until you're happy

## Features

- Unified diff view with syntax-highlighted additions/deletions
- Three diff scopes: working tree, staged, or branch comparison
- Inline commenting with line-anchored threads
- Comment resolution tracking
- Deeplink integration (`agentsidecar://open?repo=...`)
- Persistent review bundles (`.agent-review/pending.json`)

## Deeplink usage

```bash
# Working tree changes
open "agentsidecar://open?repo=$(git rev-parse --show-toplevel)&scope=workingTree&bundle=.agent-review/pending.json"

# Staged changes
open "agentsidecar://open?repo=$(git rev-parse --show-toplevel)&scope=staged&bundle=.agent-review/pending.json"

# Branch diff against main
open "agentsidecar://open?repo=$(git rev-parse --show-toplevel)&scope=branch&base=main&bundle=.agent-review/pending.json"
```

## Claude Code integration

Copy `Scripts/sidecar-review-skill.md` to `~/.claude/skills/sidecar-review/SKILL.md` to get a `/sidecar-review` slash command. Then:

```
/sidecar-review          # review working tree changes
/sidecar-review staged   # review staged changes
/sidecar-review branch   # review branch diff vs main
```

See `Scripts/claude-review-workflow.md` for the full workflow description.

## Requirements

- macOS 15.0+
- Xcode 16+
- Git

## License

MIT
