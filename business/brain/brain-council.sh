#!/bin/bash
# brain-council.sh — Akatsuki Council: multi-agent deliberation with debate
# Usage: brain-council.sh "<question>" [--agents kakuzu,sasori] [--rounds 2] [--priority P1|P2|P3]
#
# The council is a multi-round deliberation where agents:
#   Round 1: Submit domain analysis (independent)
#   Round 2: Read each other's analyses, challenge, refine, find consensus
#   Pain:   Moderates, synthesizes, delivers to Nagato
#
# Agents communicate through the council directory — their shared deliberation space.

set -euo pipefail

BRAIN_DIR="$(cd "$(dirname "$0")" && pwd)"
COUNCIL_DIR="$BRAIN_DIR/council"
TIMESTAMP="$(TZ='America/New_York' date '+%Y-%m-%d %H:%M %Z')"
SESSION_ID="$(TZ='America/New_York' date '+%Y%m%d-%H%M')"
AGENT="${AGENT_NAME:-pain}"

DEFAULT_AGENTS="kakuzu,sasori"
MAX_ROUNDS=2
PRIORITY="P2"
QUESTION=""
AGENT_LIST=""

while [ $# -gt 0 ]; do
    case "$1" in
        --agents) AGENT_LIST="$2"; shift 2 ;;
        --rounds) MAX_ROUNDS="$2"; shift 2 ;;
        --priority) PRIORITY="$2"; shift 2 ;;
        *) QUESTION="$1"; shift ;;
    esac
done

if [ -z "$QUESTION" ]; then
    echo "Usage: brain-council.sh \"<question>\" [--agents kakuzu,sasori,itachi] [--rounds 2] [--priority P1|P2|P3]"
    echo ""
    echo "Deliberation flow:"
    echo "  Round 1 — Agents submit independent domain analysis"
    echo "  Round 2 — Agents read each other, challenge, refine, find consensus"
    echo "  Pain    — Synthesizes and presents to Nagato"
    exit 1
fi

AGENT_LIST="${AGENT_LIST:-$DEFAULT_AGENTS}"
SLUG="$(echo "$QUESTION" | tr '[:upper:]' '[:lower:]' | sed 's/[^a-z0-9]/-/g' | sed 's/-\+/-/g' | sed 's/^-//;s/-$//' | cut -c1-60)"
SESSION_DIR="$COUNCIL_DIR/$(TZ='America/New_York' date '+%Y-%m-%d')/${SESSION_ID}-${SLUG}"
mkdir -p "$SESSION_DIR"

# === Agent Registry ===
agent_domain() {
    case "$1" in
        kakuzu) echo "financial|state/runway.md state/cogs.md state/ppc.md|cash, margins, unit economics, ROAS, burn, pricing, credit, runway" ;;
        sasori)  echo "build|state/tools.md state/builds.md|code, architecture, deployment, tech stack, automation, tools, infrastructure" ;;
        itachi)  echo "audit|state/audit.md state/security.md state/agent-health.md|verification, fact-checking, security, compliance, risk, data integrity" ;;
        deidara) echo "brand|tasks/deidara.md|content, viral strategy, social media, creator partnerships, brand voice, visual identity" ;;
        *)       echo "general||general analysis" ;;
    esac
}

# === Context loader ===
load_context() {
    local agent="$1"
    
    # North star
    if [ -f "$BRAIN_DIR/north-star.md" ]; then
        grep "^[0-9]\. " "$BRAIN_DIR/north-star.md" | head -5
    fi
    echo ""
    
    # Agent's state files
    local files
    files="$(agent_domain "$agent" | cut -d'|' -f2)"
    for f in $files; do
        if [ -f "$BRAIN_DIR/$f" ] && [ -s "$BRAIN_DIR/$f" ]; then
            echo "### $f"
            head -20 "$BRAIN_DIR/$f" 2>/dev/null
            echo ""
        fi
    done
    
    # Infrastructure (all agents)
    if [ -f "$BRAIN_DIR/state/tools.md" ]; then
        echo "### Infrastructure"
        sed -n '/^## 🖥️ Host/,/^## 🛠️ Built/p' "$BRAIN_DIR/state/tools.md" 2>/dev/null
        echo ""
    fi
}

