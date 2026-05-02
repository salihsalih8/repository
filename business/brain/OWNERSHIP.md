# OWNERSHIP.md — Akatsuki Brain File Authority Matrix
**Date:** 2026-04-30
**Principle:** Single-writer-per-file. Private-by-default writes. Importance-scored claims.

---

## Core Principles

### A. Private-by-Default Writes

Every agent writes to its own **episodic log** by default (`brain/episodic/<agent>.log`). Nothing is shared until explicitly published.

**Publish path:**
1. Agent writes to `brain/episodic/<agent>.log` (private, append-only)
2. Agent explicitly publishes to shared surface (`events.log` or `state/*.md`)
3. Published entries are tagged: `(agent, timestamp, importance, confidence)`
4. Quarantine is virtual — computed at read time from `published_at` + wall clock. No mutation of events.log required. Entries with `confidence: high` skip quarantine. Others carry `quarantine_until` in frontmatter, honored by brain-load.sh (filtered from hot digests, visually tagged in context)

**Why:** One poisoned or confused agent cannot corrupt the brain. Shared state is opt-in, not opt-out.

### B. Importance Scoring

Every write to shared surfaces includes an `importance` field (1-5):

| Score | Meaning | Lifespan |
|-------|---------|----------|
| 1 | Ephemeral — session-only reference | Pruned end-of-session |
| 2 | Context — useful but not critical | 90 days in events.log |
| 3 | Operational — matters for current sprint | 12 months |
| 4 | Strategic — affects decisions or direction | Permanent archive |
| 5 | Critical — breach or emergency, flag Nagato | Permanent + alert |

This lays the foundation for future demotion/forgetting. Cache-TTL pruning is expiry. Importance scoring is demotion. We need both.

---

## File Authority Matrix

### NARRATIVE FILES

| File | Owner (writer) | Readers | Rules |
|------|---------------|---------|-------|
| `north-star.md` | Nagato (human only) | All (read-only) | Never modified by agents. Use tasks/nagato.md to request changes. |
| `decisions.md` | Nagato | All (append-only) | Open/Resolved format. Append only. Never edit old entries. |
| `BRAIN-ARCHITECTURE-v2.md` | Pain | All (read-only) | Design doc. Update via amendment entries. |
| `OWNERSHIP.md` | Pain | All (read-only) | This file. Updated only by Pain with Nagato approval. |
| `AGENT-ONBOARDING.md` | Pain | All (read-only) | Agent production procedure. Kakuzu-template standardized. |

### OPERATIONAL FILES

| File | Owner (writer) | Readers | Rules |
|------|---------------|---------|-------|
| `events.log` | All (after publish) | All | Published entries only. Episodic → publish step required. Quarantine: computed virtually at read time. Filtered from hot digests. confidence=high skips entirely. |
| `tasks/pain.md` | Pain | Nagato, Pain | Current sprint tracking. Check items only. |
| `tasks/nagato.md` | Pain (writes open items) | Nagato (reviews, resolves) | Open decisions needing human input. |
| `tasks/nagato-financial.md` | Kakuzu (writes guardrail breaches) | Nagato (reviews, resolves) | Financial escalations requiring Nagato attention. |
| `tasks/kakuzu.md` | Kakuzu | Nagato, Pain | Financial sprint tasks. |
| `tasks/sasori.md` | Sasori | Nagato, Pain | Build sprint tasks. |
| `tasks/itachi.md` | Itachi | Nagato, Pain | Audit tasks & cycles. |
| `tasks/deidara.md` | Deidara | Nagato, Pain | Brand sprint tasks. |

### STATE FILES

| File | Owner (writer) | Readers | Rules |
|------|---------------|---------|-------|
| `state/runway.md` | Kakuzu | All (read) | Cash position. Fresh as of last Kakuzu boot. Must have `Last updated:` header. |
| `state/cogs.md` | Kakuzu | All (read) | Cost of goods per SKU. |
| `state/inventory.md` | Pain | All (read) | Units in transit, on hand, sold. |
| `state/ppc.md` | Kakuzu | Nagato, Pain (read) | Campaign performance data. |
| `state/pipeline.md` | Pain | All (read) | Product development pipeline. |
| `state/tools.md` | Sasori | All (read) | Active tools, versions, deployment status. |
| `state/builds.md` | Sasori | All (read) | Build history, changelogs, deploy timelines. |
| `state/audit.md` | Itachi | Pain, Nagato (read). Other agents: read only. | Audit findings log. |
| `state/security.md` | Itachi | Pain, Nagato (read). Other agents: no access. | Security posture, vulnerabilities, incidents. |
| `state/agent-health.md` | Itachi | All (read) | Per-agent reliability scoring. |

