# Self-check for coverage.ps1: powershell -NoProfile -ExecutionPolicy Bypass -File run-tests.ps1
# Same cases as run-tests.sh. 2026-01-01 has no log; 2026-01-02 has the failure modes seen in real runs
# (no results count, unquoted "blocked", zero pages); 2026-01-03 is complete.
$here = Split-Path -Parent $MyInvocation.MyCommand.Path
$cov = Join-Path (Split-Path -Parent $here) 'coverage.ps1'
$data = Join-Path $here 'data'
$script:failed = $false
function Check($day, $wantExit, $want) {
  $out = @(& powershell -NoProfile -ExecutionPolicy Bypass -File $cov -DataDir $data -Day $day)
  $code = $LASTEXITCODE
  $got = (@($out | Where-Object { $_ -like '  *' } | ForEach-Object { $_.Trim() }) -join ';')
  if ($code -ne $wantExit -or $got -ne $want) { "FAIL $day (exit $code): $($out -join ' / ')"; $script:failed = $true }
}
Check '2026-01-01' 1 'naukri | Node.js;naukri | Python backend;jobleads | feed;weekday | feed'
Check '2026-01-02' 1 'naukri | Python backend;jobleads | feed;weekday | feed'
Check '2026-01-03' 0 ''

# trackers_check.ps1: four small data folders under test\trackers.
$tc = Join-Path (Split-Path -Parent $here) 'trackers_check.ps1'
function CheckT($case, $wantExit, $want) {
  $out = @(& powershell -NoProfile -ExecutionPolicy Bypass -File $tc -DataDir (Join-Path $here "trackers\$case"))
  $code = $LASTEXITCODE
  $got = if ($code -eq 0) { "$($out[0])" } else { (@($out | Where-Object { $_ -like '  *' } | ForEach-Object { $_.Trim() }) -join ';') }
  if ($code -ne $wantExit -or $got -ne $want) { "FAIL trackers $case (exit $code): $($out -join ' / ')"; $script:failed = $true }
}
CheckT 'both-in-sync' 0 'in sync'
CheckT 'both-gaps' 1 'no Job Toast id: Coa | T;stale: Cob | T: log says submitted, trackers say SAVED/Shortlisted, want APPLIED/Applied;missing from trackers: Coe | T (ready)'
CheckT 'rolecatcher-only' 0 'in sync'
CheckT 'none' 0 'no trackers configured'
if ($script:failed) { exit 1 }
'ok'
