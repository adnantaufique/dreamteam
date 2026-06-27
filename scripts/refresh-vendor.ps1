# refresh-vendor.ps1 — dreamteam vendor-refresh guardrail (build-plan PHASE J / P2-20).
#
# For each vendored source (agency-agents, ECC, SuperClaude) at the commit pinned in
# THIRD_PARTY_NOTICES.md, this re-fetches every vendored file from raw.githubusercontent.com
# and verifies the local copy under vendor/ (and skills/mle-workflow/) has NOT drifted from
# upstream, then verifies each source LICENSE is retained, still MIT, matches upstream, and
# has a THIRD_PARTY_NOTICES entry for the pinned commit.
#
# Drift comparison IGNORES the two metadata-only changes the vendoring convention allows
# (THIRD_PARTY_NOTICES.md "Vendoring convention"): the single added column-0 `origin:`
# frontmatter line (all files) and the `name:` rename (only the two renamed ECC agents,
# mle-reviewer -> methodology-reviewer and security-reviewer -> Security Engineer). The
# prompt BODY is compared exactly and must stay pristine.
#
# Read-only: it never writes to vendor/. It is the verification gate that must pass before
# (and after) any SHA bump / vendor refresh, and the same check the CI license-gate runs.
#
# The SHAs, repo paths, and file lists below are taken VERBATIM from THIRD_PARTY_NOTICES.md —
# no SHA or path is invented. Prints a per-file PASS/DRIFT report and exits NON-ZERO on any
# drift or license change.
#
# Usage: pwsh scripts/refresh-vendor.ps1
$ErrorActionPreference = 'Stop'

$Root = Split-Path -Parent $PSScriptRoot
$Raw  = 'https://raw.githubusercontent.com'
$Tpn  = Join-Path $Root 'THIRD_PARTY_NOTICES.md'

# --- pinned commits (verbatim from THIRD_PARTY_NOTICES.md) ---
$ShaAgency = '1189f0f9bc79a1883fee958fed627c6d11581eb7'   # msitarzewski/agency-agents
$ShaEcc    = '2bc924faf2f8e893bfe0af86b1931283693c30ae'   # affaan-m/ECC
$ShaSc     = '226c45cc93b865108843a669c6545d421784b68c'   # SuperClaude-Org/SuperClaude_Framework

$script:Pass = 0
$script:Fail = 0

# Normalize for the pristine-body diff: drop CR; inside the leading YAML frontmatter drop a
# column-0 `origin:` line, and (when -StripName) a `name:` line. Body is left untouched.
function Convert-Normalized {
  param([string]$Text, [bool]$StripName)
  $lines = ($Text -replace "`r", '') -split "`n"
  $out = New-Object System.Collections.Generic.List[string]
  $inFm = $false; $seen = $false
  foreach ($ln in $lines) {
    if ($ln -eq '---') {
      if (-not $seen) { $inFm = $true; $seen = $true; $out.Add($ln); continue }
      elseif ($inFm)  { $inFm = $false;             $out.Add($ln); continue }
    }
    if ($inFm) {
      if ($ln -match '^origin:') { continue }
      if ($StripName -and $ln -match '^name:') { continue }
    }
    $out.Add($ln)
  }
  return ($out -join "`n")
}

function Get-Upstream {
  param([string]$Url)
  try { return (Invoke-WebRequest -UseBasicParsing -Uri $Url).Content }
  catch { return $null }
}

function Test-VendoredFile {
  param([string]$Repo, [string]$Sha, [string]$Up, [string]$Loc, [bool]$Renamed)
  $url = "$Raw/$Repo/$Sha/$Up"
  $lp  = Join-Path $Root $Loc
  if (-not (Test-Path -LiteralPath $lp)) {
    Write-Host ("  DRIFT  {0}  (local file missing)" -f $Loc); $script:Fail++; return
  }
  $upText = Get-Upstream $url
  if ($null -eq $upText) {
    Write-Host ("  DRIFT  {0}  (upstream fetch failed: {1})" -f $Loc, $url); $script:Fail++; return
  }
  $localNorm = Convert-Normalized (Get-Content -LiteralPath $lp -Raw) $Renamed
  $upNorm    = Convert-Normalized $upText $Renamed
  if ($localNorm -ceq $upNorm) {
    Write-Host ("  PASS   {0}" -f $Loc); $script:Pass++
  } else {
    Write-Host ("  DRIFT  {0}  (body differs from upstream {1})" -f $Loc, $Up); $script:Fail++
  }
}

