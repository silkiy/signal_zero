# Fase 07 — Kontrak, wallet, sponsorship, dan indexer

Scope implementasi/integrasi memakai test environment dan Base Sepolia. Mainnet, pembelian gas, deployment berbiaya, serta penggunaan secrets nyata memerlukan langkah operasional tersendiri; penyusunan task ini tidak menjalankannya. Seluruh path adalah rencana. Pilihan SDK/relayer/paymaster mengikuti T006, bukan asumsi task ini.

<a id="t067"></a>

## T067 — Kontrak leaderboard untuk best verified score

**Prioritas:** P1 | **Ukuran:** M | **PRD:** §5.1, §11, FR-013, FR-014
**Dependensi:** T003, T006, T060
**Tujuan:** Menyimpan satu best score per wallet/challenge setelah attestation tervalidasi.
**Output rencana (≤5 file):** `contracts/src/SignalLeaderboard.sol`, `contracts/src/ScoreAttestation.sol`, `contracts/test/SignalLeaderboard.t.sol`, `contracts/script/DeployLeaderboard.s.sol`, `contracts/script/RegisterChallenges.s.sol`.
**Kriteria selesai:**
- [ ] Registrasi challenge berotorisasi membekukan hash/versi/window sesuai T006; submission memverifikasi signer, domain chain/contract, wallet authorization, challenge/hash/version, nonce, expiry, dan window; score lebih buruk/sama tidak menggantikan best.
- [ ] State/event hanya berisi metadata/score/commitment yang diizinkan; action list tidak dikirim melalui calldata maupun event.
- [ ] Tidak mengiterasi seluruh pemain untuk rank/weekly points; script deployment lokal/Sepolia menghasilkan artifact address/config tanpa menjalankan mainnet.
**Verifikasi:** Foundry unit tests untuk unauthorized registration/mutasi challenge beku, valid/improved score, expired/wrong-domain/wrong-wallet/reused nonce, window boundaries, serta inspeksi ABI/encoded calldata/events.

<a id="t068"></a>

## T068 — Adapter wallet opsional yang mempertahankan guest

**Prioritas:** P1 | **Ukuran:** M | **PRD:** §8, §11–12, FR-014
**Dependensi:** T004, T006, T022, T028, T050
**Tujuan:** Menambahkan connect/disconnect/account-chain changes melalui interface wallet yang telah dipilih.
**Output rencana (≤5 file):** `apps/game/lib/integrations/wallet_adapter.dart`, `apps/game/lib/integrations/wallet_session.dart`, `apps/game/lib/features/profile/wallet_section.dart`, `apps/game/test/integrations/wallet_adapter_test.dart`.
**Kriteria selesai:**
- [ ] Connect wallet bersifat pilihan; cancel/disconnect tidak menghalangi campaign/practice/editor atau menghapus UUID/progress guest.
- [ ] Chain/account change membatalkan otorisasi/attestation yang tak lagi cocok; network yang didukung ditampilkan jelas.
- [ ] Tidak meminta/menyimpan private key atau seed phrase; web/mobile unsupported wallet memiliki pesan dan jalur kembali guest.
**Verifikasi:** Mock wallet connect→switch account→wrong chain→cancel→disconnect dan integration smoke pada platform hasil T004; bandingkan guest progress sebelum/sesudah.

<a id="t069"></a>

## T069 — Submission user-paid dari klien ke Base Sepolia

**Prioritas:** P1 | **Ukuran:** M | **PRD:** §11 submission pipeline, FR-014
**Dependensi:** T060, T065, T067, T068
**Tujuan:** Menghubungkan submit replay privat → attestation → transaksi best-score menggunakan wallet pemain.
**Output rencana (≤5 file):** `apps/game/lib/features/daily/submission_controller.dart`, `apps/game/lib/integrations/leaderboard_contract.dart`, `apps/game/lib/features/daily/submission_status.dart`, `apps/game/test/integrations/submission_flow_test.dart`.
**Kriteria selesai:**
- [ ] Challenge sudah terdaftar/frozen dengan identitas sama di backend dan kontrak; wallet memberi otorisasi miliknya, backend memverifikasi replay, lalu klien mengirim calldata attestation/commitment tanpa action list.
- [ ] UI membedakan verified-local, awaiting-wallet, pending, confirmed/provisional, rejected, expired, dan failed; signature/transaksi tidak otomatis diminta berulang.
- [ ] Score belum indexed/final tidak dianggap final rank; cancel user tidak menghilangkan solusi atau memaksa wallet saat bermain.
**Verifikasi:** Jalankan local-chain integration dengan signer/wallet fixture dan, jika environment tersedia, smoke Base Sepolia; decode transaksi untuk memastikan actions privat dan cocokkan score event.

