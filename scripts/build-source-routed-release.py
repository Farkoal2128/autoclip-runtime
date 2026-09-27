"""Build a candidate that fetches Microsoft/NVIDIA binaries from publishers.

This deliberately does not promote an installer pin or claim CR-09 clearance.
"""

import argparse
import base64
import csv
import hashlib
import io
import json
import re
import shutil
import zipfile
from pathlib import Path



EXTERNAL_ASSETS = [
    {
        "kind": "openblas_archive",
        "filename": "OpenBLAS-0.3.30-x64.zip",
        "url": "https://github.com/OpenMathLib/OpenBLAS/releases/download/v0.3.30/OpenBLAS-0.3.30-x64.zip",
        "bytes": 40561566,
        "sha256": "8b04387766efc05c627e26d24797ec0d4ed4c105ec14fa7400aa84a02db22b66",
        "member_path": "bin/libopenblas.dll",
        "member_sha256": "e824cf9fc22e5949807ce995a32e413a345fb97e63e6d10cfbf41aa86382193c",
    },
    {
        "kind": "microsoft_vc_redist_x64",
        "filename": "VC_redist.x64.exe",
        "url": "https://download.visualstudio.microsoft.com/download/pr/bd1c8d9d-ba95-4eee-bc6e-df1fcc876373/CC0FF0EB1DC3F5188AE6300FAEF32BF5BEEBA4BDD6E8E445A9184072096B713B/VC_redist.x64.exe",
        "bytes": 25635768,
        "sha256": "cc0ff0eb1dc3f5188ae6300faef32bf5beeba4bdd6e8e445a9184072096b713b",
    },
    {
        "kind": "python_wheel",
        "filename": "nvidia_cublas_cu12-12.4.5.8-py3-none-win_amd64.whl",
        "url": "https://files.pythonhosted.org/packages/e2/2a/4f27ca96232e8b5269074a72e03b4e0d43aa68c9b965058b1684d07c6ff8/nvidia_cublas_cu12-12.4.5.8-py3-none-win_amd64.whl",
        "bytes": 396895858,
        "sha256": "5a796786da89203a0657eda402bcdcec6180254a8ac22d72213abc42069522dc",
    },
    {
        "kind": "python_wheel",
        "filename": "nvidia_cudnn_cu12-9.10.2.21-py3-none-win_amd64.whl",
        "url": "https://files.pythonhosted.org/packages/3d/90/0bd6e586701b3a890fd38aa71c387dab4883d619d6e5ad912ccbd05bfd67/nvidia_cudnn_cu12-9.10.2.21-py3-none-win_amd64.whl",
        "bytes": 692992268,
        "sha256": "c6288de7d63e6cf62988f0923f96dc339cea362decb1bf5b3141883392a7d65e",
    },
]


def native_source_wheel_names() -> set[str]:
    """Controlled native wheels that a recipient-side build must replace."""
    return {
        "av-18.1.0-cp311-abi3-win_amd64.whl",
        "ctranslate2-4.8.2-cp311-cp311-win_amd64.whl",
    }


def validate_publisher_wheels(wheels: list[Path], entries: list[dict]) -> None:
    """Reject incomplete or mismatched PyPI routes before excluding wheel bytes."""
    by_name = {item["filename"]: item for item in entries}
    if len(by_name) != len(entries) or set(by_name) != {wheel.name for wheel in wheels}:
        raise ValueError("publisher wheel set differs from candidate")
    for wheel in wheels:
        item = by_name[wheel.name]
        fields = wheel.name.removesuffix(".whl").split("-")
        name, version = fields[0], fields[1]
        tag = "-".join(fields[-3:])
        if (item.get("package") != re.sub(r"[-_.]+", "-", name).lower()
                or item.get("version") != version
                or item.get("tags") != [tag]
                or item.get("bytes") != wheel.stat().st_size
                or item.get("sha256") != hashlib.sha256(wheel.read_bytes()).hexdigest()
                or item.get("delivery_policy") != "publisher"
                or not item.get("url", "").startswith("https://files.pythonhosted.org/")
                or not item.get("publisher_identity")):
            raise ValueError(f"publisher wheel hash mismatch or invalid identity: {wheel.name}")


