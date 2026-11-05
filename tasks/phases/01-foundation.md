# Fase 01 — Keputusan dan fondasi

Task keputusan menghasilkan spesifikasi yang dapat diimplementasikan; jangan menganggap alternatif teknis di kartu sebagai keputusan final. Semua path di bawah adalah rencana. Saat breakdown dibuat belum ada implementasi; kini T001–T008 selesai sesuai [laporan Fase 01](../evidence/phase-01.md).

<a id="t001"></a>

## T001 — Formalisasi aturan simulasi
**Prioritas:** P0 | **Ukuran:** S | **PRD:** §3.2–3.3, §20; FR-001, FR-002, FR-005
**Dependensi:** Tidak ada.
**Tujuan:** Hilangkan ambiguitas mekanik sebelum engine, solver, dan level final dibuat.
**Output rencana (≤5 file):** `specs/rules.md`, `specs/test-vectors/rules-cases.json`.
**Kriteria selesai:**
- [x] Tentukan tick awal, waktu emission source, urutan SHIFT/movement/evaluation, serta apakah completion tepat pada tick limit sah.
- [x] Definisikan collision di node/edge, target sinkron/latching, switch awal, sinyal tanpa rute, siklus, dan terminal failure dengan contoh input/output.
- [x] Catat keputusan owner/desainer beserta versi rules; node khusus di luar baseline tidak ditambahkan tanpa keputusan scope.
**Verifikasi:** Walkthrough contoh satu sinyal, dua sinyal tiba bersamaan/berbeda, SHIFT pada tick aktif, dead end, loop, completion di batas, dan timeout; setiap kasus punya state akhir yang tidak ambigu.

<a id="t002"></a>

## T002 — Tetapkan identitas versi dan normalisasi skor
**Prioritas:** P0 | **Ukuran:** S | **PRD:** §3.5, §4.2, §10; FR-004, FR-005, FR-009
**Dependensi:** T001.
**Tujuan:** Samakan kontrak puzzle/replay/score agar client dan verifier tidak mengartikan data berbeda.
**Output rencana (≤5 file):** `specs/identity-and-versioning.md`, `specs/scoring.md`, `specs/test-vectors/scoring-cases.json`.
**Kriteria selesai:**
- [x] Definisikan schema/engine/rules/generator versions, encoding kanonis, puzzle hash, replay commitment, dan perilaku versi tidak dikenal; hash/encoding menjadi kontrak lintas implementasi.
- [x] Definisikan ordered action list, tick range, duplicate SHIFT, aksi setelah selesai, serta rumus `programming_actions` dari program final; jelaskan jika nilainya berkorelasi dengan SHIFT tanpa menciptakan kontrol baru.
- [x] Contoh lexicographic `(shift_count, completion_ticks, programming_actions)` menunjukkan lebih kecil lebih baik/skor seri/program ekuivalen; tetapkan juga definisi attempt dan boundary 10 percobaan, tick optimum untuk Perfect Timing (minimum tick global atau tick solusi lexicographic optimum), serta bukti minimum SHIFT untuk Think Ahead.
**Verifikasi:** Dua orang/agent menghitung encoding dan skor fixture yang sama secara terpisah; hasil identik, termasuk kasus program diedit berkali-kali tetapi finalnya sama.

### Checkpoint CP-01A — Aturan dapat diimplementasikan
- [x] T001–T002 menghasilkan transisi, skor dan boundary yang tidak ambigu.
- [x] Contoh diperiksa sebelum schema/engine ditulis; keputusan yang belum disepakati tetap diberi status pending.

<a id="t003"></a>

## T003 — Siapkan workspace dan perintah verifikasi dasar
**Prioritas:** P0 | **Ukuran:** M | **PRD:** §10, §14
**Dependensi:** Tidak ada.
**Tujuan:** Buat skeleton minimum Flutter/Flame dan tes Dart; backend/contract scaffold dibuat pada task miliknya.
**Output rencana (≤5 file):** `apps/game/pubspec.yaml`, `apps/game/lib/main.dart`, `apps/game/test/smoke_test.dart`, `.gitignore`, `README.md` (file scaffold otomatis tidak dihitung sebagai scope fitur).
**Kriteria selesai:**
- [x] Versi Flutter/Dart/Flame dikunci dan petunjuk setup dapat diikuti dari checkout bersih.
- [x] Entrypoint kosong dapat dijalankan; domain Dart dapat dites tanpa renderer, network, atau wallet.
- [x] Dokumentasikan command nyata untuk format/analyze/test/run; dependency dan generated files diperlakukan konsisten.
**Verifikasi:** Jalankan setup, `flutter analyze`, `flutter test`, dan launch app kosong pada satu target tersedia; simpan versi serta hasil. Command belum diasumsikan tersedia sebelum task ini selesai.

