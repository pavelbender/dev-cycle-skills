# Template `01-workflow.md`

Section names: keep those a bundle already uses; otherwise these. Goal, Scope, Open questions
in the user's language; model, contracts, failure semantics and task split in compact English.
Mermaid only when a diagram makes relations clearer; per
[`process-diagram-convention.md`](process-diagram-convention.md).

````md
# Workflow: <feature name>

<User problem, target flow, and why this is an umbrella workflow rather than one task.>

## Context sources

- `<canonical guide or decision record>`
- `<related workflows and tasks>`
- `<schemas, entities, runtime docs>`

## Goal

<Observable result and the main invariant.>

## Scope

### In scope

- <concrete outcomes of the first target workflow>

### Out of scope

- <deferred capability and reason>

## User scenarios

| Scenario | Actor | Summary |
| --- | --- | --- |

## System scenarios

| Scenario | System | Summary |
| --- | --- | --- |

## Target model and invariants

<State model, ownership, lifecycle, permissions, boundaries. Number invariants so tasks can cite
them (`INV-1`, …) unless the project has its own scheme.>

## API, contracts and data flow

<Public surfaces, request context, events, schemas, consumer impact.>

## UI and runtime surfaces

<Only relevant screens, commands, configs, delivery paths.>

## Security and failure semantics

<Authorization, secrets, trust, negative outcomes, idempotency, rollback, data preservation.>

## Workflow acceptance criteria

1. <Observable condition of a completed end-to-end scenario.>
2. <Critical negative, security or data condition.>

## Suggested task split

1. <Short name of the first dependency> — `tasks/T01-<slug>.md`.

## Open questions

| Question | Blocks | Options | Who decides |
| --- | --- | --- | --- |

## Future tasks

### F01. <Deferred capability>

<Why it is separate from the first milestone and what must be stable first.>

## Related

- [`02-task-sequence.md`](02-task-sequence.md)
- <decision records, glossary, neighbouring bundles>
````
