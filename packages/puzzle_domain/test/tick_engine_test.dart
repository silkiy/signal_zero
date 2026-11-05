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

Matcher failsWith(String code) =>
    throwsA(isA<DomainException>().having((error) => error.code, 'code', code));

void main() {
  test(
    'tick zero emits each source once and preserves declared switch bits',
    () {
      for (final row in ruleCases()) {
        final puzzle = PuzzleSpec.fromJson(
          row['puzzle'] as Map<String, dynamic>,
        );
        final initial = EngineState.initial(puzzle);
        expect(initial.puzzleHash, puzzle.puzzleHash);
        expect(
          initial.toJson(),
          (row['expected_snapshots'] as List).first,
          reason: row['id'],
        );
        expect(initial.isTerminal, isFalse);
        expect(initial.diagnosticIds, isEmpty);
      }
    },
  );

  test(
    'one step moves at most one edge without reemission or input mutation',
    () {
      final puzzle = puzzleFor('single_path');
      final engine = TickEngine(puzzle);
      final initial = EngineState.initial(puzzle);
      final before = initial.toJson();
      final first = engine.step(initial);
      expect(first.tick, 1);
      expect(first.signals, {'a': 'b'});
      expect(first.usedEdges, {'a': 'ab'});
      expect(first.targetArrivals, isEmpty);
      expect(first.signals.length, initial.signals.length);
      expect(initial.toJson(), before);
      final second = engine.step(first);
      expect(second.tick, 2);
      expect(second.signals, {'a': 't'});
      expect(second.targetArrivals, {
        't': ['a'],
      });
      expect(first.signals, {'a': 'b'});
    },
  );

  test(
    'static movement matches manual trace data without asserting future terminal evaluation',
    () {
      for (final row in ruleCases().where(
        (row) => (row['shift_ticks'] as List).isEmpty,
      )) {
        final puzzle = PuzzleSpec.fromJson(
          row['puzzle'] as Map<String, dynamic>,
        );
        final engine = TickEngine(puzzle);
        var state = EngineState.initial(puzzle);
        for (final expected in (row['expected_snapshots'] as List).skip(1)) {
          state = engine.step(state);
          final actual = state.toJson();
          for (final field in [
            'tick',
            'signals',
            'switches',
            'used_edges',
            'target_arrivals',
          ]) {
            expect(
              actual[field],
              expected[field],
              reason: '${row['id']} tick ${expected['tick']} $field',
            );
          }
        }
      }
    },
  );

  test('all tokens move simultaneously from the shared prior snapshot', () {
    final puzzle = puzzleFor('head_on_edge_collision');
    final engine = TickEngine(puzzle);
    final first = engine.step(EngineState.initial(puzzle));
    final second = engine.step(first);
    expect(first.signals, {'a': 'u', 'b': 'v'});
    expect(second.signals, {'a': 'v', 'b': 'u'});
    expect(second.usedEdges, {'a': 'uv', 'b': 'vu'});
  });

  test(
    'switch routing uses port labels rather than sorted edge-list positions',
    () {
      final json = puzzleFor('shift_before_move').toJson();
      final editable = jsonDecode(jsonEncode(json)) as Map<String, dynamic>;
      for (final node in editable['nodes'] as List) {
        if (node['id'] == 's') node['initial_state'] = 1;
      }
      for (final edge in editable['edges'] as List) {
        if (edge['id'] == 'st') edge['id'] = 'aa';
        if (edge['id'] == 'sr') edge['id'] = 'zz';
      }
      final puzzle = PuzzleSpec.fromJson(editable);
      expect(puzzle.outgoingByNode['s']!.first.port, 1);
      final engine = TickEngine(puzzle);
      final second = engine.step(engine.step(EngineState.initial(puzzle)));
      expect(second.signals, {'a': 't'});
      expect(second.usedEdges, {'a': 'aa'});
      expect(second.switches, {'s': 1});
    },
  );

  test('collection permutations produce the same movement snapshot', () {
    final puzzle = puzzleFor('global_shift');
    final engine = TickEngine(puzzle);
    final normal = EngineState.initial(puzzle);
    final reordered = EngineState(
      puzzleHash: puzzle.puzzleHash,
      tick: 0,
      signals: {'b': 'b', 'a': 'a'},
      switches: {'v': 0, 'u': 0},
    );
    expect(engine.step(normal).toJson(), engine.step(reordered).toJson());
    final next = engine.step(engine.step(reordered));
    expect(next.signals, {'a': 'y', 'b': 'x'});
  });

  test('no-route token stays while routed tokens still move in that tick', () {
    final puzzle = PuzzleSpec.fromJson({
      'schema_version': 'sz-puzzle-1',
      'engine_version': engineVersion,
      'rules_version': rulesVersion,
      'tick_limit': 3,
      'nodes': [
        {'id': 'a', 'kind': 'source'},
        {'id': 'b', 'kind': 'source'},
        {'id': 'd', 'kind': 'relay'},
        {'id': 'q', 'kind': 'relay'},
        {'id': 'x', 'kind': 'target'},
        {'id': 'y', 'kind': 'target'},
      ],
      'edges': [
        {'id': 'ad', 'from': 'a', 'to': 'd', 'port': 0},
        {'id': 'bq', 'from': 'b', 'to': 'q', 'port': 0},
        {'id': 'qy', 'from': 'q', 'to': 'y', 'port': 0},
      ],
    });
    final engine = TickEngine(puzzle);
    final second = engine.step(engine.step(EngineState.initial(puzzle)));
    expect(second.signals, {'a': 'd', 'b': 'y'});
    expect(second.usedEdges, {'b': 'qy'});
    expect(second.targetArrivals, {
      'y': ['b'],
    });
  });

  test('target arrival snapshot preserves every colliding source token', () {
    final puzzle = puzzleFor('target_node_collision');
    final snapshot = TickEngine(puzzle).step(EngineState.initial(puzzle));
    expect(snapshot.signals, {'a': 'x', 'b': 'x'});
    expect(snapshot.targetArrivals, {
      'x': ['a', 'b'],
    });
    expect(() => snapshot.signals.clear(), throwsUnsupportedError);
    expect(() => snapshot.switches.clear(), throwsUnsupportedError);
    expect(() => snapshot.usedEdges.clear(), throwsUnsupportedError);
    expect(() => snapshot.targetArrivals.clear(), throwsUnsupportedError);
    expect(() => snapshot.targetArrivals['x']!.clear(), throwsUnsupportedError);
    expect(() => snapshot.toJson().clear(), throwsUnsupportedError);
  });

  test(
    'typed restore/copy defensively freezes maps, arrivals and diagnostics',
    () {
      final puzzle = puzzleFor('single_path');
      final signals = {'a': 'a'};
      final arrivals = {
        't': ['a'],
      };
      final ids = ['t', 'a', 't'];
      final restored = EngineState(
        puzzleHash: puzzle.puzzleHash,
        tick: 0,
        signals: signals,
        switches: {},
        targetArrivals: arrivals,
        diagnosticIds: ids,
      );
      signals['a'] = 't';
      arrivals['t']!.clear();
      ids.clear();
      expect(restored.signals, {'a': 'a'});
      expect(restored.targetArrivals, {
        't': ['a'],
      });
      expect(restored.diagnosticIds, ['a', 't']);
      final copy = restored.copyWith(tick: 1, usedEdges: {'a': 'ab'});
      expect(copy.tick, 1);
      expect(copy.usedEdges, {'a': 'ab'});
      expect(restored.tick, 0);
      expect(restored.usedEdges, isEmpty);
      expect(
        copy.toJson().keys,
        unorderedEquals([
          'tick',
          'signals',
          'switches',
          'used_edges',
          'target_arrivals',
          'status',
          'reason',
        ]),
      );
    },
  );

  test('terminal state is returned by identity and never stepped again', () {
    final puzzle = puzzleFor('single_path');
    final engine = TickEngine(puzzle);
    final movement = engine.step(engine.step(EngineState.initial(puzzle)));
    final terminal = movement.copyWith(
      status: RunStatus.succeeded,
      reason: TerminalReason.success,
    );
    expect(terminal.isTerminal, isTrue);
    expect(identical(engine.step(terminal), terminal), isTrue);
    expect(terminal.toJson()['status'], 'SUCCEEDED');
    expect(terminal.toJson()['reason'], 'SUCCESS');
  });

  test('puzzle mismatch is rejected even for terminal states', () {
    final puzzle = puzzleFor('single_path');
    final other = puzzleFor('tick_limit');
    final terminal = EngineState.initial(
      puzzle,
    ).copyWith(status: RunStatus.failed, reason: TerminalReason.tickLimit);
    expect(
      () => TickEngine(other).step(terminal),
      failsWith('PUZZLE_MISMATCH'),
    );
  });

  test('running state cannot execute tick limit plus one', () {
    final puzzle = puzzleFor('single_path');
    final atLimit = EngineState.initial(
      puzzle,
    ).copyWith(tick: puzzle.tickLimit);
    expect(() => TickEngine(puzzle).step(atLimit), failsWith('INVALID_TICK'));
  });

  test(
    'invalid trusted restore identities do not become new emitted tokens',
    () {
      final puzzle = puzzleFor('single_path');
      final initial = EngineState.initial(puzzle);
      final engine = TickEngine(puzzle);
      expect(
        () => engine.step(initial.copyWith(signals: {'unknown': 'a'})),
        failsWith('INVALID_STATE'),
      );
      expect(
        () => engine.step(initial.copyWith(signals: {'a': 'unknown'})),
        failsWith('INVALID_STATE'),
      );
      expect(
        () => engine.step(initial.copyWith(switches: {'unknown': 0})),
        failsWith('INVALID_STATE'),
      );
    },
  );
}