function Test-VendoredLicense {
  param([string]$Repo, [string]$Sha, [string]$Dir)
  $lp  = Join-Path $Root (Join-Path $Dir 'LICENSE')
  $url = "$Raw/$Repo/$Sha/LICENSE"
  if (-not (Test-Path -LiteralPath $lp)) {
    Write-Host ("  DRIFT  {0}/LICENSE  (retained LICENSE missing)" -f $Dir); $script:Fail++; return
  }
  $localLic = Get-Content -LiteralPath $lp -Raw
  if ($localLic -notmatch 'MIT License') {
    Write-Host ("  DRIFT  {0}/LICENSE  (local LICENSE is not MIT)" -f $Dir); $script:Fail++; return
  }
  $upLic = Get-Upstream $url
  if ($null -eq $upLic) {
    Write-Host ("  DRIFT  {0}/LICENSE  (upstream LICENSE fetch failed)" -f $Dir); $script:Fail++; return
  }
  if ($upLic -notmatch 'MIT License') {
    Write-Host ("  DRIFT  {0}/LICENSE  (upstream LICENSE no longer MIT at {1})" -f $Dir, $Sha); $script:Fail++; return
  }
  if (($localLic -replace "`r", '') -cne ($upLic -replace "`r", '')) {
    Write-Host ("  DRIFT  {0}/LICENSE  (retained LICENSE differs from upstream)" -f $Dir); $script:Fail++; return
  }
  if ((Get-Content -LiteralPath $Tpn -Raw) -notmatch [regex]::Escape($Sha)) {
    Write-Host ("  DRIFT  {0}/LICENSE  (no THIRD_PARTY_NOTICES entry for {1})" -f $Dir, $Sha); $script:Fail++; return
  }
  Write-Host ("  PASS   {0}/LICENSE  (MIT, retained verbatim, notices entry present)" -f $Dir); $script:Pass++
}

Write-Host 'dreamteam vendor-refresh guardrail — drift + license gate'
Write-Host '(SHAs/paths verbatim from THIRD_PARTY_NOTICES.md; ignoring the added origin: line + the ECC name: rename)'

Write-Host ''
Write-Host "agency-agents @ $ShaAgency  (msitarzewski/agency-agents)"
Test-VendoredFile 'msitarzewski/agency-agents' $ShaAgency 'engineering/engineering-ai-engineer.md'        'vendor/agency-agents/ai-engineer.md'             $false
Test-VendoredFile 'msitarzewski/agency-agents' $ShaAgency 'engineering/engineering-backend-architect.md'  'vendor/agency-agents/backend-architect.md'       $false
Test-VendoredFile 'msitarzewski/agency-agents' $ShaAgency 'engineering/engineering-code-reviewer.md'       'vendor/agency-agents/code-reviewer.md'           $false
Test-VendoredFile 'msitarzewski/agency-agents' $ShaAgency 'engineering/engineering-devops-automator.md'    'vendor/agency-agents/devops-automator.md'        $false
Test-VendoredFile 'msitarzewski/agency-agents' $ShaAgency 'engineering/engineering-frontend-developer.md'  'vendor/agency-agents/frontend-developer.md'      $false
Test-VendoredFile 'msitarzewski/agency-agents' $ShaAgency 'engineering/engineering-mobile-app-builder.md'  'vendor/agency-agents/mobile-app-builder.md'      $false
Test-VendoredFile 'msitarzewski/agency-agents' $ShaAgency 'engineering/engineering-software-architect.md'  'vendor/agency-agents/software-architect.md'      $false
Test-VendoredFile 'msitarzewski/agency-agents' $ShaAgency 'engineering/engineering-technical-writer.md'    'vendor/agency-agents/technical-writer.md'        $false
Test-VendoredFile 'msitarzewski/agency-agents' $ShaAgency 'testing/testing-reality-checker.md'             'vendor/agency-agents/reality-checker.md'         $false
Test-VendoredFile 'msitarzewski/agency-agents' $ShaAgency 'testing/testing-test-results-analyzer.md'       'vendor/agency-agents/test-results-analyzer.md'   $false
Test-VendoredFile 'msitarzewski/agency-agents' $ShaAgency 'testing/testing-performance-benchmarker.md'     'vendor/agency-agents/performance-benchmarker.md' $false
Test-VendoredFile 'msitarzewski/agency-agents' $ShaAgency 'design/design-ui-designer.md'                   'vendor/agency-agents/ui-designer.md'             $false
Test-VendoredLicense 'msitarzewski/agency-agents' $ShaAgency 'vendor/agency-agents'

