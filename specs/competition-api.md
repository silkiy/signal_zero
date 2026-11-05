# T006 — Kontrak API kompetisi

Baseline `sz-competition-1`, 2026-11-05. Endpoint di bawah adalah kontrak untuk T056–T086, **belum merupakan service berjalan**. Keputusan domain/score/hash tetap pada [rules.md](rules.md), [scoring.md](scoring.md), [identity-and-versioning.md](identity-and-versioning.md); chain wire pada [attestations.md](attestations.md).

## Format dan validasi

Base path `/v1`, JSON UTF-8 `application/json`, camelCase envelope. Embedded puzzle/replay tetap memakai exact snake_case schema domain agar canonical bytes/hash tidak berubah. Response sukses `{ "data": ..., "meta": {"serverTime":"RFC3339 UTC","protocolVersion":"sz-competition-1","requestId":"opaque"} }`; error `{ "error":{"code":"MACHINE_CODE","message":"safe user text","retryable":false},"meta":... }`.

Input allowlist strict pada signed business body/domain schema; duplicate JSON keys ditolak sebelum canonicalization. Angka score/tick adalah integer; nonce bertipe **uint256** memakai decimal string, sedangkan **ApiAuthorization.nonce bytes32** memakai lower-case hex32. Tidak menerima NaN/Infinity/fractional tick. Hex dan version labels persis [attestations.md](attestations.md). Initial maximum total submission JSON **128 KiB**, replay **16 KiB**, puzzle **64 KiB**, depth **16**; semua limit T007 diterapkan sebelum enqueue/parse mahal. Tidak menerima compressed HTTP request body pada baseline; file import di klien memiliki pipeline terpisah.

TLS wajib di luar loopback. Semua private response `Cache-Control: no-store`, `Referrer-Policy: no-referrer`; CORS exact allowlist game origins/config T004, tanpa wildcard credentials. Tidak membutuhkan third-party cookies atau localStorage auth pada iframe itch.io. `Authorization`, signature/body, capability, salt, replay bytes, serta action-bearing error tidak masuk logs/metrics/traces. Public APIs tidak mengembalikan private object key/signed URL/seed challenge mendatang.

## Endpoint registry

| Route | Akses/input | Response dan status utama | Pemilik |
|---|---|---|---|
| `GET /v1/config` | Public | 200 protocol/version labels, chainId, deployed contract addresses, wallet/sponsor availability; tidak ada secrets | T056/T068 |
| `GET /v1/challenges/today` | Public, tanggal dari server UTC | 200 Challenge; 503 `CHALLENGE_UNAVAILABLE` bila prerequisite freeze/publication belum aman | T057/T061 |
| `GET /v1/challenges/{id}` | Public, id tanggal UTC | 200 Challenge sesudah start; 404 sebelum publikasi/start atau unknown; archive readonly | T061 |
| `GET /v1/challenges/{id}/leaderboard?limit=25&cursor=...` | Public | 200 RankPage, source/version/provisional flags | T062/T072 |
| `GET /v1/challenges/{id}/replays/{wallet}` | Public setelah FINAL saja | 200 Reveal; 404 yang sama untuk missing/not-revealed, tanpa petunjuk private storage | T064 |
| `GET /v1/weeks/{mondayDate}/leaderboard?limit=25&cursor=...` | Public | 200 WeeklyRankPage; Monday UTC validated | T079/T080 |
| `POST /v1/auth/nonces` | Public, rate-limited NonceRequest | 201 nonce + exact ApiAuthorization typed data + expiresAt | T059 |
| `POST /v1/submissions` | Signed ApiAuthorization + SubmissionBody | 202 SubmissionAccepted baru + one-record RAM capability; 200 SubmissionReference untuk duplicate dengan fresh valid authorization | T059/T060 |
| `GET /v1/submissions/{id}` | `Authorization: Bearer <pollCapability>` | 200 private status/own attestation only, never replay bytes | T059/T060 |
| `POST /v1/submissions/access` | Fresh ApiAuthorization + `{wallet,submissionRequestId}` | 200 rotates capability for own matching original submission request, or indistinguishable 404 | T059 |
| `DELETE /v1/submissions/{id}/access` | Poll capability | Idempotent 204; matching capability revoked, no deletion of competitive evidence and no record-existence oracle | T059 |
| `POST /v1/sponsorships` | Own poll capability + SponsorBody + wallet SubmitAuthorization signature | 202 sponsor reservation/status; 409 ineligible; 503 disabled/cap/provider | T070 |
| `POST /v1/achievement-claims` | ApiAuthorization + `{wallet,achievementId,clientRequestId}` | 200 eligibility + final evidence/snapshot IDs + optional claim attestation, or 409 `NOT_FINAL`/`NOT_ELIGIBLE` | T081/T083 |

