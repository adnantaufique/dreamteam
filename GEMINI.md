# Dreamteam (Gemini CLI)

This project provides the **dreamteam** meta-orchestration skill. Load its instructions from `skills/dreamteam/`:

- Entry + spine: `skills/dreamteam/SKILL.md`
- Crew selection: `skills/dreamteam/references/caster.md`
- Per-workstream loop: `skills/dreamteam/references/loop.md`
- Review gate: `skills/dreamteam/references/gate.md`
- Profiles: `skills/dreamteam/references/profiles.md`
- Per-CLI tool/dispatch/model-tier map: `skills/dreamteam/references/platforms.md`

On Gemini CLI, read Claude Code tool names and resolve model tiers per `skills/dreamteam/references/platforms.md` (tiers `cheap/standard/capable/max` → gemini `flash-lite/flash/pro`). Dispatch subagents via `@<agent>` (or `@generalist`) carrying the role prompt with frontmatter `model:`.
