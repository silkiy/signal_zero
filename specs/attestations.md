# T006 — Wire EIP-712 dan validasi on-chain

Protocol version: `sz-competition-1`, dipilih 2026-11-05. Belum ada kontrak/signature live. Spesifikasi [EIP-712](https://eips.ethereum.org/EIPS/eip-712) menyediakan typed hashing/domain separation; replay protection, roles dan finalization di bawah adalah keputusan proyek.

## Encoding bersama

JSON API menggunakan camelCase, integer kecil sebagai JSON integer, semua `uint256` sebagai decimal string tanpa leading zero, address lower-case `0x`+40 hex, `bytes32` lower-case `0x`+64 hex. Solidity ABI types di bawah adalah authoritative; tidak memakai float. Signature ECDSA canonical low-s 65 bytes (`r,s,v`, v 27/28; normalisasi wallet 0/1 hanya pada boundary), recovered signer nonzero.

Puzzle hash/replay commitment adalah **SHA-256 opaque bytes32** dari [identity-and-versioning.md](identity-and-versioning.md). `engineVersionHash = SHA256(ASCII('sz-engine-1'))`, `rulesVersionHash = SHA256(ASCII('sz-rules-1'))`; exact labels dipublikasikan bersama metadata. Keccak EIP-712 internal tidak mengubah algoritma hash puzzle. Commitment publik:

```text
SHA256(ASCII("SIGNAL_ZERO_REPLAY_V1") || byte(0) || salt32 || uint32_be(replayBytes.length) || replayBytes)
```

`salt32` baru dibuat backend CSPRNG untuk accepted normalized replay dan disimpan privat durable bersama bytes. Replay asli, hash replay tanpa salt, salt, API request signature/body hash tidak dipublikasikan pada active/provisional challenge. Reveal mengungkap canonical replay dan salt setelah FINAL sehingga commitment dapat dihitung ulang.

## Domain

| Penggunaan | name | version | chainId | verifyingContract |
|---|---|---|---|---|
| Verifier score dan wallet submit authorization | `SIGNAL ZERO Leaderboard` | `1` | 84532 baseline | deployed leaderboard |
| Private API ownership proof | `SIGNAL ZERO API` | `1` | 84532 baseline | deployed leaderboard |
| Achievement | `SIGNAL ZERO Achievements` | `1` | 84532 baseline | separate deployed registry |

Semua domain menyertakan field ordered `name,string`; `version,string`; `chainId,uint256`; `verifyingContract,address`. Contract zero/mismatch atau chain mismatch ditolak. Wire adalah `eth_signTypedData_v4` dengan `primaryType` yang tepat; implementasi hashing merujuk EIP-712/OpenZeppelin, bukan `abi.encodePacked` bebas.

## ScoreAttestation

Primary type dan urutan field persis:

```solidity
ScoreAttestation(address wallet,uint32 challengeId,bytes32 puzzleHash,bytes32 engineVersionHash,bytes32 rulesVersionHash,uint32 shiftCount,uint32 completionTicks,uint32 programmingActions,bytes32 replayCommitment,uint256 nonce,uint64 expiresAt,uint32 signerEpoch)
```

- `challengeId` adalah angka tanggal UTC `YYYYMMDD`; scope tanggal/window diverifikasi terhadap registry immutable.
- Score berasal verifier; seluruh komponen uint32 dengan batas T007, completionTicks>=1. `programmingActions=shiftCount` pada rules baseline tetap disimpan sebagai komponen ketiga sesuai PRD.
- Nonce CSPRNG uint256 unik per wallet/challenge; kontrak mencatat `usedAttestationNonce[wallet][challengeId][nonce]` sesudah validasi dan sebelum state update/event.
- `expiresAt = min(serverNow + 300 detik, endExclusive - 1 detik)`; backend tidak menerbitkan saat sudah tutup. Kontrak mensyaratkan `block.timestamp <= expiresAt` dan `startAt <= block.timestamp < endExclusive`.
- `signerEpoch` harus sama current epoch. Signer resmi tidak memiliki hak melakukan register/mutate challenge atau memindahkan funds; hanya mengesahkan hasil.
- Kontrak mencocokkan hash/version/window registry dan **strictly smaller lexicographic tuple**. Score sama/buruk revert tanpa mengganti best/nonce; nonce belum dipakai tidak dapat memperburuk state di retry.
- `ScoreAccepted` event berisi wallet, challenge ID, tuple, commitment, nonce, signerEpoch; **tanpa action list/salt**. Metadata signer/nonce/score publik adalah informasi yang memang diperlukan validasi, bukan replay.

## SubmitAuthorization untuk relayer

```solidity
SubmitAuthorization(address wallet,bytes32 attestationDigest,address executor,uint256 nonce,uint64 expiresAt)
```

`attestationDigest` adalah full EIP-712 digest ScoreAttestation (bukan hanya structHash). Domain sama leaderboard, `wallet` cocok attestation, `executor` nonzero dan sama `msg.sender`, signature recovered dari wallet, wallet authorization nonce belum dipakai, dan expiry tidak melampaui score expiry. `usedSubmitNonce[wallet][nonce]` contract-scoped. Direct route hanya `msg.sender==wallet` tanpa authorization ekstra; relayed route memerlukan kedua signature. Menyalin calldata hanya dapat menghasilkan score yang sama untuk wallet yang sudah terikat; executor binding mencegah memakai jatah relayer lain.

Contract entrypoints rencana:

```text
submitScore(ScoreAttestation, bytes verifierSignature)
submitScoreFor(ScoreAttestation, bytes verifierSignature, SubmitAuthorization, bytes walletSignature)
```

Tidak ada route menerima replay/actions, arbitrary target, arbitrary calldata, token approval atau ETH value dari pemain.

## ApiAuthorization: HTTP ownership tanpa session cookie

```solidity
ApiAuthorization(address wallet,bytes32 audienceHash,bytes32 methodHash,bytes32 pathHash,bytes32 bodyHash,bytes32 nonce,uint64 expiresAt)
```

Domain API pada tabel. `audienceHash=SHA256(UTF8(configuredApiOrigin))` dengan exact HTTPS origin tanpa trailing slash; local probe `http://127.0.0.1:8080` hanya mode dev. `methodHash=SHA256(ASCII(uppercaseMethod))`, `pathHash=SHA256(ASCII(exactPath))`; private routes tidak memakai query params. `bodyHash=SHA256(canonical sz-cjson-1 bytes dari business body)` **tanpa** envelope authorization/signature. Body tetap privat; ini bukan public replay commitment. `nonce` server CSPRNG 32 bytes terikat wallet/method/path/bodyHash/audience/chain/contract, expiresAt serverNow+300 detik. Backend memverifikasi exact tuple dan consuming nonce secara atomik bersamaan penerimaan request; expiry harus sama persis record nonce, `serverNow > expiresAt` atau nonce reuse ditolak. Tidak ada client-issued timestamp yang bisa memperpanjang TTL.

Nonce request bukan ownership proof. API nonce yang diperoleh attacker tidak dapat digunakan tanpa signature wallet. Private request signing hanya atas user intent; tidak otomatis sign saat membuka Daily. Tidak ada long-lived login session atau third-party cookies; poll capability terbatas dijelaskan di [competition-api.md](competition-api.md).

## Challenge registry, admin, dan signer rotation

`registerChallenge(uint32 challengeId,bytes32 puzzleHash,bytes32 engineVersionHash,bytes32 rulesVersionHash,uint64 startAt,uint64 endExclusive)` owner-only; exact challenge ID/tanggal diuji publisher, `startAt % 86400 == 0`, `endExclusive == startAt + 86400`, hashes nonzero, unused ID, `block.timestamp < startAt`. Registration langsung membekukan record; tidak ada mutation/re-registration endpoint. Registration event boleh public lebih awal, puzzle specification/seed tetap private sampai start.

Publish puzzle hanya jika registration sudah canonical/finalized sebelum start dan verifier support tersedia. Gagal berarti challenge UNAVAILABLE, tidak diam-diam memilih puzzle pengganti. Challenge yang perlu dibatalkan sebelum start diberi cancelled flag immutable; admin tidak mengganti hash/window. Pause darurat menghentikan submission baru, tidak mengubah best score atau memperpanjang deadline.

Baseline non-upgradeable contracts. Owner menggunakan mekanisme two-step transfer; local/Sepolia test owner disposable, deployment publik owner diarahkan ke multisig 2-of-3 yang harus disiapkan terpisah. Jangan mengklaim multisig sudah ada. `setSigner(newSigner)` menaikkan epoch; epoch lama invalid segera. Rotasi rutin dijadwalkan setelah challenge window; emergency pause→rotate→audit→unpause dicatat. Outstanding attestation lama harus diterbitkan ulang sebelum deadline; tidak ada late-submit grace tersembunyi. `renounceOwnership` ditutup pada baseline agar operasi freeze/rotation tidak terkunci tanpa rencana.

Indexer hanya mengamati chain/config yang diizinkan. Off-chain admin API tidak public; operasi register/pause/rotate memerlukan deployment/operator signing, tidak memakai session wallet pemain. Primitive yang akan digunakan T067: [OpenZeppelin EIP712/ECDSA](https://docs.openzeppelin.com/contracts/5.x/api/utils/cryptography) dan [Ownable2Step](https://docs.openzeppelin.com/contracts/5.x/api/access#Ownable2Step); versi Solidity/OZ exact dan lockfile dipilih/diuji pada T067, bukan diklaim terinstal sekarang.

## AchievementAttestation dan bukti final

Registry terpisah memakai:

```solidity
AchievementAttestation(address wallet,uint8 achievementId,bytes32 evidenceHash,bytes32 finalitySetHash,uint64 notBefore,uint256 nonce,uint64 expiresAt,uint32 signerEpoch)
```

IDs 1 Daily Champion, 2 Consistent Mind, 3 Top Strategist, 4 Signal Master. Claim `msg.sender==wallet`; sponsorship achievement tidak diwajibkan baseline. Duplicate claim key `(wallet,achievementId)`; nonce/signature/domain replay dicegah terpisah dari leaderboard. `notBefore` = max close time sumber; expiry klaim maksimum 7 hari dari penerbitan (dapat diterbitkan ulang sesudah expiry selama eligible). `evidenceHash` SHA256 canonical evidence document versi `sz-achievement-evidence-1`, termasuk wallet, criterion, dan source snapshot IDs.

Sebelum claim, owner registry menerbitkan final snapshot record `{kind DAILY/WEEKLY, periodId, closesAt, snapshotHash}` hanya setelah backend memastikan FINAL; contract menolak publish sebelum closesAt dan overwrite period. Snapshot ID = `keccak256(abi.encode(uint8 kind,uint32 periodId,bytes32 snapshotHash))`; weekly periodId adalah tanggal Senin UTC `YYYYMMDD`. Klaim membawa sorted unique `bytes32[] snapshotIds` maksimal 10, seluruhnya harus registered final; `finalitySetHash=keccak256(abi.encode(snapshotIds))` cocok signature. Daily Champion memakai 1 daily snapshot, Consistent Mind 7 daily, Top Strategist 1 weekly, Signal Master 10 daily. Signer tetap dipercaya menentukan eligibility; kontrak tidak menghitung ranking/tujuhhari/sepuluhwins dengan iterasi semua pemain.

Kontrak memastikan sumber final sudah didaftarkan dan `block.timestamp >= notBefore`, tidak hanya mempercayai flag boolean dari client. Finality chain/indexer dan ranking correctness tetap trust assumption publisher/signature; registrasi final snapshot sendiri menunggu finality sebelum claim UI aktif. Tidak membuat NFT/token.

## Vectors wajib T060/T067/T081/T082

Untuk masing-masing primary type: satu accepted baseline, mutasi tiap field/domain, wrong signer/wallet/executor, high-s/invalid signature, reused nonce, epoch lama, expiry boundary, serta digest parity Dart↔Solidity. Score replays tidak ada dalam calldata. Nilai byte/hash nyata akan diturunkan dari fixtures, bukan angka dummy yang disebut verified pada Fase 01.
