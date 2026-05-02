#!/bin/bash
# Upgrade Pain — run once from the VM terminal
# Expands capabilities: OCR, stale process cleanup, data analysis

set -e

echo "=== Installing Tesseract OCR (read text from images) ==="
sudo apt-get install -y tesseract-ocr

echo ""
echo "=== Installing Python data tools ==="
sudo apt-get install -y python3-pandas python3-matplotlib
pip3 install openpyxl xlsxwriter 2>/dev/null

echo ""
echo "=== Adding sudo rule for stale process cleanup ==="
echo 'alfred ALL=(root) NOPASSWD: /usr/bin/killall' | sudo tee /etc/sudoers.d/pain-cleanup
echo 'alfred ALL=(root) NOPASSWD: /usr/bin/pkill' | sudo tee -a /etc/sudoers.d/pain-cleanup

echo ""
echo "=== Installing bubblewrap (sandboxing for Claude Code) ==="
sudo apt-get install -y bubblewrap socat

echo ""
echo "============================================"
echo "  Upgrade complete! 🛠️"
echo ""
echo "  New powers:"
echo "  - OCR: read text from screenshots"
echo "  - Data analysis: CSVs, charts, Excel"
echo "  - Process cleanup: no more stale Claude procs"
echo "  - Sandbox: Claude Code isolation"
echo ""
echo "  Restart gateway to pick up sudoers changes:"
echo "  systemctl --user restart openclaw-gateway"
echo "============================================"
