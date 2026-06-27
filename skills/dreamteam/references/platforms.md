# Dreamteam — Platforms (per-CLI tool / dispatch / model-tier map)

Dreamteam runs on **Claude Code**, **Codex CLI**, **Gemini CLI**, **CodeWhale**, and **OpenCode**. The loop, gate, and Caster are CLI-agnostic; only three things resolve per platform — **tool names**, **subagent dispatch**, and **the concrete model behind each abstract tier**. This file is the source of truth for all five. Default `--platform auto` (detect the host); `--platform claude|codex|gemini|codewhale|opencode` overrides.

## Tool-name map
The skill is authored in Claude Code tool names; on other CLIs read them as:

| dreamteam (Claude Code) | Gemini CLI | Codex CLI | CodeWhale | OpenCode |
|---|---|---|---|---|
| Read / Write / Edit | read_file / write_file / replace | per `references/codex-tools.md` (superpowers) | native file read/write/edit (Claude-Code-style) | `read` / `write` / `edit` (native, Claude-Code-aligned) |
| Bash / Grep / Glob | run_shell_command / grep_search / glob | per `references/codex-tools.md` | native shell + search | `bash` / `grep` / `glob` (+ `list`) |
| Agent tool (dispatch subagent) | `@generalist` / `@code-reviewer` (named agents) | custom agent / spawn | a CodeWhale subagent | the `task` tool / `@<agent>` (native subagent) |
| Skill / WebSearch / WebFetch | activate_skill / google_web_search / web_fetch | per `references/codex-tools.md` | `/skills` + MCP-provided web tools | native `skill` tool / native `websearch` (Exa-powered, off by default: needs the OpenCode provider or `OPENCODE_ENABLE_EXA`) / native `webfetch` |

> The Codex column defers to `references/codex-tools.md`, which ships with the **superpowers** plugin (a REQUIRED compose, see `SKILL.md`) — install superpowers to resolve those tool names.

## Dispatch resolver
Dispatch a "**`<role>` at tier `<T>`**" resolves to:
- **Claude Code:** the Agent tool — `subagent_type=<agent>`, `model=<resolved>`.
- **Gemini:** `@<agent-or-generalist>` carrying the role prompt, with frontmatter `model: <resolved>`.
- **Codex:** a custom agent with `model=<resolved>` (+ optional `model_reasoning_effort`).
- **CodeWhale:** a CodeWhale subagent carrying the role prompt; model selected via `~/.codewhale/config.toml` (`[providers.<id>] model=<resolved>`), the `--provider` flag / `CODEWHALE_MODEL` env, or its auto-mode.
- **OpenCode:** a native subagent — markdown in OpenCode's agents dir (`~/.config/opencode/agents/<agent>.md`, or project `.opencode/agents/`) or JSON under `agent` in `opencode.json` — with `mode: subagent` + `model: <provider>/<resolved>`; dispatched via the native `task` tool or `@<agent>`. The model is resolved from the user's **configured provider** (OpenCode is bring-your-own-provider; see the tier table). dreamteam itself loads as a native Agent Skill via the `skill` tool — no AGENTS.md downgrade needed.
- **Execution mode is always background.** Dispatch the role via the host CLI's background/async form (on Claude Code: the Agent tool's background dispatch / `run_in_background`), never a foreground inline call. The **Workflow tool is Claude-Code-only**: on Claude Code the conductor offers a one-time per-session choice (background subagents [default] | Workflow, per `loop.md`); on Gemini / Codex / CodeWhale / OpenCode there is no Workflow tool → background subagents, no prompt. The `--execution` flag pre-sets that choice (`loop.md`): `--execution workflow` is **Claude-Code-only** — on Codex / Gemini / CodeWhale / OpenCode it is rejected with a note and falls back to background subagents; `--execution background` is valid everywhere. **OpenCode caveat:** OpenCode's native `task` dispatch is **synchronous/modal** (blocking) in core, so "background" here means *dispatched via the `task` tool / `@<agent>` rather than the Workflow tool* — not non-blocking-in-chat; the conductor still awaits each result before gating, so the dispatch→await→gate→integrate contract holds either way. True non-blocking background is available only via a community plugin.

Parallel workstreams use each CLI's own parallel dispatch. Producers that **mutate files** still get an isolated workspace per `superpowers:using-git-worktrees` (CLI-agnostic).

## Abstract tier → concrete model (source of truth)
The rubric, profiles, and escalation name the **abstract** tiers; resolve them here:

| Tier      | Claude | Gemini             | Codex                                  | CodeWhale (DeepSeek-first)              | OpenCode (BYO-provider)            |
|-----------|--------|--------------------|----------------------------------------|-----------------------------------------|------------------------------------|
| cheap     | haiku  | gemini flash-lite  | gpt-5.x-mini                           | deepseek-v4-flash                       | provider mini / `small_model`      |
| standard  | sonnet | gemini flash       | gpt-5.x-codex                          | deepseek-v4-flash                       | provider standard                  |
| capable   | opus   | gemini pro         | gpt-5.5                                | deepseek-v4-pro                         | provider large                     |
| max       | fable  | gemini pro (+high) | gpt-5.5 (+high model_reasoning_effort) | deepseek-reasoner (or v4-pro +thinking) | provider top-reasoning (+effort)   |

