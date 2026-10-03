"""Standalone CPU staging uses authentic ZIP/RECORD checks, never native execution."""

import base64
import csv
import hashlib
import importlib.util
import io
import json
import tempfile
import unittest
import zipfile
from pathlib import Path
from types import SimpleNamespace
from unittest.mock import patch


ROOT = Path(__file__).resolve().parents[2]
SCRIPT = ROOT / "installer/install-cpu-native-artifact.py"
WHEELS = ("av-18.1.0-cp311-abi3-win_amd64.whl", "ctranslate2-4.8.2-cp311-cp311-win_amd64.whl")


def sha(data):
    return hashlib.sha256(data).hexdigest()


def wheel(package):
    files = {package + "/native.pyd": b"MZsynthetic native extension"}
    if package == "av":
        for library in ("avcodec-62", "avdevice-62", "avfilter-11", "avformat-62", "avutil-60", "swresample-6", "swscale-9"):
            files["av.libs/" + library + "-fixture.dll"] = b"MZsynthetic FFmpeg DLL"
    else:
        files["ctranslate2/ctranslate2.dll"] = b"MZsynthetic CT2 DLL"
    record = package + "-1.dist-info/RECORD"
    rows = [[name, "sha256=" + base64.urlsafe_b64encode(hashlib.sha256(data).digest()).rstrip(b"=").decode(), str(len(data))] for name, data in files.items()]
    rows.append([record, "", ""])
    stream = io.StringIO(newline="")
    csv.writer(stream).writerows(rows)
    files[record] = stream.getvalue().encode()
    stream = io.BytesIO()
    with zipfile.ZipFile(stream, "w") as archive:
        for name, data in files.items():
            archive.writestr(name, data)
    return stream.getvalue()


