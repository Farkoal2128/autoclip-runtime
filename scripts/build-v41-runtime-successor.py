"""Make an unpublished metadata review successor of the exact v41 r18 ZIP.

All executable, wheel, native, source, legal, SBOM and prerequisite bytes are
carried forward. This does not turn a focused review into release approval.
"""

import argparse
import hashlib
import json
import subprocess
import zipfile
from pathlib import Path, PurePosixPath


STATUS_PATH = "notices-and-source/review/current-successor-status.json"
AUX_PATH = "notices-and-source/sbom-packet-manifest.json"
R18_BASE_SHA = "31414e7b25beb51f03f809f12d8be713bc6385ce155067d077d69267c770c8e8"
R18_STANDALONE_SHA = "4bf02d79ea62b4ef393f25643d7923a08448d6263f6354ab4a3e393d7a12617e"
REVIEW_NAMES = {
    "r14-r02": "FriBiDi replacement route only",
    "r15-r03": "Pillow AVIF child notice association only",
    "r17-continuity": "exact r17 continuity at reviewed scope",
    "r17-addendum": "exact r17 addendum at reviewed scope",
    "r18-continuity": "r18 recovery and narrow byte/source continuity; historical builder invocation qualified",
}


def sha(data):
    return hashlib.sha256(data).hexdigest()


def encoded(value):
    return (json.dumps(value, indent=2) + "\n").encode()


def source_matches_commit(committed, worktree):
    if worktree == committed:
        return True
    remainder = worktree.replace(b"\r\n", b"")
    return b"\r" not in remainder and b"\n" not in remainder and worktree.replace(b"\r\n", b"\n") == committed


def safe_names(names):
    if len(names) != len(set(n.casefold() for n in names)):
        raise ValueError("Duplicate or case-colliding ZIP members")
    for name in names:
        path = PurePosixPath(name)
        if not name or "\\" in name or name.startswith("/") or ":" in name or any(part in ("", ".", "..") for part in name.split("/")) or path.is_absolute():
            raise ValueError("Unsafe ZIP member: " + name)


def verified_rows(archive, rows, *, expected):
    names = archive.namelist()
    if set(names) != set(expected) | {row["path"] for row in rows}:
        raise ValueError("Manifest membership mismatch")
    if len(rows) != len({row["path"].casefold() for row in rows}):
        raise ValueError("Duplicate manifest rows")
    for row in rows:
        data = archive.read(row["path"])
        if len(data) != row["bytes"] or sha(data) != row["sha256"]:
            raise ValueError("Manifest hash mismatch: " + row["path"])


def replace_once(data, old, new):
    if data.count(old) != 1:
        raise ValueError("Standalone pin/warning is not unique: " + old.decode())
    return data.replace(old, new)


