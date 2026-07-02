param([string]$Target = "$HOME/.codewhale/skills/dreamteam")
# Mirror the dreamteam skill into the CodeWhale skills layout (loaded via the /skills command).
$Repo = Split-Path -Parent $PSScriptRoot
New-Item -ItemType Directory -Force $Target | Out-Null
Copy-Item "$Repo/skills/dreamteam/SKILL.md" $Target -Force
Copy-Item "$Repo/skills/dreamteam/references" $Target -Recurse -Force
Write-Host "synced dreamteam -> $Target"
