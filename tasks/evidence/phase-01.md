# SIGNAL ZERO — Penutupan Fase 01

Tanggal: 5 November 2026. **Status: selesai, T001–T008 dan CP-01A–CP-01D.** Pengerjaan diotorisasi oleh instruksi pengguna untuk menuntaskan Fase 01. Keputusan mekanik/arsitektur dibuat sebagai delegasi desain implementasi; tidak diklaim sebagai pilihan pribadi owner pada setiap detail.

## Ringkasan hasil

| Task | Hasil konkret | Evidence |
|---|---|---|
| T001 | Rules `sz-rules-1`: emission tick0, movement tick1, SHIFT sebelum routing, sinkronisasi tepat tanpa latching, collision/terminal/tick limit tegas | [T001](T001.md) |
| T002 | Canonical puzzle/replay, hash SHA256, salted replay commitment, score `(SHIFT,ticks,actions)`, actions dari SHIFT final, attempt/achievement semantics | [T002](T002.md) |
| T003 | Scaffold Android/iOS/web, Flutter/Flame pins+lockfile, SDK-only package, shell normal berjalan di Chrome | [T003](T003.md) |
| T004 | Opt-in compatibility probe + sandboxed separate-site iframe; Drift persistence, file input/export, Canvas/pointer/audio dan offline-warm lulus Chrome | [T004](T004.md) |
| T005 | Dart headless/Shelf, PostgreSQL17, bounded jobs/private storage/migrations, verifier reuse dan runnable headless PoC | [T005](T005.md) |
| T006 | API/UTC/finality/reorg/privacy, EIP712 bindings, otorisasi relayer, wallet mobile/web, sponsor budget dan threat model | [T006](T006.md) |
| T007 | Numeric parser/graph/search/decompression/memory/time limits, unknown/optimal/unsat distinctions, bounded desktop probe | [T007](T007.md) |
| T008 | Tema/aturan/deadline/AI policy/source/platform dari sumber resmi diverifikasi dan dipetakan ke rilis | [T008](T008.md) |

## Verifikasi yang benar-benar berjalan

- Flutter analyze: **PASS**, no issues pada source akhir yang diperiksa.
- Flutter tests: **5 PASS** — shell guest dan 4 codec/invalid-file cases.
- Python contract tests: **6 PASS**.
- Checker spesifikasi: **13 rules cases, 35 snapshot, 3 normalisasi, 5 perbandingan, 20 boundary sets, 22 rejection descriptors PASS**. Ini oracle/kontrak fixture, bukan real engine.
- Canonical puzzle/replay/salted commitment dihitung ulang lintas Python dan PowerShell/.NET dengan hasil sama.
- Pure Dart SDK-only smoke dan headless JSON I/O PoC: **exit 0**, tanpa Flutter renderer atau engine produksi.
- Release build probe dan shell normal: **PASS** dengan renderer resource lokal. Build memiliki warning nonfatal Cupertino font tree-shaking; tercatat pada T003/T004 untuk packaging T094.
- Chrome **156.0.8078.80**: normal shell terlihat tanpa probe hook/console error. Probe direct dan iframe memakai sharedIndexedDb, data bertahan reload; export/import, invalid import, pointer, audio gesture/mute, offline-warm update lulus; **0 console errors / 0 failed requests** pada probe.
- Dart format check **8 files, 0 changed** dan syntax check runner Node lulus. Local link/status/asset hash/backlog consistency diperiksa sebagai penutupan.

Raw browser observations: [normal shell](T003-browser.json), [direct/iframe probe](T004-browser.json). Screenshot [shell](T003-foundation.png), [probe direct](T004-direct.png), [probe iframe](T004-iframe.png) sudah diinspeksi visual.

## Checkpoint

- **CP-01A PASS:** rules, skor, boundary dan golden examples tidak ambigu; independent review/hash cross-check selesai.
- **CP-01B PASS:** toolchain/commands nyata tersedia; shell dan spike browser berjalan, domain tetap headless, batas platform tercatat.
- **CP-01C PASS sebagai kontrak desain:** pilihan backend/API/wallet/gas/trust ditetapkan dan walkthrough direview; belum menjalankan integrasi backend/crypto/chain.
- **CP-01D PASS:** limits berdasarkan probe kecil dan aturan jam terverifikasi. Tidak ada token/NFT/aksi gameplay tambahan atau layanan wajib untuk guest.

## Batas yang tetap terbuka

Fase 01 menghasilkan fondasi, spesifikasi dan spike, **belum game playable**. Production engine/solver/schema, 15 level, progress storage produk, server, wallet integration, contract, transaksi, deployment, G1–G6 dan submission jam belum dikerjakan.

Android SDK tersedia namun lisensi belum seluruhnya diterima; iOS build/signing memerlukan Apple toolchain. Tidak menerima lisensi otomatis. Browser di luar Chrome desktop, perangkat mobile, hosting itch.io, private/evicted storage, offline reload/cold install dan target 60 FPS belum lulus. Headless audio hanya membuktikan API state/mute, bukan kualitas speaker. Hal ini dilacak pada task platform/data/wallet/hardening terkait, bukan disamarkan sebagai kelulusan.

Pilihan AppKit mobile belum dipasang atau diprovision; syarat license/vendor dan kompatibilitas native harus diuji T068. Sponsor disabled default dan cap angka adalah konfigurasi fixture, bukan izin belanja. Verifier/publisher tetap trust assumption; blockchain signature bukan bukti engine/rank trustless.

PRD asli tidak diubah; SHA-256 `055A7FA27E9D448E96FA9C9FD70805A3311EC1658AA213B28E8D0240589ADF8D`.

## Handoff Fase 02

Mulai **T009 — Schema puzzle terversi**, menggunakan rules/identity/limits dari Fase 01. Domain produksi berada di `packages/puzzle_domain`, dibagi oleh Flutter dan verifier; sesuaikan path rencana kartu tanpa menggandakan engine. T011 memakai oracle yang sudah ada lalu memperluasnya untuk real engine. Fase 02 belum dimulai oleh pekerjaan ini.
