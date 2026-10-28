# Process diagram convention

Every process map in this repository is a Mermaid `flowchart TD` block drawn with one fixed vocabulary:
eight semantic node classes, a fixed palette, and edge labels that mean different things depending on
what the edge leaves. The point of fixing it is that a reader who has decoded one diagram has decoded
all of them, and an author never has to invent a colour.

Every block follows the same legend, so a reader who has decoded one map has decoded all.

## The vocabulary

Eight classes, and nothing else. The class carries the meaning; the shape reinforces it.

| Class | Shape | Colour | Means |
| --- | --- | --- | --- |
| `proc` | rectangle | blue | Coordinator process: what the coordinator session itself does |
| `work` | rectangle | teal | Worker process: an in-session subagent, or a queue task in its own process |
| `auto` | rectangle | violet | Automation element: hook, script, commit broker, schedule |
| `store` | rectangle | grey | State store: event log, cache, mission file |
| `evt` | stadium | green | Event |
| `io` | stadium | steel grey | Part joint: the exit of one part and the entry of the next |
| `stop` | stadium | red | Terminal event: pause, refusal, premature exit |
| `gate` | diamond | amber | Decision gate |

A rectangle is therefore always a *doing* node and its colour says *who* does it; a stadium is
always a *state reached* and its colour says whether the flow continues, joins another part, or ends.

## The palette

Copy the block verbatim. Declare only the classes the diagram actually uses — that is why no two
diagrams in the chain carry the same `classDef` list — and never restyle a single node with `style`.

```text
classDef proc fill:#E8F1FB,stroke:#2C5F8A,stroke-width:1.2px,color:#12293D
classDef work fill:#E1F4F7,stroke:#177281,stroke-width:1.2px,color:#0B3A42
classDef auto fill:#F1E9FB,stroke:#6B3FA0,stroke-width:1.4px,color:#2E1A4A
classDef store fill:#ECEDEF,stroke:#6E6E76,stroke-width:1.2px,color:#2B2B30
classDef evt fill:#E9F7E4,stroke:#3E8E41,stroke-width:1.2px,color:#1E4620
classDef io fill:#DCE6EE,stroke:#3F5B72,stroke-width:1.6px,color:#12293D
classDef stop fill:#FBEAE7,stroke:#A33B32,stroke-width:1.3px,color:#5A1E17
classDef gate fill:#FCF3D7,stroke:#A87413,stroke-width:1.3px,color:#4A3208
```

The two thicker strokes are deliberate: `auto` at `1.4px` and `io` at `1.6px`. Automation and part
joints are the two things a reader scans for, so they carry the heaviest outline.

## The rendered legend

The vocabulary drawn in its own terms, including the two sample edges. This block is the legend for
every process map in the repository; render it next to a diagram whose reader has not seen the
convention before.

```mermaid
flowchart TD

L1["Coordinator process"]
L2["Worker process or subagent"]
L3["Automation: hook, script, broker, schedule"]
L4["State store"]
L5("Event")
L6("Part joint")
L7("Terminal event")
L8{"Decision gate"}

LA["Process"] -->|"output data"| LB{"Gate"}
LB -->|"branch condition"| LC("Event")

classDef proc fill:#E8F1FB,stroke:#2C5F8A,stroke-width:1.2px,color:#12293D
classDef work fill:#E1F4F7,stroke:#177281,stroke-width:1.2px,color:#0B3A42
classDef auto fill:#F1E9FB,stroke:#6B3FA0,stroke-width:1.4px,color:#2E1A4A
classDef store fill:#ECEDEF,stroke:#6E6E76,stroke-width:1.2px,color:#2B2B30
classDef evt fill:#E9F7E4,stroke:#3E8E41,stroke-width:1.2px,color:#1E4620
classDef io fill:#DCE6EE,stroke:#3F5B72,stroke-width:1.6px,color:#12293D
classDef stop fill:#FBEAE7,stroke:#A33B32,stroke-width:1.3px,color:#5A1E17
classDef gate fill:#FCF3D7,stroke:#A87413,stroke-width:1.3px,color:#4A3208

class L1,LA proc
class L2 work
class L3 auto
class L4 store
class L5,LC evt
class L6 io
class L7 stop
class L8,LB gate
```

## Nodes

- `["…"]` for `proc`, `work`, `auto`, `store`; `("…")` for `evt`, `io`, `stop`; `{"…"}` for `gate`.
- Always quote the label. Labels carry colons, commas, dots and flag syntax, and an unquoted label
  breaks the parse on the first `:`.
