#!/usr/bin/env bash
# Scheduled dev-cycle agent jobs on cron (Linux, macOS): autodebug and autobacklog work on items
# every 30 minutes by default; collect-issues and collect-backlog feed them every 6 hours by
# default. --every sets another interval: 30m, 60m, 2h (plain number = minutes).
# install/uninstall/pause/resume/status manage one crontab line per repository and job, tagged
# "# dev-cycle:<repo> <job>". Each line runs the stable copy ~/.claude/agent-jobs/agent-job.sh
# run, which composes the prompt from the installed dev-cycle plugin at run time, so plugin
# updates need no reinstall. Windows counterpart: agent-job.ps1.
#
# usage: agent-job.sh <install|uninstall|pause|resume|status|run> [autodebug|autobacklog|collect-issues|collect-backlog]
#        [--repo DIR] [--every 30m|2h] [--minute N] [--hour N] [--dry-run] [--max-agents N] [--model M] [--effort E]
set -euo pipefail

JOBS=(autodebug autobacklog collect-issues collect-backlog)
JOBS_HOME=$HOME/.claude/agent-jobs
STABLE=$JOBS_HOME/agent-job.sh
SELF=$(cd "$(dirname "$0")" && pwd)/$(basename "$0")
BUDGET=7200       # hard kill of the agent process group, seconds
WRAPUP=900        # the agent stops implementing this long before the kill, seconds

ACTION=${1:-}; [ $# -eq 0 ] || shift
JOB= REPO=. EVERY= MINUTE=-1 HOUR=-1 DRY=0 MAXAGENTS=2 MODEL= EFFORT=
while [ $# -gt 0 ]; do
    case $1 in
        autodebug|autobacklog|collect-issues|collect-backlog) JOB=$1 ;;
        --repo) REPO=$2; shift ;;
        --every) EVERY=$2; shift ;;
        --minute) MINUTE=$2; shift ;;
        --hour) HOUR=$2; shift ;;
        --dry-run) DRY=1 ;;
        --max-agents) MAXAGENTS=$2; shift ;;
        --model) MODEL=$2; shift ;;
        --effort) EFFORT=$2; shift ;;
        *) echo "unknown argument: $1" >&2; exit 2 ;;
    esac
    shift
done
case $ACTION in install|uninstall|pause|resume|status|run) ;; *) sed -n '10,11p' "$SELF" >&2; exit 2 ;; esac

