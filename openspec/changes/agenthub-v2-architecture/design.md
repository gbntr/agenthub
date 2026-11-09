# Design: AgentHub v2 Architecture

## Context

`agenthub` orchestrates autonomous Spec-Driven Development (SDD) across 4 AI CLI pools (`agy` Google, `agy` Anthropic, `kiro-cli`, and `copilot`) inside isolated Git Worktrees managed by Vibe Kanban on an Ubuntu Linux ARM64 VPS. See `proposal.md` for the problem statement and motivation.

Key environmental constraints shaping this design:
- **Linux ARM64 (`aarch64`) Headless VM & Multi-Worktree Concurrency**: Multiple Vibe Kanban worktrees can execute stages simultaneously. Shared state files (`~/.pipeline_quotas.json`) and ephemeral QA servers must be concurrency-safe (POSIX file locking + dynamic ephemeral TCP ports + strict process tree teardown).
- **Strict Sliding-Window & Credit Quotas**:
  - Pool 1 (`agy` Google): `gemini-3.8-flash` (`low`/`medium`/`high`) has massive quota; `gemini-4-argon` (`low`/`medium`/`high`) is capped at 25 calls per 5 hours.
  - Pool 2 (`agy` Anthropic): `claude-sonnet-5-5` and `claude-opus-5-5` (`low`/`medium`/`high`) share a strict 12 calls per 5 hours limit.
  - Pool 3 (`kiro-cli` V3): 1,000 monthly credits (`950.0` safety cap). Restricted strictly to `claude-haiku-5.5` (`0.06x`), `claude-sonnet-5.5` (`1.30x`), and `auto` (`1.00x`).
  - Pool 4 (`copilot`): Emergency fallback pool.

## Goals / Non-Goals

**Goals:**
- Decouple routing policy from Python code by combining canonical `vllm-sr` `v0.3` configuration (`config/vllm-sr/config.yaml`) with an external declarative policy (`config/routing-policy.yaml`) and cached dynamic CLI model resolution.
- Protect `~/.pipeline_quotas.json` from concurrent worktree race conditions using `fcntl.flock(LOCK_EX)`.
- Keep CLI auto-updates (`kiro-cli update -y`, `agy update`) strictly out of the critical task execution path, isolated behind `smart-agent --auto-update` (invoked only by `install.sh` or cron).
- Enforce a 6-agent pipeline (`repo-scout`, `briefing-analyst`, `spec-architect`, `code-craftsman`, `spec-auditor`, `qa-inspector`) where every agent binds explicitly to `openspec/changes/<slug>/`.
- Insert a mandatory `CODE_REVIEW` gate (`spec-auditor`) and split Stage 5 into `QA_VISUAL` (Frontend) and `QA_FUNCTIONAL` (Backend/CLI), with persistent retry tracking in `openspec/changes/<slug>/.state.json`, dynamic port allocation, and mandatory process tree teardown.
- Reduce input/output token consumption by 60%–85% using a zero-IDE Rust stack (`rtk`, `caveman`, `ast-grep`).

**Non-Goals:**
- Implementing the Obsidian Shared Vault (`.vault/` + `~/obsidian-hub/`) in this change (scheduled as Feature 5 in `docs/roadmap.md`).
- Implementing the interactive Vibe Kanban Briefing Chatbot UI in this change (scheduled as Feature 6 in `docs/roadmap.md`).
- Automatic post-QA OpenSpec archiving (`openspec archive`), since stage agents receive explicit active change directory instructions (`openspec/changes/<slug>/`).

## Decisions

### Decision 1: Two-Layer Declarative Routing + `fcntl.flock` Concurrency + Out-of-Band `--auto-update`
- **Choice**:
  1. `config/vllm-sr/config.yaml` uses the canonical `v0.3` schema (`version: v0.3`, `listeners`, `providers`, `routing.modelCards`, `routing.decisions`, `signals`) to classify `complexity`, `has_frontend_ui`, and `project_domain`, mapping them to named route decisions (`route-trivial`, `route-standard`, `route-complex`, `route-deep-arch`).
  2. `config/routing-policy.yaml` defines the stage-by-complexity candidate chains, 5-hour/monthly quota limits, Kiro credit multipliers (`claude-haiku-5.5: 0.06`, `auto: 1.00`, `claude-sonnet-5.5: 1.30`), and allowed model families.
  3. **Concurrency Safety (`fcntl.flock`)**: `core/smart-agent` wraps the entire read-modify-write transaction on `~/.pipeline_quotas.json` inside an exclusive lock (`fcntl.flock(lock_fd, fcntl.LOCK_EX)`) using `~/.pipeline_quotas.lock` so parallel worktrees never overwrite each other's counters.
  4. **Out-of-Band Auto-Update**: Normal invocations of `smart-agent` NEVER call `kiro-cli update` or `agy update`. Instead, they read `~/.cache/agenthub/models.json` with zero network latency. Only `smart-agent --auto-update` (called during `install.sh` or a scheduled cron job) runs CLI updates and refreshes the model cache.

