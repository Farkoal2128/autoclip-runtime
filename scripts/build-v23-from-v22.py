"""Derive an unpublished cuBLAS-only CUDA-provisioning candidate from exact v22."""

import argparse
import hashlib
import json
import subprocess
import zipfile
from pathlib import Path


def sha(data: bytes) -> str:
    return hashlib.sha256(data).hexdigest()


def committed(repository: Path, commit: str, name: str) -> bytes:
    return subprocess.check_output(["git", "show", f"{commit}:{name}"], cwd=repository)


def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--v22", type=Path, required=True)
    parser.add_argument("--app-wheel", type=Path, required=True)
    parser.add_argument("--archive", type=Path, required=True)
    parser.add_argument("--installer", type=Path, required=True)
    parser.add_argument("--app-repo", type=Path, required=True)
    args = parser.parse_args()
    if args.archive.exists() or args.installer.exists():
        raise ValueError("Immutable v23 candidate output already exists")
    if sha(args.v22.read_bytes()) != "cdc6b7b8b46eb1a7dd6707fd96ead4389eb5c7d03c577cd2f77f06f12ec7e97b":
        raise ValueError("Input is not the reviewed v22 archive")
    runtime = Path(__file__).resolve().parents[1]
    runtime_commit = subprocess.check_output(["git", "rev-parse", "HEAD"], cwd=runtime, text=True).strip()
    app_commit = subprocess.check_output(["git", "rev-parse", "HEAD"], cwd=args.app_repo, text=True).strip()
    app_wheel_name = "wheelhouse/autoclip-0.1.0.dev0-py3-none-any.whl"
    replacements = {
        app_wheel_name: args.app_wheel.read_bytes(),
        "build-native-from-source.ps1": committed(runtime, runtime_commit, "release/scripts/build-native-from-source.ps1"),
        "cuda-prerequisites.ps1": committed(runtime, runtime_commit, "release/scripts/cuda-prerequisites.ps1"),
    }
    with zipfile.ZipFile(args.v22) as source:
        manifest = json.loads(source.read("release-manifest.json"))
        legal = json.loads(source.read("notices-and-source/legal-index.json"))
        inventory = json.loads(source.read("notices-and-source/nvidia-runtime/inventory.json"))
        cudnn = lambda row: "cudnn" in row.get("filename", row.get("wheel", "")).lower()
        manifest["external_assets"] = [x for x in manifest["external_assets"] if not cudnn(x)]
        legal["external_assets"] = [x for x in legal["external_assets"] if not cudnn(x)]
        inventory["nvidia_runtime"] = [x for x in inventory["nvidia_runtime"] if not cudnn(x)]
        with zipfile.ZipFile(args.app_wheel) as app_archive:
            app_row = next(x for x in legal["packages"] if x["normalized_name"] == "autoclip")
            app_row["bytes"] = len(replacements[app_wheel_name])
            app_row["sha256"] = sha(replacements[app_wheel_name])
            app_row["record_rows"] = len(app_archive.read("autoclip-0.1.0.dev0.dist-info/RECORD").splitlines())
            for name, expected in app_row["legal_sha256"].items():
                if sha(app_archive.read(name)) != expected:
                    raise ValueError(f"App legal member changed and needs fresh review: {name}")
            app_row["data_assets"] = sorted(
                name for name in app_archive.namelist()
                if name.startswith(("autoclip/assets/fonts/", "autoclip/static/assets/"))
                and not name.endswith("/")
            )
            app_row["data_sha256"] = {
                name: sha(app_archive.read(name)) for name in app_row["data_assets"]
            }
        legal["v23_base_archive_sha256"] = sha(args.v22.read_bytes())
        manifest["native_build"]["runtime_commit"] = runtime_commit
        manifest["native_build"]["app_commit"] = app_commit
        manifest["native_build"]["cuda_installer_sha256"] = "540522788653606ace80869b65ac3acf8a13bea40545bd2f2af69393b5025a80"
        manifest["native_build"]["cuda_components"] = [
            "nvcc_12.8", "cudart_12.8", "cublas_12.8", "cublas_dev_12.8",
            "nvrtc_12.8", "nvrtc_dev_12.8", "nvfatbin_12.8", "nvjitlink_12.8",
            "curand_12.8", "curand_dev_12.8",
        ]
        legal["native_build"] = manifest["native_build"]
        replacements["notices-and-source/legal-index.json"] = (json.dumps(legal, indent=2) + "\n").encode()
        replacements["notices-and-source/nvidia-runtime/inventory.json"] = (json.dumps(inventory, indent=2) + "\n").encode()
        replacements["notices-and-source/MANIFEST.md"] = (
            "# Unpublished v23 source-build inventory\n\n"
            "The ZIP contains the AutoClip application wheel and pinned publisher wheels, "
            "excluding recipient-built PyAV and CTranslate2. The selected NVIDIA profile "
            "fetches only the exact cuBLAS wheel listed in `release-manifest.json`; it does "
            "not select cuDNN. CPU mode selects no NVIDIA wheel.\n\n"
            "`legal-index.json` and `nvidia-runtime/inventory.json` identify the selected "
            "wheel and DLL hashes. CUDA 12.8 is acquired from NVIDIA and installed on the "
            "recipient only when the explicit GPU mode needs missing build components. "
            "The exact NVIDIA installer and component list are in the native build manifest. "
            "Independent exact-asset and legal review remains open.\n"
        ).encode()
        old_paths = {row["path"]: row for row in manifest["files"]}
        excluded = {name for name in source.namelist() if "cudnn" in name.lower()}
        for name in excluded:
            old_paths.pop(name, None)
        for name, data in replacements.items():
            old_paths[name] = {"path": name, "bytes": len(data), "sha256": sha(data)}
        manifest["files"] = sorted(old_paths.values(), key=lambda row: row["path"])
        manifest_bytes = (json.dumps(manifest, indent=2) + "\n").encode()
        with zipfile.ZipFile(args.archive, "w") as target:
            for entry in source.infolist():
                if entry.filename in excluded:
                    continue
                target.writestr(entry, replacements.get(entry.filename, source.read(entry.filename)))
            target.writestr("cuda-prerequisites.ps1", replacements["cuda-prerequisites.ps1"])
            # Replace the manifest member after all other bytes have been selected.
        # Reopen and rewrite once to preserve v22 ordering while replacing its manifest.
    temporary = args.archive.with_suffix(".tmp")
    with zipfile.ZipFile(args.archive) as original, zipfile.ZipFile(temporary, "w") as target:
        for entry in original.infolist():
            data = manifest_bytes if entry.filename == "release-manifest.json" else original.read(entry.filename)
            target.writestr(entry, data)
    temporary.replace(args.archive)
    archive_sha = sha(args.archive.read_bytes())
    manifest_sha = sha(manifest_bytes)
    installer = committed(runtime, runtime_commit, "release/scripts/install-source-build.ps1").decode()
    helper = committed(runtime, runtime_commit, "release/scripts/cuda-prerequisites.ps1").decode()
    upstream = committed(runtime, runtime_commit, "release/scripts/upstream-assets.ps1").decode()
    installer = installer.replace(". (Join-Path $PSScriptRoot 'cuda-prerequisites.ps1')", "# CUDA helper is embedded in this standalone local installer.")
    installer = installer.replace(
        "$ErrorActionPreference = 'Stop'",
        "$ErrorActionPreference = 'Stop'\n" + upstream + "\n" + helper,
        1,
    )
    installer = installer.replace("de757f19171bbc57b6c26e31f7431a62240e2a4ee081167f649963bf61f29500", archive_sha)
    installer = installer.replace("f28fcc93e9f7d46c2f947c0d199d20b2e415de4d328eeeed961173bb5373772d", manifest_sha)
    installer = installer.replace("v11-20260926-source-build-candidate-v14", "v11-20260927-source-build-candidate-v23-cuda-bootstrap")
    args.installer.write_text(installer, encoding="utf-8")
    print(json.dumps({"archive": str(args.archive), "bytes": args.archive.stat().st_size,
                      "sha256": archive_sha, "manifest_sha256": manifest_sha,
                      "installer_sha256": sha(args.installer.read_bytes()),
                      "app_wheel_sha256": sha(args.app_wheel.read_bytes()),
                      "app_commit": app_commit, "runtime_commit": runtime_commit}))


if __name__ == "__main__":
    main()
