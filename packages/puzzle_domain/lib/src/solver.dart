import 'dart:convert';
import 'dart:typed_data';

import 'engine_state.dart';
import 'puzzle_spec.dart';
import 'replay_spec.dart';
import 'score.dart';
import 'tick_engine.dart';

import 'solver_result.dart';

/// A cumulative budget may be reused sequentially across solver attempts.
/// State/transition/time counters never reset. Arena reservations are released
/// on completion, interruption, and errors. Concurrent reuse is rejected.
final class SolverWorkBudget {
  SolverWorkBudget({
    this.maxStates = 25000,
    this.maxTransitions = 50000,
    this.maxBytes = 33554432,
    this.timeLimit = const Duration(milliseconds: 500),
    int Function()? clockMicros,
    bool Function()? isCancelled,
  }) : _clockMicros = clockMicros ?? _newClock(),
       _isCancelled = isCancelled ?? (() => false) {
    if (maxStates < 0 ||
        maxStates > 25000 ||
        maxTransitions < 0 ||
        maxTransitions > 50000 ||
        maxBytes < 0 ||
        maxBytes > 33554432 ||
        timeLimit.isNegative ||
        timeLimit > const Duration(seconds: 5)) {
      throw ArgumentError('Budget exceeds the fixed solver resource limits.');
    }
  }

  SolverWorkBudget.offline({
    int maxStates = 25000,
    int maxTransitions = 50000,
    int maxBytes = 33554432,
    Duration timeLimit = const Duration(seconds: 5),
    int Function()? clockMicros,
    bool Function()? isCancelled,
  }) : this(
         maxStates: maxStates,
         maxTransitions: maxTransitions,
         maxBytes: maxBytes,
         timeLimit: timeLimit,
         clockMicros: clockMicros,
         isCancelled: isCancelled,
       );

  final int maxStates;
  final int maxTransitions;
  final int maxBytes;
  final Duration timeLimit;
  final int Function() _clockMicros;
  final bool Function() _isCancelled;
  int? _startedAt;
  bool _active = false;
  int _states = 0;
  int _transitions = 0;
  int _activeBytes = 0;
  int _peakBytes = 0;
  int get statesRetained => _states;
  int get transitionsEvaluated => _transitions;
  int get activeAccountedBytes => _activeBytes;
  int get accountedBytes => _peakBytes;
  int get elapsedMicros => _startedAt == null
      ? 0
      : (_clockMicros() - _startedAt!).clamp(0, 2147483647);

  void _begin() {
    if (_active) {
      throw StateError('A solver budget cannot be used concurrently.');
    }
    _active = true;
    _startedAt ??= _clockMicros();
  }

  void _check() {
    if (_isCancelled()) throw const _Stop('cancelled');
    if (elapsedMicros >= timeLimit.inMicroseconds) {
      throw const _Stop('deadline');
    }
  }

  void _reserve(int bytes) {
    _check();
    if (bytes > maxBytes - _activeBytes) throw const _Stop('memoryLimit');
    _activeBytes += bytes;
    if (_activeBytes > _peakBytes) _peakBytes = _activeBytes;
  }

  void _retain() {
    _check();
    if (_states >= maxStates) throw const _Stop('stateLimit');
    _states++;
  }

  void _transition() {
    _check();
    if (_transitions >= maxTransitions) throw const _Stop('transitionLimit');
    _transitions++;
  }

  void _end() {
    _activeBytes = 0;
    _active = false;
  }
}

int Function() _newClock() {
  final watch = Stopwatch()..start();
  return () => watch.elapsedMicroseconds;
}

final class _Stop implements Exception {
  const _Stop(this.reason);
  final String reason;
}

/// Dijkstra search ordered by (SHIFT count, tick). All programs have
/// programming_actions == SHIFT count, so this proves the full score tuple.
/// No renderer, wall clock, or random input influences a state transition.
final class PuzzleSolver {
  PuzzleSolver(this.puzzle);
  final PuzzleSpec puzzle;

  SolverResult solve({SolverWorkBudget? budget}) {
    final work = budget ?? SolverWorkBudget();
    work._begin();
    _Search? search;
    try {
      search = _Search(puzzle, work);
      while (!search.advance()) {}
      return search.result();
    } on _Stop catch (stop) {
      return _result(puzzle, work, stop.reason, search);
    } finally {
      work._end();
    }
  }

  /// Performs at most 16 actual engine transitions between event-loop yields,
  /// including candidate replay verification. Cancellation can run between them.
  Future<SolverResult> solveAsync({SolverWorkBudget? budget}) async {
    final work = budget ?? SolverWorkBudget();
    work._begin();
    _Search? search;
    try {
      await Future<void>.delayed(Duration.zero);
      search = _Search(puzzle, work);
      var chunk = 0;
      final slice = Stopwatch()..start();
      while (!search.advance()) {
        if (++chunk == 16 || slice.elapsedMicroseconds >= 2000) {
          chunk = 0;
          await Future<void>.delayed(Duration.zero);
          slice.reset();
        }
      }
      return search.result();
    } on _Stop catch (stop) {
      return _result(puzzle, work, stop.reason, search);
    } finally {
      work._end();
    }
  }
}

