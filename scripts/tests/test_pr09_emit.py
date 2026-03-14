from __future__ import annotations

import sys
import tempfile
import unittest
from pathlib import Path


SCRIPTS_DIR = Path(__file__).resolve().parents[1]
if str(SCRIPTS_DIR) not in sys.path:
    sys.path.insert(0, str(SCRIPTS_DIR))

from _lib import pr09_emit


class Pr09EmitTests(unittest.TestCase):
    def test_project_text_includes_compiler_and_linker_on_darwin_with_gnat_adc(self) -> None:
        text = pr09_emit.emitted_ada_project_text(has_gnat_adc=True, platform_name="darwin")
        self.assertIn('Sdk_Root := External ("SDKROOT", "/Library/Developer/CommandLineTools/SDKs/MacOSX.sdk");', text)
        self.assertIn("package Compiler is", text)
        self.assertIn('for Default_Switches ("Ada") use ("-gnatec=gnat.adc");', text)
        self.assertIn("package Linker is", text)
        self.assertIn('for Default_Switches ("Ada") use ("-Wl,-syslibroot," & Sdk_Root);', text)

    def test_project_text_includes_only_linker_on_darwin_without_gnat_adc(self) -> None:
        text = pr09_emit.emitted_ada_project_text(has_gnat_adc=False, platform_name="darwin")
        self.assertIn('Sdk_Root := External ("SDKROOT", "/Library/Developer/CommandLineTools/SDKs/MacOSX.sdk");', text)
        self.assertNotIn("package Compiler is", text)
        self.assertIn("package Linker is", text)

    def test_project_text_omits_linker_on_non_darwin(self) -> None:
        text = pr09_emit.emitted_ada_project_text(has_gnat_adc=True, platform_name="linux")
        self.assertNotIn("Sdk_Root := External", text)
        self.assertIn("package Compiler is", text)
        self.assertNotIn("package Linker is", text)

    def test_write_project_reflects_gnat_adc_presence(self) -> None:
        with tempfile.TemporaryDirectory() as temp_dir:
            ada_dir = Path(temp_dir)
            (ada_dir / "gnat.adc").write_text("pragma Profile(Jorvik);\n", encoding="utf-8")
            gpr_path = pr09_emit.write_emitted_ada_project(ada_dir, platform_name="darwin")
            text = gpr_path.read_text(encoding="utf-8")
            self.assertIn("package Compiler is", text)
            self.assertIn("package Linker is", text)


if __name__ == "__main__":
    unittest.main()
