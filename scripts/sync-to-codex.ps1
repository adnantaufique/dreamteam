param([string]$Target = "$HOME/.agents/skills/dreamteam")
# Mirror the dreamteam skill into the Codex skills layout + add an AGENTS.md pointer.
$Repo = Split-Path -Parent $PSScriptRoot
New-Item -ItemType Directory -Force $Target | Out-Null
Copy-Item "$Repo/skills/dreamteam/SKILL.md" $Target -Force
Copy-Item "$Repo/skills/dreamteam/references" $Target -Recurse -Force
if (Test-Path "$HOME/.codex" -PathType Container) {
  $AgentsMd = "$HOME/.codex/AGENTS.md"
  if (-not (Test-Path $AgentsMd) -or -not (Select-String -Path $AgentsMd -Pattern 'dreamteam' -Quiet)) {
    Add-Content $AgentsMd "- dreamteam: see $Target/SKILL.md (meta-orchestration skill)"
  }
} else {
  Write-Host "codex not installed (no ~/.codex) -> skipped AGENTS.md pointer"
}
Write-Host "synced dreamteam -> $Target"