class CpuInstallTests(unittest.TestCase):
    def setUp(self):
        self.assertTrue(SCRIPT.is_file(), "Standalone CPU artifact staging helper absent")
        spec = importlib.util.spec_from_file_location("cpu_native_install", SCRIPT)
        self.module = importlib.util.module_from_spec(spec)
        spec.loader.exec_module(self.module)
        self.temp = tempfile.TemporaryDirectory()
        self.addCleanup(self.temp.cleanup)
        root = Path(self.temp.name)
        self.args = SimpleNamespace(archive=root / "cpu.zip", archive_sha256="", archive_bytes=0,
                                    runtime_id="autoclip-cpu-test", wheelhouse=root / "wheels", source_output=root / "source")
        config = b"".join(f"!CONFIG_{feature}=yes\n".encode() for feature in ("GPL", "NONFREE", "LIBX264", "LIBX265"))
        self.payload = {"wheels/" + filename: wheel(package) for filename, package in zip(WHEELS, ("av", "ctranslate2"))}
        self.payload.update({"build/ffmpeg-config.mak": config,
                             "build/ffmpeg-config.h": b"".join(f"#define CONFIG_{feature} 0\n".encode() for feature in ("GPL", "NONFREE", "LIBX264", "LIBX265")),
                             "build/ffmpeg-config.log": b"--disable-autodetect --enable-shared --disable-static --disable-gpl --disable-nonfree --disable-libx264 --disable-libx265\n",
                             "sources/provenance.json": b'{"producer":"synthetic fixture"}',
                             "sources/LICENSE": b"Original fixture source notice\n",
                             "sources/source.c": b"/* complete fixture source */\n"})
        self.receipt = {"profile": "cpu", "install_nvidia_gpu": False,
                        "ffmpeg_source_sha256": "464beb5e7bf0c311e68b45ae2f04e9cc2af88851abb4082231742a74d97b524c",
                        "pyav_source_sha256": "47bfc286e1bc9de7ab4681fc2b575cd2460a66919d31ffe1bd5aa54fae531a28",
                        "onednn_commit": "64f6bcbcbab628e96f33a62c3e975f8535a7bde4",
                        "ctranslate2_commit": "d44d2d069eb88c7b7804da864c10c201501cb4a9",
                        "ffmpeg_config_sha256": sha(config),
                        "cmake_arguments": ["-DWITH_CUDA=OFF", "-DWITH_CUDNN=OFF", "-DWITH_MKL=OFF", "-DWITH_OPENBLAS=ON", "-DOPENMP_RUNTIME=COMP", "-DWITH_DNNL=ON", "-DWITH_RUY=OFF", "-DWITH_FLASH_ATTN=OFF"]}
        self.associations = {"schema_version": 1, "components": [{"component": name, "source_paths": ["source.c"], "notice_paths": ["LICENSE"]} for name in ("ffmpeg", "pyav", "ctranslate2", "onednn")]}
        self.write_archive()

    def write_archive(self, manifest_changes=None, extra=None, changed=None):
        self.receipt["wheels"] = [{"filename": name, "bytes": len(self.payload["wheels/" + name]), "sha256": sha(self.payload["wheels/" + name])} for name in WHEELS]
        self.payload["build/native-build-receipt.json"] = json.dumps(self.receipt).encode()
        self.payload["sources/source-associations.json"] = json.dumps(self.associations).encode()
        self.manifest = {"schema_version": 1, "qualification": "UNQUALIFIED_CANDIDATE", "runtime_id": self.args.runtime_id,
                         "profile": "cpu", "platform": "win_x64", "python": "cp311", "producer_receipt": "build/native-build-receipt.json",
                         "provenance": "sources/provenance.json", "source_associations": self.associations,
                         "files": [{"path": name, "bytes": len(data), "sha256": sha(data)} for name, data in sorted(self.payload.items())]}
        self.manifest.update(manifest_changes or {})
        with zipfile.ZipFile(self.args.archive, "w") as archive:
            for name, data in self.payload.items():
                archive.writestr(name, (changed or {}).get(name, data))
            archive.writestr("native-artifact-manifest.json", json.dumps(self.manifest))
            for name, data in (extra or {}).items():
                archive.writestr(name, data)
        raw = self.args.archive.read_bytes()
        self.args.archive_bytes, self.args.archive_sha256 = len(raw), sha(raw)

    def assert_unstaged(self):
        self.assertFalse(self.args.wheelhouse.exists())
        self.assertFalse(self.args.source_output.exists())

    def test_extract_exact_wheels_source_and_receipt_then_preserve_retry(self):
        self.module.stage(self.args)
        for name in WHEELS:
            self.assertEqual((self.args.wheelhouse / name).read_bytes(), self.payload["wheels/" + name])
        for name, data in self.payload.items():
            if not name.startswith("wheels/"):
                self.assertEqual((self.args.source_output / name).read_bytes(), data)
        marker = self.args.source_output / "native-artifact-manifest.json"
        self.assertEqual(json.loads(marker.read_bytes()), self.manifest)
        before = {path: (path.stat().st_mtime_ns, path.read_bytes()) for directory in (self.args.wheelhouse, self.args.source_output) for path in directory.rglob("*") if path.is_file()}
        self.module.stage(self.args)
        for path, identity in before.items():
            self.assertEqual((path.stat().st_mtime_ns, path.read_bytes()), identity)

    def test_pin_identity_profile_and_outer_member_mismatch_fail_without_outputs(self):
        for change in ({"schema_version": 2}, {"schema_version": True}, {"profile": "nvidia"}, {"platform": "linux"}, {"python": "cp312"}, {"runtime_id": "foreign"}):
            with self.subTest(change=change):
                self.write_archive(manifest_changes=change)
                with self.assertRaises(ValueError):
                    self.module.stage(self.args)
                self.assert_unstaged()
        for kwargs in ({"extra": {"sources/extra.txt": b"foreign"}}, {"changed": {"sources/source.c": b"changed"}}):
            self.write_archive(**kwargs)
            with self.assertRaises(ValueError):
                self.module.stage(self.args)
            self.assert_unstaged()
        self.write_archive()
        self.args.archive_sha256 = "0" * 64
        with self.assertRaises(ValueError):
            self.module.stage(self.args)
        self.assert_unstaged()

    def test_receipt_and_inner_record_substitution_rejected_even_with_new_outer_pins(self):
        self.receipt["install_nvidia_gpu"] = True
        self.write_archive()
        with self.assertRaises(ValueError):
            self.module.stage(self.args)
        self.assert_unstaged()
        self.receipt["install_nvidia_gpu"] = False
        raw = self.payload["wheels/" + WHEELS[0]]
        out = io.BytesIO()
        with zipfile.ZipFile(io.BytesIO(raw)) as source, zipfile.ZipFile(out, "w") as target:
            for name in source.namelist():
                target.writestr(name, b"changed native bytes" if name.endswith("native.pyd") else source.read(name))
        self.payload["wheels/" + WHEELS[0]] = out.getvalue()
        self.write_archive()
        with self.assertRaises(ValueError):
            self.module.stage(self.args)
        self.assert_unstaged()

    def test_foreign_destination_or_changed_existing_file_rejected_before_mutation(self):
        self.args.source_output.mkdir()
        foreign = self.args.source_output / "foreign.txt"
        foreign.write_bytes(b"preserve me")
        with self.assertRaises(ValueError):
            self.module.stage(self.args)
        self.assertEqual(foreign.read_bytes(), b"preserve me")
        self.assertFalse(self.args.wheelhouse.exists())
        foreign.unlink()
        self.module.stage(self.args)
        target = self.args.wheelhouse / WHEELS[0]
        target.write_bytes(b"changed existing data")
        with self.assertRaises(ValueError):
            self.module.stage(self.args)
        self.assertEqual(target.read_bytes(), b"changed existing data")

    def test_unsafe_names_binary_and_real_junction_are_rejected(self):
        for name in ("sources/../escape", "sources/CON.txt", "sources/source.C"):
            self.write_archive(extra={name: b"unsafe"})
            with self.assertRaises(ValueError):
                self.module.stage(self.args)
            self.assert_unstaged()
        self.payload["sources/tool.txt"] = b"MZhidden executable"
        self.write_archive()
        with self.assertRaises(ValueError):
            self.module.stage(self.args)
        self.assert_unstaged()
        del self.payload["sources/tool.txt"]
        self.write_archive()
        import subprocess
        result = subprocess.run(["cmd", "/c", "mklink", "/J", str(self.args.wheelhouse), str(self.args.archive.parent)], capture_output=True)
        self.assertEqual(result.returncode, 0, result.stderr)
        try:
            with self.assertRaises(ValueError):
                self.module.stage(self.args)
            self.assertFalse(self.args.source_output.exists())
        finally:
            self.args.wheelhouse.rmdir()

    def test_interrupted_partial_stage_has_no_manifest_and_resumes_exactly(self):
        publish = self.module.publish
        count = 0

        def interrupt(path, data):
            nonlocal count
            count += 1
            if count == 2:
                raise OSError("interrupted")
            publish(path, data)

        with patch.object(self.module, "publish", side_effect=interrupt):
            with self.assertRaises(OSError):
                self.module.stage(self.args)
        self.assertFalse((self.args.source_output / "native-artifact-manifest.json").exists())
        self.module.stage(self.args)
        self.assertTrue((self.args.source_output / "native-artifact-manifest.json").is_file())

    def test_missing_payload_cannot_be_published_as_complete(self):
        original = self.module.publish

        def lost_file(path, data):
            original(path, data)
            if path.name == WHEELS[0]:
                path.unlink()

        with patch.object(self.module, "publish", side_effect=lost_file):
            with self.assertRaises(ValueError):
                self.module.stage(self.args)
        self.assertFalse((self.args.source_output / "native-artifact-manifest.json").exists())

    def test_implicit_case_colliding_parent_directories_rejected(self):
        self.payload["sources/Parent/a.c"] = b"source a"
        self.payload["sources/parent/b.c"] = b"source b"
        self.write_archive()
        with self.assertRaises(ValueError):
            self.module.stage(self.args)
        self.assert_unstaged()


if __name__ == "__main__":
    unittest.main()
