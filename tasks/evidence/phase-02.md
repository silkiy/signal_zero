# Fase 02 — Selesai dan siap dihubungkan ke UI

Tanggal: 6 November 2026 (Asia/Jakarta). **T009–T021 selesai**, dengan **satu commit per task** sesuai instruksi owner. Package domain `packages/puzzle_domain` digunakan bersama; tidak ada engine atau scoring kedua di Flutter/tooling. PRD asli tetap utuh.

| Task | Hasil | Commit |
|---|---|---|
| [T009](T009.md) | Schema puzzle, canonical JSON/hash, batas input | `c87ea2e` |
| [T010](T010.md) | Replay terversi, canonical program, commitment salted | `f408e0e` |
| [T011](T011.md) | 14 golden vectors / 38 snapshot manual | `01fe470` |
| [T012](T012.md) | State immutable dan pergerakan serentak satu tick | `335738d` |
| [T013](T013.md) | SHIFT global sebelum routing | `e940f44` |
| [T014](T014.md) | Collision, sync, target dan prioritas terminal | `b6a46c1` |
| [T015](T015.md) | Replay/snapshot deterministik, normalisasi tervalidasi | `5aaa615` |
| [T016](T016.md) | Skor leksikografis dari run sukses | `54e59b3` |
| [T017](T017.md) | Solver optimal terbatas, budget kumulatif, async cancellation | `6765475` |
| [T018](T018.md) | Seeded properties, enumerasi kecil, regresi dan parity VM/JS | `5ec4f61` |
| [T019](T019.md) | CLI validator/replay dengan output JSON dan exit code | `3512c3f` |
| [T020](T020.md) | Tiga asset level dengan solusi dan baseline optimal terbukti | `40a4a25` |
| [T021](T021.md) | Alur gagal → solusi → optimasi, verifikasi penutup | Commit ini, berlabel `T021` |

## Hasil verifikasi

| Pemeriksaan | Hasil |
|---|---|
| Seluruh test domain termasuk subprocess dan integrasi | **248 PASS** |
| Domain analyzer `--fatal-infos` | **No issues found** |
| Seluruh test Flutter termasuk bundle level | **8 PASS** |
| Flutter analyzer | **No issues found** |
| Flutter Web release build, resource lokal | **PASS** |
| Checker spesifikasi asli + Python unit tests | **PASS + 6 PASS** |
| Dart VM vs JavaScript hasil kompilasi | **14 kasus / 38 snapshot identik** |
| Validator + replay ketiga level | **6 invokasi exit 0**, skor `(0,1,0)`, `(0,3,0)`, `(0,4,0)` |
| Integrasi routing | `[]` gagal; `[4]` sukses `(1,4,1)`; `[2]` sukses optimal `(1,2,1)` |
| Mutation experiments | Prioritas terminal/score/heap, accounting normalisasi, SHIFT order, exit code, konten dan timing semuanya terdeteksi; source dipulihkan |
| PRD fingerprint | Tetap `055A7FA27E9D448E96FA9C9FD70805A3311EC1658AA213B28E8D0240589ADF8D` |

Perintah nyata dan batas klaim ada pada evidence per task serta [walkthrough headless](../../docs/validation/playable-core.md). Checkpoint CP-02A–CP-02E lulus. Proyek kini **21 done / 79 todo**. T022 (shell/navigasi) menjadi langkah berikut; T023–T027 dapat memakai API domain yang terverifikasi.

## Batas hasil

Default aplikasi masih shell fondasi; board, timeline, kontrol dan progress belum dikerjakan. Fase ini tidak mengklaim G1 atau readiness game untuk pemain. Solver dapat mengembalikan budget exhausted pada graph valid; accounting memori bukan process RSS/hard heap limit. Benchmark desktop dan parity corpus tidak menjamin semua graph, perangkat, browser, atau service produksi. UI runtime/playtest, verifier G2, generator G3, chain G4, mobile dan release gates mengikuti task terkait.

Tidak ada dependency yang dinaikkan, service/deployment dipublikasikan, transaksi wallet dikirim, atau submission jam dilakukan. Build dan probe lokal yang diabaikan Git bukan artifact rilis resmi.
