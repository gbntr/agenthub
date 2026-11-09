# Tasks

## 1. Run 1 — Declarative Routing, Concurrency-Safe Quotas & Out-of-Band Auto-Update

- [x] 1.1 Upgrade `config/vllm-sr/config.yaml` to the canonical `vllm-sr` `v0.3` schema (`version: v0.3`, `listeners`, `providers`, `routing.modelCards`, `routing.decisions`, `signals`) and verify with `vllm-sr config validate --config config/vllm-sr/config.yaml`.
- [x] 1.2 Create `config/routing-policy.yaml` defining 5-hour sliding window limits (`agy_anthropic_5h_max: 12`, `agy_google_pro_5h_max: 25`), Kiro monthly credit cap (`950.0`), strict Kiro model whitelist (`claude-haiku-5.5: 0.06`, `auto: 1.00`, `claude-sonnet-5.5: 1.30`), `agy` model families (`gemini-3.8-flash`, `gemini-4-argon`, `claude-sonnet-5-5`, `claude-opus-5-5`), and stage-by-complexity candidate chains, and verify YAML syntax via Python parser.
- [x] 1.3 Refactor `core/smart-agent` to remove hardcoded `if/elif/else` routing branches and fake model maps (`MODEL_MAP_AGY`, `MODEL_MAP_KIRO`), enforce `fcntl.flock(LOCK_EX)` concurrency locking on `~/.pipeline_quotas.json`, read cached model families from `~/.cache/agenthub/models.json`, and isolate CLI updates (`kiro-cli update -y`, `agy update`) strictly behind `smart-agent --auto-update` (never on normal task calls), verifying with `core/smart-agent --dry-run` and a parallel lock stress test.
- [x] 1.4 Update `docs/quota-arbitration.md` and `core/test_all_clis.sh` to reflect declarative routing, `fcntl.flock` concurrency safety, and the Kiro model whitelist (`claude-haiku-5.5` at `0.06x`, `claude-sonnet-5.5` at `1.30x`, `auto` at `1.00x`), and verify that dry-run routing tests pass.

## 2. Run 1 — Zero-IDE Rust Token Optimization Stack (`rtk`, `caveman`, `ast-grep`)

- [x] 2.1 Update `install.sh` and `config/mcp/*.json` (`mcp.json`, `kiro-mcp.json`, `copilot-mcp-config.json`) to install and configure `rtk` (`rtk-ai/rtk`), `ast-grep` (`@ast-grep/cli` / `@ast-grep/mcp`), Caveman rules (`caveman lite` and `caveman full`), and out-of-band `smart-agent --auto-update`, and verify JSON validity with `jq . config/mcp/*.json` and shell syntax with `bash -n install.sh`.

## 3. Run 2 — Stage-Specialized SDD Agents & Master Agent Catalog

- [ ] 3.1 Create the 6 specialized agent configuration profiles in `config/agents/` (`repo-scout`, `briefing-analyst`, `spec-architect`, `code-craftsman`, `spec-auditor`, `qa-inspector`) with explicit `openspec/changes/<slug>/` path binding, least-privilege tool scoping, dynamic `QA_PORT` + mandatory process teardown instructions in `qa-inspector`, and stage-specific Caveman level (`lite` vs. `full`), and verify all 6 profile files exist and validate structurally.
- [ ] 3.2 Update `config/vibe-kanban/profiles.json` to wire all 6 stages (`0. Repo Scout`, `1. Briefing (Gate 1)`, `2. Spec + Visual Mockup (Gate 2)`, `3. Implement Code (/opsx:apply)`, `4. Code & Spec Review Gate`, `5. Visual & Functional QA (/opsx:verify)`) to `/usr/local/bin/smart-agent` with `--agent` binding, and verify valid JSON with `jq . config/vibe-kanban/profiles.json`.
- [ ] 3.3 Create `docs/agents-catalog.md` and update `AGENTS.md` and `templates/openspec/project.md` documenting the 6 agents' roles, inputs, outputs, allowed tools, active spec binding (`openspec/changes/<slug>/`), and handoff rules, and verify all markdown sections are complete.

## 4. Run 2 — Code/Spec Review Gate (`CODE_REVIEW`), Dual QA (`QA_VISUAL`/`QA_FUNCTIONAL`), Persistent Retry State & Docs

- [ ] 4.1 Implement persistent self-healing rejection loop orchestration (`STATUS: REJECTED` vs. `STATUS: APPROVED`, persisted in `openspec/changes/<slug>/.state.json` under `fcntl.flock` with `max_retries: 2`) in `core/smart-agent` so that when Stage 4 (`CODE_REVIEW`) or Stage 5 (`QA_VISUAL` / `QA_FUNCTIONAL`) rejects a change, `smart-agent` automatically invokes `code-craftsman` (`APPLY`) with the defect report and re-runs the rejecting gate (or halts with `HALTED_FOR_HUMAN` at retry 2), verifying with simulated report fixtures.
- [ ] 4.2 Implement automatic `QA_VISUAL` (`has_frontend_ui == true`) vs. `QA_FUNCTIONAL` (`has_frontend_ui == false`) dispatch, dynamic ephemeral port allocation (`QA_PORT`), and `try/finally` process-group teardown in `core/smart-agent`, and verify that spawned child processes on `QA_PORT` are terminated cleanly on exit.
- [ ] 4.3 Create `docs/roadmap.md` (documenting Future Feature 5: *Hybrid Obsidian Shared Vault* and Future Feature 6: *Interactive Briefing Chatbot in Vibe Kanban*) and update `docs/zero-token-gates.md`, `docs/architecture.md`, `README.md`, and `README.pt-BR.md` with the AgentHub v2 architecture, and verify all documentation files are synchronized.
