# AGENT-ONBOARDING.md — Akatsuki Agent Production Procedure
**Version:** 1.0
**Last updated:** April 30, 2026
**Owner:** Pain (maintainer)
**Purpose:** Standardized, replicable procedure for onboarding new Akatsuki agents. Kakuzu's deployment was the smoothest — this procedure codifies that process as the template.

---

## Why This Exists

Three agents deployed. Three different experiences:
- **Kakuzu** — smoooothest. Thorough doc, clear guardrails, warming mode, everything wired before first boot.
- **Sasori** — foundation doc was a skeleton. Had to be rebuilt from scratch to match Kakuzu depth. Delayed operational readiness.
- **Pain** — ad-hoc, retrofitted. No formal onboarding at all.

**From now on:** Every new agent follows this procedure. No exceptions. Kakuzu's deployment is the gold standard — every agent gets the same depth of documentation, the same warming period, the same wiring.

---

## Prerequisites — Before ANY Work Begins

These are **Nagato decisions** that must be made before Pain touches anything. Without these, onboarding stalls at step one.

### Decision Checklist (Nagato)

- [ ] **Agent name** — Naruto character? What role in the organization?
- [ ] **Agent purpose** — one sentence. What problem does this agent solve?
- [ ] **Files it owns** — what state/task/episodic files will it be sole writer of?
- [ ] **Files it reads** — what existing files does it need access to?
- [ ] **Channel** — Telegram bot (@<agent>_bot) — standard for all Akatsuki agents. Nagato creates the bot via @BotFather.
- [ ] **Model** — default model for execution? Model for deep thinking/architecture?
- [ ] **Access control** — who can reach this agent directly? (usually Nagato only)
- [ ] **Warming duration** — standard is 30 days. Exceptions?

**Pain's role at this stage:** Present tradeoffs, recommend, document — but do NOT proceed until Nagato signs off on all 8 decisions.

---

## Phase 1 — Foundation Document

**Output:** `agents/<agent>-foundation.md`
**Template quality:** Kakuzu's doc (122+ lines, 15+ sections). Minimum bar.
**Who writes it:** Pain (with Claude Opus for architecture review if complex)

### Required Sections (every foundation doc MUST include)

| # | Section | Purpose | Example from Kakuzu |
|---|---------|---------|---------------------|
| 1 | Header block | Status, model, channel, access, runtime | `**Status:** Warming Mode (30 days)` |
| 2 | Role | What they do, where they fit, what they're NOT | "Kakuzu is the financial guardian..." |
| 3 | Communication | Intake channels, relay patterns, response format | Telegram DM, Pain relay, events.log |
| 4 | Owns (sole writer) | Every file they're responsible for, with descriptions | `state/runway.md` — Cash position |
| 5 | Reads | Files they consume but don't modify | `north-star.md`, `decisions.md` |
| 6 | Write Protocol | Private-by-default, publish gate, quarantine | Episodic → publish → quarantine → shared |
| 7 | Importance Scoring | 1-5 table tailored to their domain | Score definitions with domain-specific examples |
| 8 | Importance=5 Rules | What triggers score-5, escalation procedure | Bypass quarantine, flag Nagato, log full context |
| 9 | Hard Stops | 10+ absolute prohibitions | Financial, deployment, security, architecture, quality |
| 10 | Directives | Daily, per-request, weekly, sprint cadence | What they do on boot, per task, weekly summary |
| 11 | Warming-Up Mode | Duration, restrictions, dry-run protocol | 30 days, no self-deploy, dry-run first N sessions |
| 12 | Startup Sequence | Exact boot procedure | brain-load → read own files → check inbox → pick task |
| 13 | Authority Matrix | File-level permissions table | Sole writer, read-only, append-only |
| 14 | Data Labeling | Domain-specific labels for their data | `[ACTUAL]` vs `[ESTIMATE]` for Kakuzu, build labels for Sasori |
| 15 | Relationship to Other Agents | Who they talk to, how, why | Communication paths, dependencies |

### Section Quality Standard

Every section must pass this test: **"Can a new agent read this and operate correctly without asking a human?"**

If any section is vague, generic, or skips domain-specific details → rewrite it. The Kakuzu doc passes this test. The original Sasori skeleton did not. This is why Kakuzu was smooth and Sasori needed a rebuild.

