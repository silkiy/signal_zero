import 'puzzle_spec.dart';

enum RunStatus {
  running('RUNNING'),
  succeeded('SUCCEEDED'),
  failed('FAILED');

  const RunStatus(this.wireName);
  final String wireName;
}

enum TerminalReason {
  none(''),
  noRoute('NO_ROUTE'),
  edgeCollision('EDGE_COLLISION'),
  nodeCollision('NODE_COLLISION'),
  syncMiss('SYNC_MISS'),
  success('SUCCESS'),
  tickLimit('TICK_LIMIT');

  const TerminalReason(this.wireName);
  final String wireName;
}

/// An immutable tick snapshot, separate from rendering and wall-clock time.
///
/// This public typed constructor is an internal domain boundary: the engine or
/// a solver may restore an already-validated state from its compact arena.
/// It is not an external JSON/backup decoder. The caller must preserve puzzle,
/// signal, switch, status and reason semantics; TickEngine checks its binding.
final class EngineState {
  EngineState({
    required this.puzzleHash,
    required this.tick,
    required Map<String, String> signals,
    required Map<String, int> switches,
    Map<String, String> usedEdges = const {},
    Map<String, List<String>> targetArrivals = const {},
    this.status = RunStatus.running,
    this.reason = TerminalReason.none,
    Iterable<String> diagnosticIds = const [],
  }) : signals = _sortedMap(signals),
       switches = _sortedMap(switches),
       usedEdges = _sortedMap(usedEdges),
       targetArrivals = _sortedMap({
         for (final entry in targetArrivals.entries)
           entry.key: List<String>.unmodifiable(entry.value.toList()..sort()),
       }),
       diagnosticIds = List<String>.unmodifiable(
         diagnosticIds.toSet().toList()..sort(),
       );

  factory EngineState.initial(PuzzleSpec puzzle) => EngineState(
    puzzleHash: puzzle.puzzleHash,
    tick: 0,
    signals: {
      for (final node in puzzle.nodes)
        if (node.kind == NodeKind.source) node.id: node.id,
    },
    switches: {
      for (final node in puzzle.nodes)
        if (node.kind == NodeKind.switchNode) node.id: node.initialState!,
    },
  );

  final String puzzleHash;
  final int tick;
  final Map<String, String> signals;
  final Map<String, int> switches;
  final Map<String, String> usedEdges;
  final Map<String, List<String>> targetArrivals;
  final RunStatus status;
  final TerminalReason reason;
  final List<String> diagnosticIds;

  bool get isTerminal => status != RunStatus.running;

  EngineState copyWith({
    int? tick,
    Map<String, String>? signals,
    Map<String, int>? switches,
    Map<String, String>? usedEdges,
    Map<String, List<String>>? targetArrivals,
    RunStatus? status,
    TerminalReason? reason,
    Iterable<String>? diagnosticIds,
  }) => EngineState(
    puzzleHash: puzzleHash,
    tick: tick ?? this.tick,
    signals: signals ?? this.signals,
    switches: switches ?? this.switches,
    usedEdges: usedEdges ?? this.usedEdges,
    targetArrivals: targetArrivals ?? this.targetArrivals,
    status: status ?? this.status,
    reason: reason ?? this.reason,
    diagnosticIds: diagnosticIds ?? this.diagnosticIds,
  );

  /// The seven oracle fields only. Puzzle binding and UI diagnostic IDs are
  /// separate properties so they do not alter the reviewed fixture wire shape.
  Map<String, Object?> toJson() => Map<String, Object?>.unmodifiable({
    'tick': tick,
    'signals': signals,
    'switches': switches,
    'used_edges': usedEdges,
    'target_arrivals': targetArrivals,
    'status': status.wireName,
    'reason': reason.wireName,
  });
}

Map<String, T> _sortedMap<T extends Object>(Map<String, T> input) {
  final keys = input.keys.toList()..sort();
  return Map<String, T>.unmodifiable({
    for (final key in keys) key: input[key]!,
  });
}