LEGAL_MEMBER = re.compile(
    r"(^|/)(licen[cs]e[^/]*|copying[^/]*|authors[^/]*|.*notices?[^/]*|copyright[^/]*|thirdparty[^/]*)$",
    re.I,
)


def copy_missing_legal_files(wheels: list[Path], target: Path) -> list[str]:
    """Preserve distinct author paths even when license wording is identical."""
    added = []
    for wheel_path in wheels:
        with zipfile.ZipFile(wheel_path) as wheel:
            for member in wheel.infolist():
                if member.is_dir() or not LEGAL_MEMBER.search(member.filename):
                    continue
                if "\\" in member.filename or ".." in Path(member.filename).parts:
                    raise ValueError(f"Unsafe legal member in {wheel_path.name}: {member.filename}")
                relative = Path("notices-and-source") / "wheel-notices" / wheel_path.name / member.filename
                destination = target / relative
                data = wheel.read(member)
                if destination.exists():
                    if destination.read_bytes() != data:
                        raise ValueError(f"Existing sidecar legal copy differs: {relative}")
                    continue
                destination.parent.mkdir(parents=True, exist_ok=True)
                destination.write_bytes(data)
                added.append(relative.as_posix())
    return added


def attach_review_index(wheels: list[Path], source: Path, target: Path) -> None:
    """Bind a researched index to the exact packaged wheel bytes."""
    audit = json.loads(source.read_text(encoding="utf-8"))
    if audit.get("schema_version") != 1 or not isinstance(audit.get("packages"), list):
        raise ValueError("Unsupported review index schema")
    reviewed = {row["filename"]: row for row in audit["packages"]}
    if len(reviewed) != len(wheels) or set(reviewed) != {wheel.name for wheel in wheels}:
        raise ValueError("legal index wheel set differs from candidate")
    for wheel in wheels:
        if hashlib.sha256(wheel.read_bytes()).hexdigest() != reviewed[wheel.name]["sha256"]:
            raise ValueError(f"legal index wheel hash mismatch: {wheel.name}")
    portable = {
        "schema_version": 1,
        "source_audit_archive_sha256": audit.get("candidate_archive_sha256"),
        "wheel_count": len(wheels),
        "packages": audit["packages"],
        "external_assets": audit.get("external_assets", []),
        "native_build": audit.get("native_build", {}),
        "decision": "Evidence index for review; no independent legal approval",
    }
    sidecar = target / "notices-and-source"
    sidecar.mkdir(parents=True, exist_ok=True)
    (sidecar / "legal-index.json").write_text(json.dumps(portable, indent=2) + "\n", encoding="utf-8")
    (target / "LICENSES.md").write_text(
        "# AutoClip runtime licenses, notices and source\n\n"
        "Open `notices-and-source/legal-index.json` for exact packaged-wheel identities, "
        "legal files, separate component leads and notice locations. "
        "Original texts and source/build material are under `notices-and-source/`. "
        "The locally built PyAV/CTranslate2 wheel hashes and native DLL hashes are in "
        "`native-build-receipt.json` after installation. Downloaded NVIDIA wheels retain "
        "their own license files in the installed Python environment. "
        "The AutoClip app wheel carries its frontend and font notices; inspect any later app-only update separately.\n\n"
        "This index is technical evidence for review, not legal approval.\n",
        encoding="utf-8",
    )


def attach_source_artifacts(inputs: Path, cache: Path, target: Path) -> None:
    """Copy only pinned, byte-verified upstream source archives."""
    specification = json.loads(inputs.read_text(encoding="utf-8"))
    if specification.get("schema_version") != 1 or not isinstance(specification.get("artifacts"), list):
        raise ValueError("Unsupported source artifact specification")
    output = target / "notices-and-source" / "source-and-build"
    for item in specification["artifacts"]:
        name = item["filename"]
        if Path(name).name != name or "\\" in name:
            raise ValueError(f"Unsafe source artifact filename: {name}")
        source = cache / name
        if not source.is_file() or source.stat().st_size != item["bytes"]:
            raise ValueError(f"source artifact size mismatch: {name}")
        if hashlib.sha256(source.read_bytes()).hexdigest() != item["sha256"]:
            raise ValueError(f"source artifact hash mismatch: {name}")
    output.mkdir(parents=True, exist_ok=True)
    for item in specification["artifacts"]:
        shutil.copyfile(cache / item["filename"], output / item["filename"])
    (output / "source-artifact-manifest.json").write_text(
        json.dumps(specification, indent=2) + "\n", encoding="utf-8"
    )