### Pain's Checklist (Phase 1)
- [ ] All 15 sections present
- [ ] Importance scoring table has domain-specific examples (not generic)
- [ ] Hard stops cover: financial, deployment, security, architecture, quality (5 categories minimum)
- [ ] Warming mode defines: duration, restrictions, dry-run count, checklist
- [ ] Startup sequence is executable (brain-load.sh command, file paths, order)
- [ ] Relationship table covers all existing agents + any planned
- [ ] Document passes the "no human needed" test

---

## Phase 2 — Brain Wiring

**Output:** Files created, OWNERSHIP.md updated, brain-load.sh context added.

### Step 2.1: Create Files

Every agent needs these files created and initialized:

```bash
# From workspace root (business/brain/)
touch episodic/<agent>.log
echo "[$(date -Iseconds)] [importance:3] [confidence:high] <Agent> deployed. Awaiting first boot." >> episodic/<agent>.log

# State files (agent-specific — create each one the agent owns)
touch state/<file1>.md
touch state/<file2>.md

# Task file
touch tasks/<agent>.md

# Inbox
touch inbox/<agent>.md
```

### Step 2.2: Update OWNERSHIP.md

Add entries for the new agent in ALL relevant tables:

| Table | Entries Needed |
|-------|---------------|
| **OPERATIONAL FILES** | `tasks/<agent>.md` row |
| **STATE FILES** | One row per state file the agent owns |
| **AGENT FILES** | `agents/<agent>-foundation.md` row |
| **AGENT FILES** | `episodic/<agent>.log` row |
| **INBOX FILES** | `inbox/<agent>.md` row |
| **MIGRATION TRIGGERS** | If agent count crosses threshold, add trigger rows |

**Verification:** `grep -c "<agent>" OWNERSHIP.md` should return ≥4.

### Step 2.3: Add brain-load.sh Context

Add a context type matching the agent's domain:

```bash
# In brain-load.sh, under output_gate(), add:
<context_name>)
    echo "### <Domain> Context"
    # Load agent's state files
    # Load agent's foundation doc
    ;;
```

**Context naming convention:**
- `financial` — Kakuzu (runway, cogs, financial state)
- `build` — Sasori (tools, builds, build state)
- `brand` — Deidara (future: brand assets, content calendar)
- `compliance` — future compliance agent

The context should load the agent's state files + foundation doc summary. Keep it under 800 tokens total (brain-load.sh enforces this).

### Pain's Checklist (Phase 2)
- [ ] Episodic log created with deployment entry
- [ ] All state files created (even if empty — agents panic on missing files)
- [ ] tasks/<agent>.md created with warming-mode sprint
- [ ] inbox/<agent>.md created with empty queue
- [ ] OWNERSHIP.md updated in ALL 5 tables
- [ ] brain-load.sh has context handler for this agent
- [ ] `bash brain-test.sh` still passes (12/12)

---

## Phase 3 — Infrastructure

**Output:** OpenClaw agent config, workspace directory, channel setup.

### Step 3.1: Agent Config (openclaw.json)

Add the agent entry:

```json
{
  "id": "<agent-id>",
  "name": "<Agent Name>",
  "workspace": "/home/alfred/.openclaw/workspace-<agent-id>",
  "agentDir": "/home/alfred/.openclaw/agents/<agent-id>/agent"
}
```

Plus channel routing if they have their own bot:

```json
// In channels.telegram.accounts:
"<agent-id>": {
  "botToken": "${<AGENT>_BOT_TOKEN}",
  "dmPolicy": "allowlist",
  "allowFrom": ["6605650897"]
}

// In agents.list channel routing:
{
  "agentId": "<agent-id>",
  "match": {
    "channel": "telegram",
    "accountId": "<agent-id>"
  }
}
```

### Step 3.2: Create Workspace

```bash
mkdir -p /home/alfred/.openclaw/workspace-<agent-id>
ln -s /home/alfred/.openclaw/workspace/business /home/alfred/.openclaw/workspace-<agent-id>/business
```

### Step 3.3: Workspace Files

Every workspace needs these files. Use the templates below:

| File | Purpose | Source |
|------|---------|--------|
| `AGENTS.md` | Behavior rules, red lines, brain access | Template in Appendix A |
| `SOUL.md` | Identity, vibe, hard stops | Template in Appendix B |
| `IDENTITY.md` | Name, creature type, emoji | Template in Appendix C |
| `USER.md` | About Nagato | Copy from Pain's workspace |
| `TOOLS.md` | Agent-specific tool notes | Start minimal, agent fills in |

