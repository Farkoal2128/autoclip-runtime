"""Package a new, unqualified controlled Windows CPU native artifact."""

import argparse
from contextlib import ExitStack
import hashlib
import importlib.util
import io
import json
import os
from pathlib import Path, PurePosixPath
import re
import stat
import sys
import tarfile
import tempfile
import zipfile


ROOT = Path(__file__).resolve().parents[1]
SOURCE_PINS = {
    "ffmpeg_source_sha256": "464beb5e7bf0c311e68b45ae2f04e9cc2af88851abb4082231742a74d97b524c",
    "pyav_source_sha256": "47bfc286e1bc9de7ab4681fc2b575cd2460a66919d31ffe1bd5aa54fae531a28",
    "onednn_commit": "64f6bcbcbab628e96f33a62c3e975f8535a7bde4",
    "ctranslate2_commit": "d44d2d069eb88c7b7804da864c10c201501cb4a9",
}
CPU_FLAGS = (
    "-DWITH_CUDA=OFF", "-DWITH_CUDNN=OFF", "-DWITH_MKL=OFF",
    "-DWITH_OPENBLAS=ON", "-DOPENMP_RUNTIME=COMP", "-DWITH_DNNL=ON",
    "-DWITH_RUY=OFF", "-DWITH_FLASH_ATTN=OFF",
)
BUILD_FILES = ("native-build-receipt.json", "ffmpeg-config.mak", "ffmpeg-config.log", "ffmpeg-config.h")
BINARY_SUFFIXES = {".dll", ".pyd", ".exe", ".msi", ".msix", ".lib", ".a", ".o", ".obj", ".so", ".dylib", ".whl", ".pyc", ".pyo", ".pdb"}
CACHE_PARTS = {".git", ".venv", "__pycache__", "node_modules", "build-wheel-cache", "vendor-cache", "upstream-cache"}
ARCHIVES = (".zip", ".tar", ".tar.gz", ".tgz", ".tar.xz", ".tar.bz2")


def load_script(name):
    spec = importlib.util.spec_from_file_location(name.replace("-", "_"), ROOT / "scripts" / (name + ".py"))
    module = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(module)
    return module


def verify_native(wheelhouse, config):
    load_script("verify-native-source-wheels").verify(wheelhouse, config)


def sha(data):
    return hashlib.sha256(data).hexdigest()


def safe_name(name, seen):
    path = PurePosixPath(name)
    parts = name.rstrip("/").split("/")
    if (not name or "\\" in name or path.is_absolute() or any(
            part in ("", ".", "..") or part.endswith((" ", "."))
            or re.search(r'[<>:"|?*\x00-\x1f]', part)
            or re.fullmatch(r"(?i)(CON|PRN|AUX|NUL|COM[1-9]|LPT[1-9])(?:\..*)?", part)
            for part in parts)):
        raise ValueError(f"Unsafe archive/input path: {name}")
    key = name.rstrip("/").casefold()
    if key in seen:
        raise ValueError(f"Duplicate/case-colliding path: {name}")
    seen.add(key)
    return path


def regular(path):
    for part in (path, *path.parents):
        info = part.lstat()
        if stat.S_ISLNK(info.st_mode) or getattr(info, "st_file_attributes", 0) & 0x400:
            raise ValueError(f"Reparse/symlink input: {part}")
    if not path.is_file():
        raise ValueError(f"Missing regular input: {path}")


