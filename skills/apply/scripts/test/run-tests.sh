#!/bin/sh
# Self-check for coverage.sh: sh run-tests.sh
# Same cases as run-tests.ps1. 2026-01-01 has no log; 2026-01-02 has the failure modes seen in real runs
# (no results count, unquoted "blocked", zero pages); 2026-01-03 is complete.
here=$(cd "$(dirname "$0")" && pwd)
cov="$here/../coverage.sh"
data="$here/data"
failed=0
check() {
  out=$(sh "$cov" "$data" "$1"); code=$?
  got=$(printf '%s\n' "$out" | sed -n 's/^  //p' | tr '\n' ';')
  if [ "$code" != "$2" ] || [ "$got" != "$3" ]; then echo "FAIL $1 (exit $code): $out"; failed=1; fi
}
check 2026-01-01 1 'naukri | Node.js;naukri | Python backend;jobleads | feed;weekday | feed;'
check 2026-01-02 1 'naukri | Python backend;jobleads | feed;weekday | feed;'
check 2026-01-03 0 ''
[ "$failed" = 0 ] || exit 1
echo ok
