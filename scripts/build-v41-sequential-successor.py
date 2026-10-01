"""Replace r21's app wheel with the sequential-only app in an unpublished successor."""

import argparse
import copy
import json
import runpy
import subprocess
import zipfile
from pathlib import Path


BASE_SHA = "a4e035d42878eb6e89ed20e5806abeb2a372479164e042662d346f2dc5921195"
STANDALONE_SHA = "039d8fd145c2bfb6b7a9559d5714707116fadb8837e8528e110642dddec34b86"
WHEEL_SHA = "928a94c8f536d63dcdfe8c7b20891140a9bab404382ac44969ec28a0525a0754"
SOURCE_SHA = "685584851c1cfa20c8d4319c107e841ec6b94b905394b0382e4a9d2ad97f8e24"
APP_COMMIT = "d63a8b0501d2ba94cef37b8dac30694d90b0fff1"
BASE_RELEASE = "v41-20261001-review-pending-r21-current-app"
RELEASE = "v41-20261001-review-pending-r22-sequential"
APP = "wheelhouse/autoclip-0.1.0.dev0-py3-none-any.whl"
SOURCE = "notices-and-source/build-provenance/current/app-source.bundle"
RECEIPT = "notices-and-source/build-provenance/current/app-build-receipt.json"
STATUS = "notices-and-source/review/current-successor-status.json"
AUX = "notices-and-source/sbom-packet-manifest.json"
LEGAL = "notices-and-source/legal-index.json"
PROVENANCE = "notices-and-source/build-provenance.json"


def helpers():
    return runpy.run_path(str(Path(__file__).with_name("build-v41-current-app-successor.py")))


def pending_app_row(row):
    updated = copy.deepcopy(row)
    updated["review_disposition"] = "pending_exact_new_app_wheel_review"
    updated["disposition"] = "pending_exact_successor_review"
    return updated


