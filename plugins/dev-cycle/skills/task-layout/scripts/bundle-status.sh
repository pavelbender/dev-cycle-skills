#!/usr/bin/env bash
# Status map of a feature bundle, read from 02-task-sequence.md and the task files' frontmatter
# as the task-layout contract defines them. Prints the planning files, one row per task, the
# proof points, the dependency waves of the unfinished tasks and the stage of the cycle.
# usage: bundle-status.sh <bundle-dir>
# ponytail: bash and POSIX awk only; a host without bash builds the map by hand as the skills
# describe. Add a PowerShell twin if that becomes common.
set -euo pipefail
b=${1:?usage: bundle-status.sh <bundle-dir>}; b=${b//\\//}; b=${b%/}   # accept a Windows path
[ -d "$b" ] || { echo "not a directory: $b" >&2; exit 1; }

# A folder that is not a bundle (a domain root): print the status map of every bundle under it,
# closed bundles in _completed/ left out.
if [ ! -d "$b/tasks" ] && [ ! -f "$b/02-task-sequence.md" ]; then
    mapfile -t found < <(find "$b" -maxdepth 4 -type f -name 02-task-sequence.md -not -path "*/_completed/*" | sort)
    [ ${#found[@]} -gt 0 ] || { echo "no bundle under: $b" >&2; exit 1; }
    echo "bundles under $b: ${#found[@]}"
    for f in "${found[@]}"; do echo; bash "$0" "${f%/*}"; done
    exit 0
fi

yn() { [ -f "$1" ] && echo yes || echo no; }
shopt -s nullglob
tasks=("$b"/tasks/T[0-9]*.md)
evidence=; for f in "$b"/evidence/P[0-9]*.md; do f=${f##*/}; evidence+=" ${f%%-*}"; done
seq=(); [ ! -f "$b/02-task-sequence.md" ] || seq=("$b/02-task-sequence.md")
closed=no; case "/$b/" in */_completed/*) closed=yes ;; esac

echo "bundle: $b"
echo "scenarios: $(yn "$b/00-interaction-scenarios.md") | workflow: $(yn "$b/01-workflow.md") | sequence: $(yn "$b/02-task-sequence.md")"

awk -v workflow="$(yn "$b/01-workflow.md")" -v evidence="$evidence" -v closed="$closed" '
function ids(s,   out) {            # "T01, T03 (done in abc)" -> "T01,T03"
    out = ""
    while (match(s, /T[0-9]+/)) { out = out (out == "" ? "" : ",") substr(s, RSTART, RLENGTH); s = substr(s, RSTART + RLENGTH) }
    return out
}
function value(s) { sub(/^[^:]*:[ \t]*/, "", s); sub(/[ \t]+#.*$/, "", s); gsub(/^[ \t"]+|[ \t"]+$/, "", s); return s }
function add(id) { if (!(id in known)) { known[id] = 1; order[++n] = id } }
function finished(id) { return status[id] == "done" || status[id] == "validated" }
function open(id) { return (id in file) && !finished(id) && status[id] != "withdrawn" }
function blockers(id,   a, k, i, out) {   # predecessors that are not done or validated
    out = ""; k = split(dep[id], a, ",")
    for (i = 1; i <= k; i++) if (a[i] != "" && !finished(a[i])) out = out (out == "" ? "" : ",") a[i]
    return out
}
BEGIN { rank["draft"] = 1; rank["detail"] = 2; rank["slices"] = 3; rank["validation"] = 4 }
{ sub(/\r$/, "") }
FNR == 1 { isseq = (FILENAME ~ /02-task-sequence\.md$/); fm = 0; cur = ""
    if (!isseq) {
        id = FILENAME; sub(/^.*\//, "", id); name = id; match(id, /^T[0-9]+/); id = substr(id, RSTART, RLENGTH)
        add(id); file[id] = name
        status[id] = (name ~ /_VAL\.md$/) ? "validated" : (name ~ /_DONE\.md$/) ? "done" : "formed"
        if ($0 == "---") { fm = 1; next }
    }
}
isseq {
    if ($0 ~ /^\|[ \t]*T[0-9]+[ \t]*\|/) {             # row of the main decomposition table
        split($0, c, "|"); id = c[2]; gsub(/[ \t]/, "", id)
        if (!(id in inseq)) { inseq[id] = 1; add(id); seqdep[id] = ids(c[5]) }
    } else if ($0 ~ /^###[ \t]+T[0-9]+/) { match($0, /T[0-9]+/); cur = substr($0, RSTART, RLENGTH) }
    else if ($0 ~ /^###[ \t]+P[0-9]+/) { match($0, /P[0-9]+/); proof[++np] = substr($0, RSTART, RLENGTH); cur = "" }
    else if ($0 ~ /^##/) cur = ""
    else if (cur != "" && $0 ~ /^Work areas:/) areas[cur] = value($0)
    next
}
fm && $0 == "---" { fm = 0; next }
fm {
    if ($0 ~ /^status:/) status[id] = value($0)
    else if ($0 ~ /^blocked_by:/) { dep[id] = ids(value($0)); hasdep[id] = 1 }
    else if ($0 ~ /^pass:/) pass[id] = value($0)
    else if ($0 ~ /^milestone:/) milestone[id] = value($0)
    else if ($0 ~ /^signals:/) signals[id] = value($0)
}
!fm && !(id in title) && /^# / { t = $0; sub(/^#[ 	]+(Task:[ 	]*)?/, "", t); title[id] = t }
END {
    for (i = 1; i <= n; i++) { id = order[i]; if (!(id in hasdep)) dep[id] = seqdep[id] }
    print ""; print "ID | status | pass | ready | blocked_by | milestone | work areas | file | signals | title"
    for (i = 1; i <= n; i++) {
        id = order[i]
        if (!(id in file)) { print id " | - | - | - | " (seqdep[id] == "" ? "-" : seqdep[id]) " | - | " (id in areas ? areas[id] : "-") " | MISSING | - | -"; missing = missing " " id; continue }
        if (!(id in inseq) && nseq()) extra = extra " " id
        bl = blockers(id)
        ready = finished(id) || status[id] == "withdrawn" ? "-" : (bl == "" ? "yes" : "no: " bl)
        print id " | " status[id] " | " (id in pass ? pass[id] : "-") " | " ready " | " (dep[id] == "" ? "-" : dep[id]) " | " (id in milestone ? milestone[id] : "-") " | " (id in areas ? areas[id] : "-") " | tasks/" file[id] " | " (id in signals ? signals[id] : "?") " | " (id in title ? title[id] : "-")
    }
    print ""
    k = split(evidence, e, " "); for (i = 1; i <= k; i++) have[e[i]] = 1
    line = "proof points:"; if (np == 0) line = line " none"
    for (i = 1; i <= np; i++) { line = line " " proof[i] "=" ((proof[i] in have) ? "evidence" : "open"); if (!(proof[i] in have)) noev = noev " " proof[i] }
    print line

    # Waves: a layer of the blocked_by graph over the unfinished tasks.
    for (i = 1; i <= n; i++) if (open(order[i])) { left[order[i]] = 1; nleft++ }
    line = "waves:"; if (nleft == 0) line = line " none"
    while (nleft > 0) {
        w = ""
        for (i = 1; i <= n; i++) { id = order[i]; if (!(id in left)) continue
            ok = 1; k = split(dep[id], a, ","); for (j = 1; j <= k; j++) if (a[j] != "" && ((a[j] in left) || !(a[j] in file) || status[a[j]] == "withdrawn")) ok = 0
            if (ok) w = w (w == "" ? "" : ",") id }
        if (w == "") { line = line " STUCK{"; for (id in left) line = line " " id; line = line " } (cycle, or a predecessor that is missing or withdrawn)"; break }
        k = split(w, a, ","); for (j = 1; j <= k; j++) { delete left[a[j]]; nleft-- }
        line = line " {" w "}"
    }
    print line
    if (missing != "") print "sequence tasks without a file:" missing
    if (extra != "") print "task files not in the sequence:" extra

    # Stage, per the table of the cycle skill.
    lowest = 5; nopass = ""
    for (i = 1; i <= n; i++) { id = order[i]; if (!open(id)) continue
        opened++
        if (!(id in pass) || !(pass[id] in rank)) { nopass = nopass " " id; r = 0 } else r = rank[pass[id]]
        if (r < lowest) lowest = r }
    if (workflow != "yes") stage = "2 workflow (run scenarios first when the intent names a screen or a CLI flow)"
    else if (!nseq()) stage = "3 sequence"
    else if (missing != "") stage = "4 drafts"
    else if (opened && nopass != "") stage = "5 detail, or later: infer the pass from the sections of" nopass
    else if (opened && lowest < 2) stage = "5 detail"
    else if (opened && lowest < 3) stage = "6 slices"
    else if (opened && lowest < 4) stage = "7 validation"
    else if (opened) stage = "8 execution"
    else if (noev != "") stage = "8 execution: evidence missing for" noev
    else if (closed == "yes") stage = "closed"
    else stage = "9 close"
    print "stage: " stage
}
function nseq(   x, c) { c = 0; for (x in inseq) c++; return c }
' ${seq[@]+"${seq[@]}"} ${tasks[@]+"${tasks[@]}"} </dev/null
