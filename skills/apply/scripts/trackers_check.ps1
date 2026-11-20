# job-hunter tracker sync check for Windows. trackers_check.sh has the same rules for Mac.
# Usage: powershell -NoProfile -ExecutionPolicy Bypass -File trackers_check.ps1 -DataDir <data folder>
# Which trackers are on comes from profile.md's "- Job trackers: ..." line (Job Toast, RoleCatcher, both, or none).
# Every applications.csv row that isn't "skipped" needs a trackers.csv row with the same url. With Job Toast on,
# it needs a jobtoast_id. Each enabled tracker's status must match the log, or be a later stage after "submitted".
# Prints "in sync" or "no trackers configured" (exit 0), or each gap (exit 1).
param([Parameter(Mandatory)][string]$DataDir)
$ErrorActionPreference = 'Stop'
$profilePath = Join-Path $DataDir 'profile.md'
if (-not (Test-Path $profilePath)) { "no profile.md in $DataDir"; exit 2 }

$line = Get-Content $profilePath -Encoding UTF8 | Where-Object { $_ -match '^- Job trackers' } | Select-Object -First 1
$val = if ($line) { ($line -split ':', 2)[1] } else { '' }
$jt = $val -match 'job ?toast'; $rc = $val -match 'rolecatcher'
if (-not ($jt -or $rc)) { 'no trackers configured'; exit 0 }

$apps = @(); $p = Join-Path $DataDir 'applications.csv'; if (Test-Path $p) { $apps = @(Import-Csv $p -Encoding UTF8) }
$trk = @{}; $p = Join-Path $DataDir 'trackers.csv'; if (Test-Path $p) { foreach ($t in Import-Csv $p -Encoding UTF8) { $trk[$t.url] = $t } }
$expect = @{ 'submitted' = @('APPLIED', 'Applied'); 'ready' = @('SAVED', 'Shortlisted'); 'needs-you' = @('SAVED', 'Shortlisted'); 'failed' = @('SAVED', 'Shortlisted') }
$laterJt = 'IN_CONTACT', 'INTERVIEW_1', 'INTERVIEW_2', 'INTERVIEW_3', 'HIRED', 'DENIED', 'ARCHIVED'  # moved on after applying
$laterRc = 'Interview', 'Offer'

$gaps = @(foreach ($a in $apps) {
  if ($a.status -eq 'skipped') { continue }
  $name = "$($a.company) | $($a.title)"
  $t = $trk[$a.url]
  if (-not $t) { "missing from trackers: $name ($($a.status))"; continue }
  if ($jt -and -not $t.jobtoast_id) { "no Job Toast id: $name" }
  $w = $expect[$a.status]
  if ($w) {
    $ok = ((-not $jt) -or $t.jobtoast_status -ceq $w[0]) -and ((-not $rc) -or $t.rolecatcher_stage -ceq $w[1])
    $moved = $a.status -eq 'submitted' -and (($jt -and $laterJt -ccontains $t.jobtoast_status) -or ((-not $jt) -and $laterRc -ccontains $t.rolecatcher_stage))
    if (-not $ok -and -not $moved) { "stale: ${name}: log says $($a.status), trackers say $($t.jobtoast_status)/$($t.rolecatcher_stage), want $($w[0])/$($w[1])" }
  }
})
if ($gaps.Count -eq 0) { 'in sync'; exit 0 }
"$($gaps.Count) tracker gaps:"
$gaps | ForEach-Object { "  $_" }
exit 1
