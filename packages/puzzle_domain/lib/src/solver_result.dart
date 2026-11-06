import 'replay_spec.dart';
import 'score.dart';

enum SolverStatus { solvedOptimal, unsatisfiable, budgetExhausted, cancelled }

/// Only a completed search can establish optimality or unsatisfiability.
final class SolverResult {
  const SolverResult({
    required this.status,
    required this.puzzleHash,
    required this.engineVersion,
    required this.rulesVersion,
    required this.statesRetained,
    required this.transitionsEvaluated,
    required this.accountedBytes,
    required this.elapsedMicros,
    this.reason,
    this.replay,
    this.score,
  });

  final SolverStatus status;
  final String? reason;
  final ReplaySpec? replay;
  final Score? score;
  final String puzzleHash;
  final String engineVersion;
  final String rulesVersion;
  final int statesRetained;
  final int transitionsEvaluated;

  /// Peak accounted working memory, not process RSS or a VM heap limit.
  final int accountedBytes;
  final int elapsedMicros;
  String get proofObjective => 'lexicographicScore';
  bool get isOptimal => status == SolverStatus.solvedOptimal;
}
