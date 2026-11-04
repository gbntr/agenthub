# Semantic Quota Arbitrage & Multi-CLI Routing Matrix

> **Document:** `docs/quota-arbitration.md`  
> **Component:** `core/smart-agent` + `config/vllm-sr/config.yaml`  
> **State File:** `~/.pipeline_quotas.json`

---

## 1. The Multi-Pool Arbitrage Problem

Relying on a single AI coding CLI or a single frontier model for every phase of software engineering is both **economically wasteful** and **fragile**:
- Running a frontier reasoning model (`claude-opus-5.5` or `claude-sonnet-5.5`) to fix a typo, format a Markdown checklist, or parse a build log rapidly exhausts strict 5-hour sliding-window quotas.
- Conversely, using an ultra-lightweight model to design a distributed database migration or debug a race condition in C++ leads to subtle architectural bugs.

**AgentHub** solves this via **Semantic Quota Arbitrage**: every prompt dispatched by Vibe Kanban is intercepted by `/usr/local/bin/smart-agent`, classified across three semantic dimensions (`complexity`, `has_frontend_ui`, `project_domain`), and routed to the optimal pool among **4 independent AI CLIs**.

---

## 2. The 4 AI CLI Pools

| Pool | CLI Binary | Available Models | Quota & Billing Structure | Primary Pipeline Role |
| :--- | :--- | :--- | :--- | :--- |
| **Pool 1: Google Gemini** | `agy` | • `gemini-3.8-flash`<br>• `gemini-3.1-pro`<br>• `gemini-4-argon` | 5-hour sliding window (`max: 25` Pro/Argon calls per 5h), completely decoupled from the Anthropic pool. Massive quota on `3.8-flash`. | • **`gemini-3.8-flash`:** Interactive `ui-mockup.html` generation & multimodal **Visual QA** via Playwright.<br>• **`gemini-3.1-pro` / `4-argon`:** `STANDARD` specifications and multi-file refactoring. |
| **Pool 2: Anthropic Claude** | `agy` | • `claude-sonnet-5.5`<br>• `claude-opus-5.5` | Strict 5-hour sliding window (`max: 12` calls per 5h) + weekly ceiling. Reserved exclusively for high-complexity reasoning. | • **`claude-sonnet-5.5`:** Primary implementation engine for `COMPLEX_CODE`.<br>• **`claude-opus-5.5`:** Reserved for `DEEP_ARCH` and hard architectural deadlocks. |
| **Pool 3: AWS Kiro CLI** | `kiro-cli` | • `qwen3-coder-next` (**0.05x**)<br>• `minimax-m2.1` (**0.15x**)<br>• `deepseek-3.2` / `luna` (**0.25x**)<br>• `claude-haiku-4.5` (**0.40x**)<br>• `claude-sonnet-4.5` (**1.30x**) | Monthly bucket of **1,000 credits** (`kiro_monthly_credits_max: 950.0` safety cap). Deducted fractionally by model multiplier. | • **High-Volume Economic Workhorse:** Handles `TRIVIAL` tasks, log analysis, checklist updates, and serves as **Tier-1 Fallback** when Pool 1 or Pool 2 windows are saturated. |
| **Pool 4: GitHub Copilot CLI** | `copilot` | • Copilot Autonomous Engine (`@github/copilot`) | Monthly subscription allowance (`GH_TOKEN` OAuth). | • **Tier-2 Emergency Fallback:** Automatically triggered if both the primary CLI and AWS Kiro CLI return non-zero exit codes or rate-limit errors. |

---

## 3. Semantic Classification Signals (`vllm-sr` + Local Heuristic)

`smart-agent` queries `http://127.0.0.1:8080/v1/route` (`vllm-sr` configured via `config/vllm-sr/config.yaml`). If the `vllm-sr` daemon is offline or exceeds the `1.5s` timeout, `smart-agent` seamlessly executes a **zero-latency local word-boundary (`\b`) regex classifier** supporting both English and Portuguese prompts:

1. **`complexity`**:
   - `TRIVIAL`: Typo fixes, README updates, comments, renaming, log cleanup, formatting.
   - `STANDARD`: Routine feature specs, CRUD endpoints, standard unit tests, component wiring.
   - `COMPLEX_CODE`: Refactoring, database migrations, security hardening, parallel/concurrent algorithms, kernel/pointer logic, performance optimization.
   - `DEEP_ARCH`: Cross-system architectural redesigns or multi-service state machines.
2. **`has_frontend_ui`** (`boolean`):
   - `true` when UI/frontend tokens (`react`, `css`, `tailwind`, `html`, `layout`, `mockup`, `button`, `page`, `component`, `widget`, etc.) are detected.
   - Automatically injects the **[ACTIVE UI RULE]** into the agent prompt during `BRIEFING` and `SPEC` stages, mandating the creation of `openspec/changes/<id>/ui-mockup.html`.