Tidak ada player-facing register/freeze/signer-rotation endpoint. Admin menjalankan transaksi registry/signature ops dengan operator permissions terpisah; jangan memberi session pemain hak tersebut.

## Data contracts

`Challenge`:

```text
id YYYYMMDD; startAt/endExclusive RFC3339 UTC; state enum;
puzzleSpec exact domain object; puzzleHash bytes32;
engineVersion/rulesVersion exact strings; engineVersionHash/rulesVersionHash bytes32;
registration {chainId, contract, txHash, blockNumber, blockHash, isFinalized};
snapshot null | {snapshotId, snapshotHash, version, finalizedThroughBlock, finalizedAt};
canSubmit bool; canUseHints=false for ranked Daily; isArchive bool.
```

Response sebelum start tidak memuat puzzleSpec/seed; public today/archives hanya sesudah start. Bila cached offline, klien menandai timestamp/cache dan tidak menyimpulkan active/rank state dari device clock.

`NonceRequest`: `{wallet, chainId, method, path, bodyHash}`; method/path harus salah satu signed route allowlist. Server menambahkan configured audience, target deployed contract, nonce32, expiry. `bodyHash` canonical business body hash; nonce tidak mengesahkan ownership sampai signature diterima.

Signed private envelope:

```json
{
  "body": {
    "wallet": "0x...20-byte-address...",
    "clientRequestId": "UUIDv4",
    "challengeId": 20261105,
    "replay": {"schema_version":"sz-replay-1","engine_version":"sz-engine-1","rules_version":"sz-rules-1","puzzle_hash":"0x...32-byte-hash...","shift_ticks":[1,4]}
  },
  "authorization": {"wallet":"...","audienceHash":"...","methodHash":"...","pathHash":"...","bodyHash":"...","nonce":"...","expiresAt":0},
  "signature": "0x...65-byte-canonical-signature..."
}
```

Ini contoh **shape**, nilai hash/expiry placeholder bukan vector valid. `bodyHash` dihitung dari object `body` seluruhnya, termasuk wallet/challenge/clientRequestId dan replay, tanpa authorization/signature. API tidak menerima score authoritative dari client. Backend menormalisasi replay menurut rules setelah memverifikasi body dan mensimulasikan sukses; commitment dibuat dari **normalized** canonical replay + fresh server salt, bukan dari raw submission JSON. Signature HTTP dan unsalted bodyHash tidak boleh disalin ke calldata/event/public responses.

`SubmissionAccepted`: `{id, wallet, challengeId, status:"QUEUED", pollCapability, capabilityExpiresAt}`. ID opaque UUID/128-bit; capability CSPRNG 256-bit base64url dikirim hanya dalam response dan header berikutnya, bukan URL/query. DB menyimpan hash capability dan binding submission+wallet, bukan raw token. TTL **15 menit**; tidak membuka replay raw atau menerima arbitrary replay baru. Capability disimpan RAM saja dan dibuang pada account/chain change, disconnect, logout, app close. Klien bisa revoke; kehilangan response/expiry memerlukan fresh signed `/submissions/access` dengan original UUID pada `submissionRequestId`, yang merotasi capability. Tidak ada long-lived session, cookie, persistent token, atau wallet secret.

