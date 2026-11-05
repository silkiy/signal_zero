# SIGNAL ZERO — Product Requirements Document (PRD)

**Version:** 2.2 (Final Consolidated)  
**Date:** 2026-11-05  
**Status:** Baseline implementasi  
**Target:** Game Off 2026  
**Stack:** Flutter, Flame, Solidity, Foundry, Base  
**Platforms:** Android/iOS; web build untuk itch.io jika kompatibel

## 1. Executive Summary

SIGNAL ZERO adalah game logic-puzzle strategi berbasis jaringan sinyal. Pemain memprogram waktu satu perintah global, **SHIFT**, untuk mengubah routing switch dan menyinkronkan sinyal pada target. Permainan mudah dipelajari tetapi menawarkan optimasi mendalam. Visual dan audio dihasilkan secara procedural tanpa aset eksternal. Gameplay utama tersedia offline dan tanpa wallet; kompetisi on-chain di Base bersifat opsional.

### Product goals
- Pemain memahami sinyal, node, SHIFT, dan target lewat tutorial interaktif.
- Puzzle valid, deterministik, strategis, dan tidak repetitif.
- Daily Challenge adil dengan puzzle identik dan skor terverifikasi.
- Pemain dapat bermain sebagai guest tanpa akun, wallet, atau internet.
- Visual Holographic Circuit menarik tetapi tetap terbaca dan ringan.

### Non-goals
Tidak ada token, NFT, pay-to-win, trading, multiplayer real-time, atau kewajiban menggunakan blockchain pada rilis awal.

## 2. Target Users & Problems

| Persona | Kebutuhan |
|---|---|
| Casual Puzzle Player | Sesi singkat, onboarding mudah, rasa pencapaian |
| Strategy Optimizer | Puzzle mendalam dan pencarian solusi efisien |
| Puzzle Creator | Editor sederhana, test play, dan Share Code |
| Competitive Player | Tantangan identik, leaderboard transparan, pengakuan prestasi |

**Problem statement:** Game puzzle sering repetitif setelah mekanik dipahami; game strategi yang dalam sering terlalu rumit. SIGNAL ZERO menggunakan satu aksi global dengan konsekuensi temporal dan spasial yang kaya.

## 3. Core Gameplay

### 3.1 Core loop
1. **Observe:** Periksa sumber, target, switch, jalur, dan batas tick.
2. **Program:** Tempatkan SHIFT pada timeline.
3. **Simulate:** Jalankan simulasi deterministik.
4. **Analyze:** Amati hasil dan penyebab kegagalan.
5. **Optimize:** Ubah program untuk menekan SHIFT, tick, dan actions.

### 3.2 Mechanics
- Jaringan terarah terdiri atas source, node, edge, switch, dan target.
- Sinyal bergerak maksimal satu edge per tick.
- SHIFT mengubah state seluruh switch pada kelompok global secara serentak.
- Pemain mengatur *kapan* SHIFT terjadi, bukan mengubah setiap switch sendiri.
- Puzzle berhasil ketika semua target memenuhi kondisi sinkronisasi.
- Puzzle gagal jika batas tick terlewati atau mencapai terminal failure state.
- Detail tabrakan, sinkronisasi, dan node khusus wajib diformalkan serta diuji sebelum level final.

### 3.3 Deterministic tick order
1. Baca SHIFT pada tick aktif.
2. Terapkan perubahan switch serentak.
3. Tentukan koneksi aktif.
4. Gerakkan sinyal serentak.
5. Evaluasi target, collision, dan failure.
6. Catat snapshot untuk replay/debugging.

Simulasi tidak boleh bergantung pada frame rate atau interpolasi visual.

### 3.4 Timeline & controls
Tempatkan/hapus SHIFT, play, pause, step forward, undo, reset, replay, dan speed control.

### 3.5 Scoring
Urutan optimasi leksikografis:

`score = (shift_count, completion_ticks, programming_actions)`

Nilai lebih kecil lebih baik. *Programming actions* dihitung dari program final yang dinormalisasi, bukan banyaknya klik atau percobaan.

## 4. Content System

### 4.1 Fifteen curated levels
| Levels | Focus |
|---|---|
| 1–3 | Source, path, target |
| 4–6 | SHIFT dan routing |
| 7–9 | Timing dan sinkronisasi |
| 10–12 | Multi-signal dan optimasi |
| 13–15 | Mastery kombinasi mekanik |

### 4.2 Procedural generation
Pipeline: `generate graph → solve → evaluate difficulty/quality → reject invalid/repetitive → publish versioned puzzle`.

