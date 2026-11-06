import 'dart:convert';
import 'dart:io';

import 'package:puzzle_domain/puzzle_domain.dart';
import 'package:test/test.dart';

void main() {
  test(
    'observe, program, analyze and optimize through real runner and CLI',
    () async {
      final fixture =
          jsonDecode(
                File(
                  '../../specs/test-vectors/playable-core.json',
                ).readAsStringSync(),
              )
              as Map;
      final puzzle = PuzzleSpec.fromJson(
        Map<String, dynamic>.from(fixture['puzzle'] as Map),
      );
      final dir = await Directory.systemTemp.createTemp('sz-headless-');
      final scores = <Score>[];
      try {
        final puzzleFile = File('${dir.path}/puzzle.json');
        await puzzleFile.writeAsString(jsonEncode(puzzle.toJson()));
        for (final row in fixture['cases'] as List) {
          final v = row as Map;
          final replay = ReplaySpec.fromProgram(
            puzzle,
            (v['shift_ticks'] as List).cast<int>().toSet(),
          );
          final first = SimulationRunner(puzzle).run(replay);
          final second = SimulationRunner(
            puzzle,
          ).run(ReplaySpec.decode(replay.canonicalBytes, puzzle: puzzle));
          expect(
            first.snapshots.map((s) => s.toJson()).toList(),
            v['snapshots'],
            reason: v['id'] as String,
          );
          expect(second.snapshotHashes, first.snapshotHashes);
          final replayFile = File('${dir.path}/replay.json');
          await replayFile.writeAsBytes(replay.canonicalBytes);
          final cli = await Process.run(Platform.resolvedExecutable, [
            '--suppress-analytics',
            'run',
            'tool/replay_puzzle.dart',
            '--puzzle',
            puzzleFile.path,
            '--replay',
            replayFile.path,
            '--trace',
          ]);
          expect(
            cli.exitCode,
            first.isSuccess ? 0 : 3,
            reason: '${cli.stdout}\n${cli.stderr}',
          );
          final output = jsonDecode(cli.stdout as String) as Map;
          expect(output['puzzle_hash'], puzzle.puzzleHash);
          expect(output['snapshots'], v['snapshots']);
          expect(output['status'], first.finalState.status.wireName);
          expect(output['reason'], first.finalState.reason.wireName);
          if (first.isSuccess) {
            final score = Score.fromSuccessfulRun(first);
            scores.add(score);
            expect(score.toTuple(), v['score']);
            expect(output['score'], score.toJson());
            expect(Score.fromSuccessfulRun(second), score);
          } else {
            expect(v['score'], isNull);
            expect(output['score'], isNull);
          }
        }
        expect(scores.length, 2);
        expect(scores[1].compareTo(scores[0]), lessThan(0));
        final proof = PuzzleSolver(
          puzzle,
        ).solve(budget: SolverWorkBudget.offline());
        expect(proof.status, SolverStatus.solvedOptimal);
        expect(proof.score, scores[1]);
        final validation = await Process.run(Platform.resolvedExecutable, [
          '--suppress-analytics',
          'run',
          'tool/validate_puzzle.dart',
          '--puzzle',
          puzzleFile.path,
        ]);
        expect(
          validation.exitCode,
          0,
          reason: '${validation.stdout}\n${validation.stderr}',
        );
        final output = jsonDecode(validation.stdout as String) as Map;
        expect(output['status'], 'solvedOptimal');
        expect(output['score'], scores[1].toJson());
        expect(output['engine_version'], engineVersion);
        expect(output['rules_version'], rulesVersion);
      } finally {
        await dir.delete(recursive: true);
      }
    },
  );
}
