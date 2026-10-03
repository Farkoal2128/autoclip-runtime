"""Behavioral extraction checks; vendor fixture is opt-in and never redistributed."""
import hashlib
import importlib.util
import io
import json
import os
from pathlib import Path
import subprocess
import sys
import tarfile
import tempfile
import unittest
from unittest.mock import patch

ROOT = Path(__file__).resolve().parents[2]
HELPER = ROOT / "installer/extract-msys2-base.py"
NAME = "msys2-base-x86_64-20260611.tar.xz"
URL = "https://github.com/msys2/msys2-installer/releases/download/2026-06-11/" + NAME


def digest(data):
    return hashlib.sha256(data).hexdigest()


class ArchiveTests(unittest.TestCase):
    def setUp(self):
        spec = importlib.util.spec_from_file_location("msys_extract", HELPER)
        self.module = importlib.util.module_from_spec(spec)
        spec.loader.exec_module(self.module)
        # A short local test-owned root, never a host MSYS2 tree.
        self.temp = tempfile.TemporaryDirectory(prefix="ma-", dir=Path.cwd().anchor)
        self.addCleanup(self.temp.cleanup)
        self.work = Path(self.temp.name)
        self.parent = self.work / "target"
        self.parent.mkdir()
        self.archive = self.work / NAME
        self.manifest = self.work / "manifest.json"
        self.write_archive([])

    def write_archive(self, extras):
        with tarfile.open(self.archive, "w:xz") as stream:
            for name in ("msys64", "msys64/usr", "msys64/usr/bin"):
                row = tarfile.TarInfo(name); row.type = tarfile.DIRTYPE; row.mode = 0o755
                stream.addfile(row)
            row = tarfile.TarInfo("msys64/usr/bin/pacman-key")
            data = b"#!/bin/bash\necho fixture\n"; row.size = len(data); row.mode = 0o755
            stream.addfile(row, io.BytesIO(data))
            for row, data in extras:
                stream.addfile(row, io.BytesIO(data) if row.isfile() else None)
        self.record = {"identity": "MSYS2", "version": "20260611", "filename": NAME,
                       "artifact_kind": "archive", "archive_format": "tar.xz", "url": URL,
                       "delivery_classification": "DIRECT_RECIPIENT_DOWNLOAD",
                       "bytes": self.archive.stat().st_size,
                       "sha256": digest(self.archive.read_bytes())}
        self.document = {"schema_version": 1, "build_prerequisites": [self.record]}
        self.save_manifest()

    def save_manifest(self):
        self.manifest.write_text(json.dumps(self.document), encoding="utf-8")
        self.manifest_hash = digest(self.manifest.read_bytes())

    def extract(self):
        return self.module.extract_base(self.manifest, self.manifest_hash, self.archive, self.parent)

    def test_success_inventory_modes_and_injected_file(self):
        receipt = self.extract()
        self.assertEqual("VERIFIED_ARCHIVE_EXTRACTION", receipt["status"])
        self.assertEqual("COMPLETE", receipt["extraction_state"])
        self.assertEqual(1, receipt["file_count"])
        self.assertEqual(3, receipt["directory_count"])
        self.assertFalse(receipt["acl_verified"])
        self.assertFalse(receipt["signature_verified"])
        self.assertEqual("PENDING_NATIVE_WINDOWS_VERIFICATION", receipt["executable_mode_qualification"])
        target = self.parent / "msys64/usr/bin/pacman-key"
        row = next(row for row in receipt["inventory"] if row["path"] == "msys64/usr/bin/pacman-key")
        self.assertEqual(0o755, row["mode"])
        self.assertEqual(digest(target.read_bytes()), row["sha256"])
        self.module.verify_inventory(self.parent, receipt["inventory"])
        (target.parent / "injected.exe").write_bytes(b"unexpected")
        with self.assertRaisesRegex(ValueError, "inventory"):
            self.module.verify_inventory(self.parent, receipt["inventory"])
        (target.parent / "injected.exe").unlink()
        target.write_bytes(b"changed")
        with self.assertRaisesRegex(ValueError, "inventory"):
            self.module.verify_inventory(self.parent, receipt["inventory"])

    def test_all_members_validated_before_any_write(self):
        names = ["../escape", "/msys64/absolute", "C:/drive", "other/file", "msys64/../escape",
                 "msys64//file", "msys64/./file", "msys64\\file", "msys64/a:b", "msys64/a.",
                 "msys64/a ", "msys64/CON.txt", "msys64/lpt1", "msys64/COM¹.txt", "msys64/a?",
                 "msys64/a\x01", "msys64/usr/bin/PACMAN-KEY", "msys64/usr/bin/pacman-key",
                 "msys64/missing/file", "msys64/CON .txt", "msys64/CONIN$",
                 "msys64/usr/bin/pacman-key/child"]
        for name in names:
            with self.subTest(name=name):
                row = tarfile.TarInfo(name); row.size = 1
                self.write_archive([(row, b"x")])
                with self.assertRaises(self.module.ExtractionFailure) as caught:
                    self.extract()
                self.assertEqual("NOT_STARTED", caught.exception.receipt["extraction_state"])
                self.assertEqual([], list(self.parent.iterdir()))

    def test_links_devices_and_sparse_rejected_before_write(self):
        for kind in (tarfile.SYMTYPE, tarfile.LNKTYPE, tarfile.CHRTYPE, tarfile.BLKTYPE,
                     tarfile.FIFOTYPE, tarfile.GNUTYPE_SPARSE):
            with self.subTest(kind=kind):
                row = tarfile.TarInfo("msys64/bad"); row.type = kind; row.linkname = "usr/bin/pacman-key"
                self.write_archive([(row, b"")])
                with self.assertRaises(self.module.ExtractionFailure):
                    self.extract()
                self.assertEqual([], list(self.parent.iterdir()))

    def test_setup_hash_schema_identity_and_archive_pin_fail_closed(self):
        changes = [{"schema_version": 2}, {"version": "wrong"}, {"filename": "base.exe"},
                   {"delivery_classification": "BLOCKED"}, {"artifact_kind": "installer"},
                   {"archive_format": "zip"}, {"bytes": self.record["bytes"] + 1},
                   {"sha256": "0" * 64}, {"url": "https://example.com/"}]
        for change in changes:
            with self.subTest(change=change):
                self.write_archive([])
                (self.document if "schema_version" in change else self.record).update(change)
                self.save_manifest()
                with self.assertRaises(self.module.ExtractionFailure):
                    self.extract()
                self.assertEqual([], list(self.parent.iterdir()))
        self.write_archive([])
        self.manifest_hash = "0" * 64
        with self.assertRaises(self.module.ExtractionFailure): self.extract()
        self.document["build_prerequisites"].append(dict(self.record)); self.save_manifest()
        with self.assertRaises(self.module.ExtractionFailure): self.extract()

    def test_existing_destination_is_preserved(self):
        foreign = self.parent / "unrelated.txt"; foreign.write_bytes(b"keep")
        with self.assertRaises(self.module.ExtractionFailure): self.extract()
        self.assertEqual(b"keep", foreign.read_bytes())
        self.assertFalse((self.parent / "msys64").exists())

    def test_nonlocal_and_long_parent_rejected_without_writes(self):
        for candidate in (Path("relative"), Path("//server/share/root"),
                          self.work / ("x" * 110), self.work / "space parent"):
            with self.subTest(parent=candidate):
                self.parent = candidate
                with self.assertRaises(self.module.ExtractionFailure) as caught:
                    self.extract()
                self.assertEqual("NOT_STARTED", caught.exception.receipt["extraction_state"])

    def test_reparse_ancestor_is_rejected(self):
        outside = self.work / "outside"; outside.mkdir()
        junction = self.work / "junction"
        if os.name == "nt":
            subprocess.run(["cmd", "/d", "/c", "mklink", "/J", str(junction), str(outside)],
                           check=True, capture_output=True)
        else:
            junction.symlink_to(outside, target_is_directory=True)
        self.addCleanup(junction.unlink if os.name != "nt" else junction.rmdir)
        self.parent = junction
        with self.assertRaises(self.module.ExtractionFailure): self.extract()
        self.assertEqual([], list(outside.iterdir()))

    def test_partial_failure_receipt_does_not_clean_or_claim_complete(self):
        with patch.object(self.module, "verify_inventory", side_effect=OSError("interrupted verification")):
            with self.assertRaises(self.module.ExtractionFailure) as caught:
                self.extract()
        self.assertEqual("PARTIAL", caught.exception.receipt["extraction_state"])
        self.assertEqual(str(self.parent / "msys64"), caught.exception.receipt["owned_root"])
        self.assertTrue((self.parent / "msys64/usr/bin/pacman-key").is_file())

    def test_archive_mutation_after_authenticated_read_fails_partial(self):
        original = self.module.os.utime
        mutated = False
        def mutate(target, times):
            nonlocal mutated
            original(target, times)
            if not mutated:
                with self.archive.open("ab") as stream:
                    stream.write(b"changed")
                mutated = True
        with patch.object(self.module.os, "utime", side_effect=mutate):
            with self.assertRaises(self.module.ExtractionFailure) as caught:
                self.extract()
        self.assertEqual("PARTIAL", caught.exception.receipt["extraction_state"])
        self.assertIn("changed during extraction", str(caught.exception))

    def test_size_limits_and_duplicate_json_rejected(self):
        row = tarfile.TarInfo("msys64/huge")
        row.size = self.module.MAX_FILE_BYTES + 1
        # A header alone suffices; validation must reject its declaration before copying.
        with tarfile.open(self.archive, "w:xz") as stream:
            root = tarfile.TarInfo("msys64"); root.type = tarfile.DIRTYPE; stream.addfile(root)
            stream.addfile(row)
        self.record["bytes"] = self.archive.stat().st_size
        self.record["sha256"] = digest(self.archive.read_bytes()); self.save_manifest()
        with self.assertRaises(self.module.ExtractionFailure): self.extract()
        self.assertEqual([], list(self.parent.iterdir()))
        self.manifest.write_text('{"schema_version":1,"schema_version":1}', encoding="utf-8")
        self.manifest_hash = digest(self.manifest.read_bytes())
        with self.assertRaisesRegex(self.module.ExtractionFailure, "Duplicate manifest"):
            self.extract()

    def test_cli_failure_receipt_and_nonzero_exit(self):
        self.record["delivery_classification"] = "BLOCKED"; self.save_manifest()
        result = subprocess.run([sys.executable, "-I", "-B", str(HELPER), "--manifest", str(self.manifest),
                                 "--manifest-sha256", self.manifest_hash, "--archive", str(self.archive),
                                 "--parent", str(self.parent)], capture_output=True, text=True)
        self.assertEqual(1, result.returncode)
        self.assertEqual("NOT_STARTED", json.loads(result.stdout)["extraction_state"])

    def test_malformed_manifest_shapes_return_failure_receipts(self):
        for document in ([], None, {"schema_version": 1, "build_prerequisites": None},
                         {"schema_version": 1, "build_prerequisites": [None]}):
            with self.subTest(document=document):
                self.document = document; self.save_manifest()
                with self.assertRaises(self.module.ExtractionFailure) as caught:
                    self.extract()
                self.assertEqual("NOT_STARTED", caught.exception.receipt["extraction_state"])

    @unittest.skipUnless(os.environ.get("AUTOCLIP_TEST_MSYS2_ARCHIVE"), "explicit local vendor fixture required")
    def test_exact_official_archive(self):
        self.archive = Path(os.environ["AUTOCLIP_TEST_MSYS2_ARCHIVE"])
        self.record["bytes"] = 53555380
        self.record["sha256"] = "a2d047e8ee213c3c6a49a8de427eb1069df12207c0422ff1b3cbb5c905c34221"
        self.save_manifest()
        receipt = self.extract()
        self.assertEqual(15529, receipt["file_count"])
        self.assertEqual(1052, receipt["directory_count"])
        self.assertEqual(16581, len(receipt["inventory"]))
        self.assertEqual(288055390, sum(row.get("bytes", 0) for row in receipt["inventory"]))
        self.assertEqual(0o755, next(row["mode"] for row in receipt["inventory"]
                                    if row["path"] == "msys64/usr/bin/pacman-key"))


if __name__ == "__main__":
    unittest.main()
