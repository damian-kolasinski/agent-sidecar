# Implement Plan Review UI in AgentSidecar

## Context

AgentSidecar is a macOS SwiftUI app for reviewing code changes made by AI agents. It currently supports **diff review** — viewing git diffs with inline comments. We need to add **plan review** — a separate mode where the user reviews a Claude Code plan (a markdown file) and either approves it or requests changes with comments.

A hook script (`Scripts/plan-review-hook.sh`) already handles the Claude Code side. When Claude calls `ExitPlanMode`, the hook:
1. Opens the app via deeplink: `agentsidecar://plan?file={url-encoded-path-to-plan.md}`
2. Polls for `~/.claude/plans/{slug}.review.json`
3. On `"approved"` → proceeds. On `"changes_requested"` → sends comments back to Claude.

Your job is to implement the **app side**: receive the deeplink, display the plan, let the user review it, and write the review JSON.

## Review JSON format

The app writes to `~/.claude/plans/{slug}.review.json` where `{slug}` is the plan filename without `.md`.

**Approved:**
```json
{
  "status": "approved",
  "comments": [],
  "reviewedAt": "2026-03-16T10:30:00Z"
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
  "reviewedAt": "2026-03-16T10:32:00Z"
}
```

Each comment's `line` field must contain the **exact text** of the plan line being commented on (trimmed of leading markdown like `- `, `### `, etc. is fine, but the content must match so Claude can locate it). The `comment` field contains the reviewer's feedback.

## Deeplink handling

The current deeplink handler (`AgentSidecar/AgentSidecar/Services/DeeplinkHandler.swift`) only handles `agentsidecar://open`. Extend it to also handle `agentsidecar://plan?file={encoded-path}`.

Current implementation:
```swift
// DeeplinkHandler.swift
enum DeeplinkHandler {
    static func parse(url: URL) -> DeeplinkPayload? {
        guard url.scheme == "agentsidecar",
              url.host == "open" else {
            return nil
        }
        // ... parses repo, scope, base, bundle query params
    }
}

// DeeplinkPayload.swift
struct DeeplinkPayload: Sendable {
    let repoPath: String
    let scope: DiffScope?
    let baseBranch: String?
    let bundlePath: String?
}
```

You need to handle the `plan` host. The `file` query parameter is a URL-encoded absolute path to a `.md` file in `~/.claude/plans/`. Return a different payload type or extend the existing one — your call, but keep it clean.

The deeplink is received in `AgentSidecarApp.swift`:
```swift
.onOpenURL { url in
    appViewModel.handleDeeplink(url: url)
}
```

## App architecture — what to follow

The app uses these patterns consistently. Follow them:

- **ViewModels**: `@MainActor final class` with `@Published` properties, injected via `.environmentObject()`. See `AppViewModel` (~260 lines) for the pattern.
- **Services**: `actor`-based for thread safety. See `ReviewStore` for the persistence pattern (atomic writes via temp file + move).
- **Design system**: Use `DSColor`, `DSFont`, `DSSpacing`, `DSButton`, `DSBadge`, `DSDivider` from `AgentSidecar/AgentSidecar/DesignSystem/`. Don't create raw colors or fonts.
- **Navigation**: The main window uses `NavigationSplitView` in `ContentView.swift`. The plan review should be a **separate mode/view** that replaces the diff view when a plan deeplink is active, not a new window.

Key files to read before starting:
- `AgentSidecar/AgentSidecar/ViewModels/AppViewModel.swift` — state management pattern
- `AgentSidecar/AgentSidecar/Views/MainWindow/ContentView.swift` — navigation structure
- `AgentSidecar/AgentSidecar/Services/ReviewStore.swift` — persistence pattern (actor, atomic writes)
- `AgentSidecar/AgentSidecar/DesignSystem/` — all tokens and components
- `AgentSidecar/AgentSidecar/Views/Comments/InlineCommentComposer.swift` — text input pattern

## What to implement

### 1. Models

**`PlanReview.swift`** — the review JSON model:
```
- status: String ("approved" | "changes_requested")
- comments: [PlanComment]
- reviewedAt: Date (ISO 8601)
```

**`PlanComment.swift`**:
```
- line: String (the plan text being commented on)
- comment: String (the reviewer's feedback)
```

