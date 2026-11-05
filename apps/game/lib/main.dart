import 'package:flame/game.dart';
import 'package:flutter/material.dart';

import 'spikes/web_probe_stub.dart'
    if (dart.library.js_interop) 'spikes/web_probe.dart';

void main() {
  runApp(
    const bool.fromEnvironment('WEB_PROBE')
        ? const WebProbeApp()
        : const SignalZeroApp(),
  );
}

class SignalZeroApp extends StatelessWidget {
  const SignalZeroApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'SIGNAL ZERO',
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark(useMaterial3: true),
      home: Scaffold(
        appBar: AppBar(title: const Text('SIGNAL ZERO')),
        body: Column(
          children: [
            const Padding(
              padding: EdgeInsets.all(24),
              child: Text('Fondasi Flutter + Flame'),
            ),
            Expanded(child: GameWidget.controlled(gameFactory: FlameGame.new)),
          ],
        ),
      ),
    );
  }
}
