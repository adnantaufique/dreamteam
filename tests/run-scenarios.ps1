[CmdletBinding(PositionalBinding = $false)]
param([switch]$List, [switch]$Extract, [int]$TimeoutSec = 180,
      [Parameter(Position = 0, ValueFromRemainingArguments = $true)][string[]]$Ids)
# Live spot-check runner for tests/scenarios.md - executes selected scenarios as headless dry-runs.
# Each scenario = TWO billed `claude -p` calls (run + judge). No default set - IDs are explicit.
# Usage: pwsh tests/run-scenarios.ps1 [-List] [-Extract] [-TimeoutSec 180] <ID ...>   e.g. S49 S50 GroundingA
$ErrorActionPreference = 'Stop'
$Tests = $PSScriptRoot; $Repo = Split-Path -Parent $Tests
$Scen = "$Tests/scenarios.md"; $Skill = "$Repo/skills/dreamteam"
$Lines = Get-Content $Scen -Encoding utf8
$Tmp = Join-Path ([IO.Path]::GetTempPath()) "dreamteam-scenarios-$PID"; New-Item -ItemType Directory -Force $Tmp | Out-Null

function Get-Ids { foreach ($l in $Lines) { if ($l -match '^## (S[0-9]+|Grounding [AB]) ') { $Matches[1] -replace ' ', '' } } }
function Get-Canon([string]$Raw) {
  $w = ($Raw -replace '[^A-Za-z0-9]', '').ToLower()
  foreach ($c in Get-Ids) { if ($c.ToLower() -eq $w) { return $c } }
}
function Get-Block([string]$Id) { # scenario block: heading .. before next '## ' or '> ' blockquote
  $h = if ($Id -match '^Grounding([AB])$') { "## Grounding $($Matches[1]) " } else { "## $Id " }
  $out = @(); $on = $false
  foreach ($l in $Lines) {
    if (-not $on) { if ($l.StartsWith($h)) { $on = $true; $out += $l }; continue }
    if ($l -match '^## |^> ') { break }
    $out += $l
  }
  return $out
}
function Get-Cited([string]$Text) { # heading + Input text -> existing skill-file paths ("installed skill" = whole tree)
  $c = @()
  if ($Text -match 'installed(/fixed)? (skill|`)') { $c += "$Skill/SKILL.md"; $c += @(Get-ChildItem "$Skill/references/*.md" | ForEach-Object { "$Skill/references/$($_.Name)" }) }
  foreach ($m in [regex]::Matches($Text, 'references/[A-Za-z0-9_-]+\.md')) { $c += "$Skill/$($m.Value)" }
  if ($Text -match 'SKILL\.md') { $c += "$Skill/SKILL.md" }
  foreach ($m in [regex]::Matches($Text, '`([a-z0-9_-]+\.md)`')) { $c += "$Skill/references/$($m.Groups[1].Value)" }
  $c = @($c | Select-Object -Unique | Where-Object { Test-Path $_ })
  if (-not $c) { $c = @("$Skill/SKILL.md") }
  return $c
}
function Invoke-Claude([string]$PromptFile, [string]$OutFile) { # -> exit code (124 = timeout, -1 = no CLI or launch failure)
  $cmd = Get-Command claude.exe, claude.cmd, claude -ErrorAction SilentlyContinue | Select-Object -First 1
  if (-not $cmd) { return -1 }
  try {
    $p = Start-Process -FilePath $cmd.Source -ArgumentList '-p' -RedirectStandardInput $PromptFile `
         -RedirectStandardOutput $OutFile -RedirectStandardError "$OutFile.err" -NoNewWindow -PassThru
    if (-not $p.WaitForExit($TimeoutSec * 1000)) { try { $p.Kill($true) } catch {}; return 124 }
    return $p.ExitCode
  } catch { return -1 } # shadowed/aliased claude, resolution or launch error: ERROR row, not a dead run
}

if ($List) { Get-Ids; exit 0 }
if (-not $Ids) {
  Write-Host "usage: pwsh tests/run-scenarios.ps1 [-List] [-Extract] [-TimeoutSec 180] <ID ...>   e.g. S49 S50 GroundingA"
  Write-Host "  -List = print scenario IDs; -Extract = show parsed block + cited files, no model calls"
  Write-Host "COST: each selected scenario spends TWO headless 'claude -p' model calls (billed). No default set."
  exit 1
}
$rows = @()
foreach ($raw in $Ids) {
  $id = Get-Canon $raw
  if (-not $id) { $rows += [pscustomobject]@{ Id = $raw; Result = 'ERROR'; Note = 'unknown id (see -List)' }; continue }
  $block = @(Get-Block $id)
  $inp = @($block | Where-Object { $_ -match '^- \*\*Input:\*\* ' })[0] -replace '^- \*\*Input:\*\* ', ''
  $exp = @($block | Where-Object { $_ -match '^- \*\*Expected:\*\* ' })[0] -replace '^- \*\*Expected:\*\* ', ''
  if (-not $inp -or -not $exp) { $rows += [pscustomobject]@{ Id = $id; Result = 'ERROR'; Note = 'block missing Input/Expected' }; continue }
  $files = @(Get-Cited "$($block[0]) $inp")
  if ($Extract) {
    Write-Host "== $id  $($block[0])"; $files | ForEach-Object { Write-Host "  file: $_" }
    Write-Host "  input: $inp"; Write-Host "  expected: $exp"
    $rows += [pscustomobject]@{ Id = $id; Result = 'EXTRACT'; Note = "$($files.Count) file(s), no model calls" }; continue
  }
  $pf = "$Tmp/$id.run.prompt"; $rf = "$Tmp/$id.run.out"; $jf = "$Tmp/$id.judge.out"
  $sb = [System.Text.StringBuilder]::new()
  foreach ($f in $files) { [void]$sb.AppendLine("---- BEGIN $($f.Replace("$Skill/", '')) ----"); [void]$sb.AppendLine((Get-Content -Raw $f)); [void]$sb.AppendLine('---- END ----') }
  [void]$sb.AppendLine("`nSCENARIO INPUT:`n$inp")
  [void]$sb.AppendLine("`nState precisely what the skill requires the conductor/unit to do in this situation. Concrete actions and outputs only — no meta-commentary.")
  Set-Content -Path $pf -Value $sb.ToString() -Encoding utf8
  Write-Host "[$id] run call (claude -p, timeout ${TimeoutSec}s)..."
  $rc = Invoke-Claude $pf $rf
  if ($rc -ne 0) { $rows += [pscustomobject]@{ Id = $id; Result = 'ERROR'; Note = "run call rc=$rc$(if ($rc -eq 124) { ' (timeout)' })" }; continue }
  $jp = "SCENARIO EXPECTED (spec):`n$exp`n`nRESPONSE UNDER TEST:`n$(Get-Content -Raw $rf)`n`nDoes the response satisfy every load-bearing expectation? Answer EXACTLY 'PASS: <one line>' or 'FAIL: <specific miss>'."
  Set-Content -Path "$Tmp/$id.judge.prompt" -Value $jp -Encoding utf8
  Write-Host "[$id] judge call..."
  $rc = Invoke-Claude "$Tmp/$id.judge.prompt" $jf
  if ($rc -ne 0) { $rows += [pscustomobject]@{ Id = $id; Result = 'ERROR'; Note = "judge call rc=$rc$(if ($rc -eq 124) { ' (timeout)' })" }; continue }
  $line = @(Get-Content $jf | Where-Object { $_ -match '^(PASS|FAIL):' })[0]
  if     ($line -match '^PASS: ?(.*)') { $rows += [pscustomobject]@{ Id = $id; Result = 'PASS'; Note = $Matches[1] } }
  elseif ($line -match '^FAIL: ?(.*)') { $rows += [pscustomobject]@{ Id = $id; Result = 'FAIL'; Note = $Matches[1] } }
  else { $rows += [pscustomobject]@{ Id = $id; Result = 'ERROR'; Note = "unparseable judge verdict (see $jf)" } }
}
''
'{0,-12} {1,-8} {2}' -f 'ID', 'RESULT', 'NOTE'
foreach ($r in $rows) { '{0,-12} {1,-8} {2}' -f $r.Id, $r.Result, $r.Note }
$ok = @($rows | Where-Object { $_.Result -in 'PASS', 'EXTRACT' }).Count
"summary: $($rows.Count) selected, $ok ok, $($rows.Count - $ok) not-ok  (raw prompts/outputs: $Tmp)"
if ($ok -eq $rows.Count) { exit 0 } else { exit 1 }
