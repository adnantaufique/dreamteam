# Dreamteam — Full-Lifecycle Wrapper (raw idea → verified result)

When the input is a **raw idea**, not an approved plan, the wrapper sequences existing skills up to the point where the core engine takes over. **It adds no new logic — it only sequences, and it preserves every human-judgment gate.**

## Entry
Use the wrapper when entry detection (`SKILL.md`) sees a **raw idea** ("an app that…", "a tool to…", a vague goal) rather than a plan-ref. A plan-ref skips the wrapper and goes straight to `references/loop.md`.

## The sequence
```
1. brainstorm  → superpowers:brainstorming  → an agreed requirements/design brief   [HUMAN GATE: brainstorming approval]
2. plan        → superpowers:writing-plans   → a reviewed, step-by-step plan          [HUMAN GATE: plan review]
3. (optional) tri-review → architecture-reviewer ∥ system-architect ∥ Reality Checker → resolve findings before any build
4. build       → references/loop.md          → produce → gate → fix → integrate per workstream (dreamteam resolved via caster.md)
```

For an ai-research task invoked with `--evolve`, after a baseline result the conductor MAY enter the Layer-B generations loop (`references/evolve.md`) — opt-in, budget-capped, human-gated. (Layer A, the per-run retro, is always on; see `references/retro.md`.)

## Rules
- **Never skip the human gates.** Brainstorming's approval and the plan review are real stop points — the wrapper waits for the human at each. `--autonomy auto` does **not** bypass them: these are the genuine product/research decisions the run is supposed to pause for.
- **Don't reinvent — compose.** REQUIRED SUB-SKILLS: `superpowers:brainstorming`, `superpowers:writing-plans`. The wrapper invokes them as-is; it does not re-implement discovery or planning.
- **Tri-review is optional** — use it for high-stakes or architecturally risky builds (e.g. a complex app or research build): the three reviewers run in parallel, their findings are resolved into the plan, *then* the build starts.
- Once a reviewed plan exists, hand off to the **core engine** (`references/loop.md`); dreamteam selection happens via `references/caster.md` as usual.