Submission private state enum: `QUEUED`, `VERIFYING`, `REJECTED`, `VERIFIED`, `ATTESTED`, `TX_PENDING`, `ONCHAIN_PROVISIONAL`, `ONCHAIN_FINAL`, `EXPIRED`, `INFRA_ERROR`. Status response memuat wallet/challenge, computed score/commitment bila verified, safe failure code, attestation+signature bila available, txHash bila diketahui, status poll delay. **Attestation tanpa event tidak pernah official score.** `GET` membutuhkan capability sesuai record; token salah/ID salah sama-sama 404.

Duplicate request dengan **fresh** valid API nonce dan matching business key/body mengembalikan 200 `SubmissionReference: {id,wallet,challengeId,status,requiresAccessRecovery:true}`; tidak menerbitkan capability baru atau enqueue job kedua. Klien memakai capability RAM yang masih valid atau signed `/submissions/access`. Signature dengan nonce lama tetap 409 NONCE_USED.

Concurrent atau repeated submissions yang setelah normalisasi memiliki `(wallet,challengeId,normalizedReplayDigest)` identik mereferensikan verified replay record/salt/commitment yang sama. `clientRequestId` melindungi request acceptance; normalized identity melindungi isi replay. Digest tanpa salt tetap private.

Renewal saat score attestation expired atau signerEpoch berubah: selama challenge masih ACTIVE, client mengirim `POST /v1/submissions` dengan **fresh clientRequestId dan fresh ApiAuthorization** untuk replay yang sama. Submission attempt baru boleh memakai immutable verified replay record/salt/commitment yang sama, tetapi menerbitkan attestation **nonce/expiry/currentEpoch baru** sesudah memeriksa ulang challenge/window/version dan durable record. Business key lama tetap merujuk hasil lama (idempotent); GET tidak menerbitkan ulang signature. Sesudah close, renewal ditolak dan tidak membuat late-submit grace.

`SponsorBody`: `{submissionId, attestationDigest, submitAuthorization, walletSignature, clientRequestId}`; server mengambil stored attestation/replay dari record, tidak mempercayai arbitrary target/calldata di payload. Recovery status memakai submission capability; tx nonce/receipt dikelola relayer, tidak ditulis oleh client.

`Reveal`: `{challengeId,wallet,puzzleHash,engineVersion,rulesVersion,normalizedReplay,salt,replayCommitment,score,snapshotId,snapshotHash}`. Client memverifikasi semua identity/digest dan menjalankan engine versi yang cocok. Public replay hanya best per wallet yang terdapat snapshot final; invalid commitment tidak diterbitkan.

`RankPage`: `{challengeId,source:"CANONICAL_CHAIN",state:"PROVISIONAL"|"FINAL",projectionVersion,snapshotId,entries:[{wallet,score:{shiftCount,completionTicks,programmingActions},rank}],nextCursor}`. Rank = 1 + jumlah wallet dengan tuple strictly better; tie sama rank `1,1,3`. Iterasi tampilan deterministik tie memakai wallet ascending, **bukan** rank tie-breaker. Cursor opaque mengikat filter/projectionVersion/last tuple+wallet, `limit` default25 max100. Projection berubah saat paging -> 409 `PAGINATION_CHANGED`, klien refresh dari halaman pertama. Ranking tidak dihitung ulang hanya dari isi halaman.

`WeeklyRankPage` sama dengan `{weekId,mondayDate,closesAt,state,snapshotId,entries:[{wallet,totalPoints,rank,daily:[{challengeId,finalRank,points,snapshotId}]}],nextCursor}`. Poin hanya dari FINAL Daily; total lebih besar lebih baik; ties weekly berbagi competition rank tanpa timestamp. Unknown/missing daily ditandai, bukan dibuat verified score.

## Lifecycle UTC dan official cutoff

```text
DRAFT -> REGISTERED_FROZEN -> ACTIVE -> CLOSED_PROVISIONAL -> FINAL -> REVEALED
                    \-> UNAVAILABLE/CANCELLED (tanpa mengganti puzzle aktif)
```

