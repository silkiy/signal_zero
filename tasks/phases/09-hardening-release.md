# Fase 09 — Hardening, paket rilis, dan polish

Semua path adalah rencana. P2 bersifat opsional dan tidak memblokir P0/P1. Build yang belum diuji pada perangkat/platform tertentu harus diberi status belum terverifikasi.

<a id="t088"></a>

## T088 — Diagnostics lokal dan analytics berbasis persetujuan
**Prioritas:** P1 | **Ukuran:** M | **PRD:** §13–14, §17; FR-024
**Dependensi:** T028, T036, T047, T059.
**Tujuan:** Tambahkan bukti crash/performa/funnel tanpa membocorkan program pemain atau data wallet rahasia.
**Output rencana (≤5 file):** `apps/game/lib/data/diagnostics.dart`, `apps/game/lib/features/profile/privacy_settings.dart`, `services/api/src/diagnostics.*`, `specs/analytics-events.md`, `apps/game/test/diagnostics_test.dart`.
**Kriteria selesai:**
- [ ] Definisikan events tutorial completion, first success, attempts/completion, repeat play, hint usage, dan submission tanpa merekam action list/replay atau secrets.
- [ ] Analytics eksternal mengikuti consent; guest offline tetap berjalan, queue dibatasi, payload disanitasi, dan pencatatan lokal dapat dinonaktifkan/diekspor sesuai kebijakan.
- [ ] Crash-free sessions ≥99% dicatat sebagai target pengukuran dengan denominator/window; tidak diklaim tercapai tanpa sampel.
**Verifikasi:** Inspeksi payload/log pada consent off/on, offline/reconnect, crash terkontrol, dan active daily; tidak ada replay aktif, private key, seed, atau token autentikasi.

<a id="t089"></a>

## T089 — Profiling dan optimasi frame budget
**Prioritas:** P0 | **Ukuran:** M | **PRD:** §9, §14, §17; FR-007
**Dependensi:** T033, T034, T035.
**Tujuan:** Capai target 60 FPS pada perangkat mobile kelas menengah yang disebutkan secara nyata.
**Output rencana (≤5 file):** `apps/game/lib/game/circuit_effects.dart`, `apps/game/lib/game/particle_pool.dart` (perluas implementasi T034), `apps/game/lib/game/board_component.dart` (T023), `apps/game/integration_test/performance_test.dart`, `specs/reports/performance.md`.
**Kriteria selesai:**
- [ ] Rekam frame timings, jank, memory dan skenario board terpadat pada perangkat, OS, build mode, serta durasi yang tercatat.
- [ ] Pooling partikel, batas glow/blur, serta adaptive/reduced effects mengatasi bottleneck terukur tanpa mengubah state atau skor engine.
- [ ] Laporkan hasil dibanding target 60 FPS dengan frame budget sekitar 16,7 ms; perangkat yang tidak tersedia tidak diberi label lulus.
**Verifikasi:** Profile build sebelum/sesudah pada skenario yang sama, replay state/score identik, dan toggle reduced effects tidak memengaruhi logic.

<a id="t090"></a>

## T090 — Audit accessibility dan customization
**Prioritas:** P1 | **Ukuran:** M | **PRD:** §8–9, §14; FR-023
**Dependensi:** T036, T046, T065, T080, T083, T084.
**Tujuan:** Perbaiki hambatan navigasi dan pembacaan pada semua fitur P1 setelah baseline kontrol tersedia.
**Output rencana (≤5 file):** `apps/game/lib/app/theme.dart`, `apps/game/lib/app/accessibility.dart`, `apps/game/test/accessibility_test.dart`, `apps/game/integration_test/accessibility_flow_test.dart`, `specs/reports/accessibility.md`.
**Kriteria selesai:**
- [ ] Board/timeline memakai indikator selain warna; kontras dan ukuran target sentuh memenuhi nilai yang dipilih/didokumentasikan, teks besar tidak menutup kontrol.
- [ ] Navigasi focus/semantics pada UI yang relevan, audio toggle, simulation speed, reduced effects, serta settings persistence dapat dipakai di mobile dan web.
- [ ] Tidak ada timer real-time pada puzzle biasa; daily UTC countdown tidak memaksa puzzle inti bergantung pada network.
**Verifikasi:** Jalankan campaign/editor/daily/claim dengan non-color indicators, teks besar, effects off, audio off, keyboard di web, serta screen reader untuk kontrol UI; catat batas akses board jika ada.

### Checkpoint CP-09A — Diagnostics, performance dan accessibility diperiksa

- [ ] T088–T090 memiliki payload redacted/consent, profil perangkat, serta audit aksesibilitas dengan batas pengujian jelas.
- [ ] Evidence mencatat command/scenario, versi, hasil dan blocker; tidak ada kelulusan berdasarkan rencana saja.

