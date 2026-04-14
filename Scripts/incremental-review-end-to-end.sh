#!/usr/bin/env bash
set -euo pipefail

# ── Config ──────────────────────────────────────────────────────────
REPO="/tmp/test-incremental-review"
VIEWED_JSON="$REPO/.agent-review/viewed.json"
BOLD="\033[1m"
GREEN="\033[32m"
YELLOW="\033[33m"
RED="\033[31m"
RESET="\033[0m"

step=0
step() { step=$((step + 1)); echo -e "\n${BOLD}── Step $step: $1 ──${RESET}"; }
info() { echo -e "${GREEN}[ok]${RESET} $1"; }
warn() { echo -e "${YELLOW}[>>]${RESET} $1"; }
fail() { echo -e "${RED}[FAIL]${RESET} $1"; exit 1; }

wait_for_user() {
    echo ""
    warn "$1"
    read -rp "    Press Enter when done... "
}

assert_file_exists() {
    [[ -f "$1" ]] || fail "Expected file not found: $1"
    info "$1 exists"
}

assert_file_missing() {
    [[ ! -f "$1" ]] || fail "File should not exist yet: $1"
    info "$1 does not exist (expected)"
}

assert_json_has_key() {
    local file="$1" key="$2"
    python3 -c "
import json, sys
data = json.load(open('$file'))
scopes = data.get('scopes', {})
for scope in scopes.values():
    if '$key' in scope:
        sys.exit(0)
sys.exit(1)
" || fail "Expected key '$key' in $file"
    info "viewed.json contains '$key'"
}

assert_json_missing_key() {
    local file="$1" key="$2"
    python3 -c "
import json, sys
data = json.load(open('$file'))
scopes = data.get('scopes', {})
for scope in scopes.values():
    if '$key' in scope:
        sys.exit(1)
sys.exit(0)
" || fail "Key '$key' should not be in $file"
    info "viewed.json does not contain '$key' (expected)"
}

count_viewed_keys() {
    python3 -c "
import json
data = json.load(open('$VIEWED_JSON'))
total = sum(len(v) for v in data.get('scopes', {}).values())
print(total)
"
}

# ── Setup ───────────────────────────────────────────────────────────
step "Create test repository"

BARE="/tmp/test-incremental-review-bare.git"
rm -rf "$REPO" "$BARE"

# Create a bare remote so origin/main exists
git init --bare -b main "$BARE"
git clone "$BARE" "$REPO"
cd "$REPO"
git commit --allow-empty -m "init"
echo ".agent-review/" > .gitignore
git add .gitignore && git commit -m "add gitignore"
git push origin main

git checkout -b feature
cat > file1.txt <<'EOF'
function greet(name) {
    return "Hello, " + name;
}
EOF
cat > file2.txt <<'EOF'
const PI = 3.14159;
const E  = 2.71828;
EOF
cat > file3.txt <<'EOF'
# README
This is a test project.
EOF
git add -A && git commit -m "add initial files"
info "Created repo at $REPO with 3 files on 'feature' branch"

# ── Round 1 ─────────────────────────────────────────────────────────
step "Open app — Round 1 (initial review)"

assert_file_missing "$VIEWED_JSON"
open "agentsidecar://open?repo=$REPO&scope=branch&base=main"

wait_for_user "In the app: mark ALL 3 files as Viewed, then come back here."

assert_file_exists "$VIEWED_JSON"
assert_json_has_key "$VIEWED_JSON" "file1.txt"
assert_json_has_key "$VIEWED_JSON" "file2.txt"
assert_json_has_key "$VIEWED_JSON" "file3.txt"
info "Round 1 passed — all 3 files persisted as viewed"

echo ""
echo "  Current viewed.json:"
cat "$VIEWED_JSON"

# ── Simulate agent commit (change 1 file) ──────────────────────────
step "Simulate agent commit — modify file1.txt only"

cd "$REPO"
cat > file1.txt <<'EOF'
function greet(name) {
    if (!name) return "Hello, stranger!";
    return "Hello, " + name + "!";
}
EOF
git add -A && git commit -m "agent: improve greet function"
info "Committed change to file1.txt"

# ── Round 2 ─────────────────────────────────────────────────────────
step "Refresh app — Round 2 (after 1 file changed)"

wait_for_user "In the app: hit Refresh (Cmd+R). Verify:\n    - file1.txt is NOT viewed (diff changed)\n    - file2.txt IS still viewed and collapsed\n    - file3.txt IS still viewed and collapsed\n    Then come back here."

assert_json_has_key "$VIEWED_JSON" "file2.txt"
assert_json_has_key "$VIEWED_JSON" "file3.txt"
info "Round 2 passed — unchanged files retained viewed state"

# ── Mark the changed file as viewed again ───────────────────────────
step "Mark file1.txt as viewed again (round 2 sign-off)"

wait_for_user "In the app: mark file1.txt as Viewed, then come back here."

assert_json_has_key "$VIEWED_JSON" "file1.txt"
n=$(count_viewed_keys)
[[ "$n" -ge 3 ]] || fail "Expected at least 3 viewed entries, got $n"
info "All 3 files viewed again"

# ── Simulate agent commit (change 2 files) ──────────────────────────
step "Simulate agent commit — modify file1.txt and file3.txt"

cd "$REPO"
cat > file1.txt <<'EOF'
function greet(name) {
    if (!name) return "Hello, stranger!";
    return `Hello, ${name}!`;
}
EOF
cat > file3.txt <<'EOF'
# README
This is a test project for incremental code review.
EOF
git add -A && git commit -m "agent: template literal + update readme"
info "Committed changes to file1.txt and file3.txt"

# ── Round 3 ─────────────────────────────────────────────────────────
step "Refresh app — Round 3 (after 2 files changed)"

wait_for_user "In the app: hit Refresh. Verify:\n    - file1.txt is NOT viewed\n    - file2.txt IS still viewed and collapsed\n    - file3.txt is NOT viewed\n    Then come back here."

assert_json_has_key "$VIEWED_JSON" "file2.txt"
info "Round 3 passed — only untouched file2.txt kept viewed state"

# ── Done ────────────────────────────────────────────────────────────
echo ""
echo -e "${BOLD}${GREEN}All rounds passed!${RESET}"
echo ""
echo "  Cleanup: rm -rf $REPO $BARE"