### 2. Service

**`PlanReviewStore.swift`** — actor for reading the plan markdown and writing the review JSON:
- `loadPlan(filePath: String) -> String` — read the `.md` file content
- `saveReview(_ review: PlanReview, for planFilePath: String)` — derive `{slug}.review.json` path from the plan file path and write atomically
- Follow the `ReviewStore` pattern exactly (actor, JSONEncoder with `.prettyPrinted` + `.iso8601`, atomic write via temp file)

### 3. ViewModel

**`PlanReviewViewModel.swift`** — `@MainActor ObservableObject`:
- `planFilePath: String?` — set from deeplink
- `planContent: String` — the loaded markdown text
- `comments: [PlanComment]` — comments being composed
- `isLoading: Bool`
- `errorMessage: String?`
- `loadPlan()` — reads the file
- `addComment(line: String, comment: String)` — appends to comments array
- `removeComment(at index: Int)`
- `approve()` — writes review JSON with status "approved", empty comments
- `requestChanges()` — writes review JSON with status "changes_requested" and the comments array

### 4. Navigation

Add a `currentMode` concept to `AppViewModel` (or to `AgentSidecarApp`):
- `.diffReview` (current default)
- `.planReview(filePath: String)`

When a `plan` deeplink arrives, switch to `.planReview` mode. `ContentView` should show `PlanReviewView` instead of the `NavigationSplitView` with sidebar/detail.

### 5. Views

**`PlanReviewView.swift`** — the main plan review screen. Layout:

```
┌──────────────────────────────────────────────────┐
│  [toolbar: plan filename]           [Approve] btn│
├──────────────────────────────────────────────────┤
│                                                  │
│  Plan content rendered as selectable text,       │
│  line by line. Each line is clickable/hoverable  │
│  to add a comment.                               │
│                                                  │
│  Lines with comments show the comment inline     │
│  below them (similar to diff inline comments).   │
│                                                  │
│                                                  │
│                                                  │
├──────────────────────────────────────────────────┤
│  [Request Changes] btn  (disabled if 0 comments) │
│  Comment count: N                                │
└──────────────────────────────────────────────────┘
```

Specifics:
- The plan text should be displayed line by line in a `ScrollView` + `LazyVStack`
- Each line shows the markdown text (plain `Text` with `DSFont.code` is fine — no need for full markdown rendering)
- Hovering a line shows a "+" button in the gutter (like the diff line gutter pattern in `LineGutterView`)
- Clicking "+" opens an inline composer below that line (reuse `InlineCommentComposer` pattern)
- After submitting a comment, it appears below the line as a card (like `CommentBubbleView`)
- Comments can be deleted (X button) since they haven't been submitted yet
- **"Approve"** button in the toolbar — writes approved review JSON and shows a confirmation
- **"Request Changes"** button at the bottom — only enabled when comments exist, writes changes_requested review JSON
- After either action, show a brief "Review submitted" state, then the view can remain (the hook will pick up the file within 2 seconds)

### 6. Markdown heading styling (nice to have)

If a line starts with `#`, `##`, `###`, etc., render it with slightly larger/bolder font. Lines starting with `- ` or `1. ` can have a small indent. Keep it simple — no full markdown parser needed.

## What NOT to do

- Don't add a markdown rendering library
- Don't create a new window — reuse the existing window
- Don't modify existing diff review views
- Don't over-engineer the comment model — it's intentionally simple (just `line` + `comment` strings)
- Don't add persistence for in-progress plan reviews — comments live in memory until submitted

## Testing

After implementing, test manually:
1. Create a test plan: `echo "# Test\n\n1. Step one\n2. Step two" > ~/.claude/plans/test-plan.md`
2. Open via deeplink: `open "agentsidecar://plan?file=$(python3 -c "import urllib.parse; print(urllib.parse.quote('$HOME/.claude/plans/test-plan.md'))")"`
3. Verify the plan text displays
4. Add a comment on a line
5. Click "Request Changes" — verify `~/.claude/plans/test-plan.review.json` is written with correct format
6. Open another plan deeplink, click "Approve" — verify review JSON has `"status": "approved"`
7. Verify you can switch back to diff review mode (open a diff deeplink)
