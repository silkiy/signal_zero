# Fase 04 — Puzzle procedural, hint, dan creator

Task di dokumen ini berasal dari PRD v2.2; belum ada implementasi yang dinyatakan selesai. Path adalah rencana, bukan file yang sudah tersedia. Kerjakan berdasarkan dependensi, bukan hanya nomor: draft editor T042 memerlukan perluasan penyimpanan T047 dari fase 05.

<a id="t038"></a>

## T038 — Generator kandidat deterministik

**Prioritas:** P1 | **Ukuran:** M | **PRD:** FR-010; §4.2, §10, §14

**Dependensi:** T007, T009, T017

**Tujuan:** Menghasilkan kandidat graph dari seed serta versi yang eksplisit, dengan budget kerja terbatas. Task ini belum menerbitkan puzzle tanpa validasi.

**Output rencana (≤5 file):** `apps/game/lib/domain/generator/candidate_generator.dart`, `apps/game/lib/domain/generator/generator_descriptor.dart`, `apps/game/test/domain/generator/candidate_generator_test.dart`.

**Kriteria selesai:**
- [ ] Seed, generator version, dan rules version yang sama menghasilkan puzzle specification kanonik identik, terlepas dari frame rate atau jam perangkat.
- [ ] Kandidat memenuhi batas node, edge, tick, dan ukuran T007; versi tidak didukung ditolak dengan alasan yang jelas.
- [ ] Budget habis menghasilkan status eksplisit; kandidat tidak lolos solver tidak pernah ditandai sebagai puzzle siap terbit.

**Verifikasi:** Jalankan seed tetap berulang di test runner serta entry headless T019 saat tersedia; bandingkan specification/hash. Paksa budget minimum dan versi tidak dikenal, lalu pastikan tidak ada puzzle yang diterbitkan.

<a id="t039"></a>

## T039 — Filter validitas, difficulty, dan kemiripan

**Prioritas:** P1 | **Ukuran:** M | **PRD:** FR-010; §4.2, §18, §20

**Dependensi:** T016, T017, T038

**Tujuan:** Melengkapi pipeline kandidat menjadi puzzle terverifikasi dengan metadata difficulty dan filter kualitas yang dapat dijelaskan.

**Output rencana (≤5 file):** `apps/game/lib/domain/generator/puzzle_publisher.dart`, `apps/game/lib/domain/generator/quality_policy.dart`, `apps/game/test/domain/generator/quality_policy_test.dart`, `specs/generator-quality.md`.

**Kriteria selesai:**
- [ ] Setiap puzzle terbit mempunyai solusi yang dijalankan ulang sampai sukses sebelum tick limit; timeout/unknown solver dibedakan dari bukti tidak ada solusi.
- [ ] Baseline optimal hanya dilabeli optimal jika pencarian membuktikannya; metrik dan ambang difficulty/triviality dicatat sebagai kalibrasi, lalu diuji pada contoh curated.
- [ ] Kandidat terlalu mirip riwayat recent ditolak; descriptor seed/versi kandidat yang diterima tetap dapat merekonstruksi puzzle tanpa membutuhkan riwayat pemain.

**Verifikasi:** Gunakan fixture solvable, unsolvable, timeout, trivial, dan graph mirip. Buktikan hanya kasus sesuai kebijakan yang terbit; jalankan replay solusi untuk setiap hasil terbit dan simpan alasan reject.

<a id="t040"></a>

## T040 — Property test generator dan bukti G3

**Prioritas:** P1 | **Ukuran:** S | **PRD:** FR-010; §4.2, §14, §16 G3, §17

**Dependensi:** T018, T039

**Tujuan:** Membuktikan invariant generator pada corpus seed reproducible dan menyimpan counterexample sebagai regresi.

**Output rencana (≤5 file):** `apps/game/test/domain/generator/generator_properties_test.dart`, `specs/test-vectors/generator-regressions.json`, `tasks/evidence/g3-generator.md`.

**Kriteria selesai:**
- [ ] Corpus seed serta budget pengujian tercatat; semua puzzle yang terbit valid schema, deterministik, dan mempunyai replay sukses dalam tick limit.
- [ ] Seed yang memicu kegagalan dapat direproduksi dan dipertahankan sebagai fixture; suite juga mencakup kehabisan budget tanpa keluaran palsu.
- [ ] Bukti G3 mencatat jumlah kandidat/hasil terbit/reject/unknown serta hasil uji, tanpa menyamakan finite test coverage dengan bukti semua kemungkinan seed.

**Verifikasi:** Jalankan property suite dengan seed runner tetap lalu ulangi satu corpus di platform kedua yang tersedia. Reproduksi satu counterexample buatan untuk memastikan fixture regresi menangkapnya.

### Checkpoint CP-04A — Generator memenuhi G3

