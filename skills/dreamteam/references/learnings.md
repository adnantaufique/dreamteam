# Dreamteam — Learnings Store

Curated, human-reviewed defaults the **Caster** consults before a run (`references/caster.md`). Entries are **evidence-tagged advisory defaults, overridable** — never hard rules. Persisted by `references/retro.md`; promoted to skill edits only via the human gate. Seeded empty.

| date | profile/task_kind | learning (evidence) | applied? |
|---|---|---|---|
| | | | |

**Schema → column mapping** (how a `retro.md` record becomes a row): `profile/task_kind ← record.profile + task_kind` · `learning (evidence) ← each change.delta + its change.evidence` (plus notable `worked[]` items) · `applied? ← "no"` until the human promotes it (the human gate). One row per `change[]` entry; `confidence` travels in the learning cell.

Per-environment: this file lives in the installed skill; learnings are local unless the human promotes them upstream. (On Codex the synced copy lives alongside the `AGENTS.md` pointer; on Gemini under `~/.gemini/agents/dreamteam/` — see `references/platforms.md`.)
