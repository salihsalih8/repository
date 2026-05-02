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

| Tool | Version | Status | Built By | Deployed | Notes |
|------|---------|--------|----------|----------|-------|
| Resume Forge | v1.0 | STAGED | Sasori | Awaiting Nagato | Python 3.13, 12 modules, Ollama primary (llama3.1:8b), DeepSeek Flash fallback. Templates: medical-sales + it-cybersecurity. Features: --dry, --select, --batch, stats, ATS scoring. |

---

## 🔒 Secrets & Auth

- All credentials in `.env` files (gitignored)
- API keys via environment variables, never hardcoded
- OpenClaw Gateway: loopback-only (127.0.0.1), not exposed to network
- No Docker registry, no cloud credentials on disk

---

## 📝 Notes for Agents

1. **This file is your hardware.** Read it on boot to understand what you can use.
2. **Add to it.** When you build or install something new → update this file.
3. **Mark status.** Active / Staged / Deprecated / Retired. Don't leave zombies.
4. **Cost awareness.** Ollama = free. DeepSeek = cheap. Claude = expensive + rate-limited. Choose accordingly.
5. **No Docker.** Don't design solutions that require containerization unless Nagato approves installing it.
6. **37 GB RAM.** You have headroom. Don't be shy about loading models or datasets into memory.

---

*Pre-seeded by Pain on agent rollout. Sasori owns ongoing maintenance. Last inventory: 2026-05-01 07:37 EDT.*
