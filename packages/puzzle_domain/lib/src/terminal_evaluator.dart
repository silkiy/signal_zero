import 'domain_error.dart';
import 'engine_state.dart';
import 'puzzle_spec.dart';

/// Applies sz-rules-1 failure priority to one completed simultaneous movement.
final class TerminalEvaluator {
  TerminalEvaluator(this.puzzle)
    : _edges = {for (final e in puzzle.edges) e.id: e},
      _targets = {
        for (final n in puzzle.nodes)
          if (n.kind == NodeKind.target) n.id,
      };

  final PuzzleSpec puzzle;
  final Map<String, PuzzleEdge> _edges;
  final Set<String> _targets;

  EngineState evaluate(EngineState candidate) {
    if (candidate.puzzleHash != puzzle.puzzleHash) {
      throw const DomainException(
        'PUZZLE_MISMATCH',
        r'$.state',
        'State belongs to another puzzle.',
      );
    }
    if (candidate.isTerminal) return candidate;
    if (candidate.tick < 1 || candidate.tick > puzzle.tickLimit) {
      throw const DomainException(
        'INVALID_TICK',
        r'$.state.tick',
        'Evaluate only an executed puzzle tick.',
      );
    }
    EngineState finish(
      RunStatus status,
      TerminalReason reason,
      Iterable<String> ids,
    ) {
      final diagnosticIds = ids.toSet().toList()..sort();
      return candidate.copyWith(
        status: status,
        reason: reason,
        diagnosticIds: diagnosticIds,
      );
    }

    final noRoute = candidate.signals.keys
        .where((token) => !candidate.usedEdges.containsKey(token))
        .toList();
    if (noRoute.isNotEmpty) {
      return finish(RunStatus.failed, TerminalReason.noRoute, noRoute);
    }
    final moves = candidate.usedEdges.entries.toList()
      ..sort((a, b) => a.key.compareTo(b.key));
    final collidingEdges = <String>{};
    for (var i = 0; i < moves.length; i++) {
      final a = _edges[moves[i].value];
      if (a == null) {
        throw const DomainException(
          'INVALID_STATE',
          r'$.state.used_edges',
          'Unknown traversed edge.',
        );
      }
      for (var j = i + 1; j < moves.length; j++) {
        final b = _edges[moves[j].value];
        if (b == null) {
          throw const DomainException(
            'INVALID_STATE',
            r'$.state.used_edges',
            'Unknown traversed edge.',
          );
        }
        if (a.id == b.id || (a.fromId == b.toId && a.toId == b.fromId)) {
          collidingEdges.addAll([a.id, b.id]);
        }
      }
    }
    if (collidingEdges.isNotEmpty) {
      return finish(
        RunStatus.failed,
        TerminalReason.edgeCollision,
        collidingEdges,
      );
    }
    final occupancy = <String, int>{};
    for (final node in candidate.signals.values) {
      occupancy.update(node, (n) => n + 1, ifAbsent: () => 1);
    }
    final collisions = occupancy.keys.where((n) => occupancy[n]! > 1).toList();
    if (collisions.isNotEmpty) {
      return finish(RunStatus.failed, TerminalReason.nodeCollision, collisions);
    }
    final arrived = candidate.signals.values.where(_targets.contains).toSet();
    if (arrived.isNotEmpty) {
      if (arrived.length != _targets.length) {
        return finish(
          RunStatus.failed,
          TerminalReason.syncMiss,
          _targets.difference(arrived),
        );
      }
      return finish(RunStatus.succeeded, TerminalReason.success, const []);
    }
    if (candidate.tick == puzzle.tickLimit) {
      return finish(RunStatus.failed, TerminalReason.tickLimit, const []);
    }
    return candidate;
  }
}
