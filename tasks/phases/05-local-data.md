# Fase 05 — Data lokal, achievements, dan backup

Task ini memperluas penyimpanan minimal guest/campaign T028. Jangan membuat ulang identitas/progress atau menunggu fase editor selesai untuk memulai schema T047. Semua path merupakan rencana implementasi; tidak ada task yang sudah selesai.

<a id="t047"></a>

## T047 — Perluasan schema Drift dan migrasi

**Prioritas:** P1 | **Ukuran:** M | **PRD:** FR-008, FR-018, FR-019, FR-020; §7, §10, §12, §14

**Dependensi:** T002, T004, T009, T010, T028

**Tujuan:** Memperluas database lokal minimum dengan schema versioned untuk kebutuhan P1 sambil mempertahankan data guest P0.

**Output rencana (≤5 file):** `apps/game/lib/data/local_database.dart` (perluas database T028 yang sama), `apps/game/lib/data/local/local_tables.dart`, `apps/game/lib/data/local/schema_migrations.dart`, `apps/game/test/data/local/schema_migrations_test.dart`, `specs/local-storage.md`.

**Kriteria selesai:**
- [ ] Database mencakup progress, best score, settings, drafts, local achievements, imported puzzles, dan cache dengan identitas/versi yang eksplisit.
- [ ] Migrasi dari schema minimal T028 mempertahankan local UUID, nickname, campaign progress, serta best score; versi masa depan ditolak secara aman.
- [ ] Repository mempunyai operasi transaksi yang dibutuhkan backup/import; tidak ada kolom penyimpanan private key, seed phrase, atau wallet/session secrets.

**Verifikasi:** Buat fixture database v0 berisi progress dan settings, migrasikan, lalu baca ulang seluruh data. Jalankan test database pada target mobile serta backend web terpilih dari T004 jika tersedia.

<a id="t048"></a>

## T048 — Autosave dan pemulihan data lokal

**Prioritas:** P1 | **Ukuran:** M | **PRD:** FR-008; §12, §14

**Dependensi:** T036, T047

**Tujuan:** Memperluas autosave P0 ke perubahan data lokal P1 dan memastikan write parsial tidak merusak data yang sudah tersimpan.

**Output rencana (≤5 file):** `apps/game/lib/data/local/autosave_coordinator.dart`, `apps/game/lib/data/local/recovery_service.dart`, `apps/game/test/data/local/autosave_recovery_test.dart`.

**Kriteria selesai:**
- [ ] Perubahan repository untuk progress, settings, draft, serta achievements di-flush pada checkpoint/lifecycle yang terdokumentasi tanpa menyimpan setiap frame animasi.
- [ ] Setelah restart, data kembali ke commit terakhir yang berhasil; write gagal atau proses terputus tidak meninggalkan separuh transaksi.
- [ ] Error penyimpanan dapat diketahui pemain dan dicoba ulang; state terakhir yang masih valid tidak dihapus atau diganti diam-diam.

**Verifikasi:** Inject kegagalan di tengah transaksi dan saat flush lifecycle, lalu buka ulang database. Bandingkan dengan commit terakhir; ulangi penyimpanan yang gagal dan pastikan tidak muncul duplikat.

<a id="t049"></a>

## T049 — Enam local achievements otomatis

**Prioritas:** P1 | **Ukuran:** M | **PRD:** FR-018; §7, US-12

**Dependensi:** T002, T016, T017, T027, T042, T044, T047

**Tujuan:** Menambahkan evaluator event domain dan layar achievements lokal, tanpa transaksi atau koneksi wallet.

**Output rencana (≤5 file):** `apps/game/lib/domain/achievements/local_achievement_evaluator.dart`, `apps/game/lib/features/achievements/achievements_screen.dart`, `apps/game/lib/data/repositories/achievement_repository.dart`, `apps/game/test/domain/achievements/local_achievement_test.dart`.

**Kriteria selesai:**
- [ ] First Signal, Never Give Up, Architect, dan Signal Creator terbuka dari event completion/attempt/create/export yang terdokumentasi; boundary sepuluh attempts mengikuti kontrak T002 dan diuji pada 9/10/11.
- [ ] Think Ahead memerlukan bukti puzzle membutuhkan minimal tiga SHIFT; Perfect Timing memerlukan tick optimum tervalidasi sesuai definisi T002. Jumlah SHIFT pemain yang berlebihan atau solver timeout tidak menghasilkan bukti tersebut.
- [ ] Unlock otomatis tersimpan satu kali dan tampil setelah restart offline; status lokal tidak dianggap sebagai bukti kelayakan achievement on-chain.

**Verifikasi:** Jalankan fixture positif/negatif untuk keenam achievement, termasuk solusi sengaja boros SHIFT, baseline optimum belum terbukti, event duplikat, dan restart. Semua hasil mengikuti event/optimality contract, bukan jumlah klik UI.

