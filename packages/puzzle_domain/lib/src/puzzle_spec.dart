import 'dart:convert';
import 'dart:typed_data';

import 'package:crypto/crypto.dart';

import '../puzzle_domain.dart' as versions show engineVersion, rulesVersion;
import 'canonical_json.dart';
import 'domain_error.dart';

enum NodeKind {
  source('source'),
  relay('relay'),
  switchNode('switch'),
  target('target');

  const NodeKind(this.wireName);
  final String wireName;
}

final class PuzzleNode {
  const PuzzleNode._(this.id, this.kind, this.initialState);
  final String id;
  final NodeKind kind;
  final int? initialState;

  Map<String, Object?> toJson() => Map.unmodifiable({
    'id': id,
    'kind': kind.wireName,
    if (initialState != null) 'initial_state': initialState,
  });
}

final class PuzzleEdge {
  const PuzzleEdge._(this.id, this.fromId, this.toId, this.port);
  final String id;
  final String fromId;
  final String toId;
  final int port;

  Map<String, Object?> toJson() =>
      Map.unmodifiable({'id': id, 'from': fromId, 'to': toId, 'port': port});
}

/// A structurally valid immutable puzzle. Solvability is a separate concern.
final class PuzzleSpec {
  PuzzleSpec._(
    this.schemaVersion,
    this.engineVersion,
    this.rulesVersion,
    this.tickLimit,
    List<PuzzleNode> nodes,
    List<PuzzleEdge> edges,
  ) : nodes = List.unmodifiable(nodes),
      edges = List.unmodifiable(edges) {
    _nodeById = Map.unmodifiable({for (final node in nodes) node.id: node});
    final outgoing = <String, List<PuzzleEdge>>{
      for (final node in nodes) node.id: [],
    };
    for (final edge in edges) {
      outgoing[edge.fromId]!.add(edge);
    }
    _outgoingByNode = Map<String, List<PuzzleEdge>>.unmodifiable({
      for (final entry in outgoing.entries)
        entry.key: List<PuzzleEdge>.unmodifiable(entry.value),
    });
  }

  static const currentSchemaVersion = 'sz-puzzle-1';
  final String schemaVersion;
  final String engineVersion;
  final String rulesVersion;
  final int tickLimit;
  final List<PuzzleNode> nodes;
  final List<PuzzleEdge> edges;
  late final Map<String, PuzzleNode> _nodeById;
  late final Map<String, List<PuzzleEdge>> _outgoingByNode;
  late final Uint8List _canonicalBytes = CanonicalJson.encode(toJson());
  late final String _puzzleHash = '0x${sha256.convert(canonicalBytes)}';

  Map<String, PuzzleNode> get nodeById => _nodeById;
  Map<String, List<PuzzleEdge>> get outgoingByNode => _outgoingByNode;
  Uint8List get canonicalBytes => _canonicalBytes;
  String get puzzleHash => _puzzleHash;

  factory PuzzleSpec.decode(List<int> rawUtf8) =>
      PuzzleSpec.fromJson(_object(CanonicalJson.decode(rawUtf8), r'$'));

  factory PuzzleSpec.parse(String rawJson) {
    // Reject large UTF-16 input before allocating a second large byte buffer.
    if (rawJson.length > 65536) {
      throw const DomainException(
        'INPUT_LIMIT',
        r'$',
        'Input exceeds byte limit.',
      );
    }
    return PuzzleSpec.decode(utf8.encode(rawJson));
  }

