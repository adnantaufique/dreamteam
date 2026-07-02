param([string]$Target = "$HOME/.config/opencode/skills/dreamteam")
# Mirror the dreamteam skill into OpenCode's native Agent-Skills layout (loaded on-demand via the native `skill` tool).
# Note: OpenCode also natively reads ~/.claude/skills, so a dreamteam installed via install.ps1 is already discoverable — this sync is for OpenCode-only setups.
$Repo = Split-Path -Parent $PSScriptRoot
New-Item -ItemType Directory -Force $Target | Out-Null
Copy-Item "$Repo/skills/dreamteam/SKILL.md" $Target -Force
Copy-Item "$Repo/skills/dreamteam/references" $Target -Recurse -Force
Write-Host "synced dreamteam -> $Target"
