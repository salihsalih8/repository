# Brain Architecture
**Type:** Technical System
**Owner:** [[Pain]]
**Updated:** 2026-05-01

## Directory Structure
```
business/brain/
├── agents/          # Foundation docs per agent
├── state/           # Shared state files (single-writer-per-file)
├── tasks/           # Per-agent task tracking
├── inbox/           # Inter-agent request channels
├── episodic/        # Private agent logs (write-only per agent)
├── hot/             # Generated boot digests (<800 tokens each)
├── events.log       # Published shared event log (append-only)
├── decisions.md     # Open/resolved decisions (Nagato-owned)
├── north-star.md    # Immutable constraints (Nagato-owned)
├── OWNERSHIP.md     # File authority matrix
├── AGENT-ONBOARDING.md  # Standardized agent production procedure
├── brain-write.sh   # Write wrapper with ownership enforcement
├── brain-load.sh    # Boot loader with context gating
├── brain-recall.py  # Quarantine filter
├── brain-test.sh    # Integration test suite (11/12 passing)
└── brain-eval.sh    # Recall evaluation (10 questions, 80% threshold)
```

## Key Principles
- **Single-writer-per-file:** Every file has exactly one agent that can write it
- **Private-by-default:** All output starts in episodic/<agent>.log
- **Publish gate:** brain-write.sh events.log --importance N --confidence X
- **Virtual quarantine:** Computed at read time, not mutation. confidence=high skips.
- **Importance scoring:** 1 (ephemeral) to 5 (critical, permanent + alert)
- **Warming mode:** 30 days + 3 dry runs per agent

## Scripts
- `brain-write.sh` — Enforces ownership via owner_check(), writes with frontmatter, flock + atomic rename
- `brain-load.sh` — Generates hot digests with identity, north-star, P0 events, tasks, inbox, domain context
- `brain-recall.py` — Filters events.log by quarantine expiry and importance
- `brain-test.sh` — 14 integration tests (11/12 passing)
- `brain-recover.sh` — Recovery from corruption scenarios
- `brain-graph.py` — Kuzu graph database management

## Cron Jobs
1. brain-archive-weekly — Monday 02:00
2. brain-archive-monthly — 1st 02:00
3. brain-backup-daily — Daily 03:00
4. brain-eval-monthly — 1st 06:00
5. audit-brain-health — Every 6h
6. audit-daily-consistency — Daily 03:00 (disabled, Itachi warming)
7. audit-weekly-security — Monday 06:00 (disabled)
8. audit-weekly-drift — Saturday 06:00 (disabled)
9. audit-monthly-comprehensive — 1st 04:00 (disabled)

## Related
- [[Akatsuki System]]
- [[OWNERSHIP]]
- [[Agent Onboarding Procedure]]
