#!/bin/bash
# brain-recover.sh — One-command disaster recovery for the Akatsuki Brain
# Usage: brain-recover.sh <git-sha>
#   Restores the brain to a specific git commit, then bootstraps.
#
# Must run monthly as a test. If it doesn't work, persistence is theater.

set -euo pipefail

BRAIN_DIR="$(cd "$(dirname "$0")" && pwd)"
WORKSPACE_DIR="$(cd "$BRAIN_DIR/../.." && pwd)"
TARGET_SHA="$1"

if [ -z "$TARGET_SHA" ]; then
    echo "Usage: brain-recover.sh <git-sha>"
    echo "  Restores the brain to a specific git commit and bootstraps."
    echo ""
    echo "To find recent commits touching the brain:"
    echo "  cd $WORKSPACE_DIR && git log --oneline -- business/brain/"
    echo ""
    echo "Available recent commits:"
    cd "$WORKSPACE_DIR" && git log --oneline --max-count=10 -- business/brain/ 2>/dev/null || echo "  (no git history)"
    exit 1
fi

echo "=== Akatsuki Brain Disaster Recovery ==="
echo "Target: git $TARGET_SHA"
echo "Brain: $BRAIN_DIR"
echo "$(date)"

# === 1. Safety check ===
if [ ! -d "$WORKSPACE_DIR/.git" ]; then
    echo "ERROR: No git repository at workspace root. Recovery requires git."
    exit 1
fi

# === 2. Verify target SHA exists ===
cd "$WORKSPACE_DIR"
if ! git cat-file -e "$TARGET_SHA" 2>/dev/null; then
    echo "ERROR: SHA $TARGET_SHA not found in local git history."
    echo "Try: git fetch origin && git log --oneline origin/main"
    exit 1
fi

# === 3. Create backup of current brain ===
BACKUP_DIR="/tmp/brain-backup-$(date +%s)"
mkdir -p "$BACKUP_DIR"
echo "Backing up current brain to $BACKUP_DIR..."
cp -r "$BRAIN_DIR"/* "$BACKUP_DIR/" 2>/dev/null || true
echo "Backup created at $BACKUP_DIR"

# === 4. Restore from git ===
echo ""
echo "Restoring brain files from $TARGET_SHA..."
cd "$WORKSPACE_DIR"

# Restore only the brain directory
git checkout "$TARGET_SHA" -- business/brain/
echo "Restored business/brain/ to $TARGET_SHA"

# === 5. Recover episodic logs (not in git) ===
echo ""
echo "Recovering episodic logs from backup..."
mkdir -p "$BRAIN_DIR/episodic"
if [ -d "$BACKUP_DIR/episodic" ]; then
    cp "$BACKUP_DIR/episodic"/*.log "$BRAIN_DIR/episodic/" 2>/dev/null || true
    EPISODIC_COUNT=$(ls "$BRAIN_DIR/episodic"/*.log 2>/dev/null | wc -l)
    echo "Recovered $EPISODIC_COUNT episodic log(s)"
else
    echo "No episodic logs to recover"
fi

# === 6. Recover events.log (not in git) ===
echo ""
echo "Recovering events.log from backup..."
if [ -f "$BACKUP_DIR/events.log" ]; then
    BACKUP_EVENTS=$(wc -l < "$BACKUP_DIR/events.log")
    GIT_EVENTS=$(wc -l < "$BRAIN_DIR/events.log" 2>/dev/null || echo 0)
    # Prepend backup events (more recent) to git events (older)
    cat "$BACKUP_DIR/events.log" "$BRAIN_DIR/events.log" > "$BRAIN_DIR/events.log.recovered" 2>/dev/null
    mv "$BRAIN_DIR/events.log.recovered" "$BRAIN_DIR/events.log"
    echo "Merged $GIT_EVENTS git lines + $BACKUP_EVENTS backup lines"
else
    echo "No events.log in backup — using git version only"
fi

# === 7. Recover state files (not in git) ===
echo ""
echo "Recovering state files from backup..."
if [ -d "$BACKUP_DIR/state" ]; then
    mkdir -p "$BRAIN_DIR/state"
    cp "$BACKUP_DIR/state"/*.md "$BRAIN_DIR/state/" 2>/dev/null || true
    STATE_COUNT=$(ls "$BRAIN_DIR/state"/*.md 2>/dev/null | wc -l)
    echo "Recovered $STATE_COUNT state file(s)"
else
    echo "No state files to recover"
fi

# === 8. Recover hot files (not in git) ===
echo ""
echo "Recovering hot files from backup..."
if [ -d "$BACKUP_DIR/hot" ]; then
    mkdir -p "$BRAIN_DIR/hot"
    cp "$BACKUP_DIR/hot"/*.md "$BRAIN_DIR/hot/" 2>/dev/null || true
    echo "Recovered hot files"
else
    echo "No hot files — will regenerate via brain-load.sh"
fi

# === 9. Recover inbox files (not in git) ===
echo ""
echo "Recovering inbox from backup..."
if [ -d "$BACKUP_DIR/inbox" ]; then
    mkdir -p "$BRAIN_DIR/inbox/.unprocessed"
    cp "$BACKUP_DIR/inbox"/*.md "$BRAIN_DIR/inbox/" 2>/dev/null || true
    echo "Recovered inbox files"
else
    echo "No inbox files to recover"
fi

# === 10. Bootstrap ===
echo ""
echo "=== Running brain-bootstrap.sh ==="
if [ -f "$BRAIN_DIR/brain-bootstrap.sh" ]; then
    bash "$BRAIN_DIR/brain-bootstrap.sh"
    BOOTSTRAP_RESULT=$?
else
    echo "WARNING: brain-bootstrap.sh not found — manual boot required"
    BOOTSTRAP_RESULT=1
fi

# === 11. Report ===
echo ""
echo "=== Recovery Complete ==="
echo "Backup: $BACKUP_DIR"
echo "Brain: $BRAIN_DIR"
echo "Target: $TARGET_SHA"
echo "Bootstrap: $([ $BOOTSTRAP_RESULT -eq 0 ] && echo 'PASSED' || echo 'FAILED')"

# Log recovery event
TIMESTAMP=$(TZ='America/New_York' date '+%Y-%m-%d %H:%M %Z')
echo "---" >> "$BRAIN_DIR/events.log"
echo "date: $TIMESTAMP" >> "$BRAIN_DIR/events.log"
echo "agent: system" >> "$BRAIN_DIR/events.log"
echo "importance: 4" >> "$BRAIN_DIR/events.log"
echo "confidence: high" >> "$BRAIN_DIR/events.log"
echo "---" >> "$BRAIN_DIR/events.log"
echo "Brain recovered from git SHA $TARGET_SHA. Bootstrap: $([ $BOOTSTRAP_RESULT -eq 0 ] && echo 'PASSED' || echo 'FAILED'). Backup at $BACKUP_DIR." >> "$BRAIN_DIR/events.log"
echo "" >> "$BRAIN_DIR/events.log"

echo ""
echo "Next: run 'brain-eval.sh' to verify recall quality after recovery."
