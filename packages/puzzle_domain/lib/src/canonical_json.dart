import 'dart:convert';
import 'dart:typed_data';

import 'domain_error.dart';

/// The bounded sz-cjson-1 transport/identity primitives.
///
/// Decode preserves numeric spelling checks and duplicate keys before a normal
/// JSON decoder could lose that evidence. Schema validation remains the caller's
/// responsibility. Encode accepts ASCII strings and unsigned integers only.
abstract final class CanonicalJson {
  static Object? decode(
    List<int> bytes, {
    int maxBytes = 65536,
    int maxDepth = 16,
  }) {
    if (maxBytes < 1 || maxDepth < 1) {
      throw ArgumentError('Limits must be positive.');
    }
    if (bytes.length > maxBytes) {
      throw const DomainException(
        'INPUT_LIMIT',
        r'$',
        'Input exceeds byte limit.',
      );
    }
    if (bytes.any((byte) => byte < 0 || byte > 255)) {
      throw const DomainException('INVALID_UTF8', r'$', 'Invalid UTF-8 input.');
    }
    if (bytes.length >= 3 &&
        bytes[0] == 0xef &&
        bytes[1] == 0xbb &&
        bytes[2] == 0xbf) {
      throw const DomainException(
        'INVALID_JSON',
        r'$',
        'BOM is not permitted.',
      );
    }
    final String text;
    try {
      text = utf8.decode(bytes, allowMalformed: false);
    } on FormatException {
      throw const DomainException('INVALID_UTF8', r'$', 'Invalid UTF-8 input.');
    }
    return _RawJsonReader(text, maxDepth).read();
  }

  static Uint8List encode(
    Object? value, {
    int maxBytes = 65536,
    int maxDepth = 16,
  }) {
    if (maxBytes < 1 || maxDepth < 1) {
      throw ArgumentError('Limits must be positive.');
    }
    final buffer = StringBuffer();
    void append(String text) {
      if (buffer.length + text.length > maxBytes) {
        throw const DomainException(
          'INPUT_LIMIT',
          r'$',
          'Output exceeds byte limit.',
        );
      }
      buffer.write(text);
    }

    void validateAscii(String value) {
      if (value.length > maxBytes ||
          value.codeUnits.any((unit) => unit < 32 || unit >= 127)) {
        throw const DomainException(
          'INVALID_VALUE',
          r'$',
          'Expected bounded ASCII string.',
        );
      }
    }

    void write(Object? item, int depth) {
      if (item is int) {
        if (item < 0 || item > 2147483647) {
          throw const DomainException(
            'INVALID_INTEGER',
            r'$',
            'Unsigned integer out of range.',
          );
        }
        append(item.toString());
      } else if (item is String) {
        validateAscii(item);
        append(jsonEncode(item));
      } else if (item is List<Object?>) {
        if (depth >= maxDepth) {
          throw const DomainException(
            'DEPTH_LIMIT',
            r'$',
            'Container nesting exceeds limit.',
          );
        }
        append('[');
        for (var i = 0; i < item.length; i++) {
          if (i > 0) append(',');
          write(item[i], depth + 1);
        }
        append(']');
      } else if (item is Map<String, Object?>) {
        if (depth >= maxDepth) {
          throw const DomainException(
            'DEPTH_LIMIT',
            r'$',
            'Container nesting exceeds limit.',
          );
        }
        final keys = item.keys.toList();
        for (final key in keys) {
          validateAscii(key);
        }
        keys.sort();
        append('{');
        for (var i = 0; i < keys.length; i++) {
          if (i > 0) append(',');
          append(jsonEncode(keys[i]));
          append(':');
          write(item[keys[i]], depth + 1);
        }
        append('}');
      } else {
        throw const DomainException(
          'INVALID_VALUE',
          r'$',
          'Unsupported canonical JSON value.',
        );
      }
    }

    write(value, 0);
    return Uint8List.fromList(
      ascii.encode(buffer.toString()),
    ).asUnmodifiableView();
  }
}

final class _RawJsonReader {
  _RawJsonReader(this.text, this.maxDepth);

  final String text;
  final int maxDepth;
  int offset = 0;

  Never fail(String code, String message) =>
      throw DomainException(code, r'$', message, offset: offset);

