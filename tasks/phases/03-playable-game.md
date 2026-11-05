# Fase 03 — Game playable, onboarding, dan 15 level

Sumber: [PRD v2.2](../../SIGNAL_ZERO_PRD_v2.2.md), terutama §3–4, §8–10, §12–17. Seluruh path adalah **rencana**. Animasi dan audio hanya membaca hasil engine; hasil gameplay tidak boleh dihitung ulang dari posisi visual. Prioritas P1 untuk FR-023 tetap dipertahankan, meskipun baseline keterbacaan diperlukan saat membangun P0.

<a id="t022"></a>

## T022 — Shell Flutter dan navigasi guest-first

**Prioritas:** P0 | **Ukuran:** M | **PRD:** §8, §10, FR-008, US-08.
**Dependensi:** T003, T004.
**Tujuan:** Siapkan shell aplikasi yang dapat menjalankan game tanpa wallet atau jaringan.
**Output rencana (≤5 file):** `apps/game/lib/main.dart`, `apps/game/lib/app/app.dart`, `apps/game/lib/app/router.dart`, `apps/game/test/app/navigation_test.dart`.
**Kriteria selesai:**
- [ ] Aplikasi membuka jalur guest ke tutorial/Play tanpa layar login atau RPC blockchain wajib.
- [ ] Struktur navigasi mendukung Play, Daily, Tournament, Create, Achievements, Profile; destinasi belum dibuat memakai keadaan belum tersedia yang jelas.
- [ ] Build pada target yang lolos T004 membuka shell dan kembali dari gameplay tanpa kehilangan sesi secara tak terduga.
**Verifikasi:** Jalankan shell pada target pengembangan dan web jika kompatibel; matikan jaringan dan pastikan Play tetap dapat dibuka.

<a id="t023"></a>

## T023 — Board jaringan minimal dari snapshot

**Prioritas:** P0 | **Ukuran:** S | **PRD:** §3.2, §8–9, FR-007.
**Dependensi:** T009, T015, T021, T022.
**Tujuan:** Tampilkan source, node, directed edge, switch, target, dan sinyal secara terbaca sebelum effects.
**Output rencana (≤5 file):** `apps/game/lib/game/board_component.dart`, `apps/game/lib/game/board_layout.dart`, `apps/game/test/game/board_render_test.dart`.
**Kriteria selesai:**
- [ ] Semua entitas dan arah routing dapat dibedakan melalui bentuk/label selain warna.
- [ ] Board memakai snapshot engine; resize/interpolasi tidak mengubah state atau tick.
- [ ] Layout puzzle awal tetap terlihat di viewport mobile dan web yang didukung tanpa kontrol bertumpuk.
**Verifikasi:** Render fixture dengan semua tipe entitas, resize viewport portrait/landscape, lalu bandingkan hasil engine sebelum/sesudah resize.

<a id="t024"></a>

## T024 — Edit SHIFT pada timeline

**Prioritas:** P0 | **Ukuran:** S | **PRD:** §3.4, §8, FR-003.
**Dependensi:** T010, T022, T023.
**Tujuan:** Pemain dapat menambah dan menghapus SHIFT pada tick yang valid.
**Output rencana (≤5 file):** `apps/game/lib/features/gameplay/timeline_editor.dart`, `apps/game/lib/features/gameplay/program_controller.dart`, `apps/game/test/features/timeline_editor_test.dart`.
**Kriteria selesai:**
- [ ] Tap/aksi kontrol menghasilkan program canonical dengan tick yang jelas dan mencegah input di luar rentang.
- [ ] Edit setelah simulasi menginvalidasi hasil lama; preview tidak menampilkan skor run lama sebagai hasil program baru.
- [ ] Timeline dapat dipakai pada puzzle tick panjang tanpa memerlukan pemilihan switch satu per satu.
**Verifikasi:** Tambah/hapus pada tick awal/akhir, edit setelah sukses, serta uji aksi ekuivalen menghasilkan replay canonical sama.

<a id="t025"></a>

## T025 — Play, pause, step, dan kecepatan

