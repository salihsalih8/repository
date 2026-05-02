# Akatsuki System — Complete Replication Guide
**Version:** 1.0
**Date:** May 1, 2026
**Purpose:** Self-contained build guide. Feed this to your Claw bot to replicate the Akatsuki multi-agent system with your own domain, agents, and goals.

---

## What This Is

A multi-agent operating system built on OpenClaw. Multiple AI agents — each with their own role, files, Telegram bot, and security boundaries — collaborate through a shared brain. Agents are private-by-default (nothing shared until explicitly published), importance-scored, quarantine-gated, and audited.

**Core principles:**
- Single-writer-per-file — no agent can corrupt another's domain
- Private-by-default — all output starts in private episodic logs, published only when verified
- Importance scoring — every shared write carries a 1-5 score determining visibility and lifespan
- Warming mode — every new agent proves competence across 30 days and 3 dry runs before going autonomous
- Adversarial auditing — a dedicated security agent red-teams other agents' output

**What you'll build:**
- A brain directory (shared file system with ownership enforcement)
- 3-5 agents (operations, finance, builder, audit, brand)
- Cron automation layer (health checks, backups, scheduled audits)
- Telegram bots for every agent

---

## Prerequisites

Before your Claw bot starts building, you need to decide:

### 1. Your Organization Name
We use "Akatsuki" (Naruto-themed). Pick your own theme. This affects agent naming, file paths, and identity docs.

### 2. Your Name/Role
We use "Nagato" (leader). Agents refer to you by this name. Pick yours.

### 3. Your Agents
Define 3-5 agents. Each needs:
- **Name** — from your chosen theme
- **One-sentence purpose** — what problem does this agent solve?
- **Domain** — what files does it own? What does it read?
- **Channel** — Telegram bot name (every agent gets one)
- **Model** — default model for execution, model for deep thinking

**Our roster as a template:**

| Agent | Role | Domain |
|-------|------|--------|
| Pain | Operations chief | Task orchestration, inventory, pipeline, agent handler |
| Kakuzu | Financial heart | Runway, COGS, PPC, guardrails |
| Sasori | Tool & app builder | Code, deploy, maintain tools |
| Itachi | Audit & security sentinel | Hallucination detection, consistency, drift, adversarial testing |
| Deidara | Brand builder (planned) | Content, social, viral growth |

### 4. Your Domain Context
What business/problem are the agents operating in? This goes into `north-star.md` — the immutable constraints document only you can edit.

---

## Phase 1 — The Brain

The brain is a shared directory. Every agent reads from and writes to it. Ownership is enforced per-file.

### Step 1.1: Create the Brain Directory

```bash
mkdir -p ~/workspace/business/brain/{agents,state,tasks,inbox,episodic,hot,archive,graph,.eval-results}
```

### Step 1.2: Create north-star.md

This is YOUR document. Agents read it, never write it. It defines constraints, priorities, hard stops, and resolved decisions.

```markdown
# north-star.md
owner: human (read-only for all agents)
last-updated: YYYY-MM-DD

---

## Why — the motivation
(One paragraph on why this exists. Your mission.)

## What we're building
(One paragraph on the business/project.)

## Current phase
(What stage are you in? Pre-launch? Scaling? Maintenance?)

## Active constraints
- Capital: $X
- Time: (your availability)
- Other constraints: (legal, technical, personal)

## What agents should optimize for

Priorities are numbered. Lower number wins.

1. **Priority 1** — description
   - *30 days:* goal
   - *60 days:* goal
   - *90 days:* goal

2. **Priority 2** — description
   ...

## Hard stops

Agents must NEVER do the following without explicit approval:
- Spend money
- Contact customers, vendors, or partners
- Modify or delete north-star.md
- Delete any file or data without heads-up
- Sign up for services
- Post or publish anything
- Make promises or commitments
- Bypass the agent approval chain

## Resolved decisions (don't relitigate)
- Decision 1
- Decision 2
```

### Step 1.3: Create OWNERSHIP.md

