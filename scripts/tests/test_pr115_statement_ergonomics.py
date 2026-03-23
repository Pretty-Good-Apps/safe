from __future__ import annotations

import sys
import unittest
from pathlib import Path
from unittest import mock


SCRIPTS_DIR = Path(__file__).resolve().parents[1]
if str(SCRIPTS_DIR) not in sys.path:
    sys.path.insert(0, str(SCRIPTS_DIR))

import run_pr115_statement_ergonomics


class Pr115StatementErgonomicsTests(unittest.TestCase):
    def test_fixture_lists_cover_expected_surface(self) -> None:
        positive_sources = {
            case["source"].name for case in run_pr115_statement_ergonomics.positive_cases()
        }
        negative_sources = {
            case["source"].name for case in run_pr115_statement_ergonomics.negative_cases()
        }
        rosetta_sources = {
            case["source"].name for case in run_pr115_statement_ergonomics.rosetta_readability_cases()
        }

        self.assertEqual(
            positive_sources,
            {
                "pr115_var_basic.safe",
                "pr115_compound_terminators.safe",
                "pr115_case_terminator.safe",
                "pr115_legacy_local_decl.safe",
                "pr115_declare_terminator.safe",
            },
        )
        self.assertEqual(
            negative_sources,
            {
                "neg_pr115_same_line_missing_semicolon.safe",
                "neg_pr115_var_package_item.safe",
                "neg_pr115_var_declare_item.safe",
                "neg_pr115_missing_declaration_semicolon.safe",
                "neg_pr115_missing_case_arm_semicolon.safe",
            },
        )
        self.assertEqual(
            rosetta_sources,
            {
                "factorial.safe",
                "binary_search.safe",
                "producer_consumer.safe",
            },
        )

    def test_generate_report_includes_task_status_and_policy(self) -> None:
        positive_side_effect = [
            {"source": case["source"].name}
            for case in run_pr115_statement_ergonomics.positive_cases()
        ] + [
            {"source": case["source"].name}
            for case in run_pr115_statement_ergonomics.rosetta_readability_cases()
        ]
        negative_side_effect = [
            {"source": case["source"].name}
            for case in run_pr115_statement_ergonomics.negative_cases()
        ]

        with mock.patch.object(
            run_pr115_statement_ergonomics,
            "safec_path",
            return_value=Path("/tmp/safec"),
        ), mock.patch.object(
            run_pr115_statement_ergonomics,
            "run_positive_case",
            side_effect=positive_side_effect,
        ), mock.patch.object(
            run_pr115_statement_ergonomics,
            "run_negative_case",
            side_effect=negative_side_effect,
        ):
            report = run_pr115_statement_ergonomics.generate_report(env={})

        self.assertEqual(report["task"], "PR11.5")
        self.assertEqual(report["status"], "ok")
        self.assertTrue(report["syntax_policy"]["optional_semicolons_parser_side"])
        self.assertFalse(report["syntax_policy"]["lexer_token_stream_changed"])
        self.assertTrue(report["syntax_policy"]["var_is_additive"])
        self.assertIn("scoped-binding receive", report["syntax_policy"]["deferred_to_pr118b"])
        self.assertEqual(
            len(report["positive_fixtures"]),
            len(run_pr115_statement_ergonomics.positive_cases()),
        )
        self.assertEqual(
            len(report["negative_boundaries"]),
            len(run_pr115_statement_ergonomics.negative_cases()),
        )
        self.assertEqual(
            len(report["rosetta_readability_samples"]),
            len(run_pr115_statement_ergonomics.rosetta_readability_cases()),
        )


if __name__ == "__main__":
    unittest.main()
