# Fase 06 — Daily Challenge, verifier, dan privasi replay

Semua file di bawah adalah output yang direncanakan, belum merupakan implementasi. Runtime backend, API, autentikasi, EIP-712, dan kebijakan finalitas mengikuti keputusan T005/T006. Path tanpa ekstensi menunjukkan satu modul/file yang ekstensi akhirnya mengikuti runtime terpilih. T085 menetapkan kebijakan replay lebih dahulu meskipun ID-nya berada pada fase berikutnya.

<a id="t056"></a>

## T056 — Bootstrap backend dan penyimpanan kompetisi

**Prioritas:** P1 | **Ukuran:** M | **PRD:** §10–11, FR-012, FR-013
**Dependensi:** T003, T005, T006
**Tujuan:** Menyediakan service API yang dapat dijalankan lokal dengan database kompetisi minimal.
**Output rencana (≤5 file):** `services/api/app`, `services/api/config`, `services/api/db/migrations/001_competition`, `services/api/tests/bootstrap_test`.
**Kriteria selesai:**
- [ ] Service berjalan dengan konfigurasi tervalidasi dan health check tanpa membocorkan secrets.
- [ ] Migrasi membuat challenge, verified submission, dan replay reference dengan identitas serta uniqueness yang disepakati T006.
- [ ] Setup ulang database kosong dan restart service mempertahankan data secara benar.
**Verifikasi:** Jalankan migrasi pada DB sementara, buat satu fixture challenge/submission, restart service, lalu baca fixture dan health check; catat command sesuai runtime T005.

<a id="t057"></a>

## T057 — Publikasi puzzle Daily dan scheduler UTC

**Prioritas:** P1 | **Ukuran:** M | **PRD:** §4.2, §5, FR-012
**Dependensi:** T009, T017, T039, T056
**Tujuan:** Menerbitkan satu puzzle tervalidasi solver untuk setiap tanggal UTC dan membekukannya sebelum challenge dimulai.
**Output rencana (≤5 file):** `services/scheduler/daily_publication`, `services/scheduler/daily_clock`, `services/api/db/migrations/002_publication`, `services/scheduler/tests/daily_publication_test`.
**Kriteria selesai:**
- [ ] Challenge ID `YYYYMMDD`, start/end, puzzle spec/hash, engine/rules version, dan hasil validasi tersimpan sebelum start; generator gagal tidak menerbitkan puzzle tidak valid.
- [ ] Menjalankan job dua kali untuk tanggal sama tidak mengganti puzzle atau membuat duplikasi; puzzle aktif tidak dapat dimutasi.
- [ ] Semua request pada satu tanggal UTC memperoleh puzzle/hash identik, termasuk klien dari zona waktu berbeda.
**Verifikasi:** Dengan fake clock, uji 23:59:59→00:00:00 UTC, dua job bersamaan, generator timeout, dan percobaan mengubah puzzle yang sudah dibekukan.

<a id="t058"></a>

## T058 — Verifier backend identik dengan engine klien

**Prioritas:** P1 | **Ukuran:** M | **PRD:** §3.3–3.5, §10–11, FR-001, FR-005, FR-013; G2
**Dependensi:** T005, T010, T011, T016, T018, T019, T056
**Tujuan:** Menjalankan ulang replay dengan versi engine/rules milik challenge dan menghitung hasil sendiri.
**Output rencana (≤5 file):** `services/verifier/runner`, `services/verifier/version_registry`, `services/verifier/tests/golden_equivalence_test`, `specs/test-vectors/verifier-report.md`.
**Kriteria selesai:**
- [ ] Semua golden vectors menghasilkan state per tick, status terminal, commitment, dan score tuple identik dengan engine klien; tidak memakai skor kiriman klien sebagai kebenaran.
- [ ] Replay gagal, versi tidak didukung, tick/action di luar batas, dan waktu/resource budget habis ditolak secara eksplisit.
- [ ] Bukti G2 memuat platform/runtime/version yang diuji; dukungan replay historis memakai handler versi yang sesuai tanpa reinterpretasi diam-diam.
**Verifikasi:** Jalankan corpus sama di klien dan verifier, bandingkan seluruh snapshot/hash/score; mutasikan satu aksi, score, dan versi untuk membuktikan mismatch terdeteksi.

