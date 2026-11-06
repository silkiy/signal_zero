# SIGNAL ZERO — aplikasi Flutter

Workspace Fase 01 untuk Flutter 3.35.6 / Dart 3.9.2, Flame 1.35.1, Drift 2.30.0, dan web 1.1.1. Manifest memakai versi tepat; simpan `pubspec.lock` untuk aplikasi ini. Lihat [README root](../../README.md) dan [toolchain.json](../../toolchain.json).

Shell default menampilkan judul SIGNAL ZERO, “Fondasi Flutter + Flame”, dan area Flame kosong. Core domain headless dan tiga asset level awal sudah terverifikasi pada Fase 02. Board, timeline, kontrol dan progress gameplay belum dihubungkan ke shell. Spike browser hanya dibuka melalui compile-time flag khusus.

## Setup dan verifikasi

Dari folder `apps/game`:

```powershell
flutter pub get
flutter analyze
flutter test
flutter run -d chrome
```

Smoke test saat fondasi dibuat mencakup satu widget shell guest dan empat test codec file probe. Pemeriksaan tersebut bukan pengujian engine atau persistence gameplay. Lihat [evidence T003](../../tasks/evidence/T003.md) untuk command, versi dan keterbatasan.

Untuk target Android, pilih device yang tersedia melalui `flutter devices` lalu gunakan `flutter run -d <device-id>`. Android release build dan iOS belum dinyatakan terverifikasi. iOS memerlukan Mac/Xcode; lisensi SDK Android yang belum diterima harus ditangani melalui proses setup pengembang.

## Probe web T004

Dari folder `apps/game`, buat artifact probe:

```powershell
flutter build web --release --no-web-resources-cdn --dart-define=WEB_PROBE=true
```

Setelah build berhasil, kembali ke root repository lalu jalankan server berikut di terminal tersendiri:

```powershell
python tools/web_probe_server.py --build apps/game/build/web
```

- Halaman langsung: `http://127.0.0.1:8191/`.
- Host iframe sandbox terpisah: `http://localhost:8192/`.

Probe menguji render Flame, counter SQLite melalui Drift, reload persistence, file export/import berukuran terbatas, serta tone procedural melalui user gesture dan mute. Data/format probe adalah eksperimen kompatibilitas, bukan progress, backup atau puzzle produk. Uji offline setelah asset hangat berbeda dari fresh offline load dan harus dilaporkan terpisah.

Untuk otomasi pada Chrome yang sudah terpasang, siapkan Playwright lokal dari **root repository** jika belum tersedia:

```powershell
npm install --prefix .tools/browser playwright@1.62.1
$env:NODE_PATH = (Resolve-Path .tools/browser/node_modules).Path
node tools/web_probe_browser.cjs
```

`NODE_PATH` juga dapat menunjuk bundle dependency Playwright yang sudah tersedia pada lingkungan agent; tidak perlu menginstal ulang jika versinya sesuai. Script memakai isolated browser contexts dan channel `chrome`, tanpa memakai profil Chrome pribadi. Hasil JSON, screenshot dan file contoh ditulis ke `tasks/evidence/`. Script perlu server probe tetap berjalan.

Gunakan `flutter run -d chrome` atau build berikut untuk kembali ke shell normal:

```powershell
flutter build web --release
```

Jangan menyimpulkan seluruh platform/fitur web lolos dari keberhasilan build. Status runtime dan batas browser/iframe/offline dicatat pada [evidence T004](../../tasks/evidence/T004.md) dan [keputusan web](../../specs/decisions/web-compatibility.md). Chrome desktop direct/iframe sudah lulus; platform lain dan offline reload belum diuji.

## Domain dan file bersama

`../../packages/puzzle_domain` adalah paket Dart tanpa Flutter/Flame/network/wallet. Paket menyediakan schema puzzle/replay, engine sinkron, snapshot immutable, skor dan solver terbatas. Jalankan `dart pub get`, `dart run tool/smoke.dart`, `dart test`, dan `dart analyze --fatal-infos` dari folder paket. Dua CLI menerima gameplay puzzle/replay terversi; lihat [README root](../../README.md#headless-content-tools).

Perluas modul yang sudah ada; jangan membuat engine, database atau renderer kedua karena path rencana pada task berbeda. Output build, `.dart_tool`, lokal SDK config dan credential diabaikan oleh `.gitignore`. Lockfile aplikasi tetap disimpan.

## Level awal Fase 02

Tiga asset `assets/levels/level_01.json` sampai `level_03.json` terdaftar pada pubspec. Envelope `sz-curated-1` menyimpan gameplay pada child `puzzle`; metadata pembelajaran/layout/solusi/baseline tidak masuk puzzle hash. Suite aplikasi kini memiliki delapan test, termasuk tiga pemeriksaan bundle asset, replay dan bukti skor optimal. Board yang merender layout serta tutorial interaktif dikerjakan pada Fase 03. Lihat [validasi headless](../../docs/validation/playable-core.md).