def build(base, expected_base_sha, standalone, expected_standalone_sha,
          output, installer, release_id, source_revision, source_sha, reviews):
    partial = output.with_name(output.name + ".partial")
    if (output.exists() or installer.exists() or partial.exists()
            or len({path.resolve() for path in (base, standalone, output, installer, partial)}) != 5):
        raise ValueError("Refusing to replace immutable input/output")
    if set(reviews) != set(REVIEW_NAMES) or not release_id or "local-test" in release_id:
        raise ValueError("Exact review set and distinct successor ID required")
    base_bytes = base.read_bytes()
    standalone_bytes = standalone.read_bytes()
    if sha(base_bytes) != expected_base_sha or sha(standalone_bytes) != expected_standalone_sha:
        raise ValueError("Exact r18 base ZIP or standalone differs")
    with zipfile.ZipFile(base) as source:
        members = source.infolist()
        safe_names([member.filename for member in members])
        if any(member.is_dir() or member.external_attr >> 16 & 0o170000 == 0o120000 for member in members):
            raise ValueError("Directory or symlink ZIP member is unsupported")
        if source.testzip() is not None:
            raise ValueError("Base ZIP CRC failure")
        manifest = json.loads(source.read("release-manifest.json"))
        if manifest.get("schema_version") != 3 or len(manifest.get("publisher_wheels", [])) != 75 or len(manifest.get("external_assets", [])) != 3:
            raise ValueError("Exact v41 r18 inventory shape differs")
        verified_rows(source, manifest["files"], expected={"release-manifest.json"})
        auxiliary = json.loads(source.read(AUX_PATH))
        if auxiliary.get("file_count") != len(auxiliary.get("files", [])):
            raise ValueError("Auxiliary count mismatch")
        for row in auxiliary["files"]:
            data = source.read(row["path"])
            if len(data) != row["bytes"] or sha(data) != row["sha256"]:
                raise ValueError("Auxiliary hash mismatch: " + row["path"])
        legal = json.loads(source.read("notices-and-source/legal-index.json"))
        provenance = json.loads(source.read("notices-and-source/build-provenance.json"))
        prior_review = json.loads(source.read("notices-and-source/review/dependency-app-review.json"))
        if ("UNPUBLISHABLE_LOCAL_TEST_ONLY" not in legal.get("decision", "")
                or provenance.get("dependency_app_successor", {}).get("publication_state") != "UNPUBLISHABLE_LOCAL_TEST_ONLY"
                or prior_review.get("local_test_only") is not True):
            raise ValueError("Historical r18 local-test state differs")

        additions = {}
        associations = []
        for label, description in REVIEW_NAMES.items():
            data = reviews[label].read_bytes()
            path = f"notices-and-source/review/scoped-decisions/{label}.md"
            if not data or path in source.namelist():
                raise ValueError("Missing or colliding scoped review: " + label)
            additions[path] = data
            associations.append({"label": label, "scope": description, "path": path,
                                 "bytes": len(data), "sha256": sha(data)})
        status = {
            "schema_version": 1,
            "publication_state": "UNPUBLISHABLE_REVIEW_PENDING",
            "release_id": release_id,
            "base_archive_sha256": expected_base_sha,
            "base_manifest_sha256": sha(source.read("release-manifest.json")),
            "base_standalone_sha256": expected_standalone_sha,
            "successor_builder_revision": source_revision,
            "successor_builder_sha256": source_sha,
            "review_evidence": associations,
            "scope": "Exact scoped decisions carried forward for unchanged bytes; new successor requires independent review. Historical r18 local-test and builder-generation qualifications remain in their original records. No release or publication approval.",
        }
        additions[STATUS_PATH] = encoded(status)
        if set(additions) & set(source.namelist()):
            raise ValueError("Successor metadata overwrites base member")
        auxiliary["files"] += [
            {"path": name, "bytes": len(data), "sha256": sha(data)} for name, data in sorted(additions.items())
        ]
        auxiliary["files"].sort(key=lambda row: row["path"])
        auxiliary["file_count"] = len(auxiliary["files"])
        changes = dict(additions)
        changes[AUX_PATH] = encoded(auxiliary)
        indexed = {row["path"]: row for row in manifest["files"]}
        for name, data in changes.items():
            indexed[name] = {"path": name, "bytes": len(data), "sha256": sha(data)}
        manifest["files"] = [indexed[name] for name in sorted(indexed)]
        changes["release-manifest.json"] = encoded(manifest)
        old_manifest_sha = sha(source.read("release-manifest.json"))

        output.parent.mkdir(parents=True, exist_ok=True)
        temp = partial
        try:
            with zipfile.ZipFile(temp, "w", zipfile.ZIP_DEFLATED, compresslevel=6) as target:
                for entry in members:
                    target.writestr(entry, changes.pop(entry.filename, source.read(entry.filename)))
                for name, data in sorted(changes.items()):
                    target.writestr(name, data)
            with zipfile.ZipFile(temp) as target:
                safe_names(target.namelist())
                verified_rows(target, manifest["files"], expected={"release-manifest.json"})
                for row in auxiliary["files"]:
                    raw = target.read(row["path"])
                    if len(raw) != row["bytes"] or sha(raw) != row["sha256"]:
                        raise ValueError("Successor auxiliary hash mismatch: " + row["path"])
            new_archive_sha = sha(temp.read_bytes())
            script = standalone_bytes
            for old, new in (
                (expected_base_sha, new_archive_sha),
                (old_manifest_sha, sha(encoded(manifest))),
                (b"v41-local-test-r18-resume-recovery", release_id.encode()),
                (b"UNPUBLISHABLE_LOCAL_TEST_ONLY: installer/updater qualification candidate.",
                 b"UNPUBLISHABLE_REVIEW_PENDING: see notices-and-source/review/current-successor-status.json; exact successor review and release acceptance are pending."),
            ):
                script = replace_once(script, old if isinstance(old, bytes) else old.encode(),
                                      new if isinstance(new, bytes) else new.encode())
            installer.parent.mkdir(parents=True, exist_ok=True)
            installer.write_bytes(script)
            temp.replace(output)
        except BaseException:
            temp.unlink(missing_ok=True)
            installer.unlink(missing_ok=True)
            raise
    return {"archive_sha256": sha(output.read_bytes()),
            "manifest_sha256": sha(encoded(manifest)),
            "standalone_sha256": sha(installer.read_bytes()),
            "publication_state": "UNPUBLISHABLE_REVIEW_PENDING"}


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    for name in ("base", "standalone", "output", "installer"):
        parser.add_argument("--" + name, type=Path, required=True)
    for name in ("expected-base-sha", "expected-standalone-sha", "release-id", "repo", "revision"):
        parser.add_argument("--" + name, required=True)
    for label in REVIEW_NAMES:
        parser.add_argument("--review-" + label, type=Path, required=True)
    args = vars(parser.parse_args())
    if (args["expected_base_sha"] != R18_BASE_SHA
            or args["expected_standalone_sha"] != R18_STANDALONE_SHA):
        raise ValueError("Only the exact reviewed r18 base identities are accepted")
    repo = Path(args["repo"])
    revision = subprocess.check_output(["git", "rev-parse", args["revision"]], cwd=repo, text=True).strip()
    committed = subprocess.check_output(["git", "show", revision + ":scripts/build-v41-runtime-successor.py"], cwd=repo)
    if not source_matches_commit(committed, Path(__file__).read_bytes()):
        raise ValueError("Builder working bytes differ from exact committed source")
    reviews = {label: args["review_" + label.replace("-", "_")] for label in REVIEW_NAMES}
    print(json.dumps(build(args["base"], args["expected_base_sha"], args["standalone"],
                           args["expected_standalone_sha"], args["output"], args["installer"],
                           args["release_id"], revision, sha(committed), reviews), indent=2))


if __name__ == "__main__":
    main()