**Prioritas:** P0 | **Ukuran:** S | **PRD:** §3.3–3.4, FR-001, FR-003.
**Dependensi:** T015, T023, T024.
**Tujuan:** Hubungkan kontrol simulasi pada runner domain tanpa menggantungkan tick pada frame rate.
**Output rencana (≤5 file):** `apps/game/lib/features/gameplay/playback_controller.dart`, `apps/game/lib/features/gameplay/playback_controls.dart`, `apps/game/test/features/playback_controller_test.dart`.
**Kriteria selesai:**
- [ ] Play/pause/step memajukan runner tepat sesuai status; pause dan terminal tidak melangkah sendiri.
- [ ] Kecepatan 0.5×/1×/2× mengubah durasi presentasi, menghasilkan state akhir dan score yang sama.
- [ ] App background/foreground mengikuti kebijakan pause yang terdokumentasi dan tidak melewatkan tick.
**Verifikasi:** Jalankan replay sama dengan step manual, tiap kecepatan, serta frame delay buatan; bandingkan snapshot/score dan uji pause saat background.

### Checkpoint CP-03A — Puzzle dapat diprogram dan dijalankan

- [ ] T023–T025 memungkinkan jalur program → simulasi pada board nyata.
- [ ] Hasil tidak berubah oleh ukuran layar, FPS, atau kecepatan playback.

<a id="t026"></a>

## T026 — Undo, reset, dan replay lokal

**Prioritas:** P0 | **Ukuran:** S | **PRD:** §3.4, FR-004.
**Dependensi:** T024, T025.
**Tujuan:** Pemain dapat menganalisis percobaan lalu kembali mengedit dengan semantik yang konsisten.
**Output rencana (≤5 file):** `apps/game/lib/features/gameplay/edit_history.dart`, `apps/game/lib/features/gameplay/program_controller.dart`, `apps/game/test/features/undo_reset_replay_test.dart`.
**Kriteria selesai:**
- [ ] Undo memulihkan edit program sebelumnya sesuai kontrak T002; tidak mengubah hitungan actions dari riwayat klik.
- [ ] Reset simulasi kembali ke initial state; reset program memiliki tindakan/label jelas agar pemain tahu apakah SHIFT dihapus.
- [ ] Replay lokal menjalankan program tersimpan dari awal dengan snapshot/score sama; tidak membuat percobaan baru secara tidak sengaja.
**Verifikasi:** Edit → run → undo → run, reset setelah gagal/sukses, dan replay dua kali; bandingkan program/state/score serta counter percobaan.

<a id="t027"></a>

## T027 — Hasil permainan dan preview skor

**Prioritas:** P0 | **Ukuran:** S | **PRD:** §3.1, §3.5, §8, FR-005.
**Dependensi:** T014, T016, T025, T026.
**Tujuan:** Jelaskan kenapa puzzle sukses/gagal dan bantu pemain mengoptimalkan tuple skor.
**Output rencana (≤5 file):** `apps/game/lib/features/gameplay/score_preview.dart`, `apps/game/lib/features/gameplay/result_panel.dart`, `apps/game/test/features/result_panel_test.dart`.
**Kriteria selesai:**
- [ ] Preview menampilkan SHIFT/actions dari program dan completion ticks hanya jika sudah valid tersedia.
- [ ] Hasil sukses menampilkan tuple serta perbandingan best lokal; gagal menampilkan terminal reason dan opsi edit/retry.
- [ ] Label optimal hanya muncul bila solver membuktikannya; hasil stale setelah edit tidak diperlakukan sebagai hasil baru.
**Verifikasi:** Buka hasil gagal, sukses lebih baik/sama/lebih buruk, dan hasil dengan solver budget exhausted; periksa label serta urutan skor.

<a id="t028"></a>

## T028 — Guest profile dan autosave progress minimum

**Prioritas:** P0 | **Ukuran:** M | **PRD:** §8, §12, FR-008, US-01, US-08.
**Dependensi:** T004, T022, T027.
**Tujuan:** Simpan UUID, nickname, tutorial/campaign progress, attempts, dan best lokal offline menggunakan fondasi Drift yang minimal.
**Output rencana (≤5 file):** `apps/game/lib/data/local_database.dart`, `apps/game/lib/data/progress_repository.dart`, `apps/game/lib/features/profile/guest_profile.dart`, `apps/game/test/data/progress_repository_test.dart`.
**Kriteria selesai:**
- [ ] Profile lokal dibuat sekali; nickname dan progress bertahan setelah restart tanpa akun/wallet/internet.
- [ ] Completion, attempts, dan best score disimpan atomik dengan definisi event yang terdokumentasi; replay pasif tidak menambah attempts.
- [ ] Schema awal memiliki version/migration entry serta abstraksi repository untuk perluasan backup/drafts/achievements; cache/DB error ditangani tanpa menghapus data diam-diam.
**Verifikasi:** Selesaikan level, tutup aplikasi, buka offline, dan cocokkan data; uji penulisan gagal/retry serta dua hasil yang datang berurutan. Koordinasikan perubahan file DB dengan pemilik task data lanjutan.

