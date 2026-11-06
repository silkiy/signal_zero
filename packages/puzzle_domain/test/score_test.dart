import 'dart:convert';
import 'dart:io';

import 'package:puzzle_domain/puzzle_domain.dart';
import 'package:test/test.dart';

void main() {
  test('lexicographic comparator respects each field and immutable tuple', () {
    final scores = [
      Score(0, 64, 64),
      Score(1, 1, 0),
      Score(1, 1, 1),
      Score(1, 2, 0),
    ];
    for (var i = 0; i < scores.length; i++) {
      expect(scores[i].compareTo(scores[i]), 0);
      expect(() => scores[i].toTuple().clear(), throwsUnsupportedError);
      for (var j = i + 1; j < scores.length; j++) {
        expect(scores[i].compareTo(scores[j]), lessThan(0));
        expect(scores[j].compareTo(scores[i]), greaterThan(0));
      }
    }
    expect(Score(1, 2, 1).toJson(), {
      'shift_count': 1,
      'completion_ticks': 2,
      'programming_actions': 1,
    });
    expect(Score(1, 2, 1), Score(1, 2, 1));
    expect(Score(1, 2, 1).hashCode, Score(1, 2, 1).hashCode);
  });
  test('bounds reject fabricated out of contract tuples', () {
    for (final tuple in [
      [-1, 1, 0],
      [65, 1, 0],
      [0, 0, 0],
      [0, 65, 0],
      [0, 1, -1],
      [0, 1, 65],
    ]) {
      expect(() => Score(tuple[0], tuple[1], tuple[2]), throwsArgumentError);
    }
  });
  final vectors = <Map<String, dynamic>>[
    for (final name in ['core.json', 'edge-cases.json'])
      for (final v
          in jsonDecode(
                File('../../specs/test-vectors/$name').readAsStringSync(),
              )['cases']
              as List)
        Map<String, dynamic>.from(v as Map),
  ];
  for (final v in vectors) {
    test('verified score ${v['id']} agrees with manual oracle', () {
      final puzzle = PuzzleSpec.fromJson(
        Map<String, dynamic>.from(v['puzzle'] as Map),
      );
      final replay = ReplaySpec.parse(
        v['submitted_replay_canonical'] as String,
        puzzle: puzzle,
      );
      final run = SimulationRunner(puzzle).run(replay);
      final expected = (v['expected'] as Map)['score'];
      if (expected == null) {
        expect(
          () => Score.fromSuccessfulRun(run),
          throwsA(
            isA<DomainException>().having(
              (e) => e.code,
              'code',
              'RUN_NOT_SUCCESSFUL',
            ),
          ),
        );
      } else {
        final score = Score.fromSuccessfulRun(run);
        expect(score.toTuple(), expected);
        expect(score.programmingActions, score.shiftCount);
        final normalized = SimulationRunner(puzzle).run(run.normalizedReplay!);
        expect(Score.fromSuccessfulRun(normalized), score);
      }
    });
  }
}