# minutes <30|30m|2h>: the interval in minutes. Cron cannot express an arbitrary period, so the
# interval must repeat evenly: a divisor of 60 minutes, or whole hours that divide a day.
minutes() {
    local n
    [[ $1 =~ ^([0-9]+)([mh]?)$ ]] || { echo "--every $1: use minutes or hours, e.g. 30m, 60m, 2h" >&2; return 2; }
    n=$((10#${BASH_REMATCH[1]})); [ "${BASH_REMATCH[2]}" != h ] || n=$((n * 60))
    if [ "$n" -lt 1 ] || [ $((1440 % n)) -ne 0 ] || { [ "$n" -lt 60 ] && [ $((60 % n)) -ne 0 ]; } || { [ "$n" -ge 60 ] && [ $((n % 60)) -ne 0 ]; }; then
        echo "--every $1: use a divisor of an hour (5m, 10m, 15m, 20m, 30m) or whole hours that divide a day (1h, 2h, 3h, 4h, 6h, 8h, 12h, 24h)" >&2; return 2
    fi
    echo "$n"
}

repoName=
if top=$(git -C "$REPO" rev-parse --show-toplevel 2>/dev/null); then REPO=$top; repoName=$(basename "$REPO")
elif [ "$ACTION" != status ]; then echo "Not a git repository: $REPO" >&2; exit 1; fi
if [[ $ACTION == install || $ACTION == run ]] && [ -z "$JOB" ]; then echo "job is required for $ACTION" >&2; exit 2; fi
targets=("${JOBS[@]}"); [ -z "$JOB" ] || targets=("$JOB")

# `## Dev cycle` profile of the root AGENTS.md (or CLAUDE.md): `- key: value` lines.
profile() { # key default
    local f v=
    for f in AGENTS.md CLAUDE.md; do [ -f "$REPO/$f" ] && { v=$(tr -d '\r' <"$REPO/$f" | awk -v k="$1" '
        /^## / { in_ = ($0 ~ /^## Dev cycle[ \t]*$/); next }
        in_ && index($0, "- " k ": ") == 1 { r = substr($0, length(k) + 5); sub(/[ \t][ \t]+#.*$/, "", r); gsub(/^[ \t]+|[ \t]+$/, "", r) }
        END { print r }'); break; }; done
    echo "${v:-$2}"
}

plugin_root() {
    local r
    r=$(awk '/"dev-cycle@/ { f = 1 } f && match($0, /"installPath": *"[^"]*"/) { v = substr($0, RSTART, RLENGTH); sub(/^"installPath": *"/, "", v); print substr(v, 1, length(v) - 1); exit }' \
        "$HOME/.claude/plugins/installed_plugins.json" 2>/dev/null) || true
    [ -n "$r" ] || { echo 'The dev-cycle plugin is not installed for Claude Code' >&2; return 1; }
    echo "$r"
}

q() { printf "'%s'" "${1//\'/\'\\\'\'}"; }   # single-quote for the crontab line
iso() { date -d "@$1" +%Y-%m-%dT%H:%M:%S 2>/dev/null || date -r "$1" +%Y-%m-%dT%H:%M:%S; }

# cron_edit <drop|add|pause|resume> <repo> <job> [line]: change this repo's line for the job.
cron_edit() {
    local mode=$1 tag=" # dev-cycle:$2 $3" cur out= l
    cur=$(crontab -l 2>/dev/null || true)
    [ -z "$cur" ] || while IFS= read -r l; do
        if [[ $l == *"$tag" ]]; then
            case $mode in
                pause) [[ $l == '#paused# '* ]] || l="#paused# $l" ;;
                resume) l=${l#'#paused# '} ;;
                *) continue ;;
            esac
        fi
        out+=$l$'\n'
    done <<<"$cur"
    [ "$mode" != add ] || out+=$4$'\n'
    if [ -n "$out" ]; then printf %s "$out" | crontab -; else crontab -r 2>/dev/null || true; fi
}

cron_lines() { crontab -l 2>/dev/null | grep -F ' # dev-cycle:' || true; }

# Model and effort are pinned per job, so a changed default in the user's settings does not
# apply. Collectors read and write documents; autodebug fixes bugs, where checking matters
# most; autobacklog builds scoped work. --model and --effort given at install go into the cron
# line; without them a job follows these defaults, also after a plugin update. A line that
# names a model and no effort (installs made before effort existed) runs at medium, as it did.
pin=
if [ -n "$JOB" ]; then
    case $JOB in collect-*) dm=sonnet de=high ;; autodebug) dm=opus de=high ;; *) dm=opus de=medium ;; esac
    [ -z "$MODEL" ] || de=medium
    [ -z "$MODEL" ] || pin+=" --model $(q "$MODEL")"
    [ -z "$EFFORT" ] || pin+=" --effort $(q "$EFFORT")"
    MODEL=${MODEL:-$dm}; EFFORT=${EFFORT:-$de}
fi

if [ -n "$repoName" ]; then stateRoot=$REPO/$(profile jobs_state .dev-cycle/jobs/); stateRoot=${stateRoot%/}; fi

# Keep the state directory out of the operator's `git status`. Called by install and by run,
# so a dry run before install leaves the checkout clean too.
ensure_ignored() {
    local rel exclude
    rel=$(profile jobs_state .dev-cycle/jobs/); rel=${rel%/}
    if git -C "$REPO" check-ignore -q -- "$rel/$JOB/ledger.md"; then return 0; fi
    exclude=$(git -C "$REPO" rev-parse --path-format=absolute --git-common-dir)/info/exclude
    mkdir -p "$(dirname "$exclude")"; echo "/$rel/" >>"$exclude"
    echo "Added /$rel/ to $exclude"
}

case $ACTION in
install)
    command -v crontab >/dev/null || { echo 'crontab not found: install cron' >&2; exit 1; }
    command -v claude >/dev/null || { echo 'claude not found in PATH' >&2; exit 1; }
    ensure_ignored
    mkdir -p "$JOBS_HOME"
    [ "$SELF" = "$STABLE" ] || { cp "$SELF" "$STABLE.new" && chmod +x "$STABLE.new" && mv "$STABLE.new" "$STABLE"; }

    tag="# dev-cycle:$repoName $JOB"
    mine=$(cron_lines | grep -F " $tag" | head -n1 | sed 's/^#paused# //') || true
    every= wm= wh=
    if [ -n "$EVERY" ]; then every=$(minutes "$EVERY")   # a new interval resets the offset
    elif [ -n "$mine" ]; then                            # reinstall: keep the interval and the offset
        read -r mf hf _ <<<"$mine"; wm=${mf%%,*}; wh=${hf%%,*}
        if [[ $mf == *,* ]]; then c=${mf//[^,]/}; every=$((60 / (${#c} + 1)))
        elif [ "$hf" = '*' ]; then every=60
        else c=${hf//[^,]/}; every=$((1440 / (${#c} + 1))); fi
    elif [[ $JOB == collect-* ]]; then every=360; else every=30; fi
    if [[ $JOB == collect-* ]]; then   # collectors: half an interval apart
        off=0; [ "$JOB" != collect-backlog ] || off=$((every / 2)); dm=$((off % 60)); dh=$((off / 60))
    else                               # workers: spread over the half hour, pairs 15 min apart
        n=$(cron_lines | grep -vF " $tag" | grep -vcE ' collect-[a-z]+$') || n=0
        dm=$(( (7 + 15 * n + 5 * (n / 2)) % 30 )); dh=0
    fi
    [ "$MINUTE" -ge 0 ] || MINUTE=${wm:-$dm}
    [ "$HOUR" -ge 0 ] || { if [[ $wh =~ ^[0-9]+$ ]]; then HOUR=$wh; else HOUR=$dh; fi; }
    list=
    if [ "$every" -lt 60 ]; then
        MINUTE=$((MINUTE % every)); for ((i = MINUTE; i < 60; i += every)); do list+=${list:+,}$i; done
        sched="$list * * * *"
    else
        step=$((every / 60)); MINUTE=$((MINUTE % 60)); HOUR=$((HOUR % step))
        if [ "$step" -eq 1 ]; then list='*'; else for ((i = HOUR; i < 24; i += step)); do list+=${list:+,}$i; done; fi
        sched="$MINUTE $list * * *"
    fi
    # cron runs with a bare environment and a ~1000-char line limit: bake in a short PATH (claude's
    # dir, which also holds node for npm installs, plus the usual tool dirs).
    cpath=$(dirname "$(command -v claude)"):/opt/homebrew/bin:/usr/local/bin:/usr/bin:/bin
    line="$sched cd $(q "$REPO") && PATH=$(q "$cpath") $(q "$STABLE") run $JOB --repo $(q "$REPO")$pin >/dev/null 2>&1 $tag"
    case $line in *%*) echo 'the path to the repository or PATH contains "%", which cron cannot take' >&2; exit 1 ;; esac
    cron_edit add "$repoName" "$JOB" "$line"
    echo "$repoName $JOB: every $every min, cron '$sched'; $MODEL, $EFFORT; state $stateRoot/$JOB"
    ;;
uninstall|pause|resume)
    for j in "${targets[@]}"; do
        cron_lines | grep -qF " # dev-cycle:$repoName $j" || continue
        case $ACTION in uninstall) cron_edit drop "$repoName" "$j"; echo "$repoName ${j}: removed" ;;
            pause) cron_edit pause "$repoName" "$j"; echo "$repoName ${j}: paused" ;;
            resume) cron_edit resume "$repoName" "$j"; echo "$repoName ${j}: resumed" ;;
        esac
    done
    ;;
