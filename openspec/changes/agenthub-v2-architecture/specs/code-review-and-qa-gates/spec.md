# Spec: Code Review and QA Gates

## Purpose

Establishes the mandatory Stage 4 Code, Specification, and Dependency Integrity Review Gate (`CODE_REVIEW`) positioned after Zero-Token compilation and before Stage 5 QA, as well as the dual Visual Frontend (`QA_VISUAL`) and Functional Backend/CLI (`QA_FUNCTIONAL`) verification gates with persistent rejection state (`openspec/changes/<slug>/.state.json`), dynamic port allocation, and mandatory process teardown.

## ADDED Requirements

### Requirement: Stage 4 Code, Specification, and Dependency Integrity Gate
The system SHALL execute Stage 4 (`CODE_REVIEW` via `spec-auditor`) immediately after Stage 3 (`APPLY` + Zero-Token compiler/package validation) and prior to Stage 5 (`QA`), auditing the `git diff` against the approved OpenSpec EARS requirements, package lockfiles/manifests, test quality, and anti-stub rules.

#### Scenario: Code Review detects unimplemented EARS requirement or hardcoded stub
- **WHEN** `spec-auditor` inspects the `git diff` and detects a missing `WHEN/SHALL` requirement implementation, a `TODO`/`FIXME` placeholder, a hardcoded mock return in production code, or a weak/skipped test assertion
- **THEN** `spec-auditor` writes `STATUS: REJECTED` with exact `file:line` remediation items in `openspec/changes/<slug>/code-review-report.md`

#### Scenario: Code Review verifies dependency and lockfile integrity
- **WHEN** `spec-auditor` audits changes to package manifests (`package.json`, `pyproject.toml`, `requirements.txt`, `.csproj`, `Makefile`)
- **THEN** it verifies that newly introduced packages are legitimate, used in the implementation, and passed the Zero-Token build/test gate before writing `STATUS: APPROVED` in `openspec/changes/<slug>/code-review-report.md`

### Requirement: Dual Mode Stage 5 QA Gate (Visual Frontend and Functional Backend)
The system SHALL execute Stage 5 (`QA` via `qa-inspector`) in `QA_VISUAL` mode when `has_frontend_ui == true` and in `QA_FUNCTIONAL` mode when `has_frontend_ui == false` (backend APIs, services, CLI binaries, C/C++/C# systems).

#### Scenario: Frontend task undergoes Visual and Interactive QA
- **WHEN** a task with `has_frontend_ui == true` passes `CODE_REVIEW`
- **THEN** `qa-inspector` starts the preview server on a dynamically allocated free port, uses Playwright MCP / Browser-Use MCP to verify every EARS scenario in a headless browser, compares rendered DOM/styles against `openspec/changes/<slug>/ui-mockup.html`, and records screenshots, console logs, and `STATUS: APPROVED` or `STATUS: REJECTED` in `openspec/changes/<slug>/qa-report.md`

#### Scenario: Backend or CLI task undergoes Black-Box Functional QA
- **WHEN** a task with `has_frontend_ui == false` passes `CODE_REVIEW`
- **THEN** `qa-inspector` launches the backend API service on a dynamically allocated free port (or executes the compiled binary) and executes real black-box functional probes (valid payloads, boundary conditions, malformed inputs, and error-handling scenarios defined in `specs/`), recording exact request/response outputs and `STATUS: APPROVED` or `STATUS: REJECTED` in `openspec/changes/<slug>/qa-report.md`

### Requirement: Dynamic Ephemeral Port Allocation and Mandatory Process Tree Teardown in QA
WHILE executing `QA_VISUAL` or `QA_FUNCTIONAL`, the system SHALL bind any application server or test daemon to a dynamically discovered free ephemeral TCP port (never hardcoded default ports like `:3000`, `:5000`, or `:8000`) and SHALL unconditionally terminate the entire process group (`SIGTERM`/`SIGKILL` via `try/finally` or shell `trap EXIT`) upon completing `qa-report.md`.

#### Scenario: Concurrent worktrees run QA servers simultaneously without port collision
- **WHEN** two Git Worktrees execute Stage 5 (`QA_VISUAL` or `QA_FUNCTIONAL`) at the same time on the VM
- **THEN** each QA session binds to a distinct dynamically allocated free port (avoiding `EADDRINUSE` and never colliding with Vibe Kanban on `:3000`) and kills all spawned child processes before exiting

### Requirement: Persistent Self-Healing Rejection Loop Orchestration
IF either `spec-auditor` (`CODE_REVIEW`) or `qa-inspector` (`QA_VISUAL` / `QA_FUNCTIONAL`) outputs `STATUS: REJECTED`, THEN `smart-agent` SHALL increment the persistent retry counter in `openspec/changes/<slug>/.state.json` (capped at `max_retries: 2`), automatically invoke `code-craftsman` (`APPLY`) with the rejection report appended, and re-run the rejecting gate within the same orchestration cycle (or halt and mark `BLOCKED_MAX_RETRIES` in `.state.json` once `retry_count >= 2`).

#### Scenario: Automatic self-healing cycle on Gate rejection with persistent state
- **WHEN** Stage 4 (`CODE_REVIEW`) or Stage 5 (`QA`) writes `STATUS: REJECTED` and `openspec/changes/<slug>/.state.json` shows `retry_count < 2`
- **THEN** `smart-agent` persists `retry_count + 1` in `openspec/changes/<slug>/.state.json`, runs `code-craftsman` (`APPLY`) with the remediation items from `code-review-report.md` or `qa-report.md`, and re-executes the gate automatically

#### Scenario: Halting when maximum self-healing retries are exhausted
- **WHEN** Stage 4 (`CODE_REVIEW`) or Stage 5 (`QA`) writes `STATUS: REJECTED` and `openspec/changes/<slug>/.state.json` reaches `retry_count >= 2`
- **THEN** `smart-agent` records `"status": "HALTED_FOR_HUMAN"` in `openspec/changes/<slug>/.state.json` and exits non-zero without triggering another `APPLY` loop
