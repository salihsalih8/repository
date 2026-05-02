# Akatsuki Brain — Architecture v2 (Design Locked)

**Date:** 2026-04-30
**Source:** Synthesis of Claude Opus round 1 + Pain counter-arguments + research of 7 existing OpenClaw brain architectures
**Influences:** OpenClaw native, Shawn Harris cognitive arch, treygoff24 memory-system, claude-mem, Coolmanns 12-layer, VelvetShark masterclass, Glaucobrito unified memory
**Principle:** Steal the good, own the unique. We are the only architecture solving multi-agent coordination + cost routing + business awareness.

---

## A. Memory Architecture — Hot/Warm/Cold + Priority Gating

### A.1 Decision
Three tiers, priority-gated writes, structured frontmatter on every file.

| Tier | What | Token budget | Lifetime | Location |
|------|------|--------------|----------|----------|
| **HOT** | Per-agent digest auto-generated each session | ≤ 800 tokens | Regenerated every load | `brain/hot/<agent>.md` (ephemeral, gitignored) |
| **WARM** | Canonical files: north-star, decisions, current state, current tasks, last 30d events | Read on demand | Live | `brain/` root + `brain/state/`, `brain/tasks/` |
| **COLD** | Archived events, resolved tasks, old state snapshots, weekly digests | Searchable, never auto-loaded | Forever (archived not deleted) | `brain/archive/YYYY-MM/` |

### A.2 Priority Gating (NEW — from Shawn Harris)
Not everything is worth storing. Before writing to events.log or any memory file, classify:

| Priority | Type | Destination | Example |
|----------|------|-------------|---------|
| **P0** | Critical — must persist | `events.log` + alert Nagato | Deadline changes, budget breaches, supplier issues |
| **P1** | Operational — important context | `events.log` + `state/*` updates | Decision made, task completed, config change |
| **P2** | Context — useful reference | `events.log` only | Meeting notes, conversation summaries |
| **P3** | Ephemeral — session-only | Skip persistence | Debug steps, one-time lookups, test output |

**Implementation:** `brain-write.sh` now requires a priority flag:
```bash
brain-write.sh events.log "P1: Supplier confirmed avocado oil CoA" --priority P1
```
P0 writes are gated (requires Nagato confirmation). P3 writes are rejected by the wrapper.

### A.3 Structured Frontmatter (NEW — from treygoff24)
Every significant file starts with YAML frontmatter for deterministic search:

```yaml
---
title: Supplier CoA Verification
date: 2026-04-30
priority: P1
agent: pain
tags: [supplier, compliance, avocado-oil]
status: resolved
---
```

This enables `brain-query.sh` to filter by tag, agent, date, status — without parsing markdown.

### A.4 Implementation
```bash
generate_hot() {
    local agent="$1"
    local out="$BRAIN_DIR/hot/${agent}.md"
    {
        echo "---"
        echo "agent: $agent"
        echo "generated: $(date -I)"
        echo "source: brain-load.sh"
        echo "---"
        echo ""
        echo "## Identity"
        grep -A2 "^## $agent" "$BRAIN_DIR/agents/${agent}-foundation.md" | head -5
        echo ""
        echo "## Priorities (north-star)"
        sed -n '/^## What agents should optimize/,/^## Hard stops/p' "$BRAIN_DIR/north-star.md" \
            | grep -E "^[0-9]+\." | head -4
        echo ""
        echo "## Open decisions affecting me"
        grep "OPEN" "$BRAIN_DIR/decisions.md" | grep -i -E "$agent|all" | head -5
        echo ""
        echo "## My active tasks"
        grep -E "^- \[ \]" "$BRAIN_DIR/tasks/${agent}.md" | head -8
        echo ""
        echo "## Pulse (last 5 events touching me, P0-P1 only)"
        grep -E "\[$agent\]|@$agent" "$BRAIN_DIR/events.log" | grep -E "P0|P1" | tail -5
        echo ""
        echo "## Inbox"
        [ -s "$BRAIN_DIR/inbox/${agent}.md" ] && cat "$BRAIN_DIR/inbox/${agent}.md" || echo "(empty)"
    } > "$out"
    
    local tokens=$(($(wc -w < "$out") * 4 / 3))
    if [ "$tokens" -gt 800 ]; then
        echo "WARN: hot/${agent}.md = ~${tokens}tok (budget 800). Truncating." >&2
        head -c 3200 "$out" > "$out.tmp" && mv "$out.tmp" "$out"
    fi
}
```

