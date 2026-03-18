from __future__ import annotations

import sys
import unittest
from pathlib import Path
from unittest import mock


SCRIPTS_DIR = Path(__file__).resolve().parents[1]
if str(SCRIPTS_DIR) not in sys.path:
    sys.path.insert(0, str(SCRIPTS_DIR))

import run_pr113_discriminated_types_tuples_structured_returns


class Pr113DiscriminatedTypesTuplesStructuredReturnsTests(unittest.TestCase):
    def test_fixture_lists_cover_expected_pr113_surface(self) -> None:
        positive_sources = {
            case["source"].name
            for case in run_pr113_discriminated_types_tuples_structured_returns.POSITIVE_CASES
        }
        negative_sources = {
            case["source"].name
            for case in run_pr113_discriminated_types_tuples_structured_returns.NEGATIVE_CASES
        }
        rosetta_sources = {
            source.name
            for source in run_pr113_discriminated_types_tuples_structured_returns.ROSETTA_SAMPLES
        }

        self.assertEqual(
            positive_sources,
            {
                "pr113_discriminant_constraints.safe",
                "pr113_variant_guard.safe",
                "pr113_tuple_destructure.safe",
                "pr113_tuple_channel.safe",
                "pr113_structured_result.safe",
            },
        )
        self.assertIn("neg_pr113_mixed_constraints.safe", negative_sources)
        self.assertIn("neg_pr113_tuple_field_oob.safe", negative_sources)
        self.assertIn("neg_pr113_variant_range_choice.safe", negative_sources)
        self.assertIn("neg_string_field.safe", negative_sources)
        self.assertEqual(
            rosetta_sources,
            {"parse_result.safe", "lookup_pair.safe", "lookup_result.safe"},
        )

    def test_generate_report_includes_task_status_and_case_lists(self) -> None:
        positive_side_effect = [
            {"source": case["source"].name}
            for case in run_pr113_discriminated_types_tuples_structured_returns.POSITIVE_CASES
        ] + [
            {"source": source.name}
            for source in run_pr113_discriminated_types_tuples_structured_returns.ROSETTA_SAMPLES
        ]
        negative_side_effect = [
            {"source": case["source"].name}
            for case in run_pr113_discriminated_types_tuples_structured_returns.NEGATIVE_CASES
        ]

        with mock.patch.object(
            run_pr113_discriminated_types_tuples_structured_returns,
            "safec_path",
            return_value=Path("/tmp/safec"),
        ), mock.patch.object(
            run_pr113_discriminated_types_tuples_structured_returns,
            "run_positive_case",
            side_effect=positive_side_effect,
        ), mock.patch.object(
            run_pr113_discriminated_types_tuples_structured_returns,
            "run_negative_case",
            side_effect=negative_side_effect,
        ):
            report = run_pr113_discriminated_types_tuples_structured_returns.generate_report(env={})

        self.assertEqual(report["task"], "PR11.3")
        self.assertEqual(report["status"], "ok")
        self.assertEqual(
            len(report["positive_fixtures"]),
            len(run_pr113_discriminated_types_tuples_structured_returns.POSITIVE_CASES),
        )
        self.assertEqual(
            len(report["negative_boundaries"]),
            len(run_pr113_discriminated_types_tuples_structured_returns.NEGATIVE_CASES),
        )
        self.assertEqual(
            len(report["rosetta_samples"]),
            len(run_pr113_discriminated_types_tuples_structured_returns.ROSETTA_SAMPLES),
        )


if __name__ == "__main__":
    unittest.main()
