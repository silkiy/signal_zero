"""Contract checks for Phase 01 fixture tooling; no production engine tests."""

import copy
import json
import unittest

import check_specs as spec


class Phase01ContractTests(unittest.TestCase):
    def test_puzzle_key_and_node_order_do_not_change_frozen_hash(self):
        vectors = spec.read_json(spec.VECTORS / "rules-cases.json")
        score_vectors = spec.read_json(spec.VECTORS / "scoring-cases.json")
        vector = score_vectors["identity_vector"]
        original = next(case["puzzle"] for case in vectors["cases"] if case["id"] == vector["rules_case"])
        shuffled = dict(reversed(list(copy.deepcopy(original).items())))
        shuffled["nodes"].reverse()
        shuffled["edges"].reverse()
        self.assertEqual(spec.digest(spec.canonical_puzzle(shuffled)), vector["puzzle_hash"])

    def test_every_commitment_preimage_component_is_bound(self):
        vector = spec.read_json(spec.VECTORS / "scoring-cases.json")["identity_vector"]
        replay = spec.canonical(vector["normalized_replay"])
        salt = vector["salt_hex"]
        self.assertEqual(spec.commitment(replay, salt), vector["replay_commitment"])
        self.assertNotEqual(spec.commitment(replay + b" ", salt), vector["replay_commitment"])
        changed_salt = "ff" + salt[2:]
        self.assertNotEqual(spec.commitment(replay, changed_salt), vector["replay_commitment"])

    def test_duplicate_keys_are_not_silently_replaced(self):
        with self.assertRaisesRegex(ValueError, "duplicate JSON key"):
            json.loads('{"tick_limit":1,"tick_limit":2}', object_pairs_hook=spec._unique_object)

    def test_integer_token_contract_rejects_negative_zero_fraction_and_exponents(self):
        for raw in ("-0", "-1", "1.0", "1e1", "NaN", "Infinity"):
            with self.subTest(raw=raw), self.assertRaises(ValueError):
                json.loads(raw, parse_int=spec._unsigned_integer, parse_float=spec._no_fraction,
                           parse_constant=spec._no_fraction)

    def test_boolean_float_and_non_ascii_are_not_gameplay_integer_string_values(self):
        for value in (True, 1.0, "node_é"):
            with self.subTest(value=value), self.assertRaises(AssertionError):
                spec.canonical({"value": value})

    def test_target_collision_oracle_preserves_both_arrivals(self):
        rules = spec.read_json(spec.VECTORS / "rules-cases.json")
        case = next(case for case in rules["cases"] if case["id"] == "target_node_collision")
        terminal = case["expected_snapshots"][-1]
        self.assertEqual(terminal["target_arrivals"], {"x": ["a", "b"]})
        self.assertEqual(terminal["reason"], "NODE_COLLISION")


if __name__ == "__main__":
    unittest.main()
