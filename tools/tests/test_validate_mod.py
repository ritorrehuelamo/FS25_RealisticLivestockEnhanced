from __future__ import annotations

import sys
import tempfile
import unittest
import xml.etree.ElementTree as ET
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parents[1]))
import validate_mod
import check_lua_syntax


class ValidateModTests(unittest.TestCase):
    def test_project_identity_metadata_is_not_inherited_from_upstream(self) -> None:
        root = Path(__file__).resolve().parents[2]
        document = ET.parse(root / "modDesc.xml")
        mod_desc = document.getroot()

        self.assertEqual(
            mod_desc.findtext("author"),
            "FS25 Realistic Livestock Enhanced contributors",
        )
        self.assertEqual(mod_desc.findtext("version"), "1.0.0.0")
        self.assertEqual(
            mod_desc.findtext("title/en"),
            "Realistic Livestock Enhanced",
        )
        self.assertEqual(
            mod_desc.findtext("iconFilename"),
            "icon_RealisticLivestock.dds",
        )

    def test_normalises_only_giants_lua_extensions(self) -> None:
        source = "if ready then continue end\nlocal value = (number)::number\n"
        self.assertEqual(check_lua_syntax.standard_lua_source(source), "if ready then  end\nlocal value = (number)\n")

    def write_minimal_mod(self, root: Path, main_source: str = 'source(modDirectory .. "scripts/example.lua")') -> None:
        (root / "scripts").mkdir()
        (root / "modDesc.xml").write_text(
            '<modDesc descVersion="114"><version>1.0.0.0</version><extraSourceFiles>'
            '<sourceFile filename="scripts/main.lua"/></extraSourceFiles></modDesc>',
            encoding="utf-8",
        )
        (root / "scripts" / "main.lua").write_text(main_source, encoding="utf-8")
        (root / "scripts" / "example.lua").write_text("Example = {}", encoding="utf-8")

    def test_validates_a_minimal_mod(self) -> None:
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory)
            self.write_minimal_mod(root)
            validate_mod.validate_mod_desc(root)
            self.assertEqual(validate_mod.validate_xml(root), 1)
            self.assertEqual(validate_mod.validate_main_sources(root), 1)

    def test_rejects_missing_loader_source(self) -> None:
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory)
            self.write_minimal_mod(root, 'source(modDirectory .. "scripts/missing.lua")')
            with self.assertRaisesRegex(ValueError, "missing source files"):
                validate_mod.validate_main_sources(root)

    def test_rejects_invalid_xml(self) -> None:
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory)
            self.write_minimal_mod(root)
            (root / "broken.xml").write_text("<broken>", encoding="utf-8")
            with self.assertRaisesRegex(ValueError, "invalid XML"):
                validate_mod.validate_xml(root)


if __name__ == "__main__":
    unittest.main()
