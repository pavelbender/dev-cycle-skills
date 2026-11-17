#!/usr/bin/env bash
# lint-task.sh <task file>...  Mechanical checks on a task file; prints file:line: rule per finding, exit 1 if any.
# Rules: no file:line references, no test or PASS counts, no record sections, no duplicate criteria section, size ceiling.
rc=0
emit() { [ -n "$1" ] && { printf '%s\n' "$1"; rc=1; }; }
for f in "$@"; do
  emit "$(grep -n -E '[A-Za-z0-9_./-]+\.(go|py|ts|tsx|js|md|sh|json|sql|toml|ya?ml):[0-9]+' "$f" | cut -d: -f1 | sort -un | sed "s|^|$f:|; s|\$|: line reference (anchor by path and symbol)|")"
  emit "$(grep -n -i -E '(exactly|prints|expect(s|ed)?|reads?) `?[0-9]+`?( |$)|[0-9]+ (passed|PASS|tests? pass|files? changed)' "$f" | cut -d: -f1 | sort -un | sed "s|^|$f:|; s|\$|: count of tests, files or output lines (state the check, not the number)|")"
  emit "$(grep -n -E '^## (Execution record|Validation record|Result|Validation|Validation plan|Tests and validation)$' "$f" | cut -d: -f1 | sed "s|^|$f:|; s|\$|: record or duplicate-criteria section (records go to evidence/, checks go into Acceptance criteria)|")"
  size=$(wc -c < "$f"); [ "$size" -gt 20000 ] && emit "$f:1: $size bytes, ceiling 20000 (restates code or the plan)"
done
exit $rc
