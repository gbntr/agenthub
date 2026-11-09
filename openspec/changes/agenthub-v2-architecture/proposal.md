# Proposal: AgentHub v2 — Declarative Routing, Specialized SDD Agents, Code/Spec Audit Gate & Rust Token Optimization

## Why

The initial implementation of `agenthub` coupled routing logic and fake model translation dictionaries (`MODEL_MAP_AGY`, `MODEL_MAP_KIRO`) imperatively inside Python (`core/smart-agent`), lacked concurrency locking (`fcntl.flock`) on `~/.pipeline_quotas.json` across parallel Git Worktrees, and wasted limited 5-hour/monthly quotas on legacy or overpriced models. Additionally, jumping directly from local compiler checks (Zero-Token Gate) to Visual QA without an intermediate semantic Code/Spec Audit Gate, Backend Functional QA, or ephemeral port/process teardown leaves the pipeline vulnerable to specification drift, stub implementations, port collisions, and high token waste during repository exploration.

## What Changes

- **BREAKING**: Refactor `core/smart-agent` and `config/vllm-sr/config.yaml` to eliminate imperative `if/elif/else` routing trees, hardcoded regex fallbacks as primary logic, and artificial model alias maps (`MODEL_MAP_AGY`, `MODEL_MAP_KIRO`).
- **Declarative Routing, Concurrency-Safe Quotas & Out-of-Band Auto-Update**: Upgrade `config/vllm-sr/config.yaml` to canonical `vllm-sr` `v0.3` format (`providers`, `routing.modelCards`, `routing.decisions`) paired with an external declarative policy (`config/routing-policy.yaml`) and cached dynamic model family resolver:
  - Enforce `fcntl.flock(LOCK_EX)` exclusive file locking on `~/.pipeline_quotas.json` so concurrent Vibe Kanban Git Worktrees never suffer race conditions.
  - Isolate CLI updates (`kiro-cli update -y` with V3 engine and `agy update`) and model cache refreshes (`~/.cache/agenthub/models.json`) strictly behind an out-of-band `smart-agent --auto-update` flag (invoked only via `install.sh` or cron, never on the hot path of task execution).
  - Restrict AWS Kiro CLI (`kiro-cli`) exclusively to `claude-haiku-5.5` (`0.06x` credits), `claude-sonnet-5.5` (`1.30x` credits), and `auto` (`1.00x` credits), removing legacy/outdated models (`deepseek-3.2`, `qwen`, `minimax`, `glm`, `claude-haiku-4.5`).
  - Leverage Antigravity (`agy`) pools with `gemini-3.8-flash` (`low`/`medium`/`high`) for high-quota workloads, reserving 5-hour sliding-window pools (`gemini-4-argon`, `claude-sonnet-5-5`, `claude-opus-5-5`) for complex architecture, implementation, and cross-model review.
- **6 Specialized SDD Stage Agents & Master Catalog**: Define dedicated agent profiles (`config/agents/`) and document their contracts in `docs/agents-catalog.md` and `AGENTS.md`:
  0. `repo-scout` (Ultra-low-cost `0.06x` / `flash-low` AST context mapper producing `openspec/changes/<slug>/context-map.md`).
  1. `briefing-analyst` (Stage 1 `BRIEFING` — EARS `proposal.md` author).
  2. `spec-architect` (Stage 2 `SPEC` — `specs/`, `tasks.md`, `design.md`, and `ui-mockup.html` author).
  3. `code-craftsman` (Stage 3 `APPLY` — Spec-First TDD implementation and Zero-Token compiler verification).
  4. `spec-auditor` (Stage 4 `CODE_REVIEW` — Read-only adversarial code, spec, test-assertion, and dependency integrity auditor).
  5. `qa-inspector` (Stage 5 `QA` — Dual mode: `QA_VISUAL` via Playwright/Browser-Use MCP for frontend and `QA_FUNCTIONAL` black-box E2E execution for backend/CLI, enforcing dynamic ephemeral ports `QA_PORT` and mandatory process tree teardown).
  - Explicit active spec binding: Every agent receives and strictly follows the active change path `openspec/changes/<slug>/` without requiring post-merge spec archiving steps.
