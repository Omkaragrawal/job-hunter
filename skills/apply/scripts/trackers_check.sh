#!/bin/sh
# job-hunter tracker sync check for Mac (and Linux / Git Bash). trackers_check.ps1 has the same rules for Windows.
# Usage: sh trackers_check.sh <data folder>
# Which trackers are on comes from profile.md's "- Job trackers: ..." line (Job Toast, RoleCatcher, both, or none).
# Every applications.csv row that isn't "skipped" needs a trackers.csv row with the same url. With Job Toast on,
# it needs a jobtoast_id. Each enabled tracker's status must match the log, or be a later stage after "submitted".
# Prints "in sync" or "no trackers configured" (exit 0), or each gap (exit 1).
# Plain POSIX sh + awk only, so it runs on a stock Mac.
# shortcut: a CSV field with a line break inside quotes isn't supported; the skill writes every field on one line.
data="$1"
[ -f "$data/profile.md" ] || { echo "no profile.md in $data"; exit 2; }
apps="$data/applications.csv"; [ -f "$apps" ] || apps=/dev/null
trk="$data/trackers.csv"; [ -f "$trk" ] || trk=/dev/null

awk -v proff="$data/profile.md" -v trkf="$trk" -v appsf="$apps" '
function csvsplit(line, f,    n, i, c, field, q) {
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
{ sub(/\r$/, ""); if (FNR == 1) sub(/^\357\273\277/, "") }
FILENAME == proff {
  if (tolower($0) ~ /^- job trackers/) { v = tolower($0); sub(/^[^:]*:/, "", v); jt = (v ~ /job ?toast/); rc = (index(v, "rolecatcher") > 0) }
  next
}
FILENAME == trkf {
  for (k in f) delete f[k]
  n = csvsplit($0, f)
  if (FNR == 1) { for (i = 1; i <= n; i++) tc[f[i]] = i; next }
  u = f[tc["url"]]; tid[u] = f[tc["jobtoast_id"]]; tjs[u] = f[tc["jobtoast_status"]]; trs[u] = f[tc["rolecatcher_stage"]]; have[u] = 1
  next
}
FILENAME == appsf {
  for (k in f) delete f[k]
  n = csvsplit($0, f)
  if (FNR == 1) { for (i = 1; i <= n; i++) ac[f[i]] = i; next }
  st = f[ac["status"]]
  if (st == "skipped" || $0 == "") next
  name = f[ac["company"]] " | " f[ac["title"]]; u = f[ac["url"]]
  if (!(u in have)) { out[++g] = "missing from trackers: " name " (" st ")"; next }
  if (jt && tid[u] == "") out[++g] = "no Job Toast id: " name
  if (st == "submitted") { wj = "APPLIED"; wr = "Applied" }
  else if (st == "ready" || st == "needs-you" || st == "failed") { wj = "SAVED"; wr = "Shortlisted" }
  else next
  ok = (!jt || tjs[u] == wj) && (!rc || trs[u] == wr)
  moved = (st == "submitted") && ((jt && tjs[u] ~ /^(IN_CONTACT|INTERVIEW_1|INTERVIEW_2|INTERVIEW_3|HIRED|DENIED|ARCHIVED)$/) || (!jt && trs[u] ~ /^(Interview|Offer)$/))
  if (!ok && !moved) out[++g] = "stale: " name ": log says " st ", trackers say " tjs[u] "/" trs[u] ", want " wj "/" wr
}
END {
  if (!jt && !rc) { print "no trackers configured"; exit 0 }
  if (g == 0) { print "in sync"; exit 0 }
  print g " tracker gaps:"
  for (i = 1; i <= g; i++) print "  " out[i]
  exit 1
}' "$data/profile.md" "$trk" "$apps"
