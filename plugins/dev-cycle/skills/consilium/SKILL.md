---
name: consilium
description: >-
  Convene a consilium: 4–5 role agents (architects, developer, QA, UI/UX, release manager,
  researcher) study one hard question independently, each from its own domain, then challenge
  each other's positions; the chair records a consensus or a reasoned decision with the
  dissent. The most expensive decision tool of the set. Use when a hard question or a complex
  conclusion spans several functional domains of the product and the evidence and the advisor
  did not settle it, or when asked to convene a consilium or council of agents («созови консилиум», «консилиум агентов», «нужен консенсус агентов», "consilium",
  "council of agents").
argument-hint: "<question> [--roles <role,role,…>] [--record <file>]"
metadata:
  contract: ../task-layout/SKILL.md
---

# Consilium

Input: one question; optional `--roles` to seat named roles; optional `--record` naming the
document that receives the decision. Claude Code passes `$ARGUMENTS`; Codex the request text.

You are the chair. You frame the question, seat the members, keep them independent, check
their evidence and record the result. You do not tell a member which answer you expect.

Roles, models, effort, layers and the brief format come from
[delegation](../task-layout/references/roles-and-models.md).

## When to convene

A direct request from the user to convene a consilium is enough: convene it. On your own
initiative, convene only when all three conditions hold:

- **Several domains.** The question spans two or more functional domains of the product (for
  example persistence and authorization; an API contract and the UI that consumes it;
  runtime and data lifecycle), so no single role sees every consequence.
- **Weight.** The answer is a decision that is costly to reverse (a contract, a schema,
  stored data, the security model, behaviour users already rely on), or a complex conclusion
  that later work builds on (the cause of a failure that crosses components, the impact of a
  change on several consumers, a choice between architectures).
- **Not settled more cheaply.** Reading the code and running checks did not settle it, and
  the advisor, when the host has one, gave no answer, a partial answer, or an answer the
  evidence disputes.

Do not convene for a question inside one domain, for a fact that a read or a command can
establish, or twice for the same question without new evidence.

Cost: every member reads the project on its own, and there are up to two rounds. One
consilium costs about as much as four or five role-agent runs. That is why the three
conditions are strict.

Who convenes: only the main conversation. A subagent that meets such a question returns
`needs consilium: <question> · <domains> · <evidence paths>` in its report and continues with
the work that does not depend on the answer.

Owner decisions: a product or business decision belongs to the owner. A consilium can
prepare the options and a recommendation for the owner. It does not take the decision, and
it does not override the never-on-autopilot list of `cycle` or `needs-owner` in the
unattended jobs. On `cycle --auto` the consilium's decision is the choice autopilot takes
and records.

A host without subagents has no consilium: record the question with its options as open and
ask the owner. Do not play the members yourself; one context cannot give independent
positions.

## Phase 1. Frame the question

Write the question pack. Every member receives the same pack.

- **Question**: one decision or one conclusion to reach, phrased neutrally, that a choice
  between options, a short design or a reasoned finding can answer. Several decisions in one question: split them and take the one that
  blocks the others.
- **Why now**: what the answer blocks.
- **Domains**: the functional domains it touches.
- **Options**: the known ones, unranked, plus "none of these".
- **Constraints**: invariants, accepted decisions (`D-*`, decision records), the profile's
  `boundaries`, dates.
- **Evidence**: paths to code, schemas, the workflow, the task file, logs. Give paths, not
  your summary of them.

The pack for round 1 carries no positions: not yours, not the advisor's.

## Phase 2. Seat the members

Seat 4–5 members with different lenses, chosen by the domains in the pack.

| Member | Lens | Seat when |
| --- | --- | --- |
| system architect | target model, invariants, contracts between components, long-term cost | always |
| QA developer | failure paths, testability, what would prove the choice | always |
| developer | feasibility in this codebase, hidden complexity, existing patterns | the answer changes code |
| solution architect | fit to the current layers, migration path, order of work | the answer changes structure or a contract |
| uiux expert | user flows, states, permissions the user sees | UI or CLI behaviour is touched |
| release manager | rollout, rollback, migration order, compatibility window | data, deploy order or compatibility is touched |
| researcher | facts outside the repository: dependency docs, incidents, measurements | the answer depends on such facts |

A role can sit with a narrowed lens, for example "QA developer: security" or "solution
architect: data model". Two members never share a lens. When fewer than four rows apply, add
a second architect or QA developer with a narrowed lens that the question touches (security,
data model, performance). If you cannot name four different lenses, the question is not
cross-domain: do not convene. When more than five rows apply, keep the two "always" seats
and the three rows whose domains the decision turns on; give a dropped lens to the nearest
seat as a narrowed lens.

