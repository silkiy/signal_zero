"""Phase 01 document/vector checks, not a game engine or production codec.

Run: python tools/specs/check_specs.py [--probe]
Expected tick rows are authored by hand. This checker verifies their invariants;
T011/T018 must later compare a real engine's outputs against the same vectors.
"""

from __future__ import annotations

import argparse
import hashlib
import json
from pathlib import Path
import platform
import time
import tracemalloc


ROOT = Path(__file__).resolve().parents[2]
VECTORS = ROOT / "specs" / "test-vectors"
VERSIONS = {
    "puzzle": "sz-puzzle-1", "replay": "sz-replay-1",
    "engine": "sz-engine-1", "rules": "sz-rules-1",
    "generator": "sz-generator-1", "encoding": "sz-cjson-1",
}


def _unique_object(pairs):
    obj = {}
    for key, value in pairs:
        if key in obj:
            raise ValueError(f"duplicate JSON key: {key}")
        obj[key] = value
    return obj


def _unsigned_integer(token):
    if token != "0" and (not token or token[0] == "0" or not token.isdigit()):
        raise ValueError("noncanonical unsigned integer token")
    if not token.isascii() or not token.isdigit():
        raise ValueError("noncanonical unsigned integer token")
    return int(token)


def _no_fraction(token):
    raise ValueError(f"fraction/exponent/nonfinite number prohibited: {token}")


def read_json(path):
    return json.loads(
        path.read_text(encoding="utf-8"), object_pairs_hook=_unique_object,
        parse_int=_unsigned_integer, parse_float=_no_fraction,
        parse_constant=_no_fraction,
    )


def canonical(value):
    """Serialize already-reviewed ASCII fixture objects; not input validation."""
    def check(item):
        if type(item) is int:
            assert 0 <= item <= 2147483647, "integer range"
        elif type(item) is str:
            assert item.isascii() and all(ord(c) >= 32 for c in item), "ASCII"
        elif type(item) is list:
            for child in item:
                check(child)
        elif type(item) is dict:
            for key, child in item.items():
                assert type(key) is str and key.isascii(), "ASCII keys"
                check(child)
        else:
            raise AssertionError(f"unsupported canonical type: {type(item)}")
    check(value)
    return json.dumps(value, sort_keys=True, separators=(",", ":"), ensure_ascii=False).encode("ascii")


def canonical_puzzle(puzzle):
    puzzle = dict(puzzle)
    for key in ("nodes", "edges"):
        puzzle[key] = sorted(puzzle[key], key=lambda item: item["id"])
    return canonical(puzzle)


def digest(data):
    return "0x" + hashlib.sha256(data).hexdigest()


def commitment(replay_bytes, salt_hex):
    salt = bytes.fromhex(salt_hex)
    assert len(salt) == 32
    return digest(b"SIGNAL_ZERO_REPLAY_V1\0" + salt + len(replay_bytes).to_bytes(4, "big") + replay_bytes)