- Codex exposes `model_reasoning_effort` (an effort lever Claude Code's Agent tool lacks) — usable as an extra dial on Codex.
- **CodeWhale** is multi-provider: `deepseek-chat` aliases to flash, so cheap/standard share `deepseek-v4-flash`; tiers can also map onto Anthropic/OpenAI/MiMo models via `~/.codewhale/config.toml`, or use CodeWhale's auto-mode to pick the model + thinking level per turn. Confirm exact IDs in `~/.codewhale/config.toml` / CodeWhale's `docs/PROVIDERS.md`.
- **OpenCode is provider-agnostic — the column is NOT pinned.** OpenCode is bring-your-own-provider (75+ providers via models.dev), so each tier is the corresponding rung from whatever provider the user configured in `opencode.json` (`model` for the main rungs, native `small_model` for the cheap rung). Model IDs use OpenCode's `provider/model` form. Representative (non-pinned) examples: cheap ↔ `anthropic/claude-haiku-4-5` or `openai/gpt-5-mini`; standard ↔ `anthropic/claude-sonnet-4-5` or `openai/gpt-5`; capable ↔ `anthropic/claude-opus-*` (or `openai/gpt-5` +high); max ↔ the provider's top reasoning model (+ reasoning effort where the provider exposes it). Confirm the active provider's IDs against `opencode.json` + models.dev.
- **Back-compat:** the resolver also accepts F1's Claude reference names — `haiku→cheap`, `sonnet→standard`, `opus→capable`, `fable→max` — so any pre-F3 manifest or `--roster` carrying a concrete Claude tier still resolves on every platform.

## Per-CLI install
- **Claude Code** → `install.ps1` / `install.sh` → `~/.claude/skills/dreamteam`.
- **Gemini** → `gemini-extension.json` + `scripts/sync-to-gemini.{sh,ps1}` mirrors `skill/` (+ `GEMINI.md`) into `~/.gemini/agents/dreamteam/`.
- **Codex** → an `AGENTS.md` entry + `scripts/sync-to-codex` mirrors `skill/` into the Codex skills layout.
- **CodeWhale** → `scripts/sync-to-codewhale` mirrors `skill/` into `~/.codewhale/skills/dreamteam/` (loaded via the `/skills` command); the global-instructions fallback is `~/.agents/AGENTS.md`.
- **OpenCode** → `scripts/sync-to-opencode.{sh,ps1}` mirrors `SKILL.md` + `references/` into `~/.config/opencode/skills/dreamteam/` (OpenCode's native Agent-Skills home, loaded on-demand via the native `skill` tool). **No-sync shortcut:** OpenCode also natively reads `~/.claude/skills/<name>/SKILL.md`, so a dreamteam already installed via `install.sh` is auto-discovered there with no extra step. Global-instructions fallback: `~/.config/opencode/AGENTS.md` (or the shared root `AGENTS.md`, which OpenCode reads natively). The skill loader injects `SKILL.md` only; `references/*.md` are read on demand via the file `read` tool from the synced folder — the same on-disk mechanism the other non-Claude syncs already rely on.

## Graph tool (`graphify`) — engine-level, not per-OS
The optional AST code-graph (`--graph on|off|auto`; `loop.md` §Graph, `SKILL.md` Composes) integrates at the **engine level via portable Python**, **not** through any per-CLI / per-OS skill body — so `--graph` resolves **identically on Claude Code, Codex, Gemini, CodeWhale, and OpenCode**, with no tool-name or dispatch mapping. graphify exposes three cross-platform integration surfaces:
- **CLI** — `graphify <repo>` builds, `graphify --update` refreshes (code-only = AST = free); the conductor shells out via each CLI's Bash / `run_shell_command` equivalent (see the Tool-name map).
- **MCP server** — `graphify --mcp` (`python -m graphify.serve graphify-out/graph.json`) exposes `query_graph` / `get_neighbors` / `shortest_path` / … so any MCP-capable producer or reviewer can query the live graph; register it in the host CLI's MCP settings.
- **git-hook** — `graphify hook install` adds a post-commit hook that re-runs AST extraction on changed files. Install it on the **main working tree only — never in producer worktrees** (`superpowers:using-git-worktrees`): a per-worktree hook would rebuild the graph on every isolated producer commit. (G1 in `loop.md` rides `integrate` on the main tree.)

Install is **uv/pipx, recommend-only** (`recommend.md`); the graph is **infra — never a gate, never a verdict** (`loop.md` §Graph). Absent / `--graph off` / oversized repo → skip silently, the run continues.

Environment / sandbox + worktree handling is inherited from the composed superpowers skills (`using-git-worktrees`, `finishing-a-development-branch`) — dreamteam must use those, not a hand-rolled `git checkout -b`.

`--platform` defaults to **auto**: detect the host by its config-dir marker — `~/.claude` → claude, `~/.gemini` → gemini, `~/.codewhale` → codewhale, `~/.config/opencode` (or an `opencode.json`) → opencode, `~/.agents` (or an `AGENTS.md`) → codex; `--platform` overrides the guess. **Order matters:** OpenCode also reads `~/.agents`/`AGENTS.md` (and `~/.claude/skills`), so its distinctive `~/.config/opencode` marker is checked **before** the `~/.agents` → codex fallback.
