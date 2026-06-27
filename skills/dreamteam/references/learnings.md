# Dreamteam — Learnings Store

Curated, human-reviewed defaults the **Caster** consults before a run (`references/caster.md`). Entries are **evidence-tagged advisory defaults, overridable** — never hard rules. Persisted by `references/retro.md`; promoted to skill edits only via the human gate. Seeded empty.

| date | project_key | profile/task_kind | learning (evidence) | applied? |
|---|---|---|---|---|
| | | | | |

**Schema → column mapping** (how a `retro.md` record becomes a row): `project_key ← record.project_key` · `profile/task_kind ← record.profile + task_kind` · `learning (evidence) ← each change.delta + its change.evidence` (plus notable `worked[]` items) · `applied? ← "no"` until the human promotes it (the human gate). One row per `change[]` entry; the now-numeric `confidence` (0.3–0.9) still travels in the learning cell.

**Project vs global scope** (the `project_key` column): a **git-remote hash** = a **PROJECT** learning — consulted **only** when the current repo's git-remote hash matches, so a learning from project A no longer leaks into project B. A **`global`** value (or a blank/legacy cell) = a **GLOBAL** learning — consulted on **every** run. The Caster therefore consults **global + current-project** entries only (`references/caster.md` step 0). **Optional promotion (human-gated):** a PROJECT learning that recurs across **2+ distinct projects** with **average `confidence` ≥ 0.8** MAY be promoted to global (set its `project_key → global`) — still an advisory default, never a hard rule, in the same single-markdown store.

Per-environment: this file lives in the installed skill; learnings are local unless the human promotes them upstream. (On Codex the synced copy lives alongside the `AGENTS.md` pointer; on Gemini under `~/.gemini/agents/dreamteam/` — see `references/platforms.md`.)