This is the authority matrix. Every file has exactly one writer. This prevents agents from corrupting each other's data.

```markdown
# OWNERSHIP.md — Brain File Authority Matrix
**Date:** YYYY-MM-DD
**Principle:** Single-writer-per-file. Private-by-default writes. Importance-scored claims.

---

## Core Principles

### A. Private-by-Default Writes

Every agent writes to its own episodic log by default. Nothing is shared until explicitly published.

Publish path:
1. Agent writes to episodic/<agent>.log (private, append-only)
2. Agent explicitly publishes to shared surface (events.log or state/*.md)
3. Published entries tagged: (agent, timestamp, importance, confidence)
4. Quarantine computed at read time from published_at + wall clock
   - confidence=high: skips quarantine
   - confidence=medium: 1h hold before others act on it
   - confidence=low: expires from quarantine unless re-submitted

### B. Importance Scoring

Every shared write carries importance (1-5):

| Score | Meaning | Lifespan |
|-------|---------|----------|
| 1 | Ephemeral | Session-only |
| 2 | Context | 90 days |
| 3 | Operational | 12 months |
| 4 | Strategic | Permanent |
| 5 | Critical | Permanent + alert |

---

## File Authority Matrix

### NARRATIVE FILES

| File | Owner (writer) | Readers | Rules |
|------|---------------|---------|-------|
| north-star.md | Human only | All (read-only) | Never modified by agents |
| decisions.md | Human | All (append-only) | Open/Resolved format |
| OWNERSHIP.md | Operations agent | All (read-only) | Updated only with human approval |

### OPERATIONAL FILES

| File | Owner | Readers | Rules |
|------|-------|---------|-------|
| events.log | All (after publish) | All | Published entries only |
| tasks/<agent>.md | Respective agent | Human, Operations | Sprint tracking |

### STATE FILES (customize per agent)

| File | Owner | Readers | Rules |
|------|-------|---------|-------|
| state/<file>.md | <agent> | As needed | Fresh as of last boot |

### AGENT FILES

| File | Owner | Readers | Rules |
|------|-------|---------|-------|
| agents/<agent>-foundation.md | Agent (Ops-maintained) | All | Role, directives, hard stops |
| episodic/<agent>.log | Agent (only) | Agent (only) | Private log |

### INBOX FILES

| File | Writer | Reader | Rules |
|------|--------|--------|-------|
| inbox/<agent>.md | Any agent | Respective agent | Requests and escalations |

---
*This file is append-only. Updates require human review.*
```

### Step 1.4: Create brain-write.sh

The write enforcement script. Every agent writes through this. It enforces ownership.

