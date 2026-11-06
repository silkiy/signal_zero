import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:puzzle_domain/puzzle_domain.dart';
import 'package:test/test.dart';

import 'seeded_puzzles.dart';

void main() {
  for (final example in seededPuzzles()) {
    test(
      'seed ${example.seed} ${example.family}: deterministic, global, one-edge, normalized',
      () {
        final puzzle = example.puzzle;
        final random = Random(
          example.seed ^ example.family.codeUnits.fold(0, (a, b) => a + b),
        );
        final raw = puzzle.toJson();
        final reordered = PuzzleSpec.fromJson({
          ...raw,
          'nodes': (raw['nodes']! as List).reversed.toList(),
          'edges': (raw['edges']! as List).reversed.toList(),
        });
        expect(
          reordered.puzzleHash,
          puzzle.puzzleHash,
          reason: example.context(),
        );
        for (var sample = 0; sample < 8; sample++) {
          final program = programFromMask(
            puzzle,
            random.nextInt(1 << puzzle.tickLimit),
          );
          final context = example.context(program);
          final replay = ReplaySpec.fromProgram(puzzle, program);
          final reorderedReplay = ReplaySpec.fromProgram(
            reordered,
            program.toList().reversed.toSet(),
          );
          final run = SimulationRunner(puzzle).run(replay);
          final again = SimulationRunner(puzzle).run(replay);
          final permuted = SimulationRunner(reordered).run(reorderedReplay);
          expect(
            reorderedReplay.canonicalBytes,
            replay.canonicalBytes,
            reason: context,
          );
          expect(again.snapshotHashes, run.snapshotHashes, reason: context);
          expect(permuted.snapshotHashes, run.snapshotHashes, reason: context);
          expect(
            jsonEncode(permuted.snapshots.map((s) => s.toJson()).toList()),
            jsonEncode(run.snapshots.map((s) => s.toJson()).toList()),
            reason: context,
          );
          final edges = {for (final edge in puzzle.edges) edge.id: edge};
          for (var i = 1; i < run.snapshots.length; i++) {
            final before = run.snapshots[i - 1];
            final after = run.snapshots[i];
            expect(after.tick, before.tick + 1, reason: context);
            expect(after.signals.keys, before.signals.keys, reason: context);
            for (final entry in before.switches.entries) {
              expect(
                after.switches[entry.key],
                program.contains(after.tick) ? 1 - entry.value : entry.value,
                reason: context,
              );
            }
            for (final token in before.signals.keys) {
              final used = after.usedEdges[token];
              if (used == null) {
                expect(
                  after.signals[token],
                  before.signals[token],
                  reason: context,
                );
                expect(after.reason, TerminalReason.noRoute, reason: context);
                continue;
              }
              final edge = edges[used]!;
              expect(edge.fromId, before.signals[token], reason: context);
              expect(edge.toId, after.signals[token], reason: context);
              final node = puzzle.nodeById[edge.fromId]!;
              expect(
                edge.port,
                node.kind == NodeKind.switchNode ? after.switches[node.id] : 0,
                reason: context,
              );
            }
          }
          expect(run.finalState.isTerminal, isTrue, reason: context);
          expect(
            run.snapshots.length,
            lessThanOrEqualTo(puzzle.tickLimit + 1),
            reason: context,
          );
          if (run.isSuccess) {
            final normalized = run.normalizedReplay!;
            final normalizedRun = SimulationRunner(puzzle).run(normalized);
            expect(
              normalizedRun.normalizedReplay!.canonicalBytes,
              normalized.canonicalBytes,
              reason: context,
            );
            expect(
              normalizedRun.snapshotHashes,
              run.snapshotHashes,
              reason: context,
            );
            final count = program
                .where((tick) => tick <= run.finalState.tick)
                .length;
            expect(Score.fromSuccessfulRun(run).toTuple(), [
              count,
              run.finalState.tick,
              count,
            ], reason: context);
          } else {
            expect(run.normalizedReplay, isNull, reason: context);
          }
        }
      },
    );
  }

  test(
    'seed 0x53434f52: comparator agrees with independent tuples and is transitive',
    () {
      final random = Random(0x53434f52);
      for (var i = 0; i < 1000; i++) {
        List<int> tuple() => [
          random.nextInt(65),
          1 + random.nextInt(64),
          random.nextInt(65),
        ];
        final a = tuple();
        final b = tuple();
        final c = tuple();
        Score score(List<int> v) => Score(v[0], v[1], v[2]);
        final ab = score(a).compareTo(score(b)).sign;
        final bc = score(b).compareTo(score(c)).sign;
        final ac = score(a).compareTo(score(c)).sign;
        final context = 'seed=0x53434f52 iteration=$i a=$a b=$b c=$c';
        expect(ab, tupleCompare(a, b), reason: context);
        expect(ab, -score(b).compareTo(score(a)).sign, reason: context);
        if (ab <= 0 && bc <= 0) {
          expect(ac, lessThanOrEqualTo(0), reason: context);
        }
        expect(score(a).compareTo(score(a)), 0, reason: context);
      }
    },
  );

  final regressions =
      jsonDecode(
            File(
              '../../specs/test-vectors/regressions.json',
            ).readAsStringSync(),
          )
          as Map;
  for (final raw in regressions['cases'] as List) {
    final row = Map<String, dynamic>.from(raw as Map);
    test('regression ${row['id']}: manually derived timing and score', () {
      final puzzle = PuzzleSpec.fromJson(
        Map<String, Object?>.from(row['puzzle'] as Map),
      );
      for (final rawRun in row['runs'] as List) {
        final expected = Map<String, dynamic>.from(rawRun as Map);
        final program = (expected['program'] as List).cast<int>().toSet();
        final result = SimulationRunner(
          puzzle,
        ).run(ReplaySpec.fromProgram(puzzle, program));
        final context = jsonEncode({
          'case': row['id'],
          'puzzle': puzzle.toJson(),
          'program': program.toList(),
        });
        expect(
          result.finalState.status.wireName,
          expected['status'],
          reason: context,
        );
        expect(
          result.finalState.reason.wireName,
          expected['reason'],
          reason: context,
        );
        expect(
          result.finalState.tick,
          expected['completion_tick'],
          reason: context,
        );
        if (result.isSuccess) {
          expect(
            Score.fromSuccessfulRun(result).toTuple(),
            expected['score'],
            reason: context,
          );
        }
      }
    });
  }
}
