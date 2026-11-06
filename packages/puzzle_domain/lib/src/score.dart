import 'domain_error.dart';
import 'simulation_runner.dart';

/// Generic interface tuple; only [fromSuccessfulRun] verifies gameplay scores.
final class Score implements Comparable<Score> {
  Score(this.shiftCount, this.completionTicks, this.programmingActions) {
    if (shiftCount < 0 ||
        shiftCount > 64 ||
        completionTicks < 1 ||
        completionTicks > 64 ||
        programmingActions < 0 ||
        programmingActions > 64) {
      throw ArgumentError('Score components must respect sz-limits-1.');
    }
  }

  factory Score.fromSuccessfulRun(SimulationResult run) {
    final replay = run.normalizedReplay;
    if (!run.isSuccess || replay == null) {
      throw const DomainException(
        'RUN_NOT_SUCCESSFUL',
        r'$.score',
        'Only a verified successful run has a score.',
      );
    }
    final actions = replay.shiftTicks.length;
    return Score(actions, run.finalState.tick, actions);
  }

  final int shiftCount;
  final int completionTicks;
  final int programmingActions;

  List<int> toTuple() =>
      List<int>.unmodifiable([shiftCount, completionTicks, programmingActions]);
  Map<String, int> toJson() => Map<String, int>.unmodifiable({
    'shift_count': shiftCount,
    'completion_ticks': completionTicks,
    'programming_actions': programmingActions,
  });

  @override
  int compareTo(Score other) {
    final shifts = shiftCount.compareTo(other.shiftCount);
    if (shifts != 0) return shifts;
    final ticks = completionTicks.compareTo(other.completionTicks);
    if (ticks != 0) return ticks;
    return programmingActions.compareTo(other.programmingActions);
  }

  @override
  bool operator ==(Object other) => other is Score && compareTo(other) == 0;
  @override
  int get hashCode =>
      Object.hash(shiftCount, completionTicks, programmingActions);
}