- [ ] T038–T040 memiliki seed/version, validasi solver, quality filters, dan bukti property tests; unknown tidak terbit sebagai puzzle valid.
- [ ] Evidence mencatat command/scenario, versi, hasil dan blocker; tidak ada kelulusan berdasarkan rencana saja.

<a id="t041"></a>

## T041 — Hint tiga tahap dengan batas mode

**Prioritas:** P1 | **Ukuran:** M | **PRD:** FR-011; §4.3, §5, US-04

**Dependensi:** T010, T017, T025, T036

**Tujuan:** Menambahkan hint konseptual, rentang timing, dan satu langkah tervalidasi melalui satu layanan yang tidak mengubah puzzle maupun program pemain.

**Output rencana (≤5 file):** `apps/game/lib/domain/hints/hint_service.dart`, `apps/game/lib/features/play/hint_panel.dart`, `apps/game/test/domain/hints/hint_service_test.dart`, `apps/game/test/features/play/hint_panel_test.dart`.

**Kriteria selesai:**
- [ ] Hint diminta opsional dan berurutan: conceptual clue tanpa urutan solusi, timing clue yang sesuai solusi, lalu satu langkah yang lolos solver.
- [ ] Sebelum/sesudah permintaan hint, puzzle hash, program, dan state simulasi identik; saat solver unknown, UI tidak mengarang langkah atau klaim optimal.
- [ ] Mode Daily kompetitif menolak hint di layanan dan UI; mode editor memerlukan hasil solver validation yang masih sesuai puzzle hash/versinya.

**Verifikasi:** Minta tiga tahap pada puzzle diketahui solusinya dan bandingkan snapshot sebelum/sesudah. Uji bypass UI pada mode ranked, puzzle editor belum tervalidasi, serta puzzle yang berubah setelah validasi; semuanya tidak menghasilkan hint solusi.

<a id="t042"></a>

## T042 — Editor graph dengan draft lokal

**Prioritas:** P1 | **Ukuran:** M | **PRD:** FR-019; §4.4, §8, §12

**Dependensi:** T007, T009, T022, T023, T047

**Tujuan:** Memberi layar Create untuk menyusun puzzle kecil dan melanjutkan draft setelah aplikasi ditutup.

**Output rencana (≤5 file):** `apps/game/lib/features/create/editor_screen.dart`, `apps/game/lib/features/create/editor_controller.dart`, `apps/game/lib/data/repositories/draft_repository.dart`, `apps/game/test/features/create/editor_test.dart`.

**Kriteria selesai:**
- [ ] Pemain dapat membuat/mengedit node, edge, source, target, switch, dan tick limit melalui kontrol editor dengan batas T007.
- [ ] Draft disimpan/dimuat offline melalui repository lokal; operasi invalid memberi pesan tanpa merusak draft terakhir.
- [ ] Setiap perubahan puzzle membatalkan status solver validation lama dan menghasilkan specification yang dapat divalidasi ulang.

**Verifikasi:** Buat graph bercabang, ubah koneksi/tick limit, simpan, tutup aplikasi, lalu buka draft tanpa jaringan. Uji edge menuju node hilang, hapus node berelasi, dan melewati batas; state tetap konsisten.

<a id="t043"></a>

## T043 — Test play dan solver validation editor

**Prioritas:** P1 | **Ukuran:** M | **PRD:** FR-009, FR-011, FR-019; §4.3–4.4

**Dependensi:** T017, T025, T027, T041, T042

**Tujuan:** Memakai engine yang sama untuk mencoba draft serta memvalidasi kelayakannya sebelum menampilkan hint solver.

**Output rencana (≤5 file):** `apps/game/lib/features/create/editor_validation_controller.dart`, `apps/game/lib/features/create/editor_test_play.dart`, `apps/game/test/features/create/editor_validation_test.dart`.

**Kriteria selesai:**
- [ ] Test play menjalankan salinan draft dengan engine/timeline yang sama; keluar dari test play tidak mengubah draft atau progress campaign.
- [ ] Validasi menampilkan status valid beserta solusi terbukti, unsolvable terbukti, atau budget habis/unknown; pekerjaan terbatas dan UI dapat membatalkannya.
- [ ] Metadata validasi terikat puzzle hash/versi; hint editor hanya tersedia untuk validasi yang masih cocok dan hilang setelah draft diedit.

**Verifikasi:** Uji tiga draft: solvable, unsolvable, dan melebihi budget. Kembali ke editor, ubah satu edge, dan pastikan badge valid serta akses hint sebelumnya dicabut.

### Checkpoint CP-04B — Hint dan editor memakai engine yang sama

- [ ] T041–T043 menjaga state saat hint, mencabut validasi draft yang berubah, dan membatasi solver.
- [ ] Evidence mencatat command/scenario, versi, hasil dan blocker; tidak ada kelulusan berdasarkan rencana saja.

