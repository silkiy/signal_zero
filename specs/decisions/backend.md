# T005 — Backend dan operasi lokal

Tanggal: 2026-11-05 (Asia/Jakarta). Status: keputusan implementasi fase fondasi, dipilih agent dalam delegasi pengerjaan Fase 01. Ini bukan persetujuan deployment/biaya dan bukan bukti service sudah berjalan.

## Keputusan

Gunakan **Dart headless + Shelf**, **PostgreSQL 17**, SQL migrations, dan jobs PostgreSQL. `packages/puzzle_domain` adalah dependency source yang sama untuk Flutter dan verifier. Tidak ada port engine ke bahasa lain pada baseline. API, verifier, scheduler, dan indexer terpisah secara modul/proses; pengembangan lokal boleh menggunakan satu supervisor. Gameplay offline tidak bergantung pada semua proses ini.

| Komponen | Baseline | Bukti/kondisi |
|---|---|---|
| Runtime | Dart **3.9.2**, sama dengan Flutter 3.35.6 yang tersedia di workspace | Versi scaffold T003; jangan upgrade SDK diam-diam |
| HTTP | `shelf: 1.4.3` exact | [Version table resmi](https://pub.dev/packages/shelf/versions) menyatakan minimum Dart 3.9 |
| DB driver | `postgres: 3.5.20` exact | [Version table publisher](https://pub.dev/packages/postgres/versions) menyatakan minimum Dart 3.9; dipilih eksplisit, bukan klaim versi terbaru |
| Database | PostgreSQL **17**, current minor saat provisioning dikunci bersama image digest | [Support policy](https://www.postgresql.org/support/versioning/) mencantumkan major 17 masih didukung; tidak ada DB yang diprovision pada Fase 01 |
| Engine | path dependency `../../packages/puzzle_domain` dari service | Pure Dart; tidak boleh mengimpor Flutter, Flame, IO, clock, atau randomness ambient |
| Replay lokal | Direktori private di luar web root; service-account access saja | Metadata/ownership/commitment di DB, bytes dan salt di private store |
| Replay deployment | Interface object store dengan adapter S3-compatible private bucket | Provider/bucket/credential belum dibuat; filesystem adapter tetap cukup untuk local PoC |

Versi dependency pada tabel merupakan target manifest T056; lockfile dan `dart pub get`/tests mengunci graph sebenarnya saat implementasi. Metadata registry tidak menggantikan resolution/build. Jangan menambah library autentikasi/crypto sembarang; EIP-712 cross-check harus memakai Solidity/Foundry vectors.

## Alternatif yang dipertimbangkan

| Alternatif | Kelebihan | Biaya/risiko | Putusan |
|---|---|---|---|
| Dart headless dengan domain bersama | Tidak menggandakan aturan; satu corpus dan source untuk klien/verifier | Native/JS masih perlu parity tests; isolasi resource perlu proses | Dipilih |
| TypeScript API + port engine | Ekosistem EVM luas | Port aturan, versi, normalisasi, dan integer semantics menambah permukaan mismatch | Ditunda sampai ada kebutuhan terukur |
| Rust verifier/FFI/WASM | Kontrol resource dan performa | Toolchain/binding/build platform bertambah sebelum gameplay terbukti | Ditunda |
| SQLite backend | Setup lokal mudah | Koordinasi worker, quota contention, deployment multi-instance lebih terbatas | Tetap untuk data lokal Flutter; tidak dipilih sebagai DB kompetisi |
| Redis/BullMQ/managed queue/serverless | Scaling/operasi vendor tersedia | Service, biaya, credentials, dan failure modes tambahan | Tidak diperlukan pada baseline |

## Topologi dan data

```text
Client -> Shelf API -> DB jobs -> verifier process -> signer adapter
                    -> PostgreSQL             -> private replay store
Scheduler -> publication/finalization jobs
Indexer -> canonical events + cursor -> rank projection -> API
```

- API tidak menjalankan solver/verifier berat di event loop request. Enqueue pekerjaan bounded; worker process menggunakan `packages/puzzle_domain`. Verifier hanya menghitung ulang replay, bukan mencari solusi; solver diperlukan untuk publikasi puzzle.
- Mulai satu verifier process; concurrency maksimum **2**, queued jobs maksimum **8 per worker** dan **16 global**. Cap lebih ketat pada `../resource-limits.md` selalu menang. Queue penuh mengembalikan `503 VERIFY_QUEUE_FULL` dan Retry-After.
- Jobs memiliki `id`, `kind`, `idempotency_key`, `payload_reference`, `status`, `available_at`, `lease_until`, `attempts`. Claim memakai transaksi singkat `FOR UPDATE SKIP LOCKED`, commit lease sebelum proses berat. Lease 30 detik, heartbeat 10 detik, maksimal 3 retry untuk error infrastruktur; invalid replay tidak diulang. Worker mati melepaskan pekerjaan setelah lease berakhir.
- Scheduler polling 30 detik menggunakan UTC server dan unique job key. Register/freeze puzzle hari berikutnya ditargetkan paling lambat 10 menit sebelum start; gagal memenuhi prasyarat berarti **UNAVAILABLE**, tidak mengganti puzzle sesudah start.
- Data minimum: challenges, submissions, private replay references, API nonces, hashed poll capabilities, jobs, canonical chain events/cursors, best-score projection, final snapshots, sponsor reservations/budget, entitlement claims. Wallet disimpan sebagai 20 bytes, digest sebagai 32 bytes, `uint256` sebagai numeric/decimal string yang tidak kehilangan presisi.
- Constraints unique `(wallet, client_request_id)`, `(wallet, challenge_id, normalized_replay_digest)` untuk verified replay record, `(chain_id, tx_hash, log_index, block_hash)`, `(challenge_id, wallet)` untuk best projection, dan `(wallet, utc_day)` sponsor slot. Submission attempts dapat mereferensikan verified replay record yang sama; concurrent normalized duplicates memakai satu salt/commitment durable. Parameterized queries; ranking index dimulai challenge ID lalu score tuple.
- SQL migrations berurutan dengan checksum di `schema_migrations`, satu transaction-level advisory lock, dan migration transactional jika PostgreSQL mengizinkan. Migration gagal tidak boleh mencatat sukses; perubahan destruktif data produksi bukan bagian T056.

[PostgreSQL mendokumentasikan row locking/SKIP LOCKED](https://www.postgresql.org/docs/17/sql-select.html#SQL-FOR-UPDATE-SHARE) untuk konsumen pekerjaan bersamaan. Gunakan row lock untuk quota/budget; [transaction-level advisory locks](https://www.postgresql.org/docs/17/explicit-locking.html#ADVISORY-LOCKS) khusus koordinasi migration/scheduler.

## Private storage dan lifecycle

`ReplayStore.putPrivate/getPrivate/publishFinal/deletePrivate` menerima opaque ID dari server, bukan path/URL dari pengguna. Nama file tidak mengandung wallet, tick, actions, atau salt. Filesystem adapter menolak traversal dan symlink keluar root; penulisan temp+atomic rename. Bucket adapter memakai private ACL, encryption at rest dan service identity terpisah; tidak mengandalkan URL yang sulit ditebak sebagai ACL.

Initial policy untuk dioperasionalkan/diuji pada T085: jangan cleanup challenge active/provisional; non-best private replay dapat dibuang **90 hari setelah FINAL**, best replay+salt dipublikasikan setelah FINAL dan dipertahankan minimal **365 hari**, compact final snapshots/commitments/version metadata dipertahankan untuk audit. Pada kegagalan finalization atau privacy incident, cleanup ditahan. Local dev storage cap 1 GiB, stop menerima replay baru sebelum melebihi cap; tidak menghapus bukti active secara otomatis. Retention bukan backup `.szsave` dan tidak pernah mengandung wallet secrets.

DB insert dan object write menggunakan staged private object + DB transaction + bounded orphan cleanup; tidak ada replay public sebelum snapshot final. Signing tidak dimulai jika private replay/salt belum durable. Backup server disimpan private dan dienkripsi; keputusan RPO/RTO/hosting belum dibuat karena belum ada layanan yang diluncurkan.

## Runbook implementasi yang harus diwujudkan T056/T058

Path executable di bawah **belum ada pada Fase 01**; ini kontrak CLI task berikutnya, bukan command yang diklaim telah lulus:

```powershell
# Dari root; sesudah manifests/entrypoints dibuat T056/T058 dan DB lokal disiapkan.
Push-Location services/api
dart pub get
dart run bin/migrate.dart --up
dart run bin/api.dart --host 127.0.0.1 --port 8080
Pop-Location
```

Untuk worker/scheduler di terminal lain, `Push-Location` ke service yang sesuai lalu `dart run bin/worker.dart --concurrency 1` / `dart run bin/scheduler.dart --once --clock 2026-11-05T00:00:00Z`. Konfigurasi wajib: `DATABASE_URL` melalui environment tanpa echo, `REPLAY_PRIVATE_ROOT`, allowlist origins, `CHAIN_ID=84532`, contract address yang benar, RPC URL, signer adapter, sponsor disabled default. Tidak memakai password contoh sebagai credential deployment.

PoC minimum yang dapat dieksekusi **tanpa service/DB** adalah smoke headless Dart di runbook [verifier-runtime.md](verifier-runtime.md); tujuan T056 adalah health+DB migration+private storage, T058 mengganti stub dengan engine dan golden vectors. [Dart server libraries](https://dart.dev/server/libraries) dan [Shelf publisher API/example](https://pub.dev/packages/shelf) mendukung pilihan primitive runtime ini.

## Kriteria keluar T005

Keputusan runtime/data/storage/jobs dan headless reuse telah ditetapkan. Bukti service hidup, DB connectivity, engine parity, golden CI, real signer dan SDK wallet **belum** ada dan merupakan deliverable task implementasi terkait. T005 selesai sebagai keputusan/runbook, bukan completion T056/T058/G2.
