param([string]$Target = "$HOME/.gemini/agents/dreamteam")
# Mirror the dreamteam skill into the Gemini agents layout.
$Repo = Split-Path -Parent $PSScriptRoot
New-Item -ItemType Directory -Force $Target | Out-Null
Copy-Item "$Repo/skills/dreamteam/SKILL.md" $Target -Force
Copy-Item "$Repo/skills/dreamteam/references" $Target -Recurse -Force
Copy-Item "$Repo/GEMINI.md","$Repo/gemini-extension.json" $Target -Force -ErrorAction SilentlyContinue
Write-Host "synced dreamteam -> $Target"