### Checkpoint CP-06A — Daily immutable dan G2 terbukti

- [ ] T056–T058 menghasilkan challenge UTC immutable dan golden state/score client/verifier yang identik.
- [ ] Evidence mencatat command/scenario, versi, hasil dan blocker; tidak ada kelulusan berdasarkan rencana saja.

<a id="t059"></a>

## T059 — Intake replay privat dengan autentikasi wallet

**Prioritas:** P1 | **Ukuran:** M | **PRD:** §5.2, §11, FR-013, FR-014, FR-016
**Dependensi:** T006, T007, T056, T057, T058, T085
**Tujuan:** Menerima replay kompetitif ke backend tanpa membuka solusi kepada pemain lain.
**Output rencana (≤5 file):** `services/api/submissions/route`, `services/api/auth/wallet_session`, `services/api/replays/private_store`, `services/api/tests/submission_intake_test`.
**Kriteria selesai:**
- [ ] Identitas wallet dibuktikan lewat otorisasi kriptografis terikat challenge/session sesuai T006; wallet string saja tidak cukup.
- [ ] Payload divalidasi, dibatasi ukuran/kompleksitas, dan diverifikasi sebelum status verified; request idempotent tidak menggandakan submission.
- [ ] Replay disimpan privat sesuai T085; body/action list tidak masuk public response, URL publik, analytics, atau log.
**Verifikasi:** Uji wallet palsu, signature/session reuse, oversized body, replay invalid, retry identik, dan akses silang wallet; inspeksi response serta log fixture.

<a id="t060"></a>

## T060 — Signed attestation EIP-712 dari hasil verifier

**Prioritas:** P1 | **Ukuran:** M | **PRD:** §11, FR-013, FR-014
**Dependensi:** T002, T006, T058, T059
**Tujuan:** Menghasilkan attestation yang hanya mengesahkan solusi verified milik wallet yang berwenang.
**Output rencana (≤5 file):** `services/verifier/attestation`, `services/verifier/signer_adapter`, `services/verifier/tests/attestation_test`, `specs/test-vectors/eip712-attestation.json`.
**Kriteria selesai:**
- [ ] Typed data mengikat wallet, challenge ID, puzzle hash, rules/engine version, score tuple, replay commitment, chain ID, verifying contract, nonce, dan expiry.
- [ ] Nonce/expiry mengikuti T006; signature hanya dibuat sesudah verifikasi sukses dan tidak memuat action list.
- [ ] Secret diperoleh melalui signer adapter/config aman; test key tetap terpisah dari konfigurasi nyata dan tidak masuk repository/log.
**Verifikasi:** Verifikasi fixture signature lalu ubah satu per satu seluruh field/domain; semuanya gagal terhadap signature lama. Pastikan replay invalid tidak pernah memanggil signer.

<a id="t061"></a>

## T061 — API Daily metadata dan archive untuk guest

**Prioritas:** P1 | **Ukuran:** S | **PRD:** §5, §12, FR-012
**Dependensi:** T057
**Tujuan:** Menyediakan puzzle hari ini dan archive yang dapat dimainkan tanpa wallet.
**Output rencana (≤5 file):** `services/api/challenges/queries`, `services/api/challenges/routes`, `services/api/tests/challenge_api_test`.
**Kriteria selesai:**
- [ ] Guest dapat membaca challenge ID, waktu UTC, immutable hash/spec/version, dan status kompetisi tanpa data replay privat.
- [ ] Archive memakai puzzle/version historis yang sama; server menolak submission ranking baru ke challenge yang sudah ditutup.
- [ ] Respons menyediakan identitas versi/cache yang jelas; tidak menyatakan metadata cache sebagai status ranking atau waktu server terkini.
**Verifikasi:** Tanpa session wallet, baca active dan archive; bandingkan hash dari dua klien dan uji submit archive setelah batas UTC.

