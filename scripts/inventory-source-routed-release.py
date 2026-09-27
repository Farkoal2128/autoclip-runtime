"""Create an exact wheel/legal/native inventory for a source-routed candidate."""

import argparse
import base64
import csv
import hashlib
import io
import json
import re
import zipfile
from email.parser import Parser
from pathlib import Path


LEGAL = re.compile(r"(^|/)(license[^/]*|licence[^/]*|copying[^/]*|notice[^/]*|authors[^/]*|.*sbom.*|.*cyclonedx.*)$", re.I)
NATIVE = (".dll", ".pyd", ".so", ".dylib")


def sha256(path: Path) -> str:
    digest = hashlib.sha256()
    with path.open("rb") as stream:
        for block in iter(lambda: stream.read(1024 * 1024), b""):
            digest.update(block)
    return digest.hexdigest()


def format_paths(paths: list[str]) -> str:
    return "<br>".join(paths) if paths else "None by filename scan"


def inventory(root: Path, output: Path, archive_path: Path | None = None) -> None:
    manifest = json.loads((root / "release-manifest.json").read_text(encoding="utf-8"))
    wheels = [entry for entry in manifest["files"] if entry["path"].startswith("wheelhouse/") and entry["path"].endswith(".whl")]
    rows = []
    record_count = 0
    for entry in wheels:
        path = root / entry["path"]
        if path.stat().st_size != entry["bytes"] or sha256(path) != entry["sha256"]:
            raise ValueError(f"Manifest mismatch: {path}")
        with zipfile.ZipFile(path) as archive:
            if archive.testzip() is not None:
                raise ValueError(f"Wheel CRC failure: {path}")
            names = [item.filename for item in archive.infolist() if not item.is_dir()]
            record = next((name for name in names if name.endswith(".dist-info/RECORD")), None)
            if record is None:
                raise ValueError(f"Missing wheel RECORD: {path}")
            for name, recorded_hash, recorded_size in csv.reader(io.StringIO(archive.read(record).decode("utf-8"))):
                data = archive.read(name)
                if recorded_size and len(data) != int(recorded_size):
                    raise ValueError(f"RECORD size mismatch: {path} {name}")
                if recorded_hash:
                    algorithm, expected = recorded_hash.split("=", 1)
                    if algorithm != "sha256" or base64.urlsafe_b64encode(hashlib.sha256(data).digest()).rstrip(b"=").decode() != expected:
                        raise ValueError(f"RECORD hash mismatch: {path} {name}")
                record_count += 1
            metadata_name = next((name for name in names if name.endswith(".dist-info/METADATA")), None)
            license_text = "not identified"
            if metadata_name:
                metadata = Parser().parsestr(archive.read(metadata_name).decode("utf-8", errors="replace"))
                license_text = metadata.get("License-Expression") or metadata.get("License") or license_text
                license_text = license_text.replace("|", "/").replace("\n", " ").strip()
                if len(license_text) > 120:
                    license_text = license_text[:117] + "..."
            legal = sorted(name for name in names if LEGAL.search(name))
            native = sorted(name for name in names if name.lower().endswith(NATIVE))
            rows.append((path.name, entry["sha256"], license_text, format_paths(legal), format_paths(native)))
    archive_hash = sha256(archive_path) if archive_path else "see candidate handoff"
    source_build = bool(manifest.get("native_build"))
    lines = [
        "# CR-09 source-build candidate wheel inventory" if source_build else "# CR-09 source-routed candidate wheel inventory",
        "",
        ("Generated from the unpublished source-build candidate's exact packaged wheel bytes. "
         "This scan does not cover the two native wheels that recipients will build or the two NVIDIA wheels fetched from PyPI. "
         "It is a packaged-file scan, not a static-link or license clearance. All rows remain **unresolved** pending independent review."
         if source_build else
         "Generated from the unpublished source-routed candidate's exact wheel bytes. This is a packaged-file scan, not a static-link or license clearance. All rows remain **unresolved** pending independent component-to-obligation review. The two NVIDIA wheels are external publisher downloads listed in [the candidate handoff](cr09-source-routed-candidate.md); they are not in this ZIP."),
        "",
        f"Candidate ZIP: `{archive_hash}`. Manifest SHA-256: `{sha256(root / 'release-manifest.json')}`. {len(rows)} wheels passed ZIP CRC and {record_count:,} RECORD path/size/hash rows.",
        "",
        "| Wheel / version | SHA-256 | Metadata license | Bundled legal or SBOM paths | Native paths | Result |",
        "| --- | --- | --- | --- | --- | --- |",
    ]
    for name, wheel_hash, license_text, legal, native in rows:
        lines.append(f"| `{name}` | `{wheel_hash}` | {license_text} | {legal} | {native} | Unresolved |")
    output.write_text("\n".join(lines) + "\n", encoding="utf-8")
    print(f"{len(rows)} wheels; {record_count} RECORD rows; {output}")


if __name__ == "__main__":
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("root", type=Path)
    parser.add_argument("output", type=Path)
    parser.add_argument("--archive", type=Path)
    args = parser.parse_args()
    inventory(args.root, args.output, args.archive)