SolverResult _result(
  PuzzleSpec puzzle,
  SolverWorkBudget work,
  String? stop,
  _Search? search,
) => SolverResult(
  status: stop == 'cancelled'
      ? SolverStatus.cancelled
      : stop != null
      ? SolverStatus.budgetExhausted
      : search!._bestReplay != null
      ? SolverStatus.solvedOptimal
      : SolverStatus.unsatisfiable,
  reason: stop,
  replay: search?._bestReplay,
  score: search?._bestScore,
  puzzleHash: puzzle.puzzleHash,
  engineVersion: puzzle.engineVersion,
  rulesVersion: puzzle.rulesVersion,
  statesRetained: work.statesRetained,
  transitionsEvaluated: work.transitionsEvaluated,
  accountedBytes: work.accountedBytes,
  elapsedMicros: work.elapsedMicros,
);

final class _Search {
  _Search(this.puzzle, this.work) : engine = TickEngine(puzzle) {
    work._check();
    final capacity = work.maxStates - work.statesRetained;
    if (capacity == 0) throw const _Stop('stateLimit');
    sources =
        puzzle.nodes
            .where((n) => n.kind == NodeKind.source)
            .map((n) => n.id)
            .toList()
          ..sort();
    nodeIds = puzzle.nodes.map((n) => n.id).toList()..sort();
    nodeIndex = {for (var i = 0; i < nodeIds.length; i++) nodeIds[i]: i};
    initialSwitches = EngineState.initial(puzzle).switches;
    hasSwitches = initialSwitches.isNotEmpty;
    // Exact typed-buffer bytes plus a conservative 2 MiB allowance for the
    // bounded graph, engine transient maps, replay, and result. Not VM RSS.
    final tableSize = _tableSize(capacity);
    work._reserve(2097152 + capacity * (17 + sources.length) + tableSize * 4);
    arena = _Arena(capacity, sources.length, tableSize);
    final state = EngineState.initial(puzzle);
    _insert(state, 0, 0, -1, false);
  }

  final PuzzleSpec puzzle;
  final SolverWorkBudget work;
  final TickEngine engine;
  late final List<String> sources;
  late final List<String> nodeIds;
  late final Map<String, int> nodeIndex;
  late final Map<String, int> initialSwitches;
  late final bool hasSwitches;
  late final _Arena arena;
  EngineState? _active;
  int _activeIndex = -1;
  int _nextAction = 0;
  ReplaySpec? _candidate;
  EngineState? _verification;
  EngineState? _expected;
  ReplaySpec? _bestReplay;
  Score? _bestScore;

  SolverResult result() => _result(puzzle, work, null, this);

  // Each call does at most one transition, even while verifying a candidate.
  bool advance() {
    work._check();
    if (_candidate != null) {
      final current = _verification!;
      work._transition();
      final state = engine.step(
        current,
        shift: _candidate!.shiftTicks.contains(current.tick + 1),
      );
      _verification = state;
      if (state.isTerminal) {
        if (state.status != RunStatus.succeeded ||
            jsonEncode(state.toJson()) != jsonEncode(_expected!.toJson())) {
          throw StateError(
            'Solver candidate failed engine replay verification.',
          );
        }
        final n = _candidate!.shiftTicks.length;
        final score = Score(n, state.tick, n);
        if (_bestScore == null || score.compareTo(_bestScore!) < 0) {
          _bestScore = score;
          _bestReplay = _candidate;
        }
        _candidate = null;
        _verification = null;
        _expected = null;
      }
      return false;
    }
    if (_active == null) {
      if (arena.heapLength == 0) return true;
      final first = arena.heap[0];
      final best = _bestScore;
      if (best != null &&
          (best.shiftCount < arena.cost[first] ||
              (best.shiftCount == arena.cost[first] &&
                  best.completionTicks <= arena.tick[first]))) {
        return true;
      }
      _activeIndex = arena.pop();
      _active = _restore(_activeIndex);
      _nextAction = 0;
    }
    final shift = _nextAction++ == 1;
    final parent = _activeIndex;
    final previous = _active!;
    if (_nextAction == (hasSwitches ? 2 : 1)) _active = null;
    work._transition();
    final state = engine.step(previous, shift: shift);
    if (state.status == RunStatus.failed) return false;
    final cost = arena.cost[parent] + (shift ? 1 : 0);
    if (state.status == RunStatus.succeeded) {
      final ticks = <int>{if (shift) state.tick};
      var current = parent;
      while (arena.parent[current] >= 0) {
        if (arena.shift[current] != 0) ticks.add(arena.tick[current]);
        current = arena.parent[current];
      }
      _candidate = ReplaySpec.fromProgram(puzzle, ticks);
      _verification = EngineState.initial(puzzle);
      _expected = state;
    } else {
      _insert(
        state,
        hasSwitches ? arena.parity[parent] ^ (shift ? 1 : 0) : 0,
        cost,
        parent,
        shift,
      );
    }
    return false;
  }

