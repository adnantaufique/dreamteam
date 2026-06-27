# Dreamteam — Recommend (the Caster's skill discovery, skills-only)

When a role/capability has no good *installed* skill, the Caster may discover and **recommend** one. This file defines the discovery sources (`find-skills` + the awesome-claude-code CSV), the six component upstreams it recommends from, the trust ranking, the ephemeral `recommendations[]` schema, and the opt-in `setup` installer.

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

### Component upstreams (recommend to refresh or extend — never auto-installed)
The provenance of dreamteam's bundled and depended-on components. When a profile needs a component beyond the vendored subset — an extra agent, skill, or command — the Caster **recommends** the matching source command and the human runs it. All commands carry **no `-y`/auto-confirm**. The `/plugin …` form is **Claude-only**: under a non-Claude `--platform`, use the git/npx/pip fallback and suppress the Claude-only form (same rule as the awesome-claude-code source above).

| Source | SPDX | Role here | Install command (no auto-confirm) | Non-Claude fallback |
|---|---|---|---|---|
| agency-agents (msitarzewski) | MIT | vendored subset — recommend to pull more named agents | `git clone https://github.com/msitarzewski/agency-agents && agency-agents/scripts/install.sh --tool claude-code` | same clone; pass the matching `--tool` (e.g. `codex`/`gemini`) |
| ECC (affaan-m) | MIT | vendored subset — recommend extra reviewers/resolvers/skills/commands | `/plugin marketplace add https://github.com/affaan-m/ECC` then `/plugin install ecc@ecc` | `npx ecc-install --profile minimal --target <platform>` |
| SuperClaude (SuperClaude-Org) | MIT | vendored subset — recommend the broader `sc:*` agent/command suite | `pipx install SuperClaude && SuperClaude install` | Gemini: `pipx install SuperGemini && SuperGemini install` · Codex: `pipx install SuperCodex && SuperCodex install` |
| superpowers (obra) | MIT | depended-on — recommend to install the 5 sub-skills + `systematic-debugging` | `/plugin marketplace add obra/superpowers-marketplace` then `/plugin install superpowers@superpowers-marketplace` | per superpowers docs (manual skill sync) |
| ui-ux-pro-max (nextlevelbuilder) | MIT | depended-on — recommend to install for the `ux-designer` + design roles | `/plugin marketplace add nextlevelbuilder/ui-ux-pro-max-skill` then `/plugin install ui-ux-pro-max@ui-ux-pro-max-skill` | `npm install -g ui-ux-pro-max-cli && uipro init --ai claude` |

The sixth source, **graphify** (safishamsi, MIT), is registered in its own section below — recommend-only, never vendored.

These are **plugin/git/npm/pip** upstreams, so they stay on the **recommend-and-print** path: the Caster names the source and prints the command, the human runs it. They are **not** eligible for the skills-only, one-pinned `npx skills add` auto-`setup` flow below (that path installs skills.sh skills only). Discovery in, advice out — the Caster never installs.

**Optional reviewer lenses (host-present only — name, do not vendor).** If one of these is already installed on the host, the Caster *may* add it as an extra reviewer for its gate dimension. None is bundled or auto-installed; absent, the gate runs without it (Reality Checker + the profile's named reviewers still cover the verdict):
- `silent-failure-hunter` — swallowed errors, empty catches, ignored return values
- `type-design-analyzer` — type-model soundness, making illegal states unrepresentable
- `comment-analyzer` — comments that no longer match the code
- `code-simplifier` / `refactor-cleaner` — over-engineering cleanup (overlaps `ponytail` + the gate's native over-engineering flag; add only when the host already has it)

**ECC recommend-targets (awareness only — recommend from the ECC source above, add no machinery).** Three ECC capabilities worth surfacing when a run hits the matching need; dreamteam does not adopt their machinery:
- `search-first` — reuse-before-build search (dreamteam's native minimal-code + `ponytail` already cover this; recommend ECC's if the user wants the dedicated agent)
- `skill-stocktake` — audits installed-skill quality (a maintainer/curation tool, not a runtime role)
- `context-budget` — ECC's token/context-budget discipline for long runs

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
- The awesome-claude-code source is **Claude-only**: under any non-Claude `--platform` (gemini/codex/codewhale/opencode), **suppress** its Claude-specific recommendations (hooks/commands/status-lines/CLAUDE.md).
