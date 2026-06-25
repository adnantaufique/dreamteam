param([string]$Target = "$HOME/.agents/skills/dreamteam")
# Mirror the dreamteam skill into the Codex skills layout + add an AGENTS.md pointer.
New-Item -ItemType Directory -Force $Target | Out-Null
Copy-Item skills/dreamteam/SKILL.md $Target -Force
Copy-Item skills/dreamteam/references $Target -Recurse -Force
if (-not (Select-String -Path AGENTS.md -Pattern 'dreamteam' -Quiet -ErrorAction SilentlyContinue)) {
  Add-Content AGENTS.md "- dreamteam: see $Target/SKILL.md (meta-orchestration skill)"
}
Write-Host "synced dreamteam -> $Target"
