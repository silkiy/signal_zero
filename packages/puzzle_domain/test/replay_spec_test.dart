import 'dart:convert';
import 'dart:io';

import 'package:puzzle_domain/puzzle_domain.dart';
import 'package:test/test.dart';

void main() {
  final fixture =
      (jsonDecode(
                File(
                  '../../specs/test-vectors/scoring-cases.json',
                ).readAsStringSync(),
              )
              as Map<String, dynamic>)['identity_vector']
          as Map<String, dynamic>;
  final puzzle = PuzzleSpec.parse(fixture['canonical_puzzle'] as String);
  final original = Map<String, dynamic>.from(
    fixture['normalized_replay'] as Map,
  );
  ReplaySpec parse(Map<String, dynamic> json) =>
      ReplaySpec.parse(jsonEncode(json), puzzle: puzzle);
  Matcher code(String value) =>
      throwsA(isA<DomainException>().having((e) => e.code, 'code', value));

  test(
    'canonical replay hash and salted commitment match independent oracle',
    () {
      final replay = parse(original);
      expect(utf8.decode(replay.canonicalBytes), fixture['canonical_replay']);
      expect(replay.privateDigest, fixture['private_replay_digest']);
      expect(
        replay.publicCommitment(List.generate(32, (i) => i)),
        fixture['replay_commitment'],
      );
      expect(replay.schemaVersion, 'sz-replay-1');
      expect(replay.engineVersion, puzzle.engineVersion);
      expect(replay.rulesVersion, puzzle.rulesVersion);
    },
  );
  test('no SHIFT and inclusive final tick round-trip', () {
    for (final ticks in [
      <int>[],
      [1],
      [puzzle.tickLimit],
    ]) {
      final replay = parse({...original, 'shift_ticks': ticks});
      expect(
        ReplaySpec.decode(replay.canonicalBytes, puzzle: puzzle).shiftTicks,
        ticks,
      );
    }
  });
  test('trusted editor set normalizes independently of edit history', () {
    final replay = ReplaySpec.fromProgram(puzzle, {4, 2});
    final same = ReplaySpec.fromProgram(puzzle, {2, 4});
    expect(replay.canonicalBytes, same.canonicalBytes);
    expect(
      ReplaySpec.fromProgram(puzzle, replay.shiftTicks.toSet()).canonicalBytes,
      replay.canonicalBytes,
    );
  });
  test('trims tail only after verified completion and is idempotent', () {
    final replay = ReplaySpec.fromProgram(puzzle, {2, 4});
    final trimmed = replay.trimAfterVerifiedSuccess(2);
    expect(trimmed.shiftTicks, [2]);
    expect(
      trimmed.trimAfterVerifiedSuccess(2).canonicalBytes,
      trimmed.canonicalBytes,
    );
    expect(trimmed.privateDigest, fixture['private_replay_digest']);
    expect(replay.shiftTicks, [2, 4]);
    expect(() => replay.trimAfterVerifiedSuccess(0), code('INVALID_TICK'));
    expect(() => replay.trimAfterVerifiedSuccess(5), code('INVALID_TICK'));
  });
  test(
    'untrusted duplicate and unordered actions are rejected, not deduplicated',
    () {
      for (final ticks in [
        [2, 2],
        [4, 2],
      ]) {
        expect(
          () => parse({...original, 'shift_ticks': ticks}),
          code('NON_CANONICAL_ACTIONS'),
        );
      }
    },
  );
  test('validates the entire submitted list before a potential success', () {
    for (final ticks in [
      [0],
      [2, 5],
      [2, 1.5],
      [true],
      [-1],
    ]) {
      expect(
        () => parse({...original, 'shift_ticks': ticks}),
        throwsA(isA<DomainException>()),
      );
    }
    expect(
      () => parse({...original, 'shift_ticks': List.filled(65, 1)}),
      code('LIMIT_EXCEEDED'),
    );
  });
  test(
    'raw lexical integer rules and duplicate keys apply to replay input',
    () {
      final raw = fixture['canonical_replay'] as String;
      for (final token in ['-0', '2.0', '2e0']) {
        expect(
          () => ReplaySpec.parse(
            raw.replaceAll('[2]', '[$token]'),
            puzzle: puzzle,
          ),
          throwsA(isA<DomainException>()),
        );
      }
      expect(
        () => ReplaySpec.parse(
          raw.replaceFirst('{', '{"shift_ticks":[],'),
          puzzle: puzzle,
        ),
        code('DUPLICATE_FIELD'),
      );
    },
  );
  test('schema, engine, rules, puzzle identity and fields are strict', () {
    for (final field in ['schema_version', 'engine_version', 'rules_version']) {
      expect(
        () => parse({...original, field: 'unsupported'}),
        code('UNSUPPORTED_VERSION'),
      );
    }
    expect(
      () => parse({...original, 'puzzle_hash': '0x${'0' * 64}'}),
      code('PUZZLE_MISMATCH'),
    );
    expect(
      () => parse({...original, 'title': 'not-gameplay'}),
      code('UNKNOWN_FIELD'),
    );
    final missing = {...original}..remove('shift_ticks');
    expect(() => parse(missing), code('MISSING_FIELD'));
  });
  test('caller cannot mutate ticks or canonical bytes after validation', () {
    final input = {
      ...original,
      'shift_ticks': [2],
    };
    final replay = parse(input);
    (input['shift_ticks'] as List).clear();
    expect(replay.shiftTicks, [2]);
    expect(() => replay.shiftTicks.add(3), throwsUnsupportedError);
    expect(() => replay.canonicalBytes[0] = 0, throwsUnsupportedError);
  });
  test('byte bounds are enforced before decoding', () {
    expect(
      () => ReplaySpec.decode(List.filled(16385, 32), puzzle: puzzle),
      code('INPUT_LIMIT'),
    );
    expect(
      () => ReplaySpec.parse(' ' * 16385, puzzle: puzzle),
      code('INPUT_LIMIT'),
    );
    expect(
      () => ReplaySpec.decode([0xff], puzzle: puzzle),
      throwsA(isA<DomainException>()),
    );
  });
  test('salt must be exactly 32 validated bytes and every byte is bound', () {
    final replay = parse(original);
    for (final salt in [
      <int>[],
      List.filled(31, 0),
      List.filled(32, -1),
      List.filled(32, 256),
    ]) {
      expect(() => replay.publicCommitment(salt), code('INVALID_SALT'));
    }
    final zeros = List.filled(32, 0);
    final changed = [...zeros]..[31] = 1;
    expect(
      replay.publicCommitment(zeros),
      isNot(replay.publicCommitment(changed)),
    );
  });
}
