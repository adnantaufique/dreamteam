# Manual install of the dreamteam skill to ~/.claude/skills/dreamteam (Windows),
# then a best-effort dependency check. Plugin users can instead run:
#   /plugin marketplace add <owner>/dreamteam  &&  /plugin install dreamteam@dreamteam-marketplace
$dst = "$env:USERPROFILE\.claude\skills\dreamteam"
if (Test-Path $dst) { Remove-Item -Recurse -Force $dst }   # clean mirror: prune stale files
New-Item -ItemType Directory -Force $dst | Out-Null
Copy-Item -Recurse -Force "$PSScriptRoot\skills\dreamteam\*" $dst
if (Test-Path "$dst\SKILL.md") { Write-Output "installed dreamteam skill -> $dst" }
else { Write-Error "install failed: SKILL.md not found in $dst"; exit 1 }

# --- dependency check (best-effort; dreamteam also resolves/substitutes at runtime) ---
$root = $PSScriptRoot
$sk = "$env:USERPROFILE\.claude\skills"
$pl = "$env:USERPROFILE\.claude\plugins\cache"
$depMissing = 0
function Test-PluginSkill($name) {
  [bool](Get-ChildItem -Path $pl -Recurse -Directory -Filter $name -ErrorAction SilentlyContinue |
         Where-Object { $_.FullName -like '*superpowers*' } | Select-Object -First 1)
}
function Test-DepSkill($name) {
  if (Test-Path "$sk\$name") { return $true }
  [bool](Get-ChildItem -Path $pl -Recurse -Directory -Filter "*$name*" -ErrorAction SilentlyContinue | Select-Object -First 1)
}

# vendored agents that ship inside the plugin (path-registered in .claude-plugin\plugin.json)
$bundledAgents = @(
  'vendor\agency-agents\ai-engineer.md','vendor\agency-agents\backend-architect.md',
  'vendor\agency-agents\code-reviewer.md','vendor\agency-agents\devops-automator.md',
  'vendor\agency-agents\frontend-developer.md','vendor\agency-agents\mobile-app-builder.md',
  'vendor\agency-agents\software-architect.md','vendor\agency-agents\technical-writer.md',
  'vendor\agency-agents\reality-checker.md','vendor\agency-agents\test-results-analyzer.md',
  'vendor\agency-agents\performance-benchmarker.md','vendor\agency-agents\ui-designer.md',
  'vendor\ecc\methodology-reviewer.md','vendor\ecc\security-engineer.md',
  'vendor\ecc\build-error-resolver.md','vendor\ecc\pytorch-build-resolver.md',
  'vendor\superclaude\deep-research-agent.md','vendor\superclaude\quality-engineer.md',
  'vendor\superclaude\root-cause-analyst.md','vendor\superclaude\system-architect.md',
  'vendor\superclaude\python-expert.md'
)

Write-Output ""
Write-Output "dependency check (bundled ship with the plugin; depended-on/optional resolve or substitute at runtime):"

# 1) bundled - vendored agents + the mle-workflow skill; ship with the plugin, never 'missing'
Write-Output "  bundled (ship with the plugin):"
$bundleErr = 0
foreach ($f in $bundledAgents) {
  $name = [System.IO.Path]::GetFileNameWithoutExtension($f)
  if (Test-Path (Join-Path $root $f)) { Write-Output "    [ok bundled] $name" } else { Write-Output "    [ERROR] missing from bundle: $f"; $bundleErr++ }
}
if (Test-Path (Join-Path $root 'skills\mle-workflow\SKILL.md')) { Write-Output "    [ok bundled] mle-workflow (skill)" } else { Write-Output "    [ERROR] missing from bundle: skills\mle-workflow\SKILL.md"; $bundleErr++ }

