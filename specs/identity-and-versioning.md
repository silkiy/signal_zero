# Canonical identities and versions — sz-cjson-1

Status: **accepted delegated implementation decision**, 5 November 2026; implements T002/PRD §3.5, §4.2, §10–11. Mechanical semantics are in [rules.md](rules.md). No client/verifier/contract implementation is claimed by this document.

## Version registry

| Field/component | Exact baseline label |
|---|---|
| Puzzle `schema_version` | `sz-puzzle-1` |
| Replay `schema_version` | `sz-replay-1` |
| `engine_version` | `sz-engine-1` |
| `rules_version` including scoring/normalization | `sz-rules-1` |
| Generator provenance `generator_version` | `sz-generator-1` |
| Canonical encoding | `sz-cjson-1` |
| Limits policy | `sz-limits-1` |

Labels are exact case-sensitive ASCII strings. Unknown versions fail `UNSUPPORTED_VERSION` before simulation. Never replace an unknown historical handler with the latest rules. Published puzzles freeze schema/engine/rules versions; a generator descriptor also records the generator version and 64 lowercase hexadecimal seed characters. The descriptor reproduces a candidate without player history. Rejection sampling records the accepted candidate index; recent-history filtering is publication policy, not an implicit random input.

Any change that alters accepted puzzle meaning, normalized action list, per-tick state, score, identity bytes, or replay interpretation requires a new relevant version label and vectors. A performance-only change preserving every observable result may keep engine/rules labels. Build/app semver and source commit are deployment metadata, not replacements for these labels.

## Canonical puzzle input

The gameplay object has exactly `schema_version`, `engine_version`, `rules_version`, `tick_limit`, `nodes`, and `edges`.

- Node object: `id`, `kind`; a switch additionally has required `initial_state` integer 0 or 1. Other node kinds must not include `initial_state`.
- Edge object: `id`, `from`, `to`, `port`; port is 0 or 1 and must satisfy the graph rules.
- Node/edge IDs use `[a-z][a-z0-9_]{0,31}`. `kind` is one of the four rules labels.
- `nodes` and `edges` are sorted by ASCII ID. They may arrive in different orders at a trusted editor boundary, but canonical serialization sorts them after rejecting duplicate IDs. All other arrays retain their specified order.
- Title, tutorial prose, drawing coordinates, nickname, seed, author, provenance and difficulty are outside this gameplay object. They cannot change gameplay/hash. Any future gameplay field requires a new schema/rules decision.

## Encoding and puzzle hash

1. Validate the exact field allowlist, versions, graph references, and resource limits. Reject duplicate JSON object keys, including nested keys. Reject unknown fields rather than silently discard potentially meaningful data.
2. Gameplay numeric values must be nonnegative integer tokens (`0` or `[1-9][0-9]*`), at most `2147483647` before tighter field limits. Reject bool-as-int, negative zero, signs, fractions, exponent syntax, NaN/Infinity, and null. Domain logic has no floating point.
3. Sort object keys by ASCII bytes, recursively; sort node/edge arrays by ID. Strings in the gameplay object are ASCII and contain no control characters, so there is no Unicode normalization, locale collation, escaping, or surrogate ambiguity. A received `\u0061` decodes to `a` and canonicalizes to the literal `a`; a received non-ASCII gameplay string is invalid. Metadata may use Unicode but is excluded from these hashes.
4. Emit UTF-8/ASCII JSON with no BOM, whitespace, insignificant slash escapes, or trailing newline. Use literal double quotes around strings and ordinary decimal digits for integers. A canonical string cannot contain a quote/backslash because all permitted gameplay strings follow the above labels/ID grammar.
5. `puzzle_hash = SHA-256(canonical_puzzle_bytes)`, represented externally as `0x` plus 64 lowercase hex digits. There is no extra hash prefix; `schema_version` inside the payload separates the format.

This is the deliberately constrained `sz-cjson-1` format, **not a claim to implement a general JSON canonicalization standard**. Validate input before using a platform JSON serializer. Array order, float defaults, escaped Unicode and duplicate-key handling must not depend on a serializer's defaults.

## Replay normalization and hashing

A canonical replay has exactly `schema_version` (`sz-replay-1`), `engine_version`, `rules_version`, `puzzle_hash`, and `shift_ticks`.

- At untrusted import/API boundaries, `shift_ticks` must already contain strictly increasing, unique integer ticks from 1 through puzzle `tick_limit`. Reject duplicates or unsorted lists as `NON_CANONICAL_ACTIONS`; do not silently collapse an attacker-supplied command list.
- The editor holds a set of ticks; tapping an occupied tick removes SHIFT. Before export it serializes the sorted set. Different edit/click/undo histories with the same set are equivalent.
- For a submitted program, first validate the **entire submitted action list**, including entries after a possible success; then simulate from the initial state until the first terminal state. If it succeeds on tick `c`, the final normalized successful program removes any SHIFT with tick greater than `c`. Nothing executes after terminal success. This trimming cannot change the earlier success; rerun the trimmed replay when validating content/submission.
- Score, best-score identity, replay stored as the best solution, and public commitment all use this final trimmed program. Extra unused SHIFT entries therefore cannot worsen a valid score or create distinct best replay identities. A failed program can be saved locally unchanged but has no successful score/attestation.
- The private unsalted `replay_digest = SHA-256(canonical_replay_bytes)` can be used for internal deduplication. It **must not** be published while a competitive challenge is active: small SHIFT programs can be brute-forced.

## Salted public replay commitment

For every distinct accepted wallet/challenge/normalized-replay record, the backend generates **32 bytes from a cryptographically secure random source**. Idempotent retries reuse that record/salt. Salt is private with the replay until final reveal. A test salt is fixed only in fixtures.

```text
replay_commitment = SHA-256(
  ASCII("SIGNAL_ZERO_REPLAY_V1") || byte(0) ||
  salt_32_bytes || uint32_big_endian(length(canonical_replay_bytes)) ||
  canonical_replay_bytes
)
```

The length is the number of bytes, not characters; the payload is far below `2^32` due to limits. The 32-byte public digest is encoded as `0x` + 64 lowercase hex. Wallet, challenge ID and final score are additionally bound by the EIP-712 attestation, so a commitment is not a wallet authorization or proof of successful solving. The private DB record binds wallet, challenge, replay, salt, commitment, and verifier result.

Before finalization: publish only commitment and approved score metadata; never salt, unsalted replay digest, action lists, replay body, or publicly readable storage URL. After challenge close **and** final snapshot: reveal normalized replay plus salt; verify this preimage, puzzle hash, versions and score before playing/re-publishing it. A hash is neither encryption nor a substitute for private storage.

## EIP-712 compatibility

`puzzleHash` and `replayCommitment` are opaque `bytes32` carrying SHA-256 outputs. The EIP-712 fields `engineVersionHash` and `rulesVersionHash` are `bytes32` equal to `SHA-256(ASCII(exact_label))`; challenge registration/API retain the exact engine/rules labels and their hash mapping. Human-readable API labels are `engineVersion`/`rulesVersion`, not substitutes for these typed-data hash fields. Scoring is part of rules version, so the baseline adds no independent score-rules field. EIP-712 itself uses its prescribed typed-data hashing; **do not replace its internal hashing with SHA-256**. The contract compares the supplied opaque fields with registered frozen challenge values and verifies the signed domain. T006 owns the full typed-data fields/authorization/window policy.

Vectors in [`test-vectors/scoring-cases.json`](test-vectors/scoring-cases.json) include canonical bytes, puzzle hash, version hashes, normalized replay, test salt and commitment for cross-runtime comparison.