```bash
#!/bin/bash
# brain-write.sh — Shared write wrapper with ownership enforcement
# Usage: brain-write.sh <target-file> --importance 1-5 --confidence low|medium|high --source <episodic-log> [--message "text"]

set -euo pipefail

BRAIN_DIR="$(cd "$(dirname "$0")" && pwd)"
TARGET="$1"
shift

# Parse arguments
IMPORTANCE=""
CONFIDENCE=""
SOURCE=""
MESSAGE=""

while [[ $# -gt 0 ]]; do
    case "$1" in
        --importance) IMPORTANCE="$2"; shift 2 ;;
        --confidence) CONFIDENCE="$2"; shift 2 ;;
        --source) SOURCE="$2"; shift 2 ;;
        --message) MESSAGE="$2"; shift 2 ;;
        *) shift ;;
    esac
done

# Validate
[ -z "$IMPORTANCE" ] && { echo "ERROR: --importance required"; exit 1; }
[ -z "$CONFIDENCE" ] && { echo "ERROR: --confidence required"; exit 1; }
[ -z "$SOURCE" ] && { echo "ERROR: --source required"; exit 1; }

# Ownership check
CALLER="${AGENT_ID:-unknown}"
TARGET_REL="${TARGET#$BRAIN_DIR/}"

owner_check() {
    # Define ownership map
    case "$TARGET_REL" in
        state/runway.md|state/cogs.md|state/ppc.md)
            [ "$CALLER" != "kakuzu" ] && { echo "ERROR: $TARGET_REL is owned by kakuzu (caller is $CALLER)"; exit 1; } ;;
        state/tools.md|state/builds.md)
            [ "$CALLER" != "sasori" ] && { echo "ERROR: $TARGET_REL is owned by sasori (caller is $CALLER)"; exit 1; } ;;
        state/audit.md|state/security.md|state/agent-health.md)
            [ "$CALLER" != "itachi" ] && { echo "ERROR: $TARGET_REL is owned by itachi (caller is $CALLER)"; exit 1; } ;;
        state/inventory.md|state/pipeline.md)
            [ "$CALLER" != "pain" ] && { echo "ERROR: $TARGET_REL is owned by pain (caller is $CALLER)"; exit 1; } ;;
        tasks/*)
            TASK_AGENT="${TARGET_REL#tasks/}"
            TASK_AGENT="${TASK_AGENT%.md}"
            [ "$CALLER" != "$TASK_AGENT" ] && [ "$CALLER" != "pain" ] && { echo "ERROR: $TARGET_REL is owned by $TASK_AGENT (caller is $CALLER)"; exit 1; } ;;
    esac
}
owner_check

# Write with frontmatter, flock, atomic rename
TMP="${TARGET}.tmp.$$"
{
    echo "---"
    echo "agent: $CALLER"
    echo "importance: $IMPORTANCE"
    echo "confidence: $CONFIDENCE"
    echo "published_at: $(date -Iseconds)"
    [ "$CONFIDENCE" = "medium" ] && echo "quarantine_until: $(date -Iseconds -d '+1 hour')"
    echo "source: $SOURCE"
    echo "---"
    echo ""
    [ -n "$MESSAGE" ] && echo "$MESSAGE"
    echo ""
} > "$TMP"

# Atomic rename with flock
(
    flock -x 200
    cat "$TMP" >> "$TARGET"
    rm "$TMP"
) 200>"${TARGET}.lock"

echo "✅ Written to $TARGET_REL (importance=$IMPORTANCE, confidence=$CONFIDENCE)"
```

### Step 1.5: Create brain-load.sh

The boot loader. Every agent runs this on startup to get context.

