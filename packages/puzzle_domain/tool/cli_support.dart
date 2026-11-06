import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:puzzle_domain/puzzle_domain.dart';

/// Local file tools only; external input is bounded before JSON allocation.
Map<String, String> parseOptions(
  List<String> args, {
  required Set<String> values,
  Set<String> flags = const {},
  required Set<String> requiredOptions,
}) {
  final options = <String, String>{};
  for (var i = 0; i < args.length; i++) {
    final key = args[i];
    if ((!values.contains(key) && !flags.contains(key)) ||
        options.containsKey(key)) {
      throw const CliInputException('INVALID_ARGUMENTS');
    }
    if (flags.contains(key)) {
      options[key] = 'true';
    } else {
      if (++i >= args.length || args[i].startsWith('--') || args[i].isEmpty) {
        throw const CliInputException('INVALID_ARGUMENTS');
      }
      options[key] = args[i];
    }
  }
  if (!requiredOptions.every(options.containsKey)) {
    throw const CliInputException('INVALID_ARGUMENTS');
  }
  return options;
}

int integerOption(
  Map<String, String> options,
  String key, {
  required int fallback,
  required int maximum,
}) {
  final raw = options[key];
  if (raw == null) return fallback;
  // Avoid exponent, sign, whitespace, hex and excessively large integers.
  if (!RegExp(r'^(0|[1-9][0-9]{0,8})$').hasMatch(raw)) {
    throw const CliInputException('INVALID_ARGUMENTS');
  }
  final result = int.parse(raw);
  if (result > maximum) {
    throw const CliInputException('INVALID_ARGUMENTS');
  }
  return result;
}

Future<List<int>> readBounded(String path, int maximum) async {
  // No URL loader or remote service is used by either tool.
  if (RegExp(r'^[a-zA-Z][a-zA-Z0-9+.-]*://').hasMatch(path)) {
    throw const CliInputException('LOCAL_FILE_REQUIRED');
  }
  final handle = await File(path).open();
  try {
    final bytes = BytesBuilder(copy: false);
    while (bytes.length <= maximum) {
      final remaining = maximum + 1 - bytes.length;
      final chunk = await handle.read(remaining < 8192 ? remaining : 8192);
      if (chunk.isEmpty) break;
      bytes.add(chunk);
    }
    if (bytes.length > maximum) {
      throw const CliInputException('INPUT_LIMIT');
    }
    return bytes.takeBytes();
  } finally {
    await handle.close();
  }
}

Map<String, Object?> puzzleIdentity(PuzzleSpec puzzle) => {
  'puzzle_hash': puzzle.puzzleHash,
  'schema_version': puzzle.schemaVersion,
  'engine_version': puzzle.engineVersion,
  'rules_version': puzzle.rulesVersion,
};

void emit(Map<String, Object?> output) => stdout.writeln(jsonEncode(output));

/// Errors never echo file paths, payloads, replay actions or stack traces.
Future<void> guardedMain(Future<void> Function() work) async {
  try {
    await work();
  } on CliInputException catch (error) {
    emit({'status': 'invalidInput', 'code': error.code});
    exitCode = 2;
  } on DomainException catch (error) {
    emit({'status': 'invalidInput', 'code': error.code, 'path': error.path});
    exitCode = 2;
  } on FileSystemException {
    emit({'status': 'invalidInput', 'code': 'FILE_IO'});
    exitCode = 2;
  } catch (_) {
    emit({'status': 'internalError', 'code': 'INTERNAL_ERROR'});
    exitCode = 1;
  }
}

final class CliInputException implements Exception {
  const CliInputException(this.code);
  final String code;
}
