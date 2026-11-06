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
  for (final vector in vectors) {
    test(
      'manual golden trace ${vector['id']} matches every tick and terminal priority',
      () {
        final puzzle = PuzzleSpec.fromJson(
          Map<String, dynamic>.from(vector['puzzle'] as Map),
        );
        final replay = ReplaySpec.parse(
          vector['submitted_replay_canonical'] as String,
          puzzle: puzzle,
        );
        final expected = (vector['expected'] as Map)['snapshots'] as List;
        final engine = TickEngine(puzzle);
        var state = EngineState.initial(puzzle);
        expect(state.toJson(), expected.first);
        for (final row in expected.skip(1)) {
          state = engine.step(
            state,
            shift: replay.shiftTicks.contains(state.tick + 1),
          );
          expect(
            state.toJson(),
            row,
            reason: '${vector['id']} tick ${state.tick}',
          );
        }
        expect(state.isTerminal, isTrue);
        expect(identical(engine.step(state, shift: true), state), isTrue);
        expect(state.diagnosticIds, [...state.diagnosticIds]..sort());
      },
    );
  }
  test(
    'tick0 is never evaluated and terminal from another puzzle is rejected',
    () {
      final puzzle = PuzzleSpec.fromJson(
        Map<String, dynamic>.from(vectors.first['puzzle'] as Map),
      );
      final initial = EngineState.initial(puzzle);
      expect(
        () => TerminalEvaluator(puzzle).evaluate(initial),
        throwsA(isA<DomainException>()),
      );
      final other = PuzzleSpec.fromJson({
        ...puzzle.toJson(),
        'tick_limit': puzzle.tickLimit + 1,
      });
      final terminal = TickEngine(
        puzzle,
      ).step(TickEngine(puzzle).step(initial));
      expect(terminal.isTerminal, isTrue);
      expect(
        () => TickEngine(other).step(terminal),
        throwsA(isA<DomainException>()),
      );
    },
  );
  for (final noRoute in [true, false]) {
    test(
      'priority ${noRoute ? "NO_ROUTE" : "EDGE_COLLISION"} beats concurrent failure and tick limit',
      () {
        final puzzle = PuzzleSpec.fromJson({
          'schema_version': 'sz-puzzle-1',
          'engine_version': engineVersion,
          'rules_version': rulesVersion,
          'tick_limit': 2,
          'nodes': [
            for (final id in ['a', 'b', 'c']) {'id': id, 'kind': 'source'},
            for (final id in ['u', 'v', 'w']) {'id': id, 'kind': 'relay'},
            for (final id in ['x', 'y', 'z']) {'id': id, 'kind': 'target'},
          ],
          'edges': [
            {'id': 'au', 'from': 'a', 'to': 'u', 'port': 0},
            {'id': 'bv', 'from': 'b', 'to': 'v', 'port': 0},
            {'id': 'cw', 'from': 'c', 'to': 'w', 'port': 0},
            {'id': 'uv', 'from': 'u', 'to': 'v', 'port': 0},
            {'id': 'vu', 'from': 'v', 'to': 'u', 'port': 0},
            if (!noRoute) {'id': 'wx', 'from': 'w', 'to': 'x', 'port': 0},
          ],
        });
        final engine = TickEngine(puzzle);
        final result = engine.step(engine.step(EngineState.initial(puzzle)));
        expect(result.tick, 2);
        expect(result.status, RunStatus.failed);
        expect(
          result.reason,
          noRoute ? TerminalReason.noRoute : TerminalReason.edgeCollision,
        );
        expect(result.signals, {'a': 'v', 'b': 'u', 'c': noRoute ? 'w' : 'x'});
        expect(result.diagnosticIds, noRoute ? ['c'] : ['uv', 'vu']);
      },
    );
  }
}
