#!/usr/bin/env python3
"""Validate mod metadata, XML resources, and Lua files sourced by the mod loader."""

from __future__ import annotations

import argparse
import re
import xml.etree.ElementTree as ET
from pathlib import Path


SOURCE_CALL = re.compile(r'source\(modDirectory \.. "(?P<path>[^"]+)"\)')


def xml_files(root: Path) -> list[Path]:
    return sorted(path for path in root.rglob("*.xml") if ".git" not in path.parts)


def validate_xml(root: Path) -> int:
    count = 0
    for path in xml_files(root):
        try:
            ET.parse(path)
        except ET.ParseError as error:
            raise ValueError(f"invalid XML in {path.relative_to(root)}: {error}") from error
        count += 1
    return count


def validate_mod_desc(root: Path) -> None:
    path = root / "modDesc.xml"
    document = ET.parse(path)
    mod_desc = document.getroot()
    if mod_desc.tag != "modDesc" or not mod_desc.get("descVersion"):
        raise ValueError("modDesc.xml must contain <modDesc descVersion=...>")
    if not (mod_desc.findtext("version") or "").strip():
        raise ValueError("modDesc.xml must contain a non-empty <version>")

    for source_file in mod_desc.findall("./extraSourceFiles/sourceFile"):
        filename = source_file.get("filename")
        if not filename or not (root / filename).is_file():
            raise ValueError(f"modDesc.xml references a missing source file: {filename!r}")


def validate_main_sources(root: Path) -> int:
    main = root / "scripts" / "main.lua"
    if not main.is_file():
        raise ValueError("scripts/main.lua is missing")

    sources = SOURCE_CALL.findall(main.read_text(encoding="utf-8"))
    if not sources:
        raise ValueError("scripts/main.lua contains no statically declared source() files")
    missing = [source for source in sources if not (root / source).is_file()]
    if missing:
        raise ValueError(f"scripts/main.lua references missing source files: {', '.join(missing)}")
    return len(sources)


def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--source", type=Path, default=Path(__file__).resolve().parents[1])
    args = parser.parse_args()

    root = args.source.resolve()
    validate_mod_desc(root)
    xml_count = validate_xml(root)
    source_count = validate_main_sources(root)
    print(f"validated mod metadata, {xml_count} XML files, and {source_count} Lua loader entries")


if __name__ == "__main__":
    main()
