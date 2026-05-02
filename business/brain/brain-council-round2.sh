#!/bin/bash
# brain-council-round2.sh — Generate Round 2 deliberation prompts
# Usage: brain-council-round2.sh <council-session-dir>
#
# Reads all Round 1 responses, generates Round 2 prompts where
# each agent sees what everyone else wrote and can debate.

set -euo pipefail

BRAIN_DIR="$(cd "$(dirname "$0")" && pwd)"
SESSION_DIR="$1"
AGENT="${AGENT_NAME:-pain}"

if [ -z "$SESSION_DIR" ] || [ ! -d "$SESSION_DIR" ]; then
    echo "Usage: brain-council-round2.sh <council-session-dir>"
    exit 1
fi

TIMESTAMP="$(TZ='America/New_York' date '+%Y-%m-%d %H:%M %Z')"

# Read manifest to get question and agent list
MANIFEST="$SESSION_DIR/manifest.md"
if [ ! -f "$MANIFEST" ]; then
    echo "❌ Manifest not found — not a valid council session"
    exit 1
fi

QUESTION=$(sed -n '/^## Question/{n;p;}' "$MANIFEST")
SESSION_ID=$(grep "Session:" "$MANIFEST" | head -1 | sed 's/.*: *//')

echo "╔══════════════════════════════════════╗"
echo "║  🏛️  Council Round 2 — Debate Phase   ║"
echo "╚══════════════════════════════════════╝"
echo ""
echo "Session: $SESSION_ID"
echo ""

# Collect all Round 1 responses
R1_COUNT=0
MISSING=""
for prompt in "$SESSION_DIR"/prompt-*-r1.md; do
    [ ! -f "$prompt" ] && continue
    basename="$(basename "$prompt")"
    # Extract agent name: prompt-KAKUZU-r1.md → kakuzu
    agent_name=$(echo "$basename" | sed 's/prompt-\(.*\)-r1\.md/\1/')
    
    r1_file="$SESSION_DIR/${agent_name}-r1.md"
    if [ -f "$r1_file" ] && [ -s "$r1_file" ]; then
        echo "  ✅ $agent_name — Round 1 response ready ($(wc -l < "$r1_file") lines)"
        R1_COUNT=$((R1_COUNT + 1))
    else
        echo "  ⏳ $agent_name — waiting for Round 1 response"
        MISSING="$MISSING $agent_name"
    fi
done

echo ""

if [ -n "$MISSING" ]; then
    echo "⚠️  Missing Round 1 responses:$MISSING"
    echo "   Run again after all agents have submitted."
    echo ""
fi

if [ "$R1_COUNT" -lt 2 ]; then
    echo "❌ Need at least 2 Round 1 responses for meaningful debate. Got $R1_COUNT."
    exit 1
fi

# === Agent Registry (kept in sync with brain-council.sh) ===
agent_domain() {
    case "$1" in
        kakuzu) echo "cash, margins, unit economics, ROAS, burn, pricing, credit, runway" ;;
        sasori)  echo "code, architecture, deployment, tech stack, automation, tools, infrastructure" ;;
        itachi)  echo "verification, fact-checking, security, compliance, risk, data integrity" ;;
        deidara) echo "content, viral strategy, social media, creator partnerships, brand voice" ;;
        *)       echo "general analysis" ;;
    esac
}