- `<br/>` for line breaks. Prefer two or three short lines over one long one; a node wider than the
  gate above it forces the whole graph sideways.
- Name the real thing. A node says `mission.ps1 init -Mission ID`, `heartbeat.ps1: Stop, timeout
  600 s`, `.harness/missions/MISSION/events.jsonl` — the command, the file, the timeout, verbatim as
  the code spells it. A node that says "runs the script" is a node that will silently go stale.
- A gate label is a question with a `?`. If the question cannot be answered from state the diagram
  has already produced, the gate is in the wrong place.

## Edges

The label's meaning follows from what the edge *leaves*:

| Edge | Label carries |
| --- | --- |
| From a gate | The condition under which this branch is taken |
| From a process | The output data the process produced |
| Unlabelled `-->` | Nothing to carry: an unconditional handover, e.g. `IO1 --> G1`, `E1 --> P1` |
| Dashed `-.->` | A data link with no transfer of control |

Rules that hold across the chain:

- Every branch of every gate is drawn and labelled. A gate with an undrawn branch is a lie about the
  flow, not an omission. Branches fan out on the condition in the reader's terms, not on the boolean:
  `G1 -->|"no, the answer changes the work"| P1` and `G1 -->|"file not copied from
  settings.example.json"| P2` beat a pair of edges labelled `false` and `true`.
- The one dashed edge in the chain is `H7 -.->|"read without an open session"| H8`: the cache is read
  by something no session started. Reach for `-.->` only for that shape of fact.

## Splitting a document into parts

One diagram per part; one part per section. Parts are chained by their process inputs and outputs —
**the exit event of one part is the entry event of the next**.

- The document opens with a parts map: a table of `part | input | output`, one row per diagram. It is
  the only place a reader can see the whole chain at once, and it is what makes eleven separate
  diagrams one document.
- A part that continues the chain opens with an `io` node labelled `In: …` and closes with an `io`
  node labelled `Out: …`, whose text repeats the parts-map row. In the chain these are `IO1` and
  `IO2`.
- A part that has no upstream or no downstream carries no `io` nodes. Part 1 of the chain starts at a
  user request and ends at a state of the session; part 5 is a fan of independent
  trigger → automation chains sharing one `store`. Both are boundary parts, and forcing a joint onto
  them would invent a predecessor that does not exist.
- Parts are separated by `---`.

## Layout inside a block

```text
flowchart TD

<node declarations>

<edges>

<classDef block>

<class assignments>
```

Declarations first, all of them, then edges, then the palette, then the `class` lines — separated by
blank lines. In a fan diagram, group declarations by trigger and put a blank line between groups, and
group the edges the same way, so the groups read as the independent chains they are.

`flowchart TD` in every block. No `subgraph`, no `linkStyle`, no `LR`.

## Node ids

Ids are a local reading aid, not part of the convention: they are re-used from part to part and mean
nothing across diagrams. The habit is `E` for events, `P` for coordinator processes, `H` for
automation, `G` for gates, `IO` for joints, `S`/`LOG` for stores, `W` for workers — but the chain
itself breaks it, assigning `P5`–`P11` to `auto` and `P9`, `P12` to `work`. **Read the `class` lines,
never the prefix.** Keeping ids short and dense is worth more than keeping them systematic.

## The prose around a diagram

A part is a diagram plus a short prose block — in the chain, "What matters in this part". The diagram
carries the flow; the prose carries what a box cannot: why a timeout is what it is, what the previous
design got wrong, which file is the single writer of a cache, which two tables are editorial opinion.
Prose cites `path:line`. If a fact fits in a node, it belongs in the node, not in the prose.

## Checklist before committing a diagram

- [ ] `flowchart TD`; no `subgraph`, no `linkStyle`.
- [ ] Every node has a class; every class used is declared; nothing else is declared.
- [ ] Palette lines are byte-identical to the block above.
- [ ] Every label is quoted; every wrap is `<br/>`.
- [ ] Every gate is a question, and every branch of it is drawn and labelled with its condition.
- [ ] Every labelled process edge names the data it hands on.
- [ ] The part opens and closes on `io` nodes whose text matches its parts-map row — or it is a
      boundary part with neither.
- [ ] Commands, paths, flags and timeouts in nodes match the source they name.
- [ ] Node text is in the host document's language.