```bash
#!/bin/bash
# brain-load.sh — Agent brain loader with output gating and passive recall
# Usage: brain-load.sh <agent-name> [context-type]

set -euo pipefail

BRAIN_DIR="$(cd "$(dirname "$0")" && pwd)"
AGENT="$1"
CONTEXT="${2:-startup}"

HOT_DIR="$BRAIN_DIR/hot"
mkdir -p "$HOT_DIR"
OUTPUT="$HOT_DIR/${AGENT}.md"

# Generate hot digest (identity + north-star + passive recall + context)
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
    echo "## Identity"
    if [ -f "$BRAIN_DIR/agents/${AGENT}-foundation.md" ]; then
        head -20 "$BRAIN_DIR/agents/${AGENT}-foundation.md"
    fi
    echo ""
    
    # 2. North Star
    echo "## North Star"
    if [ -f "$BRAIN_DIR/north-star.md" ]; then
        grep -A10 "optimize for" "$BRAIN_DIR/north-star.md" | head -15
        echo ""
        grep "^- \*\*" "$BRAIN_DIR/north-star.md" | head -8
    fi
    echo ""
    
    # 3. P0 Events (24h)
    echo "## P0 Events (24h)"
    grep -c "importance: 5" "$BRAIN_DIR/events.log" 2>/dev/null || echo "(none)"
    echo ""
    
    # 4. Active tasks
    echo "## My Active Tasks"
    if [ -f "$BRAIN_DIR/tasks/${AGENT}.md" ]; then
        grep "^- \[ \]" "$BRAIN_DIR/tasks/${AGENT}.md" 2>/dev/null | head -8 || echo "(none)"
    fi
    echo ""
    
    # 5. Inbox
    echo "## Unread Inbox"
    if [ -f "$BRAIN_DIR/inbox/${AGENT}.md" ] && [ -s "$BRAIN_DIR/inbox/${AGENT}.md" ]; then
        tail -5 "$BRAIN_DIR/inbox/${AGENT}.md"
    else
        echo "(empty)"
    fi
    echo ""
    
    # 6. Context-specific bundle
    echo "## Context Bundle — $CONTEXT"
    case "$CONTEXT" in
        financial)
            head -20 "$BRAIN_DIR/state/runway.md" 2>/dev/null || echo "(no runway data)"
            head -20 "$BRAIN_DIR/state/cogs.md" 2>/dev/null || echo "(no COGS data)"
            ;;
        build)
            head -20 "$BRAIN_DIR/state/tools.md" 2>/dev/null || echo "(no tools)"
            head -20 "$BRAIN_DIR/state/builds.md" 2>/dev/null || echo "(no builds)"
            ;;
        audit)
            head -20 "$BRAIN_DIR/state/audit.md" 2>/dev/null || echo "(no audits)"
            head -20 "$BRAIN_DIR/state/agent-health.md" 2>/dev/null || echo "(no health data)"
            ;;
    esac
    
} > "$OUTPUT"

# Enforce token budget (~800 tokens)
WORDS=$(wc -w < "$OUTPUT")
EST_TOKENS=$(( WORDS * 4 / 3 ))
if [ "$EST_TOKENS" -gt 800 ]; then
    head -c 3200 "$OUTPUT" > "$OUTPUT.tmp" && mv "$OUTPUT.tmp" "$OUTPUT"
fi

echo "✅ Hot digest: $OUTPUT (~${EST_TOKENS} tokens)"
```

### Step 1.6: Create brain-recall.py (Quarantine Filter)

```python
#!/usr/bin/env python3
"""brain-recall.py — Filter events.log for quarantine-expired entries."""
import sys
from datetime import datetime, timezone, timedelta

def parse_frontmatter(entry):
    """Extract importance, confidence, quarantine_until from entry frontmatter."""
    importance = 3
    confidence = "medium"
    quarantine_until = None
    
    for line in entry.split('\n'):
        if line.startswith('importance:'):
            try: importance = int(line.split(':')[1].strip())
            except: pass
        elif line.startswith('confidence:'):
            confidence = line.split(':')[1].strip()
        elif line.startswith('quarantine_until:'):
            try:
                ts = line.split(':', 1)[1].strip()
                quarantine_until = datetime.fromisoformat(ts)
            except: pass
    
    return importance, confidence, quarantine_until

def is_actionable(importance, confidence, quarantine_until):
    """Check if entry is actionable now."""
    if confidence == "high":
        return True
    if confidence == "low":
        return False
    if quarantine_until:
        return datetime.now(timezone.utc) >= quarantine_until
    return True  # No quarantine set = actionable

def main():
    if len(sys.argv) < 2:
        print("Usage: brain-recall.py <events.log> [--all]")
        sys.exit(1)
    
    show_all = "--all" in sys.argv
    
    with open(sys.argv[1], 'r') as f:
        content = f.read()
    
    entries = content.split('---\n')
    for entry in entries:
        if not entry.strip():
            continue
        importance, confidence, q_until = parse_frontmatter(entry)
        if show_all or is_actionable(importance, confidence, q_until):
            # Print first non-empty line as summary
            for line in entry.split('\n'):
                stripped = line.strip()
                if stripped and not stripped.startswith('agent:') and not stripped.startswith('importance:') and not stripped.startswith('confidence:') and not stripped.startswith('quarantine_') and not stripped.startswith('source:') and not stripped.startswith('published_'):
                    print(f"- [I{importance}|{confidence[:3]}] {stripped[:120]}")
                    break

if __name__ == "__main__":
    main()
```

### Step 1.7: Create foundational files

