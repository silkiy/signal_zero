# Validasi core headless SIGNAL ZERO

Engine `sz-engine-1`, rules `sz-rules-1`, puzzle `sz-puzzle-1`, replay `sz-replay-1`.

Fixture [playable-core.json](../../specs/test-vectors/playable-core.json) diturunkan secara manual dari aturan SHIFT sebelum routing, satu edge per tick, serta score T002. Python hanya mengemas snapshot yang ditulis manual; output engine tidak dijadikan expected oracle.

| Tahap | Program SHIFT | Hasil | Skor |
|---|---|---|---|
| Observe/simulate | `[]` | Gagal `TICK_LIMIT` pada tick 4 | Tidak ada |
| Program/analyze | `[4]` | Sukses pada tick 4 | `(1,4,1)` |
| Optimize | `[2]` | Sukses pada tick 2 | `(1,2,1)` |

Sinyal bergerak `a → s` pada tick 1. Tanpa SHIFT, routing `s → r → s` berulang. SHIFT pada tick 4 mengarahkan sinyal ke target saat kunjungan kedua; SHIFT pada tick 2 mengarahkannya saat kunjungan pertama. Kedua solusi memakai satu aksi, sehingga completion tick menentukan perbaikan skor.

Dari `packages/puzzle_domain`:

```powershell
dart test test/integration/headless_core_test.dart
dart test
dart analyze --fatal-infos
```

Integration test memakai runner produksi, serialisasi replay canonical dan dua CLI aktual dalam subprocess. Seluruh snapshot diverifikasi terhadap fixture manual. Solver juga harus membuktikan solusi `(1,2,1)` optimal untuk objektif leksikografis. Tes menguji program tersimpan dan jalur analyze; belum ada kontrol UI observe/program/simulate yang dapat dimainkan.

Batas domain: 64 node, 128 edge defensif, 8 source/target, 32 switch, 64 tick/SHIFT. Solver berhenti pada state/transisi/memori/waktu/pembatalan, melaporkan unknown ketika budget habis, dan menyediakan `solveAsync` yang memberi giliran ke event loop. Accounting memori bukan pengukuran process RSS atau batas keras heap VM. Integrasi service tetap memerlukan worker/watchdog sesuai T007.

Tiga level awal berada pada `apps/game/assets/levels`. File tersebut adalah envelope konten `sz-curated-1`: `puzzle` berisi gameplay terversi; title, fokus belajar, posisi layout, solusi lokal dan baseline berada di luar identitas puzzle. Validator CLI menerima child `puzzle`, bukan seluruh envelope. Aset dan solusi ini masih konten lokal pengembangan.

Fase ini membuktikan core tanpa renderer. Hasil otomatis belum membuktikan game menyenangkan (G1), parity client/verifier produksi (G2), generator (G3), wallet/chain (G4), atau kelayakan rilis/mobile. Timeline, kontrol, progress, onboarding dan playtest tetap mengikuti Fase 03.
