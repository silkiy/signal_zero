import 'dart:convert';

import 'package:crypto/crypto.dart';

import 'canonical_json.dart';
import 'domain_error.dart';
import 'engine_state.dart';
import 'puzzle_spec.dart';
import 'replay_spec.dart';
import 'tick_engine.dart';

/// A result can only be produced by the actual runner, never by client scores.
final class SimulationResult {
  SimulationResult._(this.puzzle, this.submittedReplay, List<EngineState> trace)
    : snapshots = List<EngineState>.unmodifiable(trace);

  final PuzzleSpec puzzle;
  final ReplaySpec submittedReplay;
  final List<EngineState> snapshots;
  String get puzzleHash => puzzle.puzzleHash;
  EngineState get finalState => snapshots.last;
  bool get isSuccess => finalState.status == RunStatus.succeeded;
  ReplaySpec? get normalizedReplay => isSuccess
      ? submittedReplay.trimAfterVerifiedSuccess(finalState.tick)
      : null;

  /// Debug identity binds puzzle/versions and a canonical immutable state.
  late final List<String> snapshotHashes = List<String>.unmodifiable([
    for (final snapshot in snapshots)
      '0x${sha256.convert([...ascii.encode('SIGNAL_ZERO_SNAPSHOT_V1\u0000$puzzleHash\u0000${puzzle.engineVersion}\u0000${puzzle.rulesVersion}\u0000'), ...CanonicalJson.encode(snapshot.toJson())])}',
  ]);
}

/// Deterministic bounded playback; no frame time, renderer, IO or random input.
final class SimulationRunner {
  SimulationRunner(this.puzzle, {this.maxSnapshots = 65})
    : _engine = TickEngine(puzzle) {
    if (maxSnapshots < 1 || maxSnapshots > 65) {
      throw ArgumentError.value(maxSnapshots, 'maxSnapshots', 'Must be 1..65.');
    }
  }

  final PuzzleSpec puzzle;
  final int maxSnapshots;
  final TickEngine _engine;

  /// Host hook accounts shared work/deadlines before EACH actual transition.
  /// Throwing from the hook aborts work, never returns a successful score.
  SimulationResult run(ReplaySpec replay, {void Function()? beforeStep}) {
    if (replay.puzzleHash != puzzle.puzzleHash ||
        replay.engineVersion != puzzle.engineVersion ||
        replay.rulesVersion != puzzle.rulesVersion) {
      throw const DomainException(
        'PUZZLE_MISMATCH',
        r'$.replay',
        'Replay identity does not match this runner.',
      );
    }
    final snapshots = _execute(replay, beforeStep);
    final result = SimulationResult._(puzzle, replay, snapshots);
    final normalized = result.normalizedReplay;
    if (normalized != null &&
        normalized.shiftTicks.length != replay.shiftTicks.length) {
      // T002 requires revalidation of the trimmed final program. Count this
      // work through the same host hook rather than silently resetting a budget.
      final checked = _execute(normalized, beforeStep);
      if (checked.length != snapshots.length) {
        throw StateError('Normalized replay changed the terminal tick.');
      }
      for (var i = 0; i < checked.length; i++) {
        if (jsonEncode(checked[i].toJson()) !=
            jsonEncode(snapshots[i].toJson())) {
          throw StateError('Normalized replay changed a snapshot.');
        }
      }
    }
    return result;
  }

  List<EngineState> _execute(ReplaySpec replay, void Function()? beforeStep) {
    var state = EngineState.initial(puzzle);
    final trace = <EngineState>[state];
    final shifts = replay.shiftTicks.toSet();
    while (!state.isTerminal) {
      if (trace.length >= maxSnapshots) {
        throw const DomainException(
          'SNAPSHOT_LIMIT',
          r'$.snapshots',
          'Snapshot budget exhausted.',
        );
      }
      beforeStep?.call();
      state = _engine.step(state, shift: shifts.contains(state.tick + 1));
      trace.add(state);
    }
    return trace;
  }
}