Write-Host ''
Write-Host "ECC @ $ShaEcc  (affaan-m/ECC)"
Test-VendoredFile 'affaan-m/ECC' $ShaEcc 'agents/mle-reviewer.md'           'vendor/ecc/methodology-reviewer.md'   $true
Test-VendoredFile 'affaan-m/ECC' $ShaEcc 'agents/security-reviewer.md'      'vendor/ecc/security-engineer.md'      $true
Test-VendoredFile 'affaan-m/ECC' $ShaEcc 'agents/build-error-resolver.md'   'vendor/ecc/build-error-resolver.md'   $false
Test-VendoredFile 'affaan-m/ECC' $ShaEcc 'agents/pytorch-build-resolver.md' 'vendor/ecc/pytorch-build-resolver.md' $false
Test-VendoredFile 'affaan-m/ECC' $ShaEcc 'skills/mle-workflow/SKILL.md'     'skills/mle-workflow/SKILL.md'         $false
Test-VendoredLicense 'affaan-m/ECC' $ShaEcc 'vendor/ecc'

Write-Host ''
Write-Host "SuperClaude @ $ShaSc  (SuperClaude-Org/SuperClaude_Framework)"
Test-VendoredFile 'SuperClaude-Org/SuperClaude_Framework' $ShaSc 'plugins/superclaude/agents/deep-research-agent.md' 'vendor/superclaude/deep-research-agent.md' $false
Test-VendoredFile 'SuperClaude-Org/SuperClaude_Framework' $ShaSc 'plugins/superclaude/agents/quality-engineer.md'    'vendor/superclaude/quality-engineer.md'    $false
Test-VendoredFile 'SuperClaude-Org/SuperClaude_Framework' $ShaSc 'plugins/superclaude/agents/root-cause-analyst.md'  'vendor/superclaude/root-cause-analyst.md'  $false
Test-VendoredFile 'SuperClaude-Org/SuperClaude_Framework' $ShaSc 'plugins/superclaude/agents/system-architect.md'    'vendor/superclaude/system-architect.md'    $false
Test-VendoredFile 'SuperClaude-Org/SuperClaude_Framework' $ShaSc 'plugins/superclaude/agents/python-expert.md'       'vendor/superclaude/python-expert.md'       $false
Test-VendoredLicense 'SuperClaude-Org/SuperClaude_Framework' $ShaSc 'vendor/superclaude'

Write-Host ''
Write-Host '----------------------------------------------------------------'
Write-Host ("result: {0} PASS, {1} DRIFT" -f $script:Pass, $script:Fail)
if ($script:Fail -ne 0) {
  Write-Host 'FAIL: vendored files drifted from their pinned upstream, or a LICENSE changed.'
  Write-Host '      Bodies must stay pristine (only the added origin: line + the documented ECC name: rename are allowed).'
  exit 1
}
Write-Host 'OK: every vendored file matches its pinned upstream; all LICENSEs are MIT and retained.'
exit 0
