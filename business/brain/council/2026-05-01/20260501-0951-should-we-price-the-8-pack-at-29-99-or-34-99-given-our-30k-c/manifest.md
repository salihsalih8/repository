# Council Session Manifest
**Session:** 20260501-0951
**Convened:** 2026-05-01 09:51 EDT
**Convened by:** pain
**Priority:** P2
**Rounds:** 2

## Question
Should we price the 8-pack at $29.99 or $34.99 given our $30K capital and Healspot displacement target?

## Council Members
- **Kakuzu** — cash, margins, unit economics, ROAS, burn, pricing, credit, runway
- **Sasori** — code, architecture, deployment, tech stack, automation, tools, infrastructure

## Deliberation Protocol
1. **Round 1** — Independent domain analysis. Agents flag questions for each other.
2. **Round 2** — Debate. Agents read all analyses, respond to questions, challenge, refine, find consensus.
3. **Pain synthesizes** — Reads all rounds, produces unified recommendation for Nagato.

## Spawn Instructions

### Round 1 — Spawn each agent:
- sessions_spawn(agentId="kakuzu", task="$(cat /home/alfred/.openclaw/workspace/business/brain/council/2026-05-01/20260501-0951-should-we-price-the-8-pack-at-29-99-or-34-99-given-our-30k-c/prompt-kakuzu-r1.md)", mode="run")
- sessions_spawn(agentId="sasori", task="$(cat /home/alfred/.openclaw/workspace/business/brain/council/2026-05-01/20260501-0951-should-we-price-the-8-pack-at-29-99-or-34-99-given-our-30k-c/prompt-sasori-r1.md)", mode="run")

### Round 2 — After all R1 responses, spawn each agent:
- sessions_spawn(agentId="kakuzu", task="$(cat /home/alfred/.openclaw/workspace/business/brain/council/2026-05-01/20260501-0951-should-we-price-the-8-pack-at-29-99-or-34-99-given-our-30k-c/prompt-kakuzu-r2.md)", mode="run")
- sessions_spawn(agentId="sasori", task="$(cat /home/alfred/.openclaw/workspace/business/brain/council/2026-05-01/20260501-0951-should-we-price-the-8-pack-at-29-99-or-34-99-given-our-30k-c/prompt-sasori-r2.md)", mode="run")

### Synthesize:
- brain-council-synthesize.sh /home/alfred/.openclaw/workspace/business/brain/council/2026-05-01/20260501-0951-should-we-price-the-8-pack-at-29-99-or-34-99-given-our-30k-c
