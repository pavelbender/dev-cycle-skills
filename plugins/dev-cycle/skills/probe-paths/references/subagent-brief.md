# Subagent brief

A probing subagent starts with nothing but the brief. Write every brief from this skeleton
and fill every part; a missing part costs the subagent its time budget.

## Skeleton

```text
You are a QA prober for <product> on a LOCAL stand. Goal: <one focus>. Report findings
only: do NOT fix anything, do NOT edit repository files, do NOT commit. Budget: about
<N> minutes wall time, then report what you have (partial is fine; say what was not
reached and why).

HARD LIMITS
- <the only base URLs allowed; the hosts never to contact>
- <what must never be read, written or started: real credentials, home, agent config,
  installed services; the exact commands that are forbidden and the ones known safe>
- <isolation recipe to run before every client call, as copy-paste commands>
- <tenant and object prefix it may touch; the shared objects it must not change; the
  disposable objects that are its own>

SETUP FACTS
- <helper script and how to log in as each test account>
- <IDs of tenant, project, members, sample assets>
- <how to obtain a client credential; the checkout recipe that is known to work>
- <where routes and schemas are; which large files to query, not read>
- <pitfalls already paid for: shell quirks, wrong routes, selectors>

ALREADY KNOWN (do not re-report; add only new detail)
- <one line per known finding in this area>

SCENARIOS (in this order; skip what is blocked)
1. <scenario with the exact calls or pages and what to look for>
...

OUTPUT: only entries in exactly this format, then one line of what behaved correctly, one
line of what was not reached and why, and the IDs of objects left behind. No passwords or
tokens.

### <short title>
- Role: ...
- Surface: ...
- Steps: <numbered, exact commands, calls, routes>
- Expected: ...
- Actual: <statuses, texts, exit codes>
- Type: dead end | missing function | broken path | permission mismatch | race | footprint
- Severity: low | medium | high
- Evidence: <excerpt>

Before finishing: <restore roles, re-enable what was disabled, remove bindings, revoke
enrolled devices, stop processes it started, leave the shared objects as they were>.
```

Write the field labels of the output format in the language `findings.md` uses.

## Rules for the brief

- One focus. List the scenarios in the order you want them; the tail is usually not
  reached. Aim for what fits in about nine minutes.
- Name the surface pair explicitly (SaaS + CLI, CLI + MCP + SaaS) so the report can be
  filed in `coverage.md` without interpretation.
- Give exact IDs and commands. A subagent that has to discover the tenant, the login
  recipe or the build command spends its budget on setup.
- Carry the profile's `boundaries` line and the notes' hard limits verbatim.
- State what is known, or the same findings come back as new.
- Tell it how to tell a race from a missing check: run the pair in parallel, then
  sequentially.
- Ask for observations it could not verify to be marked as such, and for anything that
  looks like a stand artefact to be labelled.
- Require cleanup and a list of what stays. Samples that prove a dead end stay on purpose;
  say so.

## Lessons that belong in every brief

- An exclusive resource has one user: one browser, one client profile directory, one
  port. Hand it to a single subagent and say "you are the only user".
- Client commands run from a disposable checkout with an isolated home and credential
  path, never from the product repository root, where they may read the developer's own
  state.
- Never let a client command install, start or stop background services on the machine
  unless the notes allow it; a foreground one-shot mode is the safe substitute.
- Browser scripts: short default timeout, one try/catch per step, compact returned
  values, links counted as buttons. One snapshot is cheaper than three failed selectors.
- Test passwords are read by the subagent from the state directory and are not echoed in
  reports. Scripts that embed them are deleted afterwards.
- Shell traps that silently void a run (case-insensitive variable names, helper names
  that collide with built-in aliases) are listed under pitfalls as soon as one is hit.
- A scenario the stand cannot reach (no email delivery, no provider access, metadata
  worker off) is reported once as a blocker with what the API or UI tells a user in that
  state; it is not retried every iteration.
