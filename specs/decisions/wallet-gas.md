# T006 — Wallet adapter dan hybrid gas

Tanggal keputusan: 2026-11-05. Status: baseline teknis dipilih dalam delegasi Fase 01; dependency/provider/network integration belum dijalankan. Tidak ada wallet, proyek vendor, paymaster, relayer funded, kontrak, atau subscription yang dibuat oleh dokumen ini.

## Pilihan platform

| Target | Adapter dipilih | Batas yang harus terlihat |
|---|---|---|
| Android/iOS | Reown AppKit Flutter **1.9.0** exact, external EOA wallet connector | [Package](https://pub.dev/packages/reown_appkit) hanya mencantumkan Android/iOS; [version table](https://pub.dev/packages/reown_appkit/versions) menyatakan minimum Dart 3.8, sesuai Dart 3.9.2 baseline |
| Flutter web | Dart `dart:js_interop` ke injected **EIP-1193** provider; **EIP-6963** discovery, fallback `window.ethereum` | Tidak menyatakan Reown Flutter mendukung web. Extension dapat tidak tersedia dalam iframe/mobile browser; fallback tetap guest, bukan koneksi palsu |
| Desktop native | Guest baseline | Wallet native desktop di luar target rilis awal PRD |

Interface tunggal `WalletAdapter`: availability/capabilities, connect, disconnect, current account/chain, `personalSign` bila diperlukan kelak, `signTypedDataV4`, `sendTransaction`, account/chain/disconnect events. Baseline memakai EIP-712 untuk ownership request API dan authorization submit, bukan login otomatis. Capability `signTypedDataV4` wajib sebelum menawarkan submission; kegagalan/unsupported tidak boleh ditangani dengan private key input atau blind `eth_sign` fallback.

[Reown installation](https://docs.reown.com/appkit/flutter/core/installation) memerlukan project ID, konfigurasi native, dan mencatat keterbatasan connector Coinbase Mobile SDK terhadap Base Wallet saat diperiksa. Pilih external wallet yang benar-benar melewati T068 smoke test; tidak mengiklankan semua wallet kompatibel. Web memakai [EIP-1193](https://eips.ethereum.org/EIPS/eip-1193), [EIP-6963](https://eips.ethereum.org/EIPS/eip-6963), dan [Dart JS interop](https://dart.dev/interop/js-interop). Provider metadata/icons adalah data tidak tepercaya; tidak mengeksekusi SVG/HTML dari wallet metadata.

Reown AppKit 1.9.0 memakai [Community License](https://pub.dev/packages/reown_appkit/license), dengan ketentuan attribution, gateway, dan commercial-use thresholds. Ini keputusan dependency mobile yang **belum diinstal**; T068 harus memeriksa packaged license/notices, graph dan native requirements sebelum integrasi serta T008/T096 memeriksa konsistensi distribusi game jam. Tidak ada klaim semua service gratis/tanpa ketentuan. Lisensi package lain tidak otomatis mencakup AppKit.

## Model akun dan identitas

- Rilis baseline mendukung EOA yang dapat memberikan signature ECDSA Ethereum 65-byte canonical low-s; tidak mengambil alih custody.
- Smart-contract wallets/ERC-1271 dan account abstraction ditunda secara eksplisit. EIP-7702/delegated code, counterfactual account, atau signature format lain diperlakukan unsupported sampai ada pengujian khusus; jangan menganggap `eth_getCode` saja membuktikan tipe wallet pada semua upgrade.
- Account/chain change menghapus private poll capabilities dan attestation cache milik account lama dari RAM, tidak mengubah UUID/nickname/progress guest. Wallet association hanya tautan opsional, bukan migrasi kepemilikan data offline.
- Base Sepolia **84532** adalah integration network; Base Mainnet **8453** hanya konfigurasi masa depan, disabled default. Identitas chain dicek dari provider/RPC; [Base `eth_chainId`](https://docs.base.org/base-chain/api-reference/ethereum-json-rpc-api/eth_chainId) mencantumkan keduanya. Address kontrak harus berasal artifact deployment yang direview, tidak placeholder zero.

## Jalur user-paid

1. Guest menyelesaikan puzzle; bila memilih Submit, connect wallet dan buktikan ownership HTTP sesuai [competition-api.md](../competition-api.md).
2. Replay dikirim privat, verifier menghitung score; backend membuat salted commitment dan ScoreAttestation.
3. Wallet mengirim `submitScore(attestation, verifierSignature)` sebagai transaksi sendiri. Kontrak mensyaratkan `msg.sender == attestation.wallet`.
4. UI pending → canonical provisional → final mengikuti indexer, bukan hanya response API atau receipt awal.

Wallet menanggung gas transaksi miliknya setelah konfirmasi. Score/call tidak mentransfer dana/token, tidak memberi allowance, tidak memuat actions. Menolak/cancel menjaga solusi lokal.

## Jalur sponsored tanpa account abstraction

Pilih **EOA relayer biasa**, bukan bundler/paymaster/AA vendor pada baseline. Kontrak memiliki `submitScoreFor(attestation, verifierSignature, authorization, walletSignature)`; player menandatangani `SubmitAuthorization` yang mengikat attestation digest dan executor relayer. Relayer membayar gas dari wallet operasionalnya sendiri. Detail kedua signature ada di [attestations.md](../attestations.md).

- Baseline **satu sponsor yang berhasil per wallet per challenge/hari UTC**. Wallet dengan confirmed successful submission sebelumnya (termasuk user-paid) tidak eligible lagi; pending slot membatasi satu request bersamaan. Failed/reverted transaction boleh melepaskan kuota hanya setelah status canonical pasti; biaya yang sudah terpakai tetap dihitung global budget.
- DB transaction mengunci baris budget UTC lalu slot wallet/day dengan urutan tetap. Reservasi worst-case cost = `gasLimit * maxFeePerGas`; seluruh reservation + settled cost tidak boleh melewati global cap. Release hanya setelah known final outcome; timeout/pending tetap reserved. Fee increase harus membuat reservation tambahan secara atomik sebelum replacement dengan nonce sama.
- Sponsor **disabled default**. Test fixture cap **0.01 ETH/day**, cap **0.0002 ETH/transaction**, `gasLimit <= 500000`; ini batas simulasi konfigurasi awal, bukan estimasi biaya atau otorisasi belanja ETH. Deployment nyata harus mengatur budget eksplisit; nol/missing = tidak mensponsori.
- Authorization expiry maksimum 5 menit dan tidak lewat challenge close; relayer address nonzero dan exact `msg.sender`. Contract-specific wallet nonce sekali pakai; signer/chain/contract/wallet/payload tidak bisa diganti.
- Rate limits awal: nonce requests 10/IP/menit, private submissions 10/wallet/menit dan 30/IP/menit, sponsor attempts 3/wallet/hari serta 30/IP/jam; network gateway/token bucket dan DB slot adalah lapisan berbeda. Kuota sponsor tetap satu successful/day; batas transport mencegah abuse dan tidak membatasi attempts gameplay lokal. Response `429` dengan Retry-After; limit lebih ketat T007 menang.
- Sponsor outage/cap/eligibility failure menawarkan user-paid. Tidak mengirim transaksi user-paid otomatis atau menagih wallet untuk biaya relayer. Banyak wallet tetap dapat menjadi Sybil; kuota per wallet bukan bukti satu manusia.

## Kriteria integrasi T068–T076

Uji mobile connect/cancel/reconnect, chain/account changes, typed signatures, user-paid dan relayed calldata decoding. Uji web provider mocked dan extension nyata; iframe yang memblokir wallet harus kembali guest dengan status yang benar. Double request/reservation, late receipt, replacement, reorg, signing mismatch dan disabled sponsor masuk suite. Memilih SDK di dokumen ini bukan hasil pengujian SDK/platform.