### Checkpoint CP-06B — Submission privat dan metadata publik terpisah

- [ ] T059–T061 menegakkan wallet authorization, attestation binding, serta API guest tanpa replay leak.
- [ ] Evidence mencatat command/scenario, versi, hasil dan blocker; tidak ada kelulusan berdasarkan rencana saja.

<a id="t062"></a>

## T062 — Proyeksi best score dan shared rank berpaginasi

**Prioritas:** P1 | **Ukuran:** M | **PRD:** §5.1, §10–11, FR-013
**Dependensi:** T016, T056, T059
**Tujuan:** Menghitung ranking off-chain dari score verified melalui adapter event/projection sesuai T006.
**Output rencana (≤5 file):** `services/indexer/ranking_projection`, `services/api/leaderboard/query`, `services/api/db/migrations/003_rank_indexes`, `services/api/tests/ranking_test`.
**Kriteria selesai:**
- [ ] Satu best verified score per wallet; perbandingan tuple leksikografis lebih kecil lebih baik tanpa timestamp tie-breaker.
- [ ] Skor sama berbagi competition rank, misalnya `1,1,3,4`; pagination tidak memotong perhitungan rank global atau menduplikasi pemain.
- [ ] Query memiliki indeks dan pagination; respons membedakan provisional/final dan sumber data, tanpa menganggap attestation belum on-chain sebagai ranking resmi.
**Verifikasi:** Uji score yang mengungguli hanya komponen kedua/ketiga, repeated wallet, ties di batas halaman, dan halaman setelah banyak skor lebih baik; inspect query plan pada fixture volume yang disepakati.

<a id="t063"></a>

## T063 — Worker finalisasi Daily yang idempotent

**Prioritas:** P1 | **Ukuran:** M | **PRD:** §5.3, §6, FR-012, FR-013, FR-016
**Dependensi:** T006, T057, T062
**Tujuan:** Menghasilkan snapshot final hanya setelah challenge ditutup dan sumber event canonical memenuhi kebijakan finalitas.
**Output rencana (≤5 file):** `services/scheduler/finalize_daily`, `services/indexer/finality_port`, `services/api/db/migrations/004_final_snapshots`, `services/scheduler/tests/finalization_test`.
**Kriteria selesai:**
- [ ] Worker memakai batas UTC dan adapter finality/canonical event; belum memenuhi finalitas berarti tetap provisional, bukan snapshot final.
- [ ] Best score, shared rank, snapshot version/hash, serta event internal untuk reveal/weekly dicatat atomik dan idempotent.
- [ ] Input fixture reorg sebelum finalitas membatalkan kandidat lama; kebijakan koreksi final yang disepakati T006 terdokumentasi dan tidak diam-diam menulis ulang hasil final.
**Verifikasi:** Fake clock dan adapter event fixtures: jalankan sebelum tutup, sesudah tutup tetapi belum final, sesudah final, crash/retry, serta reorg. Adapter chain nyata dihubungkan T071/T072.

<a id="t064"></a>

## T064 — Reveal replay hanya setelah snapshot final