def inspect_source(name, data, depth=0):
    path = PurePosixPath(name)
    if (any(part.casefold() in CACHE_PARTS for part in path.parts)
            or path.suffix.lower() in BINARY_SUFFIXES
            or data.startswith((b"MZ", b"\x7fELF", b"\xca\xfe\xba\xbe", b"\xcf\xfa\xed\xfe", b"\xfe\xed\xfa\xcf", b"!<arch>\n"))):
        raise ValueError(f"Excluded source/tool/binary payload: {name}")
    is_zip = zipfile.is_zipfile(io.BytesIO(data))
    is_tar = data[:2] == b"\x1f\x8b" or data.startswith((b"BZh", b"\xfd7zXZ\x00")) or data[257:262] == b"ustar"
    if not name.lower().endswith(ARCHIVES) and not is_zip and not is_tar:
        return
    if depth >= 3:
        raise ValueError("Source archive nesting exceeds three levels")
    seen = set()
    stream = io.BytesIO(data)
    if name.lower().endswith(".zip") or is_zip:
        with zipfile.ZipFile(stream) as archive:
            for member in archive.infolist():
                safe_name(member.filename, seen)
                if stat.S_ISLNK(member.external_attr >> 16):
                    raise ValueError("Source ZIP symlink")
                if not member.is_dir():
                    inspect_source(member.filename, archive.read(member), depth + 1)
    else:
        with tarfile.open(fileobj=stream, mode="r:*") as archive:
            for member in archive:
                safe_name(member.name, seen)
                if not member.isfile() and not member.isdir():
                    raise ValueError("Source TAR contains link or special file")
                if member.isfile():
                    inspect_source(member.name, archive.extractfile(member).read(), depth + 1)