# 2) depended-on - install via README Step 1, or the opt-in installer below
Write-Output "  depended-on (install via README Step 1, or the opt-in installer below):"
foreach ($s in 'brainstorming','writing-plans','using-git-worktrees','verification-before-completion','finishing-a-development-branch') {
  if (Test-PluginSkill $s) { Write-Output "    [ok] superpowers:$s" } else { Write-Output "    [ ! ] superpowers:$s"; $depMissing++ }
}
if (Test-DepSkill 'find-skills')   { Write-Output "    [ok] find-skills" } else { Write-Output "    [ ! ] find-skills (needed for dynamic casting + the recommender)"; $depMissing++ }
if (Test-DepSkill 'ui-ux-pro-max') { Write-Output "    [ok] ui-ux-pro-max" } else { Write-Output "    [ ! ] ui-ux-pro-max (needed for the ux-designer / design roles)"; $depMissing++ }

# 3) optional - recommend-only; resolved or substituted at runtime
Write-Output "  optional (recommend-only; resolved/substituted at runtime):"
foreach ($s in 'creative-thinking-for-research','brainstorming-research-ideas','literature-review','ml-paper-writing','architecture-reviewer') {
  if (Test-DepSkill $s) { Write-Output "    [ok] $s" } else { Write-Output "    [recommend-only] $s (ai-research; install if you use that profile)" }
}
Write-Output "    [built-in] Explore, general-purpose (host-resolved at runtime)"

Write-Output ""
if ($bundleErr -gt 0) { Write-Output "warning: $bundleErr bundled file(s) missing from this checkout - re-clone/re-pull the plugin." }
if ($depMissing -gt 0) { Write-Output "note: $depMissing depended-on item(s) missing - a warning, not an error; paths needing them stay dark until installed." }
else { Write-Output "all depended-on dependencies present." }

# --- opt-in dependency installer (strictly opt-in; default N; never auto-installs) ---
Write-Output ""
Write-Output "required-dependency install commands (registered; same as README Step 1):"
Write-Output "  1) claude plugin marketplace add obra/superpowers-marketplace && claude plugin install superpowers@superpowers-marketplace"
Write-Output "  2) npx skills add vercel-labs/skills --skill find-skills"
Write-Output "  3) claude plugin marketplace add nextlevelbuilder/ui-ux-pro-max-skill && claude plugin install ui-ux-pro-max@ui-ux-pro-max-skill"

$interactive = -not [Console]::IsInputRedirected
if (($depMissing -gt 0) -and $interactive) {
  $reply = Read-Host "Install the required dependencies now? [y/N]"
  if ($reply -eq 'y' -or $reply -eq 'Y') {
    Write-Output "installing depended-on dependencies (no auto-confirm flags)..."
    if (Get-Command claude -ErrorAction SilentlyContinue) {
      claude plugin marketplace add obra/superpowers-marketplace
      if ($LASTEXITCODE -eq 0) { claude plugin install superpowers@superpowers-marketplace }
      if ($LASTEXITCODE -ne 0) { Write-Output "  superpowers: install failed - run command 1 above manually" }
    } else { Write-Output "  superpowers: 'claude' CLI not found - run command 1 above manually" }

    if (Get-Command npx -ErrorAction SilentlyContinue) {
      npx skills add vercel-labs/skills --skill find-skills
      if ($LASTEXITCODE -ne 0) { Write-Output "  find-skills: install failed - run command 2 above manually" }
    } else { Write-Output "  find-skills: 'npx' not found - run command 2 above manually" }

    if (Get-Command claude -ErrorAction SilentlyContinue) {
      claude plugin marketplace add nextlevelbuilder/ui-ux-pro-max-skill
      if ($LASTEXITCODE -eq 0) { claude plugin install ui-ux-pro-max@ui-ux-pro-max-skill }
      if ($LASTEXITCODE -ne 0) { Write-Output "  ui-ux-pro-max: install failed - run command 3 above manually" }
    } else { Write-Output "  ui-ux-pro-max: 'claude' CLI not found - run command 3 above manually" }

    Write-Output "done. re-run .\install.ps1 to re-check."
  } else {
    Write-Output "skipped (default N). run the commands above when ready."
  }
} elseif ($depMissing -gt 0) {
  Write-Output "(non-interactive shell - not prompting; run the commands above to install.)"
}
