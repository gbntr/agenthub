#!/usr/bin/env bash
# ==============================================================================
# AgentHub — Autonomous SDD Multi-CLI Pipeline Bootstrap Script (Waves 1 to 4)
# Target OS: Ubuntu 24.04 / 26.04 LTS (x86_64 & ARM64 / aarch64)
# ==============================================================================
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo "=================================================================="
echo "🚀 AgentHub Bootstrap: Provisioning Autonomous SDD Infrastructure"
echo "=================================================================="

# ------------------------------------------------------------------------------
# WAVE 1: System Baseline & Zero-Token Compiler Toolchains
# ------------------------------------------------------------------------------
echo "📦 [Wave 1] Installing system compilers, .NET SDK, and CLI utilities..."
sudo apt-get update -y
sudo apt-get install -y \
  build-essential \
  gcc \
  g++ \
  make \
  gdb \
  pkg-config \
  libssl-dev \
  unzip \
  curl \
  jq \
  tmux \
  ripgrep

# Install .NET SDK (10.0 or 8.0 depending on Ubuntu release)
if apt-cache show dotnet-sdk-10.0 >/dev/null 2>&1; then
  sudo apt-get install -y dotnet-sdk-10.0
elif apt-cache show dotnet-sdk-8.0 >/dev/null 2>&1; then
  sudo apt-get install -y dotnet-sdk-8.0
fi

# Install Astral uv / uvx
if ! command -v uv >/dev/null 2>&1; then
  echo "🐍 [Wave 1] Installing Astral uv & uvx..."
  curl -LsSf https://astral.sh/uv/install.sh | sh
fi
export PATH="$HOME/.local/bin:$HOME/.cargo/bin:/usr/local/bin:$PATH"

# Install Global TypeScript & TSX
echo "📘 [Wave 1] Installing TypeScript (tsc) and tsx globally..."
sudo npm install -g typescript tsx

# Create standard workspace directories
mkdir -p "$HOME/github/workspaces" "$HOME/github/tools/openspec-template"

# ------------------------------------------------------------------------------
# WAVE 2: Multi-CLI AI Pools (agy, kiro-cli, @github/copilot)
# ------------------------------------------------------------------------------
echo "🤖 [Wave 2] Checking & installing AI Agent CLIs..."

if ! command -v kiro-cli >/dev/null 2>&1; then
  echo "   -> Installing AWS Kiro CLI..."
  curl -fsSL https://cli.kiro.dev/install | bash || true
fi

if ! command -v copilot >/dev/null 2>&1; then
  echo "   -> Installing GitHub Copilot CLI (@github/copilot)..."
  sudo npm install -g @github/copilot
fi

# ------------------------------------------------------------------------------
# WAVE 3: OpenSpec SDD Governance, vLLM Semantic Router & Smart-Agent
# ------------------------------------------------------------------------------
echo "📐 [Wave 3] Installing OpenSpec CLI & vLLM Semantic Router..."
sudo npm install -g @fission-ai/openspec@latest

uv tool install vllm-sr || uv pip install --system vllm-sr || true

echo "⚙️  [Wave 3] Deploying vLLM-SR signals and Smart-Agent orchestrator..."
mkdir -p "$HOME/.vllm-sr"
cp "$REPO_ROOT/config/vllm-sr/config.yaml" "$HOME/.vllm-sr/config.yaml"
cp "$REPO_ROOT/templates/openspec/project.md" "$HOME/github/tools/openspec-template/project.md"

sudo cp "$REPO_ROOT/core/smart-agent" /usr/local/bin/smart-agent
sudo chmod +x /usr/local/bin/smart-agent
chmod +x "$REPO_ROOT/core/smart-agent" "$REPO_ROOT/core/test_all_clis.sh"

# ------------------------------------------------------------------------------
# WAVE 4: Vibe Kanban Daemon, Profiles, Headless Chromium & MCP Servers
# ------------------------------------------------------------------------------
echo "📋 [Wave 4] Configuring Vibe Kanban profiles & MCP servers..."
mkdir -p "$HOME/.vibe-kanban" "$HOME/.local/share/vibe-kanban"
cp "$REPO_ROOT/config/vibe-kanban/profiles.json" "$HOME/.vibe-kanban/profiles.json"
cp "$REPO_ROOT/config/vibe-kanban/profiles.json" "$HOME/.local/share/vibe-kanban/profiles.json"

mkdir -p "$HOME/.config/mcp" "$HOME/.copilot" "$HOME/.kiro/settings"
cp "$REPO_ROOT/config/mcp/mcp.json" "$HOME/.config/mcp/mcp.json"
cp "$REPO_ROOT/config/mcp/copilot-mcp-config.json" "$HOME/.copilot/mcp-config.json"
cp "$REPO_ROOT/config/mcp/kiro-mcp.json" "$HOME/.kiro/settings/mcp.json"

echo "🌐 [Wave 4] Installing Headless Chromium dependencies for Playwright MCP..."
sudo npx -y playwright install-deps chromium || true
npx -y playwright install chromium || true

echo "🔧 [Wave 4] Installing & enabling vibe-kanban systemd service..."
sudo cp "$REPO_ROOT/config/vibe-kanban/vibe-kanban.service" /etc/systemd/system/vibe-kanban.service
sudo systemctl daemon-reload
sudo systemctl enable vibe-kanban.service

echo "=================================================================="
echo "✅ AgentHub Provisioning Complete!"
echo "   Next steps:"
echo "   1. Authenticate CLIs if needed: 'gh auth login', 'kiro-cli login'"
echo "   2. Verify all 4 AI pools:       ./core/test_all_clis.sh"
echo "   3. Test semantic routing:       smart-agent --dry-run BRIEFING 'Create React login view'"
echo "   4. Start Vibe Kanban daemon:    sudo systemctl start vibe-kanban"
echo "=================================================================="
