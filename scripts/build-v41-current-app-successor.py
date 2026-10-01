"""Build an unpublished r19 successor with the reviewed current AutoClip wheel.

The r19 runtime and publisher selection remain unchanged. This creates a new
immutable artifact for exact review; it does not grant publication approval.
"""

import argparse
import copy
import hashlib
import json
import runpy
import subprocess
import zipfile
from pathlib import Path


R19_SHA = "ec8c926536ecd1457af3385d13a4c8c2cb7f10cd42e5cd84f08198ae522947c4"
R19_INSTALLER_SHA = "599d727efc4b8f99cf0198bdfb68ab5b92263b835a81f779651a80617c88c0db"
APP_SHA = "2237303b07233cc113f8c1b823b20671349eed8d96fa76b290e0920821dad303"
SOURCE_SHA = "0dc2195cbbfdb1667c24d155560536c5db57e496995f48de786842452354d423"
APP_COMMIT = "a7f3648a57a6822865b212f914263bc5c8745edc"
STATUS = "notices-and-source/review/current-successor-status.json"
AUX = "notices-and-source/sbom-packet-manifest.json"
APP_PATH = "wheelhouse/autoclip-0.1.0.dev0-py3-none-any.whl"
SOURCE_PATH = "notices-and-source/build-provenance/current/app-source.bundle"
RECEIPT_PATH = "notices-and-source/build-provenance/current/app-build-receipt.json"
APP_REVIEW = "notices-and-source/review/scoped-decisions/current-app-wheel.md"
R19_REVIEW = "notices-and-source/review/scoped-decisions/r19-continuity.md"


def sha(data):
    return hashlib.sha256(data).hexdigest()


def encoded(value):
    return (json.dumps(value, indent=2) + "\n").encode()


def source_matches_commit(committed, worktree):
    return committed == worktree or worktree.replace(b"\r\n", b"\n") == committed


def refresh_app_row(row, wheel):
    """Rebind the existing app route and notice/static maps to exact wheel bytes."""
    result = copy.deepcopy(row)
    with zipfile.ZipFile(wheel) as archive:
        names = archive.namelist()
        if len(names) != len(set(name.casefold() for name in names)) or archive.testzip():
            raise ValueError("App wheel membership or CRC differs")
        notices = {name: archive.read(name) for name in result["legal_files"]}
        result["legal_sha256"] = {name: sha(raw) for name, raw in notices.items()}
        result["data_assets"] = sorted(
            (set(result["data_assets"]) & set(names)) |
            {name for name in names if name.startswith("autoclip/static/assets/")
             and name.endswith((".js", ".css", ".ttf", ".otf", ".woff", ".woff2"))}
        )
        result["data_sha256"] = {name: sha(archive.read(name)) for name in result["data_assets"]}
        result["record_rows"] = len(names)
    raw = wheel.read_bytes()
    result["bytes"], result["sha256"] = len(raw), sha(raw)
    return result, notices


def replace_one(raw, old, new):
    if raw.count(old) != 1:
        raise ValueError("Standalone identity/status is not unique")
    return raw.replace(old, new)


def validate_archive(archive):
    names = archive.namelist()
    if len(names) != len(set(name.casefold() for name in names)):
        raise ValueError("Archive member collision")
    if any(not name or name.startswith("/") or "\\" in name or ":" in name
           or any(part in ("", ".", "..") for part in name.split("/"))
           or member.is_dir() or member.external_attr >> 16 & 0o170000 == 0o120000
           for name, member in zip(names, archive.infolist())):
        raise ValueError("Unsafe archive member")
    if archive.testzip():
        raise ValueError("Archive CRC failure")
    manifest = json.loads(archive.read("release-manifest.json"))
    rows = manifest["files"]
    if len(manifest["publisher_wheels"]) != 75 or len(manifest["external_assets"]) != 3:
        raise ValueError("r19 selection differs")
    if {row["path"] for row in rows} != set(names) - {"release-manifest.json"} or len(rows) != len(names)-1:
        raise ValueError("Outer manifest membership differs")
    for row in rows:
        raw = archive.read(row["path"])
        if len(raw) != row["bytes"] or sha(raw) != row["sha256"]:
            raise ValueError("Outer manifest hash differs: " + row["path"])
    aux = json.loads(archive.read(AUX))
    if aux["file_count"] != len(aux["files"]):
        raise ValueError("Auxiliary manifest count differs")
    for row in aux["files"]:
        raw = archive.read(row["path"])
        if len(raw) != row["bytes"] or sha(raw) != row["sha256"]:
            raise ValueError("Auxiliary manifest hash differs: " + row["path"])
    return manifest, aux


