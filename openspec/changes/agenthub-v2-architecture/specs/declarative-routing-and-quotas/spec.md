# Spec: Declarative Routing and Quotas

## Purpose

Defines the declarative semantic routing architecture (`vllm-sr` `v0.3`), external quota/cost arbitrage policy, concurrency-safe state persistence (`fcntl.flock`), out-of-band CLI auto-update enforcement (`--auto-update`), dynamic model family resolution, and strict pool model whitelisting across all 4 AI execution pools.

## ADDED Requirements

### Requirement: Declarative vLLM Semantic Router Configuration
The system SHALL define task classification signals, model cards, and prioritized routing decisions declaratively inside `config/vllm-sr/config.yaml` conforming to the canonical `vllm-sr` `v0.3` schema (`version: v0.3`, `providers`, `routing.modelCards`, `routing.decisions`, `signals`).

#### Scenario: Schema validation of router configuration
- **WHEN** `vllm-sr config validate --config config/vllm-sr/config.yaml` is executed
- **THEN** the validator exits with status code `0` and confirms compliance with the `vllm-sr` `v0.3` contract

#### Scenario: Multi-candidate route selection by stage and complexity
- **WHEN** a task prompt and pipeline stage (`SCOUT`, `BRIEFING`, `SPEC`, `APPLY`, `CODE_REVIEW`, `QA_VISUAL`, `QA_FUNCTIONAL`) are evaluated against the declarative routing rules
- **THEN** the router returns an ordered list of candidate `modelRefs` prioritized by cost efficiency and reasoning capability without relying on hardcoded `if/elif/else` model branches in Python

### Requirement: Externalized Routing Policy and Zero Artificial Model Maps
The system SHALL load quota limits, credit cost multipliers, and stage-by-complexity candidate chains from an external declarative configuration file (`config/routing-policy.yaml`) and SHALL NOT contain hardcoded fake model translation dictionaries (`MODEL_MAP_AGY`, `MODEL_MAP_KIRO`) in `core/smart-agent`.

#### Scenario: Updating model weights or quota thresholds without code modifications
- **WHEN** an operator modifies a credit multiplier, 5-hour sliding window cap, or candidate order in `config/routing-policy.yaml`
- **THEN** `smart-agent` immediately applies the updated routing policy on the next invocation without requiring changes to Python source code

### Requirement: Concurrency-Safe Quota State Persistence via File Locking
The system SHALL acquire an exclusive POSIX file lock (`fcntl.flock` with `LOCK_EX`) around the entire read-modify-write cycle of `~/.pipeline_quotas.json` so concurrent agents executing in parallel Git Worktrees cannot cause race conditions or overwrite each other's quota counters.

#### Scenario: Two worktrees update quota state simultaneously
- **WHEN** two or more `smart-agent` processes attempt to read and increment `~/.pipeline_quotas.json` concurrently
- **THEN** each process serializes access via `fcntl.flock(LOCK_EX)` on `~/.pipeline_quotas.lock` (or the state file descriptor) and persists accurate cumulative usage without lost updates

### Requirement: Strict Model Whitelisting and Cost Multipliers in AWS Kiro Pool
The system SHALL restrict Pool 3 (`kiro-cli`) invocations exclusively to `claude-haiku-5.5` (`0.06x` credits), `claude-sonnet-5.5` (`1.30x` credits), and `auto` (`1.00x` credits), and SHALL block legacy or deprecated models older than 3 months (`deepseek-3.2`, `qwen3-coder-next`, `minimax-m2.1`, `minimax-m2.5`, `glm-5`, `claude-haiku-4.5`, `claude-sonnet-4.5`).

#### Scenario: Routing a trivial or backend functional QA task to Kiro Haiku 5.5
- **WHEN** a task is routed to the `kiro-cli` pool for `TRIVIAL` complexity, `SCOUT`, `CODE_REVIEW` (`STANDARD`), or `QA_FUNCTIONAL`
- **THEN** the orchestrator selects `claude-haiku-5.5` and deducts `0.06` credits from `kiro_credits_used` in `~/.pipeline_quotas.json`

#### Scenario: Routing a complex code overflow task to Kiro Sonnet 5.5
- **WHEN** a `COMPLEX_CODE` or `DEEP_ARCH` task overflows the `agy` 5-hour windows and routes to `kiro-cli`
- **THEN** the orchestrator selects `claude-sonnet-5.5` (or `auto` for standard overflow) and deducts `1.30` credits (or `1.00` credit for `auto`) from `kiro_credits_used`

#### Scenario: Rejecting disallowed legacy models in Kiro Pool
- **WHEN** a configuration or prompt attempts to invoke a disallowed legacy model (such as `deepseek-3.2` or `claude-haiku-4.5`) on `kiro-cli`
- **THEN** the policy validator rejects the disallowed model identifier and resolves to the whitelisted tier equivalent (`claude-haiku-5.5`, `auto`, or `claude-sonnet-5.5`)

### Requirement: Out-of-Band CLI Auto-Update and Cached Dynamic Model Resolution
The system SHALL NEVER execute `kiro-cli update` or `agy update` during normal task routing (critical path); instead, CLI updates and model catalog refreshes SHALL run strictly when `smart-agent --auto-update` is invoked explicitly (via `install.sh` or a scheduled daily/weekly cron/systemd timer), while normal task invocations read the cached model list (`~/.cache/agenthub/models.json`).

#### Scenario: Normal task invocation avoids update network latency
- **WHEN** `smart-agent <STAGE> '<prompt>'` runs during a pipeline task
- **THEN** it resolves model families (`gemini-flash`, `gemini-argon`, `claude-haiku`, `claude-sonnet`, `claude-opus`) from `~/.cache/agenthub/models.json` in zero network round-trips without running `kiro-cli update` or `agy update`

#### Scenario: Out-of-band maintenance update refreshes CLIs and model cache
- **WHEN** `smart-agent --auto-update` is executed by `install.sh` or a scheduled maintenance job
- **THEN** the system executes `kiro-cli update -y` and `agy update`, queries `agy models`, and atomically updates `~/.cache/agenthub/models.json`

### Requirement: Quota-Preserving Stage Arbitrage Across 4 Pools
The system SHALL preserve the scarce 5-hour sliding windows (`agy_anthropic_5h_max: 12` and `agy_google_pro_5h_max: 25`) by routing orientation (`SCOUT`), standard briefings/specs, UI mockups, and visual/functional QA to high-quota/ultra-low-cost models (`gemini-3.8-flash` and `claude-haiku-5.5` at `0.06x`).

#### Scenario: Sliding-window saturation triggers overflow candidate
- **WHEN** the primary candidate's 5-hour sliding window (`agy_anthropic_5h` or `agy_google_pro_5h`) or monthly credit cap (`kiro_credits_used >= 950.0`) is saturated
- **THEN** `smart-agent` automatically selects the next available candidate in the route's `modelRefs` chain and falls back to Pool 4 (`copilot`) if all primary and secondary pools fail