def digest(data: bytes) -> str:
    return base64.urlsafe_b64encode(hashlib.sha256(data).digest()).rstrip(b"=").decode("ascii")


def attach_sbom_packet(packet: Path, target: Path, plan: dict) -> None:
    """Verify every staged notice/source byte before copying it into a candidate."""
    base = packet / "notices-and-source"
    manifest = json.loads((base / "sbom-packet-manifest.json").read_text(encoding="utf-8"))
    index = json.loads((base / "sbom-component-index.json").read_text(encoding="utf-8"))
    files = manifest.get("files", [])
    components = index.get("components", [])
    if (manifest.get("schema_version") != 1 or manifest.get("file_count") != len(files)
            or index.get("schema_version") != 1 or index.get("component_count") != len(components)):
        raise ValueError("Unsupported SBOM legal packet")
    expected = {(row["wheel"], row["wheel_sha256"], row["purl"])
                for row in plan["components"]}
    actual = {(row["wheel"], row["wheel_sha256"], row["purl"]) for row in components}
    if len(expected) != len(plan["components"]) or len(actual) != len(components) or actual != expected:
        raise ValueError("SBOM packet component identity differs from plan")
    verified = {}
    for row in files:
        name = row["path"]
        relative = Path(name)
        if (relative.is_absolute() or ".." in relative.parts or "\\" in name
                or not name.startswith("notices-and-source/") or name in verified):
            raise ValueError(f"Unsafe SBOM packet member: {name}")
        original = packet / relative
        if (not original.is_file() or original.stat().st_size != row["bytes"]
                or hashlib.sha256(original.read_bytes()).hexdigest() != row["sha256"]):
            raise ValueError(f"SBOM packet member differs: {name}")
        verified[name] = original
    for row in components:
        if not row.get("installed_legal_paths") or any(
            name not in verified for name in row["installed_legal_paths"]
        ) or (row.get("installed_source_path") and row["installed_source_path"] not in verified):
            raise ValueError(f"SBOM packet lacks fulfillment paths: {row['purl']}")
    for name, original in verified.items():
        destination = target / name
        if destination.exists():
            raise ValueError(f"SBOM packet collides with candidate member: {name}")
        destination.parent.mkdir(parents=True, exist_ok=True)
        shutil.copy2(original, destination)
    shutil.copy2(base / "sbom-packet-manifest.json",
                 target / "notices-and-source" / "sbom-packet-manifest.json")
    by_key = {(row["wheel"], row["wheel_sha256"], row["purl"]): row for row in components}
    for row in plan["components"]:
        source = by_key[(row["wheel"], row["wheel_sha256"], row["purl"])]
        row["notice_status"] = "SBOM_notice_source_packet_staged"
        row["source_url"] = source["source_url"]
        row["source_sha256"] = source["source_sha256"]
        row["installed_legal_paths"] = source["installed_legal_paths"]
        row["installed_source_path"] = source["installed_source_path"]


