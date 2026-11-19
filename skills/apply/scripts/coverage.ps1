# job-hunter search coverage gate for Windows. coverage.sh has the same rules for Mac.
# Usage: powershell -NoProfile -ExecutionPolicy Bypass -File coverage.ps1 -DataDir <data folder> [-Day YYYY-MM-DD]
# Checks searches\<day>.csv against every site in profile.md "## Job sites" x every query in
# "## Search queries" (sites marked "(feed" or "; feed" need one row with query "feed").
# A row counts when it has a results URL, pages_read >= 1 and a numeric results_seen,
# or when notes start with "blocked:" and quote the page's own words.
# Prints "complete" (exit 0) or the missing "site | query" pairs (exit 1).
param(
  [Parameter(Mandatory)][string]$DataDir,
  [string]$Day = (Get-Date -Format 'yyyy-MM-dd')
)
$ErrorActionPreference = 'Stop'
$profilePath = Join-Path $DataDir 'profile.md'
if (-not (Test-Path $profilePath)) { "no profile.md in $DataDir"; exit 2 }

$sites = [ordered]@{}; $queries = @(); $sec = ''
foreach ($line in Get-Content $profilePath -Encoding UTF8) {
  if ($line -match '^## ') { $sec = $line.Trim(); continue }
  if ($line -notmatch '^- ') { continue }
  $item = $line.Substring(2).Trim()
  if ($sec -eq '## Job sites') {
    if ($item -notmatch 'http' -or $item -match '^your other sites') { continue }  # career pages / placeholder
    $sites[($item -split '[ :]')[0].ToLower()] = $item.Contains('(feed') -or $item.Contains('; feed')
  } elseif ($sec -eq '## Search queries') { $queries += $item }
}

$log = Join-Path $DataDir "searches\$Day.csv"
$done = @{}
if (Test-Path $log) {
  foreach ($r in Import-Csv $log -Encoding UTF8) {
    $notes = "$($r.notes)".Trim(); $pages = "$($r.pages_read)".Trim(); $seen = "$($r.results_seen)".Trim()
    $ok = ($notes -match '^blocked:' -and $notes -match '"[^"]{3,}"') -or
          ("$($r.url)".Trim() -ne '' -and $pages -match '^\d+$' -and [int]$pages -ge 1 -and $seen -match '^\d+$')
    if ($ok) { $done[(("$($r.site)".Trim() -split ' ')[0].ToLower()) + '|' + "$($r.query)".Trim().ToLower()] = $true }
  }
}

$missing = @(foreach ($s in $sites.Keys) {
  $need = if ($sites[$s]) { @('feed') } else { $queries }
  foreach ($q in $need) { if (-not $done["$s|$($q.ToLower())"]) { "  $s | $q" } }
})
if ($missing.Count -eq 0) { 'complete'; exit 0 }
"$($missing.Count) searches missing from ${log}:"
$missing
exit 1
