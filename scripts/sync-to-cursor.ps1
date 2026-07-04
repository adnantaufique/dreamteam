param([string]$Target = "$HOME/.cursor/skills/dreamteam")
# Mirror the dreamteam skill into Cursor's native Agent-Skills layout (auto-matched on the skill description).
# Note: Cursor also reads ~/.claude/skills for compatibility, so a dreamteam installed via install.ps1 is already discoverable — this sync is for Cursor-only setups.
$Repo = Split-Path -Parent $PSScriptRoot
New-Item -ItemType Directory -Force $Target | Out-Null
Copy-Item "$Repo/skills/dreamteam/SKILL.md" $Target -Force
Copy-Item "$Repo/skills/dreamteam/references" $Target -Recurse -Force
Write-Host "synced dreamteam -> $Target"