### Checkpoint CP-03B — Core loop tersimpan

- [ ] T026–T028 memungkinkan observe → program → simulate → analyze → optimize → restart aplikasi.
- [ ] Guest tetap dapat bermain tanpa wallet; save tidak bergantung pada backend.

<a id="t029"></a>

## T029 — Tutorial interaktif bertahap

**Prioritas:** P0 | **Ukuran:** M | **PRD:** §4.1, §8, FR-006, US-01.
**Dependensi:** T020, T025, T027, T028.
**Tujuan:** Ajarkan source/target, simulasi, SHIFT, timeline, puzzle mandiri, lalu optimasi dalam sesi bermain.
**Output rencana (≤5 file):** `apps/game/lib/features/tutorial/tutorial_controller.dart`, `apps/game/lib/features/tutorial/tutorial_overlay.dart`, `apps/game/lib/features/tutorial/tutorial_steps.dart`, `apps/game/test/features/tutorial_test.dart`.
**Kriteria selesai:**
- [ ] Tahapan maju berdasarkan aksi/hasil nyata, bukan hanya menutup dialog; contoh SHIFT menggunakan fixture routing yang sah.
- [ ] Tutorial dapat dilanjutkan setelah restart dan instruksi tidak menutupi board/kontrol penting.
- [ ] Akhir tutorial memberi puzzle mandiri dan membahas skor tanpa mengharuskan hint, wallet, atau internet.
**Verifikasi:** Ikuti alur baru tanpa pengetahuan sebelumnya, lakukan aksi salah, tutup aplikasi di tengah tutorial, lalu lanjutkan; catat friksi untuk T037.

<a id="t030"></a>

## T030 — Curated levels 4–6: SHIFT dan routing

**Prioritas:** P0 | **Ukuran:** S | **PRD:** §4.1, FR-006.
**Dependensi:** T019, T024, T029.
**Tujuan:** Sediakan tiga puzzle pengantar routing global, bukan kontrol switch individual.
**Output rencana (≤5 file):** `apps/game/assets/levels/level_04.json`, `apps/game/assets/levels/level_05.json`, `apps/game/assets/levels/level_06.json`, `apps/game/test/content/levels_04_06_test.dart`.
**Kriteria selesai:**
- [ ] Setiap level memiliki tujuan belajar, solusi replay, dan baseline optimalitas dengan status yang benar.
- [ ] Ketiga level memperjelas akibat SHIFT global serta timing, tanpa tiga variasi kosmetik dari puzzle sama.
- [ ] Semua level playable melalui progression dan layout board; hasil tersimpan lokal.
**Verifikasi:** Solver/validator memeriksa tiap puzzle; mainkan ketiganya dari selection hingga hasil pada viewport mobile.

<a id="t031"></a>

## T031 — Curated levels 7–9: timing dan sinkronisasi

**Prioritas:** P0 | **Ukuran:** S | **PRD:** §4.1, FR-006.
**Dependensi:** T014, T019, T030.
**Tujuan:** Ajarkan ketepatan tick dan syarat target yang sudah diformalkan.
**Output rencana (≤5 file):** `apps/game/assets/levels/level_07.json`, `apps/game/assets/levels/level_08.json`, `apps/game/assets/levels/level_09.json`, `apps/game/test/content/levels_07_09_test.dart`.
**Kriteria selesai:**
- [ ] Perbedaan satu tick mengubah hasil pada contoh yang disengaja, dengan terminal reason yang dapat dijelaskan.
- [ ] Tiap puzzle memiliki solusi sah dan fokus sinkronisasi meningkat tanpa aturan baru tersembunyi.
- [ ] Layout membuat panjang/routing jalur dan target dapat dianalisis; baseline score tervalidasi.
**Verifikasi:** Replay solusi serta program satu tick terlalu cepat/lambat untuk tiap level; periksa feedback board dan hasil.

### Checkpoint CP-03C — Onboarding sampai sinkronisasi

