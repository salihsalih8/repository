#!/usr/bin/env bash
# ==============================================================================
# Akatsuki — Bootstrap Script for MSI GE66 Raider
# Ubuntu 24.04 LTS Desktop → Fully Operational Akatsuki Node
#
# Hardware: i7-10875H | RTX 2070 | 64GB DDR4 | 2TB NVMe
# Purpose:  Headless-capable server running Pain, Kakuzu, Sasori, Itachi
#
# Usage:
#   1. Install Ubuntu 24.04 LTS Desktop (check "install third-party drivers")
#   2. Run this script:
#      chmod +x akatsuki-bootstrap.sh && ./akatsuki-bootstrap.sh
#
# Sections (each can be run independently):
#   ./akatsuki-bootstrap.sh           — Run everything
#   ./akatsuki-bootstrap.sh system    — System packages + updates
#   ./akatsuki-bootstrap.sh nvidia    — GPU drivers + CUDA
#   ./akatsuki-bootstrap.sh network   — Tailscale + SSH + firewall
#   ./akatsuki-bootstrap.sh docker    — Docker + nvidia-container-toolkit
#   ./akatsuki-bootstrap.sh ollama    — Local LLMs (Mistral, DeepSeek, etc.)
#   ./akatsuki-bootstrap.sh openclaw  — OpenClaw + Akatsuki agents
#   ./akatsuki-bootstrap.sh voice     — GPU whisper + Piper TTS
# ==============================================================================

set -euo pipefail
SCRIPTPATH="$(cd "$(dirname "$0")" && pwd)"
LOG="/tmp/akatsuki-bootstrap-$(date +%F).log"

