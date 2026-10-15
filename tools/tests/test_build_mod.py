from __future__ import annotations

import sys
import unittest
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parents[1]))
import build_mod


class BuildModTests(unittest.TestCase):
    def test_release_archive_name_is_stable(self) -> None:
        self.assertEqual(build_mod.ARCHIVE_FILENAME, "FS25_RealisticLivestockEnhanced.zip")
        self.assertNotIn("1.0.0", build_mod.ARCHIVE_FILENAME)

    def test_mod_metadata_preserves_the_public_release_version(self) -> None:
        self.assertEqual(build_mod.mod_version("1.0.0"), "1.0.0")
        self.assertEqual(build_mod.mod_version("1.2.3-rc.4"), "1.2.3-rc.4")


if __name__ == "__main__":
    unittest.main()
