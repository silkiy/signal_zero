# Fase 08 — Weekly Tournament, achievement, dan reveal lengkap

Seluruh output di bawah masih rencana. T085 adalah keputusan storage yang dapat dikerjakan awal. T087 menghasilkan kandidat integrasi P1; hasil final G6 tetap menunggu hardening dan gate terakhir pada master plan.

<a id="t078"></a>

## T078 — Kalender Weekly dan simulasi fairness points

**Prioritas:** P1 | **Ukuran:** S | **PRD:** §6, §20, FR-017
**Dependensi:** T002, T006
**Tujuan:** Memformalkan identitas minggu UTC dan mengevaluasi distribusi poin PRD tanpa diam-diam mengubahnya.
**Output rencana (≤5 file):** `specs/weekly-rules.md`, `services/scheduler/tests/weekly_calendar_test`, `tools/simulate_weekly_points`, `tasks/evidence/weekly-fairness.md`.
**Kriteria selesai:**
- [ ] Definisi week ID mencakup Senin 00:00 UTC hingga akhir Minggu, tujuh daily IDs, pergantian tahun, dan kapan weekly dinyatakan final.
- [ ] Simulasi memakai tabel `100/75/50/30/15/5/0`, shared daily ranks, variasi jumlah peserta/hari serta ties; hasil dan keterbatasan dicatat.
- [ ] Rekomendasi kalibrasi dipisahkan dari baseline; perubahan tabel hanya diterapkan setelah keputusan produk tercatat.
**Verifikasi:** Calendar fixtures melintasi Sunday→Monday UTC dan tahun baru; jalankan cohort kecil/besar serta ties pada batas rank 1/3/10/25/100.

<a id="t079"></a>

## T079 — Akumulasi weekly dari snapshot Daily final

**Prioritas:** P1 | **Ukuran:** S | **PRD:** §6, FR-017
**Dependensi:** T063, T072, T078
**Tujuan:** Membentuk points mingguan yang dapat dihitung ulang secara idempotent dari tujuh hasil harian final.
**Output rencana (≤5 file):** `services/indexer/weekly_points`, `services/api/db/migrations/007_weekly_snapshots`, `services/indexer/tests/weekly_points_test`.
**Kriteria selesai:**
- [ ] Hanya snapshot Daily final yang menyumbang poin; no valid submission bernilai 0 dan shared daily rank memperoleh poin sama.
- [ ] Total adalah jumlah tujuh daily points; total sama berbagi competition weekly rank, lebih banyak poin lebih baik, tanpa timestamp tie-breaker.
- [ ] Processing ulang tidak menggandakan points; weekly final hanya ketika semua daily yang relevan memenuhi policy T078 dan versi snapshot tercatat.
**Verifikasi:** Fixture tujuh hari termasuk hari tanpa submission, hari masih provisional, shared champions, ties weekly, duplicate job, serta corrected-source policy T006.

<a id="t080"></a>

## T080 — API dan layar Weekly Tournament

**Prioritas:** P1 | **Ukuran:** S | **PRD:** §6, §8, FR-017
**Dependensi:** T022, T062, T079
**Tujuan:** Memperlihatkan poin, shared weekly rank, dan kontribusi per hari secara jelas kepada guest maupun wallet player.
**Output rencana (≤5 file):** `services/api/tournament/routes`, `apps/game/lib/features/tournament/tournament_screen.dart`, `apps/game/lib/features/tournament/tournament_controller.dart`, `apps/game/test/features/tournament_test.dart`.
**Kriteria selesai:**
- [ ] UI menampilkan minggu/periode UTC, tabel poin baseline, total/rank, dan breakdown harian dengan status provisional/final.
- [ ] API berpaginasi dengan shared rank global; total tied tidak dipecahkan menurut timestamp dan no submission tidak disamarkan sebagai hasil verified.
- [ ] Guest bisa membaca leaderboard; loading/offline/error dan minggu archive tidak memerlukan connect wallet.
**Verifikasi:** API/widget fixtures untuk tie melintasi halaman, hari pending finalization, pergantian minggu, guest access, dan network failure.

### Checkpoint CP-08A — Weekly berasal dari daily final

- [ ] T078–T080 menguji kalender/fairness, tabel poin, shared rank, pagination dan guest UI.
- [ ] Evidence mencatat command/scenario, versi, hasil dan blocker; tidak ada kelulusan berdasarkan rencana saja.

<a id="t081"></a>

## T081 — Eligibility achievement on-chain dari hasil final