---

## B. Agent Coordination — Single-Writer + Output Gating

### B.1 Decision
Single-writer-per-file. No exceptions. Three communication primitives + one NEW (output gating).

### B.2 Communication Primitives

| Primitive | What | When | Example |
|-----------|------|------|---------|
| **Inbox** | Async write request | Agent needs another agent to DO something | "Kakuzu, update COGS for SKU-001" |
| **State read** | Synchronous file read | Agent needs another agent's DATA | Pain reads `state/runway.md` for current cash position |
| **Events log mention** | Broadcast signal | Agent needs to notify ALL agents or flag Nagato | `@kakuzu [P1] Updated supplier CoA"` |
| **Output gating** (NEW) | Context-specific loading | Agent is about to perform a specific task type | Email task → loads email config files |

### B.3 Output Gating (NEW — from Shawn Harris)
Different task contexts trigger different brain file loads. brain-load.sh varies what it provides per task type:

| Task Context | Loads |
|-------------|-------|
| Session start | `hot/<agent>.md`, `north-star.md`, `decisions.md` (OPEN lines) |
| Financial question | `state/runway.md`, `state/cogs.md`, `agents/kakuzu-foundation.md` |
| Brand/content task | `agents/deidara-foundation.md` (once created), brand assets dir |
| Supplier/compliance | Supplier CoA files, `business/compliance/*` |
| General / undefined | Default hot digest only |

**Implementation:** Task context detected from the first user message or agent's stated task. `brain-load.sh <context>` loads only what's relevant.

### B.4 File Ownership Map

| File | Owner | Readers |
|------|-------|---------|
| `north-star.md` | Nagato (human) | All (read-only) |
| `decisions.md` | Nagato | All (append-only) |
| `events.log` | All | All |
| `tasks/pain.md` | Pain | Nagato, Pain |
| `tasks/nagato.md` | Pain (writes) | Nagato (reviews) |
| `tasks/kakuzu.md` | Kakuzu | Nagato, Pain |
| `state/runway.md` | Kakuzu | All (read) |
| `state/cogs.md` | Kakuzu | All (read) |
| `state/inventory.md` | Pain | All (read) |
| `hot/*.md` | brain-load.sh | Respective agent |
| `inbox/*.md` | Sender (writes) | Recipient (reads) |

### B.5 Locking
`brain-write.sh` uses `flock` (Linux file locks) for atomic writes:

```bash
exec 200>"$BRAIN_DIR/.locks/$(basename $TARGET).lock"
flock -x 200
# write...
flock -u 200
```

Single-writer enforced by convention + `brain-write.sh` check: if agent doesn't own the file and isn't Nagato, write is rejected.

---

## C. Knowledge Growth — Archive, Summarize, Prune

### C.1 Decision
Time-based archival. Summarization-based compression. Priority-aware pruning.

### C.2 Archive Schedule

| Frequency | What | Where |
|-----------|------|-------|
| Weekly (Monday 02:00) | Move completed tasks + resolved decisions to archive | `archive/YYYY-MM/tasks-completed.md` |
| Monthly (1st 02:00) | Rotate events.log → gzipped archive | `archive/YYYY-MM/events.log.gz` |
| Monthly | Snapshot `state/*.md` → archive | `archive/YYYY-MM/state-snapshot/` |
| Quarterly | Generate summary of quarter's decisions | `archive/YYYY-Qn/summary.md` |

### C.3 Pruning Rules
- P3 entries: never written (filtered by brain-write.sh)
- P2 entries: auto-pruned from events.log after 90 days
- P1 entries: retained in archive forever
- P0 entries: retained live for 12 months, then archived

