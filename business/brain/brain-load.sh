#!/bin/bash
# brain-load.sh v2 — Agent brain loader with output gating and passive recall
# Usage: brain-load.sh <agent-name> [context-type]
#
# Context types:
#   startup        — default session start (loads identity + open decisions)
#   financial      — load runway, cogs, financial state
#   brand          — load brand assets, competitive intel
#   compliance     — load supplier files, FDA docs
#   architecture   — load architecture docs, decisions
#   general        — default hot digest only
#
# Principles:
#   A. Private-by-default — reads from episodic/<agent>.log first
#   B. Importance scoring — filters by importance 3+ for passive recall

set -euo pipefail

BRAIN_DIR="$(cd "$(dirname "$0")" && pwd)"
WORKSPACE_DIR="$(cd "$BRAIN_DIR/../.." && pwd)"
AGENT="$1"
CONTEXT="${2:-startup}"

HOT_DIR="$BRAIN_DIR/hot"
mkdir -p "$HOT_DIR"

OUTPUT="$HOT_DIR/${AGENT}.md"

# === Passive Recall — Auto-surface before every load ===
passive_recall() {
    echo "## ⚠️ Passive Recall"
    echo ""
    
    # P0 events — per-entry quarantine filter via Python
    echo "### P0 Events (24h)"
    local p0_count=0
    if [ -f "$BRAIN_DIR/events.log" ]; then
        python3 "$BRAIN_DIR/brain-recall.py" "$BRAIN_DIR/events.log" > "$HOT_DIR/.p0-tmp" 2>/dev/null
        if [ -s "$HOT_DIR/.p0-tmp" ]; then
            while IFS= read -r line; do
                echo "- $line"
                p0_count=$((p0_count + 1))
            done < "$HOT_DIR/.p0-tmp"
        fi
    fi
    [ "$p0_count" -eq 0 ] && echo "(none)"
    echo ""
    
    # My active tasks (importance 3+)
    echo "### My Active Tasks (importance ≥3)"
    local tasks=0
    if [ -f "$BRAIN_DIR/tasks/${AGENT}.md" ]; then
        grep -E "^- \[ \]" "$BRAIN_DIR/tasks/${AGENT}.md" 2>/dev/null | head -8 | while read -r t; do
            echo "$t"
            tasks=$((tasks + 1))
        done
    fi
    [ "${tasks:-0}" -eq 0 ] && echo "(none)"
    echo ""
    
    # Open decisions affecting this agent
    echo "### Open Decisions"
    local decs=0
    if [ -f "$BRAIN_DIR/decisions.md" ]; then
        grep -A1 "OPEN" "$BRAIN_DIR/decisions.md" 2>/dev/null | grep -i -E "${AGENT}|all" | head -5 | while read -r d; do
            echo "- $d"
            decs=$((decs + 1))
        done
    fi
    [ "${decs:-0}" -eq 0 ] && echo "(none)"
    echo ""
    
    # Unread inbox
    echo "### Unread Inbox"
    local inbox_count=0
    if [ -f "$BRAIN_DIR/inbox/${AGENT}.md" ] && [ -s "$BRAIN_DIR/inbox/${AGENT}.md" ]; then
        tail -5 "$BRAIN_DIR/inbox/${AGENT}.md" | while read -r msg; do
            echo "$msg"
            inbox_count=$((inbox_count + 1))
        done
    fi
    [ "${inbox_count:-0}" -eq 0 ] && echo "(empty)"
    echo ""
}

