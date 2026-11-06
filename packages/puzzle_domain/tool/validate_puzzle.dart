import 'dart:io';

import 'package:puzzle_domain/puzzle_domain.dart';

import 'cli_support.dart';

Future<void> main(List<String> args) => guardedMain(() async {
  final options = parseOptions(
    args,
    values: const {
      '--puzzle',
      '--max-states',
      '--max-transitions',
      '--max-bytes',
      '--time-limit-ms',
    },
    requiredOptions: const {'--puzzle'},
  );
  final budget = SolverWorkBudget.offline(
    maxStates: integerOption(
      options,
      '--max-states',
      fallback: 25000,
      maximum: 25000,
    ),
    maxTransitions: integerOption(
      options,
      '--max-transitions',
      fallback: 50000,
      maximum: 50000,
    ),
    maxBytes: integerOption(
      options,
      '--max-bytes',
      fallback: 33554432,
      maximum: 33554432,
    ),
    timeLimit: Duration(
      milliseconds: integerOption(
        options,
        '--time-limit-ms',
        fallback: 5000,
        maximum: 5000,
      ),
    ),
  );
  final puzzle = PuzzleSpec.decode(
    await readBounded(options['--puzzle']!, 65536),
  );
  final result = PuzzleSolver(puzzle).solve(budget: budget);
  emit({
    ...puzzleIdentity(puzzle),
    'status': result.status.name,
    'reason': result.reason,
    'is_optimal': result.isOptimal,
    'proof_objective': result.proofObjective,
    'score': result.score?.toJson(),
    'work': {
      'states_retained': result.statesRetained,
      'transitions_evaluated': result.transitionsEvaluated,
      'accounted_bytes': result.accountedBytes,
      'elapsed_micros': result.elapsedMicros,
      'memory_measure': 'solverAccountingNotProcessRSS',
    },
  });
  exitCode = switch (result.status) {
    SolverStatus.solvedOptimal => 0,
    SolverStatus.unsatisfiable => 3,
    SolverStatus.budgetExhausted || SolverStatus.cancelled => 4,
  };
});
