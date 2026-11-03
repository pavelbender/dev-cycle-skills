---
name: plan-scenarios
description: >-
  Plan interactive user scenarios for a GUI or terminal UI before technical planning: actors,
  scenario map, interaction flows, screen and command state contract, controls and
  permissions, acceptance criteria. Produces 00-interaction-scenarios.md in a feature bundle.
  Use when a request is about screens, pages, consoles, CLI flows, prompts or user stories
  («спланируй сценарии», «как пользователь будет…», «опиши экраны консоли», "user scenarios").
argument-hint: "<feature or screen>"
metadata:
  contract: ../task-layout/SKILL.md
---

# Plan GUI/TUI user scenarios

Output: one scenario document, normally
`<tasks_root>/<domain>/<feature-slug>/00-interaction-scenarios.md`, structured per
[`references/scenario-template.md`](references/scenario-template.md). It feeds `plan-feature`,
not tasks: task files are created only on explicit request.

You are an interaction planner: how a real user moves through the interface, what they see,
what they can do, how the system answers, where the boundary is. No code. For existing
behaviour, first the gap between what exists and what is asked; desired behaviour is never
described as existing.

## Language

Purpose, boundaries, open questions and the chat report in the user's language. Flows, state
tables, control tables, feature notes in compact English. Section headings as established in
the bundles (template). Routes, commands, flags, API and file names verbatim.

## When to use

Screens, pages, modals, forms, console navigation; CLI commands, prompts, confirmations,
progress, exit codes; permission-sensitive interactions where an element is hidden, disabled,
read-only or denied; states empty / loading / success / partial / conflict / denied / offline /
validation error. When backend, contracts, dependencies and tasks are needed, `plan-feature`
follows this skill.

## Principles

- From user intent and observable behaviour, not from files and components.
- The first useful scenario before secondary screens.
- Screen states are part of the contract when they change the user's decision.
- "What the user sees" is separate from "what the system does".
- No visual detail without need: density, components, place in navigation matter; pixels later.
- Permissions visible in the interaction model: who sees the entry, who may act, what disabled
  means, how denial is explained.
- TUI: command, flags, prompts, defaults, cancel, non-interactive mode, exit codes, idempotent
  repeat, dry-run.
- GUI: route, entry points, primary and secondary actions, form behaviour, focus, recovery.
- An unresolved product decision is a question with options, not a polished story.

## Phase 0. Shape of the result

New interaction, redesign, or clarification of a planned one? Which outcome must become
possible, easier, safer or impossible? Primary surface — GUI, TUI, both? Who starts the
scenario (end user, admin, operator, external system)? Standalone document, guide update, or
input for `plan-feature`? New multi-artefact feature — which `FEATURE_BUNDLE_ROOT`?

Materially different product decisions → record options and consequences, never choose
silently. Small things (labels, paths) come from repository context without a pause.

## Phase 1. Minimal evidence pack

Root and nearest `AGENTS.md`, the canonical workflow of the area, the UI or CLI map if the
project keeps one, access and role docs, existing routes and commands, tests and smoke, the
known-issues list.

| Question | Where |
| --- | --- |
| Where does the interaction live? | workflow guide, console map, CLI doc |
| Who are the actors? | access docs, roles, current tasks |
| What exists? | routes, commands, `_DONE` tasks, tests, screenshots in `evidence/` |
| What is visible? | entities, schemas, API responses, config files |
| What fails? | permissions, validation, revoked states, missing context |
| How to prove? | component and browser tests, CLI smoke, manual acceptance steps |

Do not read the whole repository: enough not to invent a second interaction model.

## Phase 2. Actors, jobs, scenario map

Story: `As <actor>, I want <outcome>, so that <reason>`. Map: `S01`, `S02`, … with actor,
surface, trigger, outcome, priority `Must` / `Should` / `Future`. `Must` is required for the
first complete workflow; `Should` after the first proof point; `Future` blocked by a product,
backend or permission decision.

## Phase 3. Interaction flows

Per `Must`: story, surface, preconditions, main flow "user → system" step by step,
alternative flows (cancel, validation, partial result, read-only), failure and denial (`F1`:
reason → visible response and allowed recovery), observable result. Format in the template.
Mermaid `flowchart TD` only when branching makes the flow clearer; never replace exact prose
with a diagram.

## Phase 4. State and permission contract

State table per surface: `Surface | State | User sees | User can do | System rule |
Verification`. GUI: control table — visible when, enabled when, denied/disabled reason,
result. TUI: command outcome table — input, output, exit code, mutates state, recovery. Only
states that change behaviour.

## Phase 5. Feature notes and criteria

Table `Feature note | Scenarios served | Needed contract | UX/TUI implication | Not included` —
the hand-over to `plan-feature`. Never invent endpoint names, fields or component paths:
only from the repository or marked "proposed".

Acceptance criteria are observable outcomes, each verified by one action sequence, command,
test or manual step. "UI works correctly" is not a criterion.

## Quality gate

Intent before interface elements; every `Must` has actor, surface, preconditions, flow,
failure, result; GUI and TUI separated where contracts differ; important states explicit;
permissions named concretely, not "admin can"; criteria testable; feature notes do not pass
proposals off as existing; `Future` separated; open decisions are questions, not facts; a new
feature follows the bundle layout; `git diff --check` clean.

## Report

Which document was created or updated; which `Must` scenarios were captured; which states,
permissions, risks and questions were recorded; whether the document is ready for
`plan-feature`; which checks ran; branch and commit per [`task-layout`](../task-layout/SKILL.md#git-hygiene). Never claim
implementation — this is a specification.
