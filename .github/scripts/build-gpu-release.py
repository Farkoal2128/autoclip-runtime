"""Build the next Windows release from the immutable V11 asset and pinned GPU wheels.

Usage: python .github/scripts/build-gpu-release.py BASE_ZIP GPU_WHEEL_DIR OUTPUT_ZIP
The output is a new asset; never replace the published base asset.
"""

from __future__ import annotations

import hashlib
import json
import shutil
import sys
import zipfile
from pathlib import Path

BASE_SHA256 = "082a2cd31720aada57daa93b819a20e7aa540a75ab5d28c430ac8479497cd71e"
WHEELS = {
    "nvidia_cublas_cu12-12.4.5.8-py3-none-win_amd64.whl": "5a796786da89203a0657eda402bcdcec6180254a8ac22d72213abc42069522dc",
    "nvidia_cudnn_cu12-9.10.2.21-py3-none-win_amd64.whl": "c6288de7d63e6cf62988f0923f96dc339cea362decb1bf5b3141883392a7d65e",
}
FIXED_DATE = (2026, 9, 26, 0, 0, 0)


def file_hash(path: Path) -> str:
    digest = hashlib.sha256()
    with path.open("rb") as stream:
        for block in iter(lambda: stream.read(4 * 1024 * 1024), b""):
            digest.update(block)
    return digest.hexdigest()


def record_bytes(name: str, data: bytes) -> dict[str, object]:
    return {"path": name, "bytes": len(data), "sha256": hashlib.sha256(data).hexdigest()}


def add_bytes(archive: zipfile.ZipFile, name: str, data: bytes) -> dict[str, object]:
    info = zipfile.ZipInfo(name, FIXED_DATE)
    info.compress_type = zipfile.ZIP_DEFLATED
    archive.writestr(info, data)
    return record_bytes(name, data)


def build(base: Path, wheel_dir: Path, output: Path) -> None:
    if output.exists():
        raise ValueError(f"Refusing to overwrite an existing asset: {output}")
    if file_hash(base) != BASE_SHA256:
        raise ValueError("The base release asset does not match its published hash")
    for filename, expected in WHEELS.items():
        if file_hash(wheel_dir / filename) != expected:
            raise ValueError(f"CUDA wheel hash mismatch: {filename}")

    records: list[dict[str, object]] = []
    cuda_inventory: list[dict[str, object]] = []
    with zipfile.ZipFile(base) as source, zipfile.ZipFile(output, "w", allowZip64=True) as target:
        old_manifest = json.loads(source.read("release-manifest.json"))
        old_records = {item["path"]: item for item in old_manifest["files"]}
        for item in source.infolist():
            if item.is_dir() or item.filename == "release-manifest.json":
                continue
            if item.filename not in old_records:
                raise ValueError(f"Base asset contains an unlisted file: {item.filename}")
            digest = hashlib.sha256()
            info = zipfile.ZipInfo(item.filename, item.date_time)
            info.compress_type = item.compress_type
            with source.open(item) as input_stream, target.open(info, "w") as output_stream:
                while block := input_stream.read(4 * 1024 * 1024):
                    output_stream.write(block)
                    digest.update(block)
            record = {"path": item.filename, "bytes": item.file_size, "sha256": digest.hexdigest()}
            if record != old_records[item.filename]:
                raise ValueError(f"Base member disagrees with its manifest: {item.filename}")
            records.append(record)

        for filename in WHEELS:
            wheel = wheel_dir / filename
            name = "wheelhouse/" + filename
            info = zipfile.ZipInfo(name, FIXED_DATE)
            info.compress_type = zipfile.ZIP_STORED  # Wheels already compress their payloads.
            with wheel.open("rb") as input_stream, target.open(info, "w") as output_stream:
                shutil.copyfileobj(input_stream, output_stream, 4 * 1024 * 1024)
            records.append({"path": name, "bytes": wheel.stat().st_size, "sha256": WHEELS[filename]})
            with zipfile.ZipFile(wheel) as nested:
                license_names = [n for n in nested.namelist() if "license" in n.lower() and n.endswith(".txt")]
                if not license_names:
                    raise ValueError(f"No license text found in {filename}")
                for license_name in license_names:
                    license_data = nested.read(license_name)
                    notice_path = f"notices-and-source/nvidia-runtime/{filename}/{Path(license_name).name}"
                    records.append(add_bytes(target, notice_path, license_data))
                dlls = []
                for member in nested.infolist():
                    if not member.filename.lower().endswith(".dll"):
                        continue
                    digest = hashlib.sha256()
                    with nested.open(member) as stream:
                        for block in iter(lambda: stream.read(4 * 1024 * 1024), b""):
                            digest.update(block)
                    dlls.append({"path": member.filename, "bytes": member.file_size, "sha256": digest.hexdigest()})
                cuda_inventory.append({"wheel": filename, "sha256": WHEELS[filename], "dlls": dlls, "licenses": license_names})

        inventory = (json.dumps({"nvidia_runtime": cuda_inventory}, indent=2) + "\n").encode()
        records.append(add_bytes(target, "notices-and-source/nvidia-runtime/inventory.json", inventory))
        manifest = (json.dumps({"files": sorted(records, key=lambda item: str(item["path"]))}, indent=2) + "\n").encode()
        add_bytes(target, "release-manifest.json", manifest)

    print(f"Archive: {output} ({output.stat().st_size} bytes) SHA-256 {file_hash(output)}")
    print(f"Manifest SHA-256: {hashlib.sha256(manifest).hexdigest()}")
    print(f"Files: {len(records)}; Python wheels: {sum(str(r['path']).endswith('.whl') for r in records)}")


if __name__ == "__main__":
    if len(sys.argv) != 4:
        raise SystemExit(__doc__)
    build(*(Path(argument) for argument in sys.argv[1:]))