def build(base, standalone, wheel, bundle, output, installer, revision, builder_sha):
    h = helpers()
    sha, encoded = h["sha"], h["encoded"]
    paths = [base, standalone, wheel, bundle, output, installer]
    if len({path.resolve() for path in paths}) != len(paths) or output.exists() or installer.exists():
        raise ValueError("Refusing input/output alias or existing immutable output")
    if (sha(base.read_bytes()) != BASE_SHA or sha(standalone.read_bytes()) != STANDALONE_SHA
            or sha(wheel.read_bytes()) != WHEEL_SHA or sha(bundle.read_bytes()) != SOURCE_SHA):
        raise ValueError("Pinned r21 or new app input identity differs")
    info = runpy.run_path(str(Path(__file__).with_name("validate-dependency-app-successor.py")))["verify_wheel"](wheel)
    if info["name"] != "autoclip" or info["sha256"] != WHEEL_SHA:
        raise ValueError("New app wheel RECORD or identity differs")
    if APP_COMMIT not in subprocess.check_output(["git", "bundle", "list-heads", str(bundle)], text=True):
        raise ValueError("New app source commit absent from bundle")
    with zipfile.ZipFile(base) as source:
        manifest, aux = h["validate_archive"](source)
        status = json.loads(source.read(STATUS))
        if status["release_id"] != BASE_RELEASE or status["publication_state"] != "UNPUBLISHABLE_REVIEW_PENDING":
            raise ValueError("r21 status differs")
        old_manifest_sha = sha(source.read("release-manifest.json"))
        old_app = source.read(APP)
        if sha(old_app) != status["current_app_wheel_sha256"]:
            raise ValueError("r21 app wheel status differs")
        legal = json.loads(source.read(LEGAL))
        rows = [row for row in legal["packages"] if row["normalized_name"] == "autoclip"]
        if len(rows) != 1 or rows[0]["sha256"] != sha(old_app):
            raise ValueError("r21 app legal row differs")
        new_row, notices = h["refresh_app_row"](rows[0], wheel)
        new_row = pending_app_row(new_row)
        if new_row["record_rows"] != info["record_rows"]:
            raise ValueError("New app RECORD count differs")
        legal["packages"] = [new_row if row is rows[0] else row for row in legal["packages"]]
        legal["decision"] = "UNPUBLISHABLE_REVIEW_PENDING; sequential-only app wheel mapped; exact new wheel and release review pending"
        provenance = json.loads(source.read(PROVENANCE))
        provenance["app_wheel_sha256"] = WHEEL_SHA
        provenance["current_app_successor"] = {
            "app_commit": APP_COMMIT, "app_wheel_sha256": WHEEL_SHA,
            "app_source_bundle_sha256": SOURCE_SHA,
            "prior_app_wheel_sha256": sha(old_app),
            "publication_state": "UNPUBLISHABLE_REVIEW_PENDING",
            "prior_app_review_scope": "historical r21 wheel only; exact new wheel review pending",
            "historical_dependency_app_successor_unchanged": True,
        }
        receipt = {
            "schema_version": 1, "purpose": "review-pending sequential-only app wheel association",
            "app_commit": APP_COMMIT, "app_source_bundle_sha256": SOURCE_SHA,
            "app_wheel_filename": wheel.name, "app_wheel_bytes": wheel.stat().st_size,
            "app_wheel_sha256": WHEEL_SHA,
            "independent_wheel_review_status": "pending",
        }
        new_status = {
            "schema_version": 1, "publication_state": "UNPUBLISHABLE_REVIEW_PENDING",
            "release_id": RELEASE, "base_archive_sha256": BASE_SHA,
            "base_standalone_sha256": STANDALONE_SHA,
            "current_app_wheel_sha256": WHEEL_SHA, "current_app_commit": APP_COMMIT,
            "current_app_source_bundle_sha256": SOURCE_SHA,
            "current_app_review_status": "pending",
            "prior_app_review_sha256": status["app_review_sha256"],
            "successor_builder_revision": revision,
            "successor_builder_sha256": builder_sha,
            "scope": "Sequential-only current app; exact new wheel and successor review pending. r21 decisions carry only on unchanged bytes.",
        }
        changes = {APP: wheel.read_bytes(), SOURCE: bundle.read_bytes(),
                   RECEIPT: encoded(receipt), STATUS: encoded(new_status),
                   LEGAL: encoded(legal), PROVENANCE: encoded(provenance)}
        notice_prefix = "notices-and-source/wheel-notices/" + wheel.name + "/"
        for name, raw in notices.items():
            changes[notice_prefix + name] = raw
        aux_rows = {row["path"]: row for row in aux["files"]}
        for name, raw in changes.items():
            if name in aux_rows:
                aux_rows[name] = {"path": name, "bytes": len(raw), "sha256": sha(raw)}
        aux["files"] = [aux_rows[name] for name in sorted(aux_rows)]
        aux["file_count"] = len(aux["files"])
        changes[AUX] = encoded(aux)
        outer_rows = {row["path"]: row for row in manifest["files"]}
        for name, raw in changes.items():
            if name not in outer_rows:
                raise ValueError("Unexpected new archive member: " + name)
            outer_rows[name] = {"path": name, "bytes": len(raw), "sha256": sha(raw)}
        manifest["files"] = [outer_rows[name] for name in sorted(outer_rows)]
        changes["release-manifest.json"] = encoded(manifest)
        output.parent.mkdir(parents=True, exist_ok=True)
        installer.parent.mkdir(parents=True, exist_ok=True)
        try:
            with zipfile.ZipFile(output, "w", zipfile.ZIP_DEFLATED, compresslevel=6) as target:
                for member in source.infolist():
                    target.writestr(member, changes.pop(member.filename, source.read(member.filename)))
            if changes:
                raise ValueError("Unexpected omitted changes: " + ", ".join(changes))
            with zipfile.ZipFile(output) as target:
                h["validate_archive"](target)
            script = standalone.read_bytes()
            for old, new in ((BASE_SHA, sha(output.read_bytes())),
                             (old_manifest_sha, sha(encoded(manifest))),
                             (BASE_RELEASE, RELEASE)):
                script = h["replace_one"](script, old.encode(), new.encode())
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
    for name in ("base", "standalone", "wheel", "bundle", "output", "installer", "repo"):
        parser.add_argument("--" + name, required=True, type=Path)
    parser.add_argument("--revision", required=True)
    args = parser.parse_args()
    committed = subprocess.check_output(
        ["git", "show", args.revision + ":scripts/build-v41-sequential-successor.py"], cwd=args.repo)
    h = helpers()
    if not h["source_matches_commit"](committed, Path(__file__).read_bytes()):
        raise ValueError("Builder working bytes differ from committed source")
    revision = subprocess.check_output(["git", "rev-parse", args.revision], cwd=args.repo, text=True).strip()
    print(json.dumps(build(args.base, args.standalone, args.wheel, args.bundle,
                           args.output, args.installer, revision, h["sha"](committed)), indent=2))


if __name__ == "__main__":
    main()