**Prioritas:** P1 | **Ukuran:** S | **PRD:** §5.2–5.3, FR-016
**Dependensi:** T059, T063, T085
**Tujuan:** Membuka replay terbaik dari snapshot final tanpa membocorkannya selama challenge aktif atau masih provisional.
**Output rencana (≤5 file):** `services/api/replays/reveal_route`, `services/scheduler/reveal_best_replays`, `services/api/tests/replay_privacy_test`.
**Kriteria selesai:**
- [ ] Pemain lain tidak dapat membaca action list saat active maupun closed-but-provisional melalui ID guessing, listing, atau storage URL.
- [ ] Hanya replay best score pada snapshot final yang dibuka; commitment, puzzle hash, score, dan versi cocok sebelum publikasi.
- [ ] Publication idempotent mengikuti policy T085; kegagalan reveal tidak mengubah ranking final dan dapat diulang.
**Verifikasi:** Uji matriks akses owner/other/anonymous pada active, provisional, final; mutasikan commitment dan gagalkan upload sebelum retry.

### Checkpoint CP-06C — Rank final dan reveal konsisten

- [ ] T062–T064 lolos ties/pagination/finality fixtures; replay tidak terbuka saat active/provisional.
- [ ] Evidence mencatat command/scenario, versi, hasil dan blocker; tidak ada kelulusan berdasarkan rencana saja.

<a id="t065"></a>

## T065 — Layar Daily, leaderboard, dan archive

**Prioritas:** P1 | **Ukuran:** M | **PRD:** §5, §8, FR-012, FR-013, FR-016
**Dependensi:** T022, T025, T028, T041, T061, T062
**Tujuan:** Menghubungkan satu alur guest: buka Daily → mainkan puzzle → lihat hasil lokal dan ranking dengan status yang akurat.
**Output rencana (≤5 file):** `apps/game/lib/features/daily/daily_screen.dart`, `apps/game/lib/features/daily/daily_controller.dart`, `apps/game/lib/integrations/challenge_api.dart`, `apps/game/lib/data/challenge_cache.dart`, `apps/game/test/features/daily_test.dart`.
**Kriteria selesai:**
- [ ] Guest dapat memainkan active/cache/archive tanpa connect wallet; attempts tidak dibatasi dan hint tidak dapat diakses pada mode kompetitif.
- [ ] UI menampilkan tanggal/periode UTC, puzzle identity, pagination shared rank, provisional/final, loading/error/cache state.
- [ ] Archive tidak menawarkan ranking submission; hasil lokal belum on-chain tidak ditampilkan sebagai peringkat resmi; submission wallet disambung T069.
**Verifikasi:** Widget/integration fixture active→offline cached puzzle→archive, coba jalur hint alternatif, dan periksa score lokal tidak muncul sebagai confirmed rank.

<a id="t066"></a>

## T066 — Integrasi keamanan Daily dan bukti G2

**Prioritas:** P1 | **Ukuran:** S | **PRD:** §15 US-05–US-08, §18; FR-012, FR-013, FR-016
**Dependensi:** T058, T060, T063, T064, T065
**Tujuan:** Memastikan jalur API/verifier/privacy bekerja bersama sebelum menyambung transaksi nyata.
**Output rencana (≤5 file):** `services/api/tests/daily_flow_test`, `services/verifier/tests/adversarial_replay_test`, `tasks/evidence/daily-verifier.md`.
**Kriteria selesai:**
- [ ] Dua guest memperoleh puzzle identik; wallet-authenticated replay valid mendapat attestation, replay palsu/score palsu ditolak.
- [ ] Active/provisional replay tetap privat; setelah fixture canonical finalization, best replay cocok commitment dan rank ties benar.
- [ ] Laporan menyertakan golden equivalence G2 dan batas verifikasi berbasis chain fixtures; tidak menyatakan G4/production chain selesai.
**Verifikasi:** Jalankan alur end-to-end lokal dengan fake clock, private storage fixture, dan finality adapter; simpan command, versi, hasil, dan failure yang masih terbuka.

### Checkpoint CP-06D — Integrasi API siap chain

- [ ] T065–T066 membuktikan guest daily/archive dan attack cases; chain nyata belum diklaim selesai.
- [ ] Evidence mencatat command/scenario, versi, hasil dan blocker; tidak ada kelulusan berdasarkan rencana saja.
