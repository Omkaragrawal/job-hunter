# job-hunter keep-going check for Windows: an opt-in Stop hook. keep_going.sh has the same rules for Mac.
# Setup copies it, with coverage.ps1 and trackers_check.ps1, to <data folder>\.claude\keep-going\ and wires it up in
# <data folder>\.claude\settings.json. It refuses to end today's daily run while searches, leftover candidates or
# tracker gaps remain. It stays silent when this session isn't today's daily run, when the work is done, or when the
# user's last message is a plain stop/pause. It lets go after $Stall stops in a row that changed nothing.
# The message holds only counts and profile.md's own site and query names: company names and job titles come from
# websites and must not reach Claude as hook feedback.
param([Parameter(Mandatory)][string]$DataDir)
$ErrorActionPreference = 'Stop'
$Mark = '<scheduled-task name="job-hunter-daily'
$Stall = 3
# A whole line that is only a stop request; "temporarily stop linkedin" or "don't stop" doesn't count.
$StopLine = "^\W*(please\s+)?(stop|pause|halt|enough|that.?s enough)(\s+(it|here|now|for (now|today)|the run|this run))*\W*$"
$ordinal = [StringComparison]::Ordinal

function Emit($o) {
  $b = (New-Object Text.UTF8Encoding $false).GetBytes((ConvertTo-Json $o -Compress))
  $s = [Console]::OpenStandardOutput(); $s.Write($b, 0, $b.Length); $s.Flush()
}
function Key($s) { "$s".ToLowerInvariant() -replace '[\x00-\x2F\x3A-\x40\x5B-\x60\x7B-\x7F]', '' }
function Rows($name) { $p = Join-Path $DataDir $name; if (Test-Path $p) { Import-Csv $p -Encoding UTF8 } }
function Typed($o) {  # text the user (or the scheduler) sent in this transcript line, including messages queued mid-turn
  if ($o.isMeta -or $o.isSidechain) { return '' }
  if ($o.type -eq 'attachment' -and $o.attachment.type -eq 'queued_command') { $c = $o.attachment.prompt }
  elseif ($o.type -eq 'user') { $c = $o.message.content }
  else { return '' }
  if ($c -is [array]) { $c = @($c | Where-Object { $_.type -eq 'text' } | ForEach-Object { $_.text }) -join "`n" }
  $c = "$c".Trim()
  if ($c.StartsWith('Stop hook feedback', $ordinal)) { return '' }
  if ($c.StartsWith('<', $ordinal) -and -not $c.StartsWith($Mark, $ordinal) -and -not $c.StartsWith('<!--', $ordinal)) { return '' }
  $c
}