### Checkpoint CP-07A — User-paid submission terhubung

- [ ] T067–T069 memverifikasi kontrak, guest-preserving wallet, dan transaksi berisi commitment tanpa actions.
- [ ] Evidence mencatat command/scenario, versi, hasil dan blocker; tidak ada kelulusan berdasarkan rencana saja.

<a id="t070"></a>

## T070 — Sponsorship submission pertama dengan otorisasi wallet

**Prioritas:** P1 | **Ukuran:** M | **PRD:** §11 hybrid gas, FR-015
**Dependensi:** T006, T007, T059, T067, T069
**Tujuan:** Menyediakan jalur sponsor menggunakan SDK/relayer/paymaster yang dipilih tanpa kehilangan fallback user-paid.
**Output rencana (≤5 file):** `services/api/sponsorship/eligibility`, `services/api/sponsorship/submit`, `services/api/db/migrations/005_sponsor_quota`, `apps/game/lib/features/daily/gas_choice.dart`, `services/api/tests/sponsor_flow_test`.
**Kriteria selesai:**
- [ ] Baseline maksimal satu eligible sponsorship per wallet/hari UTC; reservasi/concurrency/idempotency dan refund kegagalan mengikuti keputusan T006.
- [ ] Rate limit serta global budget cap diterapkan sebelum broadcast; relayer membutuhkan otorisasi kriptografis terikat wallet/payload/domain/nonce.
- [ ] Kuota habis, sponsor tidak tersedia, atau budget cap menawarkan user-paid dengan persetujuan transaksi wallet; tidak menandatangani atas nama pemain.
**Verifikasi:** Uji dua request paralel wallet sama, pergantian tanggal UTC, budget mendekati habis, relayer down, signed payload diganti, dan fallback tanpa double broadcast.

<a id="t071"></a>

## T071 — Indexer canonical events dengan reorg dan backfill

**Prioritas:** P1 | **Ukuran:** M | **PRD:** §5.3, §10–11, FR-013
**Dependensi:** T006, T056, T067
**Tujuan:** Membaca event kontrak secara idempotent dan menyediakan sumber canonical/finality kepada ranking/finalizer.
**Output rencana (≤5 file):** `services/indexer/chain_reader`, `services/indexer/event_store`, `services/indexer/reorg_handler`, `services/api/db/migrations/006_chain_cursor`, `services/indexer/tests/reorg_test`.
**Kriteria selesai:**
- [ ] Event diidentifikasi dengan chain/contract/block-hash/tx/log position; retry/backfill tidak menggandakan score dan cursor tersimpan aman.
- [ ] Reorg menemukan common ancestor, menarik projection orphaned, dan memutar ulang canonical branch; koneksi terputus bisa catch up dengan pagination/range batas.
- [ ] Adapter mengekspor provisional versus finalized sesuai policy T006; RPC failure tidak dianggap finality atau chain kosong.
**Verifikasi:** Feed fixture dua cabang block, duplicate logs, restart tengah range, RPC timeout, serta backfill overlap; cocokkan store/projection/cursor dengan canonical branch.

<a id="t072"></a>

## T072 — Ranking resmi dari event canonical dan finalisasi nyata

