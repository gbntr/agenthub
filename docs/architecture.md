# Architecture Deep Dive: Autonomous SDD & Git Worktree Orchestration

> **Document:** `docs/architecture.md`  
> **Scope:** System Topology, State Machine, Git Worktree Isolation, Tailscale Mesh, and Human Approval Gates

---

## 1. Architectural Philosophy

Traditional AI-assisted coding workflows suffer from three structural failure modes when scaled to complex engineering tasks:

1. **Specification Drift & Hallucination:** Agents jump straight from a vague one-line prompt into modifying production files, producing unrequested abstractions or breaking existing contracts.
2. **Branch Contamination:** Multiple agents or iterative prompts operating directly on the working tree corrupt `main` or leave half-baked uncommitted changes.
3. **Blind UI Generation:** Agents generate frontend components without ever rendering them in a real browser DOM or comparing them against an approved visual baseline.

**AgentHub** eliminates all three failure modes by combining:
- **OpenSpec (`@fission-ai/openspec`)** for strict *"No Spec, No Code"* governance with formal **EARS** syntax.
- **Vibe Kanban (`BloopAI/vibe-kanban`)** for automated **Git Worktree** isolation per task card.
- **vLLM Semantic Router (`vllm-sr`) + `smart-agent`** for deterministic complexity/domain classification and multi-CLI quota arbitrage.
- **Playwright MCP & Browser-Use MCP** for autonomous headless Chromium visual QA against an interactive `ui-mockup.html`.
- **Tailscale** for zero-trust private mesh networking between the developer's browser and the headless cloud VM.

---

## 2. End-to-End Topology & Data Flow

```mermaid
flowchart TB
    subgraph Client["Developer Devices (Tailscale Mesh Network)"]
        Browser["Web Browser / IDE<br/>(Tailscale IP: 100.x.y.z)"]
    end

    subgraph VPS["Headless Cloud VM (Ubuntu Linux ARM64 / aarch64)"]
        TS["tailscaled Daemon<br/>(Encrypted WireGuard Tunnel)"]
        VK["Vibe Kanban Server (:3000)<br/>systemd: vibe-kanban.service"]

        subgraph GitLayer["Git Repository & Worktree Isolation"]
            MainBranch[("main branch<br/>(Protected / Clean)")]
            WT1["Git Worktree #1<br/>feature/auth-flow"]
            WT2["Git Worktree #2<br/>fix/memory-leak"]
        end

        subgraph Orchestration["Semantic Routing & Quota Arbitrator"]
            SA["/usr/local/bin/smart-agent"]
            VLLM["vLLM Semantic Router (vllm-sr)<br/>http://127.0.0.1:8080/v1/route"]
            Quotas[("~/.pipeline_quotas.json<br/>5h Sliding Window + Monthly Bucket")]
        end

        subgraph Pools["4 Multi-CLI AI Execution Pools"]
            P1["Pool 1: Google Gemini (agy)<br/>Flash 3.8 / Pro 3.1 / Argon 4"]
            P2["Pool 2: Anthropic Claude (agy)<br/>Sonnet 5.5 / Opus 5.5"]
            P3["Pool 3: AWS Kiro CLI<br/>Haiku 4.5 (0.06x-0.40x) / Qwen (0.05x) / DeepSeek (0.25x)"]
            P4["Pool 4: GitHub Copilot CLI<br/>Emergency Uncapped Fallback"]
        end

        subgraph Validation["Zero-Token & Multimodal Verification"]
            ZT["Zero-Token Local Compilers<br/>gcc/g++, dotnet 10, tsc --noEmit, pytest"]
            MCP["MCP Servers<br/>Playwright Headless Chromium + Browser-Use"]
        end
    end

    Browser <==>|"HTTP :3000 over Tailscale"| TS
    TS --> VK
    VK ==>|"Spawns Isolated Worktree"| WT1 & WT2
    WT1 & WT2 -.->|"1-Click Merge after QA"| MainBranch
    VK ==>|"Triggers Stage Profile (1..4)"| SA
    SA <-->|"Classifies Complexity / UI / Domain"| VLLM
    SA <-->|"Reads & Updates Usage"| Quotas
    SA ==>|"Dispatches Non-Interactive CLI"| P1 & P2 & P3 & P4
    P1 & P2 & P3 & P4 ==>|"Executes in Worktree"| ZT
    P1 & P2 & P3 & P4 ==>|"Visual Inspection & Screenshots"| MCP
```

