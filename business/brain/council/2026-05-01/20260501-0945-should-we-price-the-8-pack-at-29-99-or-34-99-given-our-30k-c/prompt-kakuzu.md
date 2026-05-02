# Council Session: 20260501-0945
**Agent:** kakuzu
**Expertise:** cash, margins, unit economics, ROAS, burn rate, pricing, inventory costs, credit lines, runway projections
**Priority:** P2

---

## Question from Nagato

Should we price the 8-pack at $29.99 or $34.99 given our $30K capital?

---

## Domain Context for kakuzu

### North Star (relevant)
1. **Velocity to launch** — every action should move us closer to a live Amazon listing. Time kills all businesses at this stage.
   - *30 days:* Supplier doc verification complete, trademark filed, LLC formed
   - *60 days:* Brand Registry applied, samples approved, PO #1 placed
--
2. **Capital preservation** — we have one shot with $30K. Avoid anything that burns cash without a direct path to revenue.
   - *30 days:* All non-essential spend identified and deferred, credit line researched
   - *60 days:* Credit line secured, PO #1 cash allocated and committed
--
3. **Brand moat early** — trademark, Brand Registry, and review velocity in the first 90 days are the difference between a brand and a listing.
   - *30 days:* Trademark filed, brand name locked
   - *60 days:* Brand Registry submitted, creator list built
--
4. **Compliance first** — never suggest or execute anything that violates Amazon TOS, FTC guidelines, or FDA labeling requirements. No shortcuts.
   - *30 days:* FDA compliance checklist complete, supplier CoA received
   - *60 days:* Label reviewed for claim compliance, Amazon TOS read

### Active Tasks
- [ ] Initial runway snapshot — populate state/runway.md with current cash position
- [ ] Initial COGS model — populate state/cogs.md with per-SKU landed cost
- [ ] Initial PPC baseline — populate state/ppc.md (empty until campaigns launch)
- [ ] Define baseline runway threshold (< 60 days)
- [ ] Define margin floor per SKU (> 30%)
- [ ] Define ROAS minimum (> 1.2x)

### state/runway.md
# Runway Tracker
Last updated: 2026-04-30 19:36 EDT (initialized — no data yet)

| Date | Cash on Hand | MTD Burn | 30d Rolling Burn | Days of Runway | Label |
|------|-------------|----------|------------------|----------------|-------|
| *pending* | *pending* | *pending* | *pending* | *pending* | ESTIMATE |

---
date: 2026-05-01 07:46 EDT
agent: kakuzu
priority: P2
---
Test entry (kakuzu)

### state/cogs.md
# Cost of Goods Sold Tracker
Last updated: 2026-04-30 19:36 EDT (initialized — no data yet)

| Date | SKU | Manufacturing | Freight | Customs | Landed Cost | Margin | Label |
|------|-----|--------------|---------|---------|-------------|--------|-------|
| *pending* | *pending* | *pending* | *pending* | *pending* | *pending* | *pending* | ESTIMATE |

---
date: 2026-05-01 07:46 EDT
agent: kakuzu
priority: P2
---
Test entry (kakuzu)

### state/ppc.md
# PPC Performance Tracker
Last updated: 2026-04-30 19:36 EDT (initialized — no data yet)

| Date | Campaign | Spend | Revenue | ROAS | ACoS | TACoS | Label |
|------|----------|-------|---------|------|------|-------|-------|
| *pending* | *pending* | *pending* | *pending* | *pending* | *pending* | *pending* | ESTIMATE |

### Available Infrastructure
# Tools & Infrastructure Inventory
Last updated: 2026-05-01 07:37 EDT
**Maintained by:** Pain (pre-seeded), Sasori (ongoing)

---

## 🖥️ Host: Clawbian

