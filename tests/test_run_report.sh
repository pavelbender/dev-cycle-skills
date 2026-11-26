#!/usr/bin/env bash
# Check run-report.py on a fixture session with one tagged subagent. usage: tests/test_run_report.sh
set -euo pipefail
script=$(dirname "$0")/../plugins/dev-cycle/skills/task-layout/scripts/run-report.py
tmp=$(mktemp -d); trap 'rm -rf "$tmp"' EXIT
mkdir -p "$tmp/s1/subagents"
line() { printf '%s\n' "$1"; }
sub=$tmp/s1/subagents/agent-aaa111.jsonl
{
line '{"type":"user","timestamp":"2026-11-26T10:00:00Z","message":{"role":"user","content":"TAG      bundle=docs/tasks/x task=T05 stage=execute\nROLE     developer; opus, high"}}'
line '{"type":"assistant","timestamp":"2026-11-26T10:00:05Z","uuid":"u1","message":{"id":"m1","model":"claude-opus-5-5","usage":{"input_tokens":2,"cache_read_input_tokens":100,"cache_creation_input_tokens":10,"output_tokens":50},"content":[{"type":"tool_use","id":"t1","name":"Bash","input":{"command":"pytest tests/a"}},{"type":"tool_use","id":"t2","name":"Read","input":{"file_path":"/a.py"}}]}}'
line '{"type":"user","timestamp":"2026-11-26T10:02:05Z","message":{"role":"user","content":[{"type":"tool_result","tool_use_id":"t1","content":"ok"},{"type":"tool_result","tool_use_id":"t2","content":"x"}]}}'
line '{"type":"assistant","timestamp":"2026-11-26T10:02:10Z","uuid":"u2","message":{"id":"m2","model":"claude-opus-5-5","usage":{"input_tokens":1,"cache_read_input_tokens":200,"cache_creation_input_tokens":0,"output_tokens":30},"content":[{"type":"tool_use","id":"t3","name":"Bash","input":{"command":"pytest tests/a"}},{"type":"tool_use","id":"t4","name":"Read","input":{"file_path":"/a.py"}},{"type":"tool_use","id":"t5","name":"Bash","input":{"command":"until [ -f done ]; do sleep 5; done"}}]}}'
line '{"type":"user","timestamp":"2026-11-26T10:03:10Z","message":{"role":"user","content":[{"type":"tool_result","tool_use_id":"t3","content":"ok"},{"type":"tool_result","tool_use_id":"t4","content":"x"},{"type":"tool_result","tool_use_id":"t5","content":"ok"}]}}'
} >"$sub"
line '{"type":"user","timestamp":"2026-11-26T10:00:00Z","message":{"role":"user","content":"go"}}' >"$tmp/s1.jsonl"
out=$(python "$script" "$tmp/s1.jsonl")
fail=0
has() { if grep -qF -- "$1" <<<"$out"; then echo "ok   $1"; else echo "FAIL missing '$1'"; echo "$out" | sed 's/^/     /'; fail=1; fi; }
has 'bundle=docs/tasks/x task=T05 stage=execute'
has '| 80 |'            # output tokens 50 + 30
has '| 313 |'           # context 2+100+10 + 1+200
has 'test runs 2 (3.0 min)'
has 'poll loops 1.0 min'
has 'files read twice 1'
has 'x2  pytest tests/a'
exit $fail
