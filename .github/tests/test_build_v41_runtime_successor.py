"""The review successor changes metadata, never operative runtime bytes."""

import hashlib
import importlib.util
import json
import tempfile
import unittest
import zipfile
from pathlib import Path


SCRIPT = Path(__file__).resolve().parents[2] / "scripts/build-v41-runtime-successor.py"
spec = importlib.util.spec_from_file_location("v41_successor", SCRIPT)
builder = importlib.util.module_from_spec(spec)
spec.loader.exec_module(builder)


def digest(data):
    return hashlib.sha256(data).hexdigest()


def encoded(value):
    return (json.dumps(value, indent=2) + "\n").encode()


class ReviewSuccessorTests(unittest.TestCase):
    def test_committed_builder_allows_windows_checkout_newlines_only(self):
        committed = b"first\nsecond\n"
        self.assertTrue(builder.source_matches_commit(committed, committed))
        self.assertTrue(builder.source_matches_commit(committed, b"first\r\nsecond\r\n"))
        self.assertFalse(builder.source_matches_commit(committed, b"first\r\nchanged\r\n"))
        self.assertFalse(builder.source_matches_commit(committed, b"first\r\nsecond\n"))
        self.assertFalse(builder.source_matches_commit(committed, b"first\rsecond\r\n"))

    def test_unsafe_or_colliding_base_members_are_rejected(self):
        for names in (("a/b", "a/B"), ("a/../b",), ("/absolute",), ("a\\b",)):
            with self.subTest(names=names), self.assertRaises(ValueError):
                builder.safe_names(names)

    def test_pending_review_successor_preserves_operative_bytes(self):
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory)
            base, target = root / "base.zip", root / "successor.zip"
            standalone, result_installer = root / "base.ps1", root / "successor.ps1"
            payload = {
                "wheelhouse/autoclip.whl": b"app unchanged",
                "notices-and-source/legal-index.json": encoded({"decision": "UNPUBLISHABLE_LOCAL_TEST_ONLY"}),
                "notices-and-source/build-provenance.json": encoded({"dependency_app_successor": {"publication_state": "UNPUBLISHABLE_LOCAL_TEST_ONLY"}}),
                "notices-and-source/review/dependency-app-review.json": encoded({"local_test_only": True}),
                "install-source-build.ps1": b"old disabled installer stub",
            }
            aux = {"schema_version": 1, "file_count": 1, "files": [
                {"path": "notices-and-source/legal-index.json", "bytes": len(payload["notices-and-source/legal-index.json"]),
                 "sha256": digest(payload["notices-and-source/legal-index.json"])}]}
            payload["notices-and-source/sbom-packet-manifest.json"] = encoded(aux)
            manifest = {"schema_version": 3, "files": [
                {"path": name, "bytes": len(data), "sha256": digest(data)} for name, data in sorted(payload.items())],
                "publisher_wheels": [{"filename": f"wheel{i}.whl", "sha256": f"{i:064x}"} for i in range(75)],
                "external_assets": [{"filename": n} for n in ("openblas", "vc", "cublas")],
                "native_build": {"runtime_commit": "r18-original"}}
            with zipfile.ZipFile(base, "w") as archive:
                for name, data in payload.items():
                    archive.writestr(name, data)
                archive.writestr("release-manifest.json", encoded(manifest))
            old_manifest_hash = digest(encoded(manifest))
            standalone.write_text(
                f"$expectedArchiveSha256 = '{digest(base.read_bytes())}'\n"
                f"$expectedManifestSha256 = '{old_manifest_hash}'\n"
                "$releaseId = 'v41-local-test-r18-resume-recovery'\n"
                "Write-Host 'UNPUBLISHABLE_LOCAL_TEST_ONLY: installer/updater qualification candidate.'\n",
                encoding="utf-8")
            evidence = {}
            for label in builder.REVIEW_NAMES:
                path = root / f"{label}.md"
                path.write_text(label, encoding="utf-8")
                evidence[label] = path
            with self.assertRaisesRegex(ValueError, "Exact r18 base"):
                builder.build(base, "0" * 64, standalone, digest(standalone.read_bytes()),
                              root / "wrong.zip", root / "wrong.ps1", "v41-r19-review-pending",
                              "f" * 40, "a" * 64, evidence)
            self.assertFalse((root / "wrong.zip").exists())
            for alias in (root / "collision", root / "sub" / ".." / "collision",
                          root / "collision.partial"):
                with self.subTest(alias=alias), self.assertRaisesRegex(ValueError, "replace immutable input/output"):
                    builder.build(base, digest(base.read_bytes()), standalone,
                                  digest(standalone.read_bytes()), root / "collision",
                                  alias, "v41-r19-review-pending",
                                  "f" * 40, "a" * 64, evidence)
            builder.build(base, digest(base.read_bytes()), standalone,
                          digest(standalone.read_bytes()), target, result_installer,
                          "v41-r19-review-pending", "f" * 40, "a" * 64, evidence)
            with zipfile.ZipFile(base) as old, zipfile.ZipFile(target) as new:
                for name in old.namelist():
                    if name not in ("release-manifest.json", "notices-and-source/sbom-packet-manifest.json"):
                        self.assertEqual(old.read(name), new.read(name), name)
                status = json.loads(new.read(builder.STATUS_PATH))
                self.assertEqual(status["publication_state"], "UNPUBLISHABLE_REVIEW_PENDING")
                self.assertEqual(status["base_archive_sha256"], digest(base.read_bytes()))
                self.assertEqual(len(status["review_evidence"]), len(evidence))
                new_manifest = json.loads(new.read("release-manifest.json"))
                self.assertEqual(new_manifest["publisher_wheels"], manifest["publisher_wheels"])
                self.assertEqual(new_manifest["external_assets"], manifest["external_assets"])
                self.assertEqual(new_manifest["native_build"], manifest["native_build"])
                self.assertEqual(set(new.namelist()), {row["path"] for row in new_manifest["files"]} | {"release-manifest.json"})
                for row in new_manifest["files"]:
                    self.assertEqual(digest(new.read(row["path"])), row["sha256"])
            text = result_installer.read_text(encoding="utf-8")
            self.assertIn("UNPUBLISHABLE_REVIEW_PENDING", text)
            self.assertIn(digest(target.read_bytes()), text)
            self.assertNotIn("UNPUBLISHABLE_LOCAL_TEST_ONLY", text)


if __name__ == "__main__":
    unittest.main()
