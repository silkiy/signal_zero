# T004 — Keputusan kompatibilitas web

Tanggal: 5 November 2026. Status: **GO terbatas untuk baseline Dart2JS + desktop Chrome**, berdasarkan spike nyata. Bukan bukti final gameplay, 60 FPS mobile, Safari/iOS, atau deployment itch.io sudah lulus.

## Versi dan ruang uji

- Windows 11; Flutter 3.35.6, Dart 3.9.2, Flame 1.35.1, Drift 2.30.0, sqlite3 2.9.4, web 1.1.1. Versi/graph ada pada `toolchain.json` dan `apps/game/pubspec.lock`.
- Chrome **156.0.8078.80**, headless, profil terisolasi baru per skenario melalui Playwright 1.62.1. Tidak memakai profil/login pengguna.
- Direct: `http://127.0.0.1:8191/`. Iframe host: `http://localhost:8192/`, child tetap origin 127.0.0.1:8191; berbeda origin dan situs. Sandbox: scripts/same-origin/downloads/forms/pointer-lock, permission autoplay/fullscreen. Server tidak menambahkan COOP/COEP.
- Renderer Flutter CanvasKit dan worker/SQLite WASM disajikan lokal. Ini build Dart2JS, bukan hasil uji aplikasi Dart2Wasm; pesan compiler “Wasm dry run succeeded” hanya pemeriksaan compiler tambahan.

## Hasil yang teramati

Sumber evidence mesin: [T004-browser.json](../../tasks/evidence/T004-browser.json). Screenshot: [direct](../../tasks/evidence/T004-direct.png), [iframe](../../tasks/evidence/T004-iframe.png).

| Skenario | Direct | Iframe |
|---|---|---|
| Flutter/Flame tampil dan frame bergerak | PASS | PASS |
| Tap pada canvas menaikkan counter pointer | PASS | PASS |
| Drift membuat tabel SQL, update/read nilai | PASS | PASS |
| Nilai hasil import tetap ada setelah reload online | PASS | PASS |
| Download JSON melalui tombol export | PASS | PASS |
| Import file melalui input browser; nilai berubah 37 | PASS | PASS |
| Versi file asing ditolak, nilai tetap 37 | PASS | PASS |
| AudioContext berjalan sesudah klik Play tone | PASS | PASS |
| Mute menolak sintesis pulse berikutnya | PASS | PASS |
| Setelah aset/worker termuat, putus network lalu update SQL 37→38 | PASS | PASS |
| Console errors / failed requests pada perjalanan uji | 0 / 0 | 0 / 0 |
| Cold install/offline reload | BELUM DIUJI | BELUM DIUJI |

Kedua skenario memilih storage **`sharedIndexedDb`**. Missing features yang dilaporkan: `dedicatedWorkersInSharedWorkers` dan `sharedArrayBuffers`. Tidak menggunakan memory-only fallback. Tanpa security headers, fallback IndexedDB yang didokumentasikan Drift terbukti cukup untuk dua skenario desktop ini. Nilai fixture sebelum reload 37 dan sesudah offline update 38; counter animasi/tap memang direset saat reload dan bukan data gameplay.

Headless browser membuktikan API audio running dan event mute, **tidak mengukur suara fisik speaker, volume/persepsi audio, atau keterlambatan mobile**. File probe `sz-probe-1` dibatasi 1 KiB dan hanya berisi integer; ini bukan format puzzle, Share Code, atau `.szsave` produksi.

## Keputusan implementasi

1. Pertahankan Flutter/Flame untuk web baseline, gunakan build JavaScript dengan resource renderer lokal untuk rilis awal. Uji Dart2Wasm terpisah jika memang dibutuhkan.
2. Pakai Drift WASM + feature detection; tampilkan kemampuan penyimpanan yang sebenarnya dan jangan menganggap mode memory-only sebagai persistent save. T028/T047 memperkenalkan database game; database probe `signal_zero_t004_probe` tidak boleh dimigrasikan menjadi progress pemain.
3. Jangan mewajibkan COOP/COEP agar game bekerja. Hosting iframe mungkin tidak memberi header tersebut; jika kelak dipakai, ulangi wallet popup/storage/iframe tests. Android Chrome tanpa SharedWorker memiliki risiko multi-tab yang harus diuji.
4. File import/export tetap berbasis user gesture dan input browser; sandbox harus mengizinkan download atau UI menyediakan fallback salin kode/file sesuai fitur. Iframe uji memberi `allow-downloads`, bukan klaim sandbox itch.io selalu identik.
5. Audio dibuat/resume hanya sesudah user gesture dan dapat dimute; kegagalan audio tidak memblokir puzzle. T035 membangun audio produksi.
6. Probe opt-in dengan `--dart-define=WEB_PROBE=true`; default app tidak membuka spike atau hook observasinya. Setelah subsistem produksi siap, buang spike dari artifact rilis di T094.

## Cara mengulangi

```powershell
Push-Location apps/game
flutter pub get
flutter test test/web_probe_test.dart
flutter build web --release --no-web-resources-cdn --dart-define=WEB_PROBE=true
Pop-Location

# Terminal 1: tetap berjalan selama tes.
python tools/web_probe_server.py --build apps/game/build/web

# Terminal 2: gunakan Playwright yang terpasang lokal, bukan profil Chrome user.
npm install --prefix .tools/browser playwright@1.62.1
$env:NODE_PATH = (Resolve-Path '.tools/browser/node_modules').Path
node tools/web_probe_browser.cjs
```

Instalasi npm di contoh adalah petunjuk checkout bersih; run saat ini memakai package Playwright bundled yang sudah tersedia. Chrome terpasang diperlukan untuk `channel: 'chrome'`. Di sandbox Codex, SDK cache serta server/browser harus dijalankan pada lingkungan host yang dapat saling mengakses localhost; hasil awal dari server sandbox tidak dipakai sebagai bukti kompatibilitas.

## Sumber resmi dan aset

- [Flutter web build/run](https://docs.flutter.dev/platform-integration/web/building): scaffold dan command build.
- [Flame GameWidget](https://docs.flame-engine.org/latest/flame/game_widget.html) dan [package 1.35.1](https://pub.dev/packages/flame/versions/1.35.1): integrasi Flame/Flutter; signature juga diperiksa dari source package terkunci.
- [Drift web setup dan browser fallbacks](https://drift.simonbinder.eu/platforms/web/): WASM, worker, headers, IndexedDB dan batas multi-tab. Dokumentasi terbaru tidak menggantikan pengujian versi terkunci.
- [Rilis Drift 2.30.0](https://github.com/simolus3/drift/releases/tag/drift-2.30.0) menyediakan `drift_worker.js`; [rintisan sqlite3 2.9.4](https://github.com/simolus3/sqlite3.dart/releases/tag/sqlite3-2.9.4) menyediakan `sqlite3.wasm`. Nama aset berbeda dari contoh dokumentasi versi lain.
- URL unduhan, versi, checksum SHA-256 dan lokasi lisensi dicatat dalam `apps/game/web/vendor-assets.json`; notice paket ada di `web/vendor-licenses/`.

## Follow-up wajib, tanpa klaim lulus

T093/T094 menguji Android/iOS, Chrome Android, Safari/iOS, Firefox, Edge, hosting itch.io nyata, origin/iframe sandbox sebenarnya, storage eviction/private mode/quota, resize/touch, fresh install dan offline reload/caching. T055/T091 menguji offline data game dan recovery. T068 menguji wallet/provider/popups. T089 mengukur target 60 FPS pada perangkat nyata. Belum ada keputusan fallback platform final yang diperlukan karena baseline desktop web tidak terblokir.