  /// For editor-owned maps. Raw external JSON must use [decode] or [parse], so
  /// duplicate-key and numeric-spelling evidence has not already been lost.
  factory PuzzleSpec.fromJson(Map<String, Object?> json) {
    _fields(json, const {
      'schema_version',
      'engine_version',
      'rules_version',
      'tick_limit',
      'nodes',
      'edges',
    }, r'$');
    _version(json['schema_version'], currentSchemaVersion, r'$.schema_version');
    _version(
      json['engine_version'],
      versions.engineVersion,
      r'$.engine_version',
    );
    _version(json['rules_version'], versions.rulesVersion, r'$.rules_version');
    final limit = _integer(json['tick_limit'], r'$.tick_limit');
    if (limit < 1 || limit > 64) {
      throw const DomainException(
        'INVALID_TICK',
        r'$.tick_limit',
        'Tick limit must be 1..64.',
      );
    }
    final rawNodes = _list(json['nodes'], 2, 64, r'$.nodes');
    final rawEdges = _list(json['edges'], 1, 128, r'$.edges');
    final nodes = <PuzzleNode>[];
    final nodeIds = <String>{};
    for (var i = 0; i < rawNodes.length; i++) {
      final path = '\$.nodes[$i]';
      final raw = _object(rawNodes[i], path);
      final id = _id(raw['id'], '$path.id');
      if (!nodeIds.add(id)) {
        throw DomainException('DUPLICATE_ID', path, 'Duplicate node ID.');
      }
      if (!raw.containsKey('kind')) {
        throw DomainException(
          'MISSING_FIELD',
          '$path.kind',
          'Required field missing.',
        );
      }
      final kind = NodeKind.values
          .where((kind) => kind.wireName == raw['kind'])
          .firstOrNull;
      if (kind == null) {
        throw DomainException(
          'INVALID_GRAPH',
          '$path.kind',
          'Unsupported node kind.',
        );
      }
      _fields(raw, {
        'id',
        'kind',
        if (kind == NodeKind.switchNode) 'initial_state',
      }, path);
      int? initial;
      if (kind == NodeKind.switchNode) {
        initial = _integer(raw['initial_state'], '$path.initial_state');
        if (initial > 1) {
          throw DomainException(
            'INVALID_GRAPH',
            '$path.initial_state',
            'Switch bit must be 0 or 1.',
          );
        }
      }
      nodes.add(PuzzleNode._(id, kind, initial));
    }
    final sourceCount = nodes.where((n) => n.kind == NodeKind.source).length;
    final targetCount = nodes.where((n) => n.kind == NodeKind.target).length;
    final switchCount = nodes
        .where((n) => n.kind == NodeKind.switchNode)
        .length;
    if (sourceCount > 8 || targetCount > 8 || switchCount > 32) {
      throw const DomainException(
        'LIMIT_EXCEEDED',
        r'$.nodes',
        'Node kind count exceeds limit.',
      );
    }
    if (sourceCount < 1 || targetCount < 1 || sourceCount != targetCount) {
      throw const DomainException(
        'INVALID_GRAPH',
        r'$.nodes',
        'Source and target counts must match in 1..8.',
      );
    }
    final edgeIds = <String>{};
    final pairs = <String>{};
    final edges = <PuzzleEdge>[];
    for (var i = 0; i < rawEdges.length; i++) {
      final path = '\$.edges[$i]';
      final raw = _object(rawEdges[i], path);
      _fields(raw, const {'id', 'from', 'to', 'port'}, path);
      final id = _id(raw['id'], '$path.id');
      if (!edgeIds.add(id)) {
        throw DomainException('DUPLICATE_ID', path, 'Duplicate edge ID.');
      }
      final from = _id(raw['from'], '$path.from');
      final to = _id(raw['to'], '$path.to');
      if (!nodeIds.contains(from)) {
        throw DomainException(
          'UNKNOWN_REFERENCE',
          '$path.from',
          'Unknown edge endpoint.',
        );
      }
      if (!nodeIds.contains(to)) {
        throw DomainException(
          'UNKNOWN_REFERENCE',
          '$path.to',
          'Unknown edge endpoint.',
        );
      }
      final port = _integer(raw['port'], '$path.port');
      if (port > 1) {
        throw DomainException(
          'INVALID_GRAPH',
          '$path.port',
          'Port must be 0 or 1.',
        );
      }
      if (!pairs.add('$from:$to')) {
        throw DomainException(
          'INVALID_GRAPH',
          path,
          'Duplicate directed endpoint pair.',
        );
      }
      edges.add(PuzzleEdge._(id, from, to, port));
    }
    for (final node in nodes) {
      final outgoing = edges.where((edge) => edge.fromId == node.id).toList();
      final incoming = edges.where((edge) => edge.toId == node.id).length;
      final ports = outgoing.map((edge) => edge.port).toSet();
      final valid = switch (node.kind) {
        NodeKind.source =>
          incoming == 0 && outgoing.length == 1 && ports.single == 0,
        NodeKind.relay =>
          outgoing.isEmpty || outgoing.length == 1 && ports.single == 0,
        NodeKind.switchNode =>
          outgoing.length == 2 &&
              ports.length == 2 &&
              ports.containsAll({0, 1}),
        NodeKind.target => outgoing.isEmpty,
      };
      if (!valid) {
        throw const DomainException(
          'INVALID_GRAPH',
          r'$.edges',
          'Node routing degree or port constraint violated.',
        );
      }
    }
    nodes.sort((a, b) => a.id.compareTo(b.id));
    edges.sort((a, b) => a.id.compareTo(b.id));
    return PuzzleSpec._(
      currentSchemaVersion,
      versions.engineVersion,
      versions.rulesVersion,
      limit,
      nodes,
      edges,
    );
  }

