# Fase 02 — Domain, engine, dan solver dasar

Sumber: [PRD v2.2](../../SIGNAL_ZERO_PRD_v2.2.md), terutama §3–4, §10, §13–15. Status implementasi terdapat di [todo](../todo.md) dan evidence masing-masing task. Domain produksi berada di `packages/puzzle_domain`; path awal kartu diselaraskan saat task dikerjakan. Kerjakan dependensi lebih dahulu dan buat **satu commit per task**. Definisi collision, sinkronisasi, tick awal/akhir, dan skor mengikuti keputusan T001/T002.

<a id="t009"></a>

## T009 — Schema puzzle terversi

**Prioritas:** P0 | **Ukuran:** S | **PRD:** §3.2, §10, FR-001.
**Dependensi:** T001, T002, T003, T007.
**Tujuan:** Buat representasi puzzle yang dapat divalidasi client, tooling, dan verifier tanpa renderer.
**Output rencana (≤5 file):** `specs/puzzle-schema/v1.json`, `packages/puzzle_domain/lib/src/puzzle_spec.dart`, `packages/puzzle_domain/test/puzzle_spec_test.dart`.
**Kriteria selesai:**
- [x] Schema memuat versi, node/source/target/switch/edge, initial state, dan tick limit sesuai rules yang disepakati.
- [x] ID/referensi tidak valid, edge tidak sah, versi unsupported, serta ukuran melebihi batas ditolak dengan alasan terstruktur.
- [x] Serialisasi canonical menghasilkan byte/hash identik untuk spesifikasi identik; metadata tampilan tidak mengubah identitas gameplay tanpa aturan eksplisit.
**Verifikasi:** Round-trip fixture valid; coba ID duplikat, referensi hilang, urutan field berbeda, dan batas input. Rekam hasil pada runner domain yang disiapkan T003.

<a id="t010"></a>

## T010 — Schema replay dan normalisasi program

**Prioritas:** P0 | **Ukuran:** S | **PRD:** §3.4–3.5, §10, FR-003, FR-004.
**Dependensi:** T002, T003, T007, T009.
**Tujuan:** Tetapkan aksi SHIFT terurut sebagai data replay terversi, terpisah dari riwayat klik UI.
**Output rencana (≤5 file):** `specs/replay-schema/v1.json`, `apps/game/lib/domain/replay.dart`, `apps/game/test/domain/replay_test.dart`.
**Kriteria selesai:**
- [ ] Replay mengikat identitas puzzle, rules/engine/replay version, dan program sesuai kontrak T002.
- [ ] Normalisasi aksi mengikuti keputusan tick/duplikasi/order yang terdokumentasi; normalisasi dua kali menghasilkan output sama.
- [ ] Tick invalid, versi unsupported, serta jumlah aksi berlebihan ditolak tanpa menjalankan simulasi.
**Verifikasi:** Fixture ekuivalen menghasilkan program canonical identik; uji replay kosong, aksi tidak urut, duplikasi, tick di batas, dan input melebihi limit.

<a id="t011"></a>

## T011 — Golden vectors rules dan replay

**Prioritas:** P0 | **Ukuran:** S | **PRD:** §3.3, §10, §14, FR-001.
**Dependensi:** T001, T002, T009, T010.
**Tujuan:** Sediakan oracle state/score yang diturunkan dari spesifikasi, sebelum engine dipakai sebagai pembuat expected output.
**Output rencana (≤5 file):** `specs/test-vectors/core.json`, `specs/test-vectors/edge-cases.json`, `specs/test-vectors/README.md`.
**Kriteria selesai:**
- [ ] Vectors mencakup gerak dasar, SHIFT pada tick sama, gerak serentak, sinkronisasi, collision, dan batas tick.
- [ ] Setiap vector mencantumkan puzzle, program canonical, snapshot per tick, terminal reason, dan expected score bila sukses.
- [ ] Expected output dapat ditelusuri ke aturan T001/T002; kasus rules yang belum diputuskan ditandai blocked, tidak diberi hasil tebakan.
**Verifikasi:** Lakukan walkthrough manual satu tick demi satu tick dengan tabel aturan; review fixture tanpa memakai output engine sebagai satu-satunya pembenar.

### Checkpoint CP-02A — Kontrak data siap