**Prioritas:** P1 | **Ukuran:** S | **PRD:** §5.1–5.3, §11, FR-013, FR-016
**Dependensi:** T062, T063, T064, T069, T071
**Tujuan:** Mengganti fixture finality/event dengan indexer nyata dan menutup jalur attestation tanpa transaksi masuk ranking resmi.
**Output rencana (≤5 file):** `services/indexer/projection_binding`, `services/scheduler/finality_binding`, `services/api/tests/canonical_ranking_flow_test`.
**Kriteria selesai:**
- [ ] Hanya transaksi canonical yang lolos kontrak menghasilkan official provisional best score; replay verified tanpa event on-chain tidak ikut official ranking.
- [ ] Setelah window ditutup dan finality terpenuhi, snapshot final serta reveal dipicu dari event source yang sama.
- [ ] Reorg sebelum finality menarik score/rank lama; transaksi pengganti tidak dihitung dua kali.
**Verifikasi:** Local-chain end-to-end submit dua wallet dengan tie, tinggalkan satu attestation tanpa transaksi, simulasi fork, lalu finalisasi dan bandingkan snapshot/replay.

### Checkpoint CP-07B — Sponsor dan canonical ranking tersambung

- [ ] T070–T072 menegakkan quota/auth/budget, reorg recovery, dan hanya event canonical masuk official ranking.
- [ ] Evidence mencatat command/scenario, versi, hasil dan blocker; tidak ada kelulusan berdasarkan rencana saja.

<a id="t073"></a>

## T073 — Fuzz dan invariants kontrak leaderboard

**Prioritas:** P1 | **Ukuran:** S | **PRD:** §11, §14, §18, FR-013, FR-014
**Dependensi:** T067
**Tujuan:** Membuktikan invariants kontrak pada input adversarial di luar happy path unit tests.
**Output rencana (≤5 file):** `contracts/test/LeaderboardFuzz.t.sol`, `contracts/test/LeaderboardInvariant.t.sol`, `contracts/test/handlers/LeaderboardHandler.sol`, `tasks/evidence/contract-review.md`.
**Kriteria selesai:**
- [ ] Best tuple tidak pernah memburuk, nonce tidak dapat dipakai ulang, dan unauthorized wallet/signer/domain tidak dapat mengubah score.
- [ ] Fuzz mencakup batas tipe angka, expiry/window, nonce, hash/version mismatch, access control/rotation, dan fungsi administrative yang ada.
- [ ] Laporan memisahkan invariant yang diuji dari asumsi trusted verifier/signer; kegagalan ditutup atau dicatat sebagai blocker G4.
**Verifikasi:** Jalankan Foundry fuzz/invariant dengan seed/run count tercatat, reproduksi setiap failure lalu simpan hasil review dan skenario serangan.

<a id="t074"></a>

## T074 — Operasi signer, rotasi, dan runbook insiden

**Prioritas:** P1 | **Ukuran:** S | **PRD:** §11 trust/security, §18, FR-014, FR-024
**Dependensi:** T006, T060, T067
**Tujuan:** Menyiapkan konfigurasi aman dan latihan rotasi signer tanpa memasukkan secrets nyata ke task/artifact.
**Output rencana (≤5 file):** `services/verifier/signer_policy`, `services/verifier/tests/signer_rotation_test`, `docs/ops/signer-runbook.md`, `services/verifier/config.example`.
**Kriteria selesai:**
- [ ] Secret access memakai mekanisme T006, least privilege, konfigurasi tervalidasi, serta redaksi log; repository hanya menyimpan nama setting/contoh palsu.
- [ ] Runbook menjelaskan rotasi/revocation, outstanding attestation/expiry, pemulihan, dan tindakan ketika signer diduga bocor.
- [ ] Dry run dengan test keys membuktikan signer lama/baru diterima atau ditolak sesuai policy dan alert untuk kegagalan penandatanganan aktif.
**Verifikasi:** Latih rotasi pada local chain, coba signature sebelum/sesudah policy cutoff, putus signer service, dan periksa config/log/evidence tidak berisi secret.

<a id="t075"></a>

## T075 — Pemulihan transaksi dan chain outage di klien