---

## 3. The 5-Stage SDD State Machine & Dual Human Gates

Every task card on Vibe Kanban transitions through a deterministic 5-stage lifecycle with **two mandatory human checkpoints**:

```mermaid
stateDiagram-v2
    [*] --> CardCreated: Developer creates card in Vibe Kanban
    CardCreated --> Stage1_Briefing: Trigger Profile 1 (BRIEFING)

    state Stage1_Briefing {
        [*] --> DraftProposal: Agent drafts openspec/changes/<id>/proposal.md
        DraftProposal --> Gate1_HumanReview: Halts execution
    }

    Gate1_HumanReview --> Stage2_SpecMockup: Human approves Scope & EARS Intent
    Gate1_HumanReview --> Stage1_Briefing: Human requests scope adjustments

    state Stage2_SpecMockup {
        [*] -->SemanticRoute: smart-agent + vllm-sr classifies task
        SemanticRoute --> GenerateSpecs: /opsx:propose generates specs/, tasks.md, design.md
        GenerateSpecs --> GenerateUIMockup: If has_frontend_ui == true, creates ui-mockup.html
        GenerateSpecs --> StrictValidate: If has_frontend_ui == false
        GenerateUIMockup --> StrictValidate: openspec validate --strict
        StrictValidate --> Gate2_HumanReview: Halts for Visual & Technical Review
    }

    Gate2_HumanReview --> Stage3_Apply: Human approves Spec + Interactive Mockup
    Gate2_HumanReview --> Stage2_SpecMockup: Human requests UI/Spec tweaks

    state Stage3_Apply {
        [*] --> WorktreeExec: /opsx:apply inside isolated Git Worktree
        WorktreeExec --> ZeroTokenGate: Run tsc / gcc / dotnet test / pytest
        ZeroTokenGate --> WorktreeExec: Compiler/Test Exit Code != 0 (Self-Heal)
        ZeroTokenGate --> MarkTaskDone: Exit Code == 0 -> Marks [x] in tasks.md
    }

    MarkTaskDone --> Stage4_VisualQA: Trigger Profile 4 (QA_VISUAL)

    state Stage4_VisualQA {
        [*] --> BootDevServer: Start ephemeral preview server
        BootDevServer --> PlaywrightVerify: Headless Chromium compares DOM vs ui-mockup.html & EARS
        PlaywrightVerify --> Stage3_Apply: Visual/Functional Bug Found (Max 2 Loops)
        PlaywrightVerify --> GenerateQAReport: Writes screenshots & logs to qa-report.md
    }

    GenerateQAReport --> FinalMerge: Card moved to Final Review
    FinalMerge --> [*]: 1-Click Merge to main & Worktree Cleanup
```

---

## 4. OpenSpec Artifact Contract

When a repository is managed by AgentHub, all specification artifacts live alongside the code in a structured, version-controlled hierarchy:

```text
target-repository/
├── AGENTS.md                        # Universal rules read by agy, kiro-cli, and copilot
├── openspec/
│   ├── project.md                   # Global constitution (domain compilers, EARS rules)
│   ├── specs/                       # Single source of truth for production capabilities
│   └── changes/
│       └── <change-slug>/           # Active Vibe Kanban card folder
│           ├── proposal.md          # Stage 1 output (Gate 1 - Briefing & EARS Scope)
│           ├── ui-mockup.html       # Stage 2 output if has_frontend_ui=true (Gate 2)
│           ├── design.md            # Stage 2 output (Only for COMPLEX_CODE / DEEP_ARCH)
│           ├── tasks.md             # Stage 2/3 sequential implementation checklist (- [x])
│           ├── qa-report.md         # Stage 4 output (Playwright screenshots + console logs)
│           └── specs/               # Delta specifications (Formal EARS: WHEN ... SHALL ...)
```

---

## 5. Private Networking via Tailscale

Because Vibe Kanban (`0.0.0.0:3000`) and ephemeral preview servers provide direct control over code execution and Git worktrees, they are **never exposed to the public internet**:

- The cloud VM’s public firewall blocks inbound traffic on port `3000`.
- Developers connect over an encrypted WireGuard mesh via **Tailscale** (`http://100.x.y.z:3000`).
- This enables reviewing `proposal.md`, interacting with `ui-mockup.html` previews, approving Gate 1 / Gate 2, and triggering 1-click merges from a laptop, tablet, or smartphone anywhere in the world.