  Map<String, Object?> toJson() => Map.unmodifiable({
    'schema_version': schemaVersion,
    'engine_version': engineVersion,
    'rules_version': rulesVersion,
    'tick_limit': tickLimit,
    'nodes': List.unmodifiable(nodes.map((node) => node.toJson())),
    'edges': List.unmodifiable(edges.map((edge) => edge.toJson())),
  });
}

Map<String, Object?> _object(Object? value, String path) {
  if (value is! Map<String, Object?>) {
    throw DomainException('INVALID_VALUE', path, 'Expected a JSON object.');
  }
  return value;
}

void _fields(Map<String, Object?> value, Set<String> allowed, String path) {
  if (value.keys.any((key) => !allowed.contains(key))) {
    throw DomainException(
      'UNKNOWN_FIELD',
      path,
      'Unknown field is not permitted.',
    );
  }
  for (final key in allowed) {
    if (!value.containsKey(key)) {
      throw DomainException(
        'MISSING_FIELD',
        '$path.$key',
        'Required field missing.',
      );
    }
  }
}

void _version(Object? value, String expected, String path) {
  if (value != expected) {
    throw DomainException('UNSUPPORTED_VERSION', path, 'Unsupported version.');
  }
}

int _integer(Object? value, String path) {
  if (value is! int || value < 0 || value > 2147483647) {
    throw DomainException(
      'INVALID_INTEGER',
      path,
      'Expected a bounded unsigned integer.',
    );
  }
  return value;
}

String _id(Object? value, String path) {
  if (value is! String ||
      value.isEmpty ||
      value.length > 32 ||
      value.codeUnitAt(0) < 97 ||
      value.codeUnitAt(0) > 122 ||
      value.codeUnits.any(
        (c) => !(c >= 97 && c <= 122 || c >= 48 && c <= 57 || c == 95),
      )) {
    throw DomainException(
      'INVALID_ID',
      path,
      'Expected an ASCII identifier of length 1..32.',
    );
  }
  return value;
}

List<Object?> _list(Object? value, int minimum, int maximum, String path) {
  if (value is! List<Object?>) {
    throw DomainException('INVALID_VALUE', path, 'Expected a JSON array.');
  }
  if (value.length > maximum) {
    throw DomainException('LIMIT_EXCEEDED', path, 'Array exceeds item limit.');
  }
  if (value.length < minimum) {
    throw DomainException('INVALID_GRAPH', path, 'Array has too few items.');
  }
  return value;
}
