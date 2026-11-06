import 'dart:async';

import 'package:puzzle_domain/puzzle_domain.dart';
import 'package:test/test.dart';

PuzzleSpec fixture({
  required List<Map<String, Object>> nodes,
  required List<Map<String, Object>> edges,
  int limit = 4,
}) => PuzzleSpec.fromJson({
  'schema_version': 'sz-puzzle-1',
  'engine_version': engineVersion,
  'rules_version': rulesVersion,
  'tick_limit': limit,
  'nodes': nodes,
  'edges': edges,
});

PuzzleSpec direct({int limit = 1}) => fixture(
  limit: limit,
  nodes: [
    {'id': 'a', 'kind': 'source'},
    {'id': 't', 'kind': 'target'},
  ],
  edges: [
    {'id': 'at', 'from': 'a', 'to': 't', 'port': 0},
  ],
);

PuzzleSpec costPriority({int limit = 4}) => fixture(
  limit: limit,
  nodes: [
    {'id': 'a', 'kind': 'source'},
    {'id': 'w', 'kind': 'switch', 'initial_state': 0},
    {'id': 'p', 'kind': 'relay'},
    {'id': 'q', 'kind': 'relay'},
    {'id': 't', 'kind': 'target'},
  ],
  edges: [
    {'id': 'aw', 'from': 'a', 'to': 'w', 'port': 0},
    {'id': 'wp', 'from': 'w', 'to': 'p', 'port': 0},
    {'id': 'wt', 'from': 'w', 'to': 't', 'port': 1},
    {'id': 'pq', 'from': 'p', 'to': 'q', 'port': 0},
    {'id': 'qt', 'from': 'q', 'to': 't', 'port': 0},
  ],
);

PuzzleSpec cycleSync() => fixture(
  nodes: [
    {'id': 'a', 'kind': 'source'},
    {'id': 'b', 'kind': 'source'},
    {'id': 'w', 'kind': 'switch', 'initial_state': 0},
    {'id': 'r', 'kind': 'relay'},
    {'id': 'p', 'kind': 'relay'},
    {'id': 'q', 'kind': 'relay'},
    {'id': 'z', 'kind': 'relay'},
    {'id': 'x', 'kind': 'target'},
    {'id': 'y', 'kind': 'target'},
  ],
  edges: [
    {'id': 'aw', 'from': 'a', 'to': 'w', 'port': 0},
    {'id': 'bp', 'from': 'b', 'to': 'p', 'port': 0},
    {'id': 'wr', 'from': 'w', 'to': 'r', 'port': 0},
    {'id': 'wx', 'from': 'w', 'to': 'x', 'port': 1},
    {'id': 'rw', 'from': 'r', 'to': 'w', 'port': 0},
    {'id': 'pq', 'from': 'p', 'to': 'q', 'port': 0},
    {'id': 'qz', 'from': 'q', 'to': 'z', 'port': 0},
    {'id': 'zy', 'from': 'z', 'to': 'y', 'port': 0},
  ],
);

PuzzleSpec loop({int limit = 64}) => fixture(
  limit: limit,
  nodes: [
    {'id': 'a', 'kind': 'source'},
    {'id': 'r', 'kind': 'relay'},
    {'id': 't', 'kind': 'target'},
  ],
  edges: [
    {'id': 'ar', 'from': 'a', 'to': 'r', 'port': 0},
    {'id': 'rr', 'from': 'r', 'to': 'r', 'port': 0},
  ],
);

Score? bruteForce(PuzzleSpec puzzle) {
  Score? best;
  // Independent complete program enumeration, no solver frontier/dominance.
  for (var mask = 0; mask < 1 << puzzle.tickLimit; mask++) {
    final replay = ReplaySpec.fromProgram(puzzle, {
      for (var tick = 1; tick <= puzzle.tickLimit; tick++)
        if ((mask & (1 << (tick - 1))) != 0) tick,
    });
    final run = SimulationRunner(puzzle).run(replay);
    if (!run.isSuccess) continue;
    final score = Score.fromSuccessfulRun(run);
    if (best == null || score.compareTo(best) < 0) best = score;
  }
  return best;
}

SolverWorkBudget unlimitedClock({int maxTransitions = 50000}) =>
    SolverWorkBudget.offline(
      maxTransitions: maxTransitions,
      clockMicros: () => 0,
    );

void expectGenuineSolution(PuzzleSpec puzzle, SolverResult result) {
  expect(result.replay, isNotNull);
  final run = SimulationRunner(puzzle).run(result.replay!);
  expect(run.isSuccess, isTrue);
  expect(Score.fromSuccessfulRun(run).toTuple(), result.score!.toTuple());
  expect(result.replay!.puzzleHash, puzzle.puzzleHash);
}