<a id="t091"></a>

## T091 — Uji ketahanan data lokal dan recovery
**Prioritas:** P1 | **Ukuran:** S | **PRD:** §12, §14, §18; FR-008, FR-020
**Dependensi:** T048, T053, T054, T055.
**Tujuan:** Buktikan progress tidak hilang saat app berhenti, storage gagal, atau restore dibatalkan.
**Output rencana (≤5 file):** `apps/game/integration_test/storage_recovery_test.dart`, `specs/reports/data-recovery.md`.
**Kriteria selesai:**
- [ ] Restart/kill saat autosave dan draft write menghasilkan state konsisten dengan operasi terakhir yang berhasil.
- [ ] Disk/quota failure, restore invalid, migration gagal dan import cancel mempertahankan data awal atau recovery backup yang dapat dipulihkan.
- [ ] Mode offline memuat campaign/practice/editor/progress yang tersedia; wallet disconnect tidak menghapus guest data.
**Verifikasi:** Fault injection pada transaksi database/import, reopen storage, lalu bandingkan checksum/content fixture sebelum dan sesudah; ulangi mekanisme persistence web sesuai T004.

<a id="t092"></a>

## T092 — Jalankan matriks determinisme lintas platform
**Prioritas:** P0 | **Ukuran:** S | **PRD:** §10, §14, §17; FR-001, FR-004
**Dependensi:** T018, T019, T026, T033.
**Tujuan:** Buktikan aturan versi yang sama menghasilkan state/score identik, termasuk replay historis yang masih didukung.
**Output rencana (≤5 file):** `specs/reports/determinism-matrix.md`, `apps/game/test/golden_replay_test.dart`, `specs/test-vectors/historical-replays.json`.
**Kriteria selesai:**
- [ ] Golden vectors berjalan di Dart/native dan Dart/web; engine/rules versions dicatat agar “lintas versi” tidak diartikan sebagai perubahan aturan tanpa versi.
- [ ] Speed/frame scheduling berbeda menghasilkan snapshot serta score identik; replay versi didukung tetap bisa dibaca dan versi asing ditolak jelas.
- [ ] Matrix membedakan PASS/FAIL/UNAVAILABLE; target yang belum diuji tidak dilaporkan lulus.
**Verifikasi:** Bandingkan hash setiap tick dan tuple skor seluruh golden fixture, termasuk boundary tick dan normalisasi action; integrasi backend tercakup terpisah oleh T058.

<a id="t093"></a>

## T093 — Smoke test paket mobile
**Prioritas:** P0 | **Ukuran:** S | **PRD:** §1, §14, §16; FR-006, FR-008
**Dependensi:** T037, T089, T092.
**Tujuan:** Hasilkan paket Android/iOS yang dapat dipasang pada toolchain yang tersedia dan laporkan keterbatasan target lainnya.
**Output rencana (≤5 file):** `specs/release/mobile-build.md`, `specs/reports/mobile-smoke.md` (artifact build dihasilkan oleh toolchain).
**Kriteria selesai:**
- [ ] Android release/debug-distribution sesuai kebutuhan dapat di-install dan menjalankan tutorial, 15 level, pause/resume serta progress offline.
- [ ] iOS diuji melalui toolchain Apple yang tersedia; jika tidak ada Mac/signing/device, tandai blocker beserta langkah penutupan, bukan kelulusan semu.
- [ ] Nomor versi, commit/reference source, checksum artifact, dan command build dicatat; secrets signing tidak masuk repo/backup.
**Verifikasi:** Fresh install lalu upgrade/reopen pada perangkat nyata/emulator yang diidentifikasi; simpan hasil tiap platform. Task tetap blocked untuk target wajib yang belum terverifikasi.

### Checkpoint CP-09B — Recovery dan platform punya evidence

- [ ] T091–T093 memiliki fault injection, matrix determinisme, dan smoke mobile; target unavailable tetap pending.
- [ ] Evidence mencatat command/scenario, versi, hasil dan blocker; tidak ada kelulusan berdasarkan rencana saja.

<a id="t094"></a>

