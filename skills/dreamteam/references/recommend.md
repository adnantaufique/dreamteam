# Dreamteam — Recommend (the Caster's skill discovery, skills-only)

When a role/capability has no good *installed* skill, the Caster may discover and **recommend** one. This file defines the two sources, the trust ranking, the ephemeral `recommendations[]` schema, and the opt-in `setup` installer.

> **INVARIANT:** The Caster only selects + recommends — **discovery in, advice out**. It never installs, persists, or executes. Installation is a dispatched, gated producer (the `setup` role), never a Caster/conductor action.

## Sources

### skills.sh via `find-skills` (primary — installable skills)
- Discovers skills **not** yet installed and carries the **install command** (`npx skills add …`).
- Has built-in **quality gates** — prefer ≥1K installs / official sources / GitHub stars; *don't recommend on search results alone*.
- Nothing clears the bar → **recommend nothing** (omitted beats a weak pick).

### awesome-claude-code (secondary — Claude-only)
- Read the machine-readable **`THE_RESOURCES_TABLE.csv`** (a few hundred curated rows — do **not** assert a precise count; columns incl. Category, Primary Link, Author, License + health flags `Active, Stale, Removed From Origin, Last Checked`). **Not** the prose README (mid-reorg, parse-hazard).
- **Discovery** = fetch the CSV + filter by Category + keyword; **cache per run** (fetch only when a real gap exists).
- **Skip** rows where `Active=FALSE` / `Stale=TRUE` / `Removed From Origin=TRUE`. Surface `NOASSERTION`/blank licenses honestly.
- **No install command** (GitHub link only) → these rows are `installable: false` and the `install` field is **OMITTED**. Never synthesize a fake `npx skills add` for a GitHub-only resource.
- **Unique value:** the non-skill resources `find-skills` can't surface — Slash-Commands, Hooks, CLAUDE.md, Status Lines, Workflows — plus a curation cross-check.

### Trust ranking
- Prefer a candidate present in **BOTH** (curated + high-install).
- **skills.sh wins** for installable skills.
- **The CSV wins** as the only source for non-skill resources, and as a curation cross-check.

## graphify — recommend-only external tool (the AST code-graph)
`graphify` (safishamsi, **MIT**) is an external **AST code-graph** CLI/MCP tool dreamteam uses as **optional conductor navigation infra** (`--graph on|off|auto`; `SKILL.md` Composes, `loop.md` §Graph). It is **RECOMMEND-only — never vendored, never auto-installed** — and is **not** discovered via `find-skills` or the awesome-claude-code CSV (it is a Python tool, not a Claude skill), so it is registered here directly.
- **When to recommend** (emit a `recommendations[]` entry): a **codebase-understanding** task, or the **`audit` profile** (especially `--mode map`), or dev producers / Code Reviewer (`caster.md`) — on a repo where `graphify` isn't installed and `--graph` isn't `off`.
- **Install — uv/pipx, no auto-confirm** (the human runs it): `uv tool install graphifyy && graphify install` (fallback `pipx install graphifyy && graphify install`). The package is **`graphifyy`**; the command is **`graphify`**. Portable Python → the **same command on every `--platform`** (`platforms.md`); no Claude-only form.
- **Degrade gracefully:** absent / `--graph off` / oversized repo → the run proceeds without the graph (agents read the tree directly). The graph is **infra, never a gate, and never decides a verdict** (`loop.md` §Graph).

## `recommendations[]` schema
Per-run **ephemeral** — advisory, **NOT persisted to `learnings.md`**. De-dup by candidate within a run.
```
recommendations: [
  { for: "<role|capability>", source: "skills.sh"|"awesome-claude-code",
    candidate: "<owner/repo@skill or repo link>",   // a REAL source hit, never invented
    why: "<one line: the gap it closes>",
    trust: "<install-count+source | curated+license+health>",
    installable: true|false,
    install: "<platform-resolved cmd; OMITTED when installable:false>",
    proceeding_with: "<best installed alternate | 'omitted'>" }
]
```

## The opt-in `setup` installer role
Default = **recommend-and-print** (the human runs the command). The installer is **OPT-IN**.

**Flow:**
1. Caster **recommends** (prints `recommendations[]`).
2. **Human approves a specific candidate** — a genuine stop. `--autonomy auto` does **NOT** bypass it; a relayed/coordinator approval does not satisfy it — only the actual user's.
3. The conductor dispatches a **pre-flight `setup` producer** (`general-purpose@cheap` + `find-skills`) that runs the **ONE pinned, approved** install command for the active `--platform`.
4. The **gate** verifies **(a)** the skill is now present, **(b)** installed identity == approved candidate (owner/repo@skill + source — no substitution), **and (c)** the **dispatched install command was the pinned approved one carrying no `-y`/auto-confirm flag**.
5. **PASS** → the conductor **re-casts** (re-enters precedence, `caster.md`) so the now-installed skill attaches. Re-cast **at most once per approved set**, and a re-cast must **NOT** generate a new recommendation for the same set.
6. **FAIL** → escalate to the human; proceed with best-available.

**Tier rationale:** the `setup` producer is `@cheap` because the command is fixed/deterministic; safety comes from the **capable-tier gate**, not the producer tier.

### HARD constraints
1. **Forbid** `find-skills`' `-y`/auto-add on this path — the **exact pinned approved command only**; the producer cannot self-approve.
2. The human approval is a **genuine stop** `--autonomy auto` cannot bypass.
3. **Install-only, exactly ONE pinned package** — no version negotiation, dependency resolution, upgrades, or `npx skills update`. **Not a standing capability.**
4. The gate verifies the **command** (== pinned, no `-y`), not just the result — a `-y` invocation is a **needs-work** even if the right package landed.

## Cross-platform
- Resolve the install command per `--platform` / `platforms.md`.
- The awesome-claude-code source is **Claude-only**: under any non-Claude `--platform` (gemini/codex/codewhale), **suppress** its Claude-specific recommendations (hooks/commands/status-lines/CLAUDE.md).
