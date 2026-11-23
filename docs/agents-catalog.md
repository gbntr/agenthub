# Agent Catalog: The 6 Stage-Specialized SDD Agents

> **Document:** `docs/agents-catalog.md`  
> **Definitions:** [`config/agents/*.md`](../config/agents/) (agy) and [`config/agents/kiro/*.json`](../config/agents/kiro/) (kiro-cli)  
> **Wiring:** `config/vibe-kanban/profiles.json` → `/usr/local/bin/smart-agent --agent <name> <STAGE> '<prompt>'`

---

## 1. Operating Contract

- **Active spec binding:** `smart-agent` appends `[ACTIVE SPEC]: openspec/changes/<slug>/` to every prompt (slug from `--slug`, `$AGENTHUB_CHANGE`, or the most recent `openspec/changes/<slug>/`). Agents read and write artifacts only there. There is no archiving step: the path is passed explicitly.
- **Least privilege:** each agent lists only the tools it needs; scouts and auditors never write application code.
- **Token economy:** shell through `rtk`, structural search through `ast-grep`, Caveman level per stage (`lite` keeps EARS clauses intact; `full` is telegraphic).
- **Models:** chosen declaratively per stage × complexity in [`config/routing-policy.yaml`](../config/routing-policy.yaml) (see [`quota-arbitration.md`](./quota-arbitration.md)). Default agent per stage lives in `stage_agents`.

## 2. Summary

| # | Agent | Stage | Default model tier | Caveman | Can reject? |
| :-: | :--- | :--- | :--- | :-: | :-: |
| 0 | `repo-scout` | `SCOUT` | `claude-haiku-5.5` (0.06x) / `gemini-3.8-flash` low | `full` | No |
| 1 | `briefing-analyst` | `BRIEFING` | `gemini-3.8-flash` → `gemini-4-argon` | `lite` | No (asks questions) |
| 2 | `spec-architect` | `SPEC` | `gemini-4-argon` → `claude-sonnet-5-5` / `opus-5-5` | `lite` | No |
| 3 | `code-craftsman` | `APPLY` | `claude-haiku-5.5` → `gemini-4-argon` → `claude-sonnet-5-5` / `opus-5-5` | `full` | No |
| 4 | `spec-auditor` | `CODE_REVIEW` | `claude-haiku-5.5` (STANDARD) → `gemini-4-argon` / `claude-sonnet-5-5` | `full` | **Yes** |
| 5 | `qa-inspector` | `QA_VISUAL` / `QA_FUNCTIONAL` | `gemini-3.8-flash` (visual) / `claude-haiku-5.5` (functional) | `full` | **Yes** |

## 3. Agents

### 0. `repo-scout` (`SCOUT`)
- **Inputs:** card request, repository.
- **Output:** `openspec/changes/<slug>/context-map.md` (impacted files, symbol line ranges, signatures, test commands).
- **Tools:** read, grep, glob, shell (via `rtk`), `ast-grep`. **Read-only on application code.**
- **Handoff:** `briefing-analyst` reads the map.

### 1. `briefing-analyst` (`BRIEFING`, Human Gate 1)
- **Inputs:** card, `context-map.md`.
- **Output:** `proposal.md` (summary, in/out of scope, formal EARS requirements, planned stages).
- **Tools:** read, grep, glob, write (`proposal.md` only). Never touches source.
- **Handoff:** human approves, then `spec-architect`.

### 2. `spec-architect` (`SPEC`, Human Gate 2)
- **Inputs:** `proposal.md`, `context-map.md`.
- **Outputs:** `specs/`, `tasks.md` with explicit Spec-First TDD test cases, `design.md` (`COMPLEX_CODE`/`DEEP_ARCH` only), `ui-mockup.html` (`has_frontend_ui == true`). Validated with `openspec validate --strict`.
- **Tools:** read, grep, glob, write (inside the change dir), `openspec` CLI.
- **Handoff:** human approves, then `code-craftsman`.

