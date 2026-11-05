# T005 — Verifier memakai domain Dart yang sama

Status: dipilih untuk baseline, 2026-11-05. Runtime tersedia mengikuti T003: Dart 3.9.2; package domain `packages/puzzle_domain`. Belum ada engine/verifier kompetitif pada Fase 01.

## Batas modul

Flutter renderer dan backend sama-sama mengimpor pure Dart domain. API hanya membaca challenge frozen dari DB dan menyerahkan puzzle/replay bytes/version ke process verifier. Domain mengembalikan terminal status, snapshots integer, normalized final program, score tuple, dan canonical replay bytes; tidak menerima skor client sebagai hasil authoritative. Normalisasi, hash, version label, salted commitment mengikuti [identity-and-versioning.md](../identity-and-versioning.md) dan [scoring.md](../scoring.md).

Verifier melakukan simulasi ulang bounded, **tidak** menjalankan pencarian solver untuk setiap submission. Solver/generator jalan pada publication worker terpisah; timeout tidak pernah berarti unsolvable atau optimal. Client runtime JS/native tidak dijadikan trusted execution: shared source mengurangi drift, golden vectors tetap wajib.

## Protokol process T058

Satu JSON request per proses awal (stdin), satu JSON response (stdout), diagnostics redacted di stderr. Hard payload limits diterapkan sebelum spawn; shell tidak digunakan. Process dipanggil melalui argument list tetap, tidak menginterpolasi user path/command.

Request internal `sz-verifier-job-1` memuat `job_id`, frozen `challenge_id/puzzle_spec/puzzle_hash`, `engine_version`, `rules_version`, replay envelope. Response sukses memuat `valid`, `terminal_state`, `completion_tick`, `normalized_replay`, `score`, `snapshot_digest`. Score/puzzle/version dicocokkan kembali oleh coordinator. Salt baru dibuat coordinator hanya sesudah validasi; salt tidak perlu masuk engine.

Status non-sukses: `INVALID_INPUT`, `UNSUPPORTED_VERSION`, `REPLAY_FAILED`, `RESOURCE_LIMIT`, `VERIFIER_TIMEOUT`, `INTERNAL_ERROR`. Jangan menyamakan infrastructure failure dengan puzzle gagal. Wall time maksimum awal **2 detik** per replay job; parent membunuh child jika lewat deadline dan mengembalikan retryable infra error. Memory ceiling deployment awal 128 MiB per worker via process/container limit; bila platform dev tidak mendukung cap, catat limit itu belum teruji. Batas lebih ketat T007 menang.

## PoC minimum yang sekarang bisa dijalankan

Jalankan di direktori sementara workspace. Ini hanya membuktikan mekanisme headless stdin/JSON tanpa Flutter/network, bukan engine/G2:

```powershell
$probePath = Join-Path $env:TEMP 'signal-zero-headless-probe.dart'
@'
import 'dart:convert';
import 'dart:io';
Future<void> main() async {
  final raw = await stdin.transform(utf8.decoder).join();
  final input = jsonDecode(raw) as Map<String, dynamic>;
  stdout.writeln(jsonEncode({'kind': 'headless-probe', 'echo': input['fixture']}));
}
'@ | Set-Content -LiteralPath $probePath -Encoding utf8
'{"fixture":"sz-engine-1"}' | dart --suppress-analytics run $probePath
```

Expected stdout: `{"kind":"headless-probe","echo":"sz-engine-1"}`. File temp dapat dihapus sesudah probe; tidak memuat secrets dan bukan service produksi.

## Golden harness dan version dispatch

T011 menyediakan vectors dengan input, expected state per tick, normalized replay, score, puzzle hash, commitment preimage/digest. T058 menjalankan corpus yang sama melalui native Dart worker dan client harness; browser test menjalankan domain di Dart-to-JS lewat Flutter web test runner hasil T003/T004. Hash snapshot berasal canonical integer JSON, bukan dump object/runtime float.

Target CLI sesudah T018/T058 mengimplementasikan harness:

```powershell
Push-Location packages/puzzle_domain
dart test test/golden_vectors_test.dart
Pop-Location
Push-Location services/verifier
dart test test/golden_equivalence_test.dart
Pop-Location
Push-Location apps/game
flutter test --platform chrome test/domain/golden_vectors_test.dart
Pop-Location
```

Commands harness adalah **kontrak file mendatang**, bukan hasil test Fase 01. CI memakai SDK tepat yang dikunci T003 dan corpus immutable; fixture expected ditinjau dari formal spec, bukan ditulis ulang otomatis dari engine terbaru.

Version registry allowlist baseline: schema `sz-puzzle-1` / `sz-replay-1`, encoding `sz-cjson-1`, engine `sz-engine-1`, rules `sz-rules-1`. Handler unknown ditolak, tidak fallback ke latest. Setiap Daily frozen mengunci exact labels; versi baru menambah handler/corpus, tidak mengganti perilaku historical replay. Generator `sz-generator-1` adalah provenance publication, bukan alasan untuk meregenerasi puzzle frozen.

## Alternatif dan batas bukti

Port TypeScript/Rust memerlukan reference interpreter serta corpus cross-language penuh; belum sebanding biaya baseline. Shared source tidak melindungi bug rules, corruption DB, signer yang berbohong, atau build berbeda dari artifact tercatat. G2 baru lulus setelah snapshot+score parity nyata pada target yang diuji, dengan version/artifact digest pada evidence.

Sumber primer: [Dart server IO](https://dart.dev/server/libraries), [Dart test tooling](https://dart.dev/tools/dart-test), [Dart JavaScript interoperability](https://dart.dev/interop/js-interop). Rancangan batas resource/worker adalah keputusan proyek, bukan jaminan dari runtime.