def build(base, standalone, wheel, bundle, app_review, r19_review,
          output, installer, release_id, builder_revision, builder_sha):
    paths = (base, standalone, wheel, bundle, app_review, r19_review, output, installer)
    if len({path.resolve() for path in paths}) != len(paths) or output.exists() or installer.exists():
        raise ValueError("Refusing input/output alias or existing immutable output")
    if not release_id or "local-test" in release_id:
        raise ValueError("Distinct review successor ID required")
    if sha(base.read_bytes()) != R19_SHA or sha(standalone.read_bytes()) != R19_INSTALLER_SHA:
        raise ValueError("Reviewed r19 input identity differs")
    if sha(wheel.read_bytes()) != APP_SHA or sha(bundle.read_bytes()) != SOURCE_SHA:
        raise ValueError("Reviewed app wheel or source bundle differs")
    if not app_review.read_bytes() or not r19_review.read_bytes():
        raise ValueError("Review evidence missing")
    validator = runpy.run_path(str(Path(__file__).with_name("validate-dependency-app-successor.py")))
    info = validator["verify_wheel"](wheel)
    if info["name"] != "autoclip" or info["sha256"] != APP_SHA:
        raise ValueError("Current app wheel identity differs")
    if APP_COMMIT not in subprocess.check_output(["git", "bundle", "list-heads", str(bundle)], text=True):
        raise ValueError("Current app source commit absent from bundle")
    with zipfile.ZipFile(base) as source:
        manifest, aux = validate_archive(source)
        old_status = json.loads(source.read(STATUS))
        if old_status["publication_state"] != "UNPUBLISHABLE_REVIEW_PENDING" or old_status["release_id"] != "v41-20260930-review-pending-r19":
            raise ValueError("Exact reviewed r19 current state differs")
        old_app = source.read(APP_PATH)
        if sha(old_app) != "8baa408fe6532ba7e0c2b1d1ef12dff182ca473bcb74af0cd02d051dce54816b":
            raise ValueError("r19 embedded app differs")
        legal = json.loads(source.read("notices-and-source/legal-index.json"))
        app_rows = [row for row in legal["packages"] if row["normalized_name"] == "autoclip"]
        if len(app_rows) != 1:
            raise ValueError("App legal row differs")
        new_row, notices = refresh_app_row(app_rows[0], wheel)
        if new_row["record_rows"] != info["record_rows"]:
            raise ValueError("App RECORD count differs")
        new_row["review_disposition"] = "scoped_app_wheel_continuity_supported"
        new_row["disposition"] = "pending_exact_successor_review"
        legal["packages"] = [new_row if row is app_rows[0] else row for row in legal["packages"]]
        legal["decision"] = "UNPUBLISHABLE_REVIEW_PENDING; current app wheel and source mapped; final exact release review pending"
        provenance = json.loads(source.read("notices-and-source/build-provenance.json"))
        provenance["app_wheel_sha256"] = APP_SHA
        provenance["current_app_successor"] = {
            "app_commit": APP_COMMIT, "app_wheel_sha256": APP_SHA,
            "app_source_bundle_sha256": SOURCE_SHA,
            "prior_app_wheel_sha256": sha(old_app),
            "publication_state": "UNPUBLISHABLE_REVIEW_PENDING",
            "historical_dependency_app_successor_unchanged": True,
        }
        receipt = {
            "schema_version": 1, "purpose": "review-pending current app wheel association",
            "app_commit": APP_COMMIT, "app_source_bundle_sha256": SOURCE_SHA,
            "app_wheel_filename": wheel.name, "app_wheel_bytes": wheel.stat().st_size,
            "app_wheel_sha256": APP_SHA, "independent_wheel_review_sha256": sha(app_review.read_bytes()),
        }
        status = {
            "schema_version": 1, "publication_state": "UNPUBLISHABLE_REVIEW_PENDING",
            "release_id": release_id, "base_archive_sha256": R19_SHA,
            "base_standalone_sha256": R19_INSTALLER_SHA,
            "current_app_wheel_sha256": APP_SHA, "current_app_commit": APP_COMMIT,
            "current_app_source_bundle_sha256": SOURCE_SHA,
            "app_review_sha256": sha(app_review.read_bytes()),
            "r19_review_sha256": sha(r19_review.read_bytes()),
            "successor_builder_revision": builder_revision,
            "successor_builder_sha256": builder_sha,
            "scope": "Current app clean-install successor pending independent exact-candidate and release review; historical r18/r19 provenance limits remain.",
        }
        changes = {
            APP_PATH: wheel.read_bytes(), SOURCE_PATH: bundle.read_bytes(),
            RECEIPT_PATH: encoded(receipt), STATUS: encoded(status),
            "notices-and-source/legal-index.json": encoded(legal),
            "notices-and-source/build-provenance.json": encoded(provenance),
            APP_REVIEW: app_review.read_bytes(), R19_REVIEW: r19_review.read_bytes(),
        }
        notice_prefix = "notices-and-source/wheel-notices/" + wheel.name + "/"
        for name, raw in notices.items():
            changes[notice_prefix + name] = raw
        if any(name in source.namelist() for name in (APP_REVIEW, R19_REVIEW)):
            raise ValueError("Review evidence path already exists")
        aux_rows = {row["path"]: row for row in aux["files"]}
        for name, raw in changes.items():
            if name in aux_rows or name in (APP_REVIEW, R19_REVIEW):
                aux_rows[name] = {"path": name, "bytes": len(raw), "sha256": sha(raw)}
        aux["files"] = [aux_rows[name] for name in sorted(aux_rows)]
        aux["file_count"] = len(aux["files"])
        changes[AUX] = encoded(aux)
        outer_rows = {row["path"]: row for row in manifest["files"]}
        for name, raw in changes.items():
            outer_rows[name] = {"path": name, "bytes": len(raw), "sha256": sha(raw)}
        manifest["files"] = [outer_rows[name] for name in sorted(outer_rows)]
        changes["release-manifest.json"] = encoded(manifest)
        script = standalone.read_bytes()
        for old, new in ((R19_SHA, "{ARCHIVE}"),
                         (sha(source.read("release-manifest.json")), sha(encoded(manifest))),
                         (old_status["release_id"], release_id)):
            if old != R19_SHA:
                script = replace_one(script, old.encode(), new.encode())
        output.parent.mkdir(parents=True, exist_ok=True)
        installer.parent.mkdir(parents=True, exist_ok=True)
        try:
            with zipfile.ZipFile(output, "w", zipfile.ZIP_DEFLATED, compresslevel=6) as target:
                for member in source.infolist():
                    target.writestr(member, changes.pop(member.filename, source.read(member.filename)))
                for name, raw in sorted(changes.items()):
                    target.writestr(name, raw)
            with zipfile.ZipFile(output) as target:
                validate_archive(target)
            script = replace_one(script, R19_SHA.encode(), sha(output.read_bytes()).encode())
            installer.write_bytes(script)
        except BaseException:
            output.unlink(missing_ok=True)
            installer.unlink(missing_ok=True)
            raise
    return {"archive_sha256": sha(output.read_bytes()),
            "manifest_sha256": sha(encoded(manifest)),
            "standalone_sha256": sha(installer.read_bytes()),
            "publication_state": "UNPUBLISHABLE_REVIEW_PENDING"}


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    for name in ("base", "standalone", "wheel", "bundle", "app-review", "r19-review", "output", "installer", "release-id", "repo", "revision"):
        parser.add_argument("--" + name, required=True, type=Path if name not in ("release-id", "revision") else str)
    args = vars(parser.parse_args())
    repo, revision = args.pop("repo"), args.pop("revision")
    committed = subprocess.check_output(["git", "show", revision + ":scripts/build-v41-current-app-successor.py"], cwd=repo)
    actual_revision = subprocess.check_output(["git", "rev-parse", revision], cwd=repo, text=True).strip()
    if not source_matches_commit(committed, Path(__file__).read_bytes()):
        raise ValueError("Builder working bytes differ from committed source")
    print(json.dumps(build(**{name.replace("-", "_"): value for name, value in args.items()},
                           builder_revision=actual_revision, builder_sha=sha(committed)), indent=2))


if __name__ == "__main__":
    main()