# === Round 1 Prompt: Independent analysis ===
generate_round1() {
    local agent="$1"
    local domain_desc
    domain_desc="$(agent_domain "$agent" | cut -d'|' -f3)"
    local other_agents=""
    IFS=',' read -ra ALL <<< "$AGENT_LIST"
    for a in "${ALL[@]}"; do
        a="$(echo "$a" | xargs)"
        [ "$a" != "$agent" ] && other_agents="$other_agents $a"
    done
    
    cat <<'PROMPT_HEADER'
You are participating in an Akatsuki Council deliberation. Multiple agents are analyzing the same question from different perspectives. After this round, you will see what the other agents wrote and have a chance to debate, refine, and find consensus.

PROMPT_HEADER

    cat <<EOF
# 🏛️ Akatsuki Council — Round 1: Domain Analysis

**Council Session:** $SESSION_ID
**Your Role:** ${agent^} — $domain_desc
**Other Council Members:**$other_agents
**Priority:** $PRIORITY

---

## The Question (from Nagato)

$QUESTION

---

## Your Domain Context

EOF
    
    load_context "$agent"
    
    cat <<'ROUND1_FOOTER'

---

## Round 1 Instructions

Analyze the question strictly from your domain expertise. Do NOT try to answer for other agents' domains.

1. **What does your domain data say?** — Ground your analysis in actual numbers/files, not speculation.
2. **What are the financial/stakes?** — If this involves money, quantify it.
3. **What are the risks from your perspective?** — What could go wrong?
4. **What opportunities do you see?** — What's the upside from your angle?
5. **What assumptions are you making?** — State confidence for each.
6. **What do you NEED from other agents?** — Flag questions for specific council members. Example: "@kakuzu: what's the landed cost per unit?" or "@sasori: can we build that in < 2 hours?"

**CRITICAL:** Flag questions for other agents explicitly with @mentions. This is how the debate starts.

## Output Format

Write your analysis to the council deliberation file (Pain will tell you the path).

Use this exact format:

```
# Round 1 — AGENT_NAME
**Confidence:** [high|medium|low]
**Importance:** [1-5]

## Domain Analysis
[Your analysis grounded in your domain data]

## Stakes & Risks
[Quantified stakes from your perspective]

## Opportunities
[What's the upside?]

## Questions for Other Agents
- @kakuzu: [specific question]
- @sasori: [specific question]

## Assumptions
- [Assumption] (confidence: high/medium/low)
```

After all agents submit Round 1, Pain will distribute everyone's analyses for Round 2 debate.
ROUND1_FOOTER
}