- [ ] T029–T031 dapat dilalui berurutan; progress bertahan setelah restart.
- [ ] Tutorial dan level tidak saling bertentangan dalam definisi SHIFT atau sinkronisasi.

<a id="t032"></a>

## T032 — Curated levels 10–12: multi-signal dan optimasi

**Prioritas:** P0 | **Ukuran:** S | **PRD:** §4.1, FR-006.
**Dependensi:** T019, T027, T031.
**Tujuan:** Tambahkan tiga puzzle yang memperlihatkan konsekuensi global pada beberapa sinyal.
**Output rencana (≤5 file):** `apps/game/assets/levels/level_10.json`, `apps/game/assets/levels/level_11.json`, `apps/game/assets/levels/level_12.json`, `apps/game/test/content/levels_10_12_test.dart`.
**Kriteria selesai:**
- [ ] Setiap puzzle memiliki solusi multi-signal dan validasi collision/sinkronisasi sesuai rules.
- [ ] Tersedia contoh solusi valid dengan skor berbeda untuk menunjukkan optimasi leksikografis.
- [ ] Solver baseline/optimality status dan metadata progression tersedia; efek tidak menutupi jalur penting.
**Verifikasi:** Validator memeriksa solusi dan alternatifnya; mainkan serta bandingkan skor pada UI hasil.

<a id="t033"></a>

## T033 — Curated levels 13–15: mastery

**Prioritas:** P0 | **Ukuran:** S | **PRD:** §4.1, FR-006.
**Dependensi:** T019, T032.
**Tujuan:** Tutup campaign dengan tiga kombinasi mekanik yang telah diajarkan.
**Output rencana (≤5 file):** `apps/game/assets/levels/level_13.json`, `apps/game/assets/levels/level_14.json`, `apps/game/assets/levels/level_15.json`, `apps/game/test/content/levels_13_15_test.dart`.
**Kriteria selesai:**
- [ ] Ketiga puzzle merupakan mastery dari rules baseline dan tidak memperkenalkan special node baru tanpa keputusan terpisah.
- [ ] Semua 15 level memiliki identitas stabil, solusi tervalidasi, urutan progression, dan status optimalitas jujur.
- [ ] Campaign dapat ditamatkan offline dan completion/progress tetap benar setelah restart.
**Verifikasi:** Jalankan batch validator terhadap 15 level; mainkan akhir campaign dan buka kembali aplikasi tanpa jaringan.

<a id="t034"></a>

## T034 — Visual procedural Holographic Circuit

**Prioritas:** P0 | **Ukuran:** M | **PRD:** §9, FR-007.
**Dependensi:** T023, T025, T027.
**Tujuan:** Terapkan arah visual PRD sambil mempertahankan board yang dapat dianalisis.
**Output rencana (≤5 file):** `apps/game/lib/game/visual_tokens.dart`, `apps/game/lib/game/circuit_effects.dart`, `apps/game/lib/game/particle_pool.dart`, `apps/game/test/game/circuit_effects_test.dart`.
**Kriteria selesai:**
- [ ] Token Void/Surface/Signal/SHIFT/Target mengikuti PRD; node, edge, partikel, gelombang SHIFT, dan target dibuat procedural.
- [ ] Success/failure memiliki feedback singkat yang tidak menutupi informasi; effects hanya membaca event/snapshot engine.
- [ ] Partikel dipool, blur dibatasi, dan reduced effects dapat menonaktifkan efek mahal tanpa kehilangan informasi gameplay.
**Verifikasi:** Rekam visual untuk semua event pada level multi-signal; bandingkan reduced/full effects dan pastikan replay/state identik. Profiling menyeluruh dilakukan pada fase hardening.

### Checkpoint CP-03D — Campaign lengkap dan visual terbaca

- [ ] T032–T034 menyelesaikan 15 curated levels dengan validasi solver.
- [ ] Effects tidak mengubah engine, menutupi jalur, atau menghalangi feedback failure.

<a id="t035"></a>

## T035 — Audio procedural dasar dan mute

