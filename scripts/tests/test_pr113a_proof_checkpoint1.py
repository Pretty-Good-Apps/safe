from __future__ import annotations

import sys
import unittest
from pathlib import Path
from unittest import mock


SCRIPTS_DIR = Path(__file__).resolve().parents[1]
if str(SCRIPTS_DIR) not in sys.path:
    sys.path.insert(0, str(SCRIPTS_DIR))

import run_pr113a_proof_checkpoint1


class Pr113aProofCheckpoint1Tests(unittest.TestCase):
    def test_corpus_lists_match_expected_checkpoint_surface(self) -> None:
        fixtures = [
            item["fixture"]
            for item in run_pr113a_proof_checkpoint1.sequential_proof_corpus()
        ]
        self.assertEqual(
            fixtures,
            [
                "tests/positive/pr112_character_case.safe",
                "tests/positive/pr112_discrete_case.safe",
                "tests/positive/pr112_string_param.safe",
                "tests/positive/pr112_case_scrutinee_once.safe",
                "tests/positive/pr113_discriminant_constraints.safe",
                "tests/positive/pr113_tuple_destructure.safe",
                "tests/positive/pr113_structured_result.safe",
                "tests/positive/pr113_variant_guard.safe",
                "tests/positive/constant_discriminant_default.safe",
                "tests/positive/result_equality_check.safe",
                "tests/positive/result_guarded_access.safe",
            ],
        )
        self.assertEqual(
            run_pr113a_proof_checkpoint1.excluded_positive_concurrency_paths(),
            ["tests/positive/pr113_tuple_channel.safe"],
        )

    def test_generate_report_includes_task_status_and_corpus_contract(self) -> None:
        fixture_names = [
            item["fixture"]
            for item in run_pr113a_proof_checkpoint1.sequential_proof_corpus()
        ]
        with mock.patch.object(
            run_pr113a_proof_checkpoint1,
            "require_safec",
            return_value=Path("/tmp/safec"),
        ), mock.patch.object(
            run_pr113a_proof_checkpoint1,
            "run_fixture",
            side_effect=[{"fixture": name} for name in fixture_names],
        ):
            report = run_pr113a_proof_checkpoint1.generate_report(env={})

        self.assertEqual(report["task"], "PR11.3a")
        self.assertEqual(report["status"], "ok")
        self.assertEqual(report["corpus_contract"]["fixtures"], fixture_names)
        self.assertEqual(
            report["corpus_contract"]["excluded_positive_concurrency"],
            ["tests/positive/pr113_tuple_channel.safe"],
        )
        self.assertEqual(len(report["fixtures"]), len(fixture_names))


if __name__ == "__main__":
    unittest.main()