### C.4 Events.log Format (NEW — with frontmatter + priority)
```
---
date: 2026-04-30
priority: P1
agent: pain
---
Supplier confirmed avocado oil spec. CoA received. [@kakuzu] Please update cogs.md.
```

This replaces the raw `[TIMESTAMP] [agent] message` format. The old format is migrated in-place by a one-time script.

---

## D. Startup Ritual — brain-load.sh + brain-bootstrap.sh

### D.1 Decision
Two-phase boot: system bootstrap first, then agent brain loading.

### D.2 System Bootstrap (NEW)
`brain-bootstrap.sh` — runs at VM boot via systemd:

```bash
#!/bin/bash
# 1. Verify filesystem invariants
[ -f "$BRAIN_DIR/north-star.md" ] || exit 1
[ -f "$BRAIN_DIR/OWNERSHIP.md" ] || exit 1

# 2. Verify git repo health
cd "$WORKSPACE_DIR"
git fsck --no-progress 2>/dev/null || echo "WARN: git fsck issues" >> /tmp/brain-bootstrap.warnings

# 3. Clear stale locks (>1 hour)
find "$BRAIN_DIR/.locks/" -mmin +60 -delete 2>/dev/null

# 4. Process unprocessed inbox messages
for msg in "$BRAIN_DIR/inbox/.unprocessed/"*; do
    [ -f "$msg" ] && mv "$msg" "$BRAIN_DIR/inbox/" 2>/dev/null
done

# 5. Mark system online
TIMESTAMP=$(date '+%Y-%m-%d %H:%M %Z')
echo "[$TIMESTAMP] [system] Brain bootstrap complete" >> "$BRAIN_DIR/events.log"
touch /tmp/brain-ready
```

Cron jobs gate on `/tmp/brain-ready`. If bootstrap fails, no cron runs.

### D.3 Agent Brain Load
`brain-load.sh <agent-name> [context-type]`:

1. Check bootstrap health (`/tmp/brain-ready`)
2. Load `north-star.md` (priorities + constraints)
3. Load `decisions.md` (OPEN items only)
4. Load `hot/<agent>.md` (regenerated every time)
5. If context type specified, load additional files per output gating rules
6. Load inbox if not empty
7. Run passive recall (see Section E)
8. Emit memory to agent context

---

## E. Search & Retrieval — Passive Recall + Frontmatter Filtering (NEW)

### E.1 Decision
Two-tier retrieval: **passive recall** (auto-surfaced before every turn) + **active search** (on-demand).

### E.2 Passive Recall (from treygoff24)
Before every agent response, brain-load.sh automatically surfaces:

1. **P0 events** from the last 24h (critical — always relevant)
2. **High-priority tasks** assigned to this agent
3. **Hot digest** (<800 tokens)
4. **Active decisions** (OPEN items from decisions.md)

This replaces the model's need to remember — the brain reminds it.

### E.3 Active Search
Two methods:

| Method | When | Implementation |
|--------|------|----------------|
| **Frontmatter filter** | Agent knows what it's looking for | `grep "^tags:.*supplier" events.log` |
| **OpenClaw memory_search** | Agent needs semantic find | OpenClaw's built-in `memory_search` tool (hybrid vector + keyword) |

**Order of operations:** Frontmatter filter first (deterministic, free). If no results, fall back to semantic search (probabilistic, embedding cost).

### E.4 Monthly Evaluation (NEW — from treygoff24)
Run a lightweight recall test on the first of each month:

```bash
#!/bin/bash
# brain-eval.sh — Test recall quality
TESTS=(
    "What is our hero claim? → avocado oil / no seed oils"
    "Who is our displacement target? → Healspot"
    "What is our launch MSRP? → $29.99"
    "How much capital do we have? → $30K"
)

PASS=0
FAIL=0
for test in "${TESTS[@]}"; do
    query="${test%%→*}"
    expected="${test##*→}"
    result=$(brain-query.sh "$query")
    if echo "$result" | grep -qi "$expected"; then
        PASS=$((PASS+1))
    else
        FAIL=$((FAIL+1))
        echo "FAIL: $query → expected '$expected', got '$result'" >> /tmp/brain-eval.failures
    fi
done
echo "Evaluation: $PASS passed, $FAIL failed" >> events.log
```

