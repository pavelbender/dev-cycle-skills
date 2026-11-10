# State files

All in `<jobs_state>/probe-paths/` (default `.dev-cycle/jobs/probe-paths/`), ignored by
git. They are the only memory between iterations. Create them in iteration 1.

| File | Holds | Rule |
| --- | --- | --- |
| `STATE.md` | index for the next iteration | read first; under 80 lines; rewritten, not appended |
| `coverage.md` | one row per walked scenario | append rows; never delete a walked row |
| `findings.md` | every finding | new entry per finding; corrections as dated notes |
| `scenarios-backlog.md` | ideas and unreached scenarios | move a taken idea to `coverage.md` |
| `accounts.local.json` | test accounts and the test password | never quoted in findings or reports |
| helper scripts | login and API helpers for the stand | written once, reused by every brief |

## STATE.md

```markdown
# probe-paths STATE (read first; keep under 80 lines)

Iterations: <N> (last: <date and time>)
Findings: <count active> (F-01…F-NN, withdrawn: F-…). Next ID: F-<NN+1>.

## Working mode
<who runs what; exclusive resources; rules learnt>

## Stand
<base URLs, how to log in, helper script, client build and isolation recipe, safe and
forbidden commands, UI routes that were found, selectors that work>

## Owner permissions
<what the owner allowed and forbade, with the date>

## Test objects
<tenants, accounts with member IDs, shared objects not to change, evidence samples left
broken on purpose, disposable members>

## Covered
<one line per surface pair or family>

## Next (highest first)
<scenarios for the next iteration, already split into single-focus briefs>

## Blockers
<what the stand cannot reach and what the owner would have to provide>
```

## coverage.md

```markdown
| # | Role | Area | Action | Surface | Status | Iteration |
|---|------|------|--------|---------|--------|-----------|
| 1 | viewer | devices | obtain a CLI token | UI+API | F-05 | 1 |
| 2 | owner+admin | skills, projects, roles | parallel edits | saas+saas | F-07…F-15 | 1 |
```

Status: `ok`, finding IDs, `part` with what is missing, or `blocked` with the reason.
Below the table keep a `todo` matrix of families and roles not yet walked.

## findings.md

```markdown
## F-NN. <one-line statement of the defect>
- Role: … · Surface: … · Type: … · Severity: low | medium | high · Status: reported
- Steps: <numbered, exact>
- Expected: …
- Actual: <statuses, texts, exit codes>
- Evidence: <excerpt; IDs of the sample objects>
```

- Statuses: `confirmed`, `reported`, `candidate`, `by-code`, `stand-artifact`,
  `withdrawn`. A changed status is a dated note under the entry, not a rewrite; a
  withdrawn finding keeps its number and says why.
- A finding that repeats a tracked issue is not added: list it under "Duplicates of known
  issues" with the issue ID and the fact that it reproduced.
- After each batch add a short "Behaved correctly" block: correct behaviour found is
  coverage too, and the best examples are the yardstick for the defects next to them.
- Severity: `high` — data or access lost, a state with no supported exit, or a write
  applied against the user's evident intent; `medium` — a path broken or misleading with a
  workaround; `low` — wording, missing convenience, inconsistent codes.
- Measurements (local footprint, swarm runs) keep their tables and seeds with the finding.

## Final report

On stop, give the owner: the directory, counts by severity and by status, the findings
that are unconfirmed or `by-code`, the stand artefacts, the scenario families not walked,
and the test data left on the stand, including every record inserted outside the product's
own API.
