// Disposable T004 spike; excluded from the normal app via WEB_PROBE=false.
// Drift setup: https://drift.simonbinder.eu/platforms/web/
// Browser APIs: https://pub.dev/packages/web/versions/1.1.1
import 'dart:async';
import 'dart:convert';
import 'dart:js_interop';
import 'dart:math' as math;

import 'package:drift/drift.dart' as drift;
import 'package:drift/wasm.dart';
import 'package:flame/events.dart';
import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:web/web.dart' as web;

import 'probe_payload.dart';

// Read-only test observations, never credentials or production gameplay data.
@JS('signalZeroProbeStatus')
external set _browserStatus(JSString value);

class WebProbeApp extends StatelessWidget {
  const WebProbeApp({super.key});

  @override
  Widget build(BuildContext context) => MaterialApp(
    debugShowCheckedModeBanner: false,
    theme: ThemeData.dark(useMaterial3: true),
    home: const _ProbeScreen(),
  );
}

class _ProbeDatabase extends drift.GeneratedDatabase {
  _ProbeDatabase(super.executor);

  @override
  int get schemaVersion => 1;

  @override
  Iterable<drift.TableInfo> get allTables => const [];
}

class _ProbeScreen extends StatefulWidget {
  const _ProbeScreen();

  @override
  State<_ProbeScreen> createState() => _ProbeScreenState();
}

class _ProbeScreenState extends State<_ProbeScreen> {
  late final _ProbeGame _game;
  late final SemanticsHandle _semantics;
  late final web.HTMLInputElement _fileInput;
  _ProbeDatabase? _database;
  web.AudioContext? _audio;
  int _value = 0;
  bool _ready = false;
  bool _busy = false;
  bool _muted = false;
  String _storage = 'opening';
  String _error = '';
  String _audioState = 'not-started';
  String _lastOperation = 'opening';
  List<String> _missingFeatures = [];

  @override
  void initState() {
    super.initState();
    _semantics = SemanticsBinding.instance.ensureSemantics();
    _game = _ProbeGame(_publish);
    _fileInput = web.HTMLInputElement()
      ..id = 'probe-import'
      ..type = 'file'
      ..accept = '.json,application/json'
      ..style.display = 'none';
    _fileInput.addEventListener(
      'change',
      ((web.Event event) {
        unawaited(_guard(_import));
      }).toJS,
    );
    web.document.body!.append(_fileInput);
    unawaited(_guard(_open));
  }

  void _publish() {
    if (!mounted) return;
    _browserStatus = jsonEncode({
      'ready': _ready,
      'value': _value,
      'storage': _storage,
      'missingFeatures': _missingFeatures,
      'frames': _game.frames,
      'taps': _game.taps,
      'audio': _audioState,
      'muted': _muted,
      'operation': _lastOperation,
      'error': _error,
    }).toJS;
  }

  Future<void> _guard(Future<void> Function() action) async {
    if (!mounted || _busy) return;
    setState(() {
      _busy = true;
      _error = '';
    });
    try {
      await action();
    } catch (error) {
      _error = error.toString();
      _lastOperation = 'rejected';
    } finally {
      if (mounted) {
        setState(() => _busy = false);
        _publish();
      }
    }
  }

  Future<void> _open() async {
    final result = await WasmDatabase.open(
      databaseName: 'signal_zero_t004_probe',
      sqlite3Uri: Uri.parse('sqlite3.wasm'),
      driftWorkerUri: Uri.parse('drift_worker.js'),
    );
    if (!mounted) {
      await result.resolvedExecutor.close();
      return;
    }
    _storage = result.chosenImplementation.name;
    _missingFeatures = result.missingFeatures.map((e) => e.toString()).toList();
    final db = _database = _ProbeDatabase(result.resolvedExecutor);
    await db.customStatement(
      'CREATE TABLE IF NOT EXISTS probe (id INTEGER PRIMARY KEY CHECK(id=1), value INTEGER NOT NULL)',
    );
    await db.customStatement('INSERT OR IGNORE INTO probe VALUES (1, 0)');
    final row = await db
        .customSelect('SELECT value FROM probe WHERE id=1')
        .getSingle();
    _value = row.read<int>('value');
    _ready = true;
    _lastOperation = 'opened';
  }