# ── Color helpers ──────────────────────────────────────────────────────────────
RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'; CYAN='\033[0;36m'; NC='\033[0m'
info()  { printf "${CYAN}[INFO]${NC}  %s\n" "$*"; }
ok()    { printf "${GREEN}[OK]${NC}    %s\n" "$*"; }
warn()  { printf "${YELLOW}[WARN]${NC}  %s\n" "$*"; }
err()   { printf "${RED}[ERR]${NC}   %s\n" "$*"; exit 1; }
section() { echo ""; printf "${CYAN}══════════════════════════════════════════════════${NC}\n"; }

# ── Pre-flight ─────────────────────────────────────────────────────────────────
preflight() {
  local os_id os_ver
  os_id=$(grep ^ID= /etc/os-release | cut -d= -f2 | tr -d '"')
  os_ver=$(grep ^VERSION_ID= /etc/os-release | cut -d= -f2 | tr -d '"')
  if [[ "$os_id" != "ubuntu" || "$os_ver" != "24.04" ]]; then
    err "This script targets Ubuntu 24.04 LTS (detected: $os_id $os_ver)"
  fi
  if [[ $EUID -eq 0 ]]; then
    err "Do NOT run as root. You'll be prompted for sudo when needed."
  fi
  ok "Ubuntu 24.04 LTS detected"
}

# ── Section: System ────────────────────────────────────────────────────────────
section_system() {
  section
  info "System packages + updates"

  # Package manager updates
  sudo apt update && sudo apt upgrade -y

  # Essential packages for a server
  sudo apt install -y \
    curl wget git vim htop iotop \
    build-essential dkms \
    net-tools dnsutils traceroute mtr \
    tmux screen \
    fail2ban ufw \
    unattended-upgrades \
    ca-certificates gnupg lsb-release \
    software-properties-common \
    python3-pip python3-venv python3-dev \
    ffmpeg \
    jq tree rsync

  # Ubuntu Pro — free security subscription (extends LTS patches from 5→10 years)
  info "Attaching Ubuntu Pro (free for personal use)..."
  if command -v pro &>/dev/null; then
    sudo pro attach || warn "Ubuntu Pro attach failed (may already be attached, or run manually later)"
    info "Token: https://ubuntu.com/pro (free, no CC needed)"
    warn "Run 'sudo pro attach PASTE_TOKEN_HERE' manually if this fails"
  else
    sudo apt install -y ubuntu-advantage-tools
    warn "Reboot recommended before 'sudo pro attach'"
  fi

  # CIS hardening with Ubuntu Security Guide
  info "Applying CIS Level 1 Server hardening..."
  sudo apt install -y usg-cisbenchmark 2>/dev/null || sudo apt install -y ubuntu-security-guide 2>/dev/null
  # Apply Level 1 STIG (safe baseline — won't break functionality)
  sudo usg fix --skip-unsupported cis_level1_server 2>/dev/null || \
    warn "CIS hardening skipped (can run manually: sudo usg fix cis_level1_server)"

  # Enable automatic security updates
  sudo dpkg-reconfigure -plow unattended-upgrades

  # Disable sleep/suspend (this is a server)
  sudo systemctl mask sleep.target suspend.target hibernate.target hybrid-sleep.target

  # Harden kernel parameters
  cat << 'KERNELHARD' | sudo tee /etc/sysctl.d/99-akatsuki-hardening.conf > /dev/null
# Akatsuki security hardening
net.ipv4.tcp_syncookies = 1
net.ipv4.ip_forward = 0
net.ipv4.conf.all.rp_filter = 1
net.ipv4.conf.default.rp_filter = 1
net.ipv4.conf.all.accept_source_route = 0
net.ipv6.conf.all.accept_source_route = 0
net.ipv4.conf.all.accept_redirects = 0
net.ipv6.conf.all.accept_redirects = 0
kernel.kptr_restrict = 2
kernel.dmesg_restrict = 1
kernel.printk = 3 3 3 3
kernel.unprivileged_bpf_disabled = 1
fs.protected_hardlinks = 1
fs.protected_symlinks = 1
KERNELHARD
  sudo sysctl -p /etc/sysctl.d/99-akatsuki-hardening.conf

  ok "System packages + security hardening installed"
}

# ── Section: Nvidia + CUDA ────────────────────────────────────────────────────
section_nvidia() {
  section
  info "Nvidia drivers + CUDA (RTX 2070)"

  # Install Nvidia driver
  sudo apt install -y nvidia-driver-550 nvidia-utils-550 nvidia-cuda-toolkit

  # Install nvidia-container-toolkit for Docker GPU access
  curl -fsSL https://nvidia.github.io/libnvidia-container/gpgkey | \
    sudo gpg --dearmor -o /usr/share/keyrings/nvidia-container-toolkit-keyring.gpg
  curl -sL https://nvidia.github.io/libnvidia-container/stable/deb/nvidia-container-toolkit.list | \
    sed 's#deb https://#deb [signed-by=/usr/share/keyrings/nvidia-container-toolkit-keyring.gpg] https://#g' | \
    sudo tee /etc/apt/sources.list.d/nvidia-container-toolkit.list
  sudo apt update && sudo apt install -y nvidia-container-toolkit

  # Configure Prime to use Intel iGPU for display, RTX 2070 for compute
  # This saves ~15W power and frees the RTX entirely for CUDA workloads
  sudo apt install -y nvidia-prime
  sudo prime-select intel 2>/dev/null || true

  # Create nvidia-persistenced for compute mode
  sudo nvidia-persistenced --user nvidia-persistenced || true

  ok "Nvidia drivers + CUDA installed"
  warn "REBOOT REQUIRED before GPU will be usable by containers"
}

# ── Section: Tailscale + SSH + Firewall ───────────────────────────────────────
section_network() {
  section
  info "Tailscale + SSH + Firewall"

  # SSH hardening
  sudo apt install -y openssh-server
  sudo sed -i 's/#PermitRootLogin.*/PermitRootLogin no/' /etc/ssh/sshd_config
  sudo sed -i 's/#PasswordAuthentication.*/PasswordAuthentication no/' /etc/ssh/sshd_config
  sudo systemctl enable ssh && sudo systemctl restart ssh

  # Tailscale — secure mesh VPN for remote access
  curl -fsSL https://tailscale.com/install.sh | sh
  info "Run 'sudo tailscale up' to authenticate after script completes"

  # Firewall
  sudo ufw default deny incoming
  sudo ufw default allow outgoing
  sudo ufw allow ssh
  sudo ufw allow 18789/tcp comment 'OpenClaw gateway'
  sudo ufw --force enable

  ok "Network security configured"
}

# ── Section: Docker ───────────────────────────────────────────────────────────
section_docker() {
  section
  info "Docker + nvidia-container-toolkit"

  # Install Docker
  sudo install -m 0755 -d /etc/apt/keyrings
  curl -fsSL https://download.docker.com/linux/ubuntu/gpg | \
    sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg
  echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] \
    https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" | \
    sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
  sudo apt update && sudo apt install -y docker-ce docker-ce-cli containerd.io docker-compose-plugin
  sudo usermod -aG docker "$USER"

  # Configure nvidia runtime for Docker
  sudo nvidia-ctk runtime configure --runtime=docker
  sudo systemctl restart docker

  ok "Docker + GPU passthrough configured"
}

# ── Section: Ollama (Local LLMs) ──────────────────────────────────────────────
section_ollama() {
  section
  info "ollama — Local LLM inference on RTX 2070"

  curl -fsSL https://ollama.com/install.sh | sh

  # Configure to use GPU
  sudo systemctl enable ollama
  sudo systemctl start ollama

  # Pull models optimized for the Akatsuki brain
  ollama pull mistral              # General purpose, fast
  ollama pull nomic-embed-text     # Embeddings for brain recall
  ollama pull deepseek-coder       # Code tasks (Sasori)
  ollama pull llama3.1:8b          # Stronger reasoning
  ollama pull llama3.1:70b 2>/dev/null || \
    warn "llama3.1:70b skipped (needs ~40GB VRAM, RTX 2070 has 8GB)"

  # OpenClaw ollama backend config
  mkdir -p "$HOME/.openclaw/ollama"
  cat > "$HOME/.openclaw/ollama/config.yaml" << 'OLLAMAEOF'
providers:
  ollama:
    baseUrl: http://127.0.0.1:11434
    api: openai-completions
    models:
      - id: mistral
        name: Mistral (local)
      - id: deepseek-coder
        name: DeepSeek Coder (local)
      - id: llama3.1:8b
        name: Llama 3.1 8B (local)
      - id: nomic-embed-text
        name: Nomic Embed (local)
OLLAMAEOF

  ok "ollama installed with local models"
}

# ── Section: Voice Pipeline (GPU-accelerated) ─────────────────────────────────
section_voice() {
  section
  info "GPU-accelerated voice pipeline"

  # faster-whisper (STT) — GPU via CTranslate2
  pip3 install --user faster-whisper

  # Download model (large-v3 gives best accuracy on RTX 2070)
  python3 -c "
from faster_whisper import WhisperModel
model = WhisperModel('large-v3', device='cuda', compute_type='float16')
print('✅ faster-whisper large-v3 loaded on GPU')
" 2>&1 | tail -1

  # Piper TTS — local, fast on CPU, no GPU needed
  # Pre-built binaries
  PIPER_VER="2023.11.14-2"
  wget -q "https://github.com/rhasspy/piper/releases/download/$PIPER_VER/piper_linux_x86_64.tar.gz" -O /tmp/piper.tar.gz
  tar -xzf /tmp/piper.tar.gz -C "$HOME/.local/bin/" 2>/dev/null || \
    mkdir -p "$HOME/.local/bin" && tar -xzf /tmp/piper.tar.gz -C "$HOME/.local/bin/"
  rm -f /tmp/piper.tar.gz

  # Download default voice
  mkdir -p "$HOME/.local/share/piper-voices"
  wget -q "https://huggingface.co/rhasspy/piper-voices/resolve/main/en/en_US/ryan/medium/en_US-ryan-medium.onnx" \
    -O "$HOME/.local/share/piper-voices/en_US-ryan-medium.onnx" 2>/dev/null &
  wget -q "https://huggingface.co/rhasspy/piper-voices/resolve/main/en/en_US/ryan/medium/en_US-ryan-medium.onnx.json" \
    -O "$HOME/.local/share/piper-voices/en_US-ryan-medium.onnx.json" 2>/dev/null &

  ok "Voice pipeline installed (whisper GPU, Piper TTS)"
}

# ── Section: OpenClaw + Akatsuki ──────────────────────────────────────────────
section_openclaw() {
  section
  info "OpenClaw + Akatsuki agents"

  # Install Node.js via nvm (latest LTS)
  curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.40.0/install.sh | bash
  export NVM_DIR="$HOME/.nvm"
  [ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"
  nvm install --lts
  nvm use --lts

  # Install OpenClaw globally
  npm install -g openclaw

  # Create workspace directory
  mkdir -p "$HOME/.openclaw/workspace"

  # Run OpenClaw wizard (non-interactive, local mode)
  openclaw onboard --mode local --non-interactive 2>/dev/null || \
    openclaw init --mode local

  # Enable OpenClaw as systemd service
  mkdir -p "$HOME/.config/systemd/user"
  cat > "$HOME/.config/systemd/user/openclaw-gateway.service" << 'SERVICEEOF'
[Unit]
Description=OpenClaw Gateway — Akatsuki Brain
After=network-online.target nvidia-persistenced.service
Wants=network-online.target

[Service]
Type=simple
ExecStart=/usr/bin/node $(npm root -g)/openclaw/dist/index.js gateway --port 18789
Restart=always
RestartSec=5
Environment=OPENCLAW_GATEWAY_PORT=18789

[Install]
WantedBy=default.target
SERVICEEOF

  systemctl --user daemon-reload
  systemctl --user enable openclaw-gateway
  systemctl --user start openclaw-gateway

  # Clone Akatsuki workspace from existing repo or create fresh
  if [[ -d "$HOME/.openclaw/workspace/.git" ]]; then
    info "Workspace git repo already exists"
  else
    git init "$HOME/.openclaw/workspace"
    cat > "$HOME/.openclaw/workspace/.gitignore" << 'GIEOF'
.env.*
*.log
node_modules/
data/
output/
reports/
archive/*/events.log.gz
state.db
graph/*.db
GIEOF
    git config --global user.email "pain@akatsuki.brain"
    git config --global user.name "Pain (Akatsuki Brain)"
  fi

  # Create memory directory
  mkdir -p "$HOME/.openclaw/workspace/memory"
  mkdir -p "$HOME/.openclaw/workspace/business"

  ok "OpenClaw installed + systemd service active"
  info "Gateway: http://localhost:18789"
}

# ── Section: Development Tools ────────────────────────────────────────────────
section_devtools() {
  section
  info "Development tools for agent building"

  # Claude Code — via our wrapper approach
  # (needs Claude CLI auth, which is manual)
  sudo useradd -m claude-worker -s /bin/bash 2>/dev/null || true
  npm install -g @anthropic-ai/claude-code 2>/dev/null || \
    warn "Claude Code not installed globally (needs manual auth)"

  # Quick sanity check
  info "Running sanity check..."
  nvidia-smi 2>/dev/null | head -3 || warn "nvidia-smi failed (may need reboot)"
  ollama list 2>/dev/null | head -5 || warn "ollama not running"
  docker info 2>/dev/null | grep -i "nvidia" | head -1 || warn "Docker nvidia runtime not found"

  echo ""
  ok "────────── Akatsuki Bootstrap Complete ──────────"
  echo ""
  echo "  Next steps:"
  echo "    1. REBOOT:  sudo reboot"
  echo "    2. Tailscale:  sudo tailscale up"
  echo "    3. Clone workspace from existing VM if needed"
  echo "    4. OpenClaw gateway: http://localhost:18789"
  echo "    5. Verify GPU:  nvidia-smi"
  echo ""
}

# ── Main ──────────────────────────────────────────────────────────────────────
main() {
  preflight

  case "${1:-all}" in
    system)   section_system ;;
    nvidia)   section_nvidia ;;
    network)  section_network ;;
    docker)   section_docker ;;
    ollama)   section_ollama ;;
    openclaw) section_openclaw ;;
    voice)    section_voice ;;
    devtools) section_devtools ;;
    all)
      section_system
      section_nvidia
      section_network
      section_docker
      section_ollama
      section_voice
      section_openclaw
      section_devtools
      ;;
    *)
      echo "Usage: $0 [system|nvidia|network|docker|ollama|openclaw|voice|devtools|all]"
      exit 1
      ;;
  esac
}

main "$@" 2>&1 | tee -a "$LOG"