**Prioritas:** P1 | **Ukuran:** S | **PRD:** §7, §11, FR-018
**Dependensi:** T060, T063, T079
**Tujuan:** Menghitung entitlement achievement per wallet tanpa mengubah local achievements atau menerbitkan token/NFT.
**Output rencana (≤5 file):** `services/api/achievements/eligibility`, `services/verifier/achievement_attestation`, `services/api/tests/achievement_eligibility_test`, `specs/achievement-attestation.md`.
**Kriteria selesai:**
- [ ] Daily Champion = shared daily #1; Consistent Mind = tujuh daily berturut-turut selesai verified; Top Strategist = shared weekly 1–10; Signal Master = sepuluh daily wins, termasuk shared #1.
- [ ] Eligibility memakai hasil final saja dan terikat wallet/achievement/snapshot evidence; tujuh hari berarti UTC berturut-turut, bukan tujuh partisipasi terpisah.
- [ ] Attestation memiliki domain/nonce/expiry/finality binding sesuai T006 dan tidak tersedia sebelum seluruh evidence final.
**Verifikasi:** Test tepat di bawah/pada tiap ambang, gap satu hari, shared winners, corrected/provisional daily, wallet mismatch, dan duplicate eligibility request.

<a id="t082"></a>

## T082 — Registry achievement terpisah dengan claim aman

**Prioritas:** P1 | **Ukuran:** M | **PRD:** §7, §11, FR-018
**Dependensi:** T067, T073, T081
**Tujuan:** Menyimpan klaim achievement opsional pada kontrak registry terpisah.
**Output rencana (≤5 file):** `contracts/src/AchievementRegistry.sol`, `contracts/test/AchievementRegistry.t.sol`, `contracts/test/AchievementRegistryFuzz.t.sol`, `contracts/script/DeployAchievements.s.sol`.
**Kriteria selesai:**
- [ ] Claim mengikat signer sah, wallet, achievement ID, evidence final, domain chain/contract, nonce, serta expiry sesuai spesifikasi T081.
- [ ] Duplicate claim, signature replay, wrong-wallet/domain, dan bukti sebelum final ditolak; event tidak memuat replay actions.
- [ ] Kontrak tidak membuat NFT/token dan tidak menjadi syarat membuka gameplay atau local achievement.
**Verifikasi:** Foundry unit/fuzz untuk valid claim dan setiap field/boundary yang dimutasi; ulangi claim serta signature di wallet/chain/registry lain.

<a id="t083"></a>

## T083 — Layar achievement dan claim wallet opsional

**Prioritas:** P1 | **Ukuran:** S | **PRD:** §7–8, FR-018
**Dependensi:** T049, T068, T081, T082
**Tujuan:** Menggabungkan tampilan local achievements dengan klaim on-chain yang dipilih pemain.
**Output rencana (≤5 file):** `apps/game/lib/features/achievements/achievements_screen.dart`, `apps/game/lib/features/achievements/claim_controller.dart`, `apps/game/lib/integrations/achievement_registry.dart`, `apps/game/test/features/achievement_claim_test.dart`.
**Kriteria selesai:**
- [ ] Enam local achievements tetap offline/otomatis; empat on-chain achievements menampilkan eligibility final dan status unclaimed/pending/claimed.
- [ ] Wallet/gas hanya diminta saat pemain memilih claim; cancel/failed claim tidak menghapus local achievement atau menghalangi bermain.
- [ ] Chain/account change, duplicate claim, expiry, serta transaction pending ditangani dan tidak ditampilkan sebagai sukses prematur.
**Verifikasi:** Guest offline lihat local awards; wallet eligible cancel lalu claim di local chain/Sepolia fixture, restart pending, dan coba claim ulang.

### Checkpoint CP-08B — Klaim achievement final dan opsional

- [ ] T081–T083 mencegah duplicate/replayed/wrong-wallet/early claims; local awards tetap offline.
- [ ] Evidence mencatat command/scenario, versi, hasil dan blocker; tidak ada kelulusan berdasarkan rencana saja.

<a id="t084"></a>

## T084 — Pemutar replay reveal dengan perbandingan skor

**Prioritas:** P1 | **Ukuran:** S | **PRD:** §5.2, FR-016
**Dependensi:** T015, T025, T026, T064, T065
**Tujuan:** Memutar replay terbaik yang sudah terbuka memakai engine historis yang sesuai.
**Output rencana (≤5 file):** `apps/game/lib/features/replays/revealed_replay_screen.dart`, `apps/game/lib/features/replays/replay_comparison.dart`, `apps/game/test/features/revealed_replay_test.dart`.
**Kriteria selesai:**
- [ ] Controls play/pause/restart/step, 0.5×/1×/2×, timeline SHIFT, dan score comparison menghasilkan state/score yang sama pada semua speed.
- [ ] Replay diambil hanya dari endpoint reveal final; puzzle hash/version/commitment diverifikasi sebelum playback, mismatch ditolak.
- [ ] Membuka replay orang lain tidak mengubah program/progress/best score pemain; versi tidak tersedia mendapat pesan yang jelas.
**Verifikasi:** Playback fixture final pada seluruh speed dan step, bandingkan snapshots; uji active replay URL, commitment rusak, versi lama, dan kembali ke puzzle milik pemain.

