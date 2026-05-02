#!/usr/bin/env bash
# Akatsuki — Workspace Migration Guide
# Copy your existing brain/data from current VM → new MSI GE66

# ── After the bootstrap runs on the new laptop, here's how to
#    bring all your data over. Run this on the NEW laptop.

# Step 1: Install Tailscale on both machines
#   New laptop:  sudo tailscale up
#   Old VM:      sudo tailscale up
#
# Step 2: Find the Tailscale IPs
#   tailscale ip -4  (run on both)

# Step 3: Rsync the workspace (run this FROM the new laptop)
#   Replace OLD_IP with the old VM's Tailscale IP
# ==============================================================
# rsync -avz --progress alfred@OLD_IP:~/.openclaw/workspace/ ~/.openclaw/workspace/
# ==============================================================
#
# This copies: AGENTS.md, SOUL.md, USER.md, memory/*,
#              business/brain/*, career-ops/*, HEARTBEAT.md

# Step 4: Only re-run doctor on career-ops
#   cd ~/.openclaw/workspace/career-ops
#   npm run doctor

# Step 5: Set up claude-worker user and auth
#   sudo useradd -m claude-worker -s /bin/bash
#   sudo passwd claude-worker
#   # Then login as claude-worker and authenticate Claude:
#   su - claude-worker
#   claude
#   # (follow OAuth flow)

# Step 6: Restart OpenClaw gateway
#   systemctl --user restart openclaw-gateway