- [ ] T009–T011 memenuhi batas input dan golden vectors konsisten dengan rules.
- [ ] Perubahan schema/rules tercatat sebelum engine, UI, dan verifier memakai kontrak tersebut.

<a id="t012"></a>

## T012 — Engine gerak sinyal satu tick

**Prioritas:** P0 | **Ukuran:** S | **PRD:** §3.2–3.3, FR-001.
**Dependensi:** T003, T009, T011.
**Tujuan:** Implementasikan transisi tick murni untuk source, jalur terarah, dan pergerakan serentak.
**Output rencana (≤5 file):** `apps/game/lib/domain/engine_state.dart`, `apps/game/lib/domain/tick_engine.dart`, `apps/game/test/domain/tick_engine_test.dart`.
**Kriteria selesai:**
- [ ] Source mengikuti emission rules; setiap sinyal bergerak maksimal satu edge per tick.
- [ ] Semua gerak dihitung dari state awal tick yang sama, bukan hasil mutasi sinyal sebelumnya.
- [ ] Engine hanya memakai data domain dan logika deterministik; tidak membaca frame time, wall clock, renderer, atau sumber random tersembunyi.
**Verifikasi:** Jalankan vectors source/path dan permutasi urutan node/sinyal; expected state tidak berubah oleh urutan koleksi.

<a id="t013"></a>

## T013 — SHIFT global sebelum pergerakan

**Prioritas:** P0 | **Ukuran:** S | **PRD:** §3.2–3.3, FR-002.
**Dependensi:** T010, T012.
**Tujuan:** Hubungkan program SHIFT ke transisi engine sesuai urutan tick resmi.
**Output rencana (≤5 file):** `apps/game/lib/domain/tick_engine.dart`, `apps/game/lib/domain/switch_routing.dart`, `apps/game/test/domain/shift_routing_test.dart`.
**Kriteria selesai:**
- [ ] SHIFT pada tick aktif mengubah seluruh switch dalam kelompok global secara serentak.
- [ ] Koneksi aktif ditentukan setelah SHIFT, kemudian sinyal bergerak pada tick yang sama.
- [ ] Tidak tersedia mutasi switch individual melalui aksi program baseline; no-SHIFT mempertahankan state routing.
**Verifikasi:** Vector dengan dua switch dan sinyal yang tiba bersamaan membedakan hasil SHIFT-before-movement dari urutan yang keliru; uji beberapa SHIFT antar-tick.

<a id="t014"></a>

## T014 — Evaluasi target dan terminal state

**Prioritas:** P0 | **Ukuran:** S | **PRD:** §3.2–3.3, FR-001, FR-005.
**Dependensi:** T001, T012, T013.
**Tujuan:** Tentukan sukses, collision, sinkronisasi, dan gagal sesuai keputusan rules; hanya node khusus yang disetujui masuk baseline.
**Output rencana (≤5 file):** `apps/game/lib/domain/terminal_evaluator.dart`, `apps/game/lib/domain/tick_engine.dart`, `apps/game/test/domain/terminal_evaluator_test.dart`.
**Kriteria selesai:**
- [ ] Semua target wajib memenuhi kondisi sinkronisasi sebelum sukses; collision ditangani sesuai tabel rules.
- [ ] Tick limit, kondisi tanpa kelanjutan, dan prioritas sukses/gagal pada tick yang sama mengikuti T001.
- [ ] Terminal reason dapat dibaca UI/debugger dan state terminal tidak melangkah lagi.
**Verifikasi:** Uji arrival serentak/tidak serentak, collision legal/ilegal sesuai rules, tepat tick limit, satu tick lewat limit, serta step setelah terminal.

### Checkpoint CP-02B — Semantik tick benar

- [ ] T012–T014 lolos vectors gerak, SHIFT, collision, dan terminal.
- [ ] Tidak ada keputusan mekanik yang terselip di renderer atau UI.

<a id="t015"></a>

## T015 — Snapshot dan replay lokal deterministik