  Future<void> _write(int value) async {
    if (value < 0 || value > 1000000) {
      throw const FormatException('Value limit.');
    }
    await _database!.customStatement('UPDATE probe SET value=? WHERE id=1', [
      value,
    ]);
    _value = value;
  }

  Future<void> _increment() async {
    await _write(_value + 1);
    _lastOperation = 'incremented';
  }

  Future<void> _export() async {
    final blob = web.Blob(
      [ProbePayload(_value).encode().toJS].toJS,
      web.BlobPropertyBag(type: 'application/json'),
    );
    final url = web.URL.createObjectURL(blob);
    final anchor = web.HTMLAnchorElement()
      ..href = url
      ..download = 'signal-zero-probe.json';
    web.document.body!.append(anchor);
    anchor.click();
    anchor.remove();
    Timer(const Duration(seconds: 1), () => web.URL.revokeObjectURL(url));
    _lastOperation = 'exported';
  }

  Future<void> _import() async {
    final files = _fileInput.files;
    if (files == null || files.length != 1) return;
    final file = files.item(0)!;
    if (file.size > ProbePayload.maxBytes) {
      throw const FormatException('File too large.');
    }
    final text = (await file.text().toDart).toDart;
    final payload = ProbePayload.decode(text);
    await _write(payload.value);
    _fileInput.value = '';
    _lastOperation = 'imported';
  }

  Future<void> _tone() async {
    if (_muted) {
      _lastOperation = 'muted-tone-skipped';
      return;
    }
    final audio = _audio ??= web.AudioContext();
    await audio.resume().toDart;
    final oscillator = audio.createOscillator();
    final gain = audio.createGain();
    gain.gain.value = 0.025;
    oscillator.frequency.value = 440;
    oscillator.connect(gain);
    gain.connect(audio.destination);
    oscillator.start();
    oscillator.stop(audio.currentTime + 0.08);
    _audioState = audio.state;
    _lastOperation = 'tone';
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('SIGNAL ZERO — Web compatibility probe')),
    body: SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            'T004 development probe; not gameplay or a save-file format.',
          ),
          Text('SQLite: $_storage · value: $_value · audio: $_audioState'),
          if (_error.isNotEmpty)
            Text(_error, style: const TextStyle(color: Colors.orange)),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              ElevatedButton(
                onPressed: _ready && !_busy ? () => _guard(_increment) : null,
                child: const Text('Increment'),
              ),
              ElevatedButton(
                onPressed: _ready && !_busy ? () => _guard(_export) : null,
                child: const Text('Export probe'),
              ),
              ElevatedButton(
                onPressed: _ready && !_busy ? () => _fileInput.click() : null,
                child: const Text('Import probe'),
              ),
              ElevatedButton(
                onPressed: !_busy ? () => _guard(_tone) : null,
                child: const Text('Play tone'),
              ),
              ElevatedButton(
                onPressed: () {
                  setState(() => _muted = !_muted);
                  _publish();
                },
                child: Text(_muted ? 'Unmute' : 'Mute'),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Semantics(
            label: 'Probe canvas',
            container: true,
            child: SizedBox(height: 220, child: GameWidget(game: _game)),
          ),
        ],
      ),
    ),
  );

  @override
  void dispose() {
    _semantics.dispose();
    _fileInput.remove();
    unawaited(_database?.close());
    _audio?.close();
    super.dispose();
  }
}

class _ProbeGame extends FlameGame with TapCallbacks {
  _ProbeGame(this.publish);
  final void Function() publish;
  int frames = 0;
  int taps = 0;
  double elapsed = 0;

  @override
  void update(double dt) {
    super.update(dt);
    elapsed += dt;
    frames++;
    if (frames % 30 == 0) publish();
  }

  @override
  void onTapDown(TapDownEvent event) {
    taps++;
    publish();
  }

  @override
  void render(Canvas canvas) {
    super.render(canvas);
    final y = size.y / 2;
    final paint = Paint()
      ..color = const Color(0xFF25E6F2)
      ..strokeWidth = 3;
    canvas.drawLine(Offset(32, y), Offset(size.x - 32, y), paint);
    canvas.drawCircle(Offset(32, y), 12, paint);
    canvas.drawCircle(Offset(size.x - 32, y), 12, paint);
    final x = 32 + (size.x - 64) * ((math.sin(elapsed * 2) + 1) / 2);
    canvas.drawCircle(
      Offset(x, y),
      7,
      Paint()..color = const Color(0xFFFF9B45),
    );
  }
}
