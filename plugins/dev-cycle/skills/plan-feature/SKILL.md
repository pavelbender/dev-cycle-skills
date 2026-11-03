---
name: plan-feature
description: >-
  Plan a new feature or a change of existing behaviour as repository documentation: an
  umbrella workflow (01-workflow.md) with target model and invariants, an impact map, and a
  dependency-ordered task sequence (02-task-sequence.md) with TNN tasks and PNN proof points.
  Use when asked to plan, decompose or design a feature, cycle or bundle («спланируй фичу»,
  «разложи на задачи», «нужен план цикла», «workflow и task sequence», "plan feature").
argument-hint: "<feature or change> [workflow|sequence|all]"
metadata:
  contract: ../task-layout/SKILL.md
---

# Plan a feature or a behaviour change

Planning model:

```text
umbrella workflow → impact map → dependency graph → small tasks → proof points
```

Output: documents in one feature bundle `<tasks_root>/<domain>/<feature-slug>/`:
`01-workflow.md` (target behaviour and model) and `02-task-sequence.md` (dependency graph
and task catalogue). Templates: [`references/workflow-template.md`](references/workflow-template.md),
[`references/task-sequence-template.md`](references/task-sequence-template.md). Layout, IDs,
readiness, project profile: [`task-layout`](../task-layout/SKILL.md).
Separate task files only on request, via `write-task`.

Second argument limits the output: `workflow` (only `01`), `sequence` (only `02`, the
workflow must exist), `all` (default).

You are a technical planner: reconcile the request with the repository's current state,
document the target model, split the work into dependency-ordered tasks. No code. For a new
feature define the target workflow; for an existing one first the gap between what is shipped,
what is documented and what is asked. Desired behaviour is never described as existing.

If `00-interaction-scenarios.md` exists (`plan-scenarios`), reuse the bundle.

## Language

Purpose, boundaries, decisions, open questions, risks and the chat report in the user's
language. Impact map, task cards, proof-point commands, dependency notes in compact English.
Section headings as established in the bundles (templates). Paths, identifiers, commands,
schema names verbatim.

## Principles

- From user and system scenarios, not from a list of files.
- Target state first, separate from current state; the transition only when needed.
- Never call "one task" work that changes independent layers, contracts, data, UI or carries
  several separately verifiable risks.
- Every task: one outcome, a named checkable deliverable, bounded work areas, dependencies,
  what it unlocks, its own verification.
- Decompose by dependencies: model and invariants → contracts → logic → delivery → UI →
  integration. Not by directory names.
- No abstract "for later" surfaces in the first milestone: `Future tasks`.
- Security, ownership, idempotency, rollback, data preservation explicit when they affect a
  contract.
- A schema or wire-contract change puts the decision record and every consumer in the impact
  map from the start.
- Assumptions do not replace evidence: unknown state → question or discovery task.
- An unresolved architecture decision is a question with options, not a fact; an owner
  decision is recorded as `D-*` without the history of alternatives.

## Deliverables and proof points

Each task yields a deliverable checkable without reference to future work: a migration with
tests, a contract with schema and schema test, a CLI command with smoke, one console capability
with its API, an end-to-end scenario with a reproducible command sequence. "Advance the
backend" is not a deliverable.

After every two–three tasks a `PNN` point: tasks it proves, the scenario that now works,
commands or steps, expected result and a negative condition. A longer chain → explain the
dependency that prevents it and keep it short.

## Phase 0. Shape of the result

What changes: new capability, rule, UX, API, data lifecycle, runtime, or correction of
documented drift? Which outcome must become possible or impossible? Local task, new workflow,
or continuation of an existing sequence? Only the two documents, short task drafts, or
detailed first tasks? `FEATURE_BUNDLE_ROOT` for new work or a canonical family to update in
place?

Materially different product decisions → record options and consequences, never choose
silently.

## Phase 1. Minimal evidence pack

