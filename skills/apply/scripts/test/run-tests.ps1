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
if ($script:failed) { exit 1 }
'ok'
