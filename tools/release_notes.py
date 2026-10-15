#!/usr/bin/env python3
"""Render release notes from reviewed PR metadata without executing its content."""

from __future__ import annotations

import argparse
import os
from pathlib import Path


def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--version", required=True)
    parser.add_argument("--stage", choices=("candidate", "final"), required=True)
    parser.add_argument("--pr-number", required=True)
    parser.add_argument("--pr-url", required=True)
    parser.add_argument("--title", default=os.environ.get("PR_TITLE", ""))
    parser.add_argument("--body", default=os.environ.get("PR_BODY", ""))
    parser.add_argument("--output", type=Path, required=True)
    args = parser.parse_args()

    label = "Release candidate" if args.stage == "candidate" else "Release"
    display_version = args.version if args.version.startswith("v") else f"v{args.version}"
    notes = (
        f"# {label} {display_version}\n\n"
        f"## Pull request\n\n"
        f"[{args.title}]({args.pr_url}) (#{args.pr_number})\n\n"
        f"## Description\n\n{args.body.strip()}\n\n"
        "## Build\n\n"
        "- Packaged from the reviewed pull-request metadata and the referenced Git commit.\n"
        "- The attached ZIP was structurally validated before publication.\n"
    )
    args.output.write_text(notes, encoding="utf-8")


if __name__ == "__main__":
    main()
