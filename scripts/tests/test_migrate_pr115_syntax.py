from __future__ import annotations

import sys
import unittest
from pathlib import Path


SCRIPTS_DIR = Path(__file__).resolve().parents[1]
if str(SCRIPTS_DIR) not in sys.path:
    sys.path.insert(0, str(SCRIPTS_DIR))

import migrate_pr115_syntax


class MigratePr115SyntaxTests(unittest.TestCase):
    def test_rewrite_safe_source_rewrites_statement_local_declaration(self) -> None:
        original = (
            "package Demo is\n"
            "   type Count is range 0 to 10;\n"
            "   function Build returns Count is\n"
            "   begin\n"
            "      Value : Count = 0;\n"
            "      return Value;\n"
            "   end Build;\n"
            "end Demo;\n"
        )
        rewritten = migrate_pr115_syntax.rewrite_safe_source(original)
        self.assertIn("      var Value : Count = 0;\n", rewritten)
        self.assertNotIn("      Value : Count = 0;\n", rewritten)

    def test_rewrite_safe_source_leaves_declarative_part_unchanged(self) -> None:
        original = (
            "package Demo is\n"
            "   type Count is range 0 to 10;\n"
            "   function Build returns Count is\n"
            "      Value : Count = 0;\n"
            "   begin\n"
            "      return Value;\n"
            "   end Build;\n"
            "end Demo;\n"
        )
        rewritten = migrate_pr115_syntax.rewrite_safe_source(original)
        self.assertEqual(rewritten, original)

    def test_rewrite_safe_source_leaves_package_object_declarations_unchanged(self) -> None:
        original = (
            "package Demo is\n"
            "   type Count is range 0 to 10;\n"
            "   Value : Count = 0;\n"
            "end Demo;\n"
        )
        rewritten = migrate_pr115_syntax.rewrite_safe_source(original)
        self.assertEqual(rewritten, original)

    def test_rewrite_safe_source_preserves_comments(self) -> None:
        original = (
            "package Demo is\n"
            "   type Count is range 0 to 10;\n"
            "   function Build returns Count is\n"
            "   begin\n"
            "      Value : Count = 0; -- migrate me\n"
            "      return Value;\n"
            "   end Build;\n"
            "end Demo;\n"
        )
        rewritten = migrate_pr115_syntax.rewrite_safe_source(original)
        self.assertIn("      var Value : Count = 0; -- migrate me\n", rewritten)

    def test_rewrite_safe_source_leaves_declare_declarative_items_unchanged(self) -> None:
        original = (
            "package Demo is\n"
            "   type Count is range 0 to 10;\n"
            "   function Build returns Count is\n"
            "   begin\n"
            "      declare\n"
            "         Temp : Count = 0;\n"
            "      begin\n"
            "         Temp = 1;\n"
            "      end;\n"
            "      return 1;\n"
            "   end Build;\n"
            "end Demo;\n"
        )
        rewritten = migrate_pr115_syntax.rewrite_safe_source(original)
        self.assertIn("         Temp : Count = 0;\n", rewritten)
        self.assertNotIn("         var Temp : Count = 0;\n", rewritten)

    def test_rewrite_safe_source_resets_after_named_end(self) -> None:
        original = (
            "package Demo is\n"
            "   type Count is range 0 to 10;\n"
            "   function Build returns Count is\n"
            "   begin\n"
            "      Value : Count = 0;\n"
            "      return Value;\n"
            "   end Build;\n"
            "   After_Build : Count = 1;\n"
            "end Demo;\n"
        )
        rewritten = migrate_pr115_syntax.rewrite_safe_source(original)
        self.assertIn("      var Value : Count = 0;\n", rewritten)
        self.assertIn("   After_Build : Count = 1;\n", rewritten)
        self.assertNotIn("   var After_Build : Count = 1;\n", rewritten)


if __name__ == "__main__":
    unittest.main()
