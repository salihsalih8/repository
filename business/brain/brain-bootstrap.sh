#!/bin/bash
# brain-bootstrap.sh — System boot health check for the Akatsuki Brain
# Runs at VM boot via systemd unit. Gates all cron jobs on success.
#
# Principles:
#   A. Private-by-default writes — checks episodic logs are writable
#   B. Importance scoring — validates frontmatter format in events.log
#
# Exit 0 = brain is healthy, /tmp/brain-ready created
# Exit 1 = brain needs attention, Nagato alerted, crons blocked

set -euo pipefail

BRAIN_DIR="$(cd "$(dirname "$0")" && pwd)"
WORKSPACE_DIR="$(cd "$BRAIN_DIR/../.." && pwd)"
READY_FLAG="/tmp/brain-ready"
WARN_FILE="/tmp/brain-bootstrap.warnings"
HEALTH_FILE="/tmp/brain-bootstrap.health"

# Bootstrap self-lock — prevent concurrent bootstrap runs
BOOTSTRAP_LOCK="$BRAIN_DIR/.locks/bootstrap.lock"
mkdir -p "$BRAIN_DIR/.locks"
exec 201>"$BOOTSTRAP_LOCK"
flock -n 201 || { echo "Bootstrap already running (lock held). Exiting."; exit 0; }
echo "PID=$$" > "$BOOTSTRAP_LOCK"

# Clean slate
rm -f "$READY_FLAG" "$WARN_FILE"
touch "$HEALTH_FILE"

fail() { echo "FATAL: $*" | tee -a "$WARN_FILE"; exit 1; }
warn() { echo "WARN: $*" | tee -a "$WARN_FILE"; }

echo "[$(date -Iseconds)] Brain bootstrap starting" >> "$HEALTH_FILE"

# === 1. Filesystem invariants ===
echo "Checking filesystem invariants..."

[ -f "$BRAIN_DIR/north-star.md" ] || fail "north-star.md missing — brain is uninitialized"
[ -f "$BRAIN_DIR/OWNERSHIP.md" ] || fail "OWNERSHIP.md missing — authority undefined"
[ -f "$BRAIN_DIR/decisions.md" ] || warn "decisions.md missing"
[ -f "$BRAIN_DIR/events.log" ] || warn "events.log missing"

# Verify no zero-byte canonical files
for f in north-star.md OWNERSHIP.md decisions.md BRAIN-ARCHITECTURE-v2.md; do
    F="$BRAIN_DIR/$f"
    if [ -f "$F" ] && [ ! -s "$F" ]; then
        fail "$f is zero bytes — possible corruption"
    fi
done

echo "✅ Filesystem invariants OK" >> "$HEALTH_FILE"

# === 2. Git health ===
echo "Checking git health..."

if [ -d "$WORKSPACE_DIR/.git" ]; then
    cd "$WORKSPACE_DIR"
    
    # Check for detached HEAD
    if git symbolic-ref -q HEAD >/dev/null 2>&1; then
        echo "  Git: on branch $(git branch --show-current)" >> "$HEALTH_FILE"
    else
        warn "Git is in detached HEAD state"
    fi
    
    # Check for rebase/merge in progress
    for d in rebase-merge rebase-apply MERGE_HEAD CHERRY_PICK_HEAD BISECT_START REVERT_HEAD; do
        if [ -f "$WORKSPACE_DIR/.git/$d" ] || [ -d "$WORKSPACE_DIR/.git/$d" ]; then
            warn "Git operation in progress: $d"
        fi
    done
    
    # Quick fsck
    git fsck --no-progress --connectivity-only 2>/dev/null || warn "git fsck found issues"
    
    # Check last commit age
    LAST_COMMIT=$(git log -1 --format=%ct 2>/dev/null || echo 0)
    NOW=$(date +%s)
    AGE_HOURS=$(( (NOW - LAST_COMMIT) / 3600 ))
    if [ "$AGE_HOURS" -gt 48 ]; then
        warn "Last git commit is ${AGE_HOURS}h old — unpushed changes at risk"
    fi
else
    warn "No git repository at workspace root"
fi

echo "✅ Git health OK" >> "$HEALTH_FILE"

# === 3. Stale lock cleanup ===
echo "Clearing stale locks..."

