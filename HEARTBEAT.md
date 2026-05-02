# Heartbeat Tasks

## 🧠 Brain Health Check (run first)
- [ ] Any P0 events in events.log? If so, flag Nagato.
- [ ] Is events.log growing too fast? (>100KB = flag)
- [ ] Are there unread messages in inbox/nagato.md?
- [ ] Git status dirty for >48h?

## 📋 Daily Operations
- [ ] Check if any open decisions in decisions.md need Nagato's input
- [ ] Review tasks/pain.md for stale items (>3 days without update)
- [ ] Check if Brain-architecture-v2.md needs updating

## 🔄 Agent Pulse
- [ ] Any sub-agent tasks pending completion?
- [ ] Opus quota still available (check /tmp/.opus-quota.json)?
- [ ] Any cron failures in events.log?

## 💬 If nothing needs attention, reply: HEARTBEAT_OK
