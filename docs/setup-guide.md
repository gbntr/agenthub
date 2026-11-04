# Complete Setup & Provisioning Guide (Ubuntu Linux / ARM64 & x86_64)

> **Document:** `docs/setup-guide.md`  
> **Reference Environment:** Ubuntu 24.04 / 26.04 LTS (`aarch64` Oracle Cloud Ampere A1 / `x86_64`)  
> **Automated Installer:** `./install.sh`

---

## 1. Hardware & OS Prerequisites

AgentHub is designed to run on a headless Linux VPS (such as an **Oracle Cloud Free Tier ARM64 Ampere A1** instance or any standard cloud VM) connected to your personal devices via **Tailscale**:

- **Architecture:** `aarch64` (ARM64) or `x86_64`
- **Recommended Specs:** 2+ vCPUs, 8–12 GB RAM, 40+ GB SSD
- **Operating System:** Ubuntu 24.04 LTS or Ubuntu 26.04 LTS
- **Network:** Tailscale installed and authenticated (`sudo tailscale up`)

---

## 2. Quickstart (Automated One-Command Bootstrap)

Clone the repository into `~/github/agenthub` and run the idempotent installer:

```bash
mkdir -p ~/github && cd ~/github
git clone https://github.com/gbntr/agenthub.git
cd agenthub
./install.sh
```

---

## 3. Wave-by-Wave Manual Breakdown

If you prefer to provision or audit each layer step by step, the architecture is organized into **5 decoupled waves**:

### Wave 1: System Baseline & Zero-Token Compilers
Installs C/C++ toolchains (`gcc`, `g++`, `make`, `gdb`), `.NET SDK 10.0` (or `8.0`), Astral `uv`/`uvx` for Python, and global TypeScript (`tsc`, `tsx`):

```bash
sudo apt-get update && sudo apt-get install -y \
  build-essential gcc g++ make gdb pkg-config libssl-dev \
  unzip curl jq tmux ripgrep dotnet-sdk-10.0

curl -LsSf https://astral.sh/uv/install.sh | sh
sudo npm install -g typescript tsx
```

### Wave 2: Installing & Authenticating the 4 AI CLI Pools

1. **Pool 1 & Pool 2 — Antigravity CLI (`agy`):**
   Ensure `agy` is installed in `~/.local/bin/agy` and authenticated with your Google Gemini Pro / Anthropic account.
2. **Pool 3 — AWS Kiro CLI (`kiro-cli`):**
   ```bash
   curl -fsSL https://cli.kiro.dev/install | bash
   # Authenticate on a headless VM using device flow:
   kiro-cli login --use-device-flow --license free
   ```
3. **Pool 4 — GitHub Copilot CLI (`copilot`):**
   ```bash
   gh auth login
   sudo npm install -g @github/copilot
   echo 'export GH_TOKEN="$(gh auth token 2>/dev/null)"' >> ~/.bashrc
   ```
4. **Verify All 4 Pools:**
   ```bash
   ./core/test_all_clis.sh
   ```

### Wave 3: OpenSpec SDD, Semantic Router (`vllm-sr`), and `smart-agent`

```bash
# Install OpenSpec CLI globally
sudo npm install -g @fission-ai/openspec@latest

# Install vLLM Semantic Router
uv tool install vllm-sr

# Copy semantic router config and smart-agent binary
mkdir -p ~/.vllm-sr
cp config/vllm-sr/config.yaml ~/.vllm-sr/config.yaml
sudo cp core/smart-agent /usr/local/bin/smart-agent
sudo chmod +x /usr/local/bin/smart-agent
```

Test semantic routing in dry-run mode:
```bash
smart-agent --dry-run BRIEFING "Create a responsive React login page with Tailwind CSS"
# Output: ⚡ [Smart-Agent Router] Stage=BRIEFING | Complexity=STANDARD | Domain=FULLSTACK_WEB | UI=True -> CLI=agy (gemini-3.1-pro)
```

### Wave 4: Vibe Kanban Daemon, Profiles, and Headless Playwright MCP

```bash
# Copy Vibe Kanban stage profiles
mkdir -p ~/.vibe-kanban ~/.local/share/vibe-kanban
cp config/vibe-kanban/profiles.json ~/.vibe-kanban/profiles.json
cp config/vibe-kanban/profiles.json ~/.local/share/vibe-kanban/profiles.json

# Configure MCP servers across agy, kiro-cli, and copilot
mkdir -p ~/.config/mcp ~/.copilot ~/.kiro/settings
cp config/mcp/mcp.json ~/.config/mcp/mcp.json
cp config/mcp/copilot-mcp-config.json ~/.copilot/mcp-config.json
cp config/mcp/kiro-mcp.json ~/.kiro/settings/mcp.json

# Install Headless Chromium for Playwright on ARM64 / x86_64
sudo npx -y playwright install-deps chromium
npx -y playwright install chromium

# Enable and start the Vibe Kanban systemd daemon
sudo cp config/vibe-kanban/vibe-kanban.service /etc/systemd/system/vibe-kanban.service
sudo systemctl daemon-reload
sudo systemctl enable --now vibe-kanban.service
```

### Wave 5: Initializing a New Project with OpenSpec & Vibe Kanban

To onboard any repository into the autonomous SDD pipeline:

```bash
mkdir -p ~/github/my-new-project && cd ~/github/my-new-project
git init -b main

# Initialize OpenSpec adapters for Antigravity, Copilot, Kiro, and Vibe
openspec init --tools antigravity,github-copilot,kiro,vibe

# Copy the master EARS & Zero-Token constitution
cp ~/github/agenthub/templates/openspec/project.md openspec/project.md
cp ~/github/agenthub/AGENTS.md AGENTS.md
```

Then open your Vibe Kanban board via your Tailscale IP (`http://<tailscale-ip>:3000`), add `~/github/my-new-project`, create a task card, and run **Profile 1 (`1. Briefing (Gate 1)`)**!