def build_publisher_routed_release(source: Path, target: Path, pins: Path,
                                   sbom_plan: Path | None = None,
                                   sbom_packet: Path | None = None) -> None:
    """Turn a verified source-build candidate into a publisher-routed candidate."""
    if target.exists():
        raise ValueError(f"Candidate output already exists: {target}")
    old = json.loads((source / "release-manifest.json").read_text(encoding="utf-8"))
    specification = json.loads(pins.read_text(encoding="utf-8"))
    if specification.get("schema_version") != 1:
        raise ValueError("Unsupported publisher wheel specification")
    entries = specification["wheels"]
    wheel_paths = [source / "wheelhouse" / item["filename"] for item in entries]
    validate_publisher_wheels(wheel_paths, entries)
    old_wheels = {Path(row["path"]).name for row in old["files"]
                  if row["path"].startswith("wheelhouse/") and row["path"].endswith(".whl")}
    apps = old_wheels - {item["filename"] for item in entries}
    if len(apps) != 1 or not next(iter(apps)).startswith("autoclip-"):
        raise ValueError("Expected exactly one AutoClip-owned wheel")
    target.mkdir(parents=True)
    for row in old["files"]:
        relative = Path(row["path"])
        if relative.is_absolute() or ".." in relative.parts or "\\" in row["path"]:
            raise ValueError(f"Unsafe source manifest path: {relative}")
        original = source / relative
        if (not original.is_file() or original.stat().st_size != row["bytes"]
                or hashlib.sha256(original.read_bytes()).hexdigest() != row["sha256"]):
            raise ValueError(f"Source manifest member differs: {relative}")
        if original.name in {item["filename"] for item in entries} and relative.parts[0] == "wheelhouse":
            continue
        destination = target / relative
        destination.parent.mkdir(parents=True, exist_ok=True)
        shutil.copy2(original, destination)

    repository = Path(__file__).resolve().parents[1]
    for name in ("upstream-assets.ps1", "Prepare-AutoClipOfflineCache.ps1"):
        shutil.copy2(repository / name, target / name)

    index_path = target / "notices-and-source" / "legal-index.json"
    if index_path.exists():
        index = json.loads(index_path.read_text(encoding="utf-8"))
        by_filename = {item["filename"]: item for item in entries}
        for row in index["packages"]:
            route = by_filename.get(row["filename"])
            if route:
                row["delivery_policy"] = "publisher"
                row["publisher_url"] = route["url"]
                row["technical_state"] = "publisher_routed"
                row["review_disposition"] = "exact publisher artifact and supplied notices pinned"
                row["fulfillment_locations"] = [
                    path for path in row.get("fulfillment_locations", [])
                    if not path.startswith(f"wheelhouse/{row['filename']}!/")
                ] + [f"publisher:{route['url']}"]
            else:
                row["delivery_policy"] = "autoclip"
                row["technical_state"] = "verified"
                row["review_disposition"] = "AutoClip-owned wheel and supplied notices verified"
            if row.get("research_class") == "METADATA":
                row["notice_disposition"] = "metadata_normalized"
            elif row.get("research_class") == "STANDARD":
                row["notice_disposition"] = "notice_verified"
            elif row.get("sbom_components"):
                row["sbom_policy"] = "All declared components treated as potentially incorporated; license/source fulfillment tracked separately"
                row["notice_disposition"] = "SBOM_component_notice_bundle_pending"
        index["publisher_wheels"] = entries
        for row in index["packages"]:
            if row["normalized_name"] == "certifi":
                row["source_delivery"] = {
                    "state": "source_delivery_verified",
                    "path": "notices-and-source/source-and-build/certifi-2026.7.22.tar.gz",
                    "sha256": "741e2c3b351ddf169a738da9f2c048608ff7f2c5cc02f1ebc6b118bb090d5d55",
                    "evidence": "Python source files and cacert.pem byte-identical to reviewed wheel",
                }
                row["technical_state"] = "source_fulfilled"
                row["review_disposition"] = "exact certifi source delivery verified"
            if row["normalized_name"] == "onnxruntime":
                row["eigen_source"] = {
                    "state": "source_obligation_conservatively_fulfilled",
                    "path": "notices-and-source/source-and-build/eigen-1d8b82b0740839c0de7f1242a3585e3390ff5f33.zip",
                    "sha256": "6a60d76351f97132669daeeb721d6bf14b008101883ad2d687a3201c5c461eb0",
                    "component_inclusion": "optional component not asserted",
                }
                row["technical_state"] = "source_fulfilled"
                row["review_disposition"] = "upstream notices and pinned Eigen source preserved"
            if row["normalized_name"] == "faster-whisper":
                model = "faster_whisper/assets/silero_vad_v6.onnx"
                if row.get("data_sha256", {}).get(model) != "4cbf549b8326f60f80f2536d9eefeb450a9abe83365a098031c89719f1be17d2":
                    raise ValueError("Silero model hash differs from reviewed wheel")
                row["silero_vad_model"] = {
                    "state": "model_provenance_verified", "path": model,
                    "sha256": row["data_sha256"][model], "copyright": "2020-present Silero Team",
                    "license": "MIT", "notice_path": "notices-and-source/models/silero-vad-v6-LICENSE",
                    "faster_whisper_revision": "v1.2.1",
                    "faster_whisper_change": "https://github.com/SYSTRAN/faster-whisper/pull/1373",
                    "silero_release": "https://github.com/snakers4/silero-vad/releases/tag/v6.0",
                    "reconstruction": "https://gist.github.com/MahmoudAshraf97/29f73de73beb8e4549dedb8b5eac9702",
                }
                row["technical_state"] = "verified"
                row["review_disposition"] = "Silero model identity and MIT notice preserved"
        index_path.write_text(json.dumps(index, indent=2) + "\n", encoding="utf-8")
    if any(item["package"] == "faster-whisper" for item in entries):
        notice = Path(__file__).resolve().parents[1] / "silero-vad-v6-LICENSE"
        if hashlib.sha256(notice.read_bytes()).hexdigest() != "2e63e9a38b6e8fc0c7bc37ce174caca1862870856c6daf5697cfb785e925520b":
            raise ValueError("Silero MIT notice differs from pinned v6.0 source")
        destination = target / "notices-and-source" / "models" / notice.name
        destination.parent.mkdir(parents=True, exist_ok=True)
        shutil.copy2(notice, destination)
    if sbom_plan:
        plan = json.loads(sbom_plan.read_text(encoding="utf-8"))
        wheel_hashes = {item["filename"]: item["sha256"] for item in entries}
        if plan.get("schema_version") != 1 or plan.get("component_count") != len(plan.get("components", [])):
            raise ValueError("Unsupported SBOM component plan")
        for component in plan["components"]:
            if wheel_hashes.get(component["wheel"]) != component["wheel_sha256"]:
                raise ValueError(f"SBOM plan wheel hash mismatch: {component['wheel']}")
        if sbom_packet:
            attach_sbom_packet(sbom_packet, target, plan)
            for row in index["packages"]:
                if row.get("sbom_components"):
                    row["notice_disposition"] = "SBOM_notice_source_packet_staged"
                    row["technical_state"] = "legal_review_pending"
            index_path.write_text(json.dumps(index, indent=2) + "\n", encoding="utf-8")
        destination = target / "notices-and-source" / "sbom-component-plan.json"
        destination.parent.mkdir(parents=True, exist_ok=True)
        destination.write_text(json.dumps(plan, indent=2) + "\n", encoding="utf-8")
    elif sbom_packet:
        raise ValueError("SBOM legal packet requires a component plan")
    (target / "publisher-wheel-manifest.json").write_text(
        json.dumps(specification, indent=2) + "\n", encoding="utf-8")
    (target / "distribution-inventory.json").write_text(json.dumps({
        "schema_version": 1, "autoclip_wheels": sorted(apps),
        "publisher_wheel_count": len(entries), "publisher_wheels": [item["filename"] for item in entries],
        "native_build": old.get("native_build", {}), "external_assets": old.get("external_assets", []),
    }, indent=2) + "\n", encoding="utf-8")
    licenses = target / "LICENSES.md"
    if licenses.exists():
        licenses.write_text(licenses.read_text(encoding="utf-8") +
            "\nDependency wheels are downloaded from their exact PyPI file URLs and retained in a verified "
            "local cache. The legal index identifies each publisher URL and installed notice copy.\n",
            encoding="utf-8")
    sidecar = target / "notices-and-source" / "MANIFEST.md"
    if sidecar.exists():
        sidecar.write_text(sidecar.read_text(encoding="utf-8") +
            "\n## v14 publisher routing\n\nOnly the AutoClip wheel is in this archive's wheelhouse. "
            "All dependency wheels are pinned in `publisher-wheel-manifest.json` and fetched from PyPI. "
            "Earlier wheel tables describe the reviewed source artifact and are not the packaged wheel list.\n",
            encoding="utf-8")
    files = []
    for file in sorted(target.rglob("*")):
        if file.is_file():
            files.append({"path": file.relative_to(target).as_posix(),
                          "bytes": file.stat().st_size,
                          "sha256": hashlib.sha256(file.read_bytes()).hexdigest()})
    manifest = {"schema_version": 3, "files": files,
                "publisher_wheels": entries, "external_assets": old.get("external_assets", []),
                "native_build": old.get("native_build", {})}
    (target / "release-manifest.json").write_text(json.dumps(manifest, indent=2) + "\n", encoding="utf-8")