**Prioritas:** P0 | **Ukuran:** S | **PRD:** §3.3–3.4, §10, FR-004.
**Dependensi:** T010, T014.
**Tujuan:** Simpan jejak transisi yang dapat diputar ulang untuk analisis dan debugging.
**Output rencana (≤5 file):** `apps/game/lib/domain/simulation_runner.dart`, `apps/game/lib/domain/simulation_snapshot.dart`, `apps/game/test/domain/replay_runner_test.dart`.
**Kriteria selesai:**
- [ ] Setiap tick menghasilkan snapshot immutable beserta terminal reason bila ada.
- [ ] Menjalankan ulang puzzle/version/program sama dari initial state menghasilkan jejak identik.
- [ ] Runner membatasi tick/memori sesuai T007 dan menolak kombinasi versi yang tidak didukung.
**Verifikasi:** Bandingkan seluruh snapshot dua run golden replay; ubah salinan snapshot dan pastikan snapshot lain tidak berubah; uji replay historis/unsupported.

<a id="t016"></a>

## T016 — Skor leksikografis dari program final

**Prioritas:** P0 | **Ukuran:** S | **PRD:** §3.5, FR-005.
**Dependensi:** T002, T010, T014.
**Tujuan:** Hitung dan bandingkan `(shift_count, completion_ticks, programming_actions)` dari hasil engine.
**Output rencana (≤5 file):** `apps/game/lib/domain/score.dart`, `apps/game/test/domain/score_test.dart`.
**Kriteria selesai:**
- [ ] Comparator memprioritaskan SHIFT, lalu completion ticks, lalu actions; nilai lebih kecil lebih baik.
- [ ] Programming actions mengikuti formula T002 atas program canonical; klik, undo, percobaan, dan kecepatan simulasi tidak memengaruhi skor.
- [ ] Run gagal tidak memiliki skor sukses; completion tick mengikuti boundary resmi.
**Verifikasi:** Uji pasangan skor yang setiap komponennya berbeda, skor sama, serta dua riwayat edit yang menghasilkan program final sama.

<a id="t017"></a>

## T017 — Solver terbatas dengan status optimalitas jelas

**Prioritas:** P0 | **Ukuran:** M | **PRD:** §4.2, §10, FR-009.
**Dependensi:** T007, T014, T016.
**Tujuan:** Cari program valid memakai engine yang sama, dalam budget kerja yang ditetapkan.
**Output rencana (≤5 file):** `apps/game/lib/domain/solver.dart`, `apps/game/lib/domain/solver_result.dart`, `apps/game/test/domain/solver_test.dart`.
**Kriteria selesai:**
- [ ] Solusi yang ditemukan dapat direplay dan sukses dalam tick limit; pencarian memakai urutan objektif skor yang disepakati.
- [ ] Hasil membedakan solved/proven optimal, solved tanpa bukti optimal jika didukung, proven unsatisfiable, dan budget exhausted; timeout bukan bukti tidak ada solusi.
- [ ] Budget tick/state/waktu atau unit kerja serta pembatalan membatasi CPU/memori; UI thread tidak menunggu pencarian panjang.
**Verifikasi:** Cocokkan puzzle kecil dengan enumerasi lengkap; replay setiap solusi; paksa budget habis pada puzzle yang sebenarnya solvable dan pastikan labelnya tidak menjadi unsatisfiable/optimal.

### Checkpoint CP-02C — Replay, skor, solver konsisten

- [ ] T015–T017 menghasilkan state/score sama dan tidak menganggap timeout sebagai bukti optimalitas.
- [ ] Solver dapat menjadi validator curated content, tanpa harus menyelesaikan setiap input editor berukuran maksimum.

<a id="t018"></a>

## T018 — Property tests engine dan solver

**Prioritas:** P0 | **Ukuran:** S | **PRD:** §10, §14, FR-001, FR-009.
**Dependensi:** T011, T015, T016, T017.
**Tujuan:** Buktikan invariants dan reproducibility lebih luas daripada contoh golden tetap.
**Output rencana (≤5 file):** `apps/game/test/domain/engine_property_test.dart`, `apps/game/test/domain/solver_property_test.dart`, `specs/test-vectors/regressions.json`.
**Kriteria selesai:**
- [ ] Test seeded mencakup determinisme, maksimal satu edge/tick, SHIFT global, normalisasi idempotent, dan stabilitas comparator.
- [ ] Solusi solver diuji ulang oleh runner; puzzle kecil memeriksa klaim optimalitas terhadap enumerasi independen.
- [ ] Setiap counterexample menyertakan seed/puzzle/program yang dapat diputar ulang dan diperkecil menjadi regression fixture.
**Verifikasi:** Jalankan suite dengan seed/budget tercatat; sengaja ubah satu urutan tick dalam percobaan lokal dan pastikan property/golden yang relevan mendeteksinya sebelum perubahan dibuang.