<a id="t085"></a>

## T085 — Kebijakan retensi dan publikasi storage replay

**Prioritas:** P1 | **Ukuran:** S | **PRD:** §5.2–5.3, §11, §20, FR-016
**Dependensi:** T006, T007
**Tujuan:** Memutuskan dan mempersiapkan konfigurasi lifecycle replay sebelum intake/reveal diterapkan.
**Output rencana (≤5 file):** `specs/replay-storage-policy.md`, `services/api/replays/storage_config`, `services/api/tests/replay_storage_policy_test`.
**Kriteria selesai:**
- [ ] Keputusan menetapkan private/public storage boundary, retention, akses owner, publikasi replay best final, kuota, cleanup, dan recovery kegagalan; nilai yang belum disepakati ditandai belum siap, bukan default tak terlihat.
- [ ] Lifecycle melarang public exposure sampai challenge closed dan snapshot final; evidence final/commitment tidak terhapus sebelum kebutuhan audit yang disepakati.
- [ ] Konfigurasi bounded dan testable tidak menaruh action list di URL/log/cache publik; checksum/commitment tidak diperlakukan sebagai enkripsi/autentikasi.
**Verifikasi:** Fake clock/config fixtures membuktikan belum-final tidak dapat dipublikasikan/di-cleanup terlalu awal, expired data sesuai policy diproses idempotent, dan private URL tidak public-readable.

<a id="t086"></a>

## T086 — Integrasi rollover Daily, Weekly, dan reveal

**Prioritas:** P1 | **Ukuran:** S | **PRD:** §5–7, §14–15, FR-016, FR-017, FR-018
**Dependensi:** T072, T079, T080, T081, T084
**Tujuan:** Memastikan satu snapshot final menjadi sumber konsisten bagi replay, weekly points, dan achievement eligibility.
**Output rencana (≤5 file):** `services/scheduler/tests/week_rollover_test`, `services/api/tests/final_snapshot_consumers_test`, `tasks/evidence/weekly-reveal-integration.md`.
**Kriteria selesai:**
- [ ] Sunday→Monday UTC tidak mencampur week ID; daily masih provisional tidak menambah final points atau membuka replay/achievement.
- [ ] Reorg sebelum finality, duplicate finalization delivery, dan crash/retry tidak menghasilkan duplicate points/reveal/entitlement.
- [ ] Setelah finality seluruh consumer merujuk snapshot version/hash yang sama; koreksi pascafinal mengikuti policy T006 secara terlihat.
**Verifikasi:** Fake-clock + canonical-chain fixture tujuh hari, late finality hari Minggu, reorg, worker crash, dan duplicate messages; rekonsiliasi tiga consumer terhadap snapshot final.

### Checkpoint CP-08C — Reveal dan rollover memakai snapshot sama

- [ ] T084–T086 memvalidasi replay controls, storage policy, serta konsistensi final snapshot ke weekly/entitlements.
- [ ] Evidence mencatat command/scenario, versi, hasil dan blocker; tidak ada kelulusan berdasarkan rencana saja.

<a id="t087"></a>

## T087 — Kandidat integrasi seluruh P1

**Prioritas:** P1 | **Ukuran:** S | **PRD:** §13–16, §21; persiapan G6
**Dependensi:** T040, T041, T046, T055, T077, T080, T083, T084, T086
**Tujuan:** Menghasilkan laporan kandidat P1 terintegrasi untuk diteruskan ke hardening dan gate G6 akhir.
**Output rencana (≤5 file):** `apps/game/integration_test/ambitious_release_test.dart`, `tasks/evidence/p1-candidate.md`.
**Kriteria selesai:**
- [ ] Alur guest offline→campaign/practice/editor/share/backup/local awards dan wallet opt-in→Daily→weekly→reveal→claim berjalan pada environment uji.
- [ ] Bukti memetakan seluruh FR P1 ke task/test terkait; accessibility, diagnostics, security, performance, dan platform gaps yang menunggu hardening tetap terlihat.
- [ ] Laporan menyatakan kandidat siap hardening atau blocker konkret; tidak menandai G6 final sebelum tugas release/hardening master plan selesai.
**Verifikasi:** Jalankan integrasi terpilih tanpa wallet/internet lalu dengan backend/local chain; simpan versi/build/commands/hasil dan gap untuk review gate akhir.

### Checkpoint CP-08D — Kandidat P1 siap hardening

- [ ] T087 mencatat bukti integrasi dan gap; G6 belum otomatis lulus.
- [ ] Evidence mencatat command/scenario, versi, hasil dan blocker; tidak ada kelulusan berdasarkan rencana saja.