```bash
# Make scripts executable
chmod +x brain-write.sh brain-load.sh brain-recall.py

# Create events.log
touch events.log

# Create decisions.md
cat > decisions.md << 'EOF'
# decisions.md
owner: human (append-only for agents)
last-updated: YYYY-MM-DD

## Open Decisions
(none yet)

## Resolved Decisions
(none yet)

---
Format: [OPEN] or [RESOLVED] | Date | Decision | Decided by
EOF
```

---

## Phase 2 — Agent Foundation Docs

Every agent gets a foundation document. This is the single most important file — it defines the agent's entire operating model. **Do not ship a skeleton.** Build it at full depth from day one.

### Required Sections (15 minimum)

| # | Section | What It Contains |
|---|---------|-----------------|
| 1 | Header block | Status, model, channel, access, runtime |
| 2 | Role | What they do, where they fit, what they're NOT |
| 3 | Communication | Intake channels, relay patterns, response format |
| 4 | Owns (sole writer) | Every file they're responsible for |
| 5 | Reads | Files they consume but don't modify |
| 6 | Write Protocol | Private-by-default, publish gate, quarantine |
| 7 | Importance Scoring | 1-5 table with domain-specific examples |
| 8 | Importance=5 Rules | What triggers critical, escalation procedure |
| 9 | Hard Stops | 10+ absolute prohibitions (5 categories: financial, deployment, security, architecture, quality) |
| 10 | Directives | Daily, per-request, weekly, sprint cadence |
| 11 | Warming-Up Mode | Duration, restrictions, dry-run protocol |
| 12 | Startup Sequence | Exact boot procedure |
| 13 | Authority Matrix | File-level permissions table |
| 14 | Data Labeling | Domain-specific labels for their output |
| 15 | Relationship to Other Agents | Communication paths, dependencies |

### Template Structure

Copy this structure for every agent foundation doc. Fill in domain-specific details. The Kakuzu (financial) doc is the gold standard — it defines guardrails, show-your-math requirements, warming mode, and data labeling with concrete examples. Match that depth.

---

## Phase 3 — Agent Workspace

Every agent needs a workspace directory with identity files.

### Step 3.1: Create Workspace

```bash
mkdir -p ~/workspace-<agent-id>
ln -s ~/workspace/business ~/workspace-<agent-id>/business
```

### Step 3.2: Create AGENTS.md

```markdown
# AGENTS.md - <Agent Name>'s Workspace

## Role
You are <Agent Name>. <One sentence purpose>.

## Communication
- Direct: Telegram DM (@<agent>_bot)
- Relay: Pain via inbox/<agent>.md or sessions_spawn
- Output: events.log with importance scoring

## Brain Access
Your workspace has a business/ symlink to the shared brain.
- Read: north-star.md, decisions.md, tasks/pain.md
- Write: episodic/<agent>.log (all output starts here)
- Publish: brain-write.sh events.log --importance N --confidence X

## Startup
On every boot: brain-load.sh <agent> <context>

## Hard Stops
- Never spend money without approval
- Never deploy without approval
- Never expose credentials
- Never modify another agent's files
- (Add domain-specific hard stops)

## Red Lines
- Don't exfiltrate private data
- Don't run destructive commands without asking
- When in doubt, ask
```

### Step 3.3: Create SOUL.md

```markdown
# SOUL.md - Who You Are

_You're not a chatbot. You're <Agent Name>._

## Core Truths
**You are a <role>.** <One sentence identity>.
**Be direct and <tone>.** <Personality>.
**<Domain principle>.** <How you approach your work>.
**You serve <leader>.** Respect their time, money, vision.

## Hard Stops
- (Key hard stops from foundation doc)

## Vibe
<Personality>. <Two adjectives>. <How you carry yourself>.
```

### Step 3.4: Create IDENTITY.md

```markdown
# IDENTITY.md - Who Am I?
- **Name:** <Agent Name>
- **Creature:** <Role description>
- **Vibe:** <Two adjectives>
- **Emoji:** <Single emoji>
- **Avatar:** —

_Established <date> — <Leader's> <role>._
```

