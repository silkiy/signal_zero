# SIGNAL ZERO

Game logic-puzzle jaringan sinyal untuk Game Off 2026. Pemain memprogram satu aksi global, **SHIFT**, pada timeline untuk menyinkronkan sinyal. Gameplay ditargetkan offline dan guest-first; kompetisi Base bersifat opsional.

**Status saat ini: fondasi Fase 01.** Spesifikasi aturan/identitas/batas sudah ditulis, workspace Flutter/Flame tersedia, dan pemeriksaan statis serta smoke test dasar telah berjalan. Engine, puzzle playable, 15 level, backend, dan kontrak belum diimplementasikan. Uji kompatibilitas browser tercatat terpisah pada [evidence T004](tasks/evidence/T004.md) saat tersedia; keberhasilan build saja bukan bukti seluruh fitur web kompatibel.

## Dokumen kerja

- [PRD v2.2](SIGNAL_ZERO_PRD_v2.2.md): baseline produk, tidak diubah oleh keputusan implementasi.
- [Rencana](tasks/plan.md), [checklist task](tasks/todo.md), dan [template penugasan agent](tasks/agent-task-template.md).
- [Rules](specs/rules.md), [identitas/versioning](specs/identity-and-versioning.md), [scoring](specs/scoring.md), dan [resource limits](specs/resource-limits.md).
- [Verifikasi aturan jam](specs/jam-compliance.md): sumber/tanggal pemeriksaan; periksa ulang saat T096.
- [Petunjuk aplikasi Flutter](apps/game/README.md).

## Toolchain yang dikunci

| Komponen | Versi |
|---|---|
| Flutter | 3.35.6, revision `9f455d2486bcb28cad87b062475f42edc959f636` |
| Dart | 3.9.2 |
| Flame | 1.35.1 |
| Drift | 2.30.0 |
| web | 1.1.1 |

Pin ada di [toolchain.json](toolchain.json), [.fvmrc](.fvmrc), manifest, dan lockfile aplikasi. Pastikan Flutter/Dart yang dipakai sesuai pin; proyek tidak mewajibkan FVM jika SDK yang tepat sudah tersedia. Python 3.11+ digunakan untuk pemeriksaan spesifikasi dan server probe. Node/Playwright hanya diperlukan untuk otomasi browser probe.

## Menjalankan fondasi aplikasi

Jalankan dari root repository dalam PowerShell:

```powershell
flutter --version
dart --version
Push-Location apps/game
flutter pub get
flutter analyze
flutter test
flutter run -d chrome
Pop-Location
```

Tampilan default berisi **SIGNAL ZERO**, teks “Fondasi Flutter + Flame”, dan area Flame kosong. Tidak membutuhkan akun atau wallet. Ini shell pengembangan, belum tutorial atau game yang dapat ditamatkan.

Paket domain dapat dijalankan dengan SDK Dart tanpa renderer:

```powershell
Push-Location packages/puzzle_domain
dart pub get
dart run tool/smoke.dart
Pop-Location
```

Saat ini paket tersebut hanya menyediakan label versi. Engine deterministik mengikuti task T009–T021.

## Memeriksa spesifikasi

```powershell
python tools/specs/check_specs.py
python -m unittest discover -s tools/specs -p 'test_*.py' -v
python tools/specs/check_specs.py --probe
```

Checker memeriksa konsistensi vectors manual, canonical hash/commitment, scoring arithmetic, dan corpus batas. `--probe` mengukur input/key-set sintetis desktop; hasilnya bukan performa solver/mobile. Bukti rinci ada pada [T001](tasks/evidence/T001.md), [T002](tasks/evidence/T002.md), dan [T007](tasks/evidence/T007.md).

## Probe web T004

Probe hanya aktif dengan `--dart-define=WEB_PROBE=true`; build biasa tetap memakai shell. Perintah build, server iframe, dan browser test ada pada [README aplikasi](apps/game/README.md#probe-web-t004). Probe menguji Flame, persistence Drift, file import/export dan audio sederhana; format file probe bukan Share Code atau `.szsave` produk.

## Struktur

```text
apps/game/                 Flutter + Flame; spike web terisolasi
packages/puzzle_domain/    SDK-only domain foundation
specs/                    Rules, kontrak data, keputusan dan vectors
tasks/                    Rencana, checklist dan evidence
tools/                    Checker spesifikasi dan tooling probe
```

Backend/verifier/scheduler/indexer dan Foundry belum dibuat. [Keputusan backend](specs/decisions/backend.md) menetapkan rencana implementasinya; tidak berarti service sudah berjalan.

## Batas lingkungan dan kontribusi

- Android SDK tersedia pada lingkungan pengembangan awal, tetapi lisensi belum seluruhnya diterima. Build Android belum dinyatakan lolos; penerimaan lisensi tidak dilakukan otomatis.
- Build/signing iOS memerlukan toolchain Apple; belum dapat diverifikasi dari Windows. Target tersebut tetap dilacak pada T093.
- Dalam sandbox Codex, Flutter/Dart menulis SDK/Pub cache di luar workspace. Gunakan izin eksekusi yang sesuai; proses yang tersangkut pada cache/startup lock bukan bukti command sudah selesai. Catatan ini untuk pengembangan, bukan alur pemain.
- Ikuti satu task siap dengan ownership file jelas. Simpan command/hasil nyata pada evidence dan jangan mencentang task yang masih memiliki AC wajib pending.
- Fondasi dan dokumentasi ini dibuat dengan bantuan AI. Disclosure final, kredit/lisensi dependency, repository publik dan submission jam dituntaskan pada T096; belum ada klaim game sudah dikirim atau dipublikasikan.
