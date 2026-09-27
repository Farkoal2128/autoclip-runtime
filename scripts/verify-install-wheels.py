"""Verify every wheel ZIP and RECORD before a source-build runtime install."""

import argparse
import base64
import csv
import hashlib
import io
import zipfile
from pathlib import Path


def verify_wheel(path: Path) -> int:
    with zipfile.ZipFile(path) as wheel:
        if wheel.testzip() is not None:
            raise ValueError(f"Wheel ZIP CRC failed: {path}")
        members = [item.filename for item in wheel.infolist() if not item.is_dir()]
        names = set(members)
        if len(names) != len(members):
            raise ValueError(f"Wheel ZIP has duplicate members: {path}")
        records = [name for name in names if name.endswith(".dist-info/RECORD")]
        if len(records) != 1:
            raise ValueError(f"Wheel RECORD missing or duplicated: {path}")
        rows = list(csv.reader(io.StringIO(wheel.read(records[0]).decode("utf-8"))))
        if {row[0] for row in rows} != names or len(rows) != len(names):
            raise ValueError(f"Wheel RECORD paths disagree with ZIP: {path}")
        for name, expected_hash, expected_size in rows:
            data = wheel.read(name)
            if expected_size and len(data) != int(expected_size):
                raise ValueError(f"Wheel RECORD size mismatch: {path} {name}")
            if expected_hash:
                digest = base64.urlsafe_b64encode(hashlib.sha256(data).digest()).rstrip(b"=").decode("ascii")
                if expected_hash != "sha256=" + digest:
                    raise ValueError(f"Wheel RECORD hash mismatch: {path} {name}")
        return len(rows)


def verify_directories(directories: list[Path], expected_count: int) -> tuple[int, int]:
    wheels = [wheel for directory in directories for wheel in directory.glob("*.whl")]
    if len(wheels) != expected_count or len({wheel.name.lower() for wheel in wheels}) != len(wheels):
        raise ValueError(f"Expected {expected_count} unique wheel filenames, found {len(wheels)}")
    return len(wheels), sum(verify_wheel(wheel) for wheel in wheels)


if __name__ == "__main__":
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("wheelhouse", type=Path)
    parser.add_argument("external_wheels", type=Path)
    parser.add_argument("--count", type=int, default=79)
    args = parser.parse_args()
    count, rows = verify_directories([args.wheelhouse, args.external_wheels], args.count)
    print(f"Verified {count} wheel ZIPs and {rows} RECORD rows")
