param([string]$Target = "$HOME/.codewhale/skills/dreamteam")
# Mirror the dreamteam skill into the CodeWhale skills layout (loaded via the /skills command).
New-Item -ItemType Directory -Force $Target | Out-Null
Copy-Item skills/dreamteam/SKILL.md $Target -Force
Copy-Item skills/dreamteam/references $Target -Recurse -Force
Write-Host "synced dreamteam -> $Target"