Persyaratan:
- Minimal satu solusi valid dan selesai dalam tick limit.
- Seed, generator version, dan rules version menghasilkan puzzle identik.
- Solver mengukur baseline optimal dan tingkat kesulitan.
- Hindari puzzle terlalu trivial atau terlalu mirip dengan yang baru dimainkan.
- Generator harus lolos property-based testing.

### 4.3 Progressive hints
1. **Conceptual clue:** Prinsip umum tanpa langkah solusi.
2. **Timing clue:** Rentang tick relevan.
3. **Actionable clue:** Satu langkah solusi tervalidasi solver.

Hint berurutan, opsional, tidak mengubah state, dan **nonaktif pada Daily Challenge kompetitif**. Puzzle editor hanya dapat memberi hint jika lolos solver validation.

### 4.4 Puzzle editor & Share Code
- Buat/edit node, edge, source, target, switch, tick limit.
- Draft lokal, test play, solver validation.
- Ekspor/impor Share Code berisi versi schema, puzzle specification, compression/checksum.
- Berfungsi offline, tidak memerlukan wallet.
- Batasi ukuran input, node, edge, dan kompleksitas; checksum bukan bukti autentisitas.

## 5. Daily Challenge

- **Satu puzzle identik untuk semua pemain setiap hari.**
- Periode: 00:00–23:59:59 UTC; ID berbasis tanggal UTC, contoh `20261105`.
- Puzzle specification, hash, engine version, dan rules version dibekukan sebelum mulai.
- Attempts tidak terbatas, hint nonaktif.
- Guest dapat bermain; wallet hanya diperlukan untuk submission on-chain.
- Puzzle lama dapat dimainkan sebagai archive tanpa mengubah ranking resmi.

### 5.1 Leaderboard
Skor diurutkan `(SHIFT, ticks, actions)` secara leksikografis. Hanya best verified score per wallet yang dihitung.

**Shared rank:** Skor identik berbagi peringkat tanpa timestamp tie-breaker. Gunakan competition ranking: `1, 1, 3, 4`.

`rank(player) = 1 + count(other_players_with_strictly_better_score)`

Ranking penuh dihitung oleh indexer, bukan iterasi semua pemain di smart contract.

### 5.2 Replay reveal
- Selama challenge aktif: skor/rank publik, **replay pemain lain privat**.
- Setelah challenge ditutup dan hasil difinalisasi: replay terbaik dibuka.
- Controls: play, pause, restart, step-by-step, 0.5×/1×/2×, timeline SHIFT, perbandingan skor.
- Replay adalah daftar aksi deterministik, bukan video.
- **Jangan mempublikasikan action list dalam calldata atau event on-chain sebelum challenge berakhir.** Hash commitment boleh disimpan on-chain; replay lengkap privat di backend sampai reveal.

### 5.3 Finalization
Setelah jendela ditutup, tunggu finalitas transaksi, ambil best score terverifikasi, hitung shared rank, buat snapshot final, ungkap replay, dan kirim poin ke Weekly Tournament. Tandai hasil sebelum finalisasi sebagai *provisional*.

## 6. Weekly Tournament

Periode Senin 00:00 UTC sampai Minggu 23:59:59 UTC. Akumulasi poin dari **ranking final** Daily Challenge.

| Final daily rank | Points |
|---|---:|
| 1 | 100 |
| 2–3 | 75 |
| 4–10 | 50 |
| 11–25 | 30 |
| 26–100 | 15 |
| 101+ | 5 |
| No valid submission | 0 |

- Shared rank menerima poin sama.
- `weekly_points = sum(daily_points for 7 days)`.
- Total mingguan identik berarti shared weekly rank.
- Tidak ada tie-breaker timestamp.
- Distribusi poin perlu disimulasikan agar jumlah peserta per hari tidak menimbulkan bias yang tidak diinginkan.

## 7. Hybrid Achievements

**Local achievements:** otomatis, offline, tersimpan di SQLite dan backup `.szsave`.

| Name | Criteria |
|---|---|
| First Signal | Selesaikan puzzle pertama |
| Think Ahead | Selesaikan puzzle yang membutuhkan minimal tiga SHIFT |
| Perfect Timing | Capai tick optimal tervalidasi |
| Never Give Up | Selesaikan puzzle setelah sepuluh percobaan |
| Architect | Buat puzzle pertama |
| Signal Creator | Ekspor Share Code |

**Optional on-chain achievements:** diverifikasi dari hasil kompetisi final dan dapat diklaim di Base.

