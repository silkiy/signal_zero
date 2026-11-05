# Traceability PRD v2.2 → task

Pemetaan ini memeriksa cakupan rencana, **bukan status implementasi**. Semua ID mengacu ke checklist [todo.md](todo.md) dan kartu pada [plan.md](plan.md). Sumber tunggal requirement: [PRD v2.2](../SIGNAL_ZERO_PRD_v2.2.md).

## Functional requirements

| FR | Prioritas PRD | Task pemilik dan verifikasi |
|---|---|---|
| FR-001 Deterministic tick simulation | P0 | T001, T009, T011–T015, T018, T021, T025, T092; ekuivalensi verifier T058 |
| FR-002 Global SHIFT routing | P0 | T001, T013, T018, T024, T030 |
| FR-003 Timeline programming + step | P0 | T010, T024, T025 |
| FR-004 Undo/reset/replay lokal | P0 | T010, T015, T026, T092 |
| FR-005 Completion + scoring | P0 | T002, T014, T016, T027 |
| FR-006 15 curated/tutorial/mastery levels | P0 | T019, T020, T029–T033, T037, T097 |
| FR-007 Procedural Holographic Circuit | P0 | T023, T034, T089 |
| FR-008 Guest profile + local progress | P0 | T022, T028; perluasan/recovery T047, T048, T050, T055, T091 |
| FR-009 Puzzle solver | P0 | T007, T017–T019; pemakaian editor T043 |
| FR-010 Procedural generator | P1 | T038–T040, T046 |
| FR-011 Three-stage progressive hints | P1 | T041, T043, T046, T065 |
| FR-012 Identical Daily Challenge | P1 | T057, T061, T063, T065, T066 |
| FR-013 Verified leaderboard + shared rank | P1 | T056, T058–T060, T062, T063, T067, T071–T073, T077 |
| FR-014 Wallet + Base submission | P1 | T006, T050, T059, T060, T067–T069, T074, T075 |
| FR-015 Hybrid gas | P1 | T006, T070, T076, T077 |
| FR-016 Post-challenge replay reveal | P1 | T059, T063–T065, T072, T084–T086 |
| FR-017 Weekly Points Tournament | P1 | T078–T080, T086 |
| FR-018 Hybrid achievements | P1 | T049, T081–T083, T086 |
| FR-019 Editor + Share Code | P1 | T042–T046, T047, T054, T055 |
| FR-020 `.szsave` backup/import | P1 | T047, T051–T055, T091 |
| FR-021 Replay sharing | P2 | T098; terpisah dari required reveal viewer T084 |
| FR-022 Advanced procedural audio | P2 | T099; audio dasar §9 adalah T035 |
| FR-023 Accessibility/customization | P1 | T036, T090; bentuk/non-color minimum saat T023/T034 |
| FR-024 Diagnostics/analytics | P1 | T074, T088, T100 |

## User stories dan acceptance PRD §15

| US | Bukti yang diminta | Task |
|---|---|---|
| US-01 Belajar SHIFT | Tutorial bertahap, progress tersimpan | T028–T030, T037 |
| US-02 Replay identik | State akhir dan score selalu sama untuk input/version sama | T011, T015, T018, T026, T058, T092 |
| US-03 Puzzle baru | Semua puzzle terbit solver-verified | T017, T038–T040, T046, T057 |
| US-04 Hint | Tiga tahap berurutan, tidak mengubah state | T041, T043 |
| US-05 Puzzle kompetisi identik | Daily ID mengikat hash sama | T057, T061, T065, T066 |
| US-06 Skor identik adil | Competition rank tanpa timestamp tie-breaker | T062, T072, T079, T080 |
| US-07 Replay tidak bocor | API privat; actions tidak masuk calldata/event | T006, T059, T064, T067, T069, T077, T085 |
| US-08 Guest bermain | Core tanpa wallet | T022, T028, T050, T055, T065, T068, T097 |
| US-09 Kreator berbagi puzzle | Share Code menghasilkan spec/hash identik | T044–T046, T054, T055 |
| US-10 Pindah progress | Backup tervalidasi + preview + merge/restore + prebackup | T051–T055, T091 |
| US-11 Weekly points | Poin dari daily standings final | T078–T080, T086 |
| US-12 Achievement tanpa paksaan gas | Local otomatis; claim on-chain opsional | T049, T081–T083 |

