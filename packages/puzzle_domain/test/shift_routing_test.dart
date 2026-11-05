import 'dart:convert';
import 'dart:io';

import 'package:puzzle_domain/puzzle_domain.dart';
import 'package:test/test.dart';

List<Map<String, dynamic>> ruleCases() {
  final file =
      jsonDecode(
            File(
              '../../specs/test-vectors/rules-cases.json',
            ).readAsStringSync(),
          )
          as Map<String, dynamic>;
  return (file['cases'] as List).cast<Map<String, dynamic>>();
}

PuzzleSpec puzzleFor(String name) => PuzzleSpec.fromJson(
  ruleCases().singleWhere((row) => row['id'] == name)['puzzle']
      as Map<String, dynamic>,
);

void main() {
  test('SHIFT movement matches all manually authored SHIFT traces', () {
    for (final row in ruleCases().where(
      (row) => (row['shift_ticks'] as List).isNotEmpty,
    )) {
      final puzzle = PuzzleSpec.fromJson(row['puzzle'] as Map<String, dynamic>);
      final engine = TickEngine(puzzle);
      final shiftTicks = (row['shift_ticks'] as List).cast<int>().toSet();
      var state = EngineState.initial(puzzle);
      for (final expected in (row['expected_snapshots'] as List).skip(1)) {
        state = engine.step(state, shift: shiftTicks.contains(state.tick + 1));
        for (final field in [
          'tick',
          'signals',
          'switches',
          'used_edges',
          'target_arrivals',
        ]) {
          expect(
            state.toJson()[field],
            expected[field],
            reason: '${row['id']} tick ${expected['tick']} $field',
          );
        }
      }
    }
  });

  test(
    'SHIFT changes routing before an occupied switch moves in the same tick',
    () {
      final puzzle = puzzleFor('shift_before_move');
      final engine = TickEngine(puzzle);
      final first = engine.step(EngineState.initial(puzzle));
      expect(first.signals, {'a': 's'});
      expect(first.switches, {'s': 0});
      final second = engine.step(first, shift: true);
      expect(second.switches, {'s': 1});
      expect(second.usedEdges, {'a': 'st'});
      expect(second.signals, {'a': 't'});
      expect(first.switches, {'s': 0});
      expect(first.signals, {'a': 's'});
      expect(() => second.switches.clear(), throwsUnsupportedError);
    },
  );

  test('SHIFT toggles every switch even before tokens occupy any switch', () {
    final puzzle = puzzleFor('global_shift');
    final engine = TickEngine(puzzle);
    final initial = EngineState.initial(puzzle);
    final first = engine.step(initial, shift: true);
    expect(first.switches, {'u': 1, 'v': 1});
    expect(first.signals, {'a': 'u', 'b': 'v'});
    expect(initial.switches, {'u': 0, 'v': 0});
    final second = engine.step(first);
    expect(second.switches, {'u': 1, 'v': 1});
    expect(second.signals, {'a': 'x', 'b': 'y'});
  });

  test(
    'global inversion preserves relative difference of initial switch bits',
    () {
      final editable =
          jsonDecode(jsonEncode(puzzleFor('global_shift').toJson()))
              as Map<String, dynamic>;
      for (final node in editable['nodes'] as List) {
        if (node['id'] == 'u') node['initial_state'] = 1;
      }
      final puzzle = PuzzleSpec.fromJson(editable);
      final engine = TickEngine(puzzle);
      final initial = EngineState.initial(puzzle);
      final first = engine.step(initial);
      final second = engine.step(first, shift: true);
      expect(initial.switches, {'u': 1, 'v': 0});
      expect(second.switches, {'u': 0, 'v': 1});
      expect(second.usedEdges, {'a': 'uy', 'b': 'vy'});
      expect(second.targetArrivals, {
        'y': ['a', 'b'],
      });
    },
  );

  test('successive SHIFT ticks invert once each and remain deterministic', () {
    final puzzle = puzzleFor('shift_before_move');
    List<Map<String, Object?>> run() {
      final engine = TickEngine(puzzle);
      var state = EngineState.initial(puzzle);
      final snapshots = <Map<String, Object?>>[state.toJson()];
      for (var tick = 1; tick <= 4; tick++) {
        state = engine.step(state, shift: tick <= 3);
        snapshots.add(state.toJson());
      }
      return snapshots;
    }

    final first = run();
    expect(first, run());
    expect(first.map((row) => (row['switches'] as Map)['s']), [0, 1, 0, 1, 1]);
    expect(first.map((row) => (row['signals'] as Map)['a']), [
      'a',
      's',
      'r',
      's',
      't',
    ]);
  });

  test(
    'no SHIFT preserves initial routing and matches the default parameter',
    () {
      final puzzle = puzzleFor('global_shift');
      final engine = TickEngine(puzzle);
      final initial = EngineState.initial(puzzle);
      expect(
        engine.step(initial).toJson(),
        engine.step(initial, shift: false).toJson(),
      );
      final second = engine.step(engine.step(initial));
      expect(second.switches, {'u': 0, 'v': 0});
      expect(second.signals, {'a': 'y', 'b': 'x'});
    },
  );

  test(
    'SHIFT with no switches changes no movement and does not invent a mechanic',
    () {
      final puzzle = puzzleFor('single_path');
      final engine = TickEngine(puzzle);
      final initial = EngineState.initial(puzzle);
      final shifted = engine.step(initial, shift: true);
      final normal = engine.step(initial);
      expect(shifted.toJson(), normal.toJson());
      expect(shifted.switches, isEmpty);
    },
  );

  test(
    'terminal state short-circuit ignores SHIFT without changing its identity',
    () {
      final puzzle = puzzleFor('shift_before_move');
      final engine = TickEngine(puzzle);
      final first = engine.step(EngineState.initial(puzzle));
      final movement = engine.step(first, shift: true);
      final terminal = movement.copyWith(
        status: RunStatus.succeeded,
        reason: TerminalReason.success,
      );
      expect(identical(engine.step(terminal, shift: true), terminal), isTrue);
      expect(terminal.switches, {'s': 1});
    },
  );
}
