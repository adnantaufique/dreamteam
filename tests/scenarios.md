# Dreamteam — Validation Scenarios (subagent tests)

Each scenario is run by dispatching a fresh **`general-purpose`** subagent, giving it the named skill file(s) (or the installed skill) + the input, and asserting its output matches **Expected**. Re-run after any edit. There is no code compiler — *the subagent's behavior is the test*. Where noted, **judge coherence, not exact agent picks**.

Install first so installed-skill scenarios see the latest copy: `pwsh ./install.ps1` (Windows) or `bash ./install.sh` (Linux/macOS) — publishes `skills/dreamteam/` → `~/.claude/skills/dreamteam/`.

## S1 — profile fast-path (`references/profiles.md`)
- **Input:** `profiles.md` + task "build an Android TV app".
- **Expected:** the **mobile-dev** dreamteam — producer Mobile App Builder (+ UI Designer for design), gate **[Code Reviewer, Reality Checker]**, `sequential`. Each role carries its default tier (Mobile App Builder@standard, UI Designer@cheap, reviewers@capable; abstract tiers, resolved per platform).

## S2 — Caster agent, no profile (`references/caster.md`)
- **Input:** `caster.md`; act as the Caster agent for task "harden and load-test our REST API" (no `--profile`/`--roster`).
- **Expected:** a coherent dreamteam manifest — a planner; producer(s) (e.g. Backend Architect / API Tester / Performance Benchmarker / Security Engineer); `reviewers` **including Reality Checker**; `gate_policy`; `workstream_strategy`; one-line rationale per pick. *Judge coherence, not exact picks.*

## S3 — gate synthesis + honesty (`references/gate.md`)
- **Input:** `gate.md` + two mock reviews: (1) Code Reviewer "Approve-with-changes" — a real **High** (resource leak, found by code-read) + a **predicted High** (build break); (2) Reality Checker "PASS" whose green build **refutes** the predicted build break and which did **not** exercise the leak path.
- **Expected:** keeps the leak as the surviving **must-fix**; **drops** the refuted build-break (evidence beats prediction); verdict = **fix-then-pass**.

## S4 — core loop + isolation (`references/loop.md`)
- **Input:** `loop.md` + `gate.md` + a 2-workstream **parallel** plan (both producers mutate the same server file) + a parallel manifest.
- **Expected:** describes **produce→gate→fix→integrate** per workstream; gives **each parallel file-mutating producer its own git worktree**; surfaces **each** workstream's gate verdict; integrates only on pass; needs-work → stop + escalate.

## S5 — end-to-end dry-run (installed `SKILL.md`)
- **Input:** installed skill; invocation `/dreamteam "add OAuth login to our web app" --autonomy confirm`. Dry-run (no execution).
- **Expected:** resolves + prints the **web** dreamteam (+ Security Engineer for auth, + Reality Checker) with rationale; describes the produce→gate→fix→integrate loop; **stops for confirmation, does not execute**.

## S6 — model-tier assignment (`references/caster.md`)
- **Input:** `caster.md` + a mixed task with a clear mechanical sub-task, an integration sub-task, and review — e.g. "add a config constant (1 file) and refactor the auth middleware across the service, then review"; no `--profile`/`--models`.
- **Expected:** the manifest assigns the **mechanical role → cheap**, the **integration role → standard**, **reviewers → capable** (incl. Reality Checker), **max not used as a default**, and each rationale line names the tier. *Assert the tiers exactly (cheap/standard/capable); judge only the agent-name picks for coherence.*