def package(args):
    if os.name != "nt":
        raise ValueError("Packaging requires Windows input sharing locks")
    if not re.fullmatch(r"[a-z0-9][a-z0-9._-]{1,127}", args.runtime_id):
        raise ValueError("Unsafe immutable runtime identity")
    args.output = args.output.absolute()
    if args.output.exists():
        raise ValueError("Output already exists; select a new immutable output")
    for parent in (args.output.parent, *args.output.parents):
        if parent.exists() and (parent.is_symlink() or getattr(parent.lstat(), "st_file_attributes", 0) & 0x400):
            raise ValueError("Output parent is a reparse point")
    wheel_files = sorted(args.wheelhouse.glob("*.whl"))
    expected = {"av-18.1.0-cp311-abi3-win_amd64.whl", "ctranslate2-4.8.2-cp311-cp311-win_amd64.whl"}
    if {path.name for path in wheel_files} != expected or len(wheel_files) != 2:
        raise ValueError("Expected precisely the two CPython 3.11 Windows x64 controlled wheels")
    selected = {"wheels/" + path.name: path for path in wheel_files}
    selected.update({"build/" + name: args.build_root / name for name in BUILD_FILES})
    if not args.source_directory.is_dir():
        raise ValueError("Source directory missing")
    seen = set()
    for path in sorted(args.source_directory.rglob("*")):
        name = path.relative_to(args.source_directory).as_posix()
        safe_name(name, seen)
        if path.is_symlink() or getattr(path.lstat(), "st_file_attributes", 0) & 0x400:
            raise ValueError("Source directory contains reparse point")
        if path.is_file():
            selected["sources/" + name] = path
    guards = load_script("build-inno")
    with ExitStack() as locks:
        for path in selected.values():
            regular(path)
            locks.enter_context(guards.read_locked(path))
        data = {name: path.read_bytes() for name, path in selected.items()}
        receipt = json.loads(data["build/native-build-receipt.json"].decode("utf-8-sig"))
        if (receipt.get("profile") != "cpu" or receipt.get("install_nvidia_gpu") is not False
                or any(receipt.get(key) != value for key, value in SOURCE_PINS.items())):
            raise ValueError("Native receipt profile/source recipe differs")
        flags = receipt.get("cmake_arguments", [])
        if (not isinstance(flags, list) or not set(CPU_FLAGS).issubset(flags)
                or any(flag.startswith(required.split("=", 1)[0] + "=") and flag != required
                       for flag in flags for required in CPU_FLAGS)):
            raise ValueError("Native receipt CPU build flags differ")
        actual_wheels = [{"filename": path.name, "bytes": len(data["wheels/" + path.name]),
                          "sha256": sha(data["wheels/" + path.name])} for path in wheel_files]
        if sorted(receipt.get("wheels", []), key=lambda row: row["filename"]) != actual_wheels:
            raise ValueError("Native receipt wheel hashes/sizes differ from actual outputs")
        if receipt.get("ffmpeg_config_sha256") != sha(data["build/ffmpeg-config.mak"]):
            raise ValueError("Native receipt FFmpeg configuration hash differs")
        if not all(data["build/" + name] for name in BUILD_FILES):
            raise ValueError("Empty build evidence")
        header = data["build/ffmpeg-config.h"].decode("utf-8")
        log = data["build/ffmpeg-config.log"].decode("utf-8")
        for feature in ("GPL", "NONFREE", "LIBX264", "LIBX265"):
            if re.findall(r"(?m)^#define CONFIG_" + feature + r"\s+(\d+)\s*$", header) != ["0"]:
                raise ValueError("Actual FFmpeg header enables or omits an excluded feature")
        for flag in ("--disable-autodetect", "--enable-shared", "--disable-static", "--disable-gpl", "--disable-nonfree", "--disable-libx264", "--disable-libx265"):
            if flag not in log:
                raise ValueError("Actual FFmpeg configure log lacks the controlled flags")
        for path in wheel_files:
            with zipfile.ZipFile(path) as archive:
                wheel_seen = set()
                for member in archive.infolist():
                    safe_name(member.filename, wheel_seen)
                    if stat.S_ISLNK(member.external_attr >> 16) or PurePosixPath(member.filename).suffix.lower() in (BINARY_SUFFIXES - {".dll", ".pyd"}):
                        raise ValueError("Unexpected wheel tool/binary member")
        verify_native(args.wheelhouse, args.build_root / "ffmpeg-config.mak")
        for name, content in data.items():
            if name.startswith("sources/"):
                inspect_source(name, content)
        provenance = json.loads(data["sources/provenance.json"].decode("utf-8-sig"))
        associations = json.loads(data["sources/source-associations.json"].decode("utf-8-sig"))
        if not isinstance(provenance, dict) or not provenance or associations.get("schema_version") != 1:
            raise ValueError("Source provenance/association metadata missing")
        components = associations.get("components", [])
        if not {"ffmpeg", "pyav", "ctranslate2", "onednn"}.issubset({row.get("component") for row in components}):
            raise ValueError("Primary native source associations missing")
        for row in components:
            for field in ("source_paths", "notice_paths"):
                if not isinstance(row.get(field), list) or not row[field]:
                    raise ValueError("Source/notice paths missing")
                for name in row[field]:
                    safe_name(name, set())
                    prefix = "sources/" + name
                    if not any(key == prefix or (field == "source_paths" and key.startswith(prefix + "/")) for key in data):
                        raise ValueError("Source/notice association absent from packaged bytes")
                    if field == "notice_paths" and not data[prefix]:
                        raise ValueError("Empty source notice")
        manifest = {
            "schema_version": 1, "qualification": "UNQUALIFIED_CANDIDATE",
            "runtime_id": args.runtime_id, "profile": "cpu", "platform": "win_x64",
            "python": "cp311", "producer_receipt": "build/native-build-receipt.json",
            "provenance": "sources/provenance.json", "source_associations": associations,
            "files": [{"path": name, "bytes": len(content), "sha256": sha(content)}
                      for name, content in sorted(data.items())],
        }
        args.output.parent.mkdir(parents=True, exist_ok=True)
        descriptor, temporary = tempfile.mkstemp(prefix=".cpu-native-", suffix=".tmp", dir=args.output.parent)
        os.close(descriptor)
        try:
            with zipfile.ZipFile(temporary, "w", compression=zipfile.ZIP_DEFLATED) as archive:
                for name, content in sorted(data.items()):
                    archive.writestr(name, content)
                archive.writestr("native-artifact-manifest.json", json.dumps(manifest, sort_keys=True, indent=2) + "\n")
            # Same-volume hard link publishes complete bytes exclusively; it cannot replace a prior output.
            os.link(temporary, args.output)
        finally:
            Path(temporary).unlink(missing_ok=True)
    return manifest


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    for name in ("wheelhouse", "build-root", "source-directory", "output"):
        parser.add_argument("--" + name, type=Path, required=True)
    parser.add_argument("--runtime-id", required=True)
    try:
        args = parser.parse_args()
        package(args)
        print(args.output)
        return 0
    except (OSError, ValueError, KeyError, TypeError, zipfile.BadZipFile, tarfile.TarError) as error:
        print(error, file=sys.stderr)
        return 1


if __name__ == "__main__":
    sys.exit(main())