### Step 3.4: Telegram Bot (mandatory — every agent gets one)

1. Nagato creates bot via @BotFather on Telegram: `@<agent>_bot`
2. Nagato sets bot token as environment variable: `<AGENT>_BOT_TOKEN`
3. Pain adds to OpenClaw config (see Step 3.1)
4. Nagato sends `/start` to the bot
5. Verify bot responds

### Step 3.5: Restart Gateway

```bash
openclaw gateway restart
```

### Pain's Checklist (Phase 3)
- [ ] Agent entry in openclaw.json (agents.list + channels routing)
- [ ] Bot token set as env var
[ ] Channel routing in openclaw.json
- [ ] Workspace directory created
- [ ] Business symlink created
- [ ] AGENTS.md created (with brain-load reference)
- [ ] SOUL.md created (with agent personality)
- [ ] IDENTITY.md created
- [ ] Gateway restarted successfully
- [ ] Bot responds to Nagato's DM

---

## Phase 4 — Warming & Dry-Run

**Output:** Agent operational but gated. Output reviewed before live deployment.

### Step 4.1: Define Warming Parameters

Standard warming: **30 days, 3 dry-run sessions.**

| Parameter | Standard | When to deviate |
|-----------|----------|-----------------|
| Duration | 30 days | Shorter if agent is read-only, longer if handles money/deployment |
| Dry-run count | 3 sessions | More if agent has high blast radius (financial, deployment) |
| Restricted actions | Deploy, spend, external contact, importance=5 | Add domain-specific restrictions |
| Reviewer | Pain (primary), Nagato (final) | — |

### Step 4.2: Dry-Run Protocol

Each dry-run session:

1. **Pain sends a real task** (not a toy problem — test with actual work)
2. **Agent executes normally** — plans, builds/analyzes, tests, produces output
3. **Agent stages output** — writes to episodic log + state files but does NOT flag Nagato for deployment or emit importance=5
4. **Pain reviews output** against checklist:
   - [ ] Output matches the task request
   - [ ] No hallucinations, no fabricated data
   - [ ] Importance scoring is appropriate
   - [ ] Confidence labels are honest
   - [ ] Write protocol followed (episodic → publish)
   - [ ] No hard stop violations
   - [ ] Domain-specific checks (math for Kakuzu, tests for Sasori)
5. **Pain gives feedback** — what was good, what needs fixing
6. **Repeat** until 3 clean dry runs (no major issues)

### Step 4.3: Warming Completion

When all dry runs are clean:
1. Pain updates `agents/<agent>-foundation.md`: `**Status:** Deployed (warming complete)`
2. Pain flags Nagato: "Warming complete for <agent>. Review and clear for live."
3. Nagato reviews dry-run outputs
4. Nagato clears agent for live operation
5. Pain publishes to `events.log` with importance=4

### Pain's Checklist (Phase 4)
- [ ] 3 dry-run sessions completed
- [ ] All dry-run outputs reviewed by Pain
- [ ] Any issues from dry runs resolved
- [ ] Foundation doc status updated
- [ ] Nagato signed off on warming completion

---

## Phase 5 — Go-Live

**Output:** Agent fully operational. All gates open.

### Step 5.1: Remove Warming Restrictions

Update `agents/<agent>-foundation.md`:
- Status → "Deployed (date)"
- Remove or comment warming restrictions
- Enable importance=5 emissions (if applicable)
- Enable deployment/action gates (if applicable)

### Step 5.2: Verify Complete Wiring

Run the go-live audit:

```bash
# Files exist
for f in \
  agents/<agent>-foundation.md \
  episodic/<agent>.log \
  tasks/<agent>.md \
  inbox/<agent>.md; do
  [ -f "business/brain/$f" ] && echo "✅ $f" || echo "❌ MISSING $f"
done

# OWNERSHIP registered
grep -c "<agent>" business/brain/OWNERSHIP.md

# brain-load wired
grep -c "<context_name>)" business/brain/brain-load.sh

# Agent config
grep -c '"<agent-id>"' ~/.openclaw/openclaw.json
```

### Step 5.3: Publish Go-Live

```bash
brain-write.sh events.log \
  --importance 4 \
  --confidence high \
  --message "<Agent> cleared for live operation. Warming complete. N dry runs passed. Nagato approved."
```

