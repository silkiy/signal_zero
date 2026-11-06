import 'dart:io';

import 'package:puzzle_domain/puzzle_domain.dart';

import 'cli_support.dart';

Future<void> main(List<String> args) => guardedMain(() async {
  final options = parseOptions(
    args,
    values: const {'--puzzle', '--replay'},
    flags: const {'--trace', '--include-replay'},
    requiredOptions: const {'--puzzle', '--replay'},
  );
  final puzzle = PuzzleSpec.decode(
    await readBounded(options['--puzzle']!, 65536),
  );
  final replay = ReplaySpec.decode(
    await readBounded(options['--replay']!, 16384),
    puzzle: puzzle,
  );
  final result = SimulationRunner(puzzle).run(replay);
  emit({
    ...puzzleIdentity(puzzle),
    'status': result.finalState.status.wireName,
    'reason': result.finalState.reason.wireName,
    'completion_tick': result.finalState.tick,
    'score': result.isSuccess ? Score.fromSuccessfulRun(result).toJson() : null,
    if (options.containsKey('--include-replay'))
      'replay': (result.normalizedReplay ?? replay).toJson(),
    if (options.containsKey('--trace'))
      'snapshots': [for (final state in result.snapshots) state.toJson()],
  });
  exitCode = result.isSuccess ? 0 : 3;
});