If failure rate > 20%, flag Nagato.

---

## F. Cost & Token Budgeting — DeepSeek for Ops, Claude for Thinking

### F.1 Decision
DeepSeek V4 Flash ($0.14/$0.28 per M tokens) as default for all operations. Claude Opus (subscription, ~20-50 messages/5h) for deep thinking only.

### F.2 Routing Rules

| Task Type | Model | Rationale |
|-----------|-------|-----------|
| File reads, brain operations | DeepSeek Flash | Plumbing — Claude would be wasteful |
| Task updates, inbox management | DeepSeek Flash | Operational — no deep thinking needed |
| Content creation (copy, captions) | DeepSeek Flash | Creative but not architectural |
| Architecture design decisions | Claude Opus | Needs reasoning depth |
| Financial modeling edge cases | Claude Opus | Cost of wrong model > cost of Opus call |
| Supplier negotiation strategy | Claude Opus | High-stakes — get it right once |
| Brand identity / naming | Claude Opus | Creative + strategic, one-shot |

### F.3 NEVER_OPUS List (Enforced)
These task types CANNOT use Opus regardless of request:

```
git_commit, file_read, file_write, grep_search,
brain_write, brain_query, rate_limit_check,
verify_lock, event_log_append, task_checklist_update
```

### F.4 Opus Quota Tracking
```bash
# brain-opus-quota.sh
QUOTA_FILE="$BRAIN_DIR/.opus-quota.json"
MAX_5H=20          # Soft cap per 5-hour window
WINDOW_MS=18000000 # 5 hours in ms

current_time=$(date +%s%3N)
window_start=$((current_time - WINDOW_MS))

# Count calls in window
calls=$(jq "[.[] | select(.timestamp > $window_start)] | length" "$QUOTA_FILE" 2>/dev/null || echo 0)

if [ "$calls" -ge "$MAX_5H" ]; then
    echo "QUOTA_EXCEEDED: $calls calls in 5h window (max $MAX_5H)"
    exit 1
fi

# Log the call
jq ". += [{\"timestamp\": $current_time, \"task\": \"$1\", \"agent\": \"$AGENT_NAME\"}]" \
    "$QUOTA_FILE" > "$QUOTA_FILE.tmp" && mv "$QUOTA_FILE.tmp" "$QUOTA_FILE"
echo "Opus call approved ($((calls+1))/$MAX_5H this window)"
```

---

## G. OpenClaw Integration

### G.1 Cron Jobs

| Cron | When | What |
|------|------|------|
| `brain-archive-weekly` | Mon 02:00 | Archive completed tasks, resolved decisions |
| `brain-archive-monthly` | 1st 02:00 | Rotate events.log, snapshot state |
| `brain-digest-weekly` | Mon 06:00 | Generate weekly 1-page summary |
| `brain-backup-daily` | Daily 03:00 | rsync events.log to Backblaze B2 |
| `brain-eval-monthly` | 1st 06:00 | Run recall quality evaluation |
| `brain-opus-quota-reset` | Every 5h | Log Opus quota state |

All cron jobs gate on `/tmp/brain-ready`.

### G.2 Heartbeat Integration
Heartbeat checks, in order:
1. Alert if P0 events exist (action needed)
2. Opus quota remaining
3. events.log size (flag if >10MB)
4. git status (flag if >48h dirty)

### G.3 Sub-Agent Memory
When spawning a sub-agent (e.g., Claude Code via ACP):
1. Generate `brain/hot/subagent-task.md` with task context
2. Sub-agent reads only its hot file + relevant state (output gated)
3. Sub-agent writes results back to `inbox/<parent>.md`
4. Sub-agent cannot modify canonical files (north-star, decisions)

---

## H. Failure & Recovery

