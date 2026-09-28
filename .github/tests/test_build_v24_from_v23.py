"""The next local candidate must retain exact identity and font notices."""

import hashlib
import importlib.util
import json
import tempfile
import unittest
import zipfile
from pathlib import Path


SCRIPT = Path(__file__).resolve().parents[2] / "scripts" / "build-v24-from-v23.py"


def digest(data: bytes) -> str:
    return hashlib.sha256(data).hexdigest()


class BuildV24Tests(unittest.TestCase):
    def test_candidate_carries_notice_and_source_snapshot(self):
        spec = importlib.util.spec_from_file_location("build_v24", SCRIPT)
        module = importlib.util.module_from_spec(spec)
        spec.loader.exec_module(module)
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory)
            wheel = root / "autoclip-0.1.0.dev0-py3-none-any.whl"
            fonts = ["autoclip/assets/licenses/" + name + "-OFL.txt" for name in
                     ("Anton", "Archivo", "InstrumentSerif", "Inter")]
            readme = "autoclip/assets/licenses/README.md"
            with zipfile.ZipFile(wheel, "w") as archive:
                for font in fonts:
                    archive.writestr(font, (font + " OFL text").encode())
                archive.writestr(readme, b"font map")
            app_member = "wheelhouse/" + wheel.name
            legal = {"schema_version": 1, "packages": [{
                "normalized_name": "autoclip", "filename": wheel.name,
                "sha256": digest(wheel.read_bytes()), "legal_files": [],
                "legal_sha256": {}, "verified_sidecar_copies": [],
                "fulfillment_locations": [],
            }]}
            manifest = {"schema_version": 3, "native_build": {
                "runtime_commit": "base-revision", "app_commit": "app-revision",
            }, "files": []}
            base = root / "base.zip"
            source = {
                app_member: wheel.read_bytes(),
                "build-native-from-source.ps1": b"old build",
                "notices-and-source/legal-index.json": (json.dumps(legal) + "\n").encode(),
                "notices-and-source/MANIFEST.md": b"old inventory\n",
            }
            manifest["files"] = [{"path": n, "bytes": len(v), "sha256": digest(v)}
                                 for n, v in source.items()]
            with zipfile.ZipFile(base, "w") as archive:
                for name, data in source.items():
                    archive.writestr(name, data)
                archive.writestr("release-manifest.json", (json.dumps(manifest) + "\n").encode())
            old_archive_hash = digest(base.read_bytes())
            old_manifest_hash = digest(zipfile.ZipFile(base).read("release-manifest.json"))
            old_id = "v23-base"
            installer = root / "old-installer.ps1"
            installer.write_text("$archive='" + old_archive_hash + "'\n$manifest='" +
                                 old_manifest_hash + "'\n$id='" + old_id + "'\n" +
                                 "& 'Prepare-AutoClipOfflineCache.ps1' -Offline:$OfflinePublisherCache\n")
            output = root / "next.zip"
            new_installer = root / "next-installer.ps1"
            snapshot = {"build-native-from-source.ps1": b"controlled Python",
                        "update.ps1": b"profile-aware updater",
                        "scripts/build-source-routed-release.py": b"font index recipe",
                        "Prepare-AutoClipOfflineCache.ps1": b"optional NVIDIA verified cache"}
            module.derive(base, wheel, installer, output, new_installer,
                          expected_base_hash=old_archive_hash,
                          old_release_id=old_id, new_release_id="v24-local",
                          source_snapshot=snapshot)
            with zipfile.ZipFile(output) as archive:
                entries = archive.namelist()
                self.assertEqual(len(entries), len(set(entries)))
                next_manifest = json.loads(archive.read("release-manifest.json"))
                next_legal = json.loads(archive.read("notices-and-source/legal-index.json"))
                indexed = {row["path"]: row for row in next_manifest["files"]}
                for name, row in indexed.items():
                    data = archive.read(name)
                    self.assertEqual((row["bytes"], row["sha256"]), (len(data), digest(data)))
                app = next_legal["packages"][0]
                for name in (*fonts, readme):
                    sidecar = "notices-and-source/wheel-notices/" + wheel.name + "/" + name
                    self.assertIn(name, app["legal_files"])
                    self.assertEqual(app["legal_sha256"][name], digest(archive.read(sidecar)))
                    self.assertIn(sidecar, app["verified_sidecar_copies"])
                self.assertEqual(archive.read("build-native-from-source.ps1"), snapshot["build-native-from-source.ps1"])
                self.assertEqual(archive.read("Prepare-AutoClipOfflineCache.ps1"), snapshot["Prepare-AutoClipOfflineCache.ps1"])
                self.assertIsNone(next_manifest["native_build"]["runtime_commit"])
                provenance = json.loads(archive.read("notices-and-source/build-provenance.json"))
                self.assertEqual(provenance["source_state"], "local_uncommitted_snapshot")
                self.assertEqual(provenance["base_archive_sha256"], old_archive_hash)
            new_text = new_installer.read_text()
            self.assertIn(digest(output.read_bytes()), new_text)
            self.assertIn(digest(zipfile.ZipFile(output).read("release-manifest.json")), new_text)
            self.assertIn("v24-local", new_text)
            self.assertIn("-InstallNvidiaGpu:$InstallNvidiaGpu", new_text)
            self.assertEqual(digest(base.read_bytes()), old_archive_hash)


if __name__ == "__main__":
    unittest.main()
