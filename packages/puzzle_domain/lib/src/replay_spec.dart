import 'dart:convert';
import 'dart:typed_data';

import 'package:crypto/crypto.dart';

import 'canonical_json.dart';
import 'domain_error.dart';
import 'puzzle_spec.dart';

/// A versioned program bound to an already validated immutable puzzle.
final class ReplaySpec {
  ReplaySpec._(this._puzzle, Iterable<int> ticks)
    : shiftTicks = List<int>.unmodifiable(ticks);

  static const currentSchemaVersion = 'sz-replay-1';
  String get schemaVersion => currentSchemaVersion;
  final PuzzleSpec _puzzle;
  final List<int> shiftTicks;
  String get engineVersion => _puzzle.engineVersion;
  String get rulesVersion => _puzzle.rulesVersion;
  String get puzzleHash => _puzzle.puzzleHash;

  factory ReplaySpec.decode(List<int> bytes, {required PuzzleSpec puzzle}) {
    final value = CanonicalJson.decode(bytes, maxBytes: 16384, maxDepth: 16);
    if (value is! Map<String, Object?>) {
      throw DomainException('INVALID_VALUE', r'$', 'Replay must be an object.');
    }
    return ReplaySpec.fromJson(value, puzzle: puzzle);
  }

  factory ReplaySpec.parse(String input, {required PuzzleSpec puzzle}) {
    // Avoid allocating an unbounded UTF-8 buffer for an oversized String.
    if (input.length > 16384) {
      throw DomainException('INPUT_LIMIT', r'$', 'Replay exceeds 16384 bytes.');
    }
    return ReplaySpec.decode(utf8.encode(input), puzzle: puzzle);
  }

  /// Trusted decoded-map boundary. Use decode/parse on untrusted JSON bytes.
  factory ReplaySpec.fromJson(
    Map<String, Object?> value, {
    required PuzzleSpec puzzle,
  }) {
    const keys = {
      'schema_version',
      'engine_version',
      'rules_version',
      'puzzle_hash',
      'shift_ticks',
    };
    if (!value.keys.every(keys.contains)) {
      throw DomainException('UNKNOWN_FIELD', r'$', 'Unexpected replay fields.');
    }
    for (final key in keys) {
      if (!value.containsKey(key)) {
        throw DomainException(
          'MISSING_FIELD',
          '\$.$key',
          'Required field missing.',
        );
      }
    }
    for (final entry in {
      'schema_version': currentSchemaVersion,
      'engine_version': puzzle.engineVersion,
      'rules_version': puzzle.rulesVersion,
    }.entries) {
      if (value[entry.key] != entry.value) {
        throw DomainException(
          'UNSUPPORTED_VERSION',
          entry.key,
          'Replay version mismatch.',
        );
      }
    }
    if (value['puzzle_hash'] != puzzle.puzzleHash) {
      throw DomainException(
        'PUZZLE_MISMATCH',
        'puzzle_hash',
        'Replay belongs to another puzzle.',
      );
    }
    final ticks = value['shift_ticks'];
    if (ticks is! List) {
      throw DomainException(
        'INVALID_VALUE',
        r'$.shift_ticks',
        'Expected an action list.',
      );
    }
    if (ticks.length > 64) {
      throw DomainException(
        'LIMIT_EXCEEDED',
        'shift_ticks',
        'Expected at most 64 actions.',
      );
    }
    var previous = 0;
    final checked = <int>[];
    for (final tick in ticks) {
      if (tick is! int || tick < 0 || tick > 2147483647) {
        throw DomainException(
          'INVALID_INTEGER',
          r'$.shift_ticks',
          'Expected unsigned integer ticks.',
        );
      }
      if (tick < 1 || tick > puzzle.tickLimit) {
        throw DomainException(
          'INVALID_TICK',
          'shift_ticks',
          'SHIFT tick is outside puzzle bounds.',
        );
      }
      if (tick <= previous) {
        throw DomainException(
          'NON_CANONICAL_ACTIONS',
          'shift_ticks',
          'Ticks must be unique and increasing.',
        );
      }
      checked.add(tick);
      previous = tick;
    }
    return ReplaySpec._(puzzle, checked);
  }

  /// The trusted editor holds a set; edit history is not part of the replay.
  factory ReplaySpec.fromProgram(PuzzleSpec puzzle, Set<int> ticks) {
    if (ticks.length > 64) {
      throw DomainException(
        'LIMIT_EXCEEDED',
        'shift_ticks',
        'Too many actions.',
      );
    }
    final sorted = ticks.toList()..sort();
    return ReplaySpec.fromJson({
      'schema_version': currentSchemaVersion,
      'engine_version': puzzle.engineVersion,
      'rules_version': puzzle.rulesVersion,
      'puzzle_hash': puzzle.puzzleHash,
      'shift_ticks': sorted,
    }, puzzle: puzzle);
  }

  Map<String, Object> toJson() => Map.unmodifiable({
    'schema_version': schemaVersion,
    'engine_version': engineVersion,
    'rules_version': rulesVersion,
    'puzzle_hash': puzzleHash,
    'shift_ticks': shiftTicks,
  });

  Uint8List get canonicalBytes => Uint8List.fromList(
    CanonicalJson.encode(toJson(), maxBytes: 16384),
  ).asUnmodifiableView();

  /// Private deduplication only. Never publish this for an active challenge.
  String get privateDigest => '0x${sha256.convert(canonicalBytes)}';

  /// Caller must have verified success; this is not a simulation or a proof.
  ReplaySpec trimAfterVerifiedSuccess(int completionTick) {
    if (completionTick < 1 || completionTick > _puzzle.tickLimit) {
      throw DomainException(
        'INVALID_TICK',
        'completion_tick',
        'Invalid completion tick.',
      );
    }
    return ReplaySpec._(_puzzle, shiftTicks.where((t) => t <= completionTick));
  }

  /// Server supplies a private CSPRNG salt. This method never invents a salt.
  String publicCommitment(List<int> salt) {
    if (salt.length != 32 || salt.any((b) => b < 0 || b > 255)) {
      throw DomainException(
        'INVALID_SALT',
        'salt',
        'Salt must be exactly 32 bytes.',
      );
    }
    final replay = canonicalBytes;
    final size = ByteData(4)..setUint32(0, replay.length, Endian.big);
    return '0x${sha256.convert([...ascii.encode('SIGNAL_ZERO_REPLAY_V1'), 0, ...salt, ...size.buffer.asUint8List(), ...replay])}';
  }
}
