param([string]$Target = "$HOME/.gemini/agents/dreamteam")
# Mirror the dreamteam skill into the Gemini agents layout.
New-Item -ItemType Directory -Force $Target | Out-Null
Copy-Item skills/dreamteam/SKILL.md $Target -Force
Copy-Item skills/dreamteam/references $Target -Recurse -Force
Copy-Item GEMINI.md,gemini-extension.json $Target -Force -ErrorAction SilentlyContinue
Write-Host "synced dreamteam -> $Target"
