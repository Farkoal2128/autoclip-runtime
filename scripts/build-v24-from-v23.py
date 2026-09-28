"""Build an unpublished v24 engineering snapshot from the exact v23 archive.

This records local uncommitted source explicitly. It is not a release clearance or
a substitute for a candidate built from a committed, retrievable source revision.
"""

import argparse
import hashlib
import json
import re
import zipfile
from pathlib import Path


V23_ARCHIVE_SHA256 = "eb44ce1e058f034ec942eb899954ed41e369ffac2f39782373f5b7918520ab4a"
V23_RELEASE_ID = "v11-20260927-source-build-candidate-v23-cuda-bootstrap"
V24_RELEASE_ID = "v11-20260927-source-build-candidate-v24-local-snapshot"
APP_MEMBER = "wheelhouse/autoclip-0.1.0.dev0-py3-none-any.whl"
FONT_NOTICE = re.compile(r"autoclip/assets/licenses/(?:[^/]+-OFL\.txt|README\.md)\Z")
SNAPSHOT_NAMES = {
    "build-native-from-source.ps1",
    "update.ps1",
    "scripts/build-source-routed-release.py",
    "Prepare-AutoClipOfflineCache.ps1",
}


def sha(data: bytes) -> str:
    return hashlib.sha256(data).hexdigest()


def file_sha(path: Path) -> str:
    digest = hashlib.sha256()
    with path.open("rb") as stream:
        for block in iter(lambda: stream.read(1024 * 1024), b""):
            digest.update(block)
    return digest.hexdigest()


def encoded(value: dict) -> bytes:
    return (json.dumps(value, indent=2) + "\n").encode("utf-8")


def replace_once(source: str, old: str, new: str) -> str:
    if source.count(old) != 1:
        raise ValueError(f"Expected exactly one installer occurrence of {old}")
    return source.replace(old, new)


