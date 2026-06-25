# Manual install of the dreamteam skill to ~/.claude/skills/dreamteam (Windows),
# then a best-effort dependency check. Plugin users can instead run:
#   /plugin marketplace add <owner>/dreamteam  ;  /plugin install dreamteam@dreamteam-marketplace
$dst = "$env:USERPROFILE\.claude\skills\dreamteam"
if (Test-Path $dst) { Remove-Item -Recurse -Force $dst }   # clean mirror: prune stale files
New-Item -ItemType Directory -Force $dst | Out-Null
Copy-Item -Recurse -Force "$PSScriptRoot\skills\dreamteam\*" $dst
if (Test-Path "$dst\SKILL.md") { Write-Output "installed dreamteam skill -> $dst" }
else { Write-Error "install failed: SKILL.md not found in $dst"; exit 1 }

# --- dependency check (best-effort; dreamteam also resolves/substitutes at runtime) ---
$sk = "$env:USERPROFILE\.claude\skills"
$pl = "$env:USERPROFILE\.claude\plugins\cache"
$ag = "$env:USERPROFILE\.claude\agents"
$missing = 0
function Test-PluginSkill($name) {
  [bool](Get-ChildItem -Path $pl -Recurse -Directory -Filter $name -ErrorAction SilentlyContinue |
         Where-Object { $_.FullName -like '*superpowers*' } | Select-Object -First 1)
}
function Test-Agent($name) {
  $n = ($name.ToLower() -replace ' ', '-')
  [bool](Get-ChildItem -Path $ag -Recurse -File -ErrorAction SilentlyContinue |
         Where-Object { $_.Name -like "*$n.md" } | Select-Object -First 1)
}
Write-Output ""
Write-Output "dependency check (missing items are resolved/substituted at runtime via the Caster + find-skills):"
Write-Output "  required sub-skills (superpowers plugin):"
foreach ($s in 'brainstorming','writing-plans','using-git-worktrees','verification-before-completion','finishing-a-development-branch') {
  if (Test-PluginSkill $s) { Write-Output "    [ok] superpowers:$s" } else { Write-Output "    [ ! ] superpowers:$s  -> install the 'superpowers' plugin"; $missing++ }
}
Write-Output "  skills (~/.claude/skills):"
foreach ($s in 'find-skills','creative-thinking-for-research','brainstorming-research-ideas','literature-review','ml-paper-writing','architecture-reviewer') {
  if (Test-Path "$sk\$s") { Write-Output "    [ok] $s" } else { Write-Output "    [ ! ] $s"; $missing++ }
}
Write-Output "  profile agents (used per profile; general-purpose is built-in):"
foreach ($a in 'Reality Checker','Code Reviewer','AI Engineer','Backend Architect','Frontend Developer','UI Designer','UX Architect','Mobile App Builder','DevOps Automator','Security Engineer','Technical Writer','Test Results Analyzer','Performance Benchmarker','deep-research-agent','system-architect','quality-engineer','root-cause-analyst','Explore','Software Architect') {
  if (Test-Agent $a) { Write-Output "    [ok] $a" } else { Write-Output "    [ ! ] $a  (may be built-in/plugin; verified at runtime)"; $missing++ }
}
if ($missing -gt 0) { Write-Output "note: $missing item(s) not found on disk - a warning, not an error; dreamteam substitutes/flags them at runtime." }
else { Write-Output "all listed dependencies found." }