### Decision 2: Adding `repo-scout` (Agent 0) Before High-Tier Models
- **Choice**: Introduce `repo-scout` running on `kiro-cli` `claude-haiku-5.5` (`0.06x`) or `agy` `gemini-3.8-flash-low` to generate `openspec/changes/<slug>/context-map.md` using `ast-grep` and `rtk` before `spec-architect` or `code-craftsman` runs on `STANDARD`/`COMPLEX_CODE` tasks.
- **Rationale**: Coding agents typically spend 60%–80% of their token budget searching for files and symbol definitions. Offloading discovery to a `0.06x` agent preserves the 12-call Anthropic and 25-call Argon 5-hour windows strictly for reasoning and code synthesis.

### Decision 3: Persistent Rejection Loop (`openspec/changes/<slug>/.state.json`) & Ephemeral Port/Process Teardown in QA
- **Choice**:
  - **Self-Healing Orchestration Across Vibe Kanban Profiles**: Even though Stages 3 (`APPLY`), 4 (`CODE_REVIEW`), and 5 (`QA`) exist as distinct profiles in `config/vibe-kanban/profiles.json`, whenever `smart-agent` executes `CODE_REVIEW` or `QA` and detects `STATUS: REJECTED` in `code-review-report.md` or `qa-report.md`, it reads/updates `openspec/changes/<slug>/.state.json` (under `fcntl.flock`). While `retry_count < 2`, `smart-agent` internally runs a self-healing cycle: it invokes `code-craftsman` (`APPLY`) passing the rejection report, re-runs the Zero-Token compiler gate, and re-runs the rejecting audit/QA gate automatically. If `retry_count` reaches `2` and the gate still rejects, it marks `"status": "HALTED_FOR_HUMAN"` in `.state.json` and exits non-zero so Vibe Kanban halts the card for human intervention.
  - **Dynamic Ports & Process Tree Teardown in `QA_VISUAL` / `QA_FUNCTIONAL`**: `smart-agent` allocates an unused ephemeral TCP port via Python `socket` (`bind(('127.0.0.1', 0))`) and injects `QA_PORT=<free_port>` into the `qa-inspector` environment and prompt instructions. Moreover, `smart-agent` spawns `qa-inspector` in a new process session (`start_new_session=True`) and enforces a `finally` cleanup block (plus explicit `trap 'kill $(jobs -p) 2>/dev/null || true' EXIT` rules in `qa-inspector`) to terminate any lingering web/API servers spawned on `QA_PORT` after `qa-report.md` is written.

### Decision 4: Zero-IDE Rust Token Optimization Stack (`rtk` + `caveman` + `ast-grep`)
- **Choice**: Combine `rtk` (`rtk-ai/rtk`), `caveman` (`JuliusBrussee/caveman`), and `ast-grep` (`@ast-grep/cli` + `@ast-grep/mcp`) instead of `CodeRLM` or `Serena MCP`.
- **Rationale**:
  - `CodeRLM` runs an HTTP daemon on port `:3000` (colliding with Vibe Kanban) and lacks native MCP integration.
  - `Serena MCP` spawns stateful LSP servers per worktree, consuming 300MB–1.5GB RAM on the ARM64 VM.
  - `rtk` + `ast-grep` are single-binary Rust tools with <10ms execution time and zero idle RAM consumption, while `caveman` (`lite` on Briefing/Spec, `full` on Scout/Apply/Review/QA) cuts output verbosity by 40%–65% without corrupting formal EARS requirements.

## Risks / Trade-offs

- **[Risk] Concurrent Git Worktrees corrupting `~/.pipeline_quotas.json` or colliding on localhost ports during QA** → **Mitigation**: Exclusive `fcntl.flock` lock around quota state reads/writes, dynamic ephemeral port allocation (`QA_PORT`), and process-group teardown after QA.
- **[Risk] Upstream CLI auto-update breaking mid-task execution or adding latency** → **Mitigation**: Never run `update` on normal `smart-agent` calls; restrict strictly to `smart-agent --auto-update`.
- **[Risk] Infinite rejection loops between `CODE_REVIEW`/`QA` and `APPLY` draining quotas** → **Mitigation**: Persist `retry_count` per stage in `openspec/changes/<slug>/.state.json` and hard-cap self-healing loops at `max_retries: 2`.

## Migration Plan

1. **Run 1 (Routing + Token Optimization)**:
   - Deploy `config/vllm-sr/config.yaml` (canonical `v0.3`) and `config/routing-policy.yaml`.
   - Refactor `core/smart-agent` with `fcntl.flock`, declarative routing, cached family resolver, and out-of-band `--auto-update`.
   - Install and configure `rtk`, `ast-grep` (`sg` + MCP), and Caveman rules via `install.sh` and `config/mcp/*.json`.
2. **Run 2 (Specialized Agents + Code Review & Functional/Visual QA Gates + Docs)**:
   - Deploy the 6 agent profiles in `config/agents/` and update `config/vibe-kanban/profiles.json`.
   - Wire persistent self-healing retry loops (`openspec/changes/<slug>/.state.json`), dynamic `QA_PORT` injection, and process-group teardown into `core/smart-agent` and `qa-inspector`.
   - Update `AGENTS.md`, `docs/agents-catalog.md`, `docs/roadmap.md`, `docs/architecture.md`, `docs/quota-arbitration.md`, `docs/zero-token-gates.md`, `README.md`, and `README.pt-BR.md`.
