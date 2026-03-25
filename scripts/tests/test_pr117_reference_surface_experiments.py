from __future__ import annotations

import sys
import unittest
from pathlib import Path
from unittest import mock


SCRIPTS_DIR = Path(__file__).resolve().parents[1]
if str(SCRIPTS_DIR) not in sys.path:
    sys.path.insert(0, str(SCRIPTS_DIR))

import run_pr117_reference_surface_experiments


class Pr117ReferenceSurfaceExperimentsTests(unittest.TestCase):
    def test_surface_lists_cover_expected_files(self) -> None:
        self.assertEqual(
            {Path(path).name for path in run_pr117_reference_surface_experiments.technical_paths()},
            {
                "ownership_move.safe",
                "ownership_borrow.safe",
                "ownership_observe_access.safe",
                "ownership_return.safe",
                "rule4_deref.safe",
                "rule4_linked_list.safe",
            },
        )
        self.assertEqual(
            {Path(path).name for path in run_pr117_reference_surface_experiments.negative_paths()},
            {
                "neg_pr117_lowercase_access_binding.safe",
                "neg_pr117_uppercase_value_binding.safe",
                "neg_pr117_lowercase_access_field.safe",
                "neg_pr117_casefold_collision.safe",
                "neg_pr117_explicit_all.safe",
                "neg_pr117_uppercase_builtin_type.safe",
                "neg_pr117_uppercase_attribute.safe",
            },
        )

    def test_generate_report_records_separate_decisions(self) -> None:
        with mock.patch.object(
            run_pr117_reference_surface_experiments,
            "safec_path",
            return_value=Path("/tmp/safec"),
        ), mock.patch.object(
            run_pr117_reference_surface_experiments,
            "run_technical_case",
            side_effect=[
                {
                    "source": case["source"].name,
                    "migration_stable": True,
                    "cutover_surface": {"compile": {"returncode": 0}},
                }
                for case in run_pr117_reference_surface_experiments.technical_cases()
            ],
        ), mock.patch.object(
            run_pr117_reference_surface_experiments,
            "run_negative_case",
            side_effect=[{"source": case["source"].name} for case in run_pr117_reference_surface_experiments.negative_cases()],
        ), mock.patch.object(
            run_pr117_reference_surface_experiments,
            "run_migration_example",
            side_effect=[{"name": case["name"]} for case in run_pr117_reference_surface_experiments.migration_examples()],
        ), mock.patch.object(
            run_pr117_reference_surface_experiments,
            "run_readability_example",
            side_effect=[{"name": case["name"]} for case in run_pr117_reference_surface_experiments.readability_examples()],
        ):
            report = run_pr117_reference_surface_experiments.generate_report(env={})

        self.assertEqual(report["task"], "PR11.7")
        self.assertEqual(report["status"], "ok")
        self.assertTrue(report["scope"]["default_surface_changed"])
        self.assertFalse(report["scope"]["explicit_source_dereference_admitted"])
        self.assertEqual(report["decisions"]["reference_signal"]["decision"], "admit")
        self.assertEqual(report["decisions"]["implicit_dereference"]["decision"], "admit")
        self.assertEqual(
            len(report["technical_corpus"]["cases"]),
            len(run_pr117_reference_surface_experiments.technical_cases()),
        )
        self.assertEqual(
            len(report["negative_boundaries"]["cases"]),
            len(run_pr117_reference_surface_experiments.negative_cases()),
        )

    def test_negative_case_catalog_keeps_explicit_all_diagnostic(self) -> None:
        explicit_all = next(
            case
            for case in run_pr117_reference_surface_experiments.negative_cases()
            if Path(case["source"]).name == "neg_pr117_explicit_all.safe"
        )
        self.assertEqual(explicit_all["reason"], "source_frontend_error")
        self.assertEqual(
            explicit_all["message"],
            "removed source construct `explicit dereference `.all`` is not allowed",
        )


if __name__ == "__main__":
    unittest.main()