- **New `CODE_REVIEW` Gate, Backend `QA_FUNCTIONAL` Gate & Persistent Retry Loop**: Insert Stage 4 (`CODE_REVIEW`) between Zero-Token compiler checks (`npm`, `pip`, `tsc`, `pytest`, `gcc`, `dotnet`) and Stage 5 (`QA`). Grant both `CODE_REVIEW` (`code-review-report.md`) and `QA` (`qa-report.md`) formal rejection authority (`STATUS: REJECTED`) orchestrated via persistent retry state in `openspec/changes/<slug>/.state.json` (`max_retries: 2`).
- **Zero-IDE Rust Token Optimization Stack**: Integrate **RTK (`rtk-ai/rtk`)** for 60%–90% terminal output compression, **Caveman (`JuliusBrussee/caveman`)** response compression (`caveman lite` for Briefing/Spec to preserve formal EARS grammar; `caveman full` for Scout/Apply/Review/QA), and **`ast-grep` (`sg` CLI + `@ast-grep/mcp`)** for zero-daemon structural AST search.
- **Roadmap Documentation**: Document Future Feature 5 (*Hybrid Obsidian Shared Vault* via `.vault/` + `~/obsidian-hub/` symlinks) and Future Feature 6 (*Interactive Briefing Chatbot in Vibe Kanban*) in `docs/roadmap.md`.

## Capabilities

### New Capabilities
- `declarative-routing-and-quotas`: Declarative `vllm-sr` `v0.3` routing configuration, external quota/cost policy matrix, `fcntl.flock` concurrency-safe state persistence, out-of-band `--auto-update` CLI maintenance, cached dynamic model family resolution, and strict pool model whitelisting (`haiku-5.5` `0.06x`, `sonnet-5.5` `1.30x`, `auto` `1.00x` on Kiro; `gemini-3.8-flash`, `gemini-4-argon`, `claude-sonnet-5-5`, `claude-opus-5-5` on Agy).
- `stage-specialized-agents`: Configuration, least-privilege tool scoping, explicit active change path (`openspec/changes/<slug>/`) binding, dynamic `QA_PORT` / teardown rules, and catalog documentation for the 6 specialized SDD agents (`repo-scout`, `briefing-analyst`, `spec-architect`, `code-craftsman`, `spec-auditor`, `qa-inspector`).
- `code-review-and-qa-gates`: Post-Zero-Token semantic Code/Spec/Dependency Integrity Review gate (`CODE_REVIEW`) and dual Frontend Visual / Backend Functional E2E QA gate (`QA_VISUAL` / `QA_FUNCTIONAL`) with persistent `.state.json` self-healing rejection loops, dynamic ephemeral port allocation, and mandatory process teardown.
- `rust-token-optimization`: Token reduction pipeline combining RTK CLI output filtering, stage-aware Caveman prompt/response compression (`lite` vs. `full`), and `ast-grep` structural AST querying (`sg` CLI + MCP) with `context-map.md` pre-scouting.

### Modified Capabilities
<!-- No pre-existing specs in openspec/specs/ -->

## Impact

- **Core Orchestrator**: `core/smart-agent`, `core/test_all_clis.sh`, `install.sh`.
- **Configuration**: `config/vllm-sr/config.yaml`, `config/routing-policy.yaml` (new), `config/agents/*.json` / `.md` (new), `config/vibe-kanban/profiles.json`, `config/mcp/mcp.json`, `config/mcp/kiro-mcp.json`, `config/mcp/copilot-mcp-config.json`.
- **Governance & Documentation**: `AGENTS.md`, `templates/openspec/project.md`, `docs/agents-catalog.md` (new), `docs/roadmap.md` (new), `docs/architecture.md`, `docs/quota-arbitration.md`, `docs/zero-token-gates.md`, `README.md`, `README.pt-BR.md`.