| Name | Criteria |
|---|---|
| Daily Champion | Shared rank #1 Daily Challenge |
| Consistent Mind | Selesaikan tujuh Daily Challenge berturut-turut |
| Top Strategist | Shared rank 1–10 Weekly Tournament |
| Signal Master | Sepuluh kemenangan Daily Challenge |

Kontrak registry terpisah, mencegah duplicate claim, replay signature, wrong-wallet claim, dan klaim sebelum finalisasi. Tidak ada NFT/token pada baseline.

## 8. UX / Information Architecture

Navigasi: **Play**, **Daily**, **Tournament**, **Create**, **Achievements**, **Profile**.

### Onboarding
Guest-first: buat local profile ID dan nickname; langsung masuk tutorial tanpa wallet. Ajarkan source/target → simulasi → SHIFT → timeline → puzzle mandiri → optimasi.

### Gameplay screen
Header puzzle; board jaringan; timeline; play/pause/step/reset/undo; score preview; hint pada mode nonkompetitif; result modal.

### Accessibility
Touch targets memadai, non-color indicators, kontras, reduced effects, audio toggle, simulation speed, tidak ada timer real-time untuk puzzle biasa.

## 9. Visual & Audio Direction

**Holographic Circuit** dibuat sepenuhnya secara procedural dengan Flutter Canvas/Flame.

| Token | Hex |
|---|---|
| Void | `#090D1C` |
| Surface | `#181C3B` |
| Signal | `#25E6F2` |
| SHIFT | `#FF9B45` |
| Target | `#B18CFF` |

- Node: lingkaran konsentris dan pulse glow.
- Edges: jalur sirkuit dengan energi.
- Signals: partikel bergerak.
- SHIFT: gelombang oranye.
- Targets: pulse sinkronisasi ungu.
- Success: iluminasi jaringan bertahap.
- Failure: distorsi singkat tanpa menutupi informasi.
- Batasi blur, gunakan pooling partikel dan adaptive/reduced effects.
- Sintesis audio sederhana untuk klik, pulse, sinkronisasi, success/failure; semua dapat dimatikan.

## 10. Technical Architecture

```text
Flutter + Flame Client
  ├─ Puzzle Domain / Deterministic Engine
  ├─ Timeline / Scoring / Solver / Generator
  ├─ Procedural Renderer / Input / Audio
  ├─ Drift SQLite / Backup / Share Codec
  └─ Challenge API / Wallet Adapter
              │
              ▼
Backend API + Verifier + Scheduler + Attestation Signer
              │
       ┌──────┴─────────┐
       ▼                ▼
Base Contracts       DB + Indexer
Leaderboard          Challenges / Scores
Achievements         Replay Storage / Ranking
```

### Suggested repository
```text
signal_zero/
├── apps/game/lib/{app,domain,game,features,data,integrations}/
├── apps/game/test/
├── services/{api,verifier,scheduler,indexer}/
├── contracts/{src,test,script}/
└── specs/{puzzle-schema,replay-schema,test-vectors}/
```

### Determinism
- Identical puzzle spec + engine version + ordered actions => identical state and score.
- Prefer integer-based logic over floating-point where possible.
- Shared formal spec and golden test vectors across client/verifier.
- Versioned replay format for historical compatibility.

## 11. Base Blockchain Infrastructure

| Network | Chain ID |
|---|---:|
| Base Sepolia | 84532 |
| Base Mainnet | 8453 |

Smart contracts menggunakan Solidity + Foundry. Gameplay tidak tergantung pada koneksi blockchain.

### Submission pipeline
1. Pemain menyelesaikan puzzle.
2. Client mengirim challenge ID + replay ke backend.
3. Verifier menjalankan ulang solusi secara deterministik.
4. Verifier menerbitkan **EIP-712 signed attestation**.
5. Wallet memilih user-paid atau sponsored transaction.
6. Kontrak memvalidasi attestation dan menyimpan best score.
7. Indexer memperbarui leaderboard.

Attestation harus mengikat wallet, challenge ID, puzzle hash, rules/engine version, score tuple, replay commitment, chain ID, verifying contract, nonce, dan expiry.

### Contract responsibilities
- Verifikasi signer, nonce, deadline, challenge window, dan best-score improvement.
- Emit event score/achievement.
- Achievement registry terpisah.
- Rank dan weekly points dihitung off-chain dari event final.
- Indexer menangani chain reorganization, pagination, dan provisional/final states.

### Hybrid gas
- User-paid gas untuk submission biasa.
- Sponsored first eligible submission (baseline satu per wallet per hari), dengan relayer/paymaster yang sesuai SDK wallet.
- Global budget cap, rate limiting, anti-abuse, dan fallback user-paid.
- Relayer tidak dapat bertindak atas nama wallet tanpa otorisasi kriptografis.

