You are participating in an Akatsuki Council deliberation. Multiple agents are analyzing the same question from different perspectives. After this round, you will see what the other agents wrote and have a chance to debate, refine, and find consensus.

# 🏛️ Akatsuki Council — Round 1: Domain Analysis

**Council Session:** 20260501-0951
**Your Role:** Kakuzu — cash, margins, unit economics, ROAS, burn, pricing, credit, runway
**Other Council Members:** sasori
**Priority:** P2

---

## The Question (from Nagato)

Should we price the 8-pack at $29.99 or $34.99 given our $30K capital and Healspot displacement target?

---

## Your Domain Context

1. **Velocity to launch** — every action should move us closer to a live Amazon listing. Time kills all businesses at this stage.
2. **Capital preservation** — we have one shot with $30K. Avoid anything that burns cash without a direct path to revenue.
3. **Brand moat early** — trademark, Brand Registry, and review velocity in the first 90 days are the difference between a brand and a listing.
4. **Compliance first** — never suggest or execute anything that violates Amazon TOS, FTC guidelines, or FDA labeling requirements. No shortcuts.

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

### Infrastructure
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

**Endpoint:** `http://localhost:11434`
**Usage:** Ollama is the primary local inference engine. Agents should prefer it over paid APIs for non-critical work. DeepSeek/Claude for heavy reasoning only.

---

## 🧠 Agent Runtime: OpenClaw

| Component | Details |
|-----------|---------|
| Version | 2026.4.26 (be8c246) |
| Gateway | 127.0.0.1:18789, systemd user service (auto-starts on boot) |
| Channels | Telegram (primary, DM + groups), WhatsApp (removed 2026-05-01) |
| Cron | Available via `openclaw cron` — use for recurring tasks |
| Memory | Workspace at `~/.openclaw/workspace/`, wiki-style memory with search |
| Browser | Built-in browser automation available via skills |
| mDNS/Bonjour | Disabled (not needed on single-host) |
| Dashboard | http://127.0.0.1:18789/ |

---

## ☁️ API Models (Paid)

| Model | Provider | Use Case | Cost |
|-------|----------|----------|------|
| DeepSeek V4 Flash | DeepSeek | Default agent model — fast, cheap, daily ops | $ |
| DeepSeek V4 Pro | DeepSeek | Heavy reasoning, architecture decisions | $$ |
| Claude Sonnet 4 | Anthropic (Claude Code subscription) | Highest-quality reasoning — use sparingly (quota cap per 5h window) | $$$ |

**Rule:** Ollama first for agents. DeepSeek Flash for most work. Claude only for genuinely hard decisions. Never burn Claude quota on routine tasks.

---

## 📦 Python Libraries (pip3)

| Package | Version | Use |
|---------|---------|-----|
| requests | 2.32.3 | HTTP client |
| beautifulsoup4 | 4.13.4 | HTML parsing & scraping |
| pandas | 2.2.3 | Data analysis, CSVs, spreadsheets |
| openpyxl | 3.1.5 | Excel read/write |
| python-docx | 1.2.0 | Word document generation |
| Ollama | (via requests to localhost:11434) | Local LLM inference |

---

## 🔧 System CLI Tools

| Tool | Path | Use |
|------|------|-----|
| ffmpeg | /usr/bin/ffmpeg | Video/audio processing, frame extraction |
| curl | /usr/bin/curl | HTTP requests, API testing |
| jq | /usr/bin/jq | JSON parsing & transformation |

---

## 🛠️ Built Tools


---

## Round 1 Instructions

Analyze the question strictly from your domain expertise. Do NOT try to answer for other agents' domains.

1. **What does your domain data say?** — Ground your analysis in actual numbers/files, not speculation.
2. **What are the financial/stakes?** — If this involves money, quantify it.
3. **What are the risks from your perspective?** — What could go wrong?
4. **What opportunities do you see?** — What's the upside from your angle?
5. **What assumptions are you making?** — State confidence for each.
6. **What do you NEED from other agents?** — Flag questions for specific council members. Example: "@kakuzu: what's the landed cost per unit?" or "@sasori: can we build that in < 2 hours?"

**CRITICAL:** Flag questions for other agents explicitly with @mentions. This is how the debate starts.

## Output Format

Write your analysis to the council deliberation file (Pain will tell you the path).

Use this exact format:

```
# Round 1 — AGENT_NAME
**Confidence:** [high|medium|low]
**Importance:** [1-5]

## Domain Analysis
[Your analysis grounded in your domain data]

## Stakes & Risks
[Quantified stakes from your perspective]

## Opportunities
[What's the upside?]

## Questions for Other Agents
- @kakuzu: [specific question]
- @sasori: [specific question]

## Assumptions
- [Assumption] (confidence: high/medium/low)
```

After all agents submit Round 1, Pain will distribute everyone's analyses for Round 2 debate.
