import 'dart:convert';
import 'dart:io';
import 'package:puzzle_domain/puzzle_domain.dart';
import 'package:test/test.dart';

void main() {
  final vectors = <Map<String, dynamic>>[
    for (final file in ['core.json', 'edge-cases.json'])
      for (final row
          in jsonDecode(
                File('../../specs/test-vectors/$file').readAsStringSync(),
              )['cases']
              as List)
        Map<String, dynamic>.from(row as Map),
  ];
  for (final v in vectors) {
    test('runner ${v['id']} reproduces immutable full golden trace twice', () {
      final p = PuzzleSpec.fromJson(
        Map<String, dynamic>.from(v['puzzle'] as Map),
      );
      final r = ReplaySpec.parse(
        v['submitted_replay_canonical'] as String,
        puzzle: p,
      );
      final a = SimulationRunner(p).run(r);
      final b = SimulationRunner(p).run(r);
      final expected = Map<String, dynamic>.from(v['expected'] as Map);
      expect(
        a.snapshots.map((s) => s.toJson()).toList(),
        expected['snapshots'],
      );
      expect(a.snapshotHashes, b.snapshotHashes);
      expect(a.finalState.toJson(), b.finalState.toJson());
      expect(a.normalizedReplay?.toJson(), expected['normalized_replay']);
      expect(a.snapshots.length, lessThanOrEqualTo(p.tickLimit + 1));
      expect(() => a.snapshots.clear(), throwsUnsupportedError);
      expect(() => a.snapshotHashes.clear(), throwsUnsupportedError);
      expect(() => a.snapshots.first.signals.clear(), throwsUnsupportedError);
    });
  }
  test(
    'shared host hook counts normalization revalidation and cancellation aborts',
    () {
      final v = vectors.firstWhere(
        (v) => v['id'] == 'trim_unused_shift_after_success',
      );
      final p = PuzzleSpec.fromJson(
        Map<String, dynamic>.from(v['puzzle'] as Map),
      );
      final r = ReplaySpec.parse(
        v['submitted_replay_canonical'] as String,
        puzzle: p,
      );
      var steps = 0;
      final result = SimulationRunner(p).run(r, beforeStep: () => steps++);
      expect(result.isSuccess, isTrue);
      expect(steps, 4);
      expect(result.normalizedReplay!.shiftTicks, [2]);
      expect(
        () => SimulationRunner(
          p,
        ).run(r, beforeStep: () => throw StateError('cancelled')),
        throwsStateError,
      );
    },
  );
  test(
    'bound trace storage fails safely and never returns partial success',
    () {
      final v = vectors.first;
      final p = PuzzleSpec.fromJson(
        Map<String, dynamic>.from(v['puzzle'] as Map),
      );
      final r = ReplaySpec.parse(
        v['submitted_replay_canonical'] as String,
        puzzle: p,
      );
      expect(
        () => SimulationRunner(p, maxSnapshots: 1).run(r),
        throwsA(
          isA<DomainException>().having(
            (e) => e.code,
            'code',
            'SNAPSHOT_LIMIT',
          ),
        ),
      );
      expect(() => SimulationRunner(p, maxSnapshots: 0), throwsArgumentError);
      expect(() => SimulationRunner(p, maxSnapshots: 66), throwsArgumentError);
    },
  );
  test('runner rejects replay bound to another puzzle before work starts', () {
    final v = vectors.first;
    final p = PuzzleSpec.fromJson(
      Map<String, dynamic>.from(v['puzzle'] as Map),
    );
    final r = ReplaySpec.parse(
      v['submitted_replay_canonical'] as String,
      puzzle: p,
    );
    final other = PuzzleSpec.fromJson({
      ...p.toJson(),
      'tick_limit': p.tickLimit + 1,
    });
    var called = false;
    expect(
      () => SimulationRunner(other).run(r, beforeStep: () => called = true),
      throwsA(isA<DomainException>()),
    );
    expect(called, isFalse);
  });
}