### Trust & security
Verifier off-chain adalah trust assumption; blockchain tidak otomatis membuktikan kebenaran solver. Mitigasi: publikasi spesifikasi/test vectors, replay commitments, signer rotation, secure key management, monitoring, contract review, dan replay disclosure pascakompetisi.

## 12. Identity, Local Storage & Backup

- Guest-first local UUID + nickname + progress.
- Wallet connection opsional; tidak boleh menghapus data guest.
- Drift/SQLite menyimpan progress, best scores, settings, drafts, achievements, imported puzzles, cache.
- Backup `.szsave`: versioned JSON (opsional compressed), checksum, schema migrations.
- Import: validate → preview → merge/restore → backup state sebelumnya → apply → report.
- Batas ukuran dan validasi konten untuk file import.
- **Tidak pernah menyimpan private key, seed phrase, atau wallet secrets dalam backup.**
- Checksum mendeteksi korupsi, bukan melindungi dari modifikasi disengaja.

## 13. Functional Requirements

| ID | Requirement | Priority |
|---|---|---|
| FR-001 | Deterministic tick simulation | P0 |
| FR-002 | Global SHIFT routing | P0 |
| FR-003 | Timeline programming + step | P0 |
| FR-004 | Undo/reset/replay lokal | P0 |
| FR-005 | Puzzle completion + scoring | P0 |
| FR-006 | 15 curated tutorial/mastery levels | P0 |
| FR-007 | Procedural Holographic Circuit rendering | P0 |
| FR-008 | Guest profile + local progress | P0 |
| FR-009 | Puzzle solver | P0 |
| FR-010 | Procedural generator | P1 |
| FR-011 | Three-stage progressive hints | P1 |
| FR-012 | Identical Daily Challenge | P1 |
| FR-013 | Verified leaderboard + shared rank | P1 |
| FR-014 | Wallet + Base submission | P1 |
| FR-015 | Hybrid gas | P1 |
| FR-016 | Post-challenge replay reveal | P1 |
| FR-017 | Weekly Points Tournament | P1 |
| FR-018 | Hybrid achievements | P1 |
| FR-019 | Puzzle editor + Share Code | P1 |
| FR-020 | `.szsave` backup/import | P1 |
| FR-021 | Replay sharing | P2 |
| FR-022 | Advanced procedural audio | P2 |
| FR-023 | Accessibility/customization | P1 |
| FR-024 | Diagnostics/analytics | P1 |

**P0** wajib untuk gameplay minimum; **P1** target Ambitious Release; **P2** polish yang dapat ditunda.

## 14. Non-Functional Requirements

- Target 60 FPS pada perangkat mobile kelas menengah.
- Deterministic simulation across platforms/versions.
- Offline campaign, practice, editor, local progress.
- Autosave dan schema migrations.
- No wallet secrets on device backup.
- Pagination dan indexed leaderboard.
- Reduced Effects, non-color indicators, audio toggle.
- Unit, property-based, integration, contract, dan golden replay tests.
- Uji web compatibility sejak awal.

## 15. User Stories & Acceptance Criteria

| ID | Story | Acceptance |
|---|---|---|
| US-01 | Pemain baru belajar SHIFT | Tutorial bertahap dan progress tersimpan |
| US-02 | Pemain menjalankan replay identik | State akhir dan skor selalu sama |
| US-03 | Pemain mendapat puzzle baru | Solver memverifikasi semua puzzle terbit |
| US-04 | Pemain meminta hint | Tiga tahap berurutan, tanpa perubahan state |
| US-05 | Kompetisi puzzle identik | Challenge ID menggunakan puzzle hash sama |
| US-06 | Skor identik adil | Shared rank, tanpa timestamp tie-breaker |
| US-07 | Replay tidak bocor | API privat selama challenge; actions tidak on-chain |
| US-08 | Guest dapat bermain | Gameplay inti tidak memerlukan wallet |
| US-09 | Kreator berbagi puzzle | Share Code menghasilkan puzzle identik |
| US-10 | Pemain memindah progress | Backup tervalidasi dan restore/merge |
| US-11 | Pemain mengikuti weekly points | Poin dari hasil harian final |
| US-12 | Achievement tanpa paksaan gas | Local otomatis; on-chain claim opsional |

## 16. Development Roadmap