def strip_vendor_dlls(source: Path, target: Path) -> None:
    with zipfile.ZipFile(source) as original, zipfile.ZipFile(target, "w") as output:
        records = []
        record_name = None
        removed = 0
        for item in original.infolist():
            if item.is_dir():
                output.writestr(item, b"")
                continue
            name = item.filename
            if name.lower() in {"ctranslate2/vcomp140.dll", "ctranslate2/libopenblas.dll"}:
                removed += 1
                continue
            if name.endswith(".dist-info/RECORD"):
                record_name = name
                continue
            data = original.read(item)
            output.writestr(item, data)
            records.append([name, "sha256=" + digest(data), str(len(data))])
        if removed != 2 or record_name is None:
            raise ValueError("Controlled CTranslate2 wheel lacks the exact vendor DLLs or RECORD")
        records.append([record_name, "", ""])
        text = io.StringIO(newline="")
        csv.writer(text, lineterminator="\n").writerows(records)
        output.writestr(record_name, text.getvalue().encode("utf-8"))


def build_release(source: Path, target: Path, *, build_native_from_source: bool = False,
                  review_index: Path | None = None, source_cache_dir: Path | None = None) -> None:
    if target.exists():
        raise ValueError(f"Candidate output already exists: {target}")
    source_manifest = json.loads((source / "release-manifest.json").read_text(encoding="utf-8"))
    listed = source_manifest["files"]
    names = [entry["path"] for entry in listed]
    if len(names) != len(set(names)) or any(
        Path(name).is_absolute() or ".." in Path(name).parts or "\\" in name for name in names
    ):
        raise ValueError("Source manifest has duplicate or unsafe paths")
    source_wheels = [source / name for name in names if name.startswith("wheelhouse/") and name.endswith(".whl")]
    if not source_wheels:
        raise ValueError("Source wheelhouse is empty")
    target.mkdir(parents=True)
    omitted = {asset["filename"] for asset in EXTERNAL_ASSETS if asset["kind"] == "python_wheel"}
    if not omitted.issubset({wheel.name for wheel in source_wheels}):
        raise ValueError("Source wheelhouse lacks a pinned NVIDIA wheel")
    controlled = [wheel for wheel in source_wheels if wheel.name.startswith("ctranslate2-4.8.2-")]
    if len(controlled) != 1:
        raise ValueError("Expected one controlled CTranslate2 wheel")
    if build_native_from_source:
        omitted.update(native_source_wheel_names())
        if not native_source_wheel_names().issubset({wheel.name for wheel in source_wheels}):
            raise ValueError("Source wheelhouse lacks the controlled PyAV or CTranslate2 wheel")
        official = "notices-and-source/nvidia-runtime/cudnn-9.10.2-official/"
        required = {official + name for name in ("eula.html", "acknowledgements.html", "notices.html")}
        if not required.issubset(set(names)):
            raise ValueError("Source release lacks versioned cuDNN 9.10.2 terms and acknowledgements")
    for entry in listed:
        relative = Path(entry["path"])
        file = source / relative
        if not file.is_file() or file.stat().st_size != entry["bytes"] or hashlib.sha256(file.read_bytes()).hexdigest() != entry["sha256"]:
            raise ValueError(f"Source release file disagrees with its manifest: {relative}")
        if file.name in omitted or relative.as_posix() == "notices-and-source/source-and-build/OpenBLAS-0.3.30-x64.zip":
            continue
        destination = target / relative
        destination.parent.mkdir(parents=True, exist_ok=True)
        if file == controlled[0]:
            strip_vendor_dlls(file, destination)
        else:
            shutil.copy2(file, destination)
    repository = Path(__file__).resolve().parents[1]
    shutil.copy2(repository / "upstream-assets.ps1", target / "upstream-assets.ps1")
    if build_native_from_source:
        for name in ("build-native-from-source.ps1", "build-v11-codec-free-ffmpeg.sh"):
            shutil.copy2(repository / name, target / name)
        shutil.copy2(repository / "scripts" / "verify-native-source-wheels.py", target / "verify-native-source-wheels.py")
        shutil.copy2(repository / "scripts" / "verify-install-wheels.py", target / "verify-install-wheels.py")
    sidecar = target / "notices-and-source" / "MANIFEST.md"
    if sidecar.exists():
        contents = sidecar.read_text(encoding="utf-8")
        contents = contents.replace(
            "Inventory for a versioned 79-wheel Windows release correction based on the 2026-09-26 app-refresh archive.",
            "Inventory for a 77-wheel source-routed Windows candidate derived from the 2026-09-26 notice-correction archive.",
        ).replace(
            "The release contains 79 wheel files: AutoClip, 76 other dependencies and two NVIDIA CUDA runtime wheels.",
            "The candidate contains 77 wheel files: AutoClip and 76 other dependencies. The two exact NVIDIA CUDA runtime wheels are fetched from their publisher during installation.",
        )
        if build_native_from_source:
            contents = contents.replace(
                "# Proposed V11 release supplement v3",
                "# 75-wheel source-build candidate notice and source inventory",
            ).replace(
                "# V11 Windows release notice and source inventory",
                "# 75-wheel source-build candidate notice and source inventory",
            ).replace("Review input only. HOLD.", "Unpublished review candidate.")
            contents = contents.replace("77-wheel source-routed", "75-wheel source-build").replace(
                "The candidate contains 77 wheel files: AutoClip and 76 other dependencies. The two exact NVIDIA CUDA runtime wheels are fetched from their publisher during installation.",
                "The candidate contains 75 wheel files. PyAV and CTranslate2 are built on the recipient machine; two NVIDIA wheels are fetched from their publisher.",
            )
            contents = contents.replace(
                "Review input only. HOLD. Exact 77-wheel candidate uses codec-free PyAV and controlled OpenBLAS plus statically linked oneDNN CTranslate2. Notice applicability remains for independent review.",
                "Review input only. HOLD. Exact 75-wheel candidate excludes PyAV and CTranslate2 native wheels; their pinned sources are built on the recipient machine. Notice applicability remains for independent review. Wheel-notice rows for these excluded wheels are historical review inputs.",
            )
        contents = contents.replace(
            "| `source-and-build/OpenBLAS-0.3.30-x64.zip` | 40561566 | `8b04387766efc05c627e26d24797ec0d4ed4c105ec14fa7400aa84a02db22b66` |\n",
            "",
        )
        routed_wheel = target / "wheelhouse" / controlled[0].name
        route_note = (
            ("## Recipient source-build candidate changes\n\n" if build_native_from_source else "## Source-routed candidate changes\n\n")
            + "The two NVIDIA wheels listed in the tables below are external publisher downloads, "
            "not members of this candidate ZIP. `release-manifest.json` pins their PyPI URLs, "
            "sizes and SHA-256 values. "
            + ("PyAV and CTranslate2 are excluded for recipient-side compilation. " if build_native_from_source else
               "The modified CTranslate2 wheel omits Microsoft's `VCOMP140.DLL` and OpenBLAS's `libopenblas.dll`; its SHA-256 is `"
               + hashlib.sha256(routed_wheel.read_bytes()).hexdigest() + "`. ")
            + "The installer requires Microsoft's x64 Visual C++ Redistributable from "
            "the pinned Microsoft URL when a compatible system OpenMP runtime is absent. "
            "The official OpenBLAS ZIP comes directly from OpenMathLib; its exact "
            "`bin/libopenblas.dll` member is verified before local placement. "
            + ("Recipient-built native outputs require a separate exact inventory and review.\n\n" if build_native_from_source else
               "All other controlled native members remain packaged pending separate review.\n\n")
        )
        if "## NVIDIA 9.10.2 review material" in contents:
            contents = contents.replace("## NVIDIA 9.10.2 review material", route_note + "## NVIDIA 9.10.2 review material", 1)
        else:
            contents += "\n" + route_note
        sidecar.write_text(contents, encoding="utf-8")
    if review_index:
        if not build_native_from_source:
            raise ValueError("Review index is defined for the recipient source-build profile")
        wheels = sorted((target / "wheelhouse").glob("*.whl"))
        attach_review_index(wheels, review_index, target)
        added = copy_missing_legal_files(wheels, target)
        if added:
            with sidecar.open("a", encoding="utf-8") as output:
                output.write("\n## Additional exact wheel legal copies\n\n")
                for path in added:
                    output.write(f"- `{path.removeprefix('notices-and-source/')}`\n")
    if source_cache_dir:
        if not build_native_from_source:
            raise ValueError("Source artifact cache is defined for the recipient source-build profile")
        attach_source_artifacts(Path(__file__).resolve().parents[1] / "source-artifact-inputs.json", source_cache_dir, target)
    files = []
    for file in sorted(target.rglob("*")):
        if file.is_file():
            relative = file.relative_to(target).as_posix()
            files.append({"path": relative, "bytes": file.stat().st_size, "sha256": hashlib.sha256(file.read_bytes()).hexdigest()})
    manifest = {"schema_version": 2, "files": files, "external_assets": EXTERNAL_ASSETS}
    if build_native_from_source:
        manifest["native_build"] = {
            "python": "3.11",
            "ffmpeg": "8.1.2",
            "ffmpeg_source_sha256": "464beb5e7bf0c311e68b45ae2f04e9cc2af88851abb4082231742a74d97b524c",
            "pyav": "18.1.0",
            "pyav_source_sha256": "47bfc286e1bc9de7ab4681fc2b575cd2460a66919d31ffe1bd5aa54fae531a28",
            "onednn": "3.1.1",
            "onednn_commit": "64f6bcbcbab628e96f33a62c3e975f8535a7bde4",
            "ctranslate2": "4.8.2",
            "ctranslate2_commit": "d44d2d069eb88c7b7804da864c10c201501cb4a9",
            "cuda_toolkit": "12.8",
            "cuda_dynamic_loading": True,
            "cuda_architectures": "Common plus sm_120",
            "wheel_names": sorted(native_source_wheel_names()),
        }
    (target / "release-manifest.json").write_text(json.dumps(manifest, indent=2) + "\n", encoding="utf-8")