### Step 3.5: Create USER.md

Copy this from the operations agent's workspace. All agents share the same USER.md (it describes the human they serve).

---

## Phase 4 — OpenClaw Configuration

### Step 4.1: Agent Config (openclaw.json)

Add each agent to `agents.list`:

```json
{
  "id": "<agent-id>",
  "name": "<Agent Name>",
  "workspace": "/home/<user>/workspace-<agent-id>",
  "agentDir": "/home/<user>/.openclaw/agents/<agent-id>/agent"
}
```

### Step 4.2: Telegram Bot Setup

For each agent:
1. Create bot via @BotFather on Telegram
2. Set environment variable: `export <AGENT>_BOT_TOKEN="<token>"`
3. Add to openclaw.json channels section:

```json
"channels": {
  "telegram": {
    "accounts": {
      "<agent-id>": {
        "botToken": "${<AGENT>_BOT_TOKEN}",
        "dmPolicy": "allowlist",
        "allowFrom": ["<your-telegram-id>"]
      }
    }
  }
}
```

4. Add channel routing to agent config:

```json
{
  "agentId": "<agent-id>",
  "match": {
    "channel": "telegram",
    "accountId": "<agent-id>"
  }
}
```

### Step 4.3: Restart Gateway

```bash
openclaw gateway restart
```

---

## Phase 5 — Brain Wiring Per Agent

For each agent you create, wire them into the brain:

### Checklist Per Agent

```bash
# Create files
touch episodic/<agent>.log
echo "[$(date)] [importance:3] [confidence:high] <Agent> deployed. Awaiting first boot." >> episodic/<agent>.log
touch state/<agent-state-file-1>.md
touch state/<agent-state-file-2>.md
touch tasks/<agent>.md
touch inbox/<agent>.md

# Update OWNERSHIP.md — add entries in ALL tables:
# - OPERATIONAL FILES: tasks/<agent>.md
# - STATE FILES: state/<agent-files>.md
# - AGENT FILES: agents/<agent>-foundation.md, episodic/<agent>.log
# - INBOX FILES: inbox/<agent>.md

# Add context to brain-load.sh
# Add case block for agent's domain context
```

---

## Phase 6 — Cron Automation Layer

### Health Check (Every 6 Hours)

```json
{
  "name": "brain-health-check",
  "schedule": { "kind": "cron", "expr": "0 */6 * * *" },
  "sessionTarget": "isolated",
  "payload": {
    "kind": "agentTurn",
    "message": "Run brain-test.sh. If exit code != 0, alert operations agent with failure summary. If exit code == 0, reply NO_REPLY.",
    "timeoutSeconds": 120,
    "model": "deepseek-v4-flash"
  }
}
```

### Daily Consistency Audit (Post-Warming)

```json
{
  "name": "audit-daily-consistency",
  "schedule": { "kind": "cron", "expr": "0 3 * * *" },
  "sessionTarget": "isolated",
  "payload": {
    "kind": "agentTurn",
    "message": "Run consistency audit on last 24h of events.log. Cross-reference claims against state files. Flag discrepancies.",
    "model": "deepseek-v4-pro",
    "thinking": "high"
  }
}
```

### Weekly Security Audit (Post-Warming)

```json
{
  "name": "audit-weekly-security",
  "schedule": { "kind": "cron", "expr": "0 6 * * 1" },
  "sessionTarget": "isolated",
  "payload": {
    "kind": "agentTurn",
    "message": "Weekly security audit: hard-stop scan, credential detection, protocol compliance. Publish report.",
    "model": "deepseek-v4-pro",
    "thinking": "high"
  }
}
```

### Daily Brain Backup

```json
{
  "name": "brain-backup-daily",
  "schedule": { "kind": "cron", "expr": "0 3 * * *" },
  "sessionTarget": "main",
  "payload": {
    "kind": "systemEvent",
    "text": "Git auto-commit brain files. Push if remote configured."
  }
}
```

---