def check_vectors():
    rules = read_json(VECTORS / "rules-cases.json")
    scores = read_json(VECTORS / "scoring-cases.json")
    invalid = read_json(VECTORS / "invalid-inputs.json")
    assert rules["rules_version"] == VERSIONS["rules"]
    cases = {case["id"]: case for case in rules["cases"]}
    assert len(cases) == len(rules["cases"]) >= 11
    snapshots = 0
    for case in cases.values():
        puzzle, trace = case["puzzle"], case["expected_snapshots"]
        assert puzzle["rules_version"] == VERSIONS["rules"]
        assert puzzle["engine_version"] == VERSIONS["engine"]
        assert trace[0]["tick"] == 0 and trace[0]["status"] == "RUNNING"
        switches = {n["id"]: n["initial_state"] for n in puzzle["nodes"] if n["kind"] == "switch"}
        sources = {n["id"] for n in puzzle["nodes"] if n["kind"] == "source"}
        targets = {n["id"] for n in puzzle["nodes"] if n["kind"] == "target"}
        assert len(sources) == len(targets)
        assert trace[0]["signals"] == {s: s for s in sources}
        assert trace[0]["switches"] == switches
        edge_by_id = {e["id"]: e for e in puzzle["edges"]}
        for previous, current in zip(trace, trace[1:]):
            assert previous["status"] == "RUNNING"
            assert current["tick"] == previous["tick"] + 1 <= puzzle["tick_limit"]
            if current["tick"] in case["shift_ticks"]:
                switches = {key: 1 - bit for key, bit in switches.items()}
            assert current["switches"] == switches
            assert set(current["signals"]) == sources
            for token, edge_id in current["used_edges"].items():
                edge = edge_by_id[edge_id]
                assert edge["from"] == previous["signals"][token]
                assert edge["to"] == current["signals"][token]
                expected_port = switches.get(edge["from"], 0)
                assert edge["port"] == expected_port
            for token in sources - set(current["used_edges"]):
                assert current["signals"][token] == previous["signals"][token]
            expected_arrivals = {}
            for token, eid in current["used_edges"].items():
                destination = edge_by_id[eid]["to"]
                if destination in targets:
                    expected_arrivals.setdefault(destination, []).append(token)
            expected_arrivals = {target: sorted(tokens) for target, tokens in expected_arrivals.items()}
            assert current["target_arrivals"] == expected_arrivals
        assert trace[-1]["status"] in ("SUCCEEDED", "FAILED")
        assert case["expected_terminal_reason"] == trace[-1]["reason"]
        if trace[-1]["status"] == "SUCCEEDED":
            assert set(trace[-1]["target_arrivals"]) == targets
        snapshots += len(trace)
    identity = scores["identity_vector"]
    puzzle_bytes = canonical_puzzle(cases[identity["rules_case"]]["puzzle"])
    assert puzzle_bytes.decode("ascii") == identity["canonical_puzzle"]
    assert digest(puzzle_bytes) == identity["puzzle_hash"]
    for label, expected in scores["version_hashes"].items():
        assert digest(label.encode("ascii")) == expected
    replay_bytes = canonical(identity["normalized_replay"])
    assert replay_bytes.decode("ascii") == identity["canonical_replay"]
    assert digest(replay_bytes) == identity["private_replay_digest"]
    assert commitment(replay_bytes, identity["salt_hex"]) == identity["replay_commitment"]
    for case in scores["normalization_cases"]:
        ticks = case["submitted_shift_ticks"]
        assert ticks == sorted(set(ticks))
        assert all(1 <= tick <= case["tick_limit"] for tick in ticks)
        final = [tick for tick in ticks if tick <= case["completion_tick"]]
        assert final == case["normalized_shift_ticks"]
        assert [len(final), case["completion_tick"], len(final)] == case["score"]
    for case in scores["comparison_cases"]:
        left, right = tuple(case["left"]), tuple(case["right"])
        actual = "LESS" if left < right else ("GREATER" if left > right else "EQUAL")
        assert actual == case["expected_comparison"]
    for case in scores["attempt_boundaries"]:
        assert (case["successful_attempt"] >= 10) == (case["never_give_up"] == "UNLOCKED")
    assert invalid["limits_version"] == "sz-limits-1"
    for limit in invalid["numeric_boundaries"]:
        maximum = limit["maximum"]
        assert [row["value"] for row in limit["cases"]] == [maximum - 1, maximum, maximum + 1]
        assert [row["expected"] for row in limit["cases"]] == ["WITHIN_LIMIT", "WITHIN_LIMIT", "LIMIT_EXCEEDED"]
    assert len(invalid["rejection_cases"]) >= 16
    print(json.dumps({"result": "PASS", "rules_cases": len(cases), "manual_snapshots_checked": snapshots,
                      "normalization_cases": len(scores["normalization_cases"]),
                      "comparison_cases": len(scores["comparison_cases"]),
                      "resource_boundaries": len(invalid["numeric_boundaries"]),
                      "rejection_case_descriptors": len(invalid["rejection_cases"]),
                      "scope": "fixture consistency/identity arithmetic; no production engine/solver"}, indent=2))


def probe_limits():
    """Bounded synthetic size/parse/key-set probe. No gameplay/search claims."""
    nodes = []
    edges = []
    ids = ["n" + str(i).zfill(31) for i in range(64)]
    for i, node_id in enumerate(ids):
        kind = "source" if i < 8 else "target" if i >= 56 else "switch" if i < 40 else "relay"
        node = {"id": node_id, "kind": kind}
        if kind == "switch":
            node["initial_state"] = i % 2
        nodes.append(node)
        for port in range(2 if kind == "switch" else 0 if kind == "target" else 1):
            edges.append({"id": "e" + str(len(edges)).zfill(31), "from": node_id,
                          "to": ids[8 + ((i + port + 1) % 56)], "port": port})
    specimen = {"schema_version": VERSIONS["puzzle"], "engine_version": VERSIONS["engine"],
                "rules_version": VERSIONS["rules"], "tick_limit": 64, "nodes": nodes, "edges": edges}
    encoded = canonical_puzzle(specimen)
    repetitions = 100
    start = time.perf_counter()
    for _ in range(repetitions):
        json.loads(encoded)
        hashlib.sha256(encoded).digest()
    parse_hash_ms = (time.perf_counter() - start) * 1000
    tracemalloc.start()
    start = time.perf_counter()
    synthetic_keys = {hashlib.sha256(i.to_bytes(4, "big")).digest() for i in range(25000)}
    key_ms = (time.perf_counter() - start) * 1000
    _, peak = tracemalloc.get_traced_memory()
    tracemalloc.stop()
    assert len(synthetic_keys) == 25000 and len(encoded) < 65536
    assert peak < 32 * 1024 * 1024
    report = {"python": platform.python_version(), "platform": platform.platform(),
              "node_count": len(nodes), "edge_count": len(edges), "puzzle_bytes": len(encoded),
              "parse_hash_repetitions": repetitions, "parse_hash_total_ms": round(parse_hash_ms, 3),
              "synthetic_32byte_key_count": len(synthetic_keys), "key_set_ms": round(key_ms, 3),
              "python_traced_peak_bytes": peak,
              "limitations": "Desktop synthetic JSON/hash/key-set only; excludes solver, real states, mobile, Dart/web, process RSS"}
    print(json.dumps(report, indent=2))


if __name__ == "__main__":
    parser = argparse.ArgumentParser()
    parser.add_argument("--probe", action="store_true")
    arguments = parser.parse_args()
    probe_limits() if arguments.probe else check_vectors()
