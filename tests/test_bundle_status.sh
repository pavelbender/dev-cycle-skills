#!/usr/bin/env bash
# Check bundle-status.sh on fixture bundles. usage: tests/test_bundle_status.sh [path to bundle-status.sh]
set -euo pipefail
script=${1:-$(dirname "$0")/../plugins/dev-cycle/skills/task-layout/scripts/bundle-status.sh}
tmp=$(mktemp -d); trap 'rm -rf "$tmp"' EXIT
fail=0
has() { if grep -qF -- "$2" <<<"$out"; then echo "ok   $1: $2"; else echo "FAIL $1: missing '$2'"; echo "$out" | sed 's/^/     /'; fail=1; fi; }
task() { # dir file status blocked pass
    printf -- '---\nid: %s\nstatus: %s\nblocked_by: [%s]\nblocks: []\n%s---\n\n# Task: x\n' "${2%%-*}" "$3" "$4" "${5:+pass: $5
}" >"$1/tasks/$2"
}
sequence() { # dir: T01 -> T02, T01 -> T03, T03 -> T04, T05 and T06 independent
    cat >"$1/02-task-sequence.md" <<'EOF'
# Task sequence: demo

## Main decomposition

| ID | Task | Checkable deliverable | Depends on | Unlocks |
| --- | --- | --- | --- | --- |
| T01 | contract | schema | — | T02, T03 |
| T02 | api | endpoint | T01 | — |
| T03 | job | worker | T01 | T04 |
| T04 | ui | page | T03 | — |
| T05 | docs | guide | — | — |
| T06 | cli | command | finished work in `abc123` | — |

## Task catalogue

### T01. Contract

Work areas: packages/contracts.

### T02. API

Work areas: services/api.

## Proof points

### P01. First slice
EOF
}

b=$tmp/a; mkdir -p "$b/tasks"
out=$(bash "$script" "$b");                    has empty "stage: 2 workflow"
touch "$b/01-workflow.md"; out=$(bash "$script" "$b"); has workflow-only "stage: 3 sequence"
sequence "$b"; out=$(bash "$script" "$b");     has no-files "stage: 4 drafts"; has no-files "T04 | - | - | - | T03"
for t in T01 T02 T03 T04 T05 T06; do task "$b" "$t-x.md" formed "" draft; done
task "$b" T02-x.md formed "T01" draft; task "$b" T03-x.md formed "T01" draft; task "$b" T04-x.md formed "T03" draft
out=$(bash "$script" "$b");                    has drafts "stage: 5 detail"; has drafts "waves: {T01,T05,T06} {T02,T03} {T04}"
has drafts "T02 | formed | draft | no: T01 | T01 | - | services/api. | tasks/T02-x.md"; has drafts "proof points: P01=open"
for t in T01 T05 T06; do task "$b" "$t-x.md" formed "" slices; done
task "$b" T02-x.md formed "T01" detail; task "$b" T03-x.md formed "T01" validation; task "$b" T04-x.md formed "T03" validation
out=$(bash "$script" "$b");                    has mixed "stage: 6 slices"
for t in T01 T05 T06; do task "$b" "$t-x.md" formed "" validation; done; task "$b" T02-x.md formed "T01" validation
out=$(bash "$script" "$b");                    has planned "stage: 8 execution"; has planned "T01 | formed | validation | yes"
rm "$b/tasks/T01-x.md"; task "$b" T01-x_VAL.md validated "" validation
out=$(bash "$script" "$b");                    has t01-done "waves: {T02,T03,T05,T06} {T04}"; has t01-done "T02 | formed | validation | yes"
for t in T02 T03 T04 T05 T06; do rm "$b/tasks/$t-x.md"; task "$b" "$t-x_DONE.md" done "" validation; done
out=$(bash "$script" "$b");                    has all-done "stage: 8 execution: evidence missing for P01"
mkdir "$b/evidence"; touch "$b/evidence/P01-slice.md"
out=$(bash "$script" "$b");                    has evidence "stage: 9 close"; has evidence "waves: none"

# a task file without frontmatter: status from the suffix, blocked_by from the sequence; CRLF input
b=$tmp/c; mkdir -p "$b/tasks"; touch "$b/01-workflow.md"; sequence "$b"
printf '# Task: old\r\n' >"$b/tasks/T01-x_DONE.md"; printf '# Task: old\r\n' >"$b/tasks/T02-x.md"
printf -- '---\r\nid: T03\r\nstatus: in_progress   # started\r\nblocked_by: [T01]\r\nblocks: [T04]\r\npass: validation\r\n---\r\n' >"$b/tasks/T03-x.md"
out=$(bash "$script" "$b");                    has legacy "T01 | done | - | - | - |"; has legacy "T02 | formed | - | yes | T01"
has legacy "T03 | in_progress | validation | yes | T01"; has legacy "stage: 4 drafts"
mkdir -p "$tmp/docs/_completed/z/tasks"; touch "$tmp/docs/_completed/z/01-workflow.md"; sequence "$tmp/docs/_completed/z"
for t in T01 T02 T03 T04 T05 T06; do task "$tmp/docs/_completed/z" "$t-x_VAL.md" validated "" ""; done
mkdir "$tmp/docs/_completed/z/evidence"; touch "$tmp/docs/_completed/z/evidence/P01-s.md"
out=$(bash "$script" "$tmp/docs/_completed/z"); has completed "stage: closed"
win=$(printf '%s' "$tmp/docs/_completed/z" | tr / '\\')   # the same bundle as a backslash path
out=$(bash "$script" "$win");                  has backslash-path "stage: closed"
exit $fail