# === Round 2 Prompt: Debate & consensus ===
generate_round2() {
    local agent="$1"
    local domain_desc
    domain_desc="$(agent_domain "$agent" | cut -d'|' -f3)"
    
    cat <<EOF
# 🏛️ Akatsuki Council — Round 2: Debate & Consensus

**Council Session:** $SESSION_ID
**Your Role:** ${agent^} — $domain_desc

---

## The Question

$QUESTION

---

## What Other Agents Said

EOF
    
    # Include all other agents' Round 1 responses
    for response in "$SESSION_DIR"/*-r1.md; do
        [ ! -f "$response" ] && continue
        local basename
        basename="$(basename "$response" .md)"
        local other_agent="${basename%-r1}"
        [ "$other_agent" = "$agent" ] && continue
        
        echo "### ${other_agent^}'s Analysis"
        echo ""
        # Include the full analysis but summarize if too long
        if [ -f "$response" ]; then
            head -80 "$response"
            local lines
            lines=$(wc -l < "$response")
            if [ "$lines" -gt 80 ]; then
                echo ""
                echo "... (truncated, $lines total lines — see council file for full)"
            fi
        else
            echo "(no response submitted)"
        fi
        echo ""
        echo "---"
        echo ""
    done
    
    cat <<'ROUND2_FOOTER'

## Round 2 Instructions

Now the real deliberation begins. You've read everyone's Round 1 analysis.

1. **Respond to questions directed at you** — If another agent @mentioned you, answer their question.
2. **Challenge assumptions** — If an agent made an assumption you think is wrong, say so. Be specific.
3. **Find consensus** — Where do you agree with other agents? State it explicitly: "I agree with @agent on X because..."
4. **Surface disagreement** — Where do you disagree? Why? Be constructive: "I disagree with @agent on Y. Here's my reasoning..."
5. **Refine your position** — Given what others said, does your recommendation change? Update it.
6. **Propose a unified recommendation** — Work toward a single recommendation you can all stand behind. If you can't get there, clearly state the split and why.

**Council rules:**
- Be direct. "I think @kakuzu is wrong about X because..."
- Respect domains. Kakuzu owns the numbers. Sasori owns feasibility. Itachi owns verification.
- Acknowledge when you're convinced. "After reading @agent's analysis, I've changed my position on..."
- If you can't resolve a disagreement, flag it for Pain to break the tie.

## Output Format

Write to your Round 2 file (Pain will tell you the path):

```
# Round 2 — AGENT_NAME
**Confidence:** [high|medium|low]

## Responses to Questions
- @other_agent: [answer to their question]

## Challenges to Other Agents
- I challenge @agent on [point] because [reasoning]

## Points of Agreement
- I agree with @agent on [point]

## Points of Disagreement
- I disagree with @agent on [point]. My reasoning: [explain]

## Refined Recommendation
[Your updated recommendation after deliberation]

## Unified Position
[The consensus you believe the council has reached — or the split if unresolved]
```

After Round 2, Pain will synthesize and present the council's recommendation to Nagato.
ROUND2_FOOTER
}

# === Main: Convene the council ===
echo "╔══════════════════════════════════════╗"
echo "║   🏛️  Akatsuki Council Convened      ║"
echo "╚══════════════════════════════════════╝"
echo ""
echo "Session:  $SESSION_ID"
echo "Question: $QUESTION"
echo "Rounds:   $MAX_ROUNDS"
echo "Priority: $PRIORITY"
echo ""

# Write session manifest
{
    echo "# Council Session Manifest"
    echo "**Session:** $SESSION_ID"
    echo "**Convened:** $TIMESTAMP"
    echo "**Convened by:** $AGENT"
    echo "**Priority:** $PRIORITY"
    echo "**Rounds:** $MAX_ROUNDS"
    echo ""
    echo "## Question"
    echo "$QUESTION"
    echo ""
    echo "## Council Members"
    IFS=',' read -ra ALL <<< "$AGENT_LIST"
    for a in "${ALL[@]}"; do
        a="$(echo "$a" | xargs)"
        echo "- **${a^}** — $(agent_domain "$a" | cut -d'|' -f3)"
    done
    echo ""
    echo "## Deliberation Protocol"
    echo "1. **Round 1** — Independent domain analysis. Agents flag questions for each other."
    echo "2. **Round 2** — Debate. Agents read all analyses, respond to questions, challenge, refine, find consensus."
    echo "3. **Pain synthesizes** — Reads all rounds, produces unified recommendation for Nagato."
    echo ""
    echo "## Spawn Instructions"
    echo ""
    echo "### Round 1 — Spawn each agent:"
    IFS=',' read -ra ALL2 <<< "$AGENT_LIST"
    for a in "${ALL2[@]}"; do
        a="$(echo "$a" | xargs)"
        echo "- sessions_spawn(agentId=\"$a\", task=\"\$(cat $SESSION_DIR/prompt-${a}-r1.md)\", mode=\"run\")"
    done
    echo ""
    echo "### Round 2 — After all R1 responses, spawn each agent:"
    IFS=',' read -ra ALL3 <<< "$AGENT_LIST"
    for a in "${ALL3[@]}"; do
        a="$(echo "$a" | xargs)"
        echo "- sessions_spawn(agentId=\"$a\", task=\"\$(cat $SESSION_DIR/prompt-${a}-r2.md)\", mode=\"run\")"
    done
    echo ""
    echo "### Synthesize:"
    echo "- brain-council-synthesize.sh $SESSION_DIR"
} > "$SESSION_DIR/manifest.md"

# Generate Round 1 prompts
echo "## Round 1 — Independent Analysis"
echo ""
IFS=',' read -ra AGENTS <<< "$AGENT_LIST"
for agent in "${AGENTS[@]}"; do
    agent="$(echo "$agent" | xargs)"
    if [ ! -f "$BRAIN_DIR/agents/${agent}-foundation.md" ]; then
        echo "  ⚠️  $agent — foundation doc missing, skipping"
        continue
    fi
    
    prompt_file="$SESSION_DIR/prompt-${agent}-r1.md"
    generate_round1 "$agent" > "$prompt_file"
    
    domain="$(agent_domain "$agent" | cut -d'|' -f3)"
    echo "  📋 $agent — $domain"
    echo "     Prompt: $prompt_file"
    echo "     Response file: $SESSION_DIR/${agent}-r1.md"
    echo ""
done

# Pre-generate Round 2 prompt template (filled in after R1 responses)
echo "## Round 2 — Debate & Consensus"
echo ""
echo "  ⏳ Round 2 prompts generated after all Round 1 responses are in."
echo "     Run: brain-council-round2.sh $SESSION_DIR"
echo ""

echo "---"
echo "Session: $SESSION_DIR"
echo ""
echo "### Pain's Orchestration Flow:"
echo "1. Spawn all agents for Round 1 (independent analysis)"
echo "2. Wait for all to complete"
echo "3. Run: brain-council-round2.sh $SESSION_DIR"
echo "4. Spawn all agents for Round 2 (debate)"
echo "5. Run: brain-council-synthesize.sh $SESSION_DIR"
echo "6. Deliver to Nagato"

# Log
{
    echo "---"
    echo "date: $TIMESTAMP"
    echo "agent: $AGENT"
    echo "importance: 3"
    echo "confidence: high"
    echo "---"
    echo "Council convened ($SESSION_ID): $QUESTION | Agents: $AGENT_LIST | Rounds: $MAX_ROUNDS"
} >> "$BRAIN_DIR/events.log"
