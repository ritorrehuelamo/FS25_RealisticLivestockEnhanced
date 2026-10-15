#!/usr/bin/env python3
"""Build and validate a distributable FS25 mod archive without mutating source."""

from __future__ import annotations

import argparse
import re
import xml.etree.ElementTree as ET
import zipfile
from pathlib import Path


RUNTIME_DIRECTORIES = (
    "animals",
    "fonts",
    "gui",
    "mod_support",
    "objects",
    "scripts",
    "translations",
    "xml",
)
ROOT_FILES = ("CHANGELOG.md", "LICENSE", "README.md", "icon_RealisticLivestock.dds", "modDesc.xml")
ARCHIVE_FILENAME = "FS25_RealisticLivestockEnhanced.zip"
PUBLIC_VERSION = re.compile(r"^(?P<major>0|[1-9]\d*)\.(?P<minor>0|[1-9]\d*)\.(?P<patch>0|[1-9]\d*)(?P<suffix>-rc\.(?P<rc>[1-9]\d*))?$")
ZIP_TIMESTAMP = (1980, 1, 1, 0, 0, 0)


def technical_version(public_version: str) -> str:
    """Map a SemVer release name to the four-part FS modDesc version."""
    match = PUBLIC_VERSION.fullmatch(public_version)
    if match is None:
        raise ValueError(f"invalid public version: {public_version!r}")

    return (
        f"{match.group('major')}.{match.group('minor')}.{match.group('patch')}.0"
        f"{match.group('suffix') or ''}"
    )


def validate_mod_desc(contents: bytes, expected_version: str | None = None) -> None:
    try:
        root = ET.fromstring(contents)
    except ET.ParseError as error:
        raise ValueError(f"modDesc.xml is not valid XML: {error}") from error

    if root.tag != "modDesc":
        raise ValueError("modDesc.xml root element must be <modDesc>")
    if not root.get("descVersion"):
        raise ValueError("modDesc.xml is missing its descVersion attribute")

    version = root.findtext("version")
    if not version or not version.strip():
        raise ValueError("modDesc.xml is missing <version>")
    if expected_version is not None and version.strip() != expected_version:
        raise ValueError(f"modDesc.xml version is {version.strip()!r}, expected {expected_version!r}")


def replace_mod_desc_version(contents: bytes, target_version: str) -> bytes:
    validate_mod_desc(contents)
    updated, replacements = re.subn(
        rb"(<version>)([^<]+)(</version>)",
        lambda match: match.group(1) + target_version.encode("utf-8") + match.group(3),
        contents,
        count=1,
    )
    if replacements != 1:
        raise ValueError("could not replace the single <version> in modDesc.xml")
    validate_mod_desc(updated, target_version)
    return updated


def runtime_files(source: Path) -> list[Path]:
    files: list[Path] = []
    for name in ROOT_FILES:
        path = source / name
        if not path.is_file():
            raise ValueError(f"required package file is missing: {name}")
        files.append(path)

    for directory in RUNTIME_DIRECTORIES:
        root = source / directory
        if not root.is_dir():
            raise ValueError(f"required package directory is missing: {directory}")
        files.extend(path for path in root.rglob("*") if path.is_file())

    return sorted(files, key=lambda path: path.relative_to(source).as_posix())


def write_archive(source: Path, destination: Path, public_version: str) -> None:
    game_version = technical_version(public_version)
    destination.parent.mkdir(parents=True, exist_ok=True)

    with zipfile.ZipFile(destination, "w", compression=zipfile.ZIP_DEFLATED, compresslevel=9) as archive:
        for path in runtime_files(source):
            arcname = path.relative_to(source).as_posix()
            contents = path.read_bytes()
            if arcname == "modDesc.xml":
                contents = replace_mod_desc_version(contents, game_version)

            info = zipfile.ZipInfo(arcname, date_time=ZIP_TIMESTAMP)
            info.compress_type = zipfile.ZIP_DEFLATED
            info.external_attr = 0o100644 << 16
            archive.writestr(info, contents, compress_type=zipfile.ZIP_DEFLATED, compresslevel=9)


def validate_archive(path: Path, public_version: str) -> None:
    expected_version = technical_version(public_version)
    with zipfile.ZipFile(path) as archive:
        invalid = [name for name in archive.namelist() if name.startswith("/") or ".." in Path(name).parts]
        if invalid:
            raise ValueError(f"archive contains unsafe paths: {invalid}")
        if "modDesc.xml" not in archive.namelist():
            raise ValueError("archive must contain modDesc.xml at its root")
        validate_mod_desc(archive.read("modDesc.xml"), expected_version)


def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--version", required=True, help="public version, e.g. 1.0.0 or 1.0.0-rc.1")
    parser.add_argument("--source", type=Path, default=Path(__file__).resolve().parents[1])
    parser.add_argument("--output-dir", type=Path, default=Path("dist"))
    args = parser.parse_args()

    source = args.source.resolve()
    output_dir = args.output_dir.resolve()
    archive = output_dir / ARCHIVE_FILENAME

    write_archive(source, archive, args.version)
    validate_archive(archive, args.version)
    print(archive)


if __name__ == "__main__":
    main()