try {
  $in = (New-Object IO.StreamReader([Console]::OpenStandardInput(), [Text.Encoding]::UTF8)).ReadToEnd() | ConvertFrom-Json
  $today = (Get-Date).Date
  $started = $null; $last = ''
  $path = "$($in.transcript_path)" -replace '^~', $HOME
  $reader = New-Object IO.StreamReader([IO.File]::Open($path, 'Open', 'Read', 'ReadWrite'), [Text.Encoding]::UTF8)
  try {
    while ($null -ne ($l = $reader.ReadLine())) {
      if (-not ($l.Contains('"type":"user"') -or $l.Contains('"type":"queued_command"')) -or $l.Contains('"type":"tool_result"')) { continue }
      try { $o = $l | ConvertFrom-Json } catch { continue }
      $t = Typed $o
      if ($t.StartsWith($Mark, $ordinal)) { $started = [DateTimeOffset]::Parse($o.timestamp, [Globalization.CultureInfo]::InvariantCulture).LocalDateTime.Date }
      if ($t) { $last = $t }
    }
  } finally { $reader.Dispose() }
  if ($started -ne $today) { exit 0 }
  foreach ($line in $last -split "`n") {
    $x = $line.Trim()
    if ($x -and -not $x.StartsWith('>') -and -not $x.StartsWith('<!--') -and $x -match $StopLine) { exit 0 }
  }

  $cov = @(& "$PSScriptRoot\coverage.ps1" -DataDir $DataDir); if ($LASTEXITCODE -gt 1) { throw "$cov" }
  $searches = @($cov | Where-Object { $_ -like '  *' } | ForEach-Object { $_.Trim() })
  $trk = @(& "$PSScriptRoot\trackers_check.ps1" -DataDir $DataDir); if ($LASTEXITCODE -gt 1) { throw "$trk" }
  $gaps = @($trk | Where-Object { $_ -like '  *' })
  $apps = @(Rows 'applications.csv')
  $urls = @{}; $pairs = @{}; $firms = @{}
  foreach ($a in $apps) {
    if ($a.url) { $urls[$a.url] = 1 }
    $f = Key $a.company; $pairs["$f|$(Key $a.title)"] = 1; if ($f) { $firms[$f] = 1 }
  }
  $left = @(foreach ($c in @(Rows 'candidates.csv')) {
    $f = Key $c.company
    if ($f -and $pairs["$f|$(Key $c.title)"]) { continue }
    if ($c.url) { if ($urls[$c.url]) { continue } }
    # shortcut: with no link saved, any log row for the company counts; save links if a company's second role gets missed
    elseif ($f -and @($firms.Keys | Where-Object { $_.StartsWith($f, $ordinal) -or $f.StartsWith($_, $ordinal) }).Count) { continue }
    "$f|$(Key $c.title)|$($c.url)"
  })

  $state = Join-Path $DataDir '.keep_going'
  if ($searches.Count + $left.Count + $gaps.Count -eq 0) { if (Test-Path $state) { Remove-Item $state }; exit 0 }
  $run = "$($in.session_id) $($today.ToString('yyyy-MM-dd'))"
  $text = ($searches + $left + $gaps + @($apps | ForEach-Object { "$($_.url)|$($_.status)|$($_.notes)" })) -join "`n"
  $print = [BitConverter]::ToString([Security.Cryptography.SHA256]::Create().ComputeHash([Text.Encoding]::UTF8.GetBytes($text)))
  $old = if (Test-Path $state) { @(Get-Content $state) } else { @('', '', '0') }
  $stalls = if ($old[0] -eq $run -and $old[1] -eq $print) { [int]$old[2] + 1 } else { 0 }
  $open = @(); if ($left.Count) { $open += "$($left.Count) leftover candidates" }; if ($searches.Count) { $open += "$($searches.Count) searches missing" }; if ($gaps.Count) { $open += "$($gaps.Count) tracker gaps" }
  $open = $open -join ', '
  if ($stalls -ge $Stall) {
    Set-Content $state @($run, $print, '0')
    Emit @{ systemMessage = "Job run stopped: nothing changed over the last $Stall tries. Still open: $open." }
    exit 0
  }
  Set-Content $state @($run, $print, "$stalls")
  $msg = @("The daily job run isn't finished ($open). Keep working now: no summary, no wrap-up and no asking for `"continue`".")
  if ($searches.Count) { $msg += 'Searches missing: ' + (@($searches | Select-Object -First 8) -join '; ') + $(if ($searches.Count -gt 8) { "; and $($searches.Count - 8) more" }) }
  if ($left.Count) { $msg += 'Leftovers are the candidates.csv rows with no applications.csv row.' }
  if ($gaps.Count) { $msg += 'Run the tracker check to list the tracker gaps.' }
  $msg += "Take one site at a time: search it, log it, then judge and fill what it kept. Log a blocked site with its 'blocked:' row and give each leftover a row in applications.csv. Anything that needs the user is a one-line hand-off; move on. Every rule in the apply skill still holds, including what may be submitted."
  Emit @{ decision = 'block'; reason = ($msg -join "`n") }
} catch {
  # A broken check must not trap the session, but it must be visible.
  Emit @{ systemMessage = "The keep-going check failed, so the run was allowed to stop: $($_.Exception.Message)" }
}
exit 0
