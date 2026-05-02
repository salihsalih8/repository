#!/bin/bash
# ============================================================
# Akatsuki Setup — Claude Code + Secure User Isolation
# Run this on the VM. I'll take it from there.
# ============================================================

set -e

echo "=== Step 1: Create isolated claude-worker user ==="
sudo useradd -m -s /bin/bash claude-worker 2>/dev/null || echo "User already exists"
sudo usermod -aG claude-worker alfred

echo "=== Step 2: Create shared brain directory ==="
sudo mkdir -p /home/alfred/.openclaw/workspace/business/brain
sudo chown -R alfred:claude-worker /home/alfred/.openclaw/workspace/business/brain
sudo chmod -R 770 /home/alfred/.openclaw/workspace/business/brain

echo "=== Step 3: Install Claude Code for claude-worker ==="
sudo -u claude-worker npm install -g @anthropic-ai/claude-code 2>/dev/null || echo "Claude Code may already be installed"

echo ""
echo "============================================================"
echo "  ✅ Setup complete!"
echo ""
echo "  === NEXT: Login to Claude ==="
echo "  Run this command:"
echo ""
echo "    sudo -u claude-worker claude login"
echo ""
echo "  A browser will open (or CLI prompt). Authenticate with"
echo "  your Claude.ai account (Pro/Max subscription)."
echo ""
echo "  Once logged in, message me on Telegram and I'll"
echo "  start the conversation with Claude about our architecture."
echo "============================================================"
