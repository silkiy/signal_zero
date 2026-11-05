# Resource and validation limits — sz-limits-1

Status: **accepted delegated initial limits**, 5 November 2026, T007. These are conservative implementation budgets, not claims about a solver, renderer, mobile device, production service, or supported scale that has not been built. T017/T039/T058/T089 must measure the real implementations and version/document any changes. Bounds apply before allocation/decompression/search, not after an unbounded operation.

## Gameplay and payload bounds

All maxima are inclusive. Structural validity also follows [rules.md](rules.md) and the exact field allowlists in [identity-and-versioning.md](identity-and-versioning.md).

| Field | Minimum | Maximum | Rejection |
|---|---:|---:|---|
| Nodes | 2 | 64 | `LIMIT_EXCEEDED` / `INVALID_GRAPH` |
| Edges | 1 | 128 | `LIMIT_EXCEEDED` / `INVALID_GRAPH` |
| Sources | 1 | 8 | `LIMIT_EXCEEDED` / `INVALID_GRAPH` |
| Targets | 1 | 8, equal to sources | `LIMIT_EXCEEDED` / `INVALID_GRAPH` |
| Switches | 0 | 32 | `LIMIT_EXCEEDED` |
| `tick_limit` | 1 | 64 | `INVALID_TICK` |
| SHIFT actions | 0 | 64, at most one per tick | `LIMIT_EXCEEDED` / `NON_CANONICAL_ACTIONS` |
| SHIFT tick | 1 | puzzle `tick_limit` | `INVALID_TICK` |
| Node/edge ID | 1 ASCII byte | 32 ASCII bytes | `INVALID_ID` |
| Gameplay JSON integer | 0 | 2147483647 before tighter field bounds | `INVALID_INTEGER` |
| Raw puzzle JSON | — | 65536 bytes (64 KiB) | `INPUT_LIMIT` |
| Raw replay JSON | — | 16384 bytes (16 KiB) | `INPUT_LIMIT` |
| API submission envelope | — | 131072 bytes (128 KiB) | `INPUT_LIMIT` |
| JSON nesting | — | 16 containers deep, root container depth 1 | `DEPTH_LIMIT` |
| Share Code encoded input | — | 65536 bytes including envelope/base encoding | `INPUT_LIMIT` |
| Share Code decoded puzzle | — | 65536 bytes | `DECOMPRESSED_LIMIT` |
| `.szsave` encoded file | — | 2097152 bytes (2 MiB) | `INPUT_LIMIT` |
| `.szsave` decompressed JSON | — | 8388608 bytes (8 MiB) | `DECOMPRESSED_LIMIT` |
| Backup entities across collections | — | 10000; each embedded puzzle still obeys its own limits | `LIMIT_EXCEEDED` |
| Individual backup metadata string | — | 4096 UTF-8 bytes | `LIMIT_EXCEEDED` |
| Nickname | 1 Unicode scalar after trim | 32 Unicode scalars **and** 128 UTF-8 bytes | `LIMIT_EXCEEDED` / `INVALID_VALUE` |

The 128-edge ceiling is a defensive parser bound, not permission to violate source/relay/switch outdegrees. With 64 nodes and the baseline degree limits a valid graph will generally have fewer edges. Source/target count equality and degree checks happen after bounded parse; disconnected targets/cycles/dead ends are legal drafts, and need a solver proof before publication.

Do not allocate an array indexed by an unchecked ID/tick/count. Reject duplicate object keys/IDs and unknown fields before hashing. Incoming port numbers, non-existing endpoints, duplicate directed pairs, missing switch ports, or incoming edges to source fail `INVALID_GRAPH`/`UNKNOWN_REFERENCE`. Duplicate/unsorted SHIFT is rejected at untrusted boundaries; the trusted editor serializes its tick set canonically.

## Bounded work

| Work unit | Initial maximum | Interpretation |
|---|---:|---|
| Solver retained unique states | 25000 | Stop before retaining state 25001. |
| Solver evaluated transitions | 50000 | Stop before evaluating transition 50001. |
| Solver-owned memory | 33554432 bytes (32 MiB) | Includes frontier, visited/proof/predecessor data and retained paths; key-set capacity alone is not enough. |
| Interactive solver/generator work | 500 ms | Worker/isolate, never a blocking UI call. |
| Offline content-generation/solver worker work | 5000 ms | Longer bounded validation; not a promise every graph fits. |
| Generator candidates per request | 100 | Stop on first applicable budget/cancellation; no invalid fallback puzzle. |
| Verifier replay worker wall time | 2000 ms | Only replay/check/hash, no unbounded solver. Watchdog kills/cancels a stuck worker. |
| Work cancellation/deadline checks | every 128 transitions **or sooner** | Also check on each bounded input chunk and at work start/end. |
| Per-worker queued jobs | 8 | Further work receives retryable `BUSY`; API rate/global quotas are separately set by T006. |

