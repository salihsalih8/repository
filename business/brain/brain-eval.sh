#!/bin/bash
# brain-eval.sh — Monthly recall quality evaluation for the Akatsuki Brain
# Tests 10 questions the brain must answer. <80% = flag Nagato.
#
# Run: brain-eval.sh [--full] [--report]
#   --full: run all 25 questions (quarterly)
#   --report: only generate report from last run, don't re-test

set -euo pipefail

BRAIN_DIR="$(cd "$(dirname "$0")" && pwd)"
WORKSPACE_DIR="$(cd "$BRAIN_DIR/../.." && pwd)"
RESULTS_DIR="$BRAIN_DIR/.eval-results"
mkdir -p "$RESULTS_DIR"

TIMESTAMP=$(date +%Y-%m-%d)
RESULT_FILE="$RESULTS_DIR/eval-${TIMESTAMP}.json"

PASS=0
FAIL=0
SKIP=0

# ===== CORE QUESTIONS (10 — every monthly run) =====
declare -A CORE_TESTS
CORE_TESTS["hero-claim"]="What is our hero claim?|avocado oil.*no seed oils"
CORE_TESTS["displacement-target"]="Who is our primary displacement target?|Healspot"
CORE_TESTS["launch-msrp"]="What is our launch MSRP?|29\\.99"
CORE_TESTS["capital"]="How much capital do we have?|30,?000|35,?000"
CORE_TESTS["agent-hierarchy"]="Who is Nagato and who is Pain?|Nagato.*leader|Pain.*execution"
CORE_TESTS["priority-1"]="What is our top priority?|velocity.*launch"
CORE_TESTS["pack-size"]="How many packs per retail unit?|8.?pack"
CORE_TESTS["niche"]="What Amazon niche are we launching in?|Protein Ramen"
CORE_TESTS["strategic-threat"]="Who is our strategic threat competitor?|Ramen Bae"
CORE_TESTS["fba-tier"]="What FBA tier does our product use?|Large Standard"

# ===== EXTENDED QUESTIONS (15 more — quarterly or --full) =====
declare -A EXTENDED_TESTS
EXTENDED_TESTS["cogs-target"]="What is our target COGS per bowl?|0\\.80|0\\.70"
EXTENDED_TESTS["founder-face"]="Is the founder willing to show face on camera?|no|not|NOT"
EXTENDED_TESTS["supplier-region"]="Where is our supplier based?|China"
EXTENDED_TESTS["hero-claim-why"]="Why was avocado oil chosen as the hero claim?|differentiated|legally defensible|search.driven"
EXTENDED_TESTS["reorder-cycle"]="What is our reorder cycle time?|10.week"
EXTENDED_TESTS["compliance-not-pursuing"]="What certifications are we NOT pursuing?|halal.*certif|organic.*certif"
EXTENDED_TESTS["vine-allocation"]="How many units for Vine review program?|30"
EXTENDED_TESTS["ta-cos-launch"]="What TACoS target for months 1-3?|30%"
EXTENDED_TESTS["cash-crunch"]="When is the critical cash crunch point?|month.*2.*3|month.*3"
EXTENDED_TESTS["credit-line-recommendation"]="What credit line is recommended?|15.*25[Kk]"
EXTENDED_TESTS["creator-seeding"]="How many creators for product seeding?|80.*120"
EXTENDED_TESTS["tier-model"]="What are the three brain memory tiers?|hot.*warm.*cold"
EXTENDED_TESTS["opus-quota"]="What is the Opus soft cap per 5h?|20"
EXTENDED_TESTS["opus-lesson"]="What was the Claude Opus rate limit lesson?|7.*separate.*session|plan.*once.*send.*once"
EXTENDED_TESTS["importance-scores"]="What are the 5 importance scores?|1.*5|ephemeral.*strategic.*critical"

