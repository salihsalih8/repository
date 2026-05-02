# Akatsuki System
**Type:** System
**Status:** Active (4 agents deployed, 1 planned)
**Updated:** 2026-05-01

## Overview
Multi-agent operating system built on OpenClaw. Each agent has a specific role, owns state files, communicates via Telegram bots, and operates within strict security boundaries enforced through a shared brain directory.

## Active Agents
- 🛠️ [[Pain]] — Operations chief, agent handler, task orchestration
- 💰 [[Kakuzu]] — Financial heart, runway/COSS/PPC, guardrails
- 🎭 [[Sasori]] — Tool & app builder, code/deploy/maintain
- 🪬 [[Itachi]] — Audit & security sentinel, hallucination detection

## Planned
- 💥 Deidara — Brand builder, content, social, viral growth

## Core Architecture
- **Brain directory:** `business/brain/` — shared file system with ownership enforcement
- **Private-by-default:** All output starts in private episodic logs, published only when verified
- **Importance scoring:** 1-5 on all shared writes, determining visibility and lifespan
- **Quarantine:** 1h hold on medium-confidence entries before other agents act
- **Warming mode:** 30 days + 3 dry runs before any agent goes autonomous
- **Single-writer-per-file:** brain-write.sh enforces ownership

## Security Layers
1. Prevention: Hard stops, warming, ownership enforcement
2. Detection: Itachi audits (consistency, hallucination, protocol, security, drift)
3. Response: P0 bypass quarantine, simultaneous Pain+Nagato alert

## Communication
- Every agent has a Telegram bot
- Warming period: agent responds but output logged for ops review
- Post-warming: autonomous direct communication
- P0 events: alert both Pain and Nagato simultaneously

## Related
- [[Salih Salih]] (Nagato)
- [[Brain Architecture]]
- [[north-star]]
