import 'dart:convert';
import 'dart:math';

import 'package:puzzle_domain/puzzle_domain.dart';

// Test-only graph families, not the production puzzle generator (FR-010).
const propertySeeds = <int>[
  0x530001,
  0x530002,
  0x530003,
  0x530005,
  0x530008,
  0x53000d,
  0x530015,
  0x530022,
];

final class SeededPuzzle {
  const SeededPuzzle(this.seed, this.family, this.puzzle);
  final int seed;
  final String family;
  final PuzzleSpec puzzle;
  String context([Iterable<int> program = const []]) => jsonEncode({
    'seed': seed,
    'family': family,
    'puzzle': puzzle.toJson(),
    'program': program.toList()..sort(),
  });
}

Map<String, Object> _node(String id, String kind, [int? bit]) => {
  'id': id,
  'kind': kind,
  if (bit != null) 'initial_state': bit,
};
Map<String, Object> _edge(String from, String to, [int port = 0]) => {
  'id': '${from}_${to}_$port',
  'from': from,
  'to': to,
  'port': port,
};
PuzzleSpec _puzzle(
  int limit,
  List<Map<String, Object>> nodes,
  List<Map<String, Object>> edges,
) => PuzzleSpec.fromJson({
  'schema_version': 'sz-puzzle-1',
  'engine_version': engineVersion,
  'rules_version': rulesVersion,
  'tick_limit': limit,
  'nodes': nodes,
  'edges': edges,
});

List<SeededPuzzle> seededPuzzles() => [
  for (final seed in propertySeeds) ..._families(seed),
];

List<SeededPuzzle> _families(int seed) {
  final random = Random(seed);
  final length = 1 + random.nextInt(5);
  final chainIds = ['s', for (var i = 1; i < length; i++) 'r$i', 't'];
  final bit = random.nextInt(2);
  final otherBit = random.nextInt(2);
  final leftLength = 1 + random.nextInt(4);
  final rightLength = random.nextBool() ? leftLength : 1 + random.nextInt(4);
  final left = ['a', for (var i = 1; i < leftLength; i++) 'u$i', 'x'];
  final right = ['b', for (var i = 1; i < rightLength; i++) 'v$i', 'y'];
  return [
    SeededPuzzle(
      seed,
      'chain',
      _puzzle(
        length + random.nextInt(3),
        [
          _node('s', 'source'),
          for (final id in chainIds.skip(1).take(length - 1))
            _node(id, 'relay'),
          _node('t', 'target'),
        ],
        [
          for (var i = 0; i < chainIds.length - 1; i++)
            _edge(chainIds[i], chainIds[i + 1]),
        ],
      ),
    ),
    SeededPuzzle(
      seed,
      'alternate-branch',
      _puzzle(
        4 + random.nextInt(3),
        [
          _node('s', 'source'),
          _node('q', 'switch', bit),
          _node('r', 'relay'),
          _node('t', 'target'),
        ],
        [
          _edge('s', 'q'),
          _edge('q', 'r', 0),
          _edge('q', 't', 1),
          _edge('r', 't'),
        ],
      ),
    ),
    SeededPuzzle(
      seed,
      'switch-loop',
      _puzzle(
        4 + random.nextInt(3),
        [
          _node('s', 'source'),
          _node('q', 'switch', bit),
          _node('r', 'relay'),
          _node('t', 'target'),
        ],
        [
          _edge('s', 'q'),
          _edge('q', 'r', 0),
          _edge('q', 't', 1),
          _edge('r', 'q'),
        ],
      ),
    ),
    SeededPuzzle(
      seed,
      'simultaneous-arrival',
      _puzzle(
        6,
        [
          _node('a', 'source'),
          _node('b', 'source'),
          for (final id in left.skip(1).take(leftLength - 1))
            _node(id, 'relay'),
          for (final id in right.skip(1).take(rightLength - 1))
            _node(id, 'relay'),
          _node('x', 'target'),
          _node('y', 'target'),
        ],
        [
          for (var i = 0; i < left.length - 1; i++) _edge(left[i], left[i + 1]),
          for (var i = 0; i < right.length - 1; i++)
            _edge(right[i], right[i + 1]),
        ],
      ),
    ),
    SeededPuzzle(
      seed,
      'two-global-switches',
      _puzzle(
        6,
        [
          _node('a', 'source'),
          _node('b', 'source'),
          _node('q', 'switch', bit),
          _node('r', 'switch', otherBit),
          _node('u', 'relay'),
          _node('v', 'relay'),
          _node('x', 'target'),
          _node('y', 'target'),
        ],
        [
          _edge('a', 'q'),
          _edge('b', 'r'),
          _edge('q', 'u', 0),
          _edge('q', 'x', 1),
          _edge('u', 'q'),
          _edge('r', 'y', 0),
          _edge('r', 'v', 1),
          _edge('v', 'r'),
        ],
      ),
    ),
  ];
}

Set<int> programFromMask(PuzzleSpec puzzle, int mask) => {
  for (var tick = 1; tick <= puzzle.tickLimit; tick++)
    if ((mask & (1 << (tick - 1))) != 0) tick,
};

// Independent objective arithmetic, intentionally does not use Score.compareTo
// or Score.fromSuccessfulRun. Every one of 2^T programs is actually replayed.
List<int>? exhaustiveScore(PuzzleSpec puzzle) {
  if (puzzle.tickLimit > 8) {
    throw ArgumentError('Exhaustive test cap is 8 ticks.');
  }
  List<int>? best;
  final runner = SimulationRunner(puzzle);
  for (var mask = 0; mask < (1 << puzzle.tickLimit); mask++) {
    final program = programFromMask(puzzle, mask);
    final result = runner.run(ReplaySpec.fromProgram(puzzle, program));
    if (!result.isSuccess) continue;
    final completion = result.finalState.tick;
    final count = program.where((tick) => tick <= completion).length;
    final tuple = [count, completion, count];
    if (best == null || tupleCompare(tuple, best) < 0) best = tuple;
  }
  return best;
}

int tupleCompare(List<int> a, List<int> b) {
  for (var i = 0; i < 3; i++) {
    if (a[i] < b[i]) return -1;
    if (a[i] > b[i]) return 1;
  }
  return 0;
}