## NFR, risiko, dan keputusan lintas fitur

| Requirement PRD §14/§18/§20 | Task |
|---|---|
| 60 FPS mobile kelas menengah; pooling/adaptive/reduced effects | T034–T036, T089, T093 |
| Determinism native/web dan versi historis | T002, T011, T018, T058, T092 |
| Offline campaign/practice/editor/progress | T022, T028, T042, T045, T046, T055, T091 |
| Autosave, schema migrations, recovery | T028, T047, T048, T053, T054, T091 |
| Tidak ada wallet secrets dalam backup | T047, T050–T054, T068, T088 |
| Batas input, solver dan compression bomb | T007, T009, T010, T017, T043, T044, T052, T054, T059 |
| Indexed/paginated leaderboard | T062, T071, T072, T080 |
| Non-color indicators, contrast, audio toggle, speed | T023, T025, T034–T036, T090 |
| Unit/property/integration/golden/contract tests | T011, T018, T021, T040, T054, T058, T066, T073, T076, T077, T082, T086, T092 |
| Web compatibility sejak awal + itch iframe | T004, T094 |
| Mobile Android/iOS platform testing | T093; keterbatasan toolchain tetap pending |
| Daily UTC, shared rank dan finality/reorg | T006, T057, T062, T063, T071, T072, T077 |
| Weekly calendar/fairness + final results only | T078, T079, T086 |
| Private replay sampai final + retention/publication | T059, T064, T084, T085 |
| EIP-712 bindings, nonce, expiry, wrong-wallet/replay protection | T006, T060, T067, T073, T077, T081, T082 |
| User-paid/sponsor auth, quota, rate limit, global cap, fallback | T006, T069, T070, T076 |
| Verifier trust, signer rotation, secure keys, monitoring/review | T006, T058, T074, T077, T088, T095 |
| Chain/backend outage tidak menghentikan core | T055, T065, T068, T075, T091 |
| Privacy/consent analytics dan metrik hipotesis | T037, T088, T089, T097, T100 |
| Jam theme/rules/deadline/AI policy belum diverifikasi | T008, T096 |

## Definition of Done PRD §21

| Item DoD | Task pembukti |
|---|---|
| SHIFT/timeline engine deterministik | T013, T018, T024, T025, T092 |
| 15 curated levels playable | T020, T029–T033, T097 |
| Solver dan generator valid | T017–T019, T038–T040 |
| Holographic Circuit terbaca/responsif | T023, T034, T089, T090 |
| Progressive hints noncompetitive | T041, T043, T065 |
| Guest offline progress | T028, T055, T091 |
| Daily identical + verified submission | T057–T060, T065–T069, T072, T077 |
| Shared rank | T062, T072, T079, T080 |
| Replay reveal sesudah challenge dan final | T063, T064, T084–T086 |
| Weekly Points dari final daily | T078–T080, T086 |
| Hybrid achievements | T049, T081–T083 |
| Editor + Share Code | T042–T046, T054 |
| Backup `.szsave` | T051–T055, T091 |
| Wallet optional | T022, T050, T055, T065, T068, T083 |
| Platform testing/jam compliance | T004, T008, T090, T092–T097 |

T100 mengaudit keseluruhan DoD ini. P0/G5 adalah paket minimum; tidak setara seluruh DoD Ambitious Release. FR-021/FR-022 P2 tetap tercatat tetapi tidak menjadi syarat P1/G6.