<a id="t004"></a>

## T004 — Spike kompatibilitas Flutter Web
**Prioritas:** P0 | **Ukuran:** M | **PRD:** §10, §14, §18–20
**Dependensi:** T003.
**Tujuan:** Temukan risiko Flame, Drift/SQLite, file import/export, dan procedural audio di web sejak awal.
**Output rencana (≤5 file):** `specs/decisions/web-compatibility.md`, `apps/game/lib/spikes/web_probe.dart`, `apps/game/web/index.html`, `apps/game/web/sqlite_worker.dart` (bila diperlukan), `apps/game/test/web_probe_test.dart`.
**Kriteria selesai:**
- [x] Bukti browser nyata menunjukkan Canvas/Flame, persistence setelah reload, serta export/import file dapat berjalan atau mencatat blocker spesifik.
- [x] Uji audio melalui interaksi pengguna dan game di iframe menyerupai itch.io; periksa console/runtime serta offline setelah aset tersedia.
- [x] Rekam GO/fix/fallback beserta target browser; hapus spike dari alur produk ketika pengganti siap, tanpa menyatakan web kompatibel hanya dari build sukses.
**Verifikasi:** Build web dan jalankan lewat server lokal di iframe; lakukan reload, simpan/baca data, export/import, audio toggle, dan input pointer. Library worker/SDK dipilih dari dokumentasi resmi saat eksekusi.

**Pembagian eksekusi:** cakupan integrasi browser melampaui satu kartu kecil, sehingga T004 dilaksanakan sebagai dua slice; status parent selesai hanya jika keduanya lulus.
- T004a: opt-in probe Flutter/Flame, bounded file codec, Drift WASM dan audio; uji codec/analyzer/build.
- T004b: isolated browser runner + server iframe lintas situs, pengujian runtime/input/reload/file/audio/offline-warm, serta evidence/report. File harness tidak masuk alur game normal.

### Checkpoint CP-01B — Toolchain dan risiko web diketahui
- [x] T003–T004 memiliki command nyata dan bukti runtime; limit platform tercatat.
- [x] Domain tetap dapat diuji headless meskipun salah satu target platform masih bermasalah.

<a id="t005"></a>

## T005 — Putuskan stack backend dan strategi verifier
**Prioritas:** P1 | **Ukuran:** S | **PRD:** §10–11, §20; FR-012, FR-013
**Dependensi:** T001, T002, T003.
**Tujuan:** Pilih runtime backend, database, private replay storage, queue/scheduler, dan cara menjalankan engine deterministik.
**Output rencana (≤5 file):** `specs/decisions/backend.md`, `specs/decisions/verifier-runtime.md`.
**Kriteria selesai:**
- [x] Bandingkan reuse domain Dart/headless dengan port engine; pilih satu beserta alasan, deployment lokal, dan konsekuensi maintenance.
- [x] Tentukan database/migrations, worker topology, private object storage, dan test harness dengan batas operasional sederhana; tidak mengasumsikan layanan berbayar sudah tersedia.
- [x] Definisikan cara menjalankan golden vectors client/verifier dalam CI dan penolakan versi yang tidak didukung.
**Verifikasi:** Catatan keputusan menyertakan proof-of-concept minimal/runbook yang dapat dieksekusi pada T056/T058; tidak memilih backend hanya karena ada pada contoh arsitektur.

<a id="t006"></a>

