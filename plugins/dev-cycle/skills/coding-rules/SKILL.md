---
name: coding-rules
description: >-
  Rules for how coding agents write, split, organise, edit and verify code: file budgets by
  tokens and lines, single responsibility, contracts first, side-effect isolation, minimal
  diffs, verification before claiming done (cs-001…cs-028). Use when writing, refactoring or
  reviewing code, or when execute-task points here.
metadata:
  role: contract
---

# Code structure rules for coding agents

Rules carry a `priority` (`critical`, `high`, `medium`) and a `check` that a reviewer can
apply. Projects may override a rule in their `AGENTS.md`; cite the rule ID when doing so.

```yaml
domain: code_structure_for_coding_agents
description: Rules for how coding agents should write, split, organize, edit, and verify code.
priority: critical

rules:
  - id: cs-001
    priority: critical
    statement: "MUST keep each source file focused on one primary responsibility; NEVER add unrelated behavior to a convenient existing file."
    applies_to: [source files, modules, packages]
    check: "File can be summarized in one sentence without 'and also'."

  - id: cs-002
    priority: critical
    statement: "MUST treat token count as the primary source-file budget: prefer <=1000 tokens, justify 1000-1500, split-candidate 1500-2000, split at 2000+ unless exempt; use lines only as fallback: target 200-400, warn >600, split/justify >800."
    applies_to: [source code files, generated-code exceptions, stable registries]
    token_budget:
      preferred: "<=1000"
      acceptable: "1000-1500 with sectioning and purpose"
      degraded: "1500-2000 split candidate"
      hard_limit: "2000+ split required unless exempt"
    line_budget:
      target: "200-400"
      soft_limit: "600"
      hard_limit: "800"
    precedence: "Token budget wins when token and line budgets disagree."
    check: "Files over 1000 tokens or 600 lines have a split plan or explicit exemption."

  - id: cs-003
    priority: critical
    statement: "SHOULD colocate feature code, contracts, adapters, tests, and short docs when they change together."
    applies_to: [features, packages, tests, examples]
    check: "Typical feature change stays within one local subtree."

  - id: cs-004
    priority: critical
    statement: "MUST use grep-friendly names for files and symbols; AVOID vague names like utils, helpers, common, misc, manager, data, or index."
    applies_to: [file names, symbols, directories]
    check: "Search by main symbol/path returns few relevant matches."

  - id: cs-005
    priority: high
    statement: "MUST keep public API surfaces narrow and explicit; external imports SHOULD enter through documented entrypoints."
    applies_to: [public APIs, package/module exports, stable entrypoints]
    check: "External imports do not depend on arbitrary internals."

  - id: cs-006
    priority: high
    statement: "MUST define contracts before implementation: types, interfaces, protocols, DTOs, errors, invariants, and public signatures first."
    applies_to: [contract files, type definitions, interfaces, DTOs, service APIs]
    check: "Inputs, outputs, and errors are clear without reading adapters."

  - id: cs-007
    priority: high
    statement: "MUST separate pure domain logic from side effects such as filesystem, network, database, SDK, shell, and framework calls."
    applies_to: [domain logic, services, adapters, repositories]
    check: "Core logic can be unit-tested without real I/O."

  - id: cs-008
    priority: high
    statement: "MUST keep dependencies directional; NEVER introduce import cycles, back edges, or cross-feature shortcuts."
    applies_to: [imports, packages, module boundaries]
    check: "Dependency graph has no new cycles."

  - id: cs-009
    priority: high
    statement: "SHOULD avoid broad re-export files; prefer direct imports unless maintaining a narrow documented public API layer."
    applies_to: [re-export files, package/module exports, public API aggregators]
    check: "Import path points to owner module or explicit public API."

  - id: cs-010
    priority: high
    statement: "MUST edit with minimal diffs; NEVER rewrite whole files when a targeted patch or mechanical transform is sufficient."
    applies_to: [agent edits, refactors, patches]
    check: "Patch changes only task-relevant lines."

  - id: cs-011
    priority: high
    statement: "MUST reassess design when a task touches more than five files; split the task or introduce a boundary if coupling causes the spread."
    applies_to: [feature changes, refactors, migrations]
    check: "Tasks touching >5 files include decomposition or boundary justification."

  - id: cs-012
    priority: high
    statement: "MUST add or update the nearest relevant test when changing behavior."
    applies_to: [unit tests, integration tests, contract tests]
    check: "Changed public behavior has changed or added tests."

  - id: cs-013
    priority: medium
    statement: "SHOULD add short retrieval-oriented module metadata: purpose, public API, side effects, invariants, related tests, and examples."
    applies_to: [docstrings, file headers, module README files]
    check: "Metadata is short, factual, and points to verification paths."

  - id: cs-014
    priority: medium
    statement: "SHOULD keep directory depth shallow and predictable; add nesting only for real ownership or boundary reasons."
    applies_to: [package layout, feature folders, monorepos]
    check: "Common task files are reachable through short predictable paths."

  - id: cs-015
    priority: medium
    statement: "MUST exclude generated code, vendored code, build output, minified bundles, lockfile noise, and irrelevant artifacts from active agent context."
    applies_to: [.gitignore, .cursorignore, AGENTS.md, repo maps]
    check: "Noise paths are documented and excluded from search/context."

  - id: cs-016
    priority: medium
    statement: "MUST preserve local conventions before introducing new structure unless the task explicitly changes those conventions."
    applies_to: [all edits]
    check: "New code matches nearby style, layout, imports, and test patterns."

  - id: cs-017
    priority: medium
    statement: "SHOULD implement new features as a small vertical slice first: contract, core/service logic, needed adapter, and one test."
    applies_to: [new features, prototypes, service additions]
    check: "Initial feature patch has a runnable test before broad expansion."

  - id: cs-018
    priority: high
    statement: "MUST NOT add abstractions without an observed boundary, multiple consumers, side-effect isolation need, or testability need."
    applies_to: [interfaces, base classes, shared modules, adapters]
    check: "Every abstraction names the boundary or consumer that justifies it."

  - id: cs-019
    priority: high
    statement: "MUST keep shared/common modules narrow and domain-neutral; NEVER move feature-specific behavior there just to avoid duplication."
    applies_to: [shared, common, utils, lib]
    check: "Shared code has multiple real consumers and no hidden feature ownership."

  - id: cs-020
    priority: medium
    statement: "MUST split files by responsibility, dependency, contract, side-effect, or test boundary; NEVER split only by arbitrary line count."
    applies_to: [refactoring, file decomposition]
    check: "Each split file has clear ownership, public surface, and test path."

  - id: cs-021
    priority: high
    statement: "MUST identify public entrypoint, contract, nearest tests, and side-effect boundaries before editing a module."
    applies_to: [agent workflow, code modification tasks]
    check: "Plan mentions entrypoint, contract, tests, and side effects before edit."

  - id: cs-022
    priority: medium
    statement: "SHOULD prefer explicit runtime wiring over hidden global state."
    applies_to: [services, clients, repositories, configuration]
    check: "Dependencies are visible in signatures, constructors, or factories."

  - id: cs-023
    priority: medium
    statement: "SHOULD keep examples close to public APIs and update them when public contracts change."
    applies_to: [examples, README snippets, public APIs]
    check: "Public API changes update a usage example when applicable."

  - id: cs-024
    priority: critical
    statement: "MUST verify after editing: run the smallest relevant test first, then typecheck/lint/build as required; NEVER claim completion without verification status."
    applies_to: [all code changes]
    check: "Final response reports checks run and results."

  - id: cs-025
    priority: high
    statement: "SHOULD leave navigation better than before: update nearest README, AGENTS.md, repo map, or module metadata when boundaries or ownership become clearer."
    applies_to: [AGENTS.md, README.md, repo-map.md, module docs]
    check: "New or changed boundaries are reflected in nearest navigational doc."

  - id: cs-026
    priority: critical
    statement: "MUST manage context with Write, Select, Compress, Isolate: load only phase-needed files, retrieve just-in-time, summarize after broad exploration, and separate read-only exploration from write-heavy coding."
    applies_to: [agent workflow, file reads, code review, implementation planning]
    check: "After reading five or more files, agent summarizes findings before editing."

  - id: cs-027
    priority: critical
    statement: "MUST prefer compact evidence, outlines, routers, and targeted symbol sections before raw full-file reads; raw source is only for exact text, control flow, or literals."
    applies_to: [repository exploration, code review, debugging, refactoring]
    check: "Investigation starts from routers/outlines/compact evidence before broad raw reads."

  - id: cs-028
    priority: critical
    statement: "MUST use these rules as the quality gate for every code-writing or code-checking task: confirm bootstrap, scope, source of truth, context budget, file-size budget, contract ownership, and focused verification."
    applies_to: [implementation tasks, refactors, tests, code reviews, quality gates]
    check: "Final response includes scope, changed files, and verification status."
```