void main() {
  test('eight-source arena stores every distinct signal position', () {
    final puzzle = fixture(
      limit: 1,
      nodes: [
        for (var i = 0; i < 8; i++) {'id': 'a$i', 'kind': 'source'},
        for (var i = 0; i < 8; i++) {'id': 't$i', 'kind': 'target'},
      ],
      edges: [
        for (var i = 0; i < 8; i++)
          {'id': 'e$i', 'from': 'a$i', 'to': 't$i', 'port': 0},
      ],
    );
    final result = PuzzleSolver(puzzle).solve(budget: unlimitedClock());
    expect(result.status, SolverStatus.solvedOptimal);
    expect(result.transitionsEvaluated, 2);
    expect(result.accountedBytes, 2097152 + 25000 * 25 + 65536 * 4);
    expectGenuineSolution(puzzle, result);
  });

  test('hard caps reject negative and oversized resource options', () {
    for (final build in <SolverWorkBudget Function()>[
      () => SolverWorkBudget(maxStates: -1),
      () => SolverWorkBudget(maxStates: 25001),
      () => SolverWorkBudget(maxTransitions: -1),
      () => SolverWorkBudget(maxTransitions: 50001),
      () => SolverWorkBudget(maxBytes: -1),
      () => SolverWorkBudget(maxBytes: 33554433),
      () => SolverWorkBudget(timeLimit: const Duration(microseconds: -1)),
      () => SolverWorkBudget(timeLimit: const Duration(milliseconds: 5001)),
    ]) {
      expect(build, throwsArgumentError);
    }
  });

  test(
    'initial async yield permits cancellation before search allocation',
    () async {
      var cancelled = false;
      final work = SolverWorkBudget(isCancelled: () => cancelled);
      Timer.run(() => cancelled = true);
      final result = await PuzzleSolver(direct()).solveAsync(budget: work);
      expect(result.status, SolverStatus.cancelled);
      expect(result.transitionsEvaluated, 0);
      expect(result.accountedBytes, 0);
      expect(work.activeAccountedBytes, 0);
    },
  );

  test('direct solution is proven and verification steps share the budget', () {
    final puzzle = direct();
    final result = PuzzleSolver(puzzle).solve(budget: unlimitedClock());
    expect(result.status, SolverStatus.solvedOptimal);
    expect(result.isOptimal, isTrue);
    expect(result.proofObjective, 'lexicographicScore');
    expect(result.score!.toTuple(), [0, 1, 0]);
    expect(
      result.transitionsEvaluated,
      2,
    ); // Search + real replay verification.
    expectGenuineSolution(puzzle, result);
  });

  test('SHIFT first beats a much faster solution using another SHIFT', () {
    final puzzle = costPriority();
    final result = PuzzleSolver(puzzle).solve(budget: unlimitedClock());
    expect(result.score!.toTuple(), [0, 4, 0]);
    expect(result.replay!.shiftTicks, isEmpty);
    final fast = SimulationRunner(
      puzzle,
    ).run(ReplaySpec.fromProgram(puzzle, {2}));
    expect(Score.fromSuccessfulRun(fast).toTuple(), [1, 2, 1]);
    expectGenuineSolution(puzzle, result);
  });

  test('tick and parity remain in transpositions for a synchronized loop', () {
    final puzzle = cycleSync();
    final result = PuzzleSolver(puzzle).solve(budget: unlimitedClock());
    expect(result.status, SolverStatus.solvedOptimal);
    expect(result.score!.toTuple(), [1, 4, 1]);
    expectGenuineSolution(puzzle, result);
  });

  test('small complete searches agree with every 2^T program enumeration', () {
    for (var ticks = 1; ticks <= 6; ticks++) {
      for (final puzzle in [
        direct(limit: ticks),
        costPriority(limit: ticks),
        loop(limit: ticks),
        if (ticks == 4) cycleSync(),
      ]) {
        final oracle = bruteForce(puzzle);
        final result = PuzzleSolver(puzzle).solve(budget: unlimitedClock());
        if (oracle == null) {
          expect(result.status, SolverStatus.unsatisfiable);
          expect(result.replay, isNull);
          expect(result.score, isNull);
        } else {
          expect(result.status, SolverStatus.solvedOptimal);
          expect(result.score!.toTuple(), oracle.toTuple());
          expectGenuineSolution(puzzle, result);
        }
      }
    }
  });

  test(
    'zero work budgets never claim UNSAT for an actually solvable puzzle',
    () {
      final puzzle = direct();
      for (final budget in [
        SolverWorkBudget(maxStates: 0),
        SolverWorkBudget(maxTransitions: 0),
        SolverWorkBudget(maxBytes: 0),
        SolverWorkBudget(timeLimit: Duration.zero),
      ]) {
        final result = PuzzleSolver(puzzle).solve(budget: budget);
        expect(result.status, SolverStatus.budgetExhausted);
        expect(result.isOptimal, isFalse);
        expect(result.replay, isNull);
        expect(result.transitionsEvaluated, 0);
      }
    },
  );

  test(
    'transition boundary includes candidate verification and stops first',
    () {
      for (final maximum in [1, 2, 3]) {
        final result = PuzzleSolver(
          direct(),
        ).solve(budget: unlimitedClock(maxTransitions: maximum));
        expect(result.transitionsEvaluated, lessThanOrEqualTo(maximum));
        expect(
          result.status,
          maximum == 1
              ? SolverStatus.budgetExhausted
              : SolverStatus.solvedOptimal,
        );
      }
    },
  );

  test('arena memory guard is checked before allocation at n-1/n/n+1', () {
    final solver = PuzzleSolver(direct());
    final baseline = solver.solve(
      budget: SolverWorkBudget(maxStates: 1, clockMicros: () => 0),
    );
    final needed = baseline.accountedBytes;
    for (final bytes in [needed - 1, needed, needed + 1]) {
      final result = solver.solve(
        budget: SolverWorkBudget(
          maxStates: 1,
          maxBytes: bytes,
          clockMicros: () => 0,
        ),
      );
      expect(result.accountedBytes, lessThanOrEqualTo(bytes));
      expect(
        result.status,
        bytes < needed
            ? SolverStatus.budgetExhausted
            : SolverStatus.solvedOptimal,
      );
    }
  });

  test(
    'state limit is inclusive, counts retained unique states, and does not reset',
    () {
      final puzzle = costPriority();
      final bounded = PuzzleSolver(
        puzzle,
      ).solve(budget: SolverWorkBudget(maxStates: 1, clockMicros: () => 0));
      expect(bounded.status, SolverStatus.budgetExhausted);
      expect(bounded.reason, 'stateLimit');
      expect(bounded.statesRetained, 1);
      final budget = SolverWorkBudget(maxTransitions: 3, clockMicros: () => 0);
      expect(
        PuzzleSolver(direct()).solve(budget: budget).status,
        SolverStatus.solvedOptimal,
      );
      final second = PuzzleSolver(direct()).solve(budget: budget);
      expect(second.status, SolverStatus.budgetExhausted);
      expect(second.transitionsEvaluated, 3);
      expect(budget.activeAccountedBytes, 0);
    },
  );

  test('exhausted search may retain an already fully verified incumbent', () {
    final puzzle = costPriority();
    SolverResult? incumbent;
    for (var cap = 1; cap <= 30; cap++) {
      final result = PuzzleSolver(
        puzzle,
      ).solve(budget: unlimitedClock(maxTransitions: cap));
      if (result.status == SolverStatus.budgetExhausted &&
          result.replay != null) {
        incumbent = result;
        break;
      }
    }
    expect(incumbent, isNotNull);
    expect(incumbent!.isOptimal, isFalse);
    expectGenuineSolution(puzzle, incumbent);
  });

  test(
    'injected monotonic deadline and cancellation are checked during work',
    () {
      SolverWorkBudget? deadline;
      deadline = SolverWorkBudget(
        timeLimit: const Duration(microseconds: 10),
        clockMicros: () => (deadline?.transitionsEvaluated ?? 0) >= 2 ? 10 : 0,
      );
      final timed = PuzzleSolver(loop()).solve(budget: deadline);
      expect(timed.status, SolverStatus.budgetExhausted);
      expect(timed.reason, 'deadline');
      expect(timed.transitionsEvaluated, 2);
      SolverWorkBudget? cancelled;
      cancelled = SolverWorkBudget(
        clockMicros: () => 0,
        isCancelled: () => (cancelled?.transitionsEvaluated ?? 0) >= 2,
      );
      final stopped = PuzzleSolver(loop()).solve(budget: cancelled);
      expect(stopped.status, SolverStatus.cancelled);
      expect(stopped.transitionsEvaluated, 2);
    },
  );

  test(
    'cooperative async search yields so a Timer can cancel ongoing work',
    () async {
      var cancelled = false;
      final budget = SolverWorkBudget.offline(
        isCancelled: () => cancelled,
        clockMicros: () => 0,
      );
      final timer = Timer.periodic(Duration.zero, (timer) {
        if (budget.transitionsEvaluated > 0) {
          cancelled = true;
          timer.cancel();
        }
      });
      try {
        final result = await PuzzleSolver(loop()).solveAsync(budget: budget);
        expect(result.status, SolverStatus.cancelled);
        expect(result.transitionsEvaluated, greaterThan(0));
        expect(result.transitionsEvaluated, lessThan(128));
        expect(budget.activeAccountedBytes, 0);
      } finally {
        timer.cancel();
      }
    },
  );

  test('sync and async return the same deterministic optimal replay', () async {
    final puzzle = cycleSync();
    final sync = PuzzleSolver(puzzle).solve(budget: unlimitedClock());
    final async = await PuzzleSolver(
      puzzle,
    ).solveAsync(budget: unlimitedClock());
    expect(async.status, sync.status);
    expect(async.score!.toTuple(), sync.score!.toTuple());
    expect(async.replay!.canonicalBytes, sync.replay!.canonicalBytes);
    expect(async.transitionsEvaluated, sync.transitionsEvaluated);
  });
}
