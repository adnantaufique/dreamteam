# Dreamteam — Platforms (per-CLI tool / dispatch / model-tier map)

Dreamteam runs on **Claude Code**, **Codex CLI**, **Gemini CLI**, and **CodeWhale**. The loop, gate, and Caster are CLI-agnostic; only three things resolve per platform — **tool names**, **subagent dispatch**, and **the concrete model behind each abstract tier**. This file is the source of truth for all four. Default `--platform auto` (detect the host); `--platform claude|codex|gemini|codewhale` overrides.

## Tool-name map
The skill is authored in Claude Code tool names; on other CLIs read them as:

| dreamteam (Claude Code) | Gemini CLI | Codex CLI | CodeWhale |
|---|---|---|---|
| Read / Write / Edit | read_file / write_file / replace | per `references/codex-tools.md` (superpowers) | native file read/write/edit (Claude-Code-style) |
| Bash / Grep / Glob | run_shell_command / grep_search / glob | per `references/codex-tools.md` | native shell + search |
| Agent tool (dispatch subagent) | `@generalist` / `@code-reviewer` (named agents) | custom agent / spawn | a CodeWhale subagent |
| Skill / WebSearch / WebFetch | activate_skill / google_web_search / web_fetch | per `references/codex-tools.md` | `/skills` + MCP-provided web tools |

> The Codex column defers to `references/codex-tools.md`, which ships with the **superpowers** plugin (a REQUIRED compose, see `SKILL.md`) — install superpowers to resolve those tool names.

## Dispatch resolver
Dispatch a "**`<role>` at tier `<T>`**" resolves to:
- **Claude Code:** the Agent tool — `subagent_type=<agent>`, `model=<resolved>`.
- **Gemini:** `@<agent-or-generalist>` carrying the role prompt, with frontmatter `model: <resolved>`.
- **Codex:** a custom agent with `model=<resolved>` (+ optional `model_reasoning_effort`).
- **CodeWhale:** a CodeWhale subagent carrying the role prompt; model selected via `~/.codewhale/config.toml` (`[providers.<id>] model=<resolved>`), the `--provider` flag / `CODEWHALE_MODEL` env, or its auto-mode.
- **Execution mode is always background.** Dispatch the role via the host CLI's background/async form (on Claude Code: the Agent tool's background dispatch / `run_in_background`), never a foreground inline call. The **Workflow tool is Claude-Code-only**: on Claude Code the conductor offers a one-time per-session choice (background subagents [default] | Workflow, per `loop.md`); on Gemini / Codex / CodeWhale there is no Workflow tool → background subagents, no prompt. The `--execution` flag pre-sets that choice (`loop.md`): `--execution workflow` is **Claude-Code-only** — on Codex / Gemini / CodeWhale it is rejected with a note and falls back to background subagents; `--execution background` is valid everywhere.

Parallel workstreams use each CLI's own parallel dispatch. Producers that **mutate files** still get an isolated workspace per `superpowers:using-git-worktrees` (CLI-agnostic).

## Abstract tier → concrete model (source of truth)
The rubric, profiles, and escalation name the **abstract** tiers; resolve them here:

| Tier      | Claude | Gemini             | Codex                                  | CodeWhale (DeepSeek-first)              |
|-----------|--------|--------------------|----------------------------------------|-----------------------------------------|
| cheap     | haiku  | gemini flash-lite  | gpt-5.x-mini                           | deepseek-v4-flash                       |
| standard  | sonnet | gemini flash       | gpt-5.x-codex                          | deepseek-v4-flash                       |
| capable   | opus   | gemini pro         | gpt-5.5                                | deepseek-v4-pro                         |
| max       | fable  | gemini pro (+high) | gpt-5.5 (+high model_reasoning_effort) | deepseek-reasoner (or v4-pro +thinking) |

- Codex exposes `model_reasoning_effort` (an effort lever Claude Code's Agent tool lacks) — usable as an extra dial on Codex.
- **CodeWhale** is multi-provider: `deepseek-chat` aliases to flash, so cheap/standard share `deepseek-v4-flash`; tiers can also map onto Anthropic/OpenAI/MiMo models via `~/.codewhale/config.toml`, or use CodeWhale's auto-mode to pick the model + thinking level per turn. Confirm exact IDs in `~/.codewhale/config.toml` / CodeWhale's `docs/PROVIDERS.md`.
- **Back-compat:** the resolver also accepts F1's Claude reference names — `haiku→cheap`, `sonnet→standard`, `opus→capable`, `fable→max` — so any pre-F3 manifest or `--roster` carrying a concrete Claude tier still resolves on every platform.

## Per-CLI install
- **Claude Code** → `install.ps1` / `install.sh` → `~/.claude/skills/dreamteam`.
- **Gemini** → `gemini-extension.json` + `scripts/sync-to-gemini.{sh,ps1}` mirrors `skill/` (+ `GEMINI.md`) into `~/.gemini/agents/dreamteam/`.
- **Codex** → an `AGENTS.md` entry + `scripts/sync-to-codex` mirrors `skill/` into the Codex skills layout.
- **CodeWhale** → `scripts/sync-to-codewhale` mirrors `skill/` into `~/.codewhale/skills/dreamteam/` (loaded via the `/skills` command); the global-instructions fallback is `~/.agents/AGENTS.md`.

## Graph tool (`graphify`) — engine-level, not per-OS
The optional AST code-graph (`--graph on|off|auto`; `loop.md` §Graph, `SKILL.md` Composes) integrates at the **engine level via portable Python**, **not** through any per-CLI / per-OS skill body — so `--graph` resolves **identically on Claude Code, Codex, Gemini, and CodeWhale**, with no tool-name or dispatch mapping. graphify exposes three cross-platform integration surfaces:
- **CLI** — `graphify <repo>` builds, `graphify --update` refreshes (code-only = AST = free); the conductor shells out via each CLI's Bash / `run_shell_command` equivalent (see the Tool-name map).
- **MCP server** — `graphify --mcp` (`python -m graphify.serve graphify-out/graph.json`) exposes `query_graph` / `get_neighbors` / `shortest_path` / … so any MCP-capable producer or reviewer can query the live graph; register it in the host CLI's MCP settings.
- **git-hook** — `graphify hook install` adds a post-commit hook that re-runs AST extraction on changed files. Install it on the **main working tree only — never in producer worktrees** (`superpowers:using-git-worktrees`): a per-worktree hook would rebuild the graph on every isolated producer commit. (G1 in `loop.md` rides `integrate` on the main tree.)

Install is **uv/pipx, recommend-only** (`recommend.md`); the graph is **infra — never a gate, never a verdict** (`loop.md` §Graph). Absent / `--graph off` / oversized repo → skip silently, the run continues.

Environment / sandbox + worktree handling is inherited from the composed superpowers skills (`using-git-worktrees`, `finishing-a-development-branch`) — dreamteam must use those, not a hand-rolled `git checkout -b`.

`--platform` defaults to **auto**: detect the host by its config-dir marker — `~/.claude` → claude, `~/.gemini` → gemini, `~/.codewhale` → codewhale, `~/.agents` (or an `AGENTS.md`) → codex; `--platform` overrides the guess.
