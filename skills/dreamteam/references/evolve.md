# Dreamteam — Layer B (benchmark evolution, opt-in, ai-research)

Layer B is the **opt-in**, benchmark-driven half of continuous improvement — a generations loop for ai-research tasks. Layer A (the per-run retro, `references/retro.md`) is always on; Layer B runs only with `--evolve` on a task that has a real evaluator.

## Layer B — benchmark evolution (opt-in, ai-research)
For an ai-research task with a **scriptable evaluator + held-out ground truth**, `--evolve` runs a generations loop:

```
Caster/meta proposes an approach → producers implement → evaluator scores vs ground truth
  → feedback-agent (references/retro.md) proposes improvements → next generation
```

- **Gate per generation = [methodology reviewer, Reality Checker]** — the data must actually support the claimed metric; the honesty backbone prevents overfitting / leakage "gains".
- **Two engines:** bridge the SIA framework (if installed + the task fits its `tasks/` shape), or run native generations via dreamteam dispatch.
- **Guardrails:** budget-capped (print the budget), human-gated, **ai-research only**. `--evolve generations=N` caps the loop at N generations (default a small budget, e.g. 3); stop at N or when the evaluator plateaus; never report a metric the held-out data doesn't support.