  Object? read() {
    final value = _value(0);
    _space();
    if (offset != text.length) {
      fail('INVALID_JSON', 'Unexpected trailing content.');
    }
    return value;
  }

  void _space() {
    while (offset < text.length) {
      final unit = text.codeUnitAt(offset);
      if (unit != 32 && unit != 9 && unit != 10 && unit != 13) break;
      offset++;
    }
  }

  bool _take(int unit) {
    _space();
    if (offset < text.length && text.codeUnitAt(offset) == unit) {
      offset++;
      return true;
    }
    return false;
  }

  Object? _value(int parentDepth) {
    _space();
    if (offset == text.length) fail('INVALID_JSON', 'Expected JSON value.');
    final unit = text.codeUnitAt(offset);
    if (unit == 123) return _object(parentDepth + 1);
    if (unit == 91) return _array(parentDepth + 1);
    if (unit == 34) return _string();
    if (unit >= 48 && unit <= 57) return _integer();
    if (unit == 45 || unit == 43 || unit == 78 || unit == 73) {
      fail(
        'INVALID_INTEGER',
        'Only unsigned decimal integer tokens are permitted.',
      );
    }
    for (final entry in const {
      'true': true,
      'false': false,
      'null': null,
    }.entries) {
      if (text.startsWith(entry.key, offset)) {
        offset += entry.key.length;
        return entry.value;
      }
    }
    fail('INVALID_JSON', 'Invalid JSON value.');
  }

  Map<String, Object?> _object(int depth) {
    if (depth > maxDepth) {
      fail('DEPTH_LIMIT', 'Container nesting exceeds limit.');
    }
    offset++;
    final result = <String, Object?>{};
    if (_take(125)) return result;
    while (true) {
      _space();
      if (offset == text.length || text.codeUnitAt(offset) != 34) {
        fail('INVALID_JSON', 'Expected an object key.');
      }
      final key = _string();
      if (result.containsKey(key)) {
        fail('DUPLICATE_FIELD', 'Duplicate JSON object key.');
      }
      if (!_take(58)) fail('INVALID_JSON', 'Expected a colon.');
      result[key] = _value(depth);
      if (_take(125)) return result;
      if (!_take(44)) fail('INVALID_JSON', 'Expected an object separator.');
    }
  }

  List<Object?> _array(int depth) {
    if (depth > maxDepth) {
      fail('DEPTH_LIMIT', 'Container nesting exceeds limit.');
    }
    offset++;
    final result = <Object?>[];
    if (_take(93)) return result;
    while (true) {
      result.add(_value(depth));
      if (_take(93)) return result;
      if (!_take(44)) fail('INVALID_JSON', 'Expected an array separator.');
    }
  }

  String _string() {
    final start = offset++;
    while (offset < text.length) {
      final unit = text.codeUnitAt(offset++);
      if (unit == 34) {
        try {
          return jsonDecode(text.substring(start, offset)) as String;
        } on FormatException {
          fail('INVALID_JSON', 'Invalid JSON string escape.');
        }
      }
      if (unit < 32) fail('INVALID_JSON', 'Unescaped control character.');
      if (unit == 92) {
        if (offset == text.length) {
          fail('INVALID_JSON', 'Truncated string escape.');
        }
        offset++;
      }
    }
    fail('INVALID_JSON', 'Unterminated JSON string.');
  }

  int _integer() {
    final start = offset;
    while (offset < text.length) {
      final unit = text.codeUnitAt(offset);
      if (unit < 48 || unit > 57) break;
      offset++;
    }
    if (offset - start > 10 ||
        (offset - start > 1 && text.codeUnitAt(start) == 48)) {
      fail('INVALID_INTEGER', 'Unsigned integer out of range or leading zero.');
    }
    if (offset < text.length &&
        const [46, 101, 69, 43, 45].contains(text.codeUnitAt(offset))) {
      fail('INVALID_INTEGER', 'Fraction, exponent or sign is not permitted.');
    }
    final value = int.parse(text.substring(start, offset));
    if (value > 2147483647) {
      fail('INVALID_INTEGER', 'Unsigned integer out of range.');
    }
    return value;
  }
}
