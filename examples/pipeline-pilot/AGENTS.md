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

Tasks are orchestrated in isolated **Git Worktrees** via **Vibe Kanban** (`:3000` over Tailscale) and routed through `/usr/local/bin/smart-agent`:

1. **Stage 1 — `BRIEFING` (Human Gate 1):**  
   Generate `openspec/changes/<slug>/proposal.md` only. Stop and request human approval.
2. **Stage 2 — `SPEC` (Human Gate 2):**  
   Run `/opsx:propose` to generate `specs/`, `tasks.md`, optional `design.md` (only for `COMPLEX_CODE` / `DEEP_ARCH`), and `ui-mockup.html` (if `has_frontend_ui == true`). Validate with `openspec validate --strict`. Stop for human review.
3. **Stage 3 — `APPLY` (`/opsx:apply`):**  
   Implement items in `tasks.md` sequentially inside the isolated Git Worktree, marking `- [x]` as each item passes Zero-Token validation.
4. **Stage 4 — `QA_VISUAL` (`/opsx:verify`):**  
   Launch the application server, inspect via **Playwright MCP** and **Browser-Use MCP**, verify EARS scenarios against `ui-mockup.html`, and write evidence/screenshots to `openspec/changes/<slug>/qa-report.md`.

---

## 3. Context & Quota Economy Rules

- Omit `design.md` for `TRIVIAL` or `STANDARD` tasks that touch fewer than 3 files.
- Keep `tasks.md` checkboxes updated in real time (`- [x]`) after each verified step.
- Never commit secrets, tokens, or `.pipeline_quotas.json` to version control.
