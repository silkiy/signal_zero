import 'dart:convert';
import 'dart:io';

import 'package:puzzle_domain/puzzle_domain.dart';
import 'package:test/test.dart';

Map<String, dynamic> simplePuzzle() => {
  'schema_version': 'sz-puzzle-1',
  'engine_version': 'sz-engine-1',
  'rules_version': 'sz-rules-1',
  'tick_limit': 1,
  'nodes': <Map<String, dynamic>>[
    {'id': 'a', 'kind': 'source'},
    {'id': 't', 'kind': 'target'},
  ],
  'edges': <Map<String, dynamic>>[
    {'id': 'at', 'from': 'a', 'to': 't', 'port': 0},
  ],
};

PuzzleSpec decode(Map<String, dynamic> value) =>
    PuzzleSpec.decode(utf8.encode(jsonEncode(value)));

Matcher failsWith(String code) =>
    throwsA(isA<DomainException>().having((error) => error.code, 'code', code));

void main() {
  group('puzzle specification', () {
    test('parses the four immutable typed entities and indexes', () {
      final spec = decode(simplePuzzle());
      expect(spec.schemaVersion, 'sz-puzzle-1');
      expect(spec.engineVersion, engineVersion);
      expect(spec.rulesVersion, rulesVersion);
      expect(spec.tickLimit, 1);
      expect(spec.nodes.first.kind, NodeKind.source);
      expect(spec.nodes.first.initialState, isNull);
      expect(spec.edges.single.fromId, 'a');
      expect(spec.edges.single.toId, 't');
      expect(spec.edges.single.port, 0);
      expect(spec.nodeById['t']!.kind, NodeKind.target);
      expect(spec.outgoingByNode['a'], [spec.edges.single]);
      expect(spec.outgoingByNode['t'], isEmpty);
      expect(() => spec.nodes.clear(), throwsUnsupportedError);
      expect(() => spec.edges.clear(), throwsUnsupportedError);
      expect(() => spec.nodeById.clear(), throwsUnsupportedError);
      expect(() => spec.outgoingByNode['a']!.clear(), throwsUnsupportedError);
      expect(() => spec.toJson().clear(), throwsUnsupportedError);
      expect(
        () => (spec.toJson()['nodes'] as List).clear(),
        throwsUnsupportedError,
      );
      expect(
        () => ((spec.toJson()['nodes'] as List).first as Map).clear(),
        throwsUnsupportedError,
      );
      expect(() => spec.canonicalBytes[0] = 0, throwsUnsupportedError);
      expect(
        () => spec.canonicalBytes.buffer.asUint8List()[0] = 0,
        throwsUnsupportedError,
      );
    });

    test('all manually authored rules puzzles are structurally valid', () {
      final source =
          jsonDecode(
                File(
                  '../../specs/test-vectors/rules-cases.json',
                ).readAsStringSync(),
              )
              as Map<String, dynamic>;
      for (final row in source['cases'] as List<dynamic>) {
        final puzzle = Map<String, dynamic>.from(row['puzzle'] as Map);
        expect(
          decode(puzzle).tickLimit,
          puzzle['tick_limit'],
          reason: row['id'],
        );
      }
    });

    test('canonical bytes and SHA256 match independently reviewed fixture', () {
      final fixture =
          jsonDecode(
                File(
                  '../../specs/test-vectors/scoring-cases.json',
                ).readAsStringSync(),
              )['identity_vector']
              as Map<String, dynamic>;
      final raw = fixture['canonical_puzzle'] as String;
      final spec = PuzzleSpec.parse(raw);
      expect(utf8.decode(spec.canonicalBytes), raw);
      expect(spec.puzzleHash, fixture['puzzle_hash']);
      final reordered = jsonDecode(raw) as Map<String, dynamic>;
      reordered['nodes'] = (reordered['nodes'] as List).reversed.toList();
      reordered['edges'] = (reordered['edges'] as List).reversed.toList();
      expect(decode(reordered).puzzleHash, spec.puzzleHash);
      expect(decode(reordered).toJson(), spec.toJson());
    });

    test('caller-owned input cannot mutate parsed models', () {
      final input = simplePuzzle();
      final spec = PuzzleSpec.fromJson(input);
      final before = spec.puzzleHash;
      (input['nodes'] as List).clear();
      input['tick_limit'] = 64;
      expect(spec.nodes, hasLength(2));
      expect(spec.tickLimit, 1);
      expect(spec.puzzleHash, before);
    });

    test('64 ticks and 64 nodes are inclusive limits', () {
      final input = simplePuzzle()..['tick_limit'] = 64;
      final nodes = input['nodes'] as List;
      for (var i = 0; i < 62; i++) {
        nodes.add({'id': 'r$i', 'kind': 'relay'});
      }
      expect(decode(input).nodes, hasLength(64));
      nodes.add({'id': 'overflow', 'kind': 'relay'});
      expect(() => decode(input), failsWith('LIMIT_EXCEEDED'));
    });

    test('eight sources and targets are inclusive limits', () {
      final input = simplePuzzle();
      input['nodes'] = <Map<String, dynamic>>[
        for (var i = 0; i < 8; i++) {'id': 's$i', 'kind': 'source'},
        for (var i = 0; i < 8; i++) {'id': 't$i', 'kind': 'target'},
      ];
      input['edges'] = <Map<String, dynamic>>[
        for (var i = 0; i < 8; i++)
          {'id': 'e$i', 'from': 's$i', 'to': 't$i', 'port': 0},
      ];
      expect(decode(input).nodes, hasLength(16));
      (input['nodes'] as List).addAll(<Map<String, dynamic>>[
        {'id': 's8', 'kind': 'source'},
        {'id': 't8', 'kind': 'target'},
      ]);
      (input['edges'] as List).add({
        'id': 'e8',
        'from': 's8',
        'to': 't8',
        'port': 0,
      });
      expect(() => decode(input), failsWith('LIMIT_EXCEEDED'));
    });

    test('32 switches are allowed but 33 are rejected', () {
      final input = simplePuzzle();
      (input['nodes'] as List).add({'id': 'r', 'kind': 'relay'});
      void addSwitch(int i) {
        (input['nodes'] as List).add({
          'id': 'w$i',
          'kind': 'switch',
          'initial_state': i % 2,
        });
        (input['edges'] as List).addAll(<Map<String, dynamic>>[
          {'id': 'w${i}a', 'from': 'w$i', 'to': 't', 'port': 0},
          {'id': 'w${i}b', 'from': 'w$i', 'to': 'r', 'port': 1},
        ]);
      }

      for (var i = 0; i < 32; i++) {
        addSwitch(i);
      }
      expect(
        decode(input).nodes.where((n) => n.kind == NodeKind.switchNode),
        hasLength(32),
      );
      addSwitch(32);
      expect(() => decode(input), failsWith('LIMIT_EXCEEDED'));
    });

    for (final tick in [0, 65]) {
      test('tick limit $tick is rejected with structured path', () {
        final input = simplePuzzle()..['tick_limit'] = tick;
        expect(
          () => decode(input),
          throwsA(
            isA<DomainException>()
                .having((e) => e.code, 'code', 'INVALID_TICK')
                .having((e) => e.path, 'path', r'$.tick_limit'),
          ),
        );
      });
    }

    for (final versionField in [
      'schema_version',
      'engine_version',
      'rules_version',
    ]) {
      test('unknown $versionField does not fall back to current version', () {
        final input = simplePuzzle()..[versionField] = 'future-999';
        expect(() => decode(input), failsWith('UNSUPPORTED_VERSION'));
      });
    }

    test('unknown or missing object fields are rejected', () {
      final extra = simplePuzzle()..['title'] = 'excluded metadata';
      expect(() => decode(extra), failsWith('UNKNOWN_FIELD'));
      final missing = simplePuzzle()..remove('tick_limit');
      expect(() => decode(missing), failsWith('MISSING_FIELD'));
      final extraNode = simplePuzzle();
      (extraNode['nodes'] as List).first['initial_state'] = 0;
      expect(() => decode(extraNode), failsWith('UNKNOWN_FIELD'));
      final extraEdge = simplePuzzle();
      (extraEdge['edges'] as List).first['weight'] = 2;
      expect(() => decode(extraEdge), failsWith('UNKNOWN_FIELD'));
    });

    for (final id in ['', 'A', 'a-b', 'é', 'a' * 33]) {
      test('invalid ID ${jsonEncode(id)} is rejected', () {
        final input = simplePuzzle();
        (input['nodes'] as List).first['id'] = id;
        expect(() => decode(input), failsWith('INVALID_ID'));
      });
    }

    test(
      'duplicate node IDs, edge IDs and foreign references are rejected',
      () {
        final nodes = simplePuzzle();
        (nodes['nodes'] as List).last['id'] = 'a';
        expect(() => decode(nodes), failsWith('DUPLICATE_ID'));
        final edges = simplePuzzle();
        (edges['edges'] as List).add({
          'id': 'at',
          'from': 'a',
          'to': 't',
          'port': 0,
        });
        expect(() => decode(edges), failsWith('DUPLICATE_ID'));
        final foreign = simplePuzzle();
        (foreign['edges'] as List).first['to'] = 'missing';
        expect(() => decode(foreign), failsWith('UNKNOWN_REFERENCE'));
      },
    );

    test(
      'graph degree, endpoint pairs, count and initial state are enforced',
      () {
        final sourceIncoming = simplePuzzle();
        (sourceIncoming['edges'] as List).first['to'] = 'a';
        expect(() => decode(sourceIncoming), failsWith('INVALID_GRAPH'));
        final mismatch = simplePuzzle();
        (mismatch['nodes'] as List).add({'id': 't2', 'kind': 'target'});
        expect(() => decode(mismatch), failsWith('INVALID_GRAPH'));
        final targetOutgoing = simplePuzzle();
        (targetOutgoing['edges'] as List).add({
          'id': 'ta',
          'from': 't',
          'to': 'a',
          'port': 0,
        });
        expect(() => decode(targetOutgoing), failsWith('INVALID_GRAPH'));
        final parallel = simplePuzzle();
        (parallel['edges'] as List).add({
          'id': 'at2',
          'from': 'a',
          'to': 't',
          'port': 1,
        });
        expect(() => decode(parallel), failsWith('INVALID_GRAPH'));
        final switchMissing = simplePuzzle();
        (switchMissing['nodes'] as List).first['kind'] = 'switch';
        expect(() => decode(switchMissing), failsWith('MISSING_FIELD'));
      },
    );

    test('oversized edge list is rejected before per-edge processing', () {
      final input = simplePuzzle()
        ..['edges'] = List.filled(129, <String, dynamic>{});
      expect(() => decode(input), failsWith('LIMIT_EXCEEDED'));
    });

    test('malformed root and field types never leak a runtime cast error', () {
      for (final raw in ['[]', 'null', 'true', '1', '{', '{} trailing']) {
        expect(
          () => PuzzleSpec.parse(raw),
          throwsA(isA<DomainException>()),
          reason: raw,
        );
      }
      for (final value in [true, null, '1', 1.0]) {
        final input = simplePuzzle()..['tick_limit'] = value;
        expect(() => decode(input), failsWith('INVALID_INTEGER'));
      }
    });
  });

  group('strict bounded raw decoder', () {
    test('canonical encoder rejects DEL control characters', () {
      expect(
        () => CanonicalJson.encode({'value': '\u007f'}),
        failsWith('INVALID_VALUE'),
      );
    });

    test('64 KiB raw input accepted, next byte rejected before parsing', () {
      final raw = jsonEncode(simplePuzzle());
      final atLimit = raw.padRight(65536);
      expect(PuzzleSpec.parse(atLimit).tickLimit, 1);
      expect(() => PuzzleSpec.parse('$atLimit '), failsWith('INPUT_LIMIT'));
    });

    test('root container is depth 1 and depth 17 is rejected', () {
      final atLimit = '${'[' * 16}0${']' * 16}';
      expect(CanonicalJson.decode(utf8.encode(atLimit)), isA<List>());
      expect(
        () => CanonicalJson.decode(utf8.encode('[$atLimit]')),
        failsWith('DEPTH_LIMIT'),
      );
    });

    test('invalid UTF8 and BOM are rejected', () {
      expect(() => PuzzleSpec.decode([0xc3, 0x28]), failsWith('INVALID_UTF8'));
      expect(
        () => PuzzleSpec.decode([0xef, 0xbb, 0xbf, ...utf8.encode('{}')]),
        failsWith('INVALID_JSON'),
      );
    });

    test(
      'duplicate root/nested/escaped keys are rejected before replacement',
      () {
        for (final raw in [
          '{"tick_limit":1,"tick_limit":2}',
          '{"nodes":[{"id":"a","id":"b"}]}',
          r'{"tick_limit":1,"ti\u0063k_limit":2}',
        ]) {
          expect(() => PuzzleSpec.parse(raw), failsWith('DUPLICATE_FIELD'));
        }
      },
    );

    for (final token in [
      '-0',
      '-1',
      '+1',
      '1.0',
      '1e1',
      '1E+1',
      '01',
      '2147483648',
      '9999999999999999999999999999',
      'NaN',
      'Infinity',
    ]) {
      test(
        'rejects numeric lexeme $token without losing original spelling',
        () {
          final raw = jsonEncode(
            simplePuzzle(),
          ).replaceFirst('"tick_limit":1', '"tick_limit":$token');
          expect(() => PuzzleSpec.parse(raw), failsWith('INVALID_INTEGER'));
        },
      );
    }

    test('escaped ASCII IDs canonicalize to literal ASCII', () {
      final raw = jsonEncode(simplePuzzle());
      final escaped = raw.replaceAll('"a"', r'"\u0061"');
      expect(
        PuzzleSpec.parse(escaped).puzzleHash,
        PuzzleSpec.parse(raw).puzzleHash,
      );
    });
  });
}