## S7 — tier escalation (`references/loop.md` + `references/gate.md`)
- **Input:** `loop.md` + `gate.md` + a single workstream whose first producer (dispatched at **cheap**) returns output the gate rules **needs-work** (a real High that isn't fixed); plus a `NEEDS_CONTEXT` variant.
- **Expected:** re-dispatches the fix **one tier up (cheap→standard)**, capped at `max_fix_iterations` then escalates to the human; reports the **tier path** (standard→…); the `NEEDS_CONTEXT` variant stays at **cheap** + adds context (no tier bump).

## S8 — retro learnings (`references/retro.md`)
- **Input:** `retro.md` + a mock run record (two workstreams: one passed clean; one escalated cheap→capable after a needs-work on a resource leak).
- **Expected:** emits a learnings record matching the schema, with **evidence-tagged `change` deltas** (e.g. `{target:tier, delta:"default the leak-prone role to capable", evidence:"escalated twice on the leak"}`); flags any skill-editing delta as **proposed/human-gated**; records nothing it can't cite run evidence for.

## S9 — Caster consults learnings (`references/caster.md` + `references/learnings.md`)
- **Input:** `caster.md` + a `learnings.md` seeded with one entry (`android | keep the ExoPlayer-leak check as a must-fix; default the build role to capable | evidence: escalated twice`). Task "build an Android TV app".
- **Expected:** adjusts the **mobile-dev** pick accordingly (the `android` learnings key normalizes to `mobile-dev`; build role → capable; leak check noted) **and** treats it as an **overridable default** (states it could override), not a hard rule.

## S10 — Layer B evolve dry-run (`references/evolve.md`)
- **Input:** `evolve.md` + an ai-research task + `--evolve`. Dry-run (no execution).
- **Expected:** describes the generations loop with `[methodology reviewer, Reality Checker]` per generation, a budget, the human gate, and the leakage caution — **without executing** — and confirms it's opt-in / ai-research-only.

## S11 — cross-CLI tier + dispatch resolution (`references/platforms.md`)
- **Input:** `platforms.md` + these asks: (a) resolve **tier=cheap** for Claude Code, Gemini, Codex, CodeWhale; (b) resolve **tier=max** for all four; (c) back-compat: resolve a role carrying the Claude name **`sonnet`** on Gemini.
- **Expected:** (a) `haiku` / `flash-lite` / `gpt-5.x-mini` / `deepseek-v4-flash`, each with the right dispatch verb (Agent tool `model:` / `@generalist` frontmatter `model:` / Codex custom agent `model=` / CodeWhale subagent via config.toml); (b) `fable` / `gemini pro (+high)` / `gpt-5.5 (+high model_reasoning_effort)` / `deepseek-reasoner`; (c) `sonnet→standard→gemini flash`. A single-tier pass is insufficient — ≥2 tiers + the back-compat input must hold.

## S12 — orchestration adherence (`SKILL.md` §"You are the conductor" + `references/loop.md`)
- **Input:** give a subagent the installed/fixed skill + a multi-workstream task with an *easy* workstream (e.g. GET /health + a request-id middleware + a **one-line README badge**). Ask it, as the conductor, whether it produces the easy badge workstream **inline** or **dispatches** a producer for it — and to cite the governing rule.
- **Expected:** it answers **dispatch for EVERY workstream (including the easy badge)**, cites the imperative conductor rule + the "trivial → inline" red flag that counters it, and notes the mandatory "Dispatching … for WS-N" re-anchor; if dispatch is genuinely unavailable it **says so and pauses**, never silently producing inline.

> The tier vocabulary is abstract (`cheap/standard/capable/max`, resolved per `references/platforms.md`); re-run **S1–S7** for selection/gate/escalation, **S8–S10** for the retro/learnings/evolve loop, **S11** for cross-CLI resolution, and **S12** for conductor adherence.

## S13 — minimal-code principle (native) + ponytail amplifier (`SKILL.md` + `references/loop.md`/`gate.md`/`caster.md`)
- **Input:** a code task (e.g. "add a JSON config loader to our CLI"). Consider both: (a) `ponytail` absent, (b) `ponytail` installed.
- **Expected:** in **both** cases the producer aims for the *simplest solution that fully works* and the gate's Code Reviewer flags **over-engineering** — never by cutting validation/security/accessibility — because minimal-code is **native** to dreamteam (SKILL.md Overview + loop.md + gate.md), NOT gated on the skill. When `ponytail` IS installed, the Caster additionally attaches it to the code producer's `skills[]` as the enforcer. Absent ponytail ≠ no minimal-code check.

## S14 — advisory recommend (skills-only) (`references/recommend.md` + `references/caster.md`)
- **Input:** `recommend.md` + `caster.md`; act as the Caster for a task whose best-fit skill is **discoverable-but-not-installed** (via `find-skills`/skills.sh), with a weaker skill already installed. Plus a variant where **nothing** clears the quality bar.
- **Expected:** records a `recommendations[]` entry (a **verified** candidate + `why` + `trust` + `install` cmd + **`proceeding_with` naming the alternate it ran with, or `'omitted'`**), **proceeds with the best available** installed option, and **never blocks**. In the variant where nothing clears the bar → **no** recommendation (omitted beats a weak pick). The Caster still only selects — it recommends, never installs.

## S15 — awesome-claude-code CSV (Claude-only) (`references/recommend.md` + `references/platforms.md`)
- **Input:** `recommend.md` + `platforms.md`; a **Claude-Code** task needing a **non-skill** resource `find-skills` can't surface (e.g. a hook) → the Caster discovers from `THE_RESOURCES_TABLE.csv`. Plus the same ask under a non-Claude `--platform` (gemini/codex/codewhale).
- **Expected:** the recommendation is sourced from the CSV with **`installable:false`** (the `install` field **omitted** — no synthesized `npx skills add`), **health-flag-filtered** (skip rows with `Stale=TRUE`/`Removed From Origin=TRUE`/`Active=FALSE`), with licenses surfaced honestly. Under **any non-Claude `--platform`** the Claude-specific recommendation is **suppressed**.

## S16 — opt-in installer role (`references/recommend.md` + `references/gate.md`)
- **Input:** `recommend.md` + `gate.md`; a recommended candidate **with explicit user approval** → a gated `setup` producer (`general-purpose@cheap` + `find-skills`). Cover: (a) the pinned cmd carrying no `-y`; (b) a `-y` invocation that lands the right package; (c) `--autonomy auto`; (d) a substituted/typosquatted package.
- **Expected:** (a) the `setup` producer runs the **ONE pinned approved cmd (no `-y`)**, the gate verifies **presence + identity/source + that the command carried no `-y`**, the conductor **re-casts** (≤ once per approved set) and the skill attaches; (b) a `-y` invocation is **rejected (needs-work) even if the right package landed** (the gate checks the command, not just the result); (c) `--autonomy auto` does **NOT** bypass the human approval / auto-install; (d) a substituted/typosquatted package **fails** the identity gate.

## S17 — F6 (Karpathy fold-in) (`references/loop.md` + `references/gate.md`)
- **Input:** `loop.md` + `gate.md`; a producer dispatched with an **explicit, verifiable success criterion**, whose output exhibits **both** over-engineering **and** gratuitous diff scope (unrequested refactors/reformatting of untouched code); plus a variant with **genuine ambiguity** in the spec.
- **Expected:** the dispatch carries the explicit success criterion (what the gate will check — not "make it work"); the gate raises **both** `over-engineering` **and** `gratuitous diff scope` as findings; on genuine ambiguity the producer returns **NEEDS_CONTEXT** (surface assumptions first) — **not a silent guess**.

> S14–S17 are additive (selection/gate/loop/principles unchanged; the Caster still only selects — now also recommends); re-run S1–S13 as regression.

## S18 — audit/bugs (`references/audit.md` + `references/gate.md` + `references/loop.md`)
- **Input:** `audit.md` + `gate.md` + `loop.md`; an `audit` run (mode `bugs`) over existing code — dimension reviewers (e.g. correctness/security/performance) fan out, plus a bare `--profile audit` variant with no mode given.
- **Expected:** the dimension reviewers fan out **as producers** (read-only finding-hunters, not the gate); the gate **confirms a real bug and refutes a false positive** (evidence beats prediction); the run is **read-only — `integrate` is a no-op** (no worktree merge, nothing written back); a refuted finding is **dropped from the report, not the whole report**; bare `--profile audit` defaults to **`bugs`**.

## S19 — audit/map + depth (`references/audit.md`)
- **Input:** `audit.md`; an `audit` run (mode `map`) over a repo, run at `--depth shallow` and again at `--depth exhaustive`.
- **Expected:** mode `map` produces a **structured project model** (not a bug list); `--depth shallow` vs `exhaustive` **changes fan-out breadth**; **`exhaustive` is budget-printed + confirm-gated**; fan-out is **capped by `audit_policy.max_parallel_reviewers`**.

## S20 — mutation/mock-integrity (`references/gate.md`)
- **Input:** `gate.md` + a producer's test suite that is **green**, including (a) a test that **passes against a deliberately broken implementation** and (b) a test that **mocks the very unit under test**.
- **Expected:** both are a **must-fix** — a test that **survives a broken implementation** or **mocks the unit under test** proves nothing, **even though it's "green"** (passing ≠ verifying).

## S21 — devil's-advocate-on-unanimous (`references/gate.md`)
- **Input:** `gate.md` + (a) a **3-reviewer unanimous PASS**, (b) a **2-reviewer** unanimous pass, and (c) the same 3-reviewer unanimous pass **outside the `audit` profile**.
- **Expected:** (a) the unanimous PASS triggers **one** adversarial reviewer **once** (outside the fix loop), whose **unevidenced prediction is dropped** on reconciliation; (b) a **2-reviewer** pass does **NOT** trigger it (threshold is 3); (c) it is **off by default outside the `audit` profile**.

## S22 — mobile-dev rename (`references/profiles.md`)
- **Input:** `profiles.md` + tasks "build an Android TV app", "build a React Native app", "an iOS app"; plus `--profile android`; plus a `learnings.md` row keyed `android`.
- **Expected:** all three tasks **resolve to `mobile-dev`** (keyword widening across Android/React Native/iOS, **not** the Caster fallback); `--profile android` **resolves to `mobile-dev`** (alias kept for back-compat); a learnings row keyed `android` **still matches** the renamed profile.

> S18–S22 are additive (audit profile + gate sharpenings + the mobile-dev rename); re-run S1–S17 as regression.

## S23 — execution mode (F10) (`SKILL.md` + `references/loop.md` + `references/platforms.md`)
- **Input:** a dreamteam run reaching its **first dispatch**, on **Claude Code** and (variant) on **Gemini**.
- **Expected:** the conductor dispatches in the **background** (never a foreground/inline Agent call); on the **first dispatch** it asks **once** "background subagents or Workflow? [background]" and uses that choice for the **session** (defaults to **background** if no answer); the mode is **surfaced in the re-anchor line**; the **Workflow option is offered only on Claude Code** (Gemini/Codex/CodeWhale → background, **no prompt**); the conductor still **awaits each result then gates** (background ≠ fire-and-forget); best-effort if the choice falls out of context (**re-ask, don't assume**).

## S24 — session stickiness + carve-out (F11) (`SKILL.md`)
- **Input:** after a dreamteam run: (a) a second artifact-producing task; (b) a pure Q&A; (c) a genuinely tiny edit (one-line typo, **not** part of any plan); (d) a one-line change that **IS** a unit of the current plan; (e) the user says "stop using dreamteam this session".
- **Expected:** (a) runs **through dreamteam** (sticky); (b) **answered directly** (out of scope — no artifact); (c) **MAY** be inline via the carve-out **only after** the conductor **states the classification** and it passes **ALL** bounds (≲5 lines / one file / no new logic / no security-validation-a11y), any doubt → **dispatch**; (d) **dispatched** (a small *workstream* is not the carve-out); (e) stickiness **off for the session**, a later `/dreamteam` **re-arms**.

## S25 — `--execution` flag pre-sets the session mode (`SKILL.md` + `references/loop.md` + `references/platforms.md`)
- **Input:** a dreamteam run reaching its **first dispatch**: (a) `/dreamteam … --execution workflow` on **Claude Code**; (b) `/dreamteam … --execution background`; (c) `/dreamteam … --execution workflow --platform gemini`; (d) the **same run with no `--execution` flag**.
- **Expected:** the flag **IS the answer** to the one-time choice, so the conductor **does NOT ask** "Background subagents or the Workflow tool?" — (a) session = **Workflow** mode (Claude-only), prompt **skipped**, mode **surfaced in the first re-anchor line**; (b) session = **background**, prompt **skipped**, surfaced the same way; (c) `workflow` is **INVALID on a non-Claude platform** (no Workflow tool) → **noted clearly + falls back to background subagents**; (d) **no regression** — with no flag the one-time per-session prompt **still governs** (asked once, **default background**, per loop.md). The flag **only pre-sets the existing one-time session choice** — dispatch is still **always background**, there is **no per-workstream re-prompt**, and the produce→gate→fix→integrate loop is **identical**.

> S1–S24 are re-run as regression — these additions are additive.

## Grounding A — Android build (dry-run)
- **Input:** installed skill; `/dreamteam "build an Android TV app from its spec"`. Selection + description only.
- **Expected:** picks the **mobile-dev** profile dreamteam (Mobile App Builder + UI Designer); **sequential** workstreams; gate **[Code Reviewer, Reality Checker]**.

## Grounding B — ML research salvage (dry-run)
- **Input:** installed skill; `/dreamteam --profile ai-research "salvage a failed-hypothesis study: expand new directions ∥ polish current findings for publication"`. Selection + description only.
- **Expected:** picks the **ai-research** dreamteam; **two parallel workstreams** (*expand* ∥ *polish*); gate **[a methodology reviewer, Reality Checker]**.
