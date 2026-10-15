#!/usr/bin/env python3
"""Parse GIANTS Lua sources with standard Lua after neutralising GIANTS-only syntax."""

from __future__ import annotations

import argparse
import re
import subprocess
import tempfile
from pathlib import Path


GIANTS_CAST = re.compile(r"::[A-Za-z_][A-Za-z0-9_]*")
GIANTS_CONTINUE = re.compile(r"\bcontinue\b")


def standard_lua_source(contents: str) -> str:
    """Remove only GIANTS parser extensions so a standard Lua parser can check the rest."""
    return GIANTS_CAST.sub("", GIANTS_CONTINUE.sub("", contents))


def check(source_root: Path, luac: str) -> int:
    files = sorted(source_root.rglob("*.lua"))
    if not files:
        raise ValueError(f"no Lua files found under {source_root}")

    with tempfile.TemporaryDirectory() as directory:
        temporary_root = Path(directory)
        for source in files:
            relative = source.relative_to(source_root)
            temporary = temporary_root / relative
            temporary.parent.mkdir(parents=True, exist_ok=True)
            temporary.write_text(standard_lua_source(source.read_text(encoding="utf-8")), encoding="utf-8")
            result = subprocess.run((luac, "-p", str(temporary)), capture_output=True, text=True, check=False)
            if result.returncode:
                message = (result.stderr or result.stdout).replace(str(temporary), str(source))
                raise ValueError(f"Lua syntax check failed for {source}: {message.strip()}")
    return len(files)


def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--source-root", type=Path, default=Path("scripts"))
    parser.add_argument("--luac", default="luac5.4")
    args = parser.parse_args()
    print(f"parsed {check(args.source_root.resolve(), args.luac)} GIANTS Lua files")


if __name__ == "__main__":
    main()
