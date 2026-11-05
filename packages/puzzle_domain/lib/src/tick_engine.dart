import 'domain_error.dart';
import 'engine_state.dart';
import 'puzzle_spec.dart';

/// Integer-tick simultaneous movement with one global SHIFT per active tick.
/// Terminal evaluation is added by T014; this intermediate slice is not a
/// complete gameplay engine until that dependent task is implemented.
final class TickEngine {
  TickEngine(this.puzzle)
    : _sourceIds = Set<String>.unmodifiable(
        puzzle.nodes
            .where((node) => node.kind == NodeKind.source)
            .map((node) => node.id),
      ),
      _switchIds = Set<String>.unmodifiable(
        puzzle.nodes
            .where((node) => node.kind == NodeKind.switchNode)
            .map((node) => node.id),
      );

  final PuzzleSpec puzzle;
  final Set<String> _sourceIds;
  final Set<String> _switchIds;

  EngineState step(EngineState state, {bool shift = false}) {
    if (state.puzzleHash != puzzle.puzzleHash) {
      throw const DomainException(
        'PUZZLE_MISMATCH',
        r'$.puzzle_hash',
        'State belongs to a different puzzle.',
      );
    }
    if (state.isTerminal) return state;
    if (state.tick < 0 || state.tick >= puzzle.tickLimit) {
      throw const DomainException(
        'INVALID_TICK',
        r'$.tick',
        'Cannot advance outside the puzzle tick budget.',
      );
    }
    _validateState(state);
    // Flip every switch before planning any route, including empty switches.
    // Program normalization/scoring owns action cost, even with no switches.
    final switches = shift
        ? {
            for (final entry in state.switches.entries)
              entry.key: 1 - entry.value,
          }
        : state.switches;
    final positions = <String, String>{};
    final usedEdges = <String, String>{};
    final arrivals = <String, List<String>>{};
    // Every route reads the same immutable prior state. Routing never observes
    // another token's new location, and no source emits a second token here.
    for (final entry in state.signals.entries) {
      final node = puzzle.nodeById[entry.value]!;
      final port = node.kind == NodeKind.switchNode ? switches[node.id]! : 0;
      PuzzleEdge? route;
      for (final edge in puzzle.outgoingByNode[node.id]!) {
        if (edge.port == port) {
          route = edge;
          break;
        }
      }
      if (route == null) {
        positions[entry.key] = entry.value;
        continue;
      }
      positions[entry.key] = route.toId;
      usedEdges[entry.key] = route.id;
      if (puzzle.nodeById[route.toId]!.kind == NodeKind.target) {
        arrivals.putIfAbsent(route.toId, () => []).add(entry.key);
      }
    }
    return EngineState(
      puzzleHash: puzzle.puzzleHash,
      tick: state.tick + 1,
      signals: positions,
      switches: switches,
      usedEdges: usedEdges,
      targetArrivals: arrivals,
    );
  }

  void _validateState(EngineState state) {
    if (state.signals.length != _sourceIds.length ||
        !state.signals.keys.every(_sourceIds.contains) ||
        !state.signals.values.every(puzzle.nodeById.containsKey)) {
      throw const DomainException(
        'INVALID_STATE',
        r'$.signals',
        'Signal identities or positions do not match puzzle.',
      );
    }
    if (state.switches.length != _switchIds.length ||
        !state.switches.keys.every(_switchIds.contains) ||
        state.switches.values.any((bit) => bit != 0 && bit != 1)) {
      throw const DomainException(
        'INVALID_STATE',
        r'$.switches',
        'Switch identities or bits do not match puzzle.',
      );
    }
  }
}