### 3. `code-craftsman` (`APPLY`)
- **Inputs:** `tasks.md`, `specs/`, `ui-mockup.html`; on retries, the appended `[REJECTION REPORT]`.
- **Output:** application code and tests; `- [x]` marks in `tasks.md`.
- **Tools:** read, write, grep, glob, shell, `ast-grep`. Runs the Zero-Token gate to exit code 0 before ticking a task.
- **Prohibited:** editing `openspec/changes/<slug>/specs/`, stubs, `TODO` placeholders, weakened asserts.
- **Handoff:** `spec-auditor`.

### 4. `spec-auditor` (`CODE_REVIEW`)
- **Inputs:** `git diff`, `specs/`, `tasks.md`, manifests/lockfiles (`package.json`, `pyproject.toml`, `requirements.txt`, `.csproj`, `Makefile`).
- **Output:** `code-review-report.md` ending in `STATUS: APPROVED` or `STATUS: REJECTED` (with `file:line` items).
- **Tools:** read, grep, glob, read-only git, write (report only). **Read-only on source.**
- **Rejection power:** yes, triggers the self-healing loop (§4).
- **Handoff:** `qa-inspector` on approval.

### 5. `qa-inspector` (`QA_VISUAL` / `QA_FUNCTIONAL`)
- **Dispatch:** `smart-agent ... QA` resolves to `QA_VISUAL` when `ui-mockup.html` exists or UI signals are detected, otherwise `QA_FUNCTIONAL`.
- **Visual:** headless Chromium through Playwright / Browser-Use MCP, EARS scenarios, DOM/style comparison with `ui-mockup.html`, screenshots, console logs.
- **Functional:** black-box API/CLI probes (valid, boundary, malformed inputs, error handling).
- **Output:** `qa-report.md` ending in `STATUS: APPROVED` or `STATUS: REJECTED`.
- **Port & teardown rule:** bind servers only to `$QA_PORT` (never `:3000`, `:5000`, `:8000`) and kill every spawned process; `smart-agent` enforces it too (§5).
- **Rejection power:** yes.

## 4. Self-Healing Rejection Loop

When `CODE_REVIEW` or `QA_*` writes `STATUS: REJECTED` (or no verdict, or the agent fails), `smart-agent`:

1. Reads/updates `openspec/changes/<slug>/.state.json` under `fcntl.flock` (`.state.lock`).
2. If `retry_count < max_retries` (`2`, from `orchestration.max_retries`): increments `retry_count`, runs `code-craftsman` (`APPLY`) with the report appended, runs the local Zero-Token gate (`AGENTHUB_VALIDATE_CMD` or auto-detected `tsc`/`npm test`/`pytest`/`make test`), then re-runs the rejecting gate.
3. Otherwise writes `"status": "HALTED_FOR_HUMAN"` and exits `1`, so Vibe Kanban stops the card.

```json
{ "status": "RETRYING_CODE_REVIEW", "retry_count": 1, "max_retries": 2,
  "history": [{ "gate": "CODE_REVIEW", "verdict": "REJECTED", "ts": 1793832000 }] }
```

A human who fixed a halted change resets it with `smart-agent --reset-state --slug <slug> <GATE> '<prompt>'`. Stale reports are deleted before every gate run, so an old verdict is never trusted.

## 5. QA Port Allocation & Teardown

For `QA_VISUAL` / `QA_FUNCTIONAL`, `smart-agent` picks a free ephemeral port with Python `socket` (`bind(('127.0.0.1', 0))`), exports `QA_PORT=<port>` and states it in the prompt, runs the agent in its own session (`start_new_session=True`), and in a `finally` block kills the process group (`SIGTERM`, then `SIGKILL`) and any process still listening on `QA_PORT`. Concurrent worktrees therefore never collide (`EADDRINUSE`) or leak RAM.

## 6. Verification

`./core/test_gates.sh` simulates the loop with fake CLIs (no tokens): halt at retry 2, self-heal after one retry, QA dispatch, dynamic port, leaked-server teardown, and concurrent port uniqueness.
