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


SCRIPT = Path(__file__).resolve().parents[2] / "scripts" / "build-source-routed-release.py"
spec = importlib.util.spec_from_file_location("source_routed_release", SCRIPT)
module = importlib.util.module_from_spec(spec)
spec.loader.exec_module(module)


class SourceRoutedReleaseTest(unittest.TestCase):
    def test_sbom_packet_requires_exact_files_and_component_identity(self):
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory)
            packet = root / "packet" / "notices-and-source"
            packet.mkdir(parents=True)
            legal = packet / "sbom-legal" / "example" / "LICENSE"
            legal.parent.mkdir(parents=True)
            legal.write_bytes(b"grant")
            relative = "notices-and-source/sbom-legal/example/LICENSE"
            manifest = {"schema_version": 1, "file_count": 1, "files": [{
                "path": relative, "bytes": 5,
                "sha256": hashlib.sha256(b"grant").hexdigest()}]}
            (packet / "sbom-packet-manifest.json").write_text(json.dumps(manifest))
            component = {"wheel": "example.whl", "wheel_sha256": "a" * 64,
                         "purl": "pkg:cargo/example@1", "installed_legal_paths": [relative],
                         "installed_source_path": None, "source_url": "https://example.org/source",
                         "source_sha256": "b" * 64}
            (packet / "sbom-component-index.json").write_text(json.dumps({
                "schema_version": 1, "component_count": 1, "components": [component]}))
            plan = {"components": [{"wheel": "example.whl", "wheel_sha256": "a" * 64,
                                    "purl": "pkg:cargo/example@1"}]}
            target = root / "target"
            target.mkdir()
            module.attach_sbom_packet(root / "packet", target, plan)
            self.assertEqual((target / relative).read_bytes(), b"grant")
            legal.write_bytes(b"wrong")
            with self.assertRaisesRegex(ValueError, "SBOM packet member differs"):
                module.attach_sbom_packet(root / "packet", root / "other", plan)

    def test_publisher_manifest_matches_exact_reviewed_wheels(self):
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory)
            wheelhouse = root / "wheelhouse"
            wheelhouse.mkdir()
            (wheelhouse / "autoclip-1-py3-none-any.whl").write_bytes(b"app")
            third = wheelhouse / "example-1-py3-none-any.whl"
            third.write_bytes(b"third party")
            entry = {"package": "example", "version": "1", "filename": third.name,
                     "tags": ["py3-none-any"], "bytes": third.stat().st_size,
                     "sha256": hashlib.sha256(third.read_bytes()).hexdigest(),
                     "url": "https://files.pythonhosted.org/example.whl",
                     "publisher_identity": "PyPI project example", "delivery_policy": "publisher"}
            module.validate_publisher_wheels([third], [entry])
            with self.assertRaisesRegex(ValueError, "publisher wheel hash mismatch"):
                module.validate_publisher_wheels([third], [{**entry, "sha256": "0" * 64}])
            with self.assertRaisesRegex(ValueError, "publisher wheel set differs"):
                module.validate_publisher_wheels([third], [])

    def test_v14_route_excludes_exact_third_party_wheel_bytes(self):
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory)
            source = root / "v13"
            wheelhouse = source / "wheelhouse"
            wheelhouse.mkdir(parents=True)
            app = wheelhouse / "autoclip-1-py3-none-any.whl"
            third = wheelhouse / "example-1-py3-none-any.whl"
            app.write_bytes(b"app")
            third.write_bytes(b"third party")
            files = [{"path": f"wheelhouse/{p.name}", "bytes": p.stat().st_size,
                      "sha256": hashlib.sha256(p.read_bytes()).hexdigest()} for p in (app, third)]
            (source / "release-manifest.json").write_text(json.dumps({"schema_version": 2,
                "files": files, "external_assets": [], "native_build": {}}))
            pinned = root / "pins.json"
            pinned.write_text(json.dumps({"schema_version": 1, "wheels": [{
                "package": "example", "version": "1", "filename": third.name,
                "tags": ["py3-none-any"], "bytes": third.stat().st_size,
                "sha256": hashlib.sha256(third.read_bytes()).hexdigest(),
                "url": "https://files.pythonhosted.org/example.whl",
                "publisher_identity": "PyPI project example", "delivery_policy": "publisher"}]}))
            target = root / "v14"
            module.build_publisher_routed_release(source, target, pinned)
            self.assertTrue((target / "wheelhouse" / app.name).is_file())
            self.assertFalse((target / "wheelhouse" / third.name).exists())
            manifest = json.loads((target / "release-manifest.json").read_text())
            self.assertEqual(manifest["publisher_wheels"][0]["filename"], third.name)

    def test_source_artifacts_are_verified_and_copied(self):
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory)
            cache = root / "cache"
            cache.mkdir()
            (cache / "source.tar.gz").write_bytes(b"source")
            inputs = root / "inputs.json"
            inputs.write_text(json.dumps({"schema_version": 1, "artifacts": [{
                "owner": "example", "component": "dependency", "relationship": "source lead",
                "filename": "source.tar.gz", "url": "https://example.org/source.tar.gz",
                "bytes": 6, "sha256": hashlib.sha256(b"source").hexdigest()
            }]}), encoding="utf-8")
            target = root / "target"
            target.mkdir()
            module.attach_source_artifacts(inputs, cache, target)
            copied = target / "notices-and-source" / "source-and-build" / "source.tar.gz"
            self.assertEqual(copied.read_bytes(), b"source")
            self.assertEqual(len(json.loads((copied.parent / "source-artifact-manifest.json").read_text())["artifacts"]), 1)
            (cache / "source.tar.gz").write_bytes(b"wrong!")
            with self.assertRaisesRegex(ValueError, "source artifact hash mismatch"):
                module.attach_source_artifacts(inputs, cache, target)

    def test_copies_distinct_legal_members_without_collapsing_authors(self):
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory)
            wheel_path = root / "example-1.0-py3-none-any.whl"
            with zipfile.ZipFile(wheel_path, "w") as wheel:
                wheel.writestr("example-1.0.dist-info/licenses/LICENSE", "same permission text")
                wheel.writestr("example-1.0.dist-info/licenses/AUTHORS", "Author A")
            target = root / "release"
            target.mkdir()
            copied = module.copy_missing_legal_files([wheel_path], target)
            self.assertEqual(len(copied), 2)
            base = target / "notices-and-source" / "wheel-notices" / wheel_path.name
            self.assertEqual((base / "example-1.0.dist-info" / "licenses" / "AUTHORS").read_text(), "Author A")
            self.assertEqual((base / "example-1.0.dist-info" / "licenses" / "LICENSE").read_text(), "same permission text")

    def test_rejects_legal_index_for_different_wheel_bytes(self):
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory)
            wheel_path = root / "example-1.0-py3-none-any.whl"
            wheel_path.write_bytes(b"actual")
            source = root / "audit.json"
            source.write_text(json.dumps({"schema_version": 1, "packages": [
                {"filename": wheel_path.name, "sha256": hashlib.sha256(b"other").hexdigest()}
            ]}), encoding="utf-8")
            with self.assertRaisesRegex(ValueError, "legal index wheel hash"):
                module.attach_review_index([wheel_path], source, root / "target")

    def test_removes_bundled_vendor_wheels_and_openmp_dll(self):
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory)
            source = root / "source"
            wheelhouse = source / "wheelhouse"
            wheelhouse.mkdir(parents=True)
            (source / "LICENSE").write_text("license", encoding="utf-8")
            official = source / "notices-and-source" / "nvidia-runtime" / "cudnn-9.10.2-official"
            official.mkdir(parents=True)
            for name in ("eula.html", "acknowledgements.html", "notices.html"):
                (official / name).write_text(name, encoding="utf-8")
            sidecar = source / "notices-and-source" / "MANIFEST.md"
            sidecar.write_text(
                "# V11 Windows release notice and source inventory\n\n"
                "Inventory for a versioned 79-wheel Windows release correction based on the 2026-09-26 app-refresh archive.\n\n"
                "The release contains 79 wheel files: AutoClip, 76 other dependencies and two NVIDIA CUDA runtime wheels.\n",
                encoding="utf-8",
            )
            (wheelhouse / "nvidia_cublas_cu12-12.4.5.8-py3-none-win_amd64.whl").write_bytes(b"cublas")
            (wheelhouse / "nvidia_cudnn_cu12-9.10.2.21-py3-none-win_amd64.whl").write_bytes(b"cudnn")
            (wheelhouse / "autoclip-0.1.0.dev0-py3-none-any.whl").write_bytes(b"app")
            (wheelhouse / "av-18.1.0-cp311-abi3-win_amd64.whl").write_bytes(b"pyav")
            native = wheelhouse / "ctranslate2-4.8.2-cp311-cp311-win_amd64.whl"
            record = "ctranslate2-4.8.2.dist-info/RECORD"
            with zipfile.ZipFile(native, "w") as archive:
                archive.writestr("ctranslate2/ctranslate2.dll", b"native")
                archive.writestr("ctranslate2/vcomp140.dll", b"microsoft")
                archive.writestr("ctranslate2/libopenblas.dll", b"openblas")
                archive.writestr(record, "")
            (source / ".venv").mkdir()
            (source / ".venv" / "unexpected.dll").write_bytes(b"installed runtime")
            listed = [file for file in source.rglob("*") if file.is_file() and ".venv" not in file.parts]
            (source / "release-manifest.json").write_text(json.dumps({
                "files": [{"path": file.relative_to(source).as_posix(), "bytes": file.stat().st_size,
                           "sha256": hashlib.sha256(file.read_bytes()).hexdigest()} for file in listed]
            }), encoding="utf-8")

            target = root / "target"
            module.build_release(source, target)
            self.assertTrue((target / "upstream-assets.ps1").is_file())
            self.assertFalse((target / ".venv").exists())
            self.assertFalse(list((target / "wheelhouse").glob("nvidia_*.whl")))
            with zipfile.ZipFile(target / "wheelhouse" / native.name) as archive:
                self.assertNotIn("ctranslate2/vcomp140.dll", archive.namelist())
                self.assertNotIn("ctranslate2/libopenblas.dll", archive.namelist())
                self.assertEqual(archive.read("ctranslate2/ctranslate2.dll"), b"native")
                rows = list(csv.reader(io.StringIO(archive.read(record).decode())))
                entry = next(row for row in rows if row[0] == "ctranslate2/ctranslate2.dll")
                digest = base64.urlsafe_b64encode(hashlib.sha256(b"native").digest()).rstrip(b"=").decode()
                self.assertEqual(entry, ["ctranslate2/ctranslate2.dll", "sha256=" + digest, "6"])
            manifest = json.loads((target / "release-manifest.json").read_text())
            self.assertEqual(len(manifest["external_assets"]), 4)
            self.assertNotIn("wheelhouse/nvidia_cublas_cu12-12.4.5.8-py3-none-win_amd64.whl", [f["path"] for f in manifest["files"]])
            source_target = root / "source-build-target"
            module.build_release(source, source_target, build_native_from_source=True)
            self.assertFalse(list((source_target / "wheelhouse").glob("av-*.whl")))
            self.assertFalse(list((source_target / "wheelhouse").glob("ctranslate2-*.whl")))
            self.assertTrue((source_target / "wheelhouse" / "autoclip-0.1.0.dev0-py3-none-any.whl").is_file())
            self.assertTrue((source_target / "build-native-from-source.ps1").is_file())
            self.assertTrue((source_target / "build-v11-codec-free-ffmpeg.sh").is_file())
            self.assertTrue((source_target / "verify-native-source-wheels.py").is_file())
            self.assertTrue((source_target / "verify-install-wheels.py").is_file())
            self.assertTrue((source_target / "notices-and-source" / "nvidia-runtime" / "cudnn-9.10.2-official" / "acknowledgements.html").is_file())
            current_packet = (source_target / "notices-and-source" / "MANIFEST.md").read_text(encoding="utf-8")
            self.assertIn("75-wheel source-build candidate", current_packet)
            self.assertNotIn("Proposed V11 release", current_packet)
            self.assertNotIn("Review input only. HOLD", current_packet)
            native_manifest = json.loads((source_target / "release-manifest.json").read_text())
            self.assertEqual(native_manifest["native_build"]["wheel_names"], sorted(module.native_source_wheel_names()))
            self.assertTrue(native_manifest["native_build"]["cuda_dynamic_loading"])
            self.assertEqual(native_manifest["native_build"]["ctranslate2_commit"], "d44d2d069eb88c7b7804da864c10c201501cb4a9")


if __name__ == "__main__":
    unittest.main()
