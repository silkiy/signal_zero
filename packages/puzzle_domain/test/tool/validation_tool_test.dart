import 'dart:convert';
import 'dart:io';

import 'package:test/test.dart';

Map<String, Object?> object(Object? value) =>
    (value as Map).cast<String, Object?>();

Directory repositoryRoot() {
  var directory = Directory.current.absolute;
  while (!File('${directory.path}/specs/rules.md').existsSync()) {
    final parent = directory.parent;
    if (parent.path == directory.path) {
      throw StateError('Repository root missing.');
    }
    directory = parent;
  }
  return directory;
}

void main() {
  final root = repositoryRoot();
  final package = '${root.path}/packages/puzzle_domain';
  late Directory temp;
  late String successPuzzle;
  late String successReplay;
  late String unsatPuzzle;
  late String failedReplay;

  Future<ProcessResult> invoke(String tool, List<String> args) => Process.run(
    Platform.resolvedExecutable,
    ['--suppress-analytics', 'run', 'tool/$tool.dart', ...args],
    workingDirectory: package,
  );

  Map<String, Object?> output(ProcessResult result, int expectedExit) {
    expect(
      result.exitCode,
      expectedExit,
      reason: '${result.stdout}\n${result.stderr}',
    );
    expect(result.stderr, isEmpty);
    final lines = const LineSplitter().convert(result.stdout as String);
    expect(
      lines,
      hasLength(1),
      reason: 'One machine-readable JSON record per invocation.',
    );
    return object(jsonDecode(lines.single));
  }

  setUpAll(() {
    temp = Directory.systemTemp.createTempSync('signal-zero-cli-');
    Map<String, Object?> fixture(String suite, String id) {
      final document = object(
        jsonDecode(
          File(
            '${root.path}/specs/test-vectors/$suite.json',
          ).readAsStringSync(),
        ),
      );
      return (document['cases'] as List)
          .map(object)
          .singleWhere((item) => item['id'] == id);
    }

    String write(String name, Object? value) {
      final file = File('${temp.path}/$name.json');
      file.writeAsStringSync(jsonEncode(value));
      return file.path;
    }

    final good = fixture('core', 'single_path');
    final impossible = fixture('edge-cases', 'tick_limit');
    successPuzzle = write('success-puzzle', good['puzzle']);
    successReplay = write('success-replay', good['submitted_replay']);
    unsatPuzzle = write('unsat-puzzle', impossible['puzzle']);
    failedReplay = write('failed-replay', impossible['submitted_replay']);
  });

  tearDownAll(() => temp.deleteSync(recursive: true));

  test(
    'actual validator proves a solution without exposing its program',
    () async {
      final report = output(
        await invoke('validate_puzzle', ['--puzzle', successPuzzle]),
        0,
      );
      expect(report['status'], 'solvedOptimal');
      expect(report['is_optimal'], isTrue);
      expect(report['proof_objective'], 'lexicographicScore');
      expect(report['score'], {
        'shift_count': 0,
        'completion_ticks': 2,
        'programming_actions': 0,
      });
      expect(report.containsKey('replay'), isFalse);
      expect(jsonEncode(report), isNot(contains('shift_ticks')));
      expect(jsonEncode(report), isNot(contains('digest')));
    },
  );

  test('actual replay returns score and only opt-in private output', () async {
    final args = ['--puzzle', successPuzzle, '--replay', successReplay];
    final report = output(await invoke('replay_puzzle', args), 0);
    expect(report['status'], 'SUCCEEDED');
    expect(report['reason'], 'SUCCESS');
    expect(report['completion_tick'], 2);
    expect(report['score'], {
      'shift_count': 0,
      'completion_ticks': 2,
      'programming_actions': 0,
    });
    expect(report.containsKey('snapshots'), isFalse);
    expect(report.containsKey('replay'), isFalse);
    expect(jsonEncode(report), isNot(contains('digest')));
    final traced = output(
      await invoke('replay_puzzle', [...args, '--trace', '--include-replay']),
      0,
    );
    expect(traced['snapshots'], hasLength(3));
    expect(object(traced['replay'])['shift_ticks'], isEmpty);
    expect(traced['score'], report['score']);
  });

  test(
    'UNSAT and failed replay use exit3 with distinct structured statuses',
    () async {
      final unsat = output(
        await invoke('validate_puzzle', ['--puzzle', unsatPuzzle]),
        3,
      );
      expect(unsat['status'], 'unsatisfiable');
      expect(unsat['score'], isNull);
      final failed = output(
        await invoke('replay_puzzle', [
          '--puzzle',
          unsatPuzzle,
          '--replay',
          failedReplay,
        ]),
        3,
      );
      expect(failed['status'], 'FAILED');
      expect(failed['reason'], 'TICK_LIMIT');
      expect(failed['score'], isNull);
    },
  );

  test(
    'zero transition allowance is budget exhausted on a solvable puzzle',
    () async {
      final report = output(
        await invoke('validate_puzzle', [
          '--puzzle',
          successPuzzle,
          '--max-transitions',
          '0',
        ]),
        4,
      );
      expect(report['status'], 'budgetExhausted');
      expect(report['is_optimal'], isFalse);
      expect(object(report['work'])['transitions_evaluated'], 0);
    },
  );

  test(
    'corrupt, unsupported and replay binding errors are safe exit2',
    () async {
      final bad = File('${temp.path}/corrupt.json')
        ..writeAsStringSync('{"secret":"never print me"');
      final report = output(
        await invoke('validate_puzzle', ['--puzzle', bad.path]),
        2,
      );
      expect(report['status'], 'invalidInput');
      expect(jsonEncode(report), isNot(contains('never print me')));
      final mismatch = output(
        await invoke('replay_puzzle', [
          '--puzzle',
          successPuzzle,
          '--replay',
          failedReplay,
        ]),
        2,
      );
      expect(mismatch['code'], 'PUZZLE_MISMATCH');
      final replay = object(jsonDecode(File(successReplay).readAsStringSync()));
      replay['engine_version'] = 'sz-engine-future';
      final unsupported = File('${temp.path}/future.json')
        ..writeAsStringSync(jsonEncode(replay));
      final future = output(
        await invoke('replay_puzzle', [
          '--puzzle',
          successPuzzle,
          '--replay',
          unsupported.path,
        ]),
        2,
      );
      expect(future['code'], 'UNSUPPORTED_VERSION');
    },
  );

  test(
    'oversized files rejected before decoding, with separate replay limit',
    () async {
      final largePuzzle = File('${temp.path}/large-puzzle.json')
        ..writeAsStringSync(' ' * 65537);
      final largeReplay = File('${temp.path}/large-replay.json')
        ..writeAsStringSync(' ' * 16385);
      expect(
        output(
          await invoke('validate_puzzle', ['--puzzle', largePuzzle.path]),
          2,
        )['code'],
        'INPUT_LIMIT',
      );
      expect(
        output(
          await invoke('replay_puzzle', [
            '--puzzle',
            successPuzzle,
            '--replay',
            largeReplay.path,
          ]),
          2,
        )['code'],
        'INPUT_LIMIT',
      );
    },
  );

  test(
    'missing files and remote URLs are rejected without echoing their paths',
    () async {
      final missing = '${temp.path}/private-missing-puzzle.json';
      final report = output(
        await invoke('validate_puzzle', ['--puzzle', missing]),
        2,
      );
      expect(report['code'], 'FILE_IO');
      expect(jsonEncode(report), isNot(contains(missing)));
      expect(
        output(
          await invoke('validate_puzzle', [
            '--puzzle',
            'https://example.invalid/private.json',
          ]),
          2,
        )['code'],
        'LOCAL_FILE_REQUIRED',
      );
    },
  );

  test(
    'strict arguments reject unknown, duplicate, missing and bad budgets',
    () async {
      for (final args in <List<String>>[
        [],
        ['--puzzle'],
        ['--puzzle', successPuzzle, '--puzzle', successPuzzle],
        ['--puzzle', successPuzzle, '--trace'],
        ['--puzzle', successPuzzle, '--max-states', '-1'],
        ['--puzzle', successPuzzle, '--max-states', '25001'],
        ['--puzzle', successPuzzle, '--max-transitions', '50001'],
        ['--puzzle', successPuzzle, '--max-bytes', '33554433'],
        ['--puzzle', successPuzzle, '--time-limit-ms', '5001'],
        ['--puzzle', successPuzzle, '--time-limit-ms', '1e3'],
        ['--puzzle', successPuzzle, '--time-limit-ms', 'NaN'],
        ['--puzzle', successPuzzle, '--max-states', '999999999999999999999'],
      ]) {
        expect(
          output(await invoke('validate_puzzle', args), 2)['code'],
          'INVALID_ARGUMENTS',
          reason: '$args',
        );
      }
      expect(
        output(
          await invoke('replay_puzzle', [
            '--puzzle',
            successPuzzle,
            '--replay',
            successReplay,
            '--trace',
            '--trace',
          ]),
          2,
        )['code'],
        'INVALID_ARGUMENTS',
      );
    },
    timeout: const Timeout(Duration(minutes: 2)),
  );
}
