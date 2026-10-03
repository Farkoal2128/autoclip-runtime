"""Controlled packaging behavior; native PE inspection is an external boundary."""

import hashlib
import importlib.util
import json
import tempfile
import unittest
import zipfile
from pathlib import Path
from types import SimpleNamespace
from unittest.mock import patch


ROOT = Path(__file__).resolve().parents[2]
SCRIPT = ROOT / "scripts/package-cpu-native-artifact.py"


class CpuArtifactTests(unittest.TestCase):
    def setUp(self):
        self.assertTrue(SCRIPT.is_file(), "Authorized CPU artifact packaging CLI is absent")
        spec = importlib.util.spec_from_file_location("cpu_artifact", SCRIPT)
        self.module = importlib.util.module_from_spec(spec)
        spec.loader.exec_module(self.module)
        self.temp = tempfile.TemporaryDirectory()
        self.addCleanup(self.temp.cleanup)
        root = Path(self.temp.name)
        self.args = SimpleNamespace(wheelhouse=root / "wheels", build_root=root / "build",
                                    source_directory=root / "source", output=root / "candidate.zip",
                                    runtime_id="autoclip-cpu-win-x64-py311-test")
        for directory in (self.args.wheelhouse, self.args.build_root, self.args.source_directory):
            directory.mkdir()
        rows = []
        for name in ("av-18.1.0-cp311-abi3-win_amd64.whl", "ctranslate2-4.8.2-cp311-cp311-win_amd64.whl"):
            path = self.args.wheelhouse / name
            with zipfile.ZipFile(path, "w") as archive:
                archive.writestr("package/source.py", "# native inspection boundary fixture\n")
            rows.append({"filename": name, "bytes": path.stat().st_size,
                         "sha256": hashlib.sha256(path.read_bytes()).hexdigest()})
        config = b"".join(f"!CONFIG_{name}=yes\n".encode() for name in ("GPL", "NONFREE", "LIBX264", "LIBX265"))
        log = b"--disable-autodetect --enable-shared --disable-static --disable-gpl --disable-nonfree --disable-libx264 --disable-libx265\n"
        header = b"".join(f"#define CONFIG_{name} 0\n".encode() for name in ("GPL", "NONFREE", "LIBX264", "LIBX265"))
        for name, data in (("ffmpeg-config.mak", config), ("ffmpeg-config.log", log), ("ffmpeg-config.h", header)):
            (self.args.build_root / name).write_bytes(data)
        self.receipt = {**self.module.SOURCE_PINS, "profile": "cpu", "install_nvidia_gpu": False,
                        "ffmpeg_config_sha256": hashlib.sha256(config).hexdigest(),
                        "cmake_arguments": list(self.module.CPU_FLAGS), "wheels": rows}
        self.write_receipt()
        components = []
        for component in ("ffmpeg", "pyav", "ctranslate2", "onednn"):
            (self.args.source_directory / component).mkdir()
            (self.args.source_directory / component / "source.c").write_text("/* source */\n")
            (self.args.source_directory / component / "LICENSE").write_text("Original test notice\n")
            components.append({"component": component, "source_paths": [component],
                               "notice_paths": [component + "/LICENSE"]})
        (self.args.source_directory / "source-associations.json").write_text(json.dumps({"schema_version": 1, "components": components}))
        (self.args.source_directory / "provenance.json").write_text('{"producer": "test only"}')
        self.check = patch.object(self.module, "verify_native")
        self.native = self.check.start()
        self.addCleanup(self.check.stop)

    def write_receipt(self):
        (self.args.build_root / "native-build-receipt.json").write_text(json.dumps(self.receipt))

    def test_exact_inventory_unqualified_and_no_overwrite(self):
        self.module.package(self.args)
        self.native.assert_called_once()
        original = self.args.output.read_bytes()
        with zipfile.ZipFile(self.args.output) as archive:
            manifest = json.loads(archive.read("native-artifact-manifest.json"))
            self.assertEqual(manifest["qualification"], "UNQUALIFIED_CANDIDATE")
            self.assertEqual(manifest["profile"], "cpu")
            self.assertEqual({row["path"] for row in manifest["files"]}, set(archive.namelist()) - {"native-artifact-manifest.json"})
            for row in manifest["files"]:
                data = archive.read(row["path"])
                self.assertEqual((row["bytes"], row["sha256"]), (len(data), hashlib.sha256(data).hexdigest()))
        with self.assertRaises(ValueError):
            self.module.package(self.args)
        self.assertEqual(original, self.args.output.read_bytes())

    def test_receipt_profile_flags_and_wheel_pins_fail_before_publication(self):
        for change in ({"profile": "nvidia"}, {"install_nvidia_gpu": "false"},
                       {"cmake_arguments": []}, {"ffmpeg_source_sha256": "0" * 64},
                       {"wheels": []}):
            with self.subTest(change=change):
                original = self.receipt.copy()
                self.receipt.update(change)
                self.write_receipt()
                with self.assertRaises(ValueError):
                    self.module.package(self.args)
                self.assertFalse(self.args.output.exists())
                self.receipt = original
        self.write_receipt()
        (self.args.wheelhouse / self.receipt["wheels"][0]["filename"]).write_bytes(b"substitution")
        with self.assertRaises(ValueError):
            self.module.package(self.args)
        self.assertFalse(self.args.output.exists())

    def test_source_binary_nested_archive_and_unsafe_members_rejected(self):
        for filename, members in (("nested.zip", {"vendor.dll": b"MZbinary"}),
                                  ("nested.zip", {"../escape.c": b"source"}),
                                  ("nested.zip", {"A.c": b"source", "a.c": b"source"}),
                                  ("nested.zip", {"hidden.zip": self.nested_binary()})):
            with self.subTest(members=members):
                path = self.args.source_directory / filename
                with zipfile.ZipFile(path, "w") as archive:
                    for name, data in members.items():
                        archive.writestr(name, data)
                with self.assertRaises(ValueError):
                    self.module.package(self.args)
                self.assertFalse(self.args.output.exists())
                path.unlink()
        (self.args.source_directory / "payload.txt").write_bytes(b"MZhidden")
        with self.assertRaises(ValueError):
            self.module.package(self.args)

    @staticmethod
    def nested_binary():
        import io
        data = io.BytesIO()
        with zipfile.ZipFile(data, "w") as archive:
            archive.writestr("tool.exe", b"MZbinary")
        return data.getvalue()

    def test_native_verification_failure_leaves_no_output(self):
        self.native.side_effect = ValueError("native import mismatch")
        with self.assertRaises(ValueError):
            self.module.package(self.args)
        self.assertFalse(self.args.output.exists())

    def test_actual_ffmpeg_header_and_log_must_match_controlled_profile(self):
        path = self.args.build_root / "ffmpeg-config.h"
        path.write_bytes(b"#define CONFIG_GPL 1\n")
        with self.assertRaises(ValueError):
            self.module.package(self.args)
        self.assertFalse(self.args.output.exists())

    def test_hidden_archive_reparse_and_failed_or_raced_publication(self):
        hidden = self.args.source_directory / "hidden.txt"
        hidden.write_bytes(self.nested_binary())
        with self.assertRaises(ValueError):
            self.module.package(self.args)
        hidden.unlink()
        with patch.object(self.module.zipfile.ZipFile, "writestr", side_effect=OSError("interrupted")):
            with self.assertRaises(OSError):
                self.module.package(self.args)
        self.assertFalse(self.args.output.exists())
        self.assertEqual(list(self.args.output.parent.glob(".cpu-native-*.tmp")), [])
        original_link = self.module.os.link

        def race(source, destination):
            destination.write_bytes(b"another publisher")
            original_link(source, destination)

        with patch.object(self.module.os, "link", side_effect=race):
            with self.assertRaises(FileExistsError):
                self.module.package(self.args)
        self.assertEqual(self.args.output.read_bytes(), b"another publisher")
        self.assertEqual(list(self.args.output.parent.glob(".cpu-native-*.tmp")), [])
        self.args.output.unlink()
        # Actual junctions need no Windows symlink privilege.
        import subprocess
        junction = self.args.source_directory / "escape"
        result = subprocess.run(["cmd", "/c", "mklink", "/J", str(junction), str(self.args.build_root)], capture_output=True)
        self.assertEqual(result.returncode, 0, result.stderr)
        try:
            with self.assertRaises(ValueError):
                self.module.package(self.args)
            self.assertFalse(self.args.output.exists())
        finally:
            junction.rmdir()


if __name__ == "__main__":
    unittest.main()