### H.1 What Breaks First (Ranked)
1. **events.log grows unbounded** → cron archive fixes this
2. **Git repo diverges** → clone + restore from GitHub
3. **Agent forgets instructions** → brain-load.sh hot digest was stale
4. **brain-write.sh lockfile stale** → bootstrap clears after 1h
5. **Opus quota fully consumed** → DeepSeek fallback, wait for window

### H.2 One-Command Recovery (NEW)
```bash
brain-recover.sh <git-sha>
```
1. Nukes current brain (moves to `/tmp/brain-backup-$(date +%s)`)
2. `git checkout <sha>` — restores from git
3. Runs bootstrap — regenerates hot files, clears locks
4. Verifies invariants — north-star.md exists, OWNERSHIP.md current
5. Reports status to Nagato

Must run monthly as a test.

### H.3 Backup Strategy
| Layer | What | Frequency | Cost |
|-------|------|-----------|------|
| Git (GitHub) | Narrative state (north-star, decisions, tasks, foundations) | Per change | Free |
| Rsync (Backblaze B2) | events.log, state files, archives | Daily | ~$0.50/mo |
| Local | Full brain on disk | Always | Free |

### H.4 Failure Diagnostics Checklist (NEW — from VelvetShark)
When the brain "forgets" something:

1. **Is it in the files?** `grep "topic" events.log decisions.md tasks/*`
   - If no → it was never stored (Failure A)
2. **Is it in context?** Run `/context list` in OpenClaw
   - If hot digest is truncated → increase bootstrapMaxChars config
3. **Was it compacted?** Check the pre-compaction memory flush saved it
   - If no → instructions existed only in chat (Failure A again)
4. **Was it pruned?** Check if session pruning trimmed tool results
   - If yes → temporary, re-run the query

---

## I. Scalability Roadmap

| Stage | Agent Count | Architecture | Trigger |
|-------|-------------|--------------|---------|
| **Stage 1** (Now) | 2-3 | Pure markdown, git-backed, serial runtime | — |
| **Stage 2** (Day 90) | 3-10 | + SQLite for tabular state, + brain-read.sh mandatory | 500 rows OR 2nd SKU |
| **Stage 3** (Month 6) | 10-25 | + Vector embeddings for recall, + inbox automation | Recall failure > 5% |
| **Stage 4** (Year 2) | 25-50 | + Message queue, + parallel agents | Concurrent agent requests exceed cron capacity |

**The invariant that never changes across stages:**
```bash
brain_load()      # Returns context blob
brain_search()    # Returns ranked snippets
brain_write()     # Atomic append
brain_message()   # Inbox delivery
brain_query()     # Tabular query
```

Implementation changes underneath. API stays the same.

---

## J. What We Stole & What We Own

### From others (gratefully adopted):
| Feature | Source |
|---------|--------|
| P0-P3 priority gating | Shawn Harris |
| Output gating (context-specific loading) | Shawn Harris |
| Structured YAML frontmatter | treygoff24 memory-system |
| Passive recall (auto-surfaced context) | treygoff24 memory-system |
| Observation → context injection | claude-mem |
| Failure diagnostics checklist | VelvetShark |
| Monthly recall evaluation | treygoff24 memory-system |
| Activation/decay concept | Coolmanns 12-layer |

### Unique to Akatsuki Brain (no one else has this):
| Feature | Why It Matters |
|---------|----------------|
| Multi-agent file ownership | Without this, agents overwrite each other's state |
| Cost routing (DeepSeek/Opus) | Without this, we burn $50 quota in a day |
| Opus quota tracking | Without this, Nagato loses interactive access |
| Git-backed narrative | Without this, decisions are unrecoverable |
| Serial runtime | Without this, cost is unpredictable |
| Business-context-aware (north-star) | Without this, agents optimize wrong things |
| brain-bootstrap.sh | Without this, VM crash = silent data loss |
| brain-recover.sh | Without this, recovery is manual and unreliable |

---

*End of Akatsuki Brain v2. Locked April 30, 2026. Next review: May 30, 2026 or 2nd SKU launch, whichever comes first.*