## Phase 7 — Security Architecture

### Layer 1: Prevention

| Mechanism | What It Prevents |
|-----------|-----------------|
| Private-by-default writes | Agents can't publish unverified output |
| Ownership enforcement | Agents can't corrupt other agents' files |
| Importance scoring | Low-value noise doesn't reach the human |
| Confidence labeling | Honest uncertainty — "I'm not sure about this" |
| Quarantine (1h hold) | Medium-confidence entries get a cooling-off period |
| Hard stops (10+ per agent) | Spend, deploy, contact externals — gated |
| Warming mode (30 days) | New agents prove competence before autonomy |
| Dry-run protocol (3 sessions) | Human reviews output before agent goes live |

### Layer 2: Detection

| Mechanism | What It Detects |
|-----------|----------------|
| brain-test.sh (every 6h) | Script integrity, file health, brain structure |
| Consistency audit (daily) | Numbers match across state files |
| Hallucination audit (daily) | Claims reference data that actually exists |
| Protocol compliance (weekly) | Agents follow their foundation docs |
| Security audit (weekly) | Hard-stop violations, credential exposure |
| Drift analysis (weekly) | Agent quality degrading over time |
| Adversarial testing (on-demand) | Red-team probes: fabrication, boundary, authority |
| Agent trust scoring | Per-agent reliability: Accuracy + Completeness + Protocol + Usefulness |

### Layer 3: Response

| Mechanism | What Happens |
|-----------|-------------|
| P0 events bypass quarantine | Critical findings visible immediately |
| Simultaneous Pain + Nagato alert | P0 hits both ops and human at once |
| Audit trail immutability | All findings preserved, never deleted |
| Agent trust score < 60 | Agent output gated until human review |

---

## Phase 8 — Agent Onboarding Procedure

For every new agent, follow this production checklist:

```
=== AGENT PRODUCTION CHECKLIST ===
Agent: ___________
Date started: ___________

PREREQUISITES (Human decides)
[ ] Agent name & role
[ ] Files owned
[ ] Files read
[ ] Channel (Telegram bot name)
[ ] Model (default + deep thinking)
[ ] Access control
[ ] Warming duration (default: 30 days)

PHASE 1 — Foundation Document
[ ] Header block
[ ] Role (what + where + NOT)
[ ] Communication protocol
[ ] Owns table
[ ] Reads table
[ ] Write protocol (private-by-default)
[ ] Importance scoring (domain-specific examples)
[ ] Importance=5 escalation rules
[ ] Hard stops (5 categories, 10+ items)
[ ] Directives (daily, per-request, weekly, sprint)
[ ] Warming-Up Mode
[ ] Startup sequence
[ ] Authority matrix
[ ] Data labeling
[ ] Agent relationships
[ ] "No human needed" test passed

PHASE 2 — Brain Wiring
[ ] episodic/<agent>.log created
[ ] State files created
[ ] tasks/<agent>.md created
[ ] inbox/<agent>.md created
[ ] OWNERSHIP.md updated (5 tables)
[ ] brain-load.sh context added
[ ] brain-test.sh still passing

PHASE 3 — Infrastructure
[ ] Agent config in openclaw.json
[ ] Telegram bot created (@BotFather)
[ ] Bot token env var set
[ ] Channel routing in openclaw.json
[ ] Workspace directory created
[ ] Business symlink created
[ ] AGENTS.md created
[ ] SOUL.md created
[ ] IDENTITY.md created
[ ] Gateway restarted
[ ] Bot responds to DM

PHASE 4 — Warming & Dry-Run
[ ] Dry-run #1: _____ (Review: PASS / FIX)
[ ] Dry-run #2: _____ (Review: PASS / FIX)
[ ] Dry-run #3: _____ (Review: PASS / FIX)
[ ] Foundation doc status updated
[ ] Human signed off

PHASE 5 — Go-Live
[ ] Warming restrictions removed from doc
[ ] Go-live audit passed
[ ] Published to events.log (importance=4)
[ ] Day 1 check: _____
[ ] Day 7 check: _____ (agent trusted)
```

