from __future__ import annotations

import sys
import unittest
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parents[1]))
import release_version


class ReleaseVersionTests(unittest.TestCase):
    def test_first_release_is_the_requested_baseline(self) -> None:
        self.assertEqual(release_version.next_version(None, "minor", (1, 0, 0)), (1, 0, 0))

    def test_minor_patch_and_major_bumps(self) -> None:
        self.assertEqual(release_version.next_version("v1.2.3", "minor", (1, 0, 0)), (1, 3, 0))
        self.assertEqual(release_version.next_version("v1.2.3", "patch", (1, 0, 0)), (1, 2, 4))
        self.assertEqual(release_version.next_version("v1.2.3", "major", (1, 0, 0)), (2, 0, 0))

    def test_conventional_commit_mapping(self) -> None:
        self.assertEqual(release_version.bump_for("feat(pedigree): add kinship graph", ""), "minor")
        self.assertEqual(release_version.bump_for("fix(build): exclude Git files", ""), "patch")
        self.assertEqual(release_version.bump_for("feat!: replace the save format", ""), "major")

    def test_non_release_conventional_title_is_valid_but_not_versioned(self) -> None:
        self.assertIsNotNone(release_version.TITLE.fullmatch("docs: clarify release process"))
        with self.assertRaisesRegex(ValueError, "release PR title"):
            release_version.bump_for("docs: clarify release process", "")

    def test_release_description_requires_reviewable_sections(self) -> None:
        self.assertTrue(release_version.release_description_is_valid("## Summary\n\nOne change.\n\n## Validation\n\nTests pass."))
        self.assertFalse(release_version.release_description_is_valid("## Summary\n\nOne change."))


if __name__ == "__main__":
    unittest.main()
