# SIGNAL ZERO — Task checklist

Sumber: [plan.md](plan.md) dan [PRD v2.2](../SIGNAL_ZERO_PRD_v2.2.md). Status proyek: **11 done / 89 todo**. Checkbox dicentang hanya setelah AC, verifikasi, dan review lulus. Laporan: [phase-01.md](evidence/phase-01.md).

Status yang dipakai: `todo`, `in_progress`, `review`, `done`, `blocked`. Ubah status/owner/evidence pada baris task. Dependency harus `done` sebelum task diambil. ID lebih besar boleh dikerjakan lebih dahulu jika siap.

**Langkah berikut yang direkomendasikan:** T012 (Fase 02). Fase 01 selesai; Fase 02 sedang berjalan.

**Jumlah:** 100 task — 40 P0, 58 P1, 2 P2.

Template penugasan: [agent-task-template.md](agent-task-template.md). Pemetaan requirement: [coverage.md](coverage.md).

## Fase 01 — Keputusan dan fondasi

- [x] [T001 — Formalisasi aturan simulasi](phases/01-foundation.md#t001) · **P0** · deps: tidak ada · status: `done` · owner: root/team · evidence: [T001.md](evidence/T001.md)
- [x] [T002 — Tetapkan identitas versi dan normalisasi skor](phases/01-foundation.md#t002) · **P0** · deps: T001 · status: `done` · owner: root/team · evidence: [T002.md](evidence/T002.md)
- [x] [T003 — Siapkan workspace dan perintah verifikasi dasar](phases/01-foundation.md#t003) · **P0** · deps: tidak ada · status: `done` · owner: root/team · evidence: [T003.md](evidence/T003.md)
- [x] [T004 — Spike kompatibilitas Flutter Web](phases/01-foundation.md#t004) · **P0** · deps: T003 · status: `done` · owner: root/team · evidence: [T004.md](evidence/T004.md)
- [x] [T005 — Putuskan stack backend dan strategi verifier](phases/01-foundation.md#t005) · **P1** · deps: T001, T002, T003 · status: `done` · owner: root/team · evidence: [T005.md](evidence/T005.md)
- [x] [T006 — Tetapkan protokol kompetisi dan otorisasi wallet](phases/01-foundation.md#t006) · **P1** · deps: T002, T005, T007 · status: `done` · owner: root/team · evidence: [T006.md](evidence/T006.md)
- [x] [T007 — Tetapkan batas sumber daya dan validasi](phases/01-foundation.md#t007) · **P0** · deps: T001, T002 · status: `done` · owner: root/team · evidence: [T007.md](evidence/T007.md)
- [x] [T008 — Verifikasi tema dan aturan resmi game jam](phases/01-foundation.md#t008) · **P0** · deps: tidak ada · status: `done` · owner: root/team · evidence: [T008.md](evidence/T008.md)
## Fase 02 — Domain, engine, dan solver dasar

- [x] [T009 — Schema puzzle terversi](phases/02-core-engine.md#t009) · **P0** · deps: T001, T002, T003, T007 · status: `done` · owner: root/team · evidence: [T009.md](evidence/T009.md)
- [x] [T010 — Schema replay dan normalisasi program](phases/02-core-engine.md#t010) · **P0** · deps: T002, T003, T007, T009 · status: `done` · owner: root/team · evidence: [T010.md](evidence/T010.md)
- [x] [T011 — Golden vectors rules dan replay](phases/02-core-engine.md#t011) · **P0** · deps: T001, T002, T009, T010 · status: `done` · owner: root/team · evidence: [T011.md](evidence/T011.md)
- [ ] [T012 — Engine gerak sinyal satu tick](phases/02-core-engine.md#t012) · **P0** · deps: T003, T009, T011 · status: `todo` · owner: — · evidence: —
- [ ] [T013 — SHIFT global sebelum pergerakan](phases/02-core-engine.md#t013) · **P0** · deps: T010, T012 · status: `todo` · owner: — · evidence: —
- [ ] [T014 — Evaluasi target dan terminal state](phases/02-core-engine.md#t014) · **P0** · deps: T001, T012, T013 · status: `todo` · owner: — · evidence: —
- [ ] [T015 — Snapshot dan replay lokal deterministik](phases/02-core-engine.md#t015) · **P0** · deps: T010, T014 · status: `todo` · owner: — · evidence: —
- [ ] [T016 — Skor leksikografis dari program final](phases/02-core-engine.md#t016) · **P0** · deps: T002, T010, T014 · status: `todo` · owner: — · evidence: —
- [ ] [T017 — Solver terbatas dengan status optimalitas jelas](phases/02-core-engine.md#t017) · **P0** · deps: T007, T014, T016 · status: `todo` · owner: — · evidence: —
- [ ] [T018 — Property tests engine dan solver](phases/02-core-engine.md#t018) · **P0** · deps: T011, T015, T016, T017 · status: `todo` · owner: — · evidence: —
- [ ] [T019 — Validator headless untuk puzzle dan replay](phases/02-core-engine.md#t019) · **P0** · deps: T009, T010, T015, T016, T017 · status: `todo` · owner: — · evidence: —
- [ ] [T020 — Curated levels 1–3](phases/02-core-engine.md#t020) · **P0** · deps: T019 · status: `todo` · owner: — · evidence: —
- [ ] [T021 — Vertical slice headless satu puzzle](phases/02-core-engine.md#t021) · **P0** · deps: T018, T019, T020 · status: `todo` · owner: — · evidence: —
## Fase 03 — Game playable, onboarding, dan 15 level

- [ ] [T022 — Shell Flutter dan navigasi guest-first](phases/03-playable-game.md#t022) · **P0** · deps: T003, T004 · status: `todo` · owner: — · evidence: —
- [ ] [T023 — Board jaringan minimal dari snapshot](phases/03-playable-game.md#t023) · **P0** · deps: T009, T015, T021, T022 · status: `todo` · owner: — · evidence: —
- [ ] [T024 — Edit SHIFT pada timeline](phases/03-playable-game.md#t024) · **P0** · deps: T010, T022, T023 · status: `todo` · owner: — · evidence: —
- [ ] [T025 — Play, pause, step, dan kecepatan](phases/03-playable-game.md#t025) · **P0** · deps: T015, T023, T024 · status: `todo` · owner: — · evidence: —
- [ ] [T026 — Undo, reset, dan replay lokal](phases/03-playable-game.md#t026) · **P0** · deps: T024, T025 · status: `todo` · owner: — · evidence: —
- [ ] [T027 — Hasil permainan dan preview skor](phases/03-playable-game.md#t027) · **P0** · deps: T014, T016, T025, T026 · status: `todo` · owner: — · evidence: —
- [ ] [T028 — Guest profile dan autosave progress minimum](phases/03-playable-game.md#t028) · **P0** · deps: T004, T022, T027 · status: `todo` · owner: — · evidence: —
- [ ] [T029 — Tutorial interaktif bertahap](phases/03-playable-game.md#t029) · **P0** · deps: T020, T025, T027, T028 · status: `todo` · owner: — · evidence: —
- [ ] [T030 — Curated levels 4–6: SHIFT dan routing](phases/03-playable-game.md#t030) · **P0** · deps: T019, T024, T029 · status: `todo` · owner: — · evidence: —
- [ ] [T031 — Curated levels 7–9: timing dan sinkronisasi](phases/03-playable-game.md#t031) · **P0** · deps: T014, T019, T030 · status: `todo` · owner: — · evidence: —
- [ ] [T032 — Curated levels 10–12: multi-signal dan optimasi](phases/03-playable-game.md#t032) · **P0** · deps: T019, T027, T031 · status: `todo` · owner: — · evidence: —
- [ ] [T033 — Curated levels 13–15: mastery](phases/03-playable-game.md#t033) · **P0** · deps: T019, T032 · status: `todo` · owner: — · evidence: —
- [ ] [T034 — Visual procedural Holographic Circuit](phases/03-playable-game.md#t034) · **P0** · deps: T023, T025, T027 · status: `todo` · owner: — · evidence: —
- [ ] [T035 — Audio procedural dasar dan mute](phases/03-playable-game.md#t035) · **P0** · deps: T004, T025, T027, T028 · status: `todo` · owner: — · evidence: —
- [ ] [T036 — Kontrol aksesibel dan preferensi dasar](phases/03-playable-game.md#t036) · **P1** · deps: T023, T024, T025, T028, T034, T035 · status: `todo` · owner: — · evidence: —
- [ ] [T037 — Playtest core dan keputusan G1](phases/03-playable-game.md#t037) · **P0** · deps: T027, T028, T029, T030 · status: `todo` · owner: — · evidence: —
## Fase 04 — Puzzle procedural, hint, dan creator

- [ ] [T038 — Generator kandidat deterministik](phases/04-content-creator.md#t038) · **P1** · deps: T007, T009, T017 · status: `todo` · owner: — · evidence: —
- [ ] [T039 — Filter validitas, difficulty, dan kemiripan](phases/04-content-creator.md#t039) · **P1** · deps: T016, T017, T038 · status: `todo` · owner: — · evidence: —
- [ ] [T040 — Property test generator dan bukti G3](phases/04-content-creator.md#t040) · **P1** · deps: T018, T039 · status: `todo` · owner: — · evidence: —
- [ ] [T041 — Hint tiga tahap dengan batas mode](phases/04-content-creator.md#t041) · **P1** · deps: T010, T017, T025, T036 · status: `todo` · owner: — · evidence: —
- [ ] [T042 — Editor graph dengan draft lokal](phases/04-content-creator.md#t042) · **P1** · deps: T007, T009, T022, T023, T047 · status: `todo` · owner: — · evidence: —
- [ ] [T043 — Test play dan solver validation editor](phases/04-content-creator.md#t043) · **P1** · deps: T017, T025, T027, T041, T042 · status: `todo` · owner: — · evidence: —
- [ ] [T044 — Format Share Code yang versioned](phases/04-content-creator.md#t044) · **P1** · deps: T002, T007, T009 · status: `todo` · owner: — · evidence: —
- [ ] [T045 — Ekspor dan impor Share Code dalam UI](phases/04-content-creator.md#t045) · **P1** · deps: T022, T042, T044, T047 · status: `todo` · owner: — · evidence: —
- [ ] [T046 — Alur practice dan creator end-to-end](phases/04-content-creator.md#t046) · **P1** · deps: T027, T040, T041, T043, T045 · status: `todo` · owner: — · evidence: —
## Fase 05 — Data lokal, achievements, dan backup

- [ ] [T047 — Perluasan schema Drift dan migrasi](phases/05-local-data.md#t047) · **P1** · deps: T002, T004, T009, T010, T028 · status: `todo` · owner: — · evidence: —
- [ ] [T048 — Autosave dan pemulihan data lokal](phases/05-local-data.md#t048) · **P1** · deps: T036, T047 · status: `todo` · owner: — · evidence: —
- [ ] [T049 — Enam local achievements otomatis](phases/05-local-data.md#t049) · **P1** · deps: T002, T016, T017, T027, T042, T044, T047 · status: `todo` · owner: — · evidence: —
- [ ] [T050 — Adapter identity guest dan wallet](phases/05-local-data.md#t050) · **P1** · deps: T002, T047 · status: `todo` · owner: — · evidence: —
- [ ] [T051 — Ekspor backup `.szsave`](phases/05-local-data.md#t051) · **P1** · deps: T002, T007, T047 · status: `todo` · owner: — · evidence: —
- [ ] [T052 — Validasi dan preview impor `.szsave`](phases/05-local-data.md#t052) · **P1** · deps: T007, T047, T051 · status: `todo` · owner: — · evidence: —
- [ ] [T053 — Merge atau restore secara transaksional](phases/05-local-data.md#t053) · **P1** · deps: T048, T051, T052 · status: `todo` · owner: — · evidence: —
- [ ] [T054 — Pengujian input berbahaya dan migrasi backup](phases/05-local-data.md#t054) · **P1** · deps: T044, T047, T053 · status: `todo` · owner: — · evidence: —
- [ ] [T055 — Pembuktian alur lokal sepenuhnya offline](phases/05-local-data.md#t055) · **P1** · deps: T028, T046, T048, T049, T050, T053, T054 · status: `todo` · owner: — · evidence: —
## Fase 06 — Daily Challenge, verifier, dan privasi replay

- [ ] [T056 — Bootstrap backend dan penyimpanan kompetisi](phases/06-daily-verifier.md#t056) · **P1** · deps: T003, T005, T006 · status: `todo` · owner: — · evidence: —
- [ ] [T057 — Publikasi puzzle Daily dan scheduler UTC](phases/06-daily-verifier.md#t057) · **P1** · deps: T009, T017, T039, T056 · status: `todo` · owner: — · evidence: —
- [ ] [T058 — Verifier backend identik dengan engine klien](phases/06-daily-verifier.md#t058) · **P1** · deps: T005, T010, T011, T016, T018, T019, T056 · status: `todo` · owner: — · evidence: —
- [ ] [T059 — Intake replay privat dengan autentikasi wallet](phases/06-daily-verifier.md#t059) · **P1** · deps: T006, T007, T056, T057, T058, T085 · status: `todo` · owner: — · evidence: —
- [ ] [T060 — Signed attestation EIP-712 dari hasil verifier](phases/06-daily-verifier.md#t060) · **P1** · deps: T002, T006, T058, T059 · status: `todo` · owner: — · evidence: —
- [ ] [T061 — API Daily metadata dan archive untuk guest](phases/06-daily-verifier.md#t061) · **P1** · deps: T057 · status: `todo` · owner: — · evidence: —
- [ ] [T062 — Proyeksi best score dan shared rank berpaginasi](phases/06-daily-verifier.md#t062) · **P1** · deps: T016, T056, T059 · status: `todo` · owner: — · evidence: —
- [ ] [T063 — Worker finalisasi Daily yang idempotent](phases/06-daily-verifier.md#t063) · **P1** · deps: T006, T057, T062 · status: `todo` · owner: — · evidence: —
- [ ] [T064 — Reveal replay hanya setelah snapshot final](phases/06-daily-verifier.md#t064) · **P1** · deps: T059, T063, T085 · status: `todo` · owner: — · evidence: —
- [ ] [T065 — Layar Daily, leaderboard, dan archive](phases/06-daily-verifier.md#t065) · **P1** · deps: T022, T025, T028, T041, T061, T062 · status: `todo` · owner: — · evidence: —
- [ ] [T066 — Integrasi keamanan Daily dan bukti G2](phases/06-daily-verifier.md#t066) · **P1** · deps: T058, T060, T063, T064, T065 · status: `todo` · owner: — · evidence: —
## Fase 07 — Kontrak, wallet, sponsorship, dan indexer

- [ ] [T067 — Kontrak leaderboard untuk best verified score](phases/07-chain-wallet.md#t067) · **P1** · deps: T003, T006, T060 · status: `todo` · owner: — · evidence: —
- [ ] [T068 — Adapter wallet opsional yang mempertahankan guest](phases/07-chain-wallet.md#t068) · **P1** · deps: T004, T006, T022, T028, T050 · status: `todo` · owner: — · evidence: —
- [ ] [T069 — Submission user-paid dari klien ke Base Sepolia](phases/07-chain-wallet.md#t069) · **P1** · deps: T060, T065, T067, T068 · status: `todo` · owner: — · evidence: —
- [ ] [T070 — Sponsorship submission pertama dengan otorisasi wallet](phases/07-chain-wallet.md#t070) · **P1** · deps: T006, T007, T059, T067, T069 · status: `todo` · owner: — · evidence: —
- [ ] [T071 — Indexer canonical events dengan reorg dan backfill](phases/07-chain-wallet.md#t071) · **P1** · deps: T006, T056, T067 · status: `todo` · owner: — · evidence: —
- [ ] [T072 — Ranking resmi dari event canonical dan finalisasi nyata](phases/07-chain-wallet.md#t072) · **P1** · deps: T062, T063, T064, T069, T071 · status: `todo` · owner: — · evidence: —
- [ ] [T073 — Fuzz dan invariants kontrak leaderboard](phases/07-chain-wallet.md#t073) · **P1** · deps: T067 · status: `todo` · owner: — · evidence: —
- [ ] [T074 — Operasi signer, rotasi, dan runbook insiden](phases/07-chain-wallet.md#t074) · **P1** · deps: T006, T060, T067 · status: `todo` · owner: — · evidence: —
- [ ] [T075 — Pemulihan transaksi dan chain outage di klien](phases/07-chain-wallet.md#t075) · **P1** · deps: T048, T069, T071 · status: `todo` · owner: — · evidence: —
- [ ] [T076 — Uji abuse sponsorship dan biaya terbatas](phases/07-chain-wallet.md#t076) · **P1** · deps: T070, T074 · status: `todo` · owner: — · evidence: —
- [ ] [T077 — Gate G4: alur kompetisi adversarial end-to-end](phases/07-chain-wallet.md#t077) · **P1** · deps: T066, T072, T073, T074, T075, T076 · status: `todo` · owner: — · evidence: —
## Fase 08 — Weekly Tournament, achievement, dan reveal lengkap

- [ ] [T078 — Kalender Weekly dan simulasi fairness points](phases/08-tournament-achievements.md#t078) · **P1** · deps: T002, T006 · status: `todo` · owner: — · evidence: —
- [ ] [T079 — Akumulasi weekly dari snapshot Daily final](phases/08-tournament-achievements.md#t079) · **P1** · deps: T063, T072, T078 · status: `todo` · owner: — · evidence: —
- [ ] [T080 — API dan layar Weekly Tournament](phases/08-tournament-achievements.md#t080) · **P1** · deps: T022, T062, T079 · status: `todo` · owner: — · evidence: —
- [ ] [T081 — Eligibility achievement on-chain dari hasil final](phases/08-tournament-achievements.md#t081) · **P1** · deps: T060, T063, T079 · status: `todo` · owner: — · evidence: —
- [ ] [T082 — Registry achievement terpisah dengan claim aman](phases/08-tournament-achievements.md#t082) · **P1** · deps: T067, T073, T081 · status: `todo` · owner: — · evidence: —
- [ ] [T083 — Layar achievement dan claim wallet opsional](phases/08-tournament-achievements.md#t083) · **P1** · deps: T049, T068, T081, T082 · status: `todo` · owner: — · evidence: —
- [ ] [T084 — Pemutar replay reveal dengan perbandingan skor](phases/08-tournament-achievements.md#t084) · **P1** · deps: T015, T025, T026, T064, T065 · status: `todo` · owner: — · evidence: —
- [ ] [T085 — Kebijakan retensi dan publikasi storage replay](phases/08-tournament-achievements.md#t085) · **P1** · deps: T006, T007 · status: `todo` · owner: — · evidence: —
- [ ] [T086 — Integrasi rollover Daily, Weekly, dan reveal](phases/08-tournament-achievements.md#t086) · **P1** · deps: T072, T079, T080, T081, T084 · status: `todo` · owner: — · evidence: —
- [ ] [T087 — Kandidat integrasi seluruh P1](phases/08-tournament-achievements.md#t087) · **P1** · deps: T040, T041, T046, T055, T077, T080, T083, T084, T086 · status: `todo` · owner: — · evidence: —
## Fase 09 — Hardening, paket rilis, dan polish

- [ ] [T088 — Diagnostics lokal dan analytics berbasis persetujuan](phases/09-hardening-release.md#t088) · **P1** · deps: T028, T036, T047, T059 · status: `todo` · owner: — · evidence: —
- [ ] [T089 — Profiling dan optimasi frame budget](phases/09-hardening-release.md#t089) · **P0** · deps: T033, T034, T035 · status: `todo` · owner: — · evidence: —
- [ ] [T090 — Audit accessibility dan customization](phases/09-hardening-release.md#t090) · **P1** · deps: T036, T046, T065, T080, T083, T084 · status: `todo` · owner: — · evidence: —
- [ ] [T091 — Uji ketahanan data lokal dan recovery](phases/09-hardening-release.md#t091) · **P1** · deps: T048, T053, T054, T055 · status: `todo` · owner: — · evidence: —
- [ ] [T092 — Jalankan matriks determinisme lintas platform](phases/09-hardening-release.md#t092) · **P0** · deps: T018, T019, T026, T033 · status: `todo` · owner: — · evidence: —
- [ ] [T093 — Smoke test paket mobile](phases/09-hardening-release.md#t093) · **P0** · deps: T037, T089, T092 · status: `todo` · owner: — · evidence: —
- [ ] [T094 — Siapkan paket web itch.io](phases/09-hardening-release.md#t094) · **P0** · deps: T004, T037, T089, T092 · status: `todo` · owner: — · evidence: —
- [ ] [T095 — Review keamanan kontrak dan batas trust](phases/09-hardening-release.md#t095) · **P1** · deps: T066, T073, T074, T076, T077, T082, T085 · status: `todo` · owner: — · evidence: —
- [ ] [T096 — Lengkapi paket instruksi dan kepatuhan jam](phases/09-hardening-release.md#t096) · **P0** · deps: T008, T093, T094 · status: `todo` · owner: — · evidence: —
- [ ] [T097 — Validasi kandidat rilis minimum G5](phases/09-hardening-release.md#t097) · **P0** · deps: T017, T033, T037, T089, T092, T093, T094, T096 · status: `todo` · owner: — · evidence: —
- [ ] [T098 — Bagikan replay nonkompetitif](phases/09-hardening-release.md#t098) · **P2** · deps: T010, T015, T044, T064, T084, T085 · status: `todo` · owner: — · evidence: —
- [ ] [T099 — Polish audio procedural lanjutan](phases/09-hardening-release.md#t099) · **P2** · deps: T035, T089 · status: `todo` · owner: — · evidence: —
- [ ] [T100 — Audit akhir Ambitious Release G6](phases/09-hardening-release.md#t100) · **P1** · deps: T040, T046, T055, T087, T088, T089, T090, T091, T092, T093, T094, T095, T096, T097 · status: `todo` · owner: — · evidence: —