# Generate Round 2 prompt for each agent that submitted R1
for prompt in "$SESSION_DIR"/prompt-*-r1.md; do
    [ ! -f "$prompt" ] && continue
    agent=$(echo "$(basename "$prompt")" | sed 's/prompt-\(.*\)-r1\.md/\1/')
    r1_file="$SESSION_DIR/${agent}-r1.md"
    [ ! -f "$r1_file" ] && continue
    
    domain_desc="$(agent_domain "$agent")"
    prompt_file="$SESSION_DIR/prompt-${agent}-r2.md"
    
    # Build list of other agents
    other_list=""
    for other_r1 in "$SESSION_DIR"/*-r1.md; do
        [ ! -f "$other_r1" ] && continue
        other_name=$(echo "$(basename "$other_r1")" | sed 's/-r1\.md//')
        [ "$other_name" = "$agent" ] && continue
        other_domain="$(agent_domain "$other_name")"
        other_list="${other_list}  - **${other_name^}** — $other_domain"$'\n'
    done
    
    {
        echo "# 🏛️ Akatsuki Council — Round 2: Debate & Consensus"
        echo ""
        echo "**Council Session:** $SESSION_ID"
        echo "**Your Role:** ${agent^} — $domain_desc"
        echo "**Phase:** Round 2 — Debate"
        echo ""
        echo "---"
        echo ""
        echo "## The Question"
        echo ""
        echo "$QUESTION"
        echo ""
        echo "---"
        echo ""
        echo "## Your Round 1 Analysis"
        echo ""
        sed -n '/^## Domain Analysis/,/^## /p' "$r1_file" 2>/dev/null | head -15 || echo "(see your R1 file)"
        echo ""
        echo "---"
        echo ""
        echo "## What Other Council Members Said (Round 1)"
        echo ""
        
        for other_r1 in "$SESSION_DIR"/*-r1.md; do
            [ ! -f "$other_r1" ] && continue
            other_name=$(echo "$(basename "$other_r1")" | sed 's/-r1\.md//')
            [ "$other_name" = "$agent" ] && continue
            other_domain="$(agent_domain "$other_name")"
            
            echo "### ${other_name^} ($other_domain)"
            echo ""
            
            # Include key sections from their response
            if grep -q "^## Domain Analysis" "$other_r1" 2>/dev/null; then
                sed -n '/^## Domain Analysis/,/^## /p' "$other_r1" | head -20
            fi
            
            if grep -q "^## Stakes & Risks" "$other_r1" 2>/dev/null; then
                echo ""
                sed -n '/^## Stakes & Risks/,/^## /p' "$other_r1" | head -10
            fi
            
            if grep -q "^## Questions for Other Agents" "$other_r1" 2>/dev/null; then
                echo ""
                sed -n '/^## Questions for Other Agents/,/^## /p' "$other_r1" | head -10
            fi
            
            # Extract any @mentions of this agent specifically
            mentions=$(grep -i "@${agent}" "$other_r1" 2>/dev/null || true)
            if [ -n "$mentions" ]; then
                echo ""
                echo "**⚠️  Questions directed at YOU:**"
                echo "$mentions" | while read -r m; do echo "> $m"; done
            fi
            
            echo ""
            echo "---"
            echo ""
        done
        
        cat <<'R2_INSTRUCTIONS'

## Round 2 Instructions

This is the debate phase. You've now read everyone's perspective. Engage.

### Your Tasks:

1. **Answer questions directed at you** — Other agents may have @mentioned you. Answer them directly.

2. **Challenge what you disagree with** — Be specific and constructive:
   - "I challenge @kakuzu's assumption that margin is 40%. Our COGS model shows..."
   - "I disagree with @sasori's timeline. Building that requires..."

3. **Acknowledge when you're convinced** — Changing your mind is strength, not weakness:
   - "After reading @agent's analysis, I now agree that..."
   - "@agent raised a risk I hadn't considered. My updated position is..."

4. **Work toward consensus** — The goal is ONE recommendation:
   - Find where you all agree → state it explicitly
   - Where you disagree → narrow it to the specific point
   - If consensus is impossible → clearly document the split for Pain to decide

5. **Refine your recommendation** — Update based on the full council's input.

### Council Rules
- Be direct. No diplomacy filters. "I think @kakuzu is wrong about X because..."
- Respect domains. Kakuzu owns numbers. Sasori owns feasibility. Numbers beat opinions.
- Don't re-litigate. If you all agree on something, move on.
- Flag unresolved splits for Pain. "Pain needs to decide between X and Y because..."

## Output Format

Write to your Round 2 file:

```
# Round 2 — AGENT_NAME
**Confidence:** [high|medium|low]

## Responses to @Mentions
- @other_agent: [direct answer to their question]

## Challenges
- I challenge @agent's [claim/assumption] because [reasoning + evidence]

## Concessions
- I've changed my position on [point] after reading @agent's analysis

## Points of Agreement (Council Consensus)
- We all agree that...
- @agent and I agree on...

## Points of Disagreement (for Pain)
- @agent and I disagree on [specific point]. Their view: X. My view: Y.
- **Tiebreaker needed:** [what Pain must decide]

## Refined Recommendation
[Your updated recommendation after full deliberation]

## Council Position
[What you believe is the council's unified position — or the documented split]
```
R2_INSTRUCTIONS
        
    } > "$prompt_file"
    
    echo "  📋 $agent — Round 2 prompt generated"
    echo "     Prompt: $prompt_file"
    echo "     Response file: $SESSION_DIR/${agent}-r2.md"
    echo ""
done

echo "---"
echo "### Next: Spawn all agents for Round 2 debate"
echo ""
for prompt in "$SESSION_DIR"/prompt-*-r2.md; do
    [ ! -f "$prompt" ] && continue
    agent=$(echo "$(basename "$prompt")" | sed 's/prompt-\(.*\)-r2\.md/\1/')
    echo "sessions_spawn(agentId=\"$agent\", task=\"\$(cat $prompt)\", mode=\"run\")"
done
echo ""
echo "After Round 2: brain-council-synthesize.sh $SESSION_DIR"
