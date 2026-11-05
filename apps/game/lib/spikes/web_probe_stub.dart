import 'package:flutter/material.dart';

/// The compatibility spike is opt-in and web-only, never the mobile game flow.
class WebProbeApp extends StatelessWidget {
  const WebProbeApp({super.key});

  @override
  Widget build(BuildContext context) => const MaterialApp(
    home: Scaffold(body: Center(child: Text('Web probe requires a browser.'))),
  );
}