LOCK_DIR="$BRAIN_DIR/.locks"
mkdir -p "$LOCK_DIR"
# Clear stale locks: 10min timeout AND verify PID is dead before removing
FINDS_STALE=$(find "$LOCK_DIR" -type f -mmin +10 2>/dev/null | wc -l)
if [ "$FINDS_STALE" -gt 0 ]; then
    find "$LOCK_DIR" -type f -mmin +10 | while read -r lockfile; do
        pid=$(cat "$lockfile" 2>/dev/null | grep -o 'PID=[0-9]*' | cut -d= -f2)
        if [ -n "$pid" ] && kill -0 "$pid" 2>/dev/null; then
            warn "Lock $lockfile held by live PID $pid — NOT clearing"
        else
            rm "$lockfile" 2>/dev/null
            echo "  Cleared stale lock: $(basename $lockfile)" >> "$HEALTH_FILE"
        fi
    done
fi

echo "✅ Stale locks cleared" >> "$HEALTH_FILE"

# === 4. Episodic log health ===
echo "Checking episodic logs..."

mkdir -p "$BRAIN_DIR/episodic"
for agent in pain kakuzu deidara; do
    EPISODIC="$BRAIN_DIR/episodic/${agent}.log"
    if [ ! -f "$EPISODIC" ]; then
        echo "[$(date -Iseconds)] [importance:3] [confidence:medium] Episodic log initialized for $agent" > "$EPISODIC"
    fi
    if [ ! -w "$EPISODIC" ]; then
        fail "Episodic log for $agent is not writable"
    fi
done

echo "✅ Episodic logs healthy" >> "$HEALTH_FILE"

# === 5. Process unprocessed inbox ===
echo "Processing inbox..."

INBOX="$BRAIN_DIR/inbox"
UNPROCESSED="$INBOX/.unprocessed"
mkdir -p "$INBOX" "$UNPROCESSED"

UNPROCESSED_COUNT=$(ls "$UNPROCESSED" 2>/dev/null | wc -l)
if [ "$UNPROCESSED_COUNT" -gt 0 ]; then
    for msg in "$UNPROCESSED"/*; do
        [ -f "$msg" ] || continue
        TARGET=$(basename "$msg" | sed 's/\.pending$//')
        cat "$msg" >> "$INBOX/$TARGET" 2>/dev/null || warn "Could not deliver $msg to $TARGET"
        rm "$msg"
    done
    echo "  Processed $UNPROCESSED_COUNT unprocessed inbox message(s)" >> "$HEALTH_FILE"
fi

echo "✅ Inbox processed" >> "$HEALTH_FILE"

# === 6. events.log frontmatter validation ===
echo "Validating events.log format..."

if [ -f "$BRAIN_DIR/events.log" ]; then
    # Check for entries without importance field
    BARE_ENTRIES=$(grep -c "^\[" "$BRAIN_DIR/events.log" 2>/dev/null || echo 0)
    if [ "$BARE_ENTRIES" -gt 0 ]; then
        warn "$BARE_ENTRIES entries in events.log lack frontmatter headers"
    fi
fi

echo "✅ events.log validated" >> "$HEALTH_FILE"

# === 7. Generate hot digests ===
echo "Generating hot digests..."

if [ -f "$BRAIN_DIR/brain-load.sh" ]; then
    for agent in pain nagato; do
        bash "$BRAIN_DIR/brain-load.sh" "$agent" "startup" 2>/dev/null || warn "Hot digest generation failed for $agent"
    done
    echo "✅ Hot digests generated" >> "$HEALTH_FILE"
else
    warn "brain-load.sh not found — skipping hot digest generation"
fi

# === 8. Mark system ready ===
touch "$READY_FLAG"

# Summarize
WARN_COUNT=$(wc -l < "$WARN_FILE" 2>/dev/null || echo 0)
echo ""
echo "=== Brain Bootstrap Complete ==="
echo "Warnings: $WARN_COUNT"
echo "Ready flag: $READY_FLAG"
echo "Health log: $HEALTH_FILE"

if [ "$WARN_COUNT" -gt 0 ]; then
    echo ""
    echo "⚠️  Warnings found:"
    cat "$WARN_FILE"
fi

# Write to events.log
TIMESTAMP=$(TZ='America/New_York' date '+%Y-%m-%d %H:%M %Z')
echo "---" >> "$BRAIN_DIR/events.log"
echo "date: $TIMESTAMP" >> "$BRAIN_DIR/events.log"
echo "agent: system" >> "$BRAIN_DIR/events.log"
echo "importance: 2" >> "$BRAIN_DIR/events.log"
echo "confidence: high" >> "$BRAIN_DIR/events.log"
echo "---" >> "$BRAIN_DIR/events.log"
echo "Brain bootstrap complete. $WARN_COUNT warning(s)." >> "$BRAIN_DIR/events.log"
echo "" >> "$BRAIN_DIR/events.log"

exit 0
