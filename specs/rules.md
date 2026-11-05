# SIGNAL ZERO rules — sz-rules-1

Status: **accepted implementation baseline through delegated design**, 5 November 2026. PRD v2.2 §3 and §20 leave these mechanics open. The instruction to finish Phase 01 delegates the routine choices below to the implementation team; this records agent design decisions, **not a claim that the owner personally selected every rule or that G1 playtesting passed**. Any future behavior change needs a new rules version and new vectors.

## State and graph

The baseline has four node kinds: `source`, `relay`, `switch`, `target`. No special nodes, signal colors/types, capacities, per-switch controls, waiting commands, repeated emission, or real-time deadlines are added.

| Node | Incoming | Outgoing | Behavior |
|---|---|---|---|
| source | 0 | exactly one edge, port 0 | Emits its one token at tick 0. |
| relay | any | zero or one edge, port 0 | Uses its outgoing edge. Zero outgoing is a legal draft dead end, not a valid published solution. |
| switch | any | exactly two edges, ports 0 and 1, different destinations | Routes on its current bit `0` or `1`. |
| target | any | 0 | Must receive one token on the common success tick. |

There are equally many sources and targets, from 1 to 8. Each token is identified by its source node ID. Any source token may satisfy any target: there is no hidden source-target matching. Each node ID and edge ID is unique in its own namespace; edge endpoints must exist. Duplicate directed endpoint pairs are invalid. Self-loops and directed cycles are allowed; geometric crossings have no meaning unless represented by a shared node. An edge always costs one integer tick, regardless of its drawn length.

Zero-incoming or disconnected targets, loops, and dead ends may exist in structurally valid drafts. Schema validity therefore does **not** prove solvability. Content publication additionally needs a replay validated to succeed by the solver/engine.

## Initial state and tick numbering

`tick_limit` is an integer from 1 through 64. At snapshot tick **0**, each source holds its emitted token, switches hold their explicit initial bits, and status is `RUNNING`. Emission happens once; source nodes never create a second token. No movement or target evaluation happens at tick 0. SHIFT is only legal at ticks **1..tick_limit**.

Executing tick `t` from snapshot `t-1` performs exactly this sequence:

1. Read whether the canonical program contains SHIFT at `t`.
2. If so, invert **all** switch bits simultaneously. All baseline switches are in one global group. A switch with no token still toggles.
3. Plan one outgoing edge for every token using the new routing bits and the same prior snapshot. A token without a route has no move.
4. Apply all planned moves simultaneously; each routed token travels exactly one edge. A no-route token remains where it was. This candidate position state is retained even when the tick fails.
5. Evaluate failures, synchronization, success, then the remaining tick budget using the priority below.
6. Record the immutable tick snapshot, including switch bits, token positions, used edges, target arrivals, status, and reason. In vectors, `target_arrivals` maps each reached target ID to the sorted list of **all** arriving token IDs, preserving duplicate-target collisions rather than overwriting an arrival.

The engine does not read frame time, wall clock, animation positions, platform random values, or audio state. Playback speed changes presentation only. Stepping a terminal state returns that same state without another snapshot, mutation, or attempt.

## Collision, synchronization, and failure priority

Use this priority if several conditions occur on one tick. A result includes the primary reason plus sorted diagnostic IDs; choosing a different traversal order must not change it.

| Priority | Reason/status | Condition after planned movement |
|---:|---|---|
| 1 | `NO_ROUTE` / `FAILED` | At least one token had no outgoing edge on this tick. Other routed tokens still move in the recorded snapshot. |
| 2 | `EDGE_COLLISION` / `FAILED` | Two tokens traverse opposite edges `A→B` and `B→A` on the same tick, or share the same directed edge. A geometric crossing of unrelated edges is not a collision. |
| 3 | `NODE_COLLISION` / `FAILED` | More than one token occupies the same destination node after movement, including a target or a stationary no-route token. There is no merge or target capacity greater than one. |
| 4 | `SYNC_MISS` / `FAILED` | At least one target receives a token this tick, but not every target receives exactly one. Targets do not latch, hold, retry, or accumulate across ticks. |
| 5 | `SUCCESS` / `SUCCEEDED` | Every target receives exactly one token this tick and no higher-priority failure occurred. Equal source/target counts mean all tokens are now at targets. |
| 6 | `TICK_LIMIT` / `FAILED` | No success or earlier failure and `t == tick_limit`. No tick `tick_limit+1` is executed. |
| 7 | none / `RUNNING` | None of the above. |

Successful arrival **on** `tick_limit` is valid. A path requiring one more tick fails at the tick-limit snapshot, with no speculative extra movement. A token at a dead end reached on tick 1 fails `NO_ROUTE` when routing tick 2 is attempted; if the limit was 1, it instead fails `TICK_LIMIT` at tick 1. Collision takes precedence over simultaneous complete target arrival.

Cycles are not rejected or heuristically declared impossible by the engine: SHIFT later in a timeline can change their exit. They run until success/failure or the fixed tick limit. A solver may prove a state impossible, but a search timeout is not such a proof.

## Why these choices

- One emission and exact simultaneous arrival make timing visible and keep replay state compact. Immediate partial-arrival failure explains the missed synchronization rather than silently storing a token in a target. This is an early baseline to validate at T037, not evidence that the game is already fun.
- Two switch ports and one global inversion preserve the single-action mechanic. Relay dead ends allow the editor to represent invalid attempts without inventing a node type.
- Node and head-on edge collisions make shared routes consequential. Pure drawing intersections remain harmless so layout changes cannot change puzzle behavior.
- Integer ticks and explicit failure precedence remove client/verifier ambiguity. No unbounded wait or cycle detection is required to finish a run.

Alternatives considered: repeated source emission, target latching/windowed synchronization, signals passing through each other, and per-switch SHIFT groups. They expand the state or change the teaching model and are deferred, not silently enabled.

## Reviewed walkthrough vectors

[`test-vectors/rules-cases.json`](test-vectors/rules-cases.json) is the manually authored oracle for initial and every executed tick. It covers single path, exact limit, timeout, SHIFT before routing, global toggling, simultaneous arrival, partial arrival, ordinary/target node collision, head-on collision, no route, collision-over-partial-arrival precedence, and a bounded cycle. `tools/specs/check_specs.py` checks fixture consistency and independent arithmetic/hash properties; it is **not the Phase 02 production engine** and does not claim engine equivalence. Future T011/T018 must run the real engine against this oracle.
