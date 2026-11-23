#!/usr/bin/env bash
# AgentHub — Zero-token simulation of the CODE_REVIEW / QA gates in core/smart-agent.
# Fake `agy`, `kiro-cli` and `copilot` executables replace the real CLIs, so no AI tokens
# are spent. Covers: retry/halt loop + .state.json, QA dispatch, dynamic QA_PORT, teardown.
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
SA="$REPO_ROOT/core/smart-agent"
export AGENTHUB_POLICY="$REPO_ROOT/config/routing-policy.yaml"
export HOME="$(mktemp -d)"
WORK="$(mktemp -d)"
trap 'rm -rf "$HOME" "$WORK"' EXIT

BIN="$WORK/bin"; mkdir -p "$BIN"
export STUB_LOG="$WORK/calls.log" STUB_SEQ="$WORK/verdicts"
# Fake CLI: logs "<agent>", writes the gate report with the next verdict from $STUB_SEQ,
# and (for qa-inspector) leaks an HTTP server on $QA_PORT that smart-agent must kill.
cat > "$BIN/fake-cli" <<'STUB'
#!/usr/bin/env bash
agent=""; while [ $# -gt 0 ]; do [ "$1" = "--agent" ] && agent="$2"; shift; done
echo "$agent QA_PORT=${QA_PORT:-}" >> "$STUB_LOG"
slug_dir="openspec/changes/demo"
next_verdict() { v=$(head -n1 "$STUB_SEQ"); sed -i 1d "$STUB_SEQ"; echo "${v:-APPROVED}"; }
case "$agent" in
  spec-auditor) echo "STATUS: $(next_verdict)" > "$slug_dir/code-review-report.md" ;;
  qa-inspector)
    setsid python3 -m http.server "$QA_PORT" --bind 127.0.0.1 >/dev/null 2>&1 &
    sleep 1
    echo "STATUS: $(next_verdict)" > "$slug_dir/qa-report.md" ;;
esac
exit 0
STUB
chmod +x "$BIN/fake-cli"
for n in agy kiro-cli copilot; do ln -s fake-cli "$BIN/$n"; done
export PATH="$BIN:$PATH"
export AGENTHUB_VALIDATE_CMD="true"

fail() { echo "❌ $*"; exit 1; }
new_repo() { rm -rf "$WORK/repo"; mkdir -p "$WORK/repo/openspec/changes/demo"; cd "$WORK/repo"; : > "$STUB_LOG"; printf '%s\n' "$@" > "$STUB_SEQ"; }
state() { python3 -c "import json;print(json.load(open('openspec/changes/demo/.state.json'))['$1'])"; }

echo "== 0. Agent profiles and Vibe Kanban wiring =="
for a in repo-scout briefing-analyst spec-architect code-craftsman spec-auditor qa-inspector; do
  f="$REPO_ROOT/config/agents/$a.md"
  [ -f "$f" ] && head -1 "$f" | grep -q '^---$' && grep -q "^name: $a$" "$f" || fail "bad agent profile $a"
  grep -q 'openspec/changes/<slug>/' "$f" || fail "$a lacks active-spec binding"
  jq -e ".name == \"$a\"" "$REPO_ROOT/config/agents/kiro/$a.json" >/dev/null || fail "bad kiro profile $a"
  jq -e --arg a "$a" '[.profiles[].args[1]] | index($a) != null' "$REPO_ROOT/config/vibe-kanban/profiles.json" >/dev/null || fail "$a not wired in profiles.json"
done
grep -q 'QA_PORT' "$REPO_ROOT/config/agents/qa-inspector.md" || fail "qa-inspector lacks QA_PORT rule"
echo "✅ 6 agents defined and wired"

echo "== 1. REJECTED, REJECTED, REJECTED -> HALTED_FOR_HUMAN (exit 1, retry_count 2) =="
new_repo REJECTED REJECTED REJECTED
set +e; python3 "$SA" --slug demo CODE_REVIEW "review" >/dev/null 2>&1; rc=$?; set -e
[ "$rc" = 1 ] || fail "expected exit 1, got $rc"
[ "$(state status)" = HALTED_FOR_HUMAN ] || fail "status $(state status)"
[ "$(state retry_count)" = 2 ] || fail "retry_count $(state retry_count)"
[ "$(grep -c '^code-craftsman' "$STUB_LOG")" = 2 ] || fail "expected 2 APPLY runs"
[ "$(grep -c '^spec-auditor' "$STUB_LOG")" = 3 ] || fail "expected 3 audits"
echo "✅ halted after 2 retries"

echo "== 2. REJECTED then APPROVED -> exit 0, one APPLY =="
new_repo REJECTED APPROVED
python3 "$SA" --slug demo CODE_REVIEW "review" >/dev/null 2>&1 || fail "expected exit 0"
[ "$(grep -c '^code-craftsman' "$STUB_LOG")" = 1 ] || fail "expected 1 APPLY run"
[ "$(state status)" = CODE_REVIEW_APPROVED ] && [ "$(state retry_count)" = 1 ] || fail "bad state"
echo "✅ self-healed in one retry"

echo "== 3. QA_FUNCTIONAL: dynamic QA_PORT + teardown =="
new_repo APPROVED
python3 "$SA" --slug demo QA "functional check" >/dev/null 2>&1 || fail "QA failed"
port="$(grep -o 'QA_PORT=[0-9]*' "$STUB_LOG" | head -1 | cut -d= -f2)"
[ -n "$port" ] && [ "$port" != 3000 ] && [ "$port" != 5000 ] && [ "$port" != 8000 ] || fail "bad QA_PORT '$port'"
sleep 1
if ss -H -ltn "sport = :$port" | grep -q .; then fail "leaked listener on :$port"; fi
echo "✅ QA_PORT=$port allocated, listener torn down"

echo "== 4. QA dispatch: ui-mockup.html present -> QA_VISUAL =="
new_repo APPROVED
touch openspec/changes/demo/ui-mockup.html
python3 "$SA" --slug demo QA "check it" 2>&1 | grep -q 'Stage=QA_VISUAL' || fail "expected QA_VISUAL"
echo "✅ dispatched to QA_VISUAL"

echo "== 5. Concurrent QA sessions get distinct ports =="
new_repo APPROVED APPROVED
python3 "$SA" --slug demo QA "a" >/dev/null 2>&1 &
python3 "$SA" --slug demo QA "b" >/dev/null 2>&1 &
wait
[ "$(grep -o 'QA_PORT=[0-9]*' "$STUB_LOG" | sort -u | wc -l)" = 2 ] || fail "ports collided"
echo "✅ distinct ports"
echo "🎉 gate orchestration checks passed"
