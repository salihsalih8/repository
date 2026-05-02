# Pain — Current Tasks
**Last updated:** 2026-04-30 08:38 EDT

## Current Sprint: Build the Brain Skeleton

### 🥇 Priority 1: Brain skeleton + Pain wiring — ✅ DONE
- [x] AGENTS.md updated with brain-first lookup rule
- [x] Today's memory created (2026-04-30.md)
- [x] `brain-load.sh` — load north-star.md + decisions.md + current task state on startup
- [x] `brain-write.sh` — shared write wrapper for all agents
- [x] Wire Pain into brain (this file is part of that)
- [x] Define startup sequence in `brain-load.sh`
- [x] BRAIN-ARCHITECTURE.md (v1, Claude Opus)
- [x] BRAIN-ARCHITECTURE-v2.md (v2, research synthesis from 7 architectures)
- [x] P0-P3 priority gating, frontmatter, passive recall, output gating documented

### 🥈 Priority 2: Spawn Kakuzu
- [ ] Kakuzu foundation doc is written (`agents/kakuzu-foundation.md`)
- [ ] Create `tasks/kakuzu.md`
- [ ] Create `state/runway.md`, `state/cogs.md`
- [ ] Wire Kakuzu into brain-load.sh

### 🥉 Priority 3: Plan Deidara
- [ ] Research brand naming
- [ ] Research visual identity design
- [ ] Draft Deidara foundation doc
- [ ] Create `brain/agents/deidara-foundation.md`

### ✅ Priority 4: Sasori Foundation Doc — DONE
- [x] Comprehensive foundation document written (matching Kakuzu depth)
- [x] OWNERSHIP.md updated with Sasori's files
- [x] inbox/sasori.md created
- [x] events.log updated
- [x] Warming mode active (30 days, 3 dry-run builds required)

### ✅ Priority 5: Itachi Deployed — DONE
- [x] Foundation doc written (24KB, 6 audit types, adversarial testing protocol)
- [x] Brain wired: episodic log, 3 state files, tasks, inbox
- [x] OWNERSHIP.md updated (6 entries)
- [x] brain-load.sh audit context added
- [x] Workspace created (AGENTS/SOUL/IDENTITY)
- [x] Audit cron layer: 1 active (brain-health every 6h) + 4 disabled (daily/weekly/monthly — activate post-warming)
- [x] Warming mode: 30 days, 3 dry-run audits, Pain review

## Rules
- **Never execute foundational/architectural work without Nagato's permission**
- Spawning sub-agents (Claude Code, etc.) requires explicit greenlight
- Tactical ops (reading, organizing, updating task lists, editing owned files) is fine without asking

## Claude Opus Usage Protocol
- **Plan once, send once** — never launch multiple sessions. One shot, done right.
- **Check quota first** — test with a tiny prompt before sending anything big.
- **Never kill a running Claude session** — let it finish. Killed sessions burn quota with zero output.
- **No test/hello prompts on Claude** — those are DeepSeek's job.
- **Prep all context inline** — include file contents in the prompt to minimize tool-use counts.
- **DeepSeek for ops, Claude for deep thinking only** — be ruthless about what justifies an Opus call.
- **If rate limited, stop and wait** — retry at the reset time. No workarounds.

**Rate limit behavior:** Claude Code Pro caps at ~20-50 messages per 5-hour window. Each prompt + each tool use counts. Plan accordingly.

## Open Issues
- Brand name — NOT selected yet, blocks trademark
- LLC/EIN — status unknown
- Trademark — not filed
- Kakuzu deployment — pending Nagato greenlight
- Voice on podcast — open decision