---

## Phase 9 — Communication Architecture

### Agent-to-Human
- Every agent has a Telegram bot
- During warming: agent responds directly but output is logged for ops review
- Post-warming: autonomous direct communication
- P0 events: alert both operations agent AND human simultaneously

### Agent-to-Agent
- Shared state files (read-only across agents)
- events.log for published output (all agents read)
- inbox/<agent>.md for direct requests
- sessions_spawn for operations agent to delegate tasks

### Escalation Flow

```
Agent Finding → Classify
  ├── P3 (minor) → events.log (importance=2) → state file update
  ├── P2 (moderate) → events.log (importance=3) → weekly digest to ops
  ├── P1 (significant) → events.log (importance=4) → immediate ops alert
  └── P0 (critical) → bypass quarantine → events.log (importance=5)
       → ops agent (URGENT) + human (URGENT) simultaneously
```

---

## Key Design Decisions (Don't Relitigate)

These are battle-tested choices from building this system:

1. **Single-writer-per-file** — simpler than row-level locking, sufficient for <10 agents
2. **Markdown state files over SQLite** — human-readable, git-diffable, sufficient for <500 rows. Migrate to SQLite at scale.
3. **Virtual quarantine (read-time filter)** — doesn't mutate events.log. Cleaner than physical quarantine files.
4. **Agent naming from fiction** — gives agents personality. Makes debugging and team discussions more natural.
5. **Warming mode over real-time gate** — lighter weight. Pattern detection over interception.
6. **Telegram bots for all agents** — speed over filter. Warming mode provides the safety net.
7. **Dedicated audit agent (Itachi)** — cron catches mechanical failures, agent catches semantic failures
8. **DeepSeek V4 Flash for routine, Claude Opus for architecture** — cost-optimized model routing

---

## What NOT to Build (Lessons Learned)

1. **Don't let agents write foundation docs as skeletons.** Kakuzu shipped at full depth. Sasori shipped as a skeleton and needed a rebuild. Full depth from day one.

2. **Don't skip the audit agent.** Without Itachi, you have no automated way to detect hallucinations. Cron is mechanical. You need semantic auditing.

3. **Don't let agents contact the human unfiltered during warming.** The 30-day warming period with ops review catches bad patterns before they become bad habits.

4. **Don't create agents without defined state files.** An agent with nothing to own is an agent with nothing to do. Define files before defining directives.

5. **Don't skip OWNERSHIP.md updates.** Every agent must be registered in every relevant table. Miss one and brain-write.sh won't enforce boundaries.

6. **Don't use Claude Opus for routine work.** DeepSeek V4 Flash/Pro handles 95% of operations. Claude Opus is for architecture decisions and adversarial analysis only.

---

## Quick Start — Build This in One Session

Feed this entire document to your Claw bot and say:

> "Build the Akatsuki system for my domain. My organization is called ____. I am ____. My agents are: (list names and one-sentence purposes). My business context is: (paste your north-star). Start with the brain, then build each agent at full Kakuzu-depth."

Your Claw bot should:
1. Create the brain directory structure
2. Create north-star.md, OWNERSHIP.md, events.log, decisions.md
3. Create brain-write.sh, brain-load.sh, brain-recall.py
4. Write comprehensive foundation docs for every agent (15 sections each)
5. Wire OWNERSHIP.md with all agents
6. Create all state files, task files, inboxes
7. Create workspaces with AGENTS.md, SOUL.md, IDENTITY.md
8. Set up cron jobs (health check, backups, audits)
9. Add agents to openclaw.json
10. Tell you which Telegram bots to create via @BotFather

Total expected output: ~15-25 files, 3-5 foundation docs, 4-6 cron jobs, fully wired brain.

---

*This document is self-contained. Feed it to any OpenClaw agent and it can replicate this system from scratch. Adjust agent roles, file names, and domain context to your needs. The architecture is the product — the agents are the implementation.*