def derive(
    base: Path,
    app_wheel: Path,
    old_installer: Path,
    output: Path,
    new_installer: Path,
    *,
    expected_base_hash: str,
    old_release_id: str,
    new_release_id: str,
    source_snapshot: dict[str, bytes],
) -> dict:
    if output.exists() or new_installer.exists():
        raise ValueError("Refusing to replace an immutable candidate output")
    if file_sha(base) != expected_base_hash:
        raise ValueError("Input archive differs from the reviewed base")
    if set(source_snapshot) != SNAPSHOT_NAMES:
        raise ValueError("The source snapshot must contain the four reviewed files")
    if not re.fullmatch(r"[A-Za-z0-9][A-Za-z0-9._-]*", new_release_id):
        raise ValueError("Invalid new release identity")

    with zipfile.ZipFile(base) as source, zipfile.ZipFile(app_wheel) as wheel:
        names = source.namelist()
        if len(names) != len(set(names)) or APP_MEMBER not in names:
            raise ValueError("Base archive has duplicate members or lacks the app wheel")
        if sha(source.read(APP_MEMBER)) != file_sha(app_wheel):
            raise ValueError("App wheel differs from the reviewed base member")
        manifest_raw = source.read("release-manifest.json")
        manifest = json.loads(manifest_raw)
        legal = json.loads(source.read("notices-and-source/legal-index.json"))
        app_rows = [row for row in legal["packages"] if row.get("normalized_name") == "autoclip"]
        if len(app_rows) != 1 or app_rows[0]["sha256"] != file_sha(app_wheel):
            raise ValueError("App legal row does not match the reviewed wheel")

        replacements = {name: source_snapshot[name] for name in
                        ("build-native-from-source.ps1", "Prepare-AutoClipOfflineCache.ps1")}
        app_row = app_rows[0]
        font_members = sorted(name for name in wheel.namelist() if FONT_NOTICE.fullmatch(name))
        if not font_members or not any(name.endswith("README.md") for name in font_members):
            raise ValueError("App wheel lacks its font license map")
        if len([name for name in font_members if name.endswith("-OFL.txt")]) != 4:
            raise ValueError("Expected the four reviewed app font notices")
        for name in font_members:
            data = wheel.read(name)
            member = f"notices-and-source/wheel-notices/{app_wheel.name}/{name}"
            if member in names:
                raise ValueError(f"Base already contains font sidecar: {member}")
            replacements[member] = data
            app_row.setdefault("legal_sha256", {})[name] = sha(data)
            for key, value in (
                ("legal_files", name),
                ("verified_sidecar_copies", member),
            ):
                if value not in app_row.setdefault(key, []):
                    app_row[key].append(value)
            for location in (f"{APP_MEMBER}!/{name}", member):
                if location not in app_row.setdefault("fulfillment_locations", []):
                    app_row["fulfillment_locations"].append(location)
        for key in ("legal_files", "verified_sidecar_copies", "fulfillment_locations"):
            app_row[key].sort()

        base_commit = manifest["native_build"].get("runtime_commit")
        manifest["native_build"]["runtime_commit"] = None
        manifest["native_build"]["runtime_base_commit"] = base_commit
        manifest["native_build"]["candidate_source_state"] = "local_uncommitted_snapshot"
        legal["v24_base_archive_sha256"] = expected_base_hash
        legal["candidate_source_state"] = "local_uncommitted_snapshot"
        replacements["notices-and-source/legal-index.json"] = encoded(legal)
        inventory = source.read("notices-and-source/MANIFEST.md").decode("utf-8")
        replacements["notices-and-source/MANIFEST.md"] = (
            inventory.rstrip() + "\n\n## " + new_release_id + " local engineering snapshot\n\n"
            "The app's four OFL texts and font map are indexed and copied into wheel-notices. "
            "oneDNN's optional Python probe uses the controlled build interpreter. "
            "Optional NVIDIA wheels use the verified publisher cache. "
            "The source snapshot is local and uncommitted; this candidate is not release eligible.\n"
        ).encode("utf-8")
        provenance = {
            "schema_version": 1,
            "source_state": "local_uncommitted_snapshot",
            "base_archive_sha256": expected_base_hash,
            "runtime_base_commit": base_commit,
            "app_wheel_sha256": file_sha(app_wheel),
            "source_file_sha256": {name: sha(data) for name, data in source_snapshot.items()},
        }
        replacements["notices-and-source/build-provenance.json"] = encoded(provenance)
        replacements["notices-and-source/build-provenance/update.ps1"] = source_snapshot["update.ps1"]
        replacements["notices-and-source/build-provenance/build-source-routed-release.py"] = source_snapshot[
            "scripts/build-source-routed-release.py"
        ]
        replacements["notices-and-source/build-provenance/build-v24-from-v23.py"] = Path(__file__).read_bytes()
        replacements["notices-and-source/build-provenance/Prepare-AutoClipOfflineCache.ps1"] = source_snapshot[
            "Prepare-AutoClipOfflineCache.ps1"
        ]

        indexed = {row["path"]: row for row in manifest["files"]}
        for name, data in replacements.items():
            indexed[name] = {"path": name, "bytes": len(data), "sha256": sha(data)}
        manifest["files"] = [indexed[name] for name in sorted(indexed)]
        manifest_bytes = encoded(manifest)
        with zipfile.ZipFile(output, "w") as target:
            for entry in source.infolist():
                data = manifest_bytes if entry.filename == "release-manifest.json" else replacements.pop(
                    entry.filename, None
                )
                if data is None:
                    data = source.read(entry.filename)
                target.writestr(entry, data)
            for name, data in sorted(replacements.items()):
                entry = zipfile.ZipInfo(name, (2026, 9, 27, 0, 0, 0))
                entry.compress_type = zipfile.ZIP_DEFLATED
                target.writestr(entry, data)

    installer = old_installer.read_text(encoding="utf-8")
    installer = replace_once(installer, expected_base_hash, file_sha(output))
    installer = replace_once(installer, sha(manifest_raw), sha(manifest_bytes))
    installer = replace_once(installer, old_release_id, new_release_id)
    installer = replace_once(installer, "-Offline:$OfflinePublisherCache",
                             "-Offline:$OfflinePublisherCache -InstallNvidiaGpu:$InstallNvidiaGpu")
    new_installer.write_text(installer, encoding="utf-8")
    return {
        "archive": str(output),
        "archive_sha256": file_sha(output),
        "manifest_sha256": sha(manifest_bytes),
        "installer_sha256": file_sha(new_installer),
        "release_id": new_release_id,
        "source_state": "local_uncommitted_snapshot",
    }


def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--v23", type=Path, required=True)
    parser.add_argument("--app-wheel", type=Path, required=True)
    parser.add_argument("--v23-installer", type=Path, required=True)
    parser.add_argument("--archive", type=Path, required=True)
    parser.add_argument("--installer", type=Path, required=True)
    parser.add_argument("--release-id", required=True)
    args = parser.parse_args()
    runtime = Path(__file__).resolve().parents[1]
    snapshot = {name: (runtime / name).read_bytes() for name in SNAPSHOT_NAMES}
    result = derive(
        args.v23, args.app_wheel, args.v23_installer, args.archive, args.installer,
        expected_base_hash=V23_ARCHIVE_SHA256,
        old_release_id=V23_RELEASE_ID,
        new_release_id=args.release_id,
        source_snapshot=snapshot,
    )
    print(json.dumps(result, indent=2))


if __name__ == "__main__":
    main()