## T094 — Siapkan paket web itch.io
**Prioritas:** P0 | **Ukuran:** S | **PRD:** §1, §14, §19
**Dependensi:** T004, T037, T089, T092.
**Tujuan:** Hasilkan web playable jika kompatibel, atau bukti blocker dan fallback paket yang dapat diakses juri.
**Output rencana (≤5 file):** `apps/game/web/index.html`, `specs/release/itch-web.md`, `specs/reports/web-smoke.md` (ZIP hasil build tidak menjadi source).
**Kriteria selesai:**
- [ ] ZIP memiliki entrypoint dan asset path benar; iframe lokal dapat membuka tutorial/game tanpa wallet atau cross-origin error yang menghalangi.
- [ ] Periksa resize, pointer/keyboard, storage reload, audio unlock, file export/import sesuai fitur dalam paket, serta browser target dari T004.
- [ ] Bila web tidak kompatibel, catat keputusan fallback berdasarkan aturan T008 dan bukti paket alternatif; jangan klaim web tersedia sebelum diuji.
**Verifikasi:** Ekstrak artifact ke folder bersih, serve dan embed lewat iframe; jalankan smoke browser dari artifact, bukan development server Flutter.

<a id="t095"></a>

## T095 — Review keamanan kontrak dan batas trust
**Prioritas:** P1 | **Ukuran:** M | **PRD:** §11, §18, §20; FR-013–FR-018
**Dependensi:** T066, T073, T074, T076, T077, T082, T085.
**Tujuan:** Tutup temuan prioritas tinggi sebelum deployment rilis; review tidak menghapus trust assumption verifier off-chain.
**Output rencana (≤5 file):** `specs/security/review.md`, `specs/security/findings.md`, `specs/release/chain-runbook.md`.
**Kriteria selesai:**
- [ ] Review independen meliputi attestation/authorization, replay privacy, finalization/reorg, sponsor abuse, registry claims, signer rotation dan privilege admin.
- [ ] Temuan critical/high diperbaiki melalui task kecil terpisah dan retest; risiko tersisa memiliki keputusan owner sebelum mainnet.
- [ ] Catat network/chain ID/address/signer config dan prosedur rotasi/pause/recovery yang benar-benar didukung; Base Sepolia baseline uji, mainnet keputusan eksplisit kemudian.
**Verifikasi:** Cocokkan threat model T006 dengan bukti tests/attack scenarios dan deployed testnet config; jangan menyebut “audited” hanya karena agent membaca source.

<a id="t096"></a>

## T096 — Lengkapi paket instruksi dan kepatuhan jam
**Prioritas:** P0 | **Ukuran:** S | **PRD:** §16, §19, §21
**Dependensi:** T008, T093, T094.
**Tujuan:** Buat paket yang dapat dimainkan juri beserta instruksi singkat dan disclosure yang diwajibkan aturan aktual.
**Output rencana (≤5 file):** `README.md`, `specs/release/submission-checklist.md`, `specs/release/credits.md`, `specs/release/known-issues.md`.
**Kriteria selesai:**
- [ ] Instruksi mencakup objective, SHIFT/timeline/controls, platform, mulai sebagai guest, serta fitur yang benar-benar ada pada paket tersebut.
- [ ] Tema/rules/AI policy/deadline dicek ulang dari sumber resmi; kredit/lisensi dan disclosure disesuaikan bukti T008.
- [ ] Checksum/version, daftar fitur P0/P1/P2 yang dikirim, known issues, dan akses juri tercatat; tidak mengklaim backend/chain sudah live tanpa bukti.
**Verifikasi:** Tester baru mengikuti README dari artifact bersih sampai first success tanpa petunjuk chat; checklist submission cocok dengan paket. Upload/submission bukan bagian dari task breakdown saat ini.

### Checkpoint CP-09C — Paket dan instruksi cocok aturan aktual

- [ ] T094–T096 membuktikan artifact web/fallback, security review P1, dan instruksi/kepatuhan jam. Jalur G5 tidak menunggu T095 P1.
- [ ] Evidence mencatat command/scenario, versi, hasil dan blocker; tidak ada kelulusan berdasarkan rencana saja.

<a id="t097"></a>

## T097 — Validasi kandidat rilis minimum G5
**Prioritas:** P0 | **Ukuran:** S | **PRD:** §13–17, §21
**Dependensi:** T017, T033, T037, T089, T092, T093, T094, T096.
**Tujuan:** Putuskan kesiapan game jam P0 memakai bukti playable, bukan jumlah task yang dicentang.
**Output rencana (≤5 file):** `specs/reports/gate-g5.md`.
**Kriteria selesai:**
- [ ] Seluruh task P0 dan criteria rilis relevan PASS; G1 sudah dinilai, 15 level valid solver, guest progress/offline, controls, determinism, dan paket dapat dimainkan.
- [ ] Laporkan tutorial completion, pemahaman SHIFT ≥80%, first success ≤5 menit sebagai target playtest dengan jumlah tester serta hasil nyata; tidak mengarang statistik dari sampel kosong.
- [ ] Daftar scope paket dan outstanding P1/P2 jelas; keputusan siap/tidak siap menyertakan blocker serta owner, tanpa menyebut seluruh DoD P1 selesai.
**Verifikasi:** Jalankan smoke core dari artifact T093/T094, baca evidence G1/determinism/performance, dan audit checklist P0. Rekomendasi PRD mengutamakan G1–G3; jika generator P1 belum siap, nyatakan G3 belum lulus.

