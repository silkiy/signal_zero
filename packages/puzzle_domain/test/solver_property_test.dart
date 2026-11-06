import 'package:puzzle_domain/puzzle_domain.dart';
import 'package:test/test.dart';

import 'seeded_puzzles.dart';

void main() {
  for (final example in seededPuzzles()) {
    test(
      'seed ${example.seed} ${example.family}: exact optimum vs complete 2^T enumeration',
      () {
        final puzzle = example.puzzle;
        final expected = exhaustiveScore(puzzle);
        final result = PuzzleSolver(
          puzzle,
        ).solve(budget: SolverWorkBudget.offline());
        final context = example.context(result.replay?.shiftTicks ?? const []);
        expect(
          result.status,
          expected == null
              ? SolverStatus.unsatisfiable
              : SolverStatus.solvedOptimal,
          reason: context,
        );
        expect(result.isOptimal, expected != null, reason: context);
        if (expected == null) {
          expect(result.replay, isNull, reason: context);
          expect(result.score, isNull, reason: context);
        } else {
          final independentlyReplayed = SimulationRunner(
            puzzle,
          ).run(result.replay!);
          expect(independentlyReplayed.isSuccess, isTrue, reason: context);
          expect(result.score!.toTuple(), expected, reason: context);
          final count = result.replay!.shiftTicks
              .where((tick) => tick <= independentlyReplayed.finalState.tick)
              .length;
          expect(
            [count, independentlyReplayed.finalState.tick, count],
            expected,
            reason: context,
          );
        }
      },
    );
  }

  test(
    'seeded solver API is cooperatively deterministic in async mode',
    () async {
      for (final example in seededPuzzles().where(
        (c) => c.family == 'switch-loop',
      )) {
        final sync = PuzzleSolver(
          example.puzzle,
        ).solve(budget: SolverWorkBudget.offline());
        final asynchronous = await PuzzleSolver(
          example.puzzle,
        ).solveAsync(budget: SolverWorkBudget.offline());
        final context = example.context();
        expect(asynchronous.status, sync.status, reason: context);
        expect(
          asynchronous.score?.toTuple(),
          sync.score?.toTuple(),
          reason: context,
        );
        expect(
          asynchronous.replay?.canonicalBytes,
          sync.replay?.canonicalBytes,
          reason: context,
        );
        if (asynchronous.replay != null) {
          expect(
            SimulationRunner(
              example.puzzle,
            ).run(asynchronous.replay!).isSuccess,
            isTrue,
            reason: context,
          );
        }
      }
    },
  );
}
