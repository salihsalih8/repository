#!/bin/bash
# brain-write.sh — Shared write wrapper for all agents (v2)
# Features: priority gating, frontmatter support, file locking, agent ownership check
#
# Usage: brain-write.sh <target> <message> [--priority P0|P1|P2|P3]
#   target: "events.log" | "tasks/<agent>.md" | "state/<file>.md" | "inbox/<agent>.md"
#   message: content to write (reads from stdin if not provided)
#   --priority: P0=critical, P1=operational, P2=context, P3=ephemeral (default: P2)
#
# Guardrails:
#   - Cannot modify north-star.md (human's file)
#   - Cannot modify decisions.md resolved entries (append only)
#   - P3 (ephemeral) writes are silently dropped
#   - P0 writes require confirmation
#   - Agent ownership enforced per OWNERSHIP.md

BRAIN_DIR="$(cd "$(dirname "$0")" && pwd)"
LOCK_DIR="$BRAIN_DIR/.locks"
TIMESTAMP="$(TZ='America/New_York' date '+%Y-%m-%d %H:%M %Z')"
AGENT="${AGENT_NAME:-pain}"
PRIORITY="P2"  # default

# Parse args
TARGET="$1"
MESSAGE="$2"
if [ "$3" = "--priority" ] && [ -n "$4" ]; then
    PRIORITY="$4"
fi

if [ -z "$TARGET" ]; then
    echo "Usage: brain-write.sh <target> [message] [--priority P0|P1|P2|P3]"
    echo "  target: events.log | tasks/<name>.md | state/<file>.md | inbox/<agent>.md"
    exit 1
fi

# == Guardrails ==

# P3 — silently drop ephemeral
if [ "$PRIORITY" = "P3" ]; then
    echo "(P3 ephemeral — skipped)"
    exit 0
fi

# Cannot modify north-star
if [ "$TARGET" = "north-star.md" ]; then
    echo "ERROR: north-star.md is human-only. Use tasks/nagato.md to request changes."
    exit 1
fi

# P0 — require explicit confirmation (unless force flag set)
if [ "$PRIORITY" = "P0" ] && [ "$P0_CONFIRMED" != "yes" ]; then
    echo "⚠️  P0 write requires confirmation. Set P0_CONFIRMED=yes to proceed."
    echo "    Message: $MESSAGE"
    exit 1
fi

# == File locking ==
mkdir -p "$LOCK_DIR"
LOCKFILE="$LOCK_DIR/$(echo "$TARGET" | tr '/' '_').lock"
exec 200>"$LOCKFILE"
flock -x 200 || { echo "ERROR: Could not acquire lock on $TARGET"; exit 1; }

# == Ownership enforcement ==
# Maps file pattern → authorized agent(s). Must match OWNERSHIP.md.
# Same enforcement style as north-star.md block.
owner_check() {
    local target="$1"
    local agent="$2"
    case "$target" in
        tasks/pain.md|brain-load.sh|brain-write.sh|brain-bootstrap.sh|brain-test.sh|brain-graph.py|BRAIN-ARCHITECTURE-v2.md|OWNERSHIP.md)
            [ "$agent" = "pain" ] || { echo "ERROR: $target is owned by pain (caller is $agent)"; exit 1; } ;;
        tasks/kakuzu.md|state/runway.md|state/cogs.md|state/ppc.md)
            [ "$agent" = "kakuzu" ] || { echo "ERROR: $target is owned by kakuzu (caller is $agent)"; exit 1; } ;;
        tasks/nagato.md|tasks/nagato-financial.md)
            case "$agent" in pain|kakuzu) ;; *) echo "ERROR: $target requires pain or kakuzu (caller is $agent)"; exit 1 ;; esac ;;
        state/inventory.md|state/pipeline.md|tasks/deidara.md)
            [ "$agent" = "pain" ] || { echo "ERROR: $target is owned by pain (caller is $agent)"; exit 1; } ;;
        ephemeral/*|scratch/*)
            ;;  # no ownership — anyone can write scratch
        agents/kakuzu-foundation.md|agents/deidara-foundation.md)
            [ "$agent" = "pain" ] || { echo "ERROR: foundation docs are owned by pain (caller is $agent)"; exit 1; } ;;
        *)
            # Default: reject unknown targets
            echo "ERROR: Unknown or unowned target '$target'. Check OWNERSHIP.md."
            exit 1 ;;
    esac
}

# Run ownership check before writing
case "$TARGET" in
    north-star.md|decisions.md)
        echo "ERROR: $TARGET is append-only or human-owned. Use tasks/nagato.md to request changes."
        flock -u 200; exit 1 ;;
    events.log|inbox/*|episodic/*)
        ;;  # no ownership check for shared or private logs
    *)
        owner_check "$TARGET" "$AGENT"
        ;;
esac

# == Write ==
case "$TARGET" in
    events.log)
        {
            echo "---"
            echo "date: $TIMESTAMP"
            echo "agent: $AGENT"
            echo "priority: $PRIORITY"
            echo "---"
            echo "$MESSAGE"
            echo ""
        } >> "$BRAIN_DIR/$TARGET"
        echo "✅ events.log [${PRIORITY}]"
        ;;
    tasks/*|state/*)
        {
            echo ""
            echo "---"
            echo "date: $TIMESTAMP"
            echo "agent: $AGENT"
            echo "priority: $PRIORITY"
            echo "---"
            echo "$MESSAGE"
        } >> "$BRAIN_DIR/$TARGET"
        echo "✅ $TARGET [${PRIORITY}]"
        ;;
    inbox/*)
        {
            echo ""
            echo "---"
            echo "date: $TIMESTAMP"
            echo "from: $AGENT"
            echo "priority: $PRIORITY"
            echo "---"
            echo "$MESSAGE"
        } >> "$BRAIN_DIR/$TARGET"
        echo "✅ $TARGET [${PRIORITY}]"
        ;;
    scratch/*)
        echo "$MESSAGE" >> "$BRAIN_DIR/../$TARGET"
        echo "✅ $TARGET (ephemeral, not in git)"
        ;;
    *)
        echo "ERROR: Unknown target '$TARGET'. Valid: events.log, tasks/*, state/*, inbox/*, scratch/*"
        flock -u 200
        exit 1
        ;;
esac

flock -u 200