3. **`project_domain`**:
   - `FULLSTACK_WEB` (TypeScript, React, Node.js, Python web backends)
   - `UNIVERSITY_C_CPP_CSHARP` (GCC/G++, Make, .NET 10 / C#)
   - `DOCS_ONLY` (Markdown, specifications, architecture docs)

---

## 4. Decision Tree & Cascading Fallback Flow

```mermaid
flowchart TD
    Start(["Incoming Task: smart-agent <STAGE> '<prompt>'"]) --> Classify["Classify Task<br/>(vllm-sr HTTP :8080 or Local Regex Fallback)"]
    Classify --> CheckUI{"Stage in [SPEC, BRIEFING]<br/>AND has_frontend_ui == true?"}
    CheckUI -- Yes --> InjectUI["Inject Mandatory UI Rule:<br/>Generate openspec/changes/<id>/ui-mockup.html"]
    CheckUI -- No --> CheckStage
    InjectUI --> CheckStage{"Stage in<br/>[QA_VISUAL, UI_MOCKUP]?"}

    CheckStage -- Yes --> RouteFlash["Select Pool 1: agy (gemini-3.8-flash)"]
    CheckStage -- No --> CheckComp{"Task Complexity?"}

    CheckComp -- TRIVIAL --> Q_Kiro1{"Kiro Credits < 950?"}
    Q_Kiro1 -- Yes --> RouteKiroHaiku["Select Pool 3: kiro-cli (claude-haiku-4.5 / 0.40x)"]
    Q_Kiro1 -- No --> RouteFlash

    CheckComp -- STANDARD --> Q_GPro{"Google Pro 5h < 25?"}
    Q_GPro -- Yes --> RouteGPro["Select Pool 1: agy (gemini-3.1-pro -> gemini-4-argon)"]
    Q_GPro -- No --> Q_Kiro2{"Kiro Credits < 950?"}
    Q_Kiro2 -- Yes --> RouteKiroLuna["Select Pool 3: kiro-cli (deepseek-3.2 / 0.25x)"]
    Q_Kiro2 -- No --> RouteFlash

    CheckComp -- COMPLEX_CODE --> Q_Anth1{"Anthropic 5h < 12?"}
    Q_Anth1 -- Yes --> RouteSonnet["Select Pool 2: agy (claude-sonnet-5.5)"]
    Q_Anth1 -- No --> Q_GPro2{"Google Pro 5h < 25?"}
    Q_GPro2 -- Yes --> RouteArgon["Select Pool 1: agy (gemini-4-argon)"]
    Q_GPro2 -- No --> RouteKiroSonnet["Select Pool 3: kiro-cli (claude-sonnet-4.5 / 1.30x)"]

    CheckComp -- DEEP_ARCH --> Q_Anth2{"Anthropic 5h < 12?"}
    Q_Anth2 -- Yes --> RouteOpus["Select Pool 2: agy (claude-opus-5.5)"]
    Q_Anth2 -- No --> RouteArgon

    RouteFlash & RouteKiroHaiku & RouteGPro & RouteKiroLuna & RouteSonnet & RouteArgon & RouteKiroSonnet & RouteOpus --> ExecPrimary["Execute Selected Primary CLI"]

    ExecPrimary --> CheckExit{"Exit Code == 0?"}
    CheckExit -- Yes --> SaveQuota["Update ~/.pipeline_quotas.json & Exit 0"]
    CheckExit -- No --> FB1["Tier-1 Fallback:<br/>kiro-cli chat --model claude-haiku-4.5"]
    FB1 --> CheckFB1{"Exit Code == 0?"}
    CheckFB1 -- Yes --> SaveQuota
    CheckFB1 -- No --> FB2["Tier-2 Emergency Fallback:<br/>copilot -p '<prompt>' -s --allow-all"]
```

---

## 5. Sliding-Window Quota Persistence (`~/.pipeline_quotas.json`)

`smart-agent` maintains state in `~/.pipeline_quotas.json`:

```json
{
  "window_start": 1793832000.0,
  "agy_anthropic_5h": 3,
  "agy_google_pro_5h": 8,
  "kiro_credits_used": 14.65
}
```

- **Automatic 5-Hour Reset:** Whenever `time.time() - window_start > 18000` (5 hours), `agy_anthropic_5h` and `agy_google_pro_5h` reset to `0`, and `window_start` advances to the current timestamp.
- **Configurable Thresholds via Environment Variables:**
  - `AGY_ANTHROPIC_5H_MAX` (Default: `12`)
  - `AGY_GOOGLE_PRO_5H_MAX` (Default: `25`)
  - `KIRO_MONTHLY_CREDITS_MAX` (Default: `950.0`)
  - `VLLM_SR_URL` (Default: `http://127.0.0.1:8080/v1/route`)
