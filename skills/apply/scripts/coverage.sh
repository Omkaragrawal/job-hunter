#!/bin/sh
# job-hunter search coverage gate for Mac (and Linux / Git Bash). coverage.ps1 has the same rules for Windows.
# Usage: sh coverage.sh <data folder> [YYYY-MM-DD]
# Checks searches/<day>.csv against every site in profile.md "## Job sites" x every query in
# "## Search queries" (sites marked "(feed" or "; feed" need one row with query "feed").
# A row counts when it has a results URL, pages_read >= 1 and a numeric results_seen,
# or when notes start with "blocked:" and quote the page's own words.
# Prints "complete" (exit 0) or the missing "site | query" pairs (exit 1).
# Plain POSIX sh + awk only (no gawk extensions), so it runs on a stock Mac.
data="$1"
day="${2:-$(date +%Y-%m-%d)}"
[ -f "$data/profile.md" ] || { echo "no profile.md in $data"; exit 2; }
logname="$data/searches/$day.csv"
log="$logname"
[ -f "$log" ] || log=/dev/null

awk -v logname="$logname" '
function trim(s) { sub(/^[ \t]+/, "", s); sub(/[ \t]+$/, "", s); return s }
function csvsplit(line, f,    n, i, c, field, q) {   # one CSV line -> f[1..n]; handles "" escapes
  n = 1; field = ""; q = 0
  for (i = 1; i <= length(line); i++) {
    c = substr(line, i, 1)
    if (q) {
      if (c == "\"") { if (substr(line, i + 1, 1) == "\"") { field = field "\""; i++ } else q = 0 }
      else field = field c
    } else if (c == "\"") q = 1
    else if (c == ",") { f[n++] = field; field = "" }
    else field = field c
  }
  f[n] = field
  return n
}
function quoted(s) {   # true if s contains "xxx" with at least 3 characters inside
  while (match(s, /"[^"]+"/)) { if (RLENGTH >= 5) return 1; s = substr(s, RSTART + RLENGTH) }
  return 0
}
{ sub(/\r$/, "") }
FNR == 1 { file++ }
file == 1 {
  if ($0 ~ /^## /) { sec = trim($0); next }
  if ($0 !~ /^- /) next
  item = trim(substr($0, 3))
  if (sec == "## Job sites") {
    if (item !~ /http/ || tolower(item) ~ /^your other sites/) next
    name = tolower(item); sub(/[ :].*/, "", name)
    if (!(name in feed)) { nsites++; site[nsites] = name }
    feed[name] = (index(item, "(feed") || index(item, "; feed")) ? 1 : 0
  } else if (sec == "## Search queries") { nq++; query[nq] = item }
  next
}
file == 2 && FNR > 1 {
  if (trim($0) == "") next
  for (k in f) delete f[k]
  csvsplit($0, f)
  s = tolower(trim(f[1])); sub(/ .*/, "", s)
  q = tolower(trim(f[2])); url = trim(f[3]); pages = trim(f[4]); seen = trim(f[5]); notes = trim(f[7])
  ok = 0
  if (tolower(substr(notes, 1, 8)) == "blocked:" && quoted(notes)) ok = 1
  else if (url != "" && pages ~ /^[0-9]+$/ && pages + 0 >= 1 && seen ~ /^[0-9]+$/) ok = 1
  if (ok) done[s SUBSEP q] = 1
}
END {
  miss = 0
  for (i = 1; i <= nsites; i++) {
    n = site[i]
    if (feed[n]) { if (!((n SUBSEP "feed") in done)) out[++miss] = n " | feed" }
    else for (j = 1; j <= nq; j++) if (!((n SUBSEP tolower(query[j])) in done)) out[++miss] = n " | " query[j]
  }
  if (miss == 0) { print "complete"; exit 0 }
  print miss " searches missing from " logname ":"
  for (i = 1; i <= miss; i++) print "  " out[i]
  exit 1
}' "$data/profile.md" "$log"
