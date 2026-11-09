# Spec: Stage-Specialized Agents

## Purpose

Defines the 6 specialized SDD stage agents (`repo-scout`, `briefing-analyst`, `spec-architect`, `code-craftsman`, `spec-auditor`, `qa-inspector`), their least-privilege tool boundaries, explicit active specification path binding (`openspec/changes/<slug>/`), dynamic port/teardown hygiene for QA, and the central agent catalog documentation.

## ADDED Requirements

### Requirement: Six Specialized Stage Agent Profiles
The system SHALL provide 6 distinct, role-scoped agent definitions in `config/agents/` and register their execution profiles in `config/vibe-kanban/profiles.json` so each pipeline stage runs with a dedicated system prompt and least-privilege tool boundary.

#### Scenario: Stage 0 Repo Scout execution
- **WHEN** `smart-agent` executes stage `SCOUT` with agent `repo-scout`
- **THEN** the agent operates in read-only mode on application source code using `ast-grep` and `rtk` and writes only `openspec/changes/<slug>/context-map.md` containing impacted files, symbol line ranges, type signatures, and test commands

#### Scenario: Stage 1 Briefing Analyst execution
- **WHEN** `smart-agent` executes stage `BRIEFING` with agent `briefing-analyst`
- **THEN** the agent reads `context-map.md` (if present) and writes only `openspec/changes/<slug>/proposal.md` using formal EARS syntax without modifying any application source files

#### Scenario: Stage 2 Spec Architect execution
- **WHEN** `smart-agent` executes stage `SPEC` with agent `spec-architect`
- **THEN** the agent generates `specs/`, `tasks.md` (with explicit Spec-First TDD test cases), optional `design.md` (for `COMPLEX_CODE`/`DEEP_ARCH`), and `ui-mockup.html` (when `has_frontend_ui == true`) inside `openspec/changes/<slug>/`, and validates them with `openspec validate --strict`

#### Scenario: Stage 3 Code Craftsman execution
- **WHEN** `smart-agent` executes stage `APPLY` with agent `code-craftsman`
- **THEN** the agent implements `openspec/changes/<slug>/tasks.md` using Spec-First TDD inside the isolated Git Worktree, runs Zero-Token local compilers/tests, and is forbidden from altering `openspec/changes/<slug>/specs/` to weaken requirements

#### Scenario: Stage 4 Spec Auditor execution
- **WHEN** `smart-agent` executes stage `CODE_REVIEW` with agent `spec-auditor`
- **THEN** the agent operates with read-only permissions on application source code and writes its audit verdict exclusively to `openspec/changes/<slug>/code-review-report.md`

#### Scenario: Stage 5 QA Inspector execution with dynamic port and teardown rules
- **WHEN** `smart-agent` executes stage `QA_VISUAL` or `QA_FUNCTIONAL` with agent `qa-inspector`
- **THEN** the agent binds any spawned server strictly to the dynamically allocated `QA_PORT` (never hardcoded `:3000`, `:5000`, or `:8000`), executes live browser or backend/CLI verification, writes its evidence and verdict to `openspec/changes/<slug>/qa-report.md`, and terminates all spawned server processes before exiting

### Requirement: Explicit Active Specification Binding Without Archiving Overhead
The system SHALL pass the active change directory path (`openspec/changes/<slug>/`) explicitly in every agent's instructions so all 6 agents deterministically locate the authoritative `proposal.md`, `context-map.md`, `specs/`, and `tasks.md` without requiring a post-QA spec archiving step.

#### Scenario: Agent resolves active change specification deterministically
- **WHEN** any stage agent is invoked for a change `<slug>`
- **THEN** the agent reads and updates artifacts strictly under `openspec/changes/<slug>/` as its single source of truth for that task

### Requirement: Master Agent Catalog Documentation
The system SHALL maintain a comprehensive markdown specification at `docs/agents-catalog.md` (and summary table in `AGENTS.md`) documenting each agent's role, input artifacts, output artifacts, allowed tools, default model tier, Caveman compression level, and rejection authority.

#### Scenario: Developer or orchestrator inspects agent responsibilities
- **WHEN** `docs/agents-catalog.md` is read
- **THEN** it provides the complete operational contract, prompt boundaries, and handoff protocol for all 6 agents (`repo-scout`, `briefing-analyst`, `spec-architect`, `code-craftsman`, `spec-auditor`, `qa-inspector`)