- UTC day adalah interval half-open `[00:00:00, next day 00:00:00)`. Challenge ID berasal tanggal UTC start; example PRD `20261105`. Device timezone tidak menentukan period/rank.
- Scheduler memvalidasi solusi dan membekukan DB hash/spec/version; owner mendaftarkan hash/window/version ke kontrak sebelum start. Metadata registration saja public; spec dan generator seed untuk hari mendatang tetap private. Daily seed memakai CSPRNG256bit, bukan tanggal UTC saja; hash publik tidak dianggap enkripsi, sehingga small/predictable candidate catalogs tidak boleh dipakai untuk menjanjikan secrecy puzzle sebelum start.
- ACTIVE hanya sesudah frozen registration final dan server UTC mencapai start. Attempts gameplay tidak dibatasi dan hint disabled. Auth/rate limit hanya transport submission.
- API menerima replay hanya sebelum endExclusive, tetapi **waktu inklusi transaksi menurut `block.timestamp`** adalah batas resmi. Request/signature/broadcast sebelum deadline tidak menjamin inclusion; kontrak menolak block timestamp di/diatas endExclusive. Tidak ada grace/backdating berdasarkan `receivedAt` API.
- Saat UTC close, UI closed/provisional; finalizer menunggu RPC `finalized` block dengan timestamp **>= endExclusive**, indexer canonical lengkap sampai block tersebut, dan seluruh log sebelum cutoff diproyeksikan. Jangan mengganti ini dengan sleep tetap/jumlah konfirmasi saja.
- Snapshot final atomik memuat best score per wallet dan shared rank + canonical cutoff block hash/number; semua consumer weekly/reveal/eligibility merujuk snapshot yang sama. Finalization/reveal jobs idempotent dengan snapshot ID/version.
- Sebelum FINAL, bahkan sesudah UTC close, replay orang lain tetap private. Sesudah FINAL worker reveal memeriksa commitment lalu publikasi; publication failure berarti FINAL belum REVEALED dan bisa retry tanpa mengubah rank.
- Archive dapat dimainkan offline dari cached spec/historical engine tanpa mengirim ranking resmi baru.

