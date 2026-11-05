import 'package:flutter_test/flutter_test.dart';
import 'package:signal_zero/spikes/probe_payload.dart';

void main() {
  test('probe file round-trips an integer value', () {
    expect(ProbePayload.decode(const ProbePayload(7).encode()).value, 7);
  });

  test('probe rejects foreign versions and extra fields', () {
    for (final input in [
      '{"version":"foreign","value":2}',
      '{"version":"sz-probe-1","value":2,"secret":"ignored"}',
    ]) {
      expect(() => ProbePayload.decode(input), throwsFormatException);
    }
  });

  test('probe rejects fractional, negative and out-of-range values', () {
    for (final value in ['1.5', '-1', '1000001', 'true', 'null', '"3"']) {
      expect(
        () => ProbePayload.decode('{"version":"sz-probe-1","value":$value}'),
        throwsFormatException,
      );
    }
  });

  test('probe bounds bytes before parsing and rejects malformed JSON', () {
    expect(() => ProbePayload.decode('x' * 1025), throwsFormatException);
    expect(() => ProbePayload.decode('{'), throwsFormatException);
    expect(() => ProbePayload.decode('[]'), throwsFormatException);
  });
}