### Checkpoint CP-09D — Gate G5 dinilai

- [ ] T097 mencatat kesiapan seluruh P0; G2/G3/P1 yang belum selesai disebutkan terpisah.
- [ ] Evidence mencatat command/scenario, versi, hasil dan blocker; tidak ada kelulusan berdasarkan rencana saja.

<a id="t098"></a>

## T098 — Bagikan replay nonkompetitif
**Prioritas:** P2 | **Ukuran:** M | **PRD:** §13; FR-021
**Dependensi:** T010, T015, T044, T064, T084, T085.
**Tujuan:** Tambahkan ekspor/impor replay berversi untuk puzzle lokal atau kompetisi yang sudah boleh diungkap.
**Output rencana (≤5 file):** `apps/game/lib/features/replay/replay_share.dart`, `apps/game/lib/data/replay_share_codec.dart`, `apps/game/test/replay_share_test.dart`.
**Kriteria selesai:**
- [ ] Replay share menyertakan identitas puzzle/engine/rules dan actions kanonis sehingga state/score direproduksi, tanpa private key/token/wallet secret.
- [ ] Invalid/oversized/unsupported replay ditolak dan tidak memodifikasi progress otomatis.
- [ ] UI/API tidak menawarkan atau mengekspor replay kompetitif milik pemain lain sebelum challenge final; aturan embargo tetap berlaku di jalur share.
**Verifikasi:** Export/import fixture lokal dan daily final, bandingkan snapshot/score; percobaan share daily aktif pemain lain ditolak.

<a id="t099"></a>

## T099 — Polish audio procedural lanjutan
**Prioritas:** P2 | **Ukuran:** S | **PRD:** §9, §13; FR-022
**Dependensi:** T035, T089.
**Tujuan:** Tingkatkan feedback audio setelah baseline game stabil tanpa aset eksternal.
**Output rencana (≤5 file):** `apps/game/lib/game/procedural_audio.dart` (perluas audio T035), `apps/game/lib/game/audio_presets.dart`, `specs/reports/audio-polish.md`.
**Kriteria selesai:**
- [ ] Variasi procedural klik/pulse/sync/success/failure terbaca, dibatasi polyphony, dan tidak menutupi feedback penting.
- [ ] Toggle/mute dan platform audio unlock dihormati, tidak ada aset audio eksternal atau perubahan logic simulasi.
- [ ] Profiling tidak menunjukkan regresi material terhadap budget T089 pada target uji yang sama.
**Verifikasi:** Dengar rangkaian event bersamaan pada mobile/web, mute/unmute/restart, lalu ulangi skenario frame profiling audio on/off.

<a id="t100"></a>

## T100 — Audit akhir Ambitious Release G6
**Prioritas:** P1 | **Ukuran:** S | **PRD:** §13–17, §21–22
**Dependensi:** T040, T046, T055, T087, T088, T089, T090, T091, T092, T093, T094, T095, T096, T097.
**Tujuan:** Tutup seluruh P1 dan DoD PRD melalui bukti lintas fitur setelah hardening; P2 tetap opsional.
**Output rencana (≤5 file):** `specs/reports/gate-g6.md`, `specs/release/release-manifest.md`.
**Kriteria selesai:**
- [ ] Traceability FR-001–FR-020/FR-023/FR-024, US-01–US-12, NFR, G1–G6 dan DoD mempunyai hasil/bukti yang dapat diperiksa; belum diuji tetap pending.
- [ ] Alur guest offline, practice/hints, editor/share/backup, daily verified wallet/sponsor, finalized reveal/weekly/claim lolos dari artifact/lingkungan rilis yang dituju.
- [ ] Known issues, kapasitas/budget sponsor, monitoring/recovery, platform matrix dan trust verifier dicatat; blocker wajib selesai sebelum ditandai done.
**Verifikasi:** Audit evidence seluruh checkpoint dan jalankan satu journey lintas fitur pada versi build, engine/rules, backend dan contract address yang tercatat. Jangan menandai G6 hanya dari integrasi T087.

### Checkpoint CP-09E — Gate G6 dinilai

- [ ] T100 menutup P1 dan hardening sesuai DoD. T098/T099 opsional; statusnya tidak menghalangi G6.
- [ ] Evidence mencatat command/scenario, versi, hasil dan blocker; tidak ada kelulusan berdasarkan rencana saja.
