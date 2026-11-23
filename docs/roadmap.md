# Roadmap

> **Document:** `docs/roadmap.md`  
> **Status:** planned features; nothing here is implemented yet.

---

## Future Feature 5 — Hybrid Obsidian Shared Vault

**Goal:** a shared knowledge base across repositories without coupling any repo to a single machine layout.

- Each repository keeps its own `.vault/` (versioned notes: decisions, glossary, lessons from rejected gates).
- A hub directory `~/obsidian-hub/` holds **symlinks** to every repo's `.vault/`, so one Obsidian vault can browse all projects.
- Agents would read `.vault/` as optional context during `SCOUT`/`BRIEFING`; writes stay inside the repo.

**Out of scope for now:** no Obsidian daemon, plugin or sync integration is created. Only this design is recorded.

## Future Feature 6 — Interactive Briefing Chatbot in Vibe Kanban

**Goal:** replace the one-shot Briefing prompt with a conversational agent inside Vibe Kanban that interviews the requester, resolves ambiguity, and produces a better `proposal.md` for Gate 1.

- Chat UI embedded in the card, backed by `briefing-analyst`.
- Transcript persisted next to the change (`openspec/changes/<slug>/`).

**Out of scope for now:** the Vibe Kanban server source is not modified and no chat UI is added.


## Future Feature 7 — DevOps Agent & Infrastructure Control (Pending)

**Goal:** add a dedicated DevOps agent and operational control plane to manage CI/CD, runtime services, and safe deployments without manual SSH babysitting.

- **Scope (planned):**
  - CI/CD pipeline monitoring & triage (GitHub Actions, release tagging, PR checks).
  - Service & host health checks (`systemd` units such as `vibe-kanban`, `vllm-sr`, disk/RAM/port diagnostics, log inspection via `rtk`).
  - Controlled deployment & rollback workflows gated by explicit human approval before any production or infrastructure mutation.
  - Zero-secret discipline: uses existing OAuth/environment bindings, never persists credentials in repo artifacts.

**Status:** pending (out of scope for the v2 initial pilot — documentation only).

## Explicitly not planned

- **Automatic spec archiving (`openspec archive`):** agents receive `openspec/changes/<slug>/` explicitly, so no archive step is required.