| Resource | Spec |
|----------|------|
| CPU | 4-core x86_64 |
| RAM | 37 GB (34 GB available) |
| Disk | 112 GB SSD (81 GB free, 25% used) |
| OS | Debian 13, Linux 6.12 |
| Node.js | v22.22.2 |
| Python | 3.13.5 |
| Git | 2.47.3 |
| Docker | Not installed |
| Virtualization | Not installed (no libvirt, no VirtualBox) |
| SQLite | Not installed — use JSON/CSV for storage or install if needed |

---

## 🤖 Local LLM: Ollama

| Model | Size | Status | Notes |
|-------|------|--------|-------|
| `llama3.1:8b` | 4.9 GB | ✅ active | Primary local model — general purpose, good for agents & text gen |
| `nomic-embed-text` | 274 MB | ✅ active | Embeddings — semantic search, RAG, clustering |


### Recent Events (kakuzu-relevant)
Priority order set: brain skeleton → Kakuzu → Deidara.
Kakuzu deployed. State files (runway.md, cogs.md, ppc.md) initialized. Episodic log created. Warming-up mode active — no importance=5 emissions for 30 days. Communication model: Kakuzu reports through Pain (chief of staff). Nagato never contacts Kakuzu directly. guardrails: Runway <60d AND >15% drop WoW, Margin <30% AND >5pp drop, ROAS <1.2x AND >0.5x drop. False alarm protocol: Nagato → Pain → "tell Kakuzu that was false, show me the math."
[2026-04-30 23:00 EDT] Sasori foundation document completed. Comprehensive build including: communication protocol, write protocol with importance scoring, 14 hard stops, build classification (P0-P3), complexity tiers (small/medium/large/system), testing requirements per tier, 8-gate deployment pipeline, warming-up mode (30 days), dry-run protocol (first 3 builds), data labeling, security baseline, startup sequence, sprint cadence, error handling & recovery, tool inventory standards. Sasori now matches Kakuzu's documentation depth. OWNERSHIP.md updated with Sasori's files. inbox/sasori.md created. Ready for Nagato review.
[2026-04-30 23:19 EDT] AGENT-ONBOARDING.md created. Standardized agent production procedure using Kakuzu's smooth deployment as the template. 5 phases: Prerequisites (Nagato decisions) → Foundation Document (15 required sections, Kakuzu-depth minimum) → Brain Wiring (files, OWNERSHIP, brain-load context) → Infrastructure (OpenClaw config, workspace, channel) → Warming & Dry-Run (3 sessions, Pain review) → Go-Live (audit, monitor 7 days). Includes full checklist, workspace file templates (AGENTS.md, SOUL.md, IDENTITY.md), and explicit note that Deidara is next in queue. This procedure eliminates the skeleton-first mistake we made with Sasori.
Brain integration tests (kakuzu): 13 passed, 0 failed, 6 skipped.

---

## Your Role

You are **Kakuzu**, the Akatsuki's cash, margins, unit economics, ROAS, burn rate, pricing, inventory costs, credit lines, runway projections expert.

Analyze the question above from your domain expertise. Consider:
1. What does your domain data say about this?
2. What are the risks from your perspective?
3. What opportunities do you see?
4. What assumptions are you making? (state confidence level)
5. What would you need to know to be more confident?
6. If this is outside your domain, say so clearly.

## Output Instructions

Write your full analysis to: `/home/alfred/.openclaw/workspace/business/brain/council/2026-05-01/20260501-0945-should-we-price-the-8-pack-at-29-99-or-34-99-given-our-30k-c/kakuzu.md`

Format:
```
# Council Response — kakuzu
**Confidence:** [high|medium|low]
**Importance:** [1-5]

## Analysis
[Your domain-specific analysis]

## Recommendation
[Clear, actionable recommendation from your perspective]

## Assumptions & Unknowns
[What you assumed, what you'd need verified]

## Dissenting View (if any)
[If you disagree with what you think other agents might say]
```

---
*Council convened by Pain at 2026-05-01 09:45 EDT. Respond within 10 minutes.*
