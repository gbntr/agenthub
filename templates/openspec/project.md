# Project Constitution: SDD Governance & Engineering Rules

> **Document:** Master Repository Constitution Template (`openspec/project.md`)  
> **Standard:** Spec-Driven Development (`@fission-ai/openspec`)  
> **Version:** 1.0.0  

---

## 1. Fundamental Principles (Axioms)

1. **No Spec, No Code:**  
   No implementation file may be created or modified unless an OpenSpec change proposal (`openspec/changes/<change-id>/`) has been drafted, validated (`openspec validate --strict`), and explicitly approved by a human reviewer (Gate 1 & Gate 2).

2. **Formal EARS Requirements Syntax:**  
   Every requirement in `specs/*.md` or `proposal.md` MUST adhere to **EARS (Easy Approach to Requirements Syntax)**:
   - **Ubiquitous:** `The system SHALL <response>.`
   - **Event-Driven:** `WHEN <trigger>, the system SHALL <response>.`
   - **State-Driven:** `WHILE <state>, the system SHALL <response>.`
   - **Optional Feature:** `WHERE <feature is included>, the system SHALL <response>.`
   - **Unwanted Behavior (Exception):** `IF <abnormal condition>, THEN the system SHALL <response>.`

3. **Zero-Token Validation (Zero-Token Gates):**  
   Before invoking LLM-based Visual QA or requesting human merge approval, all code must pass deterministic local compilers, static typecheckers, and unit tests without consuming LLM tokens.

---

## 2. Technology Domain Rules

### 2.1. Fullstack Web Domain (TypeScript / React / Node.js / Python Backend)
- **Mandatory Zero-Token Gate:**
  ```bash
  npx tsc --noEmit
  npm test -- --passWithNoTests
  # And if Python backend is present:
  pytest
  ```
- **Mandatory UI Prototype Rule:**  
  Every task classified with `has_frontend_ui == true` MUST generate and maintain a self-contained interactive prototype at `openspec/changes/<change-id>/ui-mockup.html` using **Tailwind CSS via CDN**. This prototype is visually inspected by a human at Gate 2 and used as the baseline reference by the Playwright MCP Visual QA agent.

### 2.2. Academic & Systems Domain (C / C++)
- **Mandatory Zero-Token Gate:**
  ```bash
  gcc -Wall -Wextra -Werror -pedantic -std=c17 ...
  # Or for C++:
  g++ -Wall -Wextra -Werror -std=c++20 ...
  make test
  ```
- **Memory & Undefined Behavior Sanitizers:** Whenever applicable during debugging and verification, compile with `-fsanitize=address,undefined`.
- **UI Bypass:** `has_frontend_ui` is always `false`; skip `ui-mockup.html` and browser QA.

### 2.3. Enterprise & Academic Domain (.NET 10 / C#)
- **Mandatory Zero-Token Gate:**
  ```bash
  dotnet build --nologo -v q
  dotnet test --nologo -v q
  ```

---

## 3. SDD Artifact Lifecycle & Context Economy

The directory structure under `openspec/changes/<change-id>/` strictly follows these phases:

1. `proposal.md` — Intent, in-scope/out-of-scope boundaries, formal EARS requirements, and impact analysis.
2. `ui-mockup.html` — Interactive visual prototype (only when `has_frontend_ui == true`).
3. `design.md` — Architectural decisions, sequence/component diagrams, and rejected alternatives. *(Context Economy Rule: Omit `design.md` for `TRIVIAL` or `STANDARD` tasks modifying fewer than 3 files).*
4. `tasks.md` — Atomic, sequential checklist of implementation tasks (`- [ ] 1.1 ...` updated immediately to `- [x] 1.1 ...` upon verification).
5. `qa-report.md` — Evidence of Zero-Token test execution and headless Playwright/Browser-Use MCP visual inspection.

---

## 4. Human Approval Gates

- **Gate 1 (Briefing & Scope Approval):**  
  The agent halts after generating `proposal.md` and awaits human confirmation of scope and requirements.
- **Gate 2 (Specification & Visual Mockup Approval):**  
  The agent halts after generating `specs/`, `tasks.md`, optional `design.md`, and `ui-mockup.html`. Coding (`/opsx:apply`) inside the isolated Git Worktree only begins after explicit human sign-off.
- **Final Review & 1-Click Merge:**  
  The agent presents `qa-report.md`, Zero-Token compiler exit codes, and Desktop/Mobile Playwright screenshots before the worktree branch is merged into `main`.

---

## 5. Stage Agents & Review/QA Gates (AgentHub v2)

Six specialized agents (catalog: `docs/agents-catalog.md` in the AgentHub repo) run the pipeline and are always bound to the active change `openspec/changes/<change-id>/`:

| Stage | Agent | Produces |
| :--- | :--- | :--- |
| `SCOUT` | `repo-scout` | `context-map.md` |
| `BRIEFING` | `briefing-analyst` | `proposal.md` (EARS) |
| `SPEC` | `spec-architect` | `specs/`, `tasks.md` (TDD cases), `design.md`, `ui-mockup.html` |
| `APPLY` | `code-craftsman` | code + tests (must not edit `specs/`) |
| `CODE_REVIEW` | `spec-auditor` | `code-review-report.md` |
| `QA_VISUAL` / `QA_FUNCTIONAL` | `qa-inspector` | `qa-report.md` |

- Gate reports MUST end with `STATUS: APPROVED` or `STATUS: REJECTED`. A rejection triggers an automatic `APPLY` retry (state in `.state.json`, `max_retries: 2`) before halting for a human.
- QA servers MUST bind to the dynamic `$QA_PORT` (never `:3000`, `:5000`, `:8000`) and be torn down before exit.