# ===== Run tests =====
run_test() {
    local id="$1"
    local spec="$2"
    local query="${spec%%|*}"
    local expected_pattern="${spec#*|}"
    
    local result=""
    local found=false
    
    # Search brain files in priority order
    for file in "$BRAIN_DIR/north-star.md" "$BRAIN_DIR/decisions.md" \
                "$BRAIN_DIR/BRAIN-ARCHITECTURE-v2.md" "$BRAIN_DIR/OWNERSHIP.md" \
                "$WORKSPACE_DIR/memory/business-context.md"; do
        if [ -f "$file" ]; then
            if echo "$query" | grep -qi "$expected_pattern" 2>/dev/null; then
                : # query itself matches (trivial case)
            fi
            result=$(grep -i -E "$expected_pattern" "$file" 2>/dev/null | head -3)
            if [ -n "$result" ]; then
                found=true
                break
            fi
        fi
    done
    
    # Also try OpenClaw memory_search if available
    if [ "$found" = "false" ] && command -v openclaw &>/dev/null; then
        result=$(openclaw memory search "$query" --max-results 3 2>/dev/null | head -20)
        if [ -n "$result" ]; then
            found=true
        fi
    fi
    
    if [ "$found" = "true" ]; then
        PASS=$((PASS + 1))
        echo "  ✅ $id: FOUND"
        return 0
    else
        echo "  ❌ $id: MISSING ($query)"
        return 1
    fi
}

echo "=== Akatsuki Brain Recall Evaluation ==="
echo "Date: $(date)"
echo ""

# Core tests
echo "Core Questions (10):"
echo "--------------------"
for id in "${!CORE_TESTS[@]}"; do
    run_test "$id" "${CORE_TESTS[$id]}" || true
done

# Extended tests (quarterly or --full)
if [ "${1:-}" = "--full" ]; then
    echo ""
    echo "Extended Questions (15):"
    echo "-----------------------"
    for id in "${!EXTENDED_TESTS[@]}"; do
        run_test "$id" "${EXTENDED_TESTS[$id]}" || true
    done
    TOTAL=$(( ${#CORE_TESTS[@]} + ${#EXTENDED_TESTS[@]} ))
else
    TOTAL=${#CORE_TESTS[@]}
fi

# ===== Report =====
SCORE=$(echo "scale=1; $PASS * 100 / $TOTAL" | bc 2>/dev/null || echo "0")

echo ""
echo "=== Results ==="
echo "Total: $TOTAL"
echo "Passed: $PASS"
echo "Failed: $TOTAL-$PASS"
echo "Score: ${SCORE}%"
echo ""

THRESHOLD=80
if (( $(echo "$SCORE < $THRESHOLD" | bc -l 2>/dev/null || echo 0) )); then
    STATUS="FAIL"
    echo "❌ BELOW THRESHOLD ($THRESHOLD%) — flag Nagato"
else
    STATUS="PASS"
    echo "✅ ABOVE THRESHOLD ($THRESHOLD%)"
fi

# ===== Write results =====
cat > "$RESULT_FILE" << JSONEOF
{
  "date": "$TIMESTAMP",
  "score": $SCORE,
  "passed": $PASS,
  "total": $TOTAL,
  "threshold": $THRESHOLD,
  "status": "$STATUS",
  "mode": "${1:-monthly}"
}
JSONEOF

# ===== Log to events.log =====
EVENT_TS=$(TZ='America/New_York' date '+%Y-%m-%d %H:%M %Z')
echo "---" >> "$BRAIN_DIR/events.log"
echo "date: $EVENT_TS" >> "$BRAIN_DIR/events.log"
echo "agent: system" >> "$BRAIN_DIR/events.log"
echo "importance: 3" >> "$BRAIN_DIR/events.log"
echo "confidence: high" >> "$BRAIN_DIR/events.log"
echo "---" >> "$BRAIN_DIR/events.log"
echo "Brain recall evaluation: ${SCORE}% ($PASS/$TOTAL). Status: $STATUS." >> "$BRAIN_DIR/events.log"
echo "" >> "$BRAIN_DIR/events.log"

echo ""
echo "Results saved to $RESULT_FILE"
echo "Previous results: $RESULTS_DIR/"

# Show history
echo ""
echo "Score history:"
for f in $(ls -t "$RESULTS_DIR"/eval-*.json 2>/dev/null | head -6); do
    score=$(grep -o '"score": [0-9.]*' "$f" | grep -o '[0-9.]*')
    date=$(grep -o '"date": "[^"]*"' "$f" | cut -d'"' -f4)
    status=$(grep -o '"status": "[^"]*"' "$f" | cut -d'"' -f4)
    echo "  $date — ${score}% ($status)"
done
