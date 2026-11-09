<div align="center">

# ⚡ AgentHub

### Autonomous Spec-Driven Development (SDD) & Multi-CLI AI Agent Orchestration Hub

[![Language: English](https://img.shields.io/badge/Language-English%20🇺🇸-blue?style=for-the-badge)](./README.md)
[![Idioma: Português](https://img.shields.io/badge/Idioma-Português%20🇧🇷-green?style=for-the-badge)](./README.pt-BR.md)

[![Methodology: OpenSpec SDD](https://img.shields.io/badge/Governance-OpenSpec%20SDD%20(EARS)-6f42c1?style=flat-square)](https://github.com/Fission-AI/OpenSpec)
[![Orchestration: Vibe Kanban](https://img.shields.io/badge/Worktrees-Vibe%20Kanban-ff69b4?style=flat-square)](https://github.com/BloopAI/vibe-kanban)
[![Routing: vLLM-SR](https://img.shields.io/badge/Router-vLLM%20Semantic%20Router-00a67e?style=flat-square)](https://github.com/vllm-project/semantic-router)
[![Network: Tailscale Mesh](https://img.shields.io/badge/Network-Tailscale%20Zero--Trust-24292e?style=flat-square)](https://tailscale.com/)
[![QA: Playwright MCP](https://img.shields.io/badge/Visual%20QA-Playwright%20%26%20Browser--Use%20MCP-2ead33?style=flat-square)](https://github.com/microsoft/playwright-mcp)
[![Platform: Ubuntu ARM64](https://img.shields.io/badge/Platform-Linux%20ARM64%20%7C%20x86__64-E95420?style=flat-square)](./docs/setup-guide.md)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg?style=flat-square)](./LICENSE)

*A production-grade, self-hosted autonomous software engineering pipeline that eliminates AI hallucination, branch pollution, and quota exhaustion through formal EARS specifications, isolated Git Worktrees, semantic multi-CLI routing, Zero-Token compiler gates, and headless browser Visual QA.*

</div>

---

## 📖 Table of Contents

1. [Why AgentHub? (The Engineering Problem)](#-1-why-agenthub-the-engineering-problem)
2. [Core Architectural Pillars](#-2-core-architectural-pillars)
3. [System Architecture & Mermaid Workflows](#-3-system-architecture--mermaid-workflows)
   - [3.1. End-to-End Infrastructure & Network Topology](#31-end-to-end-infrastructure--network-topology)
   - [3.2. The 5-Stage SDD State Machine & Human Approval Gates](#32-the-5-stage-sdd-state-machine--human-approval-gates)
   - [3.3. Semantic Router & 4-Pool Quota Arbitrage Decision Tree](#33-semantic-router--4-pool-quota-arbitrage-decision-tree)
4. [Ecosystem & Integrated Repositories Deep Dive](#-4-ecosystem--integrated-repositories-deep-dive)
5. [Multi-CLI Quota Arbitrage Matrix](#-5-multi-cli-quota-arbitrage-matrix)
6. [Zero-Token Compiler Gates & Autonomous Visual QA](#-6-zero-token-compiler-gates--autonomous-visual-qa)
7. [Repository Structure](#-7-repository-structure)
8. [Quickstart & Installation](#-8-quickstart--installation)
9. [Detailed Documentation](#-9-detailed-documentation)

---

## 🎯 1. Why AgentHub? (The Engineering Problem)

Unstructured "vibe coding" with autonomous AI agents breaks down rapidly on real-world software projects due to four predictable failure modes:

1. **Hallucination & Scope Creep:** Jumping directly from a brief prompt to code generation causes agents to invent unrequested abstractions, break architectural boundaries, or miss edge cases.
2. **Working Tree Contamination:** Running multiple coding agents directly on `main` or a shared working directory leads to tangled diffs and broken builds.
3. **Quota Exhaustion & Rate Limits:** Burning expensive frontier reasoning calls (`Claude Opus 5.5` / `Sonnet 5.5`) on trivial tasks (fixing typos, updating checklists, reading logs) exhausts strict 5-hour sliding windows within minutes.
4. **Blind Frontend Implementation:** Agents write React/HTML/Tailwind components without rendering them in a real browser DOM or comparing them against a human-approved visual prototype.

**AgentHub** solves these challenges by turning a headless Linux cloud VM into an **Autonomous Spec-Driven Engineering Hub** accessible securely from anywhere over **Tailscale**.

---

## 🏛️ 2. Core Architectural Pillars

- **📐 Strict SDD Governance (*No Spec, No Code*):** Powered by **OpenSpec (`@fission-ai/openspec`)**. Agents are forbidden from writing implementation code until formal **EARS (Easy Approach to Requirements Syntax)** specifications and an interactive **UI Mockup (`ui-mockup.html`)** pass two mandatory human approval gates (**Gate 1: Briefing** and **Gate 2: Spec + Visual Mockup**).
- **⚖️ Semantic Multi-CLI Quota Arbitrage:** Powered by **`vllm-sr`** and [`core/smart-agent`](./core/smart-agent). Tasks are dynamically classified by complexity (`TRIVIAL`, `STANDARD`, `COMPLEX_CODE`, `DEEP_ARCH`), domain, and UI impact, routing execution across **4 independent AI CLI pools** (`agy` Google Gemini, `agy` Anthropic Claude, AWS `kiro-cli`, and GitHub `copilot` CLI) with a 5-hour sliding-window quota tracker (`~/.pipeline_quotas.json`) and cascading fallbacks.
- **🌿 Complete Git Worktree Isolation:** Powered by **Vibe Kanban**. Every task card spawns an isolated **Git Worktree** and dedicated feature branch. The `main` branch remains untouched until all checks pass and the developer clicks **Merge**.
- **🛡️ Zero-Token Gates & Multimodal Visual QA:** Code is validated locally using zero-token static analyzers and compilers (`tsc --noEmit`, `gcc/g++ -Wall -Werror`, `dotnet test`, `pytest`) followed by headless Chromium inspection via **Playwright MCP** and **Browser-Use MCP**, comparing the live application against the approved `ui-mockup.html`.

---

## 🗺️ 3. System Architecture & Mermaid Workflows

### 3.1. End-to-End Infrastructure & Network Topology

```mermaid
flowchart TB
    subgraph Client["Developer Devices (Anywhere via Tailscale)"]
        User(["Developer Browser / Workstation<br/>Tailscale Mesh IP (100.x.y.z)"])
    end

    subgraph VPS["Headless Cloud VM (Ubuntu Linux ARM64 / aarch64)"]
        TS["Tailscale WireGuard Tunnel<br/>(Zero Public Ports Exposed)"]
        VK["Vibe Kanban Daemon (:3000)<br/>Git Worktree Manager & Preview UI"]

        subgraph Worktrees["Isolated Git Worktrees (/home/ubuntu/github/...)"]
            Main[("main branch<br/>Always Green")]
            WT["Isolated Task Worktree<br/>openspec/changes/<slug>/"]
        end

        subgraph Brain["Semantic Routing & Quota Arbitrator"]
            SA["smart-agent Orchestrator<br/>(/usr/local/bin/smart-agent)"]
            SR["vLLM Semantic Router (vllm-sr)<br/>(:8080/v1/route + Regex Fallback)"]
            DB[("~/.pipeline_quotas.json<br/>5h Sliding Window & Credit Tracker")]
        end

        subgraph Pools["4 Multi-CLI AI Execution Pools"]
            P1["Pool 1: Google Gemini (agy)<br/>Flash 3.8 | Argon 4"]
            P2["Pool 2: Anthropic Claude (agy)<br/>Sonnet 5.5 | Opus 5.5"]
            P3["Pool 3: AWS Kiro CLI (kiro-cli)<br/>Haiku 5.5 (0.06x) | Auto (1.00x) | Sonnet 5.5 (1.30x)"]
            P4["Pool 4: GitHub Copilot CLI (copilot)<br/>Tier-2 Emergency Fallback"]
        end

        subgraph Verification["Zero-Token & Multimodal QA Layer"]
            ZT["Zero-Token Local Compilers<br/>GCC 15 / .NET 10 / TypeScript 7 / Pytest"]
            MCP["Headless Chromium ARM64<br/>Playwright MCP + Browser-Use MCP"]
        end
    end

    User <==>|"Private HTTP :3000"| TS
    TS --> VK
    VK ==>|"Creates & Manages"| WT
    WT -.->|"1-Click Merge"| Main
    VK ==>|"Dispatches Stage Profile (1..4)"| SA
    SA <-->|"Extracts Signals"| SR
    SA <-->|"Reads/Writes Quotas"| DB
    SA ==>|"Routes by Complexity & Quota"| P1 & P2 & P3 & P4
    P1 & P2 & P3 & P4 ==>|"Writes Specs & Code"| WT
    P1 & P2 & P3 & P4 ==>|"Runs Local Build/Test"| ZT
    P1 & P2 & P3 & P4 ==>|"Renders & Compares UI"| MCP
```

---

### 3.2. The 5-Stage SDD State Machine & Human Approval Gates

```mermaid
flowchart TD
    Card(["1. Developer Creates Card in Vibe Kanban"]) --> P1["Profile 1: BRIEFING<br/>(smart-agent BRIEFING)"]
    P1 --> Prop["Generates openspec/changes/<slug>/proposal.md<br/>(Scope, Out-of-Scope & EARS Overview)"]
    Prop --> G1{"🛑 HUMAN GATE 1<br/>Approve Briefing?"}

    G1 -- "Request Changes" --> P1
    G1 -- "Approved" --> P2["Profile 2: SPEC + VISUAL MOCKUP<br/>(smart-agent SPEC -> /opsx:propose)"]

    P2 --> CheckUI{"has_frontend_ui == true?"}
    CheckUI -- "Yes (Injected Rule)" --> GenUI["Generates specs/, tasks.md, design.md<br/>+ Interactive ui-mockup.html (Tailwind CDN)"]
    CheckUI -- "No (Backend / Systems)" --> GenSpec["Generates specs/, tasks.md, design.md"]

    GenUI & GenSpec --> StrictVal["Runs: openspec validate --strict"]
    StrictVal --> G2{"🛑 HUMAN GATE 2<br/>Approve Specs & UI Mockup?"}

    G2 -- "Adjust Spec / UI" --> P2
    G2 -- "Approved Visually" --> P3["Profile 3: IMPLEMENT CODE<br/>(smart-agent APPLY -> /opsx:apply in Git Worktree)"]

    P3 --> LoopTask["Implements Next Item in tasks.md"]
    LoopTask --> ZTGate{"Zero-Token Compiler Gate<br/>(tsc / gcc / dotnet / pytest)<br/>Exit Code == 0?"}
    ZTGate -- "No (Compiler Error)" --> LoopTask
    ZTGate -- "Yes (Pass)" --> CheckMore{"More Unchecked [ ]<br/>Items in tasks.md?"}
    CheckMore -- "Yes" --> LoopTask
    CheckMore -- "No (All [x])" --> P4["Profile 4: VISUAL QA & VERIFICATION<br/>(smart-agent QA_VISUAL -> /opsx:verify)"]

    P4 --> BrowserQA["Starts App via dev-manager-mcp<br/>Playwright MCP + Browser-Use MCP Inspects Live DOM"]
    BrowserQA --> CompareQA{"Matches ui-mockup.html<br/>& EARS Scenarios?"}
    CompareQA -- "Bug Found (Max 2 Self-Heal Loops)" --> P3
    CompareQA -- "Verified (Pass)" --> Report["Saves Screenshots & Logs to qa-report.md"]
    Report --> Merge(["✅ Final Human Review & 1-Click Merge to main"])
```

---

### 3.3. Semantic Router & 4-Pool Quota Arbitrage Decision Tree

```mermaid
flowchart LR
    Prompt(["Task Prompt + Stage"]) --> Classifier["vllm-sr (:8080/v1/route)<br/>or Local Regex Classifier"]
    Classifier --> StageCheck{"Stage == QA_VISUAL<br/>or UI_MOCKUP?"}

    StageCheck -- Yes --> Pool1_Flash["Pool 1: agy<br/>gemini-3.8-flash"]
    StageCheck -- No --> CompCheck{"Complexity Signal"}

    CompCheck -- TRIVIAL --> KiroHaiku["Pool 3: kiro-cli<br/>claude-haiku-5.5 (0.06x)"]
    CompCheck -- STANDARD --> Pool1_Pro["Pool 1: agy<br/>gemini-4-argon-medium<br/>(Fallback: kiro auto 1.00x)"]
    CompCheck -- COMPLEX_CODE --> Pool2_Sonnet["Pool 2: agy<br/>claude-sonnet-5.5<br/>(Fallback: gemini-4-argon -> kiro sonnet)"]
    CompCheck -- DEEP_ARCH --> Pool2_Opus["Pool 2: agy<br/>claude-opus-5.5<br/>(Fallback: gemini-4-argon)"]

    Pool1_Flash & KiroHaiku & Pool1_Pro & Pool2_Sonnet & Pool2_Opus --> Exec{"Primary CLI<br/>Exit Code == 0?"}
    Exec -- Yes --> Done(["Update ~/.pipeline_quotas.json"])
    Exec -- No --> FB1["Tier-1 Fallback:<br/>kiro-cli (claude-haiku-5.5)"]
    FB1 --> FB1_Check{"Exit Code == 0?"}
    FB1_Check -- Yes --> Done
    FB1_Check -- No --> FB2["Tier-2 Emergency Fallback:<br/>GitHub Copilot CLI (copilot -p)"]
```

---

## 🧩 4. Ecosystem & Integrated Repositories Deep Dive

AgentHub unifies best-in-class open-source tools and commercial AI CLIs into a single cohesive platform:

### 1. [Vibe Kanban](https://github.com/BloopAI/vibe-kanban) (`BloopAI/vibe-kanban`)
- **Role:** Visual Orchestration Board, Git Worktree Manager & Preview Server.
- **How it's used in AgentHub:** Runs persistently as a headless `systemd` service ([`vibe-kanban.service`](./config/vibe-kanban/vibe-kanban.service)) on port `3000`. Configured via [`profiles.json`](./config/vibe-kanban/profiles.json) with 4 custom execution profiles that invoke `/usr/local/bin/smart-agent` for each stage of the SDD lifecycle (`BRIEFING`, `SPEC`, `APPLY`, `QA_VISUAL`). Whenever a card is started, Vibe Kanban automatically creates an isolated Git Worktree so multiple agents can code in parallel without polluting `main`. Also exposed as an MCP server (`npx -y vibe-kanban --mcp`).

### 2. [vLLM Semantic Router (`vllm-sr`)](https://github.com/vllm-project/semantic-router)
- **Role:** Low-latency Semantic Classification & Signal Extraction.
- **How it's used in AgentHub:** Configured via [`config/vllm-sr/config.yaml`](./config/vllm-sr/config.yaml) to evaluate incoming task descriptions on `http://127.0.0.1:8080/v1/route` and emit three structured signals:
  - `complexity`: `TRIVIAL` | `STANDARD` | `COMPLEX_CODE` | `DEEP_ARCH`
  - `has_frontend_ui`: `true` | `false` (triggers automatic injection of the `ui-mockup.html` Tailwind prototype requirement)
  - `project_domain`: `FULLSTACK_WEB` | `UNIVERSITY_C_CPP_CSHARP` | `DOCS_ONLY`
- **Resilience:** If the `vllm-sr` daemon is stopped to save RAM, [`core/smart-agent`](./core/smart-agent) transparently falls back to an embedded zero-latency bilingual (EN/PT-BR) word-boundary (`\b`) regex classifier.

### 3. [OpenSpec](https://github.com/Fission-AI/OpenSpec) (`@fission-ai/openspec`)
- **Role:** Spec-Driven Development (SDD) Governance & Artifact Validation.
- **How it's used in AgentHub:** Enforces a strict contract inside `openspec/changes/<change-id>/` (`proposal.md`, `specs/`, `design.md`, `tasks.md`, `ui-mockup.html`, `qa-report.md`). Initialized across repositories with multi-agent adapters (`openspec init --tools antigravity,github-copilot,kiro,vibe`) and governed by our master constitution template ([`templates/openspec/project.md`](./templates/openspec/project.md)) requiring formal **EARS** syntax (`WHEN <trigger>, the system SHALL <response>`) and strict schema validation (`openspec validate --strict`).

### 4. [Tailscale](https://tailscale.com/)
- **Role:** Zero-Trust WireGuard Mesh Network.
- **How it's used in AgentHub:** Connects the developer's laptop/phone directly to the headless cloud VPS (`100.x.y.z`). Enables private access to the Vibe Kanban web UI (`:3000`), interactive inspection of `ui-mockup.html` previews, and live dev servers without exposing a single port on the public internet firewall.

### 5. [Playwright MCP](https://github.com/microsoft/playwright-mcp) & [Browser-Use MCP](https://github.com/browser-use/browser-use)
- **Role:** Autonomous Headless Browser Automation & Multimodal Visual QA.
- **How it's used in AgentHub:** Registered globally across all agent CLIs via [`config/mcp/mcp.json`](./config/mcp/mcp.json) running against ARM64 Headless Chromium. During Stage 4 (`QA_VISUAL`), the agent boots the web app, navigates through the EARS user flows in headless Chromium, captures Desktop/Mobile screenshots, checks console/network logs, and compares the live DOM against the Gate 2 `ui-mockup.html`.

### 6. Multi-CLI Execution Engines (`agy`, `kiro-cli`, `copilot`)
- **Antigravity CLI (`agy`):** Executes Google Gemini (`gemini-3.8-flash`, `gemini-4-argon`) and Anthropic Claude (`claude-sonnet-5.5`, `claude-opus-5.5`) non-interactively (`agy -p "<prompt>" --model <model> --dangerously-skip-permissions`).
- **AWS Kiro CLI (`kiro-cli`):** Executes ultra-low-cost credit-multiplied models (`claude-haiku-5.5` @ `0.06x`, `auto` @ `1.00x`, `claude-sonnet-5.5` @ `1.30x` (strict whitelist in `config/routing-policy.yaml`)) via `kiro-cli chat --no-interactive --trust-all-tools`.
- **GitHub Copilot CLI (`@github/copilot`):** Provides an uncapped emergency safety net (`copilot -p "<prompt>" -s --allow-all`) authenticated seamlessly via `GH_TOKEN="$(gh auth token)"`.

---

## 📊 5. Multi-CLI Quota Arbitrage Matrix

`smart-agent` tracks usage in `~/.pipeline_quotas.json` using a **5-hour sliding window** (`18,000s`) for `agy` pools and a **monthly credit counter** for `kiro-cli`:

| Task Classification / Stage | Primary Pool & Model | Quota Window / Cost | Automatic Fallback Chain |
| :--- | :--- | :--- | :--- |
| **`QA_VISUAL` / `UI_MOCKUP`** | **Pool 1 (`agy`):** `gemini-3.8-flash` | High-Quota Multimodal Pool | `kiro-cli` (`claude-haiku-5.5`) $\rightarrow$ `copilot` |
| **`TRIVIAL`**<br>*(Typos, logs, README, rename)* | **Pool 3 (`kiro-cli`):** `claude-haiku-5.5` | **0.06x** of 1,000 monthly credits | `agy` (`gemini-3.8-flash`) $\rightarrow$ `copilot` |
| **`STANDARD`**<br>*(Specs, routine features, tests)* | **Pool 1 (`agy`):** `gemini-4-argon-medium` | Max **25 calls / 5h window** | `kiro-cli` (`auto` @ **1.00x**) $\rightarrow$ `agy` (`gemini-3.8-flash`) |
| **`COMPLEX_CODE`**<br>*(Refactors, concurrency, DB, C/C++)* | **Pool 2 (`agy`):** `claude-sonnet-5.5` | Max **12 calls / 5h window** | `agy` (`gemini-4-argon`) $\rightarrow$ `kiro-cli` (`claude-sonnet-5.5`) |
| **`DEEP_ARCH`**<br>*(System-wide architecture, deadlocks)* | **Pool 2 (`agy`):** `claude-opus-5.5` | Shared **12 calls / 5h window** | `agy` (`gemini-4-argon`) $\rightarrow$ `kiro-cli` $\rightarrow$ `copilot` |

---

## 🛡️ 6. Zero-Token Compiler Gates & Autonomous Visual QA

Before an agent can check off an item in `tasks.md` or request human review, it must pass deterministic local verification that consumes **zero LLM tokens**:

| Project Domain (`project_domain`) | Mandatory Zero-Token Gate Commands | Visual QA (`QA_VISUAL`) |
| :--- | :--- | :--- |
| **`FULLSTACK_WEB`**<br>*(TypeScript, React, Node, Python)* | `npx tsc --noEmit && npm test -- --passWithNoTests && pytest` | **Required** if `has_frontend_ui == true` (Playwright MCP vs `ui-mockup.html`) |
| **`UNIVERSITY_C_CPP_CSHARP`**<br>*(C17, C++20, .NET 10 / C#)* | `gcc/g++ -Wall -Wextra -Werror -fsanitize=address,undefined` & `make test`<br>or `dotnet build --nologo -v q && dotnet test --nologo -v q` | **Skipped** (`has_frontend_ui == false`) |
| **`DOCS_ONLY`**<br>*(Specifications & Architecture)* | `openspec validate --strict` | **Skipped** |

---

## 📂 7. Repository Structure

```text
agenthub/
├── README.md                          # Comprehensive English documentation (You are here)
├── README.pt-BR.md                    # Complete Portuguese (PT-BR) documentation
├── LICENSE                            # MIT License
├── AGENTS.md                          # Universal operating instructions for AI coding agents
├── install.sh                         # Idempotent one-command bootstrap script (Waves 1 to 4)
│
├── core/                              # Core orchestration & verification executables
│   ├── smart-agent                    # Semantic router, 5h quota manager, UI rule injector & fallback engine
│   └── test_all_clis.sh               # Automated E2E health check for all 4 AI CLI pools (POOL1..POOL4)
│
├── config/                            # Production configuration templates
│   ├── vibe-kanban/
│   │   ├── profiles.json              # 4 Vibe Kanban SDD Stage Profiles (Briefing, Spec+UI, Apply, Visual QA)
│   │   └── vibe-kanban.service        # Systemd unit running Vibe Kanban on 0.0.0.0:3000
│   ├── mcp/
│   │   ├── mcp.json                   # Unified MCP servers (vibe-kanban, playwright, browser-use)
│   │   ├── copilot-mcp-config.json    # GitHub Copilot CLI MCP configuration
│   │   └── kiro-mcp.json              # AWS Kiro CLI MCP settings
│   └── vllm-sr/
│       └── config.yaml                # vLLM Semantic Router classification signal definitions
│
├── templates/                         # Spec-Driven Development (SDD) governance templates
│   └── openspec/
│       └── project.md                 # Master OpenSpec constitution (EARS syntax & Zero-Token Gates)
│
├── examples/                          # Homologated real-world pilot repositories
│   └── pipeline-pilot/                # Complete working SDD pilot with specs, mockups & QA reports
│
└── docs/                              # In-depth technical documentation
    ├── architecture.md                # State machine, Git Worktree isolation & Tailscale mesh topology
    ├── quota-arbitration.md           # 4-Pool routing matrix, Kiro credit multipliers & 5h sliding window
    ├── zero-token-gates.md            # Domain-specific compiler gates & Playwright MCP Visual QA flow
    ├── e2e-walkthrough.md             # End-to-end homologation evidence & 5-stage execution report
    └── setup-guide.md                 # Step-by-step cloud VM provisioning guide (Waves 1 to 5)
```

---

## 🚀 8. Quickstart & Installation

### 1. Bootstrap the VM Infrastructure
Clone `agenthub` onto your Ubuntu Linux VM (`aarch64` or `x86_64`) and run the automated installer:

```bash
mkdir -p ~/github && cd ~/github
git clone https://github.com/gbntr/agenthub.git
cd agenthub
./install.sh
```

### 2. Verify All 4 AI CLI Pools
Ensure `agy`, `kiro-cli`, and `copilot` (`gh auth login`) are authenticated, then run the automated pool validator:

```bash
./core/test_all_clis.sh
```
```text
==================================================
   AGENTHUB: 4-POOL AI CLI HEALTH CHECK (WAVE 2)  
==================================================
Testing Pool 1 (Google Gemini via agy)... ✅ [PASS] (POOL1_OK)
Testing Pool 2 (Anthropic Claude via agy)... ✅ [PASS] (POOL2_OK)
Testing Pool 3 (AWS Kiro CLI / Amazon Q)... ✅ [PASS] (POOL3_OK)
Testing Pool 4 (GitHub Copilot CLI)... ✅ [PASS] (POOL4_OK)
==================================================
🎉 ALL 4 AI POOLS ARE OPERATIONAL AND VERIFIED!
==================================================
```

### 3. Test the Semantic Router (`smart-agent`)
Simulate task routing across different complexities and domains without consuming tokens using `--dry-run`:

```bash
# Frontend UI Task -> Injects UI Mockup Rule & routes to Gemini Pro / Argon
smart-agent --dry-run BRIEFING "Create a responsive React dashboard widget with Tailwind CSS"

# Trivial Task -> Routes to low-cost Kiro CLI (Haiku / Qwen)
smart-agent --dry-run APPLY "Fix typo in README checklist"

# Complex Systems Task -> Routes to Anthropic Claude Sonnet 5.5
smart-agent --dry-run APPLY "Refactor C++ thread pool concurrency lock and database migration"
```

### 4. Access Vibe Kanban via Tailscale
Open your browser on any device connected to your Tailscale network:
```text
http://<your-tailscale-ip>:3000
```

---

## 📚 9. Detailed Documentation

For deeper technical specifications, explore the `docs/` directory:

- **[Architecture & State Machine (`docs/architecture.md`)](./docs/architecture.md)** — Detailed breakdown of Git Worktree isolation, the 5-stage SDD lifecycle, OpenSpec directory contracts, and Tailscale zero-trust networking.
- **[Semantic Quota Arbitrage (`docs/quota-arbitration.md`)](./docs/quota-arbitration.md)** — Complete routing matrix, Kiro credit multipliers (`0.05x` to `1.30x`), 5-hour sliding window math, and cascading fallback logic.
- **[Zero-Token Gates & Visual QA (`docs/zero-token-gates.md`)](./docs/zero-token-gates.md)** — Compiler flags for Web/TypeScript, C/C++ Sanitizers, .NET 10, and the Playwright/Browser-Use MCP visual inspection sequence.
- **[E2E Pilot Walkthrough (`docs/e2e-walkthrough.md`)](./docs/e2e-walkthrough.md)** — Complete step-by-step homologation report of the 5-stage SDD lifecycle on `examples/pipeline-pilot/` with 100% EARS scenarios passed.
- **[Cloud VM Setup Guide (`docs/setup-guide.md`)](./docs/setup-guide.md)** — Wave-by-wave provisioning instructions (Waves 1 through 5) for Ubuntu Linux ARM64 / Oracle Cloud.

---

<div align="center">

**Designed & Engineered by [Guilherme Bento Ramos (`gbntr`)](https://github.com/gbntr)**  
*Released under the [MIT License](./LICENSE).*

</div>