Stop at the **first** reached budget. The time/candidate/state/transition budgets cover the **whole request**, including every generator candidate and nested solver call: pass the remaining budget down, never restart 500 ms for each of 100 candidates. Check elapsed monotonic time; deadline scheduling never determines a gameplay result. State/transition budget is deterministic work accounting, wall-clock/memory is environmental protection. Cancellation/deadline cleanup must release worker resources; returning timeout while work continues is not completion. Use a watchdog/process boundary where in-worker cancellation cannot be guaranteed. These budgets can cause an otherwise valid puzzle to return unknown on a slower device; a published solution is valid independently of how long the solver needed to find it.

Result contract:

| Result | What is established |
|---|---|
| `INVALID_INPUT` | Schema/version/resource validation rejected the request before gameplay. Specific error identifies the bound. |
| `SOLVED_OPTIMAL` | A replay succeeds and the requested optimization objective has an exhaustive/certified bound proof. Include objective/hash/versions. |
| `SOLVED_UNPROVEN` | A replay succeeds, but optimum not proved; it may establish solvability only. |
| `UNSATISFIABLE` | Complete bounded problem space was exhausted with a proof there is no valid solution under the puzzle's fixed tick limit. |
| `BUDGET_EXHAUSTED` | Work stopped on state/transition/time/memory/candidate budget; include reason. No claim of impossibility or optimality. A found valid replay may be attached with unproven status. |
| `CANCELLED` / `BUSY` | Work aborted/not admitted; no gameplay conclusion. |

Publisher policy must explicitly decide if a valid unproven-optimum puzzle is suitable for a mode/difficulty. It may never publish a candidate without a replay that the engine validates to succeed. Achievements requiring optimum proof remain locked for unknown/unproven bounds.

## Import, compression, and backup field boundaries

1. Measure raw bytes before decoding. For base encoding, estimate decoded bytes before allocation and enforce the real output cap while streaming.
2. Allow only the format's selected compression codec; use bounded streaming output and reject truncated/trailing/unexpected members according to that format. Never call an unbounded decompress-then-check helper. Absolute output and input caps are both enforced; no guessed compression ratio substitutes for them.
3. Validate depth before recursive materialization. A parser without a depth bound must be guarded by a streaming pre-scan or a sandboxed worker with strict memory/time caps. JSON must not execute code, interpret file paths, fetch URLs, or construct arbitrary runtime objects.
4. Apply schema/version allowlists and reference/duplicate checks; verify checksum. A checksum detects corruption only. Valid-looking user-edited local progress does not prove competitive/achievement eligibility.
5. Preview without writes, prebackup, then transactional merge/restore under T052/T053. Never load secrets into the preview/export source object.

Backup's reserved top-level data namespaces are `schema_version`, `created_at_utc`, `profile`, `progress`, `best_scores`, `settings`, `drafts`, `achievements`, `imported_puzzles`, and `cached_puzzles`. Exact nested schema/codec/migration is T051; each namespace must itself be allowlisted, not an arbitrary map. Profile portable data contains local UUID/nickname, not active wallet/session credentials. Reject unknown fields rather than recursively copying them. In particular `private_key`, `seed_phrase`, mnemonic, auth token, wallet session, cookies, signer key, or any equivalent secret field must never be exported or accepted as a valid restore field. A denylist is an additional check, **not** a replacement for schema allowlists.

## Measured small probe and rationale

Actual command: `python tools/specs/check_specs.py --probe` on Python 3.11.15, Windows 10 build 26300, desktop environment available to this task.

| Probe | Observed result |
|---|---:|
| Synthetic maximum-node specimen | 64 nodes, 88 edges, all IDs 32 bytes |
| Canonical puzzle bytes | 16104 bytes; fits 65536-byte cap |
| Parse JSON + SHA-256, 100 repetitions | 13.239 ms total in this run |
| Retain 25000 distinct synthetic 32-byte keys in a Python set | 86.447 ms in this run |
| Peak Python allocations traced for that set | 3899837 bytes |

This probe is bounded and reproducible, not a benchmark target. It demonstrates that the chosen input envelope and a small retained-key count are reasonable desktop starting points. It does **not** measure real graph reachability, solver branching/optimality, state objects/path storage, process RSS, renderer FPS, Dart/web/native speed, or mobile latency. The separate 32 MiB cap and worker deadlines remain mandatory; an implementation can hit them before the state-count cap. The 64-tick ceiling makes the naïve space `2^64`, so the solver must report unknown rather than attempt unconditional exhaustive search. T017 must benchmark the actual representation and adjust versioned limits only with recorded evidence.

[`test-vectors/invalid-inputs.json`](test-vectors/invalid-inputs.json) contains inclusive maximum `n-1/n/n+1`, minimum boundaries, malformed/reference/version/duplicate/compression descriptors, and the distinction between a legal cycle and invalid input. These are acceptance cases for future production validators; the Phase 01 checker verifies the corpus and arithmetic, **not a production parser's rejection behavior**.