### Checkpoint CP-05A — Data dan achievements lokal konsisten

- [ ] T047–T049 mempertahankan guest P0 saat migrasi, autosave/recovery, dan unlock yang tervalidasi.
- [ ] Evidence mencatat command/scenario, versi, hasil dan blocker; tidak ada kelulusan berdasarkan rencana saja.

<a id="t050"></a>

## T050 — Adapter identity guest dan wallet

**Prioritas:** P1 | **Ukuran:** S | **PRD:** FR-008, FR-014; §8, §12, US-08

**Dependensi:** T002, T047

**Tujuan:** Menyediakan aturan linking/unlinking public wallet identity tanpa memindahkan atau menghapus kepemilikan data guest. SDK wallet akan dipasang oleh task integrasi wallet.

**Output rencana (≤5 file):** `apps/game/lib/data/repositories/identity_repository.dart`, `apps/game/test/data/identity_linking_test.dart`, `specs/identity-linking.md`.

**Kriteria selesai:**
- [ ] Link/disconnect wallet mempertahankan local UUID, nickname, progress, drafts, serta local achievements; cancel/gagal koneksi tidak mengubah data.
- [ ] Pergantian wallet memisahkan identitas kompetitif dan cache terkait sesuai kontrak; skor/claim on-chain tidak dipindahkan ke wallet lain sebagai data lokal.
- [ ] Adapter diuji dengan public identity stub dan tidak menyimpan private key/seed/session secret; gameplay offline tetap tersedia tanpa adapter wallet aktif.

**Verifikasi:** Pada profil berisi progress, simulasikan link A → disconnect → link B, termasuk pembatalan dan error. Bandingkan data lokal sebelum/sesudah dan pastikan tampilan kompetitif menggunakan wallet yang benar.

<a id="t051"></a>

## T051 — Ekspor backup `.szsave`

**Prioritas:** P1 | **Ukuran:** M | **PRD:** FR-020; §7, §12, US-10

**Dependensi:** T002, T007, T047

**Tujuan:** Mengekspor snapshot lokal portable dalam format versioned JSON, checksum, dan compression opsional yang dapat dipulihkan di instalasi lain.

**Output rencana (≤5 file):** `specs/backup-schema/v1.md`, `apps/game/lib/data/backup/backup_encoder.dart`, `apps/game/lib/features/profile/backup_export.dart`, `apps/game/test/data/backup/export_test.dart`.

**Kriteria selesai:**
- [ ] Ekspor konsisten berisi profile/progress, best score, settings, drafts, local achievements, imported puzzles serta metadata versi yang diperlukan; cakupan cache portable/rebuildable dijelaskan.
- [ ] File memiliki version, checksum, batas ukuran, dan compression marker bila dipakai; hasil parsial/gagal tidak dilaporkan sebagai backup berhasil.
- [ ] Allowlist ekspor mengecualikan private key, seed phrase, token autentikasi, serta wallet/session secrets; checksum tidak disebut sebagai bukti autentisitas data.

**Verifikasi:** Ekspor database fixture yang mewakili semua kategori, decode dengan pembaca format, dan bandingkan snapshot. Tambahkan field rahasia sentinel pada stub sumber untuk memastikan field tersebut tidak ikut ke file.

<a id="t052"></a>

## T052 — Validasi dan preview impor `.szsave`

**Prioritas:** P1 | **Ukuran:** M | **PRD:** FR-020; §12, §14, US-10

**Dependensi:** T007, T047, T051

**Tujuan:** Membaca backup tidak tepercaya menjadi preview yang menjelaskan isi, kompatibilitas, dan dampak merge/restore tanpa lebih dulu menulis data.

**Output rencana (≤5 file):** `apps/game/lib/data/backup/backup_decoder.dart`, `apps/game/lib/data/backup/backup_preview.dart`, `apps/game/lib/features/profile/backup_import_preview.dart`, `apps/game/test/data/backup/import_preview_test.dart`.

**Kriteria selesai:**
- [ ] Ukuran input/dekompresi, checksum, schema, versi, referensi puzzle, dan kompleksitas divalidasi sebelum menghasilkan preview; versi lama hanya diterima melalui migrasi yang tersedia.
- [ ] Preview menyatakan jumlah entitas, konflik, data yang akan berubah, serta pilihan merge/restore; tidak memberi otoritas kompetitif pada best score/achievement lokal hasil impor.
- [ ] Membuka atau membatalkan preview tidak menulis database, mengubah identity wallet, maupun menjalankan konten/input eksternal.

**Verifikasi:** Preview file valid, lama yang didukung, checksum salah, unknown version, dan payload mengembang berlebih. Bandingkan snapshot database sebelum/sesudah setiap preview/cancel; seluruhnya identik.

### Checkpoint CP-05B — Identity dan backup tidak membawa secrets

