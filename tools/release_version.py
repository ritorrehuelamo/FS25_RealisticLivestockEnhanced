#!/usr/bin/env python3
"""Calculate a release version from a Conventional Commit PR title."""

from __future__ import annotations

import argparse
import os
import re
from pathlib import Path


VERSION = re.compile(r"^v(?P<major>0|[1-9]\d*)\.(?P<minor>0|[1-9]\d*)\.(?P<patch>0|[1-9]\d*)$")
TITLE = re.compile(r"^(?P<type>[a-z][a-z0-9-]*)(?:\([^)]+\))?(?P<breaking>!)?: .+")


def parse_version(tag: str) -> tuple[int, int, int] | None:
    match = VERSION.fullmatch(tag.strip())
    if match is None:
        return None
    return tuple(int(match.group(name)) for name in ("major", "minor", "patch"))


def bump_for(title: str, body: str) -> str:
    match = TITLE.fullmatch(title.strip())
    if match is None:
        raise ValueError("PR title must use Conventional Commit syntax, for example feat:, fix:, or docs:")
    if match.group("breaking") or re.search(r"^BREAKING CHANGE:", body, re.MULTILINE):
        return "major"
    if match.group("type") == "feat":
        return "minor"
    if match.group("type") == "fix":
        return "patch"
    raise ValueError("release PR title must use feat:, fix:, or a breaking Conventional Commit")


def next_version(latest_tag: str | None, bump: str, initial_version: tuple[int, int, int]) -> tuple[int, int, int]:
    if latest_tag is None:
        return initial_version
    current = parse_version(latest_tag)
    if current is None:
        raise ValueError(f"latest stable tag is not valid SemVer: {latest_tag!r}")
    major, minor, patch = current
    if bump == "major":
        return major + 1, 0, 0
    if bump == "minor":
        return major, minor + 1, 0
    return major, minor, patch + 1


def release_description_is_valid(body: str) -> bool:
    required = ("Summary", "Validation")
    for heading in required:
        match = re.search(
            rf"^## {heading}[ \t]*\r?$\n(?P<content>[\s\S]*?)(?=^## |\Z)",
            body,
            re.MULTILINE,
        )
        if match is None or not match.group("content").strip():
            return False
    return True


def manual_fs25_verification_is_valid(body: str) -> bool:
    section = re.search(
        r"^## Manual FS25 verification[ \t]*\r?$\n(?P<content>[\s\S]*?)(?=^## |\Z)",
        body,
        re.MULTILINE,
    )
    if section is None:
        return False

    # Release PRs define their own game-specific verification steps. Requiring
    # the wording of an old template made a fully checked, more thorough list
    # fail despite the manual work having been completed. Require a meaningful
    # checklist instead: at least three items, and no unchecked item.
    checks = re.findall(
        r"^[ \t]*[-*][ \t]+\[([ xX])\][ \t]+\S.*$",
        section.group("content"),
        re.MULTILINE,
    )
    return len(checks) >= 3 and all(state.lower() == "x" for state in checks)


def write_output(path: Path, values: dict[str, str]) -> None:
    with path.open("a", encoding="utf-8") as output:
        for key, value in values.items():
            output.write(f"{key}={value}\n")


def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--title", default=os.environ.get("PR_TITLE", ""))
    parser.add_argument("--body", default=os.environ.get("PR_BODY", ""))
    parser.add_argument("--latest-tag", default=os.environ.get("LATEST_STABLE_TAG") or None)
    parser.add_argument("--initial-version", default="1.0.0")
    parser.add_argument("--github-output", type=Path)
    parser.add_argument("--require-description", action="store_true")
    parser.add_argument("--require-manual-fs25-verification", action="store_true")
    parser.add_argument("--validate-title", action="store_true")
    args = parser.parse_args()

    initial = parse_version(f"v{args.initial_version}")
    if initial is None:
        raise ValueError("initial version must be major.minor.patch")
    if args.require_description and not release_description_is_valid(args.body):
        raise ValueError("release PR description must include non-empty ## Summary and ## Validation sections")
    if args.require_manual_fs25_verification and not manual_fs25_verification_is_valid(args.body):
        raise ValueError("release PR description must include checked Manual FS25 verification items")

    if args.validate_title:
        if TITLE.fullmatch(args.title.strip()) is None:
            raise ValueError("PR title must use Conventional Commit syntax, for example feat:, fix:, or docs:")
        return

    bump = bump_for(args.title, args.body)
    version = ".".join(str(part) for part in next_version(args.latest_tag, bump, initial))
    values = {"version": version, "bump": bump, "tag": f"v{version}"}
    if args.github_output:
        write_output(args.github_output, values)
    else:
        for key, value in values.items():
            print(f"{key}={value}")


if __name__ == "__main__":
    main()
