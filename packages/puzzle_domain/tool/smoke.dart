import 'dart:convert';

import 'package:puzzle_domain/puzzle_domain.dart';

void main() {
  final puzzle = PuzzleSpec.fromJson({
    'schema_version': 'sz-puzzle-1',
    'engine_version': engineVersion,
    'rules_version': rulesVersion,
    'tick_limit': 1,
    'nodes': [
      {'id': 'a', 'kind': 'source'},
      {'id': 't', 'kind': 'target'},
    ],
    'edges': [
      {'id': 'at', 'from': 'a', 'to': 't', 'port': 0},
    ],
  });
  final run = SimulationRunner(puzzle).run(ReplaySpec.fromProgram(puzzle, {}));
  print(
    jsonEncode({
      'engine_version': engineVersion,
      'rules_version': rulesVersion,
      'status': run.finalState.status.wireName,
      'score': Score.fromSuccessfulRun(run).toTuple(),
    }),
  );
}
