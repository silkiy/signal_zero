import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:puzzle_domain/puzzle_domain.dart';
import 'package:test/test.dart';

// Host-side fixture validation only. Expected transitions are manual oracle
// data; this file contains no movement algorithm or replacement game engine.
Map<String, Object?> object(Object? value) =>
    (value as Map).cast<String, Object?>();

List<Object?> array(Object? value) => (value as List).cast<Object?>();

// Remove only CR in CRLF byte pairs. UTF-8 bytes, lone CR, BOM, whitespace,
// trailing newline and JSON formatting are otherwise unchanged.
List<int> sourceBytesWithLf(List<int> bytes) => [
  for (var i = 0; i < bytes.length; i++)
    if (!(bytes[i] == 13 && i + 1 < bytes.length && bytes[i + 1] == 10))
      bytes[i],
];

Directory repositoryRoot() {
  var directory = Directory.current.absolute;
  while (!File('${directory.path}/specs/rules.md').existsSync()) {
    final parent = directory.parent;
    if (parent.path == directory.path) {
      throw StateError('Run from the repository or a directory inside it.');
    }
    directory = parent;
  }
  return directory;
}

void main() {
  final root = repositoryRoot();
  File source(String path) => File('${root.path}/$path');
  Map<String, Object?> read(String path) =>
      object(jsonDecode(source(path).readAsStringSync()));

  final originalRules = read('specs/test-vectors/rules-cases.json');
  final originalScores = read('specs/test-vectors/scoring-cases.json');
  final originals = {
    for (final item in array(originalRules['cases']))
      object(item)['id'] as String: object(item),
  };
  final suites = [
    read('specs/test-vectors/core.json'),
    read('specs/test-vectors/edge-cases.json'),
  ];
  final vectors = [
    for (final suite in suites)
      for (final value in array(suite['cases'])) object(value),
  ];

  test(
    'corpus retains every manual case and the final-program tail example',
    () {
      expect(suites.map((s) => s['suite']), ['core', 'edge-cases']);
      expect(array(suites[0]['cases']), hasLength(5));
      expect(array(suites[1]['cases']), hasLength(9));
      expect(vectors, hasLength(14));
      final ids = vectors.map((v) => v['id'] as String).toSet();
      expect(ids, hasLength(14));
      expect(ids, {...originals.keys, 'trim_unused_shift_after_success'});
      expect(
        vectors.fold<int>(
          0,
          (count, v) =>
              count + array(object(v['expected'])['snapshots']).length,
        ),
        38,
      );
    },
  );

  test(
    'source provenance normalizes CRLF only across Windows and LF checkouts',
    () {
      // BOM, UTF-8 e-acute, lone CR, spaces and trailing newline stay intact.
      final lf = [239, 187, 191, 195, 169, 13, 120, 10, 32, 9, 10];
      final crlf = [239, 187, 191, 195, 169, 13, 120, 13, 10, 32, 9, 13, 10];
      expect(sourceBytesWithLf(crlf), lf);
      expect(sourceBytesWithLf(lf), lf);
      expect(
        sha256.convert(sourceBytesWithLf(crlf)).toString(),
        sha256.convert(lf).toString(),
      );
    },
  );

  test(
    'suite provenance points to unchanged independently authored sources',
    () {
      for (final suite in suites) {
        expect(suite['schema_version'], 'sz-golden-1');
        expect(suite['engine_version'], engineVersion);
        expect(suite['rules_version'], rulesVersion);
        expect(suite['encoding_version'], 'sz-cjson-1');
        expect(suite['limits_version'], 'sz-limits-1');
        final provenance = object(suite['provenance']);
        expect(provenance['source_hash_encoding'], 'sha256:utf8:crlf-to-lf');
        for (final item in array(provenance['source_artifacts'])) {
          final artifact = object(item);
          final bytes = sourceBytesWithLf(
            source(artifact['path'] as String).readAsBytesSync(),
          );
          expect('0x${sha256.convert(bytes)}', artifact['sha256']);
        }
      }
    },
  );

  for (final vector in vectors) {
    test(
      'golden ${vector['id']} has valid identities and a complete manual trace',
      () {
        final puzzleJson = object(vector['puzzle']);
        final puzzle = PuzzleSpec.fromJson(puzzleJson);
        expect(utf8.decode(puzzle.canonicalBytes), vector['puzzle_canonical']);
        expect(puzzle.puzzleHash, vector['puzzle_hash']);
        expect(
          PuzzleSpec.parse(vector['puzzle_canonical'] as String).toJson(),
          puzzle.toJson(),
        );

        final submitted = ReplaySpec.parse(
          vector['submitted_replay_canonical'] as String,
          puzzle: puzzle,
        );
        expect(submitted.toJson(), vector['submitted_replay']);
        expect(
          utf8.decode(submitted.canonicalBytes),
          vector['submitted_replay_canonical'],
        );
        expect(submitted.privateDigest, vector['submitted_replay_digest']);
        expect(
          ReplaySpec.decode(submitted.canonicalBytes, puzzle: puzzle).toJson(),
          submitted.toJson(),
        );

        final provenance = object(vector['provenance']);
        expect(array(provenance['rule_refs']), isNotEmpty);
        expect(provenance['manual_walkthrough'], isNotEmpty);
        final original = originals[provenance['rules_case_id']]!;
        expect(puzzleJson, original['puzzle']);
        expect(
          submitted.shiftTicks,
          vector['id'] == 'trim_unused_shift_after_success'
              ? [2, 4]
              : original['shift_ticks'],
        );
        final expected = object(vector['expected']);
        final snapshots = array(expected['snapshots']).map(object).toList();
        expect(snapshots, original['expected_snapshots']);
        final terminal = object(expected['terminal']);
        expect(terminal['reason'], original['expected_terminal_reason']);
        expect(terminal, {
          'tick': snapshots.last['tick'],
          'status': snapshots.last['status'],
          'reason': snapshots.last['reason'],
        });
        expect(terminal['tick'], inInclusiveRange(1, puzzle.tickLimit));
        expect(terminal['status'], anyOf('SUCCEEDED', 'FAILED'));

        final nodes = array(puzzleJson['nodes']).map(object).toList();
        final nodeIds = nodes.map((n) => n['id']).toSet();
        final sourceIds = nodes
            .where((n) => n['kind'] == 'source')
            .map((n) => n['id'])
            .toSet();
        expect(snapshots.first['tick'], 0);
        expect(snapshots.first['signals'], {
          for (final id in sourceIds) id: id,
        });
        for (var tick = 0; tick < snapshots.length; tick++) {
          final snapshot = snapshots[tick];
          expect(snapshot['tick'], tick);
          final signals = object(snapshot['signals']);
          expect(signals.keys.toSet(), sourceIds);
          expect(signals.values.every(nodeIds.contains), isTrue);
          if (tick < snapshots.length - 1) {
            expect(snapshot['status'], 'RUNNING');
            expect(snapshot['reason'], '');
          }
          for (final arrivals in object(snapshot['target_arrivals']).values) {
            final tokens = array(arrivals).cast<String>();
            expect(tokens, orderedEquals(tokens.toList()..sort()));
            expect(tokens.toSet(), hasLength(tokens.length));
            expect(tokens.every(sourceIds.contains), isTrue);
          }
        }

        if (terminal['status'] == 'SUCCEEDED') {
          final normalized = submitted.trimAfterVerifiedSuccess(
            terminal['tick'] as int,
          );
          expect(normalized.toJson(), expected['normalized_replay']);
          expect(
            utf8.decode(normalized.canonicalBytes),
            expected['normalized_replay_canonical'],
          );
          expect(
            normalized.privateDigest,
            expected['normalized_replay_digest'],
          );
          expect(
            normalized
                .trimAfterVerifiedSuccess(terminal['tick'] as int)
                .toJson(),
            normalized.toJson(),
          );
          final finalTicks = array(
            object(expected['normalized_replay'])['shift_ticks'],
          );
          expect(expected['score'], [
            finalTicks.length,
            terminal['tick'],
            finalTicks.length,
          ]);
          expect(
            ReplaySpec.fromProgram(
              puzzle,
              finalTicks.cast<int>().toSet(),
            ).toJson(),
            normalized.toJson(),
          );
        } else {
          for (final field in [
            'normalized_replay',
            'normalized_replay_canonical',
            'normalized_replay_digest',
            'score',
          ]) {
            expect(expected[field], isNull);
          }
        }
      },
    );
  }

  test('reviewed SHA-256 and salted commitment anchor is retained exactly', () {
    final identity = object(originalScores['identity_vector']);
    final vector = vectors.singleWhere((v) => v['id'] == 'shift_before_move');
    final expected = object(vector['expected']);
    expect(vector['puzzle_canonical'], identity['canonical_puzzle']);
    expect(vector['puzzle_hash'], identity['puzzle_hash']);
    expect(
      expected['normalized_replay_canonical'],
      identity['canonical_replay'],
    );
    expect(
      expected['normalized_replay_digest'],
      identity['private_replay_digest'],
    );
    final puzzle = PuzzleSpec.fromJson(object(vector['puzzle']));
    final replay = ReplaySpec.parse(
      identity['canonical_replay'] as String,
      puzzle: puzzle,
    );
    expect(
      replay.publicCommitment(List<int>.generate(32, (i) => i)),
      identity['replay_commitment'],
    );
  });
}
