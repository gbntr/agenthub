#!/usr/bin/env bash
# AgentHub — Zero-token verification of core/smart-agent (no AI CLI is invoked).
# Covers: dry-run routing for every stage, absence of hardcoded model maps,
# kiro whitelist enforcement, and a parallel fcntl.flock stress test.
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
SA="$REPO_ROOT/core/smart-agent"
export AGENTHUB_POLICY="$REPO_ROOT/config/routing-policy.yaml"
# Isolated HOME so the real quota/cache state is never touched.
export HOME="$(mktemp -d)"
trap 'rm -rf "$HOME"' EXIT

echo "== 1. Dry-run routing for all stages =="
for stage in SCOUT BRIEFING SPEC APPLY CODE_REVIEW QA_VISUAL QA_FUNCTIONAL; do
  out="$(python3 "$SA" --dry-run "$stage" 'refactor concurrency kernel module')"
  echo "$out" | grep -q '^\[DRY-RUN\]' || { echo "❌ $stage dry-run failed"; exit 1; }
  echo "✅ $stage -> $(echo "$out" | tail -1)"
done

echo "== 2. No hardcoded model maps =="
if grep -nE 'MODEL_MAP_(AGY|KIRO)|elif comp ==' "$SA"; then echo "❌ hardcoded routing found"; exit 1; fi
echo "✅ clean"

echo "== 3. Kiro whitelist (only haiku-5.5 / auto / sonnet-5.5) =="
python3 - "$SA" <<'PY'
import sys, importlib.machinery, importlib.util
loader = importlib.machinery.SourceFileLoader("sa", sys.argv[1])
spec = importlib.util.spec_from_loader("sa", loader); sa = importlib.util.module_from_spec(spec); loader.exec_module(sa)
pol = sa.load_policy()
for bad, good in pol["kiro"]["blocked"].items():
    got = sa.normalize_candidate({"cli": "kiro", "model": bad}, pol)["runtime"]
    assert got == good and got in pol["kiro"]["whitelist"], (bad, got)
print("✅ blocked models remapped to whitelist")
PY

echo "== 4. Parallel flock stress (20 procs x 5 increments) =="
python3 - "$SA" <<'PY'
import sys, importlib.machinery, importlib.util, multiprocessing as mp
def load():
    loader = importlib.machinery.SourceFileLoader("sa", sys.argv[1])
    spec = importlib.util.spec_from_loader("sa", loader); m = importlib.util.module_from_spec(spec); loader.exec_module(m); return m
def worker(_):
    sa = load(); pol = sa.load_policy()
    cand = sa.normalize_candidate({"cli": "agy", "model": "claude-sonnet-5-5", "level": "low"}, pol)
    for _ in range(5):
        with sa.quota_lock():
            q = sa.load_quotas(); sa.apply_usage(q, pol, cand); sa.save_quotas(q)
if __name__ == "__main__":
    with mp.get_context("fork").Pool(20) as p: p.map(worker, range(20))
    sa = load()
    with sa.quota_lock(): total = sa.load_quotas()["agy_anthropic_5h"]
    assert total == 100, f"lost updates: {total} != 100"
    print("✅ 100/100 increments preserved")
PY

echo "== 5. Normal calls never run CLI updates =="
python3 - "$SA" <<'PY'
import sys, re
src = open(sys.argv[1]).read()
body = src.split("def run():")[1]
assert body.index("auto_update()") < body.index("run_gate("), "auto_update must short-circuit first"
assert '"update"' not in src.split("def auto_update")[0] and '"update"' not in src.split("def build_cmd")[1], "update call leaked outside auto_update()"
print("✅ updates isolated behind --auto-update")
PY
echo "🎉 smart-agent checks passed"
