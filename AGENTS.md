# AGENTS.md — Universal Agent Operating Instructions

> **Repository:** `agenthub`  
> **Architecture:** Autonomous Spec-Driven Development (SDD) & Multi-CLI Orchestration Hub  
> **Compatible Agents:** Antigravity (`agy`), AWS Kiro CLI (`kiro-cli`), GitHub Copilot CLI (`copilot`), Claude Code

---

## 1. Core Axioms (Mandatory)

1. **No Spec, No Code:**  
   Never create or modify application source code without an approved OpenSpec change directory under `openspec/changes/<change-id>/` containing at minimum an approved `proposal.md` (Gate 1) and `specs/` + `tasks.md` (Gate 2).
2. **Formal EARS Requirements:**  
   All requirements inside `proposal.md` and `specs/*.md` MUST use **EARS (Easy Approach to Requirements Syntax)**:
   - **Ubiquitous:** `The system SHALL <response>.`
   - **Event-Driven:** `WHEN <trigger>, the system SHALL <response>.`
   - **State-Driven:** `WHILE <state>, the system SHALL <response>.`
   - **Optional Feature:** `WHERE <feature is included>, the system SHALL <response>.`
   - **Unwanted Behavior:** `IF <condition>, THEN the system SHALL <response>.`
3. **Interactive UI Mockup Rule (`has_frontend_ui == true`):**  
   If a task modifies or introduces visual frontend components (HTML, CSS, React, Tailwind, views), you MUST create a self-contained interactive prototype at `openspec/changes/<change-id>/ui-mockup.html` (using Tailwind CSS via CDN) during the `SPEC` phase before writing production UI code.
4. **Zero-Token Validation Before Completion:**  
   Always run the local compiler, typechecker, or test suite before marking a task complete or invoking Visual QA:
   - **TypeScript / Web:** `npx tsc --noEmit && npm test -- --passWithNoTests`
   - **Python:** `pytest`
   - **C / C++:** `gcc/g++ -Wall -Wextra -Werror` and `make test`
   - **C# / .NET:** `dotnet build --nologo -v q && dotnet test --nologo -v q`

---

## 2. Workflow Stages & Vibe Kanban Integration

Tasks are orchestrated in isolated **Git Worktrees** via **Vibe Kanban** (`:3000` over Tailscale) and routed through `/usr/local/bin/smart-agent --agent <name> <STAGE>`. The active change is always `openspec/changes/<slug>/` (passed explicitly; no archiving). Full contracts: [`docs/agents-catalog.md`](./docs/agents-catalog.md).

| Stage | Agent | Output | Gate |
| :--- | :--- | :--- | :--- |
| 0 — `SCOUT` | `repo-scout` | `context-map.md` | — |
| 1 — `BRIEFING` | `briefing-analyst` | `proposal.md` (EARS) | Human Gate 1 |
| 2 — `SPEC` | `spec-architect` | `specs/`, `tasks.md` (TDD), `design.md`, `ui-mockup.html` | Human Gate 2 |
| 3 — `APPLY` | `code-craftsman` | code + tests, `- [x]` in `tasks.md` (never edits `specs/`) | Zero-Token gate |
| 4 — `CODE_REVIEW` | `spec-auditor` | `code-review-report.md` (`STATUS: APPROVED\|REJECTED`) | Auto reject loop |
| 5 — `QA_VISUAL` / `QA_FUNCTIONAL` | `qa-inspector` | `qa-report.md` (`STATUS: APPROVED\|REJECTED`) | Auto reject loop |

- **Rejection loop:** `STATUS: REJECTED` makes `smart-agent` re-run `code-craftsman` with the report and re-run the gate, persisted in `openspec/changes/<slug>/.state.json` (`max_retries: 2`); then `HALTED_FOR_HUMAN` and exit `1`.
- **QA hygiene:** servers bind only to `$QA_PORT` (never `:3000`, `:5000`, `:8000`) and every spawned process is terminated.
- **Token economy:** run shell commands through `rtk`; query code structurally with `ast-grep` instead of reading whole files; Caveman `lite` for Briefing/Spec, `full` elsewhere.

---

## 3. Context & Quota Economy Rules

- Omit `design.md` for `TRIVIAL` or `STANDARD` tasks that touch fewer than 3 files.
- Keep `tasks.md` checkboxes updated in real time (`- [x]`) after each verified step.
- Never commit secrets, tokens, or `.pipeline_quotas.json` to version control.
