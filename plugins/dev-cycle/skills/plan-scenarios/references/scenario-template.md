# Template `00-interaction-scenarios.md`

Section names: keep those a bundle already uses; otherwise these. Goal, Scope, Open questions
in the user's language; flows and tables in compact English. No empty sections: "Not
required" with a reason.

````md
# Interaction scenarios: <feature name>

<Which user outcome this document clarifies and where it goes next: `plan-feature`, a guide
update, tasks.>

## Context sources

- `<canonical guide or workflow>`
- `<UI/CLI map, entities, API, tasks>`

## Goal

<Observable user outcome and the main interaction invariant.>

## Scope

### In scope

- <outcomes of the first target interaction>

### Out of scope

- <deferred interactions and why>

## Actors and jobs

| Actor | Job | Context | Permission/capability assumptions |
| --- | --- | --- | --- |

## Scenario map

| Scenario | Actor | Surface | Trigger | Desired outcome | Priority |
| --- | --- | --- | --- | --- | --- |
| S01 | ... | GUI / TUI / both | ... | ... | Must |

## Interaction flows

### S01. <scenario name>

Story: as `<actor>`, I want <outcome>, so that <reason>.

Surface: GUI / TUI / both.

Preconditions:

- <state, permissions, selected context, local config>

Main flow:

1. User <action>.
2. System <response>.

Alternative flows:

- A1. <cancel, validation, partial result, read-only>

Failure and denial:

- F1. <missing permission / context / input> → <visible response and allowed recovery>.

Result:

- <observable state that proves success>.

## UI/TUI state contract

| Surface | State | User sees | User can do | System rule | Verification |
| --- | --- | --- | --- | --- | --- |
| `/route` or `<cli> <cmd>` | Empty | ... | ... | ... | ... |

## Controls and permissions

| Control or command | Visible/available when | Enabled when | Denied/disabled reason | Result |
| --- | --- | --- | --- | --- |

For TUI also:

| Command case | Input | Output | Exit code | Mutates state | Recovery |
| --- | --- | --- | --- | --- | --- |

## Feature notes for technical planning

| Feature note | Scenarios served | Needed contract | UX/TUI implication | Not included |
| --- | --- | --- | --- | --- |

## Acceptance criteria

1. <observable outcome checked by one action, command or test>

## Validation plan

- <component / browser / manual / CLI smoke>

## Open questions

| Question | Blocks | Options | Decision needed |
| --- | --- | --- | --- |

## Future scenarios

### F01. <name>

<Why it is separate from the first milestone and what must be stable first.>
````

Good criteria:

1. A project admin with `files.write` opens `/projects/42/files`, uploads a file and sees the
   new row without a reload.
2. A member without that permission sees the page read-only, the upload button is absent, a
   direct `POST` returns `403`.
3. `app files import --dry-run` prints the plan and exits `0` without touching storage.