Root `AGENTS.md` and its `## Dev cycle` profile → the domain README → nearest `AGENTS.md` →
decision records, schemas and glossary the profile names. Code via a code graph or language
server when the project has one; docs and literals via search.

| Question | Where |
| --- | --- |
| Canonical context? | domain workflows, decision records, schemas, `AGENTS.md`, bundle READMEs |
| Already done? | `_DONE`/`_VAL` tasks, `_completed/`, evidence, tests, `git log` |
| Current contract? | JSON Schema, parquet schemas, migrations, CLI, OpenAPI, consumers |
| Boundaries not to cross? | decision records, invariants, forbidden zones and `boundaries` in `AGENTS.md` |
| How to prove? | existing tests, the profile's `stand` smoke, the project's known-issues list |

Do not read the whole repository. Every claim in the plan has a source: code, document, test or
an explicitly marked new decision.

## Phase 2. Target workflow

Create or update `01-workflow.md` per the template. Happy path from action to durable result;
failures that change architecture (no permission, no context, state conflict, invalid input,
incomplete local state); control plane separate from runtime, canonical identity separate from
short-lived handles; who owns each record, file, resource and what may be deleted.
Implementation detail only when it changes a contract, security, dependency order or an
acceptance criterion.

## Phase 3. Impact map

Table `Layer | Current state | Required change | Risk/invariant` for touched layers only:
workflow, persistence/model, API/contracts, authorization/policy, resolver/state machine,
CLI/runtime, storage/zones, observability/audit, UI, docs/tests. The map chooses tasks, it is
not a checklist: do not invent an untouched layer and do not hide a real dependency behind
"adjust where needed".

## Phase 4. Decisions and questions

The workflow records decisions that shape architecture: identity and lifecycle, source of
truth, authorization context and denial reasons, compatibility direction (direct migration,
one-off backfill, no legacy bridge), artefact ownership, trust and checksums, rollback and
repeated runs. Open questions short, each marked with what it blocks: the whole plan, one
task, or the future.

## Phase 5. Decomposition

Create or update `02-task-sequence.md`. Atomicity: one checkable goal; a named deliverable;
bounded work areas; no decisions hidden in a future task; explicit dependencies; a concrete
"unlocks"; one small implement-and-verify cycle; no "while we are here". Split by ownership,
risk, consumer, verification or delivery order; never mechanically, leaving the first task
with half a contract.

Console UI as small capabilities, each tied to the task that delivers its contract (`model →
API → UI slice`), not one "frontend" task at the end. A UI task names the exact API operation
it consumes.

Conventions: `TNN` for tasks, `PNN` for proof points; IDs are copied from here, not derived
from a free filename; published IDs never renumbered; `Depends on` may reference finished
work — then with the document, commit or contract; `Unlocks` is a concrete consequence;
unknown order because of an unverified fact → a narrow discovery task first.

## Phase 6. Changing existing behaviour

Table `Aspect | Current state | Target state | Transition` over workflow, persisted state,
contract, runtime, tests and docs. Per gap one path: direct contract change; migration/backfill
with ownership and repeatability; removal of the obsolete; temporary compatibility only for a
real consumer, with an end date and a removal test. No "just in case" legacy fallback, no
parallel source of truth.

## Quality gate

The workflow explains the target flow and is not one task; boundaries separate the first
milestone from the future; state, permission and ownership invariants explicit; the dependency
graph is real, not just an order; every task has goal, scope, dependencies, unlocks,
verification, deliverable; proof points at most every 2–3 tasks; the first batch is a complete
useful vertical slice; schemas, ADRs, consumers and docs included where they change; `DONE`
claims and statements about current behaviour backed by evidence; `git diff --check` clean;
nothing unresolved presented as fact.

## Report

Which workflow and task sequence were created or updated; the first batch; significant
decisions, risks, questions; whether task drafts were created; which checks ran; branch and
commit per [`task-layout`](../task-layout/SKILL.md#git-hygiene). Never claim implementation.