def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("source", type=Path, help="Verified extracted 79-wheel release root")
    parser.add_argument("target", type=Path, help="New empty candidate directory")
    parser.add_argument("--archive", type=Path, help="Optional versioned candidate ZIP")
    parser.add_argument("--build-native-from-source", action="store_true", help="Omit PyAV and CTranslate2 wheels for recipient builds")
    parser.add_argument("--review-index", type=Path, help="Exact-wheel audit JSON to ship as a review index")
    parser.add_argument("--source-cache-dir", type=Path, help="Cache of pinned upstream source archives")
    parser.add_argument("--publisher-wheels", type=Path, help="Convert an existing source-build candidate to publisher-routed wheels")
    parser.add_argument("--sbom-plan", type=Path, help="Conservative SBOM component obligation worklist")
    parser.add_argument("--sbom-legal-packet", type=Path, help="Verified staged SBOM legal/source packet")
    args = parser.parse_args()
    if args.publisher_wheels:
        build_publisher_routed_release(args.source, args.target, args.publisher_wheels,
                                       args.sbom_plan, args.sbom_legal_packet)
    else:
        build_release(args.source, args.target, build_native_from_source=args.build_native_from_source,
                      review_index=args.review_index, source_cache_dir=args.source_cache_dir)
    if args.archive:
        if args.archive.exists():
            raise ValueError(f"Candidate archive already exists: {args.archive}")
        with zipfile.ZipFile(args.archive, "w", compression=zipfile.ZIP_DEFLATED, compresslevel=6) as archive:
            for file in sorted(args.target.rglob("*")):
                if file.is_file():
                    archive.write(file, file.relative_to(args.target).as_posix())
        for file in (args.target / "release-manifest.json", args.archive):
            print(file, file.stat().st_size, hashlib.sha256(file.read_bytes()).hexdigest())


if __name__ == "__main__":
    main()
