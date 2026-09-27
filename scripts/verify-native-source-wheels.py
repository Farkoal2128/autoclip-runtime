"""Fail a recipient native build if its wheels/configuration changed unexpectedly."""

import argparse
import base64
import csv
import hashlib
import io
import zipfile
from pathlib import Path

import pefile


FFMPEG = {"avcodec-62", "avdevice-62", "avfilter-11", "avformat-62", "avutil-60", "swresample-6", "swscale-9"}


def check_record(archive: zipfile.ZipFile) -> set[str]:
    if archive.testzip() is not None:
        raise ValueError("Wheel ZIP CRC check failed")
    names = set(archive.namelist())
    record = next((name for name in names if name.endswith(".dist-info/RECORD")), None)
    if not record:
        raise ValueError("Wheel RECORD missing")
    rows = list(csv.reader(io.StringIO(archive.read(record).decode("utf-8"))))
    if {row[0] for row in rows} != {name for name in names if not name.endswith("/")}:
        raise ValueError("Wheel RECORD paths disagree with archive")
    for name, expected_hash, expected_size in rows:
        data = archive.read(name)
        if expected_size and int(expected_size) != len(data):
            raise ValueError(f"Wheel RECORD size mismatch: {name}")
        if expected_hash:
            sha = base64.urlsafe_b64encode(hashlib.sha256(data).digest()).rstrip(b"=").decode("ascii")
            if expected_hash != "sha256=" + sha:
                raise ValueError(f"Wheel RECORD hash mismatch: {name}")
    return names


def verify(wheelhouse: Path, ffmpeg_config: Path) -> None:
    config = ffmpeg_config.read_text(encoding="utf-8")
    for flag in ("GPL", "NONFREE", "LIBX264", "LIBX265"):
        if f"!CONFIG_{flag}=yes" not in config or f"CONFIG_{flag}=yes\n" in config.replace(f"!CONFIG_{flag}=yes\n", ""):
            raise ValueError(f"Unsafe FFmpeg configuration: {flag}")
    for package in ("av-18.1.0-", "ctranslate2-4.8.2-"):
        matches = list(wheelhouse.glob(package + "*.whl"))
        if len(matches) != 1:
            raise ValueError(f"Expected one locally built {package} wheel")
        with zipfile.ZipFile(matches[0]) as archive:
            names = check_record(archive)
            dlls = {name for name in names if name.lower().endswith(".dll")}
            if package.startswith("av-"):
                if len(dlls) != 7 or {next((part for part in FFMPEG if name.startswith("av.libs/" + part + "-")), "") for name in dlls} != FFMPEG:
                    raise ValueError("PyAV wheel does not contain exactly the seven controlled FFmpeg DLLs")
            else:
                if dlls != {"ctranslate2/ctranslate2.dll"}:
                    raise ValueError("CTranslate2 wheel contains an unexpected DLL")
                pe = pefile.PE(data=archive.read("ctranslate2/ctranslate2.dll"))
                imports = {entry.dll.decode("ascii").lower() for entry in pe.DIRECTORY_ENTRY_IMPORT}
                if not {"libopenblas.dll", "vcomp140.dll"}.issubset(imports):
                    raise ValueError("CTranslate2 missing controlled OpenBLAS/OpenMP imports")
                if any("mkl" in name or "iomp" in name or "cudnn" in name or "cublas" in name for name in imports):
                    raise ValueError("CTranslate2 unexpectedly imports MKL, Intel OpenMP, cuDNN or direct cuBLAS")
        print(matches[0].name, matches[0].stat().st_size, hashlib.sha256(matches[0].read_bytes()).hexdigest())


if __name__ == "__main__":
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("wheelhouse", type=Path)
    parser.add_argument("ffmpeg_config", type=Path)
    args = parser.parse_args()
    verify(args.wheelhouse, args.ffmpeg_config)