## T006 — Tetapkan protokol kompetisi dan otorisasi wallet
**Prioritas:** P1 | **Ukuran:** M | **PRD:** §5, §11, §20; FR-013–FR-016
**Dependensi:** T002, T005, T007.
**Tujuan:** Bekukan kontrak integrasi API, EIP-712, wallet SDK, sponsor gas, dan batas privasi sebelum agent berbeda mengimplementasikannya.
**Output rencana (≤5 file):** `specs/competition-api.md`, `specs/attestations.md`, `specs/decisions/wallet-gas.md`, `specs/security/competition-threat-model.md`.
**Kriteria selesai:**
- [x] Definisikan endpoint/status/error, challenge lifecycle UTC, otorisasi registrasi/freeze hash/versi/window on-chain, nonce/expiry, signer rotation/admin policy, finality/reorg policy, dan semua attestation bindings dalam PRD §11; tentukan penanganan deadline vs waktu transaksi masuk.
- [x] Pilih wallet SDK dan jalur user-paid/sponsor yang didukung mobile/web; definisikan otorisasi kriptografis agar relayer tidak dapat mengganti wallet pemilik skor.
- [x] Diagram aliran data menetapkan replay privat sampai hasil final, commitments publik saja, tidak ada actions pada calldata/event/log/analytics; publikasi puzzle sebelum hari aktif dibatasi sesuai aturan kompetisi.
**Verifikasi:** Walkthrough guest, wallet palsu, attestation kedaluwarsa, wrong chain/contract, replay leak, sponsor gagal, dan reorg; setiap batas trust memiliki pemilik implementasi.

### Checkpoint CP-01C — Kontrak backend siap
- [x] T005–T006 memilih runtime, API, otorisasi, dan trust boundary sebelum implementasi P1 kompetitif.
- [x] Signer, sponsor dan replay privacy mempunyai jalur uji yang jelas.

<a id="t007"></a>

## T007 — Tetapkan batas sumber daya dan validasi
**Prioritas:** P0 | **Ukuran:** S | **PRD:** §4.2–4.4, §12, §18; FR-009, FR-019, FR-020
**Dependensi:** T001, T002.
**Tujuan:** Tentukan limit eksplisit agar solver, generator, replay, dan import tidak menghabiskan resource tanpa batas.
**Output rencana (≤5 file):** `specs/resource-limits.md`, `specs/test-vectors/invalid-inputs.json`.
**Kriteria selesai:**
- [x] Angka limit node/edge/source/target/tick/action/byte/decompressed-byte dan kapasitas solver ditetapkan berdasarkan probe kecil, dengan alasan serta error yang diharapkan.
- [x] Bedakan invalid input, solver timeout/unknown, puzzle proven unsolvable, dan solusi terbukti optimal; timeout tidak menjadi bukti validitas/optimalitas.
- [x] Tentukan schema allowlist, foreign references, duplicate ID, compression bomb, backup secret denylist/allowlist, dan cancellation untuk pekerjaan berat.
**Verifikasi:** Set fixture batas `n-1/n/n+1`, cyclic input, payload rusak, versi asing, dan oversized disepakati serta dapat dipakai ulang pada codec/API/backup tests.

<a id="t008"></a>

## T008 — Verifikasi tema dan aturan resmi game jam
**Prioritas:** P0 | **Ukuran:** S | **PRD:** §19–20
**Dependensi:** Tidak ada.
**Tujuan:** Ganti status PRD “belum diverifikasi” dengan bukti aturan resmi saat task dieksekusi; breakdown ini tidak memverifikasi aturan jam.
**Output rencana (≤5 file):** `specs/jam-compliance.md`.
**Kriteria selesai:**
- [x] Periksa halaman resmi yang dirujuk PRD untuk tema, deadline/timezone, rules, AI policy, submission format, dan akses juri; simpan URL dan tanggal pemeriksaan.
- [x] Petakan konsekuensi terhadap konsep, disclosure AI, lisensi/kredit, platform, dan jadwal; ambiguitas ditandai untuk keputusan owner.
- [x] Setiap perubahan requirement disetujui sebagai perubahan scope dan dipetakan ke backlog sebelum implementasi terkait.
**Verifikasi:** Checklist memiliki bukti per klaim atau status belum terkonfirmasi; tidak mengarang tema/deadline dan tidak menganggap deskripsi PRD sebagai aturan resmi.

### Checkpoint CP-01D — Batas dan kepatuhan terlacak
- [x] T007–T008 menetapkan resource limits serta bukti aturan jam, atau blocker dengan pemilik yang jelas.
- [x] Belum ada fitur/aturan game baru yang dimasukkan diam-diam ke baseline.