### AGENT FILES

| File | Owner (writer) | Readers | Rules |
|------|---------------|---------|-------|
| `agents/pain-foundation.md` | Pain | All (read) | Pain's identity, role, constraints. |
| `agents/kakuzu-foundation.md` | Kakuzu | All (read) | Kakuzu's role, directives, guardrails. |
| `agents/sasori-foundation.md` | Sasori (Pain-maintained) | All (read) | Sasori's role, directives, build gates. |
| `agents/itachi-foundation.md` | Itachi (Pain-maintained) | All (read) | Itachi's role, audit methodology, security baseline. |
| `agents/deidara-foundation.md` | Deidara | Deidara, Nagato, Pain (read) | Deidara's role (not yet created). |
| `episodic/pain.log` | Pain (only) | Pain (only) | Private event log. Explicit publish needed to share. |
| `episodic/kakuzu.log` | Kakuzu (only) | Kakuzu (only) | Private event log. |
| `episodic/sasori.log` | Sasori (only) | Sasori (only) | Private build log. |
| `episodic/itachi.log` | Itachi (only) | Itachi (only). Pain may request access for review. | Private audit trail. |
| `episodic/deidara.log` | Deidara (only) | Deidara (only) | Private event log. |

### GENERATED FILES

| File | Generator | Readers | Rules |
|------|-----------|---------|-------|
| `hot/<agent>.md` | brain-load.sh | Respective agent | Regenerated each session. ≤800 tokens. Gitignored. |
| `archive/YYYY-MM/*` | Cron jobs | All (read) | Monthly rotation. Compressed. |

### INBOX FILES

| File | Owner (writer) | Readers | Rules |
|------|---------------|---------|-------|
| `inbox/pain.md` | Any agent | Pain | Write requests for Pain. |
| `inbox/nagato.md` | Any agent | Nagato | Alerts, decisions needed. |
| `inbox/kakuzu.md` | Any agent | Kakuzu | Write requests for Kakuzu. |
| `inbox/sasori.md` | Any agent | Sasori | Write requests for Sasori. |
| `inbox/itachi.md` | Any agent | Itachi | Audit requests for Itachi. |

---

## Publish Protocol

```
1. Agent writes to episodic/<agent>.log
   Format: [TIMESTAMP] [importance:1-5] [confidence:low|medium|high] message

2. Agent decides to share → calls brain-write.sh events.log with:
   --importance 1-5
   --confidence low|medium|high
   --source episodic/<agent>.log

3. Entry appears in events.log with frontmatter:
   ---
   agent: pain
   importance: 3
   confidence: high
   quarantine_until: 2026-04-30T15:00-04:00
   ---

4. Others can read immediately. Act on entries where:
   - quarantine has expired (>1h) OR
   - confidence = high

5. P0 entries bypass quarantine (always actionable)
```

---

## Locking

`brain-write.sh` enforces via `flock` + atomic rename. Write to `<target>.tmp`, `fsync`, `rename` to `<target>`. Readers see old-or-new, never partial. Lockfiles store holder PID; bootstrap clears only if PID dead AND timer > 10min.

**Invariant:** Brain directory must be on local POSIX filesystem. Network/synced FS (Dropbox, NFS, iCloud) silently breaks flock.

---

## Migration Triggers

| Trigger | Action |
|---------|--------|
| Agent count > 5 | Add brain-read.sh as mandatory read path |
| State files > 500 rows | Migrate tabular state to SQLite (brain.db) |
| State files > 10 | Split state/ into subdirectories per agent |
| Sasori deploys | Add ownership rows for sasori state files (tools.md, builds.md) |
| Itachi deploys | Add ownership rows for itachi state files (audit.md, security.md, agent-health.md) |
| Deidara deploys | Add ownership rows for deidara state files |
| Kuzu deploys | Add `graph/kuzu.db` row (Pain owns, all read) |

---

*This file is append-only. Updates require Nagato review.*