  EngineState _restore(int index) => EngineState(
    puzzleHash: puzzle.puzzleHash,
    tick: arena.tick[index],
    signals: {
      for (var s = 0; s < sources.length; s++)
        sources[s]: nodeIds[arena.positions[index * sources.length + s]],
    },
    switches: {
      for (final e in initialSwitches.entries)
        e.key: e.value ^ arena.parity[index],
    },
  );

  void _insert(
    EngineState state,
    int parity,
    int cost,
    int parent,
    bool shift,
  ) {
    final positions = [for (final s in sources) nodeIndex[state.signals[s]]!];
    final slot = arena.slot(state.tick, parity, positions);
    final known = arena.table[slot] - 1;
    if (known >= 0) {
      if (cost >= arena.cost[known]) return;
      if (arena.closed[known] != 0) {
        throw StateError('Dijkstra encountered a cheaper settled state.');
      }
      arena.cost[known] = cost;
      arena.parent[known] = parent;
      arena.shift[known] = shift ? 1 : 0;
      arena.up(arena.heapPosition[known]);
      return;
    }
    work._retain();
    final id = arena.length++;
    arena.tick[id] = state.tick;
    arena.parity[id] = parity;
    arena.cost[id] = cost;
    arena.parent[id] = parent;
    arena.shift[id] = shift ? 1 : 0;
    for (var s = 0; s < sources.length; s++) {
      arena.positions[id * sources.length + s] = positions[s];
    }
    arena.table[slot] = id + 1;
    arena.heap[arena.heapLength] = id;
    arena.heapPosition[id] = arena.heapLength++;
    arena.up(arena.heapLength - 1);
  }
}

int _tableSize(int capacity) {
  var size = 2;
  while (size < capacity * 2) {
    size *= 2;
  }
  return size;
}

/// Fixed-size arena, indexed min-heap, and open-addressed transposition table.
/// Parents of expanded states never change: improved tentative keys are fixed
/// before expansion, so descendants always reconstruct the original prefix.
final class _Arena {
  _Arena(int capacity, this.sources, int tableSize)
    : positions = Uint8List(capacity * sources),
      tick = Uint8List(capacity),
      parity = Uint8List(capacity),
      cost = Uint8List(capacity),
      parent = Int32List(capacity),
      shift = Uint8List(capacity),
      closed = Uint8List(capacity),
      heapPosition = Int32List(capacity),
      heap = Int32List(capacity),
      table = Int32List(tableSize);
  final int sources;
  final Uint8List positions, tick, parity, cost, shift, closed;
  final Int32List parent, heapPosition, heap, table;
  int length = 0;
  int heapLength = 0;

  int slot(int t, int p, List<int> nodes) {
    // Multiplication by 31 stays below 2^53 on the JS target.
    var hash = (t * 31 + p) & 0x7fffffff;
    for (final node in nodes) {
      hash = (hash * 31 + node) & 0x7fffffff;
    }
    var slot = hash & (table.length - 1);
    while (table[slot] != 0) {
      final id = table[slot] - 1;
      var same = tick[id] == t && parity[id] == p;
      for (var s = 0; same && s < sources; s++) {
        same = positions[id * sources + s] == nodes[s];
      }
      if (same) return slot;
      slot = (slot + 1) & (table.length - 1);
    }
    return slot;
  }

  bool _less(int a, int b) =>
      cost[a] < cost[b] ||
      (cost[a] == cost[b] &&
          (tick[a] < tick[b] || (tick[a] == tick[b] && a < b)));

  void _swap(int a, int b) {
    final saved = heap[a];
    heap[a] = heap[b];
    heap[b] = saved;
    heapPosition[heap[a]] = a;
    heapPosition[heap[b]] = b;
  }

  void up(int position) {
    while (position > 0) {
      final parentPosition = (position - 1) ~/ 2;
      if (!_less(heap[position], heap[parentPosition])) return;
      _swap(position, parentPosition);
      position = parentPosition;
    }
  }

  int pop() {
    final first = heap[0];
    heapLength--;
    if (heapLength != 0) {
      heap[0] = heap[heapLength];
      heapPosition[heap[0]] = 0;
      var position = 0;
      while (position * 2 + 1 < heapLength) {
        var child = position * 2 + 1;
        if (child + 1 < heapLength && _less(heap[child + 1], heap[child])) {
          child++;
        }
        if (!_less(heap[child], heap[position])) break;
        _swap(position, child);
        position = child;
      }
    }
    closed[first] = 1;
    heapPosition[first] = -1;
    return first;
  }
}
