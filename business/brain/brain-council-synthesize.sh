#!/bin/bash
# brain-council-synthesize.sh — Synthesize multi-round council deliberation
# Usage: brain-council-synthesize.sh <council-session-dir>
#
# Reads all rounds from all agents, identifies:
#   - Consensus (points where all agents agree)
#   - Dissent (disagreements, documented splits)
#   - Tiebreakers needed (flagged for Pain/Nagato)
#   - Refined recommendations (Round 2 positions)

set -euo pipefail

BRAIN_DIR="$(cd "$(dirname "$0")" && pwd)"
SESSION_DIR="$1"
AGENT="${AGENT_NAME:-pain}"

if [ -z "$SESSION_DIR" ] || [ ! -d "$SESSION_DIR" ]; then
    echo "Usage: brain-council-synthesize.sh <council-session-dir>"
    exit 1
fi

SYNTHESIS_FILE="$SESSION_DIR/synthesis.md"
MANIFEST="$SESSION_DIR/manifest.md"
TIMESTAMP="$(TZ='America/New_York' date '+%Y-%m-%d %H:%M %Z')"

if [ ! -f "$MANIFEST" ]; then
    echo "❌ Not a valid council session (no manifest)"
    exit 1
fi

QUESTION=$(sed -n '/^## Question/{n;p;}' "$MANIFEST" 2>/dev/null || echo "(unknown)")
SESSION_ID=$(grep "Session:" "$MANIFEST" | head -1 | sed 's/.*: *//' || echo "unknown")

echo "╔══════════════════════════════════════╗"
echo "║ 🏛️  Council Synthesis — $AGENT       ║"
echo "╚══════════════════════════════════════╝"
echo ""
echo "Session: $SESSION_ID"
echo ""

# === Collect all responses ===
declare -A R1_CONFIDENCE R2_CONFIDENCE
declare -A R1_REC R2_REC
declare -A HAS_R1 HAS_R2
AGENTS=()

for r1 in "$SESSION_DIR"/*-r1.md; do
    [ ! -f "$r1" ] && continue
    name=$(echo "$(basename "$r1")" | sed 's/-r1\.md//')
    AGENTS+=("$name")
    HAS_R1["$name"]=1
    
    conf=$(grep -i "confidence:" "$r1" 2>/dev/null | head -1 | sed 's/.*: *//' | tr '[:upper:]' '[:lower:]' || echo "unknown")
    R1_CONFIDENCE["$name"]="$conf"
    
    echo "  ✅ $name — Round 1 (confidence: $conf)"
done

echo ""

for r2 in "$SESSION_DIR"/*-r2.md; do
    [ ! -f "$r2" ] && continue
    name=$(echo "$(basename "$r2")" | sed 's/-r2\.md//')
    HAS_R2["$name"]=1
    
    conf=$(grep -i "confidence:" "$r2" 2>/dev/null | head -1 | sed 's/.*: *//' | tr '[:upper:]' '[:lower:]' || echo "unknown")
    R2_CONFIDENCE["$name"]="$conf"
    
    echo "  ✅ $name — Round 2 (confidence: $conf)"
done

echo ""

