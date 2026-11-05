import 'dart:convert';

/// Disposable spike format. This is NOT the puzzle/share/backup format.
class ProbePayload {
  const ProbePayload(this.value);

  final int value;
  static const maxBytes = 1024;

  String encode() => jsonEncode({'version': 'sz-probe-1', 'value': value});

  static ProbePayload decode(String input) {
    if (utf8.encode(input).length > maxBytes) {
      throw const FormatException('Probe file exceeds 1024 bytes.');
    }
    final data = jsonDecode(input);
    if (data is! Map<String, dynamic> ||
        data.length != 2 ||
        data['version'] != 'sz-probe-1' ||
        data['value'] is! int) {
      throw const FormatException('Invalid probe schema/version.');
    }
    final value = data['value'] as int;
    if (value < 0 || value > 1000000) {
      throw const FormatException('Probe value outside 0..1000000.');
    }
    return ProbePayload(value);
  }
}