status)
    cron_lines | while IFS= read -r l; do
        st=active; [[ $l != '#paused# '* ]] || { st=paused; l=${l#'#paused# '}; }
        t=${l##*# dev-cycle:}
        printf '%-44s %-7s cron %s\n' "$t" "$st" "$(cut -d' ' -f1-5 <<<"$l")"
    done
    if [ -n "$repoName" ]; then
        for j in "${JOBS[@]}"; do
            ledger=$stateRoot/$j/ledger.md
            [ ! -f "$ledger" ] || { echo "== $j ($ledger)"; tail -n 5 "$ledger"; }
        done
    fi
    ;;
run)
    state=$stateRoot/$JOB
    ensure_ignored >/dev/null
    mkdir -p "$state/reports" "$state/logs" "$state/patches"
    ledger=$state/ledger.md
    [ -f "$ledger" ] || printf '| stamp | item | status | branch | commit | report |\n| --- | --- | --- | --- | --- | --- |\n' >"$ledger"
    find "$state/logs" -type f -mtime +14 -delete

    root=$(plugin_root)
    latest=$root/agent-jobs/agent-job.sh
    if [ "$SELF" = "$STABLE" ] && [ -f "$latest" ] && ! cmp -s "$latest" "$STABLE"; then
        cp "$latest" "$STABLE.new" && chmod +x "$STABLE.new" && mv "$STABLE.new" "$STABLE"   # takes effect from the next run
    fi

    start=$(date +%s); stamp=$(date +%Y%m%d-%H%M)
    # ponytail: a stale lock whose PID was reused counts as running; clear running/ if runs stop.
    running=$JOBS_HOME/running; mkdir -p "$running"
    live=()
    for f in "$running"/*.lock; do
        [ -e "$f" ] || continue
        if kill -0 "$(cat "$f")" 2>/dev/null; then live+=("$(basename "$f" .lock)"); else rm -f "$f"; fi
    done
    lock=$running/$repoName-$JOB.lock
    # Collectors run 4 times a day and are not capped, or busy workers would starve them.
    if { [[ $JOB != collect-* ]] && [ ${#live[@]} -ge "$MAXAGENTS" ]; } || [[ " ${live[*]:-} " == *" $repoName-$JOB "* ]]; then
        echo "${stamp}: busy (${live[*]:-})" >>"$state/logs/skipped.log"
        exit 0
    fi
    echo $$ >"$lock"
    trap 'rm -f "$lock"' EXIT

    deadline=$((start + BUDGET))
    notesRel=$(profile job_notes ""); notes=; [ -z "$notesRel" ] || notes=$REPO/$notesRel
    others=; for j in "${JOBS[@]}"; do [ "$j" = "$JOB" ] || others+="${others:+; }$j = $stateRoot/$j"; done
    promptFile=$state/logs/$stamp.prompt.md
    {
        cat <<EOF
Job: $JOB
Run stamp: $stamp
Started: $(iso "$start")
Stop and wrap up by: $(iso $((deadline - WRAPUP)))
Hard deadline: $(iso "$deadline") (the process group is killed then)
Mode: $([ "$DRY" = 1 ] && echo 'DRY RUN' || echo FULL)
Model: $MODEL
Effort: $EFFORT
Platform: $(uname -s)
Repository (main checkout, operator's tree): $REPO
State directory: $state
State directories of the other jobs: $others
Job notes: ${notes:-none}
dev-cycle plugin root: $root


EOF
        cat "$root/agent-jobs/common.md"; echo
        cat "$root/agent-jobs/jobs/$JOB.md"
        [ -z "$notes" ] || { printf '\n# Project job notes (%s)\n\n' "$notesRel"; cat "$notes"; }
    } >"$promptFile"
    log=$state/logs/$stamp.jsonl
    err=$state/logs/$stamp.err.log

    cd "$REPO"
    set -m   # own process group, so the deadline kills the whole agent tree
    claude -p --model "$MODEL" --effort "$EFFORT" --permission-mode bypassPermissions --output-format stream-json --verbose \
        <"$promptFile" >"$log" 2>"$err" &
    pid=$!
    set +m
    code=
    while kill -0 "$pid" 2>/dev/null; do
        if [ "$(date +%s)" -ge "$deadline" ]; then
            kill -TERM -- "-$pid" 2>/dev/null || true; sleep 10; kill -KILL -- "-$pid" 2>/dev/null || true
            code=timeout; break
        fi
        sleep 5
    done
    if [ -z "$code" ]; then code=0; wait "$pid" || code=$?; else wait "$pid" 2>/dev/null || true; fi

    shopt -s nullglob; reported=("$state/reports/$stamp-"*.md)
    if [ "$code" != 0 ] || [ ${#reported[@]} -eq 0 ]; then
        echo "| $stamp | (runner) | exit $code, report $([ ${#reported[@]} -gt 0 ] && echo written || echo missing) | - | - | logs/$stamp.jsonl |" >>"$ledger"
    fi
    ;;
esac