- [ ] T050–T052 menjaga progress guest, ekspor portable, dan preview import tanpa write.
- [ ] Evidence mencatat command/scenario, versi, hasil dan blocker; tidak ada kelulusan berdasarkan rencana saja.

<a id="t053"></a>

## T053 — Merge atau restore secara transaksional

**Prioritas:** P1 | **Ukuran:** M | **PRD:** FR-020; §12, US-10

**Dependensi:** T048, T051, T052

**Tujuan:** Menerapkan pilihan impor secara atomik dengan backup state sebelumnya serta laporan hasil yang sesuai preview.

**Output rencana (≤5 file):** `specs/backup-merge-policy.md`, `apps/game/lib/data/backup/backup_apply_service.dart`, `apps/game/lib/features/profile/backup_import_result.dart`, `apps/game/test/data/backup/import_apply_test.dart`.

**Kriteria selesai:**
- [ ] Aturan konflik per jenis entitas dan semantik merge/restore terdokumentasi sebelum apply; input preview yang telah berubah harus divalidasi ulang.
- [ ] State sebelumnya dibackup berhasil sebelum apply; kegagalan backup membatalkan apply, dan kegagalan write menyebabkan rollback seluruh transaksi.
- [ ] Hasil akhir sesuai pilihan/preview serta dilaporkan dengan jumlah perubahan/konflik/error; impor tidak menghapus atau mengganti rahasia maupun sesi wallet yang berada di luar backup.

**Verifikasi:** Jalankan merge dengan ID duplikat dan restore ke profil berbeda. Inject gagal membuat pre-backup serta gagal di tengah apply; bandingkan state semula byte/canonical snapshot dan buktikan rollback tanpa data campuran.

<a id="t054"></a>

## T054 — Pengujian input berbahaya dan migrasi backup

**Prioritas:** P1 | **Ukuran:** S | **PRD:** FR-019, FR-020; §12, §14, §18

**Dependensi:** T044, T047, T053

**Tujuan:** Mengunci batas resource dan integritas data melalui corpus adversarial untuk Share Code, `.szsave`, dan schema lama.

**Output rencana (≤5 file):** `apps/game/test/data/backup/import_adversarial_test.dart`, `apps/game/test/domain/share/share_adversarial_test.dart`, `specs/test-vectors/import-regressions.json`.

**Kriteria selesai:**
- [ ] Corpus mencakup truncated payload, referensi invalid, duplicate ID, unknown version, ukuran batas/batas+1, compression bomb, dan mutasi input dengan seed reproducible.
- [ ] Input ditolak dalam budget T007 tanpa hang/crash; input yang gagal tidak mengubah database/progress sebelumnya.
- [ ] Fixture migrasi versi yang didukung mempertahankan makna data; versi yang tidak didukung memberi error eksplisit tanpa mencoba downgrade atau menghapus database.

**Verifikasi:** Jalankan corpus serta seeded fuzz dengan batas waktu/memori tercatat. Bandingkan snapshot database sebelum/sesudah setiap input gagal dan simpan counterexample yang ditemukan sebagai regresi.

<a id="t055"></a>

## T055 — Pembuktian alur lokal sepenuhnya offline

**Prioritas:** P1 | **Ukuran:** S | **PRD:** FR-008, FR-018, FR-019, FR-020; §12, §14, US-08, US-09, US-10, US-12

**Dependensi:** T028, T046, T048, T049, T050, T053, T054

**Tujuan:** Menguji satu perjalanan pemain dari data guest sampai backup dipulihkan tanpa ketergantungan layanan kompetisi.

**Output rencana (≤5 file):** `apps/game/integration_test/offline_progress_backup_test.dart`, `tasks/evidence/offline-data.md`.

**Kriteria selesai:**
- [ ] Dengan jaringan diblokir, pemain melanjutkan campaign/practice, mengedit draft, mengimpor puzzle, serta melihat progress/settings/local achievements setelah restart.
- [ ] Backup hasil profil A dipreview lalu merge/restore pada database bersih B; data portable sesuai schema dan Share Code tetap menghasilkan puzzle identik.
- [ ] Tanpa wallet atau dengan wallet service gagal, seluruh alur lokal tetap dapat diselesaikan; hasil uji mencatat target/platform dan keterbatasan pengujian.

**Verifikasi:** Jalankan integration test memakai database sementara dan transport yang menolak semua network request. Restart aplikasi di tengah perjalanan dan ulangi restore pada instalasi/database bersih; simpan bukti hasil serta bug yang ditemukan.

### Checkpoint CP-05C — Restore dan offline terbukti

- [ ] T053–T055 lolos pre-backup/rollback, adversarial input, dan journey offline lintas profil.
- [ ] Evidence mencatat command/scenario, versi, hasil dan blocker; tidak ada kelulusan berdasarkan rencana saja.