### Step 5.4: Monitor First Week

- Pain checks agent output daily for first 7 days
- Any unexpected behavior → flag Nagato, consider re-entering warming
- After 7 clean days → agent is fully trusted

---

## Quick Reference — Agent Production Checklist

Copy this into every new agent's onboarding session.

```
=== AKATSUKI AGENT PRODUCTION CHECKLIST ===
Agent: ___________
Date started: ___________

PREREQUISITES (Nagato decides)
[ ] Agent name & role
[ ] Files owned
[ ] Files read
[ ] Channel (Telegram/Sub-agent)
[ ] Model (default + deep thinking)
[ ] Access control
[ ] Warming duration

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
[ ] Warming-Up Mode (duration, restrictions, dry-run count)
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
[ ] brain-test.sh still 12/12

PHASE 3 — Infrastructure
[ ] Agent config in openclaw.json
[ ] Channel routing
[ ] Bot token env var
[ ] Workspace directory created
[ ] Business symlink created
[ ] AGENTS.md created
[ ] SOUL.md created
[ ] IDENTITY.md created
[ ] Gateway restarted
[ ] Bot responds

PHASE 4 — Warming & Dry-Run
[ ] Dry-run #1: _____ (Pain review: PASS / FIX)
[ ] Dry-run #2: _____ (Pain review: PASS / FIX)
[ ] Dry-run #3: _____ (Pain review: PASS / FIX)
[ ] Foundation doc status updated
[ ] Nagato signed off

PHASE 5 — Go-Live
[ ] Warming restrictions removed from doc
[ ] Go-live audit passed (all files, wiring verified)
[ ] Published to events.log (importance=4)
[ ] Day 1 check: _____
[ ] Day 3 check: _____
[ ] Day 7 check: _____ (agent trusted)
```

---

## Appendices

### Appendix A — AGENTS.md Template

```markdown
# AGENTS.md - <Agent Name>'s Workspace

## Role

You are <Agent Name>, the Akatsuki's <role description>. <One sentence purpose>.

## Communication

<Channel setup — Telegram bot, sub-agent relay, etc.>

**Protocol:**
- Nagato → you directly via <channel>
- Pain → you via inbox/<agent>.md or sessions_spawn
- You report to events.log

## Brain Access

Your workspace has a `business/` symlink to the shared brain. Use it to:
- Read `business/brain/north-star.md` for priorities
- Read `business/brain/decisions.md` for resolved decisions
- Read `business/brain/tasks/pain.md` for what Pain needs
- Write to `business/brain/episodic/<agent>.log` for your private log

## Startup

On every boot, load your brain:
```bash
brain-load.sh <agent> <context>
```

## Hard Stops
- (List from foundation doc)

## Red Lines
- Don't exfiltrate private data. Ever.
- Don't run destructive commands without asking.
- `trash` > `rm`
- When in doubt, ask Nagato or Pain.
```

### Appendix B — SOUL.md Template

```markdown
# SOUL.md - Who You Are

_You're not a chatbot. You're <Agent Name> of the Akatsuki._

## Core Truths

**You are a <role>.** <One sentence identity>.

**Be direct and <tone>.** <Personality guidance>.

**<Domain-specific principle>.** <How they approach their work>.

**You serve Nagato.** Salih is Nagato. Respect his time, his money, his vision. You <action> — he decides.

## Hard Stops
- (Key hard stops from foundation doc)

## Vibe

<Agent personality>. <Two adjectives>. <How they carry themselves>.

---

_You are <Agent Name>. The <title>._
```

### Appendix C — IDENTITY.md Template

```markdown
# IDENTITY.md - Who Am I?

- **Name:** <Agent Name>
- **Creature:** <Role description>
- **Vibe:** <Two adjectives>
- **Emoji:** <Single emoji>
- **Avatar:** —

---

_Established <date> — <Nagato's> <role>._
```

### Appendix D — Post-Onboarding: Deidara

Deidara is the next agent in the queue (brand builder / viral explosion agent). This procedure should be executed start-to-finish for Deidara's deployment. No shortcuts. Foundation doc at Kakuzu depth from day one — no skeleton-first approach.

---

*This document is owned by Pain. Updated whenever a new agent is onboarded. Lessons learned from each deployment are incorporated here. Last updated: April 30, 2026.*