<a id="t044"></a>

## T044 — Format Share Code yang versioned

**Prioritas:** P1 | **Ukuran:** M | **PRD:** FR-019; §4.4, §14, US-09

**Dependensi:** T002, T007, T009

**Tujuan:** Mengimplementasikan codec offline untuk puzzle specification, versi schema, compression, dan checksum yang mempunyai format terdokumentasi.

**Output rencana (≤5 file):** `specs/share-schema/v1.md`, `apps/game/lib/domain/share/share_codec.dart`, `apps/game/test/domain/share/share_codec_test.dart`, `specs/test-vectors/share-code.json`.

**Kriteria selesai:**
- [ ] Encode/decode fixture valid menghasilkan puzzle specification kanonik dan hash identik, termasuk versi rules/engine yang diperlukan.
- [ ] Versi tidak didukung, checksum rusak, specification invalid, ukuran terkompresi/dekompresi berlebih, dan kompleksitas di luar T007 ditolak sebelum konsumsi resource berlebih.
- [ ] Format/checksum dijelaskan sebagai deteksi korupsi; Share Code tidak diberi klaim autentisitas, tidak memerlukan wallet, dan tidak mengunduh resource eksternal.

**Verifikasi:** Jalankan golden round-trip fixture, mutasi satu karakter, truncated payload, unknown version, dan payload yang mengembang di atas batas. Pastikan reject memberi alasan stabil serta tidak hang.

<a id="t045"></a>

## T045 — Ekspor dan impor Share Code dalam UI

**Prioritas:** P1 | **Ukuran:** M | **PRD:** FR-019; §4.4, §8, §12, US-09

**Dependensi:** T022, T042, T044, T047

**Tujuan:** Menghubungkan codec ke layar ekspor draft serta import preview yang dapat disimpan dan dimainkan offline.

**Output rencana (≤5 file):** `apps/game/lib/features/create/share_code_sheet.dart`, `apps/game/lib/features/create/import_puzzle_screen.dart`, `apps/game/lib/data/repositories/imported_puzzle_repository.dart`, `apps/game/test/features/create/share_import_test.dart`.

**Kriteria selesai:**
- [ ] Pemain dapat menyalin/mengekspor Share Code dan membuka preview impor dengan identitas, versi, dan ringkasan puzzle hasil validasi.
- [ ] Membatalkan preview tidak menulis data; menyetujui impor menyimpan puzzle lokal tanpa menimpa draft/progress yang tidak terkait.
- [ ] Puzzle impor dimainkan dengan engine yang sesuai dan hash asal; input salah menampilkan alasan penolakan serta tidak membuka hint sebelum solver validation yang cocok.

**Verifikasi:** Ekspor puzzle dari instalasi A, impor pada profil bersih B dalam mode offline, dan bandingkan hash serta replay hasil. Uji cancel, duplicate import, checksum salah, dan versi tidak didukung.

<a id="t046"></a>

## T046 — Alur practice dan creator end-to-end

**Prioritas:** P1 | **Ukuran:** M | **PRD:** FR-010, FR-011, FR-019; §4, §14, US-03, US-04, US-09

**Dependensi:** T027, T040, T041, T043, T045

**Tujuan:** Menyediakan pintu masuk Practice yang menyatukan puzzle hasil generator dengan gameplay/hint, lalu membuktikan perjalanan creator sampai puzzle impor dapat dimainkan.

**Output rencana (≤5 file):** `apps/game/lib/features/play/practice_screen.dart`, `apps/game/integration_test/practice_flow_test.dart`, `apps/game/integration_test/creator_share_flow_test.dart`, `tasks/evidence/local-content.md`.

**Kriteria selesai:**
- [ ] Pemain meminta puzzle practice, melihat identitas/difficulty, mencoba solusi, dan memakai tiga tahap hint tanpa wallet/internet.
- [ ] Bila generator kehabisan budget, UI memberi status/retry dan tidak menerbitkan kandidat invalid atau melabeli hasil unknown sebagai optimal.
- [ ] Alur buat → validasi → test play → ekspor → impor → selesaikan mempunyai bukti end-to-end; puzzle impor mempertahankan specification/hash.

**Verifikasi:** Jalankan kedua integration flow dalam mode offline pada target tersedia. Simulasikan generator tanpa hasil, lalu ulangi creator flow setelah restart untuk memeriksa draft dan puzzle impor tetap tersedia.

### Checkpoint CP-04C — Konten lokal dapat dibagikan

- [ ] T044–T046 lolos round-trip Share Code dan journey practice/creator offline.
- [ ] Evidence mencatat command/scenario, versi, hasil dan blocker; tidak ada kelulusan berdasarkan rencana saja.