<a id="t019"></a>

## T019 — Validator headless untuk puzzle dan replay

**Prioritas:** P0 | **Ukuran:** S | **PRD:** §4.1–4.2, §10, FR-006, FR-009.
**Dependensi:** T009, T010, T015, T016, T017.
**Tujuan:** Sediakan entry point tanpa Flutter UI untuk memvalidasi konten dan menjalankan replay.
**Output rencana (≤5 file):** `apps/game/tool/validate_puzzle.dart`, `apps/game/tool/replay_puzzle.dart`, `apps/game/test/tool/validation_tool_test.dart`.
**Kriteria selesai:**
- [ ] Tool menerima puzzle/replay terversi dan menghasilkan diagnosis serta score/solver status terstruktur.
- [ ] Invalid schema, run gagal, dan budget exhausted dapat dibedakan; exit status tidak menyamarkan kegagalan.
- [ ] Tool menggunakan library domain produksi, tidak memiliki engine atau formula skor kedua.
**Verifikasi:** Panggil entry point aktual yang dibuat T003 terhadap fixture valid, corrupt, unsatisfiable, dan budget exhausted; catat perintah yang benar setelah tooling tersedia.

<a id="t020"></a>

## T020 — Curated levels 1–3

**Prioritas:** P0 | **Ukuran:** S | **PRD:** §4.1, FR-006, US-01.
**Dependensi:** T019.
**Tujuan:** Buat tiga puzzle awal yang memperkenalkan source, jalur, dan target tanpa menuntut SHIFT kompleks.
**Output rencana (≤5 file):** `apps/game/assets/levels/level_01.json`, `apps/game/assets/levels/level_02.json`, `apps/game/assets/levels/level_03.json`, `apps/game/test/content/levels_01_03_test.dart`.
**Kriteria selesai:**
- [ ] Masing-masing level memiliki fokus belajar, layout terbaca, tick limit, versi, dan solusi yang tervalidasi.
- [ ] Kesulitan naik bertahap; tidak mengajarkan mekanik yang belum ditetapkan dalam rules baseline.
- [ ] Metadata baseline score mencantumkan apakah optimalitas benar-benar terbukti oleh solver.
**Verifikasi:** Jalankan validator pada ketiga level dan replay solusinya; review pembelajaran melalui walkthrough source → path → target.

### Checkpoint CP-02D — Konten awal dapat divalidasi

- [ ] T018–T020 lolos suite domain dan validator; ketiga level memiliki solusi sah.
- [ ] Daftar perintah pengujian nyata tercatat, bukan perintah contoh yang diasumsikan tersedia.

<a id="t021"></a>

## T021 — Vertical slice headless satu puzzle

**Prioritas:** P0 | **Ukuran:** S | **PRD:** §3.1, §16 fase Playable Core, FR-001–FR-005.
**Dependensi:** T018, T019, T020.
**Tujuan:** Integrasikan observe/program/simulate/analyze/optimize pada satu puzzle sebelum renderer penuh.
**Output rencana (≤5 file):** `apps/game/test/integration/headless_core_test.dart`, `specs/test-vectors/playable-core.json`, `docs/validation/playable-core.md`.
**Kriteria selesai:**
- [ ] Satu fixture routing mencakup program gagal, perubahan timing SHIFT, lalu solusi sukses yang skornya lebih baik.
- [ ] Replay dari hasil program memiliki snapshot/score identik dan validator memberikan status yang sama.
- [ ] Bukti integrasi menyebut rules/engine version dan batas yang belum diuji; tidak mengklaim G1 menyenangkan hanya dari test otomatis.
**Verifikasi:** Jalankan integration scenario melalui entry point domain nyata; simpan output gagal/sukses dan perbandingan skor.

### Checkpoint CP-02E — Core siap UI

- [ ] T021 terverifikasi; tidak ada ketergantungan domain pada frame rate atau blockchain.
- [ ] T022–T027 dapat menghubungkan UI pada engine yang sudah dibuktikan.