**Prioritas:** P0 pendukung game feel | **Ukuran:** S | **PRD:** §9, §14; FR-022 tetap P2 untuk audio lanjutan.
**Dependensi:** T004, T025, T027, T028.
**Tujuan:** Beri feedback klik, pulse, sinkronisasi, sukses/gagal dengan sintesis sederhana.
**Output rencana (≤5 file):** `apps/game/lib/game/procedural_audio.dart`, `apps/game/lib/features/settings/audio_toggle.dart`, `apps/game/test/game/procedural_audio_test.dart`.
**Kriteria selesai:**
- [ ] Suara dihasilkan procedural tanpa aset eksternal dan dapat dimatikan seluruhnya.
- [ ] Mute tersimpan lokal; jika audio gagal atau web belum mengizinkan playback, gameplay tetap berjalan.
- [ ] Audio mengikuti event presentasi tanpa mengubah tick/score; voice count dan resource dibatasi.
**Verifikasi:** Toggle mute, restart, jalankan replay cepat, dan uji browser sebelum/sesudah user gesture; periksa tidak ada suara tertinggal setelah keluar gameplay.

<a id="t036"></a>

## T036 — Kontrol aksesibel dan preferensi dasar

**Prioritas:** P1; baseline keterbacaan menjadi pendukung P0 | **Ukuran:** M | **PRD:** §8–9, §14, FR-023.
**Dependensi:** T023, T024, T025, T028, T034, T035.
**Tujuan:** Pastikan bentuk, label, kontras, touch target, kecepatan, reduced effects, dan audio dapat digunakan pemain dengan kebutuhan berbeda.
**Output rencana (≤5 file):** `apps/game/lib/features/settings/accessibility_settings.dart`, `apps/game/lib/features/gameplay/playback_controls.dart`, `apps/game/lib/features/gameplay/timeline_editor.dart`, `apps/game/test/features/accessibility_test.dart`.
**Kriteria selesai:**
- [ ] Kontrol memiliki label semantik dan touch target sesuai standar yang dipilih serta dicatat; sinyal/switch/target dapat dibedakan tanpa warna saja.
- [ ] Kontras, font scaling, reduced effects, mute, dan simulation speed bekerja dengan preferensi tersimpan.
- [ ] Puzzle biasa tidak memiliki timer real-time; penggunaan bantuan aksesibilitas tidak mengubah score atau hasil engine.
**Verifikasi:** Periksa semantics, skala teks besar, grayscale/kontras, touch input, dan keyboard bila web mendukung; mainkan fixture sama pada semua preferensi.

<a id="t037"></a>

## T037 — Playtest core dan keputusan G1

**Prioritas:** P0 | **Ukuran:** S | **PRD:** §16 G1, §17, FR-006, US-01.
**Dependensi:** T027, T028, T029, T030.
**Tujuan:** Uji apakah pemain baru memahami SHIFT dan menikmati optimasi segera setelah tutorial dan level routing awal playable, sebelum memperbanyak konten/polish/blockchain. ID task bukan urutan wajib; jalankan T037 sebelum T031–T036 bila dependensinya sudah siap.
**Output rencana (≤5 file):** `docs/playtest/core-protocol.md`, `docs/playtest/core-results.md`, `docs/playtest/core-followups.md`.
**Kriteria selesai:**
- [ ] Protocol mengukur tutorial completion, waktu sukses pertama, pemahaman SHIFT, dan kebingungan rules pada tutorial/level routing awal tanpa memberi jawaban terlebih dulu; validasi campaign lengkap diulang saat T097.
- [ ] Hasil mencatat jumlah peserta, perangkat, metode, serta perbandingan target hipotesis PRD ≥80% completion/pemahaman dan ≤5 menit sukses pertama; sample kecil tidak diklaim sebagai bukti populasi.
- [ ] Keputusan G1 berisi bukti aktual dan task perbaikan spesifik bila belum lolos; tanpa peserta, status tetap menunggu playtest, bukan lulus otomatis.
**Verifikasi:** Jalankan sesi manusia pada build playable; simpan temuan anonim dan minta penilaian owner atas kesenangan/pemahaman. Agent dapat menyiapkan protocol/build lebih dulu, tetapi tidak boleh mengarang peserta atau hasil.

### Checkpoint CP-03E — Campaign playable dan bukti G1

- [ ] Setelah T033/T035, build P0 guest offline/tutorial/15 level dan audio dasar dapat dimainkan; bukti G1 awal dari T037 sudah tersedia.
- [ ] FR-023/T036 tetap terlacak sebagai perluasan P1; statusnya tidak memblokir checkpoint campaign P0. Baseline kontrol yang memengaruhi keterbacaan dinilai saat P0 dibangun.
- [ ] G1 membutuhkan playtest manusia; task kompetitif dapat direncanakan tetapi tidak menggantikan validasi gameplay.
