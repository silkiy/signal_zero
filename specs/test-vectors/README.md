# SIGNAL ZERO golden vectors — `sz-golden-1`

Task T011, 6 November 2026. These are independently reviewed **expected** results for `sz-engine-1` / `sz-rules-1`. No production engine generated any transition in this corpus. Loading a vector or passing the fixture tests does not prove that an engine, solver, client/verifier pair, or release gate passes.

## Sources and provenance

- [Rules](../rules.md), T001: source emission/tick order, global SHIFT, routing, collision/synchronization/failure precedence, and inclusive tick limit.
- [Scoring](../scoring.md), T002: `(shift_count, completion_ticks, programming_actions)` and final successful program.
- [Identities](../identity-and-versioning.md), T002: canonical puzzle/replay bytes, SHA-256, versions, and trimming actions after success.
- [Limits](../resource-limits.md), T007: bounded input and supported graph/tick limits.
- [Original manual rules cases](rules-cases.json): 13 reviewed traces, copied without calculating movement or terminal outcomes from an engine.
- [Original scoring/identity cases](scoring-cases.json): the previously cross-checked canonical/hash/commitment anchor and tail-normalization example.

The suite envelope records source artifact SHA-256 and the review date. Source provenance uses `source_hash_encoding: sha256:utf8:crlf-to-lf`: hash the UTF-8 file bytes after replacing **CRLF pairs with LF only**. Preserve all other bytes, including lone CR, BOM if present, whitespace, trailing newline and JSON formatting. This makes Windows and LF-only clones agree with the committed `.gitattributes` policy; it is not canonical JSON reserialization. Each case records the original rules-case ID, rule sections relative to `specs/`, and a manual walkthrough note. A formatting helper packaged existing snapshots and independently computed canonical JSON, SHA-256, and the documented score arithmetic; it did not simulate the graph. The `shift_before_move` canonical puzzle/replay also matches the existing T002 identity anchor, previously cross-checked with Python and PowerShell/.NET.

## Coverage

| File | Cases | Purpose |
|---|---:|---|
| [core.json](core.json) | 5 | Basic source/path, exact-limit success, SHIFT before same-tick routing, global switch inversion, simultaneous target synchronization. |
| [edge-cases.json](edge-cases.json) | 9 | Tick-limit failure, partial synchronization, node/head-on/target collision, dead-end no-route, bounded cycle, failure precedence, and unused SHIFT tail normalization. |

The 14 cases contain 38 expected snapshots including tick 0. All 13 original rules cases are retained exactly once; one extra case reuses `shift_before_move`'s tick 0–2 trace with submitted SHIFT `[2,4]`. Success at tick 2 means SHIFT 4 is valid input but never executes. Its normalized successful replay has SHIFT `[2]` and score `[1,2,1]`. The entire submitted list must still be validated before simulation; a tick outside the puzzle limit is not made valid by earlier success.

No rule remains unresolved for these cases. Additional special nodes or changed collision/target behavior require a new rules decision and versioned oracle before new expected results are added.

## Fixture contract

`schema_version: sz-golden-1` identifies this **test corpus envelope**, not a new gameplay/replay schema. Each envelope also names engine/rules/encoding/limits versions, the suite, source provenance, and `cases`.

Each case has:

- `puzzle`, `puzzle_canonical`, `puzzle_hash`: exact domain puzzle, ASCII canonical JSON text, and its SHA-256 identity. Canonical text encodes the complete byte sequence with UTF-8 and no trailing newline. Node/edge arrays are sorted by ASCII ID for this encoding.
- `submitted_replay`, `submitted_replay_canonical`, `submitted_replay_digest`: versioned, sorted, duplicate-free input program and complete canonical bytes/private digest. The digest is test data, not a public active-challenge replay commitment.
- `expected.snapshots`: every state from initial tick 0 through the first terminal tick, with `signals` keyed by source token ID, switch bits, used edge IDs, sorted target-arrival token lists, status and reason. Running reason is the empty string. There is no snapshot after terminal success/failure.
- `expected.terminal`: final tick/status/reason. Failed runs retain their last diagnostic state and have no successful score.
- `expected.normalized_replay`, `expected.normalized_replay_canonical`, `expected.normalized_replay_digest`, `expected.score`: the final trimmed successful replay and `(SHIFT,ticks,actions)` tuple; **all four are `null` for failure**.
- `provenance` and `tags`: source/walkthrough evidence and feature selection for later engine tests. Tags are test metadata and do not affect puzzle identity.

Target arrival multiplicity is preserved: `{"x":["a","b"]}` records both colliding arrivals. It must not be flattened to one token or interpreted as a successful target hit.

## Loading and verification

The SDK-only `packages/puzzle_domain/test/golden_vectors_test.dart` loads both files and uses T009/T010's real puzzle/replay validators. It checks canonical bytes/hashes, input/final replay identity, source provenance, basic trace structure, terminal/score consistency, and the retained T002 commitment anchor. It deliberately does **not** implement movement, select failure reasons, or run a replacement reference engine.

After publishing this task's files, run from the repository root:

```powershell
Push-Location packages/puzzle_domain
dart test test/golden_vectors_test.dart
Pop-Location
```

Execution results belong in `tasks/evidence/T011.md`; the corpus by itself does not establish a test run. T009/T010's public APIs are prerequisites. Test code can locate the repository from either root or package working directory. Browser harnesses should embed/load the same JSON assets later; this host test's file I/O is not a browser asset loader.

T012–T018 must compare the production engine's actual snapshots/terminal/score with these expected values, selecting relevant tags while tasks are implemented. T058/T092 reuse the corpus for verifier/platform equivalence. A fixture-only PASS is not G2.

## Changing an oracle

Review a change against the formal rules one tick at a time, retain the rationale and update source provenance deliberately. Keep the previous version available when rules/encoding semantics change. Never regenerate expected snapshots from the implementation merely to make a failing engine test pass. If an ambiguity is discovered, mark the affected case blocked and resolve the rule first.