if [ ${#AGENTS[@]} -eq 0 ]; then
    echo "❌ No agent responses found."
    exit 1
fi

# === Generate Synthesis ===
{
    echo "# Council Synthesis: $QUESTION"
    echo ""
    echo "**Session:** $SESSION_ID"
    echo "**Synthesized:** $TIMESTAMP"
    echo "**Synthesized by:** $AGENT (Pain, Chief of Staff)"
    echo ""
    echo "---"
    echo ""
    
    # === Executive Summary (to be filled by Pain) ===
    echo "## Executive Summary"
    echo ""
    echo "*(Pain: write 1-3 sentence summary for Nagato here)*"
    echo ""
    
    # === Round 1 Summary ===
    echo "## Round 1 — Independent Analysis"
    echo ""
    for name in "${AGENTS[@]}"; do
        r1="$SESSION_DIR/${name}-r1.md"
        if [ -f "$r1" ]; then
            echo "### ${name^} (confidence: ${R1_CONFIDENCE[$name]:-unknown})"
            echo ""
            # Domain Analysis
            if grep -q "^## Domain Analysis" "$r1" 2>/dev/null; then
                sed -n '/^## Domain Analysis/,/^## /p' "$r1" | grep -v "^## " | head -10
            fi
            echo ""
            # Key recommendation
            if grep -q "^## Stakes" "$r1" 2>/dev/null; then
                echo "**Stakes:**"
                sed -n '/^## Stakes/,/^## /p' "$r1" | grep -v "^## " | head -5
                echo ""
            fi
            echo "---"
            echo ""
        fi
    done
    
    # === Round 2: The Debate ===
    if [ ${#HAS_R2[@]} -gt 0 ]; then
        echo "## Round 2 — Debate & Deliberation"
        echo ""
        
        # Collect consensus points
        echo "### Points of Agreement"
        echo ""
        for name in "${AGENTS[@]}"; do
            r2="$SESSION_DIR/${name}-r2.md"
            [ ! -f "$r2" ] && continue
            if grep -q "^## Points of Agreement" "$r2" 2>/dev/null; then
                sed -n '/^## Points of Agreement/,/^## /p' "$r2" | grep "^- " | head -5 | while read -r line; do
                    echo "- ${name^}: $line"
                done
            fi
        done
        echo ""
        
        # Collect disagreements
        echo "### Points of Disagreement (for Pain to resolve)"
        echo ""
        for name in "${AGENTS[@]}"; do
            r2="$SESSION_DIR/${name}-r2.md"
            [ ! -f "$r2" ] && continue
            if grep -q "^## Points of Disagreement" "$r2" 2>/dev/null; then
                sed -n '/^## Points of Disagreement/,/^## /p' "$r2" | grep "^- " | head -5 | while read -r line; do
                    echo "- ${name^}: $line"
                done
            fi
        done
        echo ""
        
        # Challenges exchanged
        echo "### Challenges Exchanged"
        echo ""
        for name in "${AGENTS[@]}"; do
            r2="$SESSION_DIR/${name}-r2.md"
            [ ! -f "$r2" ] && continue
            if grep -q "^## Challenges" "$r2" 2>/dev/null; then
                challenges=$(sed -n '/^## Challenges/,/^## /p' "$r2" | grep "^- " | head -5)
                if [ -n "$challenges" ]; then
                    echo "**${name^} challenged:**"
                    echo "$challenges"
                    echo ""
                fi
            fi
            if grep -q "^## Concessions" "$r2" 2>/dev/null; then
                concessions=$(sed -n '/^## Concessions/,/^## /p' "$r2" | grep "^- " | head -5)
                if [ -n "$concessions" ]; then
                    echo "**${name^} conceded:**"
                    echo "$concessions"
                    echo ""
                fi
            fi
        done
        
        # Refined recommendations
        echo "### Refined Recommendations (post-debate)"
        echo ""
        for name in "${AGENTS[@]}"; do
            r2="$SESSION_DIR/${name}-r2.md"
            [ ! -f "$r2" ] && continue
            if grep -q "^## Refined Recommendation" "$r2" 2>/dev/null; then
                rec=$(sed -n '/^## Refined Recommendation/,/^## /p' "$r2" | grep -v "^## " | head -5 | tr '\n' ' ')
                echo "- **${name^}:** $rec"
            fi
        done
        echo ""
    fi
    
    # === Pain's Unified Recommendation ===
    echo "---"
    echo ""
    echo "## Pain's Unified Recommendation"
    echo ""
    echo "*(Pain: synthesize everything above into a final recommendation for Nagato)*"
    echo ""
    echo "### The Council's Consensus"
    echo "- "
    echo ""
    echo "### Dissenting Views"
    echo "- "
    echo ""
    echo "### Tiebreakers Needed from Nagato"
    echo "- "
    echo ""
    echo "### Recommended Action"
    echo "1. "
    echo "2. "
    echo "3. "
    echo ""
    echo "### Confidence"
    echo "- Combined: [high|medium|low]"
    echo "- Key uncertainties: "
    echo ""
    
} > "$SYNTHESIS_FILE"

echo "Synthesis scaffold: $SYNTHESIS_FILE"
echo ""
echo "### Response Summary:"
for name in "${AGENTS[@]}"; do
    r1="$SESSION_DIR/${name}-r1.md"
    r2="$SESSION_DIR/${name}-r2.md"
    had_r2=""
    [ -f "$r2" ] && had_r2=" → R2 refined"
    
    echo ""
    echo "**${name^}** [R1: ${R1_CONFIDENCE[$name]:-?}$had_r2]"
    if [ -f "$r1" ] && grep -q "^## Domain Analysis" "$r1" 2>/dev/null; then
        sed -n '/^## Domain Analysis/,/^## /p' "$r1" | grep -v "^## " | head -3 | sed 's/^/  /'
    fi
done

echo ""
echo "---"
echo "Next: Pain fills in 'Pain's Unified Recommendation' in $SYNTHESIS_FILE"
echo "      Then deliver to Nagato."

# Log
{
    echo "---"
    echo "date: $TIMESTAMP"
    echo "agent: $AGENT"
    echo "importance: 3"
    echo "confidence: high"
    echo "---"
    echo "Council synthesis: $SESSION_ID | ${#AGENTS[@]} agents: ${AGENTS[*]} | Rounds: $( [ ${#HAS_R2[@]} -gt 0 ] && echo "2" || echo "1" )"
} >> "$BRAIN_DIR/events.log"