**Prioritas:** P1 | **Ukuran:** S | **PRD:** §11–12, §18, FR-014
**Dependensi:** T048, T069, T071
**Tujuan:** Mempertahankan solusi dan status transaksi saat RPC/backend gagal atau aplikasi dibuka ulang.
**Output rencana (≤5 file):** `apps/game/lib/features/daily/pending_submission_store.dart`, `apps/game/lib/features/daily/submission_recovery.dart`, `apps/game/test/integrations/submission_recovery_test.dart`.
**Kriteria selesai:**
- [ ] Simpan transaction hash/chain/challenge/wallet/status tanpa wallet secrets; restart melakukan status lookup sebelum menawarkan retry.
- [ ] Timeout tidak dianggap transaction failed; expired attestation dan challenge closed ditangani tanpa menjanjikan late submission resmi.
- [ ] Retry tidak menggandakan broadcast/nonce atau biaya otomatis; offline campaign tetap dapat digunakan.
**Verifikasi:** Putus jaringan sebelum/sesudah broadcast, restart aplikasi saat pending, ganti wallet, maju melewati deadline, lalu pulihkan jaringan dan cocokkan status chain.

### Checkpoint CP-07C — Kontrak dan recovery tahan kegagalan

- [ ] T073–T075 memiliki bukti fuzz/invariants, signer rotation dan pending transaction recovery.
- [ ] Evidence mencatat command/scenario, versi, hasil dan blocker; tidak ada kelulusan berdasarkan rencana saja.

<a id="t076"></a>

## T076 — Uji abuse sponsorship dan biaya terbatas

**Prioritas:** P1 | **Ukuran:** S | **PRD:** §11 hybrid gas, §18, FR-015
**Dependensi:** T070, T074
**Tujuan:** Memastikan aturan sponsor tahan request serentak, replay authorization, dan retry yang sengaja diulang.
**Output rencana (≤5 file):** `services/api/tests/sponsorship_abuse_test`, `services/api/tests/sponsorship_budget_test`, `tasks/evidence/sponsorship-abuse.md`.
**Kriteria selesai:**
- [ ] Parallel requests, duplicate idempotency keys, wallet swap, signature replay, dan wrong chain/contract tidak melewati kuota/otorisasi.
- [ ] Global cap tetap berlaku dalam contention dan failure/retry; service tidak menjanjikan mitigasi Sybil penuh dari kuota per wallet saja.
- [ ] Rate/budget rejections menyediakan fallback user-paid dan telemetry redacted tanpa menyimpan replay/actions atau secret.
**Verifikasi:** Jalankan concurrent bounded load terhadap fake relayer dengan budget kecil, injeksikan broadcast failure/late receipt, dan rekonsiliasi semua reservasi serta biaya fixture.

<a id="t077"></a>

## T077 — Gate G4: alur kompetisi adversarial end-to-end

**Prioritas:** P1 | **Ukuran:** S | **PRD:** §15 US-05–US-08, §16 G4, §18; FR-012–FR-016
**Dependensi:** T066, T072, T073, T074, T075, T076
**Tujuan:** Menguji batas kepercayaan submission dari replay hingga canonical ranking dan final reveal.
**Output rencana (≤5 file):** `services/api/tests/competitive_e2e_test`, `contracts/test/CompetitiveFlow.t.sol`, `tasks/evidence/G4.md`.
**Kriteria selesai:**
- [ ] Score palsu, replay invalid, wrong wallet/domain/version, reused nonce, expired/out-of-window transaction, dan bypass sponsor ditolak pada boundary yang sesuai.
- [ ] Dua wallet tie memperoleh shared rank, reorg provisional pulih, dan private actions tidak terungkap lewat API/log/calldata/event sebelum final.
- [ ] Evidence mencatat environment, commands, hasil, serta asumsi verifier/signer tepercaya; temuan keamanan terbuka memblokir G4.
**Verifikasi:** Jalankan matrix adversarial pada local chain dan smoke test Sepolia yang tersedia; decode transaksi/event dan audit output publik sebelum/sesudah finalisasi.

### Checkpoint CP-07D — Gate G4 dinilai

- [ ] T076–T077 melaporkan sponsor abuse dan competitive E2E; temuan keamanan terbuka memblokir kelulusan.
- [ ] Evidence mencatat command/scenario, versi, hasil dan blocker; tidak ada kelulusan berdasarkan rencana saja.
