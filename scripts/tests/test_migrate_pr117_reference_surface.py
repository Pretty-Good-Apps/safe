from __future__ import annotations

import sys
import unittest
from pathlib import Path


SCRIPTS_DIR = Path(__file__).resolve().parents[1]
if str(SCRIPTS_DIR) not in sys.path:
    sys.path.insert(0, str(SCRIPTS_DIR))

import migrate_pr117_reference_surface
from _lib.pr117_surface import migration_examples


class MigratePr117ReferenceSurfaceTests(unittest.TestCase):
    def test_reference_signal_example_rewrites_bindings_and_fields(self) -> None:
        example = next(item for item in migration_examples() if item["name"] == "reference_signal_binding_and_field_case")
        rewritten = migrate_pr117_reference_surface.rewrite_safe_source(
            example["source"],
            mode=example["mode"],
        )
        for fragment in example["required_fragments"]:
            self.assertIn(fragment, rewritten)

    def test_combined_mode_rewrites_params_and_strips_all(self) -> None:
        example = next(item for item in migration_examples() if item["name"] == "combined_reference_signal_and_implicit_deref")
        rewritten = migrate_pr117_reference_surface.rewrite_safe_source(
            example["source"],
            mode=example["mode"],
        )
        self.assertIn("Head : node_ptr", rewritten)
        self.assertIn("Head.value", rewritten)
        self.assertIn("Head.Next.value", rewritten)
        self.assertNotIn(".all", rewritten)

    def test_implicit_deref_mode_rewrites_terminal_all(self) -> None:
        source = (
            "function Read (P : data_ptr) returns data\n"
            "   if P != null\n"
            "      return P.all;\n"
        )
        rewritten = migrate_pr117_reference_surface.rewrite_safe_source(
            source,
            mode="implicit-deref",
        )
        self.assertIn("return P;", rewritten)
        self.assertNotIn(".all", rewritten)

    def test_reference_signal_mode_renames_package_type_and_function(self) -> None:
        source = (
            "package Demo\n"
            "\n"
            "   type Payload is record\n"
            "      count : Integer;\n"
            "\n"
            "   function Build returns Payload\n"
            "      amount : Integer = 1;\n"
            "      return (count = amount) as Payload;\n"
        )
        rewritten = migrate_pr117_reference_surface.rewrite_safe_source(source, mode="reference-signal")
        self.assertIn("package demo", rewritten)
        self.assertIn("type payload is record", rewritten)
        self.assertIn("function build returns payload", rewritten)
        self.assertIn("count : integer;", rewritten)

    def test_conflicting_rewrites_are_rejected(self) -> None:
        source = (
            "package Demo\n"
            "\n"
            "   type Payload is record\n"
            "      value : Integer;\n"
            "\n"
            "   type Payload_Ptr is access Payload;\n"
            "\n"
            "   function Example\n"
            "      source : Payload_Ptr = null;\n"
            "      Source : Payload_Ptr = null;\n"
        )
        with self.assertRaises(migrate_pr117_reference_surface.ReferenceSurfaceMigrationError):
            migrate_pr117_reference_surface.rewrite_safe_source(source, mode="reference-signal")


if __name__ == "__main__":
    unittest.main()
