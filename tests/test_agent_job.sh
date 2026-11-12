#!/usr/bin/env bash
# Check agent-job.sh with a stub crontab and a stub claude: cron schedules, model pinning,
# prompt composition, and that the state directory stays out of `git status`.
# usage: tests/test_agent_job.sh [path to agent-job.sh]
set -euo pipefail
src=${1:-$(dirname "$0")/../plugins/dev-cycle/agent-jobs/agent-job.sh}
script=$(cd "$(dirname "$src")" && pwd)/$(basename "$src")
tmp=$(mktemp -d); trap 'rm -rf "$tmp"' EXIT
mkdir -p "$tmp/bin" "$tmp/home" "$tmp/repo"
cat >"$tmp/bin/crontab" <<EOF
#!/usr/bin/env bash
f="$tmp/crontab.txt"
case \${1:-} in -l) [ -f "\$f" ] && cat "\$f" || exit 1 ;; -r) rm -f "\$f" ;; -) cat >"\$f" ;; esac
EOF
cat >"$tmp/bin/claude" <<EOF
#!/usr/bin/env bash
printf '%s\n' "\$*" >"$tmp/claude.args"; cat >"$tmp/claude.stdin"
EOF
chmod +x "$tmp/bin/crontab" "$tmp/bin/claude"
git -C "$tmp/repo" init -q
export HOME=$tmp/home PATH=$tmp/bin:$PATH

fail=0
line() { grep -F "# dev-cycle:repo $1" "$tmp/crontab.txt"; }
sched() { line "$1" | grep -oE '^[^c]*' | sed 's/ $//'; }   # the five cron fields: up to "cd"
expect() { # job expected
    local got; got=$(sched "$1")
    if [ "$got" = "$2" ]; then echo "ok   $1: $got"; else echo "FAIL $1: got '$got', want '$2'"; fail=1; fi
}
run() { "$script" install "$@" --repo "$tmp/repo" >/dev/null; }

run collect-issues;               expect collect-issues  '0 0,6,12,18 * * *'
run collect-backlog;              expect collect-backlog '0 3,9,15,21 * * *'
run autodebug;                    expect autodebug       '7,37 * * * *'
run autobacklog;                  expect autobacklog     '22,52 * * * *'
run autodebug;                    expect autodebug       '7,37 * * * *'        # reinstall keeps interval and offset
run autodebug --every 60m;        expect autodebug       '22 * * * *'          # new interval, offset recomputed (1 other worker)
run autodebug;                    expect autodebug       '22 * * * *'          # reinstall keeps the 60 min interval
run autobacklog --every 15;       expect autobacklog     '7,22,37,52 * * * *'
run autobacklog --every 2h;       expect autobacklog     '22 0,2,4,6,8,10,12,14,16,18,20,22 * * *'
run collect-backlog --every 1h;   expect collect-backlog '30 * * * *'
run collect-issues --every 24h;   expect collect-issues  '0 0 * * *'
run collect-issues;               expect collect-issues  '0 0 * * *'           # reinstall keeps 24h
run collect-backlog --every 12h --hour 5 --minute 10; expect collect-backlog '10 5,17 * * *'
for bad in 45m 7 90m 5h 0 abc; do
    if "$script" install autodebug --every "$bad" --repo "$tmp/repo" >/dev/null 2>&1; then echo "FAIL --every $bad accepted"; fail=1; else echo "ok   --every $bad rejected"; fi
done

# model and effort: defaults stay out of the cron line, explicit values go in
run autodebug
if line autodebug | grep -q -- '--model'; then echo "FAIL default model in the cron line"; fail=1; else echo "ok   default model is not in the cron line"; fi
run autodebug --model sonnet --effort low
if line autodebug | grep -qF -- "--model 'sonnet' --effort 'low'"; then echo "ok   explicit model and effort are in the cron line"; else echo "FAIL explicit model missing: $(line autodebug)"; fail=1; fi

# run: prompt from the header, common.md and agent-jobs/jobs/<job>.md; per-job model and effort
plugin=$(cd "$(dirname "$script")/.." && pwd)
mkdir -p "$HOME/.claude/plugins"
printf '{ "plugins": {\n  "dev-cycle@test": [ {\n    "installPath": "%s"\n  } ] } }\n' "$plugin" >"$HOME/.claude/plugins/installed_plugins.json"
# the last case: a line installed before effort existed names a model only and keeps medium
for pair in "collect-issues::--model sonnet --effort high" "autodebug::--model opus --effort high" "autobacklog::--model opus --effort medium" "collect-issues:--model opus:--model opus --effort medium"; do
    job=${pair%%:*}; rest=${pair#*:}; extra=${rest%%:*}; want=${rest#*:}
    # shellcheck disable=SC2086
    "$script" run "$job" --dry-run --repo "$tmp/repo" $extra >/dev/null 2>&1 || true
    if grep -qF -- "$want" "$tmp/claude.args" && grep -q '^## Job: ' "$tmp/claude.stdin" \
        && grep -q '^# Unattended dev-cycle job' "$tmp/claude.stdin" && grep -q '^Mode: DRY RUN' "$tmp/claude.stdin"; then
        echo "ok   run $job $extra: $want; prompt has header, common rules and job text"
    else echo "FAIL run $job: args '$(cat "$tmp/claude.args" 2>/dev/null)'"; fail=1; fi
done
if [ -z "$(git -C "$tmp/repo" status --short)" ]; then echo "ok   state directory is not in git status"; else echo "FAIL git status: $(git -C "$tmp/repo" status --short)"; fail=1; fi

"$script" pause --repo "$tmp/repo" >/dev/null; grep -c '^#paused# ' "$tmp/crontab.txt" | sed 's/^/paused lines: /'
"$script" uninstall --repo "$tmp/repo" >/dev/null; [ ! -s "$tmp/crontab.txt" ] && echo "ok   uninstall leaves no lines"
exit $fail