# === Output Gating — Context-specific loading ===
output_gate() {
    echo "## 📋 Context Bundle — $CONTEXT"
    echo ""
    
    case "$CONTEXT" in
        financial)
            echo "### Financial State"
            if [ -f "$BRAIN_DIR/state/runway.md" ] && [ -s "$BRAIN_DIR/state/runway.md" ]; then
                head -20 "$BRAIN_DIR/state/runway.md"
            else
                echo "*(state/runway.md is empty — first boot, no data yet)*"
            fi
            echo ""
            if [ -f "$BRAIN_DIR/state/cogs.md" ] && [ -s "$BRAIN_DIR/state/cogs.md" ]; then
                head -20 "$BRAIN_DIR/state/cogs.md"
            else
                echo "*(state/cogs.md is empty — first boot, no data yet)*"
            fi
            echo ""
            [ -f "$BRAIN_DIR/agents/kakuzu-foundation.md" ] && head -20 "$BRAIN_DIR/agents/kakuzu-foundation.md" || echo "(kakuzu not deployed)"
            ;;
        brand)
            echo "### Brand Context"
            [ -f "$WORKSPACE_DIR/memory/business-context.md" ] && grep -A5 "HERO CLAIM\|COMPETITIVE" "$WORKSPACE_DIR/memory/business-context.md" | head -30 || echo "(context not found)"
            ;;
        compliance)
            echo "### Compliance Context"
            [ -f "$BRAIN_DIR/north-star.md" ] && grep -A3 "compliance\|FDA\|TOS\|FTC" "$BRAIN_DIR/north-star.md" | head -20 || echo "(north-star not found)"
            ;;
        architecture)
            echo "### Architecture Context"
            [ -f "$BRAIN_DIR/BRAIN-ARCHITECTURE-v2.md" ] && grep "^## " "$BRAIN_DIR/BRAIN-ARCHITECTURE-v2.md" | head -10 || echo "(architecture not found)"
            [ -f "$BRAIN_DIR/OWNERSHIP.md" ] && grep -A3 "Core Principles" "$BRAIN_DIR/OWNERSHIP.md" | head -15 || echo "(ownership not found)"
            ;;
        build)
            echo "### Build Context"
            if [ -f "$BRAIN_DIR/state/tools.md" ] && [ -s "$BRAIN_DIR/state/tools.md" ]; then
                head -20 "$BRAIN_DIR/state/tools.md"
            else
                echo "*(state/tools.md is empty — no tools deployed yet)*"
            fi
            echo ""
            if [ -f "$BRAIN_DIR/state/builds.md" ] && [ -s "$BRAIN_DIR/state/builds.md" ]; then
                head -20 "$BRAIN_DIR/state/builds.md"
            else
                echo "*(state/builds.md is empty — no builds yet)*"
            fi
            echo ""
            [ -f "$BRAIN_DIR/agents/sasori-foundation.md" ] && head -20 "$BRAIN_DIR/agents/sasori-foundation.md" || echo "(sasori not deployed)"
            ;;
        audit)
            echo "### Audit Context"
            if [ -f "$BRAIN_DIR/state/audit.md" ] && [ -s "$BRAIN_DIR/state/audit.md" ]; then
                head -30 "$BRAIN_DIR/state/audit.md"
            else
                echo "*(state/audit.md is empty — no audits yet)*"
            fi
            echo ""
            if [ -f "$BRAIN_DIR/state/agent-health.md" ] && [ -s "$BRAIN_DIR/state/agent-health.md" ]; then
                head -20 "$BRAIN_DIR/state/agent-health.md"
            else
                echo "*(state/agent-health.md is empty — no scores yet)*"
            fi
            echo ""
            [ -f "$BRAIN_DIR/agents/itachi-foundation.md" ] && grep -A3 "^## Audit Types" "$BRAIN_DIR/agents/itachi-foundation.md" | head -10 || echo "(itachi not deployed)"
            ;;
        startup|general)
            # Infrastructure is already loaded in the main hot digest section
            ;;
        *)
            echo "(unknown context: $CONTEXT — defaulting to general)"
            ;;
    esac
}

# === Generate hot digest ===
{
    echo "---"
    echo "agent: $AGENT"
    echo "generated: $(date -Iseconds)"
    echo "context: $CONTEXT"
    echo "---"
    echo ""
    
    echo "# Hot Digest — $AGENT"
    echo ""
    
    # 1. Identity
    echo "## 🎭 Identity"
    if [ -f "$BRAIN_DIR/agents/${AGENT}-foundation.md" ]; then
        head -12 "$BRAIN_DIR/agents/${AGENT}-foundation.md"
    else
        echo "*(no foundation doc — using defaults)*"
    fi
    echo ""
    
    # 2. Infrastructure (what's available to build with)
    echo "## 🛠️ Infrastructure"
    if [ -f "$BRAIN_DIR/state/tools.md" ] && [ -s "$BRAIN_DIR/state/tools.md" ]; then
        sed -n '/^## 🖥️ Host/,/^## 📝 Notes/p' "$BRAIN_DIR/state/tools.md" | head -40
    else
        echo "*(state/tools.md is empty — no tools inventoried yet)*"
    fi
    echo ""
    
    # 3. North Star (priorities + constraints)
    echo "## 📜 North Star"
    if [ -f "$BRAIN_DIR/north-star.md" ]; then
        sed -n '/^## What agents should optimize/,/^## Hard stops/p' "$BRAIN_DIR/north-star.md" | head -15
        echo ""
        echo "**Hard stops:**"
        sed -n '/^## Hard stops/,/^## Resolved decisions/p' "$BRAIN_DIR/north-star.md" | grep "^- \*\*" | head -5
    else
        echo "*(north-star.md not found)*"
    fi
    echo ""
    
    # 4. Passive Recall
    passive_recall
    
    # 5. Output-gated context
    output_gate
    
} > "$OUTPUT"

# === Token budget enforcement ===
WORD_COUNT=$(wc -w < "$OUTPUT")
ESTIMATED_TOKENS=$(( WORD_COUNT * 4 / 3 ))

if [ "$ESTIMATED_TOKENS" -gt 1000 ]; then
    echo "⚠️  Hot digest for $AGENT: ~${ESTIMATED_TOKENS} tokens (budget 1000). Truncating." >&2
    head -c 5000 "$OUTPUT" > "$OUTPUT.tmp" && mv "$OUTPUT.tmp" "$OUTPUT"
fi

echo "✅ Hot digest generated: $OUTPUT (~${ESTIMATED_TOKENS} tokens, context: $CONTEXT)"
