#!/bin/sh
# job-hunter keep-going check for Mac: an opt-in Stop hook. keep_going.ps1 has the same rules for Windows.
# Setup copies it, with coverage.sh and trackers_check.sh, to <data folder>/.claude/keep-going/ and wires it up in
# <data folder>/.claude/settings.json. It refuses to end today's daily run while searches, leftover candidates or
# tracker gaps remain. It stays silent when this session isn't today's daily run, when the work is done, or when the
# user's last message is a plain stop/pause. It lets go after STALL stops in a row that changed nothing.
# The message holds only counts and profile.md's own site and query names: company names and job titles come from
# websites and must not reach Claude as hook feedback.
# Plain POSIX sh + awk only, so it runs on a stock Mac.
# shortcut: a CSV field with a line break inside quotes isn't supported; the skill writes every field on one line.
data="$1"
here=$(cd "$(dirname "$0")" && pwd)
LC_ALL=C; export LC_ALL
STALL=3
# A broken check must not trap the session, but it must be visible.
fail() { printf '{"systemMessage":"The keep-going check failed, so the run was allowed to stop: %s"}\n' "$1"; exit 0; }

lib='
function jstr(s,    p, v) {   # s starts just after a JSON string opening quote
  gsub(/\\\\/, "\001", s); gsub(/\\"/, "\002", s)
  p = index(s, "\""); v = p ? substr(s, 1, p - 1) : s
  gsub(/\\n/, "\n", v); gsub(/\\[rt]/, " ", v); gsub(/\\\//, "/", v); gsub(/\002/, "\"", v); gsub(/\001/, "\\", v)
  return v
}
function field(s, name,    p) { p = index(s, "\"" name "\":\""); return p ? jstr(substr(s, p + length(name) + 4)) : "" }
'
input=$(cat)
transcript=$(printf '%s\n' "$input" | awk "$lib"'{ s = s $0 } END { print field(s, "transcript_path") }')
session=$(printf '%s\n' "$input" | awk "$lib"'{ s = s $0 } END { print field(s, "session_id") }')
case "$transcript" in "~"*) transcript="$HOME${transcript#\~}" ;; esac
[ -f "$transcript" ] || fail "no transcript file"

# Prints "<UTC start time of the daily run, or -> <1 if the user last asked to stop>".
scan=$(awk "$lib"'
function body(s, name,    p, out) {   # a string value, or the text blocks of an array value
  p = index(s, "\"" name "\":[")
  if (!p) return field(s, name)
  s = substr(s, p)
  while ((p = index(s, "\"text\":\"")) > 0) { s = substr(s, p + 8); out = out "\n" jstr(s) }
  return out
}
function stopline(s) {   # a whole line that is only a stop request
  s = tolower(s)
  return s ~ /^[ -\/:-@\[-`{-~]*(please +)?(stop|pause|halt|enough|that.?.?.?s enough)( +(it|here|now|for now|for today|the run|this run))*[ -\/:-@\[-`{-~]*$/
}
BEGIN { mark = "<scheduled-task name=\"job-hunter-daily"; started = "-" }
index($0, "\"type\":\"tool_result\"") || index($0, "\"isMeta\":true") || index($0, "\"isSidechain\":true") { next }
index($0, "\"type\":\"queued_command\"") { t = body($0, "prompt"); hit = 1 }
!hit && index($0, "\"type\":\"user\"") && index($0, "\"role\":\"user\"") { t = body($0, "content"); hit = 1 }
hit {
  hit = 0
  sub(/^[ \n]+/, "", t)
  if (substr(t, 1, 18) == "Stop hook feedback") next
  ismark = (substr(t, 1, length(mark)) == mark)
  if (substr(t, 1, 1) == "<" && !ismark && substr(t, 1, 4) != "<!--") next
  if (ismark) started = field($0, "timestamp")
  if (t != "") last = t
}
END {
  n = split(last, line, "\n")
  for (i = 1; i <= n; i++) {
    x = line[i]; sub(/^ +/, "", x); sub(/ +$/, "", x)
    if (x != "" && substr(x, 1, 1) != ">" && substr(x, 1, 4) != "<!--" && stopline(x)) stop = 1
  }
  print started, stop + 0
}' "$transcript") || fail "could not read the transcript"
started=${scan% *}
[ "$started" != "-" ] && [ "${scan##* }" = 0 ] || exit 0

# Local midnight as UTC: BSD date first (Mac), then GNU date.
today=$(date +%Y-%m-%d)
if e=$(date -j -f '%Y-%m-%d %H:%M:%S' "$today 00:00:00" +%s 2>/dev/null); then mid=$(date -u -r "$e" +%Y-%m-%dT%H:%M:%S)
else e=$(date -d "$today 00:00:00" +%s) && mid=$(date -u -d "@$e" +%Y-%m-%dT%H:%M:%S) || fail "date not understood"; fi
[ "$(printf '%s\n%s\n' "$mid" "$started" | sort | head -n 1)" = "$mid" ] || exit 0

out=$(sh "$here/coverage.sh" "$data"); [ $? -le 1 ] || fail "the coverage check did not run"
searches=$(printf '%s\n' "$out" | sed -n 's/^  //p')
out=$(sh "$here/trackers_check.sh" "$data"); [ $? -le 1 ] || fail "the tracker check did not run"
gaps=$(printf '%s\n' "$out" | sed -n 's/^  //p')
apps="$data/applications.csv"; [ -f "$apps" ] || apps=/dev/null
cand="$data/candidates.csv"; [ -f "$cand" ] || cand=/dev/null
left=$(awk -v appsf="$apps" -v candf="$cand" '
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
function key(s) { s = tolower(s); gsub(/[ -\/:-@\[-`{-~\t]/, "", s); return s }
{ sub(/\r$/, ""); if (FNR == 1) sub(/^\357\273\277/, "") }
$0 == "" { next }
{ for (k in f) delete f[k]; n = csvsplit($0, f) }
FNR == 1 { for (k in col) delete col[k]; for (i = 1; i <= n; i++) col[f[i]] = i; next }
{ firm = key(f[col["company"]]); title = key(f[col["title"]]); url = f[col["url"]] }
FILENAME == appsf { if (url != "") urls[url] = 1; pairs[firm "|" title] = 1; if (firm != "") firms[firm] = 1; next }
FILENAME == candf {
  if (firm != "" && ((firm "|" title) in pairs)) next
  if (url != "") { if (url in urls) next }
  # shortcut: with no link saved, any log row for the company counts; save links if a second role there gets missed
  else if (firm != "") { seen = 0; for (x in firms) if (index(x, firm) == 1 || index(firm, x) == 1) seen = 1; if (seen) next }
  print firm "|" title "|" url
}' "$apps" "$cand") || fail "could not compare candidates.csv with applications.csv"

count() { if [ -n "$1" ]; then printf '%s\n' "$1" | wc -l | tr -d ' '; else echo 0; fi; }
ns=$(count "$searches"); nl=$(count "$left"); ng=$(count "$gaps")
state="$data/.keep_going"
if [ $((ns + nl + ng)) = 0 ]; then rm -f "$state"; exit 0; fi
run="$session $today"
print=$( { printf '%s\n' "$searches" "$left" "$gaps"; cat "$apps"; } | cksum)
stalls=0
if [ -f "$state" ] && [ "$(sed -n 1p "$state")" = "$run" ] && [ "$(sed -n 2p "$state")" = "$print" ]; then stalls=$(( $(sed -n 3p "$state") + 1 )); fi
open=""
[ "$nl" = 0 ] || open="$nl leftover candidates"
[ "$ns" = 0 ] || open="${open:+$open, }$ns searches missing"
[ "$ng" = 0 ] || open="${open:+$open, }$ng tracker gaps"
if [ "$stalls" -ge "$STALL" ]; then
  printf '%s\n%s\n0\n' "$run" "$print" > "$state"
  printf '{"systemMessage":"Job run stopped: nothing changed over the last %s tries. Still open: %s."}\n' "$STALL" "$open"
  exit 0
fi
printf '%s\n%s\n%s\n' "$run" "$print" "$stalls" > "$state"
{
  echo "The daily job run isn't finished ($open). Keep working now: no summary, no wrap-up and no asking for \"continue\"."
  if [ "$ns" != 0 ]; then
    more=""; [ "$ns" -le 8 ] || more="; and $((ns - 8)) more"
    echo "Searches missing: $(printf '%s\n' "$searches" | head -n 8 | awk '{ printf "%s%s", (NR > 1 ? "; " : ""), $0 }')$more"
  fi
  [ "$nl" = 0 ] || echo "Leftovers are the candidates.csv rows with no applications.csv row."
  [ "$ng" = 0 ] || echo "Run the tracker check to list the tracker gaps."
  echo "Take one site at a time: search it, log it, then judge and fill what it kept. Log a blocked site with its 'blocked:' row and give each leftover a row in applications.csv. Anything that needs the user is a one-line hand-off; move on. Every rule in the apply skill still holds, including what may be submitted."
} | awk '
BEGIN { printf "{\"decision\":\"block\",\"reason\":\"" }
{
  if (NR > 1) printf "\\n"
  for (i = 1; i <= length($0); i++) { c = substr($0, i, 1); if (c == "\\" || c == "\"") printf "\\"; printf "%s", (c == "\t" ? " " : c) }
}
END { print "\"}" }'
