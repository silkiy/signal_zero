import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:puzzle_domain/puzzle_domain.dart';

Map<String, Object?> object(Object? value) =>
    (value as Map).cast<String, Object?>();

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const expectedTicks = [1, 3, 4];
  const expectedSources = [1, 1, 2];
  for (var index = 0; index < 3; index++) {
    final id = 'level_0${index + 1}';
    test(
      'registered $id asset has a valid replay and proven baseline',
      () async {
        // Read the actual Flutter asset bundle, so missing pubspec registration
        // fails instead of silently validating a separate filesystem copy.
        final level = object(
          jsonDecode(await rootBundle.loadString('assets/levels/$id.json')),
        );
        expect(level['content_version'], 'sz-curated-1');
        expect(level['level_id'], id);
        expect(level['title'], isA<String>());
        expect((level['title'] as String).trim(), isNotEmpty);
        expect(level['learning_focus'], isA<String>());
        expect((level['learning_focus'] as String).trim(), isNotEmpty);

        final puzzle = PuzzleSpec.fromJson(object(level['puzzle']));
        expect(puzzle.engineVersion, engineVersion);
        expect(puzzle.rulesVersion, rulesVersion);
        expect(
          puzzle.nodes.where((node) => node.kind == NodeKind.source),
          hasLength(expectedSources[index]),
        );
        expect(
          puzzle.nodes.where((node) => node.kind == NodeKind.target),
          hasLength(expectedSources[index]),
        );
        expect(
          puzzle.nodes.where((node) => node.kind == NodeKind.switchNode),
          isEmpty,
          reason: 'These introductory levels teach fixed paths before SHIFT.',
        );

        final layout = object(level['layout']);
        expect(layout['width'], 960);
        expect(layout['height'], 540);
        final positions = object(layout['nodes']);
        expect(
          positions.keys,
          unorderedEquals(puzzle.nodes.map((node) => node.id)),
        );
        final occupied = <String>{};
        for (final entry in positions.entries) {
          final position = object(entry.value);
          expect(position.keys, unorderedEquals(['x', 'y']));
          expect(position['x'], isA<int>());
          expect(position['y'], isA<int>());
          final x = position['x'] as int;
          final y = position['y'] as int;
          expect(x, inInclusiveRange(0, 960));
          expect(y, inInclusiveRange(0, 540));
          expect(
            occupied.add('$x,$y'),
            isTrue,
            reason: 'Node positions must differ.',
          );
        }

        final solution = object(level['solution']);
        final ticks = (solution['shift_ticks'] as List).cast<int>();
        expect(ticks, isEmpty);
        final replay = ReplaySpec.fromProgram(puzzle, ticks.toSet());
        final run = SimulationRunner(puzzle).run(replay);
        expect(run.isSuccess, isTrue);
        expect(run.finalState.tick, expectedTicks[index]);
        expect(run.finalState.reason, TerminalReason.success);
        expect(run.snapshots, hasLength(expectedTicks[index] + 1));
        expect(
          run.snapshots
              .take(run.snapshots.length - 1)
              .every((snapshot) => snapshot.targetArrivals.isEmpty),
          isTrue,
          reason: 'Targets must be reached together on the final tick.',
        );

        final baseline = object(level['baseline']);
        expect(baseline['puzzle_hash'], puzzle.puzzleHash);
        expect(baseline['score'], [0, expectedTicks[index], 0]);
        expect(Score.fromSuccessfulRun(run).toTuple(), baseline['score']);
        expect(baseline['optimality'], 'solvedOptimal');
        expect(baseline['proof_objective'], 'lexicographicScore');
        expect((baseline['explanation'] as String).trim(), isNotEmpty);
        final solved = PuzzleSolver(
          puzzle,
        ).solve(budget: SolverWorkBudget.offline());
        expect(solved.status, SolverStatus.solvedOptimal);
        expect(solved.isOptimal, isTrue);
        expect(solved.proofObjective, baseline['proof_objective']);
        expect(solved.score!.toTuple(), baseline['score']);
        final checked = SimulationRunner(puzzle).run(solved.replay!);
        expect(checked.isSuccess, isTrue);
        expect(Score.fromSuccessfulRun(checked), solved.score);

        // The envelope holds presentation and teaching metadata. PuzzleSpec only
        // receives its explicit gameplay child; metadata never enters its hash.
        final editedEnvelope = {
          ...level,
          'title': 'Edited local title',
          'learning_focus': 'Edited local teaching text',
          'layout': {'width': 1, 'height': 1, 'nodes': <String, Object?>{}},
        };
        final samePuzzle = PuzzleSpec.fromJson(
          object(editedEnvelope['puzzle']),
        );
        expect(samePuzzle.puzzleHash, puzzle.puzzleHash);
        expect(samePuzzle.canonicalBytes, puzzle.canonicalBytes);
        expect(
          () => PuzzleSpec.fromJson(editedEnvelope),
          throwsA(isA<DomainException>()),
          reason: 'A content envelope is not itself an accepted puzzle schema.',
        );
      },
    );
  }
}