Model and effort: each member runs on the first tier its row of the roles table names, at
`high` whatever effort that row gives: a seat is judgment work. The researcher is the exception: everyday tier, `medium`, because a position is
synthesis. Members are read-only: no edits, no commits, no commands, no helpers. Claude
Code: seat every member as the agent type `dev-cycle:consilium-member`, whose tools (read and
search only) enforce that; pass the role's `model` and the effort on the call. Where that
type is missing (Codex): a normal spawn with `SCOPE read-only` in the brief. The researcher
seat needs the web, which that type cannot reach: seat it as a general-purpose agent with
`SCOPE read-only`, or put the outside facts into the question pack yourself.

## Phase 3. Round 1: independent positions

Start all members in one message so they run at the same time and cannot see each other.

```text
ROLE     <role>, consilium member; <model>, <effort>
GOAL     Give your position on the question below from your lens. Other members cover the
         other lenses. The chair combines the positions; a clear position with evidence is
         worth more than a hedge.
QUESTION <the question pack>
LENS     <what this member judges>
SCOPE    read-only; no edits, no commits, no commands
HELPERS  no helpers
RETURN   position: <the option or design you recommend, 2–5 sentences>
         evidence: <file:line or document for each claim>
         checks for the chair: <commands that would settle a point, and what each would show>
         risks: <what breaks if your position is taken, and for whom>
         conditions: <what must hold for it to work>
         would change my mind: <the fact that would flip your position>
         confidence: high | medium | low, and one line why
         unknowns: <what you could not verify>
```

## Phase 4. Combine

Build the table `member | position | key evidence | risks | confidence`.

1. Check the evidence that carries a position yourself: open the `file:line`, and run the
   "checks for the chair" that bear on the decision. A claim you cannot confirm counts as an
   opinion.
2. The positions are compatible and their conditions can hold together → consensus. Go to
   phase 6.
3. Otherwise write each disagreement as one concrete point, for example: "A: migrate in
   place. B: dual-write. Disputed fact: whether table X has readers outside this service."
4. A disagreement about a fact is settled by checking the fact, not by a vote: you run the
   command, or a researcher reads the code when reading is enough.

## Phase 5. Round 2: challenge

Only when a disagreement remains after phase 4. Send each member the positions table (by
role), the disputed points, the facts found since round 1, and the advisor's answer when
there was one. Continue the same member agents when the host can message them (Claude Code:
`SendMessage`); otherwise start fresh agents and include their own round-1 position.

Ask each member for:

- the strongest objection to each other position;
- whether it keeps, changes or narrows its own position, and the evidence for that;
- the smallest check or experiment that would settle a disputed point.

There is one challenge round. What still disagrees after it goes to the chair's decision.

## Phase 6. Decide

- **Consensus**: adopt it.
- **Majority with dissent**: adopt it when the dissent's risks are mitigated or accepted in
  the record.
- **Split**: decide in this order: executable truth and invariants; the option that is
  cheaper to undo; the smallest change that meets the constraints. Evidence outweighs the
  number of voices: one member with a verified blocking fact outweighs four opinions.
- **Owner-level** (architecture or business per the project's rules): hand the options and
  the recommendation to the owner. On autopilot record the recommendation as
  `autopilot: <choice> — <reason>`.

## Phase 7. Record

Write the record where the question lived: the workflow's decisions (`D-*`), the task file's
open decisions, or a decision record when the profile names `decisions`. `--record` names the
file explicitly. A question with no document: give the record in the reply. The record is the
one edit to a task file or workflow that a coordinator makes itself; commit it per
[`task-layout`](../task-layout/SKILL.md#git-hygiene). Remove the question from the open
questions.

```markdown
### Consilium: <question> (<date>)

- Decision: <what>. Reached by: consensus | majority | chair's decision | handed to the owner.
- Why: <2–4 lines: the evidence that carried it>.
- Members: <role — model, effort — position in one line>; …
- Dissent: <who, what, why it was not adopted> | none.
- Conditions and follow-ups: <checks, tasks, proof points>.
- Reopen when: <the fact that would invalidate the decision>.
```

Add a model notes row per member, task kind `consilium`.

## Report

In the user's language, for a reader who has not seen the rounds: the decision first, how it
was reached, the dissent, the conditions and follow-ups, where it is recorded, and the
members with model and effort.

## Anti-patterns

Convening for a fact. Telling members the expected answer. Letting members see each other in
round 1. Counting voices instead of evidence. A third round. A consilium inside a consilium.
Using it to override an owner decision. Members editing files.