[Base JSON-RPC block tags](https://docs.base.org/base-chain/api-reference/ethereum-json-rpc-api/eth_getBlockByNumber) mendukung `latest/safe/finalized`; baseline memakai `finalized`. [Base derivation specification](https://docs.base.org/base-chain/specs/protocol/consensus/derivation) menjelaskan hubungan L1 finality dan derived L2 chain; tidak memakai withdrawal waiting period sebagai timer Daily.

## Idempotency, concurrency, dan error

`clientRequestId` UUID dan unique `(wallet,route,clientRequestId)` berlaku pada **submission, sponsorship, dan achievement-attestation issuance**. Nonce consumption+DB acceptance satu transaksi; sponsor memakai wallet SubmitAuthorization sebagai proof dan reservation rules terpisah. Exact signed API retry dengan nonce sudah consumed mengembalikan **409 NONCE_USED**, tidak membuat pekerjaan kedua. Fresh API nonce dengan business key+body sama mereferensikan record yang sama; jika submission capability response awal hilang, gunakan fresh signed `/submissions/access` dengan `submissionRequestId` sama. Server tidak mengembalikan raw capability lama yang DB hanya simpan hash. Business key sama tetapi body berbeda -> 409 `IDEMPOTENCY_CONFLICT`. Achievement request key sama mengembalikan attestation yang sama selagi epoch/expiry masih valid; setelah tidak valid perlu request key/otorisasi baru, bukan menghidupkan signature lama.

Pengecualian eksplisit: `/auth/nonces` selalu menerbitkan fresh bounded nonce dan tidak memerlukan client key; `/submissions/access` adalah recovery berotorisasi baru yang sengaja **merotasi** capability dan tidak membuat replay/job baru; DELETE access idempotent secara efek/204 tanpa client key. GET tidak memiliki side effect. DELETE dengan token invalid/already-revoked tetap 204 tanpa melakukan apa pun agar tidak membocorkan keberadaan record.

Sponsor transaction/slot/budget concurrency mengikuti [wallet-gas.md](decisions/wallet-gas.md). Indexer cursor menyimpan number+hash+parent, log uniqueness, backfill overlap; common ancestor rollback menghapus projection orphaned lalu replay canonical. Provisional API boleh berubah dan menampilkan versi; official final snapshot tidak ditulis ulang diam-diam. Baseline memerlukan satu explicitly trusted RPC yang mendukung finalized tag; bila secondary dikonfigurasi, finalized ancestor/hash harus konsisten. Bila reorg menyentuh finalized anchor atau dua trusted RPC tidak sepakat, **halt finalization/claims/reveal**, flag `FINALITY_INCIDENT`, simpan evidence dan operator review. Replay yang sudah published tidak bisa dianggap private kembali; koreksi membutuhkan explicit superseding snapshot/audit event, bukan erase history.

| HTTP | Codes baseline | Perilaku |
|---|---|---|
| 400 | `INVALID_JSON`, `DUPLICATE_KEY`, `INVALID_FIELD` | Safe field path saja, tanpa echo replay |
| 401 | `AUTH_REQUIRED`, `INVALID_SIGNATURE`, `AUTH_EXPIRED` | Tidak menandatangani/menjalankan verifier |
| 403 | `WALLET_MISMATCH`, `WRONG_CHAIN`, `WRONG_CONTRACT` | Tidak mengganti owner dari wallet string |
| 404 | `NOT_FOUND` | Unknown/private/not-revealed sama untuk endpoint replay/capability |
| 409 | `NONCE_USED`, `IDEMPOTENCY_CONFLICT`, `CHALLENGE_CLOSED`, `NOT_FINAL`, `PAGINATION_CHANGED`, `SPONSOR_INELIGIBLE`, `NOT_ELIGIBLE` | Refresh/re-authorize/user-paid sesuai code; tidak retry side effect otomatis |
| 413 | `PAYLOAD_TOO_LARGE` | Reject sebelum parse/queue mahal |
| 422 | `UNSUPPORTED_VERSION`, `REPLAY_FAILED`, `RESOURCE_LIMIT` | Replay/rules invalid, bukan skor verified |
| 429 | `RATE_LIMITED` | Retry-After; gameplay lokal tetap tersedia |
| 503 | `VERIFY_QUEUE_FULL`, `VERIFIER_UNAVAILABLE`, `SIGNER_UNAVAILABLE`, `RPC_UNAVAILABLE`, `SPONSOR_DISABLED`, `BUDGET_EXHAUSTED`, `CHALLENGE_UNAVAILABLE`, `FINALITY_INCIDENT` | Retryable bila sesuai; tidak finality fallback/false success |
| 500 | `INTERNAL_ERROR` | requestId untuk diagnosis, tanpa stack/payload/secrets |

## Walkthrough kontrak

1. **Guest:** GET today -> hash yang sama -> main offline; tidak ada nonce/wallet call sampai pemain memilih submit.
2. **Wallet palsu:** attacker mengirim wallet korban, tetapi ApiAuthorization recovered signer berbeda -> 401/403, tidak ada attestation.
3. **Valid submission:** fresh nonce -> EIP712 HTTP proof -> 202/capability -> verifier -> salted commitment/attestation -> wallet direct tx atau wallet authorized sponsor -> indexer provisional -> finalized snapshot -> reveal/weekly.
4. **Expired/wrong domain:** API expiry/domain gagal sebelum queue; on-chain score expiry/domain/epoch gagal sebelum state update. Client memperoleh attestation baru hanya jika masih ACTIVE.
5. **Sponsor gagal:** slot pending/reservation dipertahankan sampai receipt pasti; user-paid tetap pilihan dengan konfirmasi wallet, tanpa double broadcast otomatis.
6. **Leak attempt:** public replay GET/storage ID guessing/cache/log inspection sebelum FINAL tidak mengembalikan actions/salt/unsalted replay hash; public commitment salted.
7. **Reorg:** orphaned provisional score ditarik, cursor ulang dari ancestor; finality belum pasti menahan reveal/weekly/claims. Finalized-anchor anomaly masuk incident state.

Walkthrough ini design verification; implementasi/attack tests dan decoded calldata evidence baru T066/T073/T077.
