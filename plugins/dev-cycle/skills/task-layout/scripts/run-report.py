#!/usr/bin/env python3
"""Per-agent cost and waste report from Claude Code transcripts.

usage: run-report.py <session.jsonl | project dir> [--since DATE] [--until DATE] [--bundle TEXT] [--totals]

Reads the main thread and every subagent transcript next to it. A subagent is labelled by the
TAG line of its brief (`TAG bundle=<dir> task=T05 stage=execute`), else by its ROLE line.
Prints one table per agent and a totals block: tokens, tool calls, test-run minutes, repeated
identical runs, polling loops, files read twice. Numbers come from the transcript, not from
estimates. Stdlib only.
"""
import glob, json, os, re, sys
from datetime import datetime

TEST = re.compile(r"\b(pytest|vitest|jest|go test|cargo test|dotnet test|playwright test|"
                  r"(pnpm|npm|yarn)( run)? [\w:.-]*test|selftest\.sh|run_backend_suite)")
POLL = re.compile(r"\buntil\b.*\bsleep\b|\bwhile\b.*\bsleep\b")


def ts(s):
    return datetime.fromisoformat(s.replace("Z", "+00:00")).timestamp()


def label(first):
    m = re.search(r"^TAG\s+(.+)$", first, re.M)
    if m:
        return m.group(1).strip()
    m = re.search(r"^ROLE\s+(.+)$", first, re.M)
    t = re.search(r"\b(T\d{2,3})\b", first)
    return ((m.group(1).strip() if m else first[:60].replace("\n", " ")) + (f" {t.group(1)}" if t else ""))[:90]


def load(path):
    rows = []
    for l in open(path, encoding="utf-8", errors="replace"):
        try:
            rows.append(json.loads(l))
        except ValueError:
            pass  # a transcript can hold a torn line
    usage, calls, results, first, times, model = {}, {}, {}, None, [], None
    for o in rows:
        if o.get("timestamp"):
            times.append(ts(o["timestamp"]))
        msg = o.get("message") or {}
        c = msg.get("content")
        if o.get("type") == "user" and first is None and not o.get("isMeta"):
            first = c if isinstance(c, str) else " ".join(x.get("text", "") for x in c if isinstance(x, dict))
        if o.get("type") == "assistant":
            model = msg.get("model") or model
            u = msg.get("usage") or {}
            usage[msg.get("id") or o.get("uuid")] = u  # a message may repeat per block: keep the last
            for b in c if isinstance(c, list) else []:
                if b.get("type") == "tool_use":
                    calls[b["id"]] = (b["name"], b.get("input") or {}, ts(o["timestamp"]))
        if o.get("type") == "user" and isinstance(c, list):
            for b in c:
                if b.get("type") == "tool_result":
                    results[b["tool_use_id"]] = ts(o["timestamp"])
    return dict(first=first or "", usage=usage, calls=calls, results=results, times=times, model=model or "?")


def analyse(name, d):
    out = sum(u.get("output_tokens", 0) for u in d["usage"].values())
    ctx = sum(u.get("input_tokens", 0) + u.get("cache_read_input_tokens", 0)
              + u.get("cache_creation_input_tokens", 0) for u in d["usage"].values())
    tools, test_s, polls_s, cmds, reads = {}, 0.0, 0.0, [], {}
    for tid, (tool, inp, t0) in d["calls"].items():
        tools[tool] = tools.get(tool, 0) + 1
        dur = max(0.0, d["results"].get(tid, t0) - t0)
        cmd = inp.get("command", "") if tool in ("Bash", "PowerShell") else ""
        if cmd and POLL.search(cmd):
            polls_s += dur
        elif cmd and TEST.search(cmd):
            test_s += dur
            cmds.append(re.sub(r"\s+", " ", cmd).strip())
        if tool == "Read" and inp.get("file_path"):
            reads[inp["file_path"]] = reads.get(inp["file_path"], 0) + 1
    wall = (max(d["times"]) - min(d["times"])) if d["times"] else 0
    return dict(name=name, label=label(d["first"]) if name != "main" else "main thread", model=d["model"],
                wall=wall, out=out, ctx=ctx, n=sum(tools.values()), test_s=test_s, polls_s=polls_s,
                cmds=cmds, reread=sum(v - 1 for v in reads.values() if v > 1), start=min(d["times"] or [0]))


def files(arg):
    if os.path.isdir(arg):
        return sorted(glob.glob(os.path.join(arg, "*.jsonl")))
    return [arg]


def main(argv):
    if not argv or argv[0] in ("-h", "--help"):
        print(__doc__); return 2
    since = until = bundle = None
    if "--since" in argv:
        since = datetime.fromisoformat(argv[argv.index("--since") + 1]).timestamp()
    if "--until" in argv:
        until = datetime.fromisoformat(argv[argv.index("--until") + 1]).timestamp()
    if "--bundle" in argv:
        bundle = argv[argv.index("--bundle") + 1]
    agents = []
    for sess in files(argv[0]):
        sub = glob.glob(os.path.join(sess[:-6], "subagents", "agent-*.jsonl"))
        for p, nm in [(sess, "main")] + [(s, os.path.basename(s)[6:-6]) for s in sorted(sub)]:
            d = load(p)
            if d["times"] and (since is None or min(d["times"]) >= since) and (until is None or min(d["times"]) < until):
                if bundle and nm != "main" and bundle not in d["first"]:
                    continue
                agents.append(analyse(nm, d))
    if not agents:
        print("no agents found"); return 1
    agents.sort(key=lambda a: a["start"])
    if "--totals" not in argv:
        print("| agent | label | model | wall min | out tok | context tok | tools | test min | poll min | reread |")
        print("| --- | --- | --- | ---: | ---: | ---: | ---: | ---: | ---: | ---: |")
        for a in agents:
            print(f"| {a['name'][:8]} | {a['label']} | {a['model'].replace('claude-', '')} | {a['wall']/60:.1f} | "
                  f"{a['out']} | {a['ctx']} | {a['n']} | {a['test_s']/60:.1f} | {a['polls_s']/60:.1f} | {a['reread']} |")
    seen = {}
    for a in agents:
        for c in a["cmds"]:
            seen[c] = seen.get(c, 0) + 1
    dup = {c: n for c, n in seen.items() if n > 1}
    print(f"\nagents {len(agents)}; out tok {sum(a['out'] for a in agents)}; context tok {sum(a['ctx'] for a in agents)}; "
          f"test runs {sum(len(a['cmds']) for a in agents)} ({sum(a['test_s'] for a in agents)/60:.1f} min); "
          f"poll loops {sum(a['polls_s'] for a in agents)/60:.1f} min; files read twice {sum(a['reread'] for a in agents)}")
    print(f"identical test commands run more than once: {len(dup)} "
          f"({sum(n - 1 for n in dup.values())} repeat runs)")
    for c, n in sorted(dup.items(), key=lambda x: -x[1])[:8]:
        print(f"  x{n}  {c[:110]}")
    return 0


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))