1. **Playable Core:** Puzzle schema, engine, SHIFT, timeline, scoring, tests.
2. **Game Feel & Tutorial:** Flame renderer, holographic effects, 15 levels, UX.
3. **Infinite Puzzles:** Solver, generator, difficulty filtering, progressive hints.
4. **Competitive Infrastructure:** Daily scheduler, verifier, API, Base contracts, indexer, wallet.
5. **Community & Progression:** Weekly points, achievements, replay reveal, editor, Share Code, backup.
6. **Release Hardening:** Performance, accessibility, security review, web export, itch.io packaging.

### Release gates
- **G1:** SHIFT gameplay terbukti menyenangkan.
- **G2:** Deterministic client/verifier.
- **G3:** Puzzle generator menghasilkan konten valid.
- **G4:** Competitive submissions tidak dapat memalsukan skor.
- **G5:** Build jam dapat dimainkan dan instruksi jelas.
- **G6:** Ambitious Release P1 stabil.

Jika waktu terbatas, utamakan playable game (G1–G3), bukan integrasi blockchain.

## 17. Success Metrics (Initial Hypotheses)

| Metric | Initial target |
|---|---|
| Tutorial completion | ≥80% testers |
| Time to first success | ≤5 minutes |
| SHIFT mechanic comprehension | ≥80% testers |
| Published puzzle validity | 100% solver-verified |
| Replay consistency | 100% golden tests |
| Crash-free sessions | ≥99% |
| Rendering | Target 60 FPS |
| Share Code import | 100% valid test fixtures |

Pantau daily completion, retention, repeat play, hint usage, dan challenge submission. Analytics harus mematuhi privasi dan persetujuan yang relevan.

## 18. Risks & Mitigations

| Risk | Mitigation |
|---|---|
| Gameplay repetitif | Topology/timing variety + playtesting |
| Puzzle buruk | Solver, difficulty filters, curated validation |
| Ambiguous mechanics | Formal state transitions + tests |
| Jam scope terlalu besar | P0-first dan release gates |
| Flutter Web incompatibility | Test web sejak awal |
| Client/verifier mismatch | Shared spec + golden test vectors |
| Replay bocor | Private backend until reveal; no action calldata |
| Sponsored gas abuse | Quotas, rate limits, budget caps |
| Signer compromise | Secure keys, rotation, monitoring |
| Chain outage | Offline gameplay + retry |
| Malicious imports | Schema validation + resource limits |
| Excessive effects | Adaptive quality + reduced effects |

## 19. Game Off 2026 Compliance

**Belum diverifikasi:** tema resmi, deadline, rules, AI policy, dan persyaratan platform.

Periksa [halaman resmi Game Off 2026](https://itch.io/jam/game-off-2026) sebelum submission. Pastikan konsep sesuai tema dan build dapat diakses juri. Prioritaskan web playable untuk itch.io jika memungkinkan, tanpa kewajiban wallet.

## 20. Open Technical Decisions

- Definisi collision, synchronization, special nodes, failure states.
- Kalibrasi solver difficulty.
- Simulasi fairness Weekly Points.
- SDK wallet dan sponsor gas.
- Replay storage, retention, reveal publication.
- Web export compatibility.
- Smart contract review dan threat model.
- Konfirmasi tema dan aturan game jam.

## 21. Definition of Done

- [ ] SHIFT/timeline engine deterministik.
- [ ] 15 curated levels playable.
- [ ] Solver dan generator valid.
- [ ] Holographic Circuit terbaca dan responsif.
- [ ] Progressive hints pada noncompetitive modes.
- [ ] Guest offline progress.
- [ ] Daily identical puzzle + verified submission.
- [ ] Shared rank.
- [ ] Replay reveal setelah challenge.
- [ ] Weekly Points dari final daily standings.
- [ ] Hybrid achievements.
- [ ] Editor + Share Code.
- [ ] Backup `.szsave`.
- [ ] Wallet optional.
- [ ] Platform testing dan jam compliance.

## 22. Final Product Decision Summary

| Dimension | Decision |
|---|---|
| Core mechanic | Global SHIFT + Timeline Programming |
| Visual | Holographic Circuit |
| Content | 15 curated + procedural + editor |
| Hints | Progressive 3-stage, disabled in ranked daily |
| Daily | One identical puzzle/day |
| Ranking | Shared Rank |
| Replay | Reveal after daily closes |
| Weekly | Accumulated Daily Rank Points |
| Identity | Guest-first |
| Achievements | Local + optional on-chain |
| Blockchain | Base + hybrid gas |
| Storage | Drift/SQLite + `.szsave` |
| Tech | Flutter + Flame + Solidity/Foundry |

**Implementation recommendation:** Mulai dari deterministic puzzle engine dan satu puzzle playable. Validasi gameplay sebelum membangun blockchain atau polish visual.

---
*End of SIGNAL ZERO PRD v2.2.*
