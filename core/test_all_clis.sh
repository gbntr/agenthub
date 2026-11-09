#!/usr/bin/env bash
set -e

export PATH="$HOME/.local/bin:$HOME/.cargo/bin:$PATH"
export GH_TOKEN="$(gh auth token 2>/dev/null || true)"

echo "=================================================="
echo "   AGENTHUB: 4-POOL AI CLI HEALTH CHECK (WAVE 2)  "
echo "=================================================="

echo "Allowed models -> Kiro: claude-haiku-5.5 (0.06x), auto (1.00x), claude-sonnet-5.5 (1.30x)"
echo "                  Agy:  gemini-3.8-flash, gemini-4-argon, claude-sonnet-5-5, claude-opus-5-5"
echo "--------------------------------------------------"

echo -n "Offline declarative routing (dry-run, all stages)... "
for stage in SCOUT BRIEFING SPEC APPLY CODE_REVIEW QA_VISUAL QA_FUNCTIONAL; do
    smart-agent --dry-run "$stage" "health check routing" >/dev/null || { echo "❌ [FAIL] $stage"; exit 1; }
done
echo "✅ [PASS]"

echo -n "Testing Pool 1 (Google Gemini via agy)... "
OUT_P1=$(agy -p "Reply with the exact string: POOL1_OK" --model gemini-3.8-flash-low --dangerously-skip-permissions 2>&1)
if echo "$OUT_P1" | grep -q "POOL1_OK"; then
    echo "✅ [PASS] ($OUT_P1)"
else
    echo "❌ [FAIL] ($OUT_P1)"
    exit 1
fi

echo -n "Testing Pool 2 (Anthropic Claude via agy)... "
OUT_P2=$(agy -p "Reply with the exact string: POOL2_OK" --model claude-sonnet-5-5-low --dangerously-skip-permissions 2>&1)
if echo "$OUT_P2" | grep -q "POOL2_OK"; then
    echo "✅ [PASS] ($OUT_P2)"
else
    echo "❌ [FAIL] ($OUT_P2)"
    exit 1
fi

echo -n "Testing Pool 3 (AWS Kiro CLI / Amazon Q)... "
OUT_P3=$(kiro-cli chat --no-interactive --trust-all-tools --model claude-haiku-5.5 "Reply with the exact string: POOL3_OK" 2>&1)
if echo "$OUT_P3" | grep -q "POOL3_OK"; then
    echo "✅ [PASS] ($OUT_P3)"
else
    echo "❌ [FAIL] ($OUT_P3)"
    exit 1
fi

echo -n "Testing Pool 4 (GitHub Copilot CLI)... "
OUT_P4=$(copilot -p "Reply with the exact string: POOL4_OK" -s --allow-all 2>&1)
if echo "$OUT_P4" | grep -q "POOL4_OK"; then
    echo "✅ [PASS] ($OUT_P4)"
else
    echo "❌ [FAIL] ($OUT_P4)"
    exit 1
fi

echo "=================================================="
echo "🎉 ALL 4 AI POOLS ARE OPERATIONAL AND VERIFIED!"
echo "=================================================="
