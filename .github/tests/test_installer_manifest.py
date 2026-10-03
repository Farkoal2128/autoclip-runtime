"""Behavioral checks for the release-to-installer dependency manifest gate."""

import hashlib
import importlib.util
import io
import json
import subprocess
import sys
import tempfile
import unittest
import zipfile
from pathlib import Path


ROOT = Path(__file__).resolve().parents[2]
VERIFIER = ROOT / "scripts" / "verify-installer-manifest.py"


def digest(data):
    return hashlib.sha256(data).hexdigest()


def encoded(value):
    return (json.dumps(value, sort_keys=True, indent=2) + "\n").encode()


def nested_zip(files):
    result = io.BytesIO()
    with zipfile.ZipFile(result, "w", zipfile.ZIP_DEFLATED) as archive:
        for path, data in files.items():
            archive.writestr(path, data)
    return result.getvalue()


def cpu_native_fixture(directory):
    """Reuse the authentic ZIP/RECORD fixture, with synthetic native bytes only."""
    spec = importlib.util.spec_from_file_location("cpu_staging_fixture", ROOT / ".github/tests/test_cpu_native_install.py")
    module = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(module)
    fixture = module.CpuInstallTests()
    fixture.setUp()
    try:
        path = directory / "autoclip-cpu-test.zip"
        path.write_bytes(fixture.args.archive.read_bytes())
        return {"identity": fixture.args.runtime_id, "runtime_id": fixture.args.runtime_id,
                "filename": path.name, "url": "https://example.org/" + path.name,
                "bytes": path.stat().st_size, "sha256": digest(path.read_bytes()),
                "delivery_classification": "DIRECT_RECIPIENT_DOWNLOAD", "profile": "cpu",
                "redirect_hosts": ["example.org"],
                "qualification_receipt_path": "notices/cpu-distribution-receipt.json"}, path
    finally:
        fixture.doCleanups()


class InstallerManifestTests(unittest.TestCase):
    def setUp(self):
        self.temp = tempfile.TemporaryDirectory()
        self.addCleanup(self.temp.cleanup)
        self.root = Path(self.temp.name)
        self.archive = self.root / "release.zip"
        self.manifest_path = self.root / "installer-manifest.json"
        self.payload = {"app/AutoClip.bin": b"first-party application bytes"}
        self.wheel = {
            "filename": "example-1-py3-none-any.whl",
            "version": "1",
            "url": "https://files.pythonhosted.org/example.whl",
            "bytes": 6,
            "sha256": digest(b"wheel!"),
            "delivery_classification": "DIRECT_RECIPIENT_DOWNLOAD",
        }
        self.external = {
            "kind": "python_wheel",
            "filename": self.wheel["filename"],
            "url": self.wheel["url"],
            "bytes": self.wheel["bytes"],
            "sha256": self.wheel["sha256"],
            "profile": "cpu",
            "delivery_classification": "DIRECT_RECIPIENT_DOWNLOAD",
            "redirect_hosts": ["files.pythonhosted.org"],
        }
        self._write_archive()
        self._write_outer_manifest()

    def _write_archive(self):
        publisher_manifest = encoded({"schema_version": 1, "wheels": [self.wheel]})
        inventory = encoded({
            "schema_version": 1,
            "publisher_wheels": [self.wheel["filename"]],
            "external_assets": [self.external],
        })
        files = {
            **self.payload,
            "publisher-wheel-manifest.json": publisher_manifest,
            "distribution-inventory.json": inventory,
        }
        release_manifest = encoded({
            "schema_version": 3,
            "files": [
                {"path": path, "bytes": len(data), "sha256": digest(data)}
                for path, data in sorted(files.items())
            ],
            "publisher_wheels": [self.wheel],
            "external_assets": [self.external],
            **({"native_build": self.native_build} if hasattr(self, "native_build") else {}),
        })
        with zipfile.ZipFile(self.archive, "w", zipfile.ZIP_DEFLATED) as archive:
            for path, data in files.items():
                archive.writestr(path, data)
            archive.writestr("release-manifest.json", release_manifest)

    def _outer_manifest(self):
        archive_bytes = self.archive.read_bytes()
        with zipfile.ZipFile(self.archive) as archive:
            release_manifest = archive.read("release-manifest.json")
            publisher_manifest = archive.read("publisher-wheel-manifest.json")
            inventory = archive.read("distribution-inventory.json")
        return {
            "schema_version": 1,
            "target_release": {
                "id": "fixture-v1",
                "url": "https://example.org/release.zip",
                "delivery_classification": "DIRECT_RECIPIENT_DOWNLOAD",
                "redirect_hosts": ["example.org"],
                "bytes": len(archive_bytes),
                "sha256": digest(archive_bytes),
                "manifest_sha256": digest(release_manifest),
                "distribution_inventory_sha256": digest(inventory),
            },
            "publisher_wheels": {
                "manifest_path": "publisher-wheel-manifest.json",
                "sha256": digest(publisher_manifest),
                "count": 1,
                "delivery_classification": "DIRECT_RECIPIENT_DOWNLOAD",
                "license_evidence": "synthetic fixture",
                "redirect_hosts": ["files.pythonhosted.org"],
            },
            "external_assets": [self.external],
            "setup_payload": [
                {"path": path, "sha256": digest(data),
                 "delivery_classification": "BUNDLE_ALLOWED"}
                for path, data in sorted(self.payload.items())
            ],
            "compiler": {
                "identity": "Inno Setup compiler test fixture",
                "version": "6.5.4",
                "url": "https://example.org/is.exe",
                "bytes": 1,
                "sha256": digest(b"i"),
                "delivery_classification": "SYSTEM_PROVIDED",
                "license_evidence": "synthetic fixture",
                "provenance_status": "synthetic test fixture",
            },
        }

    def _write_outer_manifest(self, manifest=None):
        self.manifest_path.write_bytes(encoded(manifest or self._outer_manifest()))

    def _run(self, require_installable=False):
        return subprocess.run(
            [sys.executable, str(VERIFIER), "--manifest", str(self.manifest_path),
             "--archive", str(self.archive)] +
            (["--require-installable"] if require_installable else []),
            capture_output=True, text=True, check=False,
        )

    def _assert_rejected(self, manifest=None):
        self._write_outer_manifest(manifest)
        result = self._run()
        self.assertNotEqual(result.returncode, 0, result.stdout + result.stderr)
        self.assertNotRegex(result.stderr, r"can't open file .*verify-installer-manifest\.py")

    def test_valid_exact_release_graph_passes(self):
        result = self._run()
        self.assertEqual(result.returncode, 0, result.stdout + result.stderr)

    def _publisher_cpu_manifest(self):
        descriptor, artifact = cpu_native_fixture(self.root)
        receipt = encoded({"schema_version": 1, "decision": "QUALIFIED_COMPONENT_DISTRIBUTION",
                           "artifact": {key: descriptor[key] for key in ("runtime_id", "filename", "bytes", "sha256")},
                           "evidence_scope": "synthetic unit fixture; no actual disposition"})
        descriptor["qualification_receipt_sha256"] = digest(receipt)
        self.payload[descriptor["qualification_receipt_path"]] = receipt
        canonical = json.loads((ROOT / "release/manifests/installer-dependencies-v1.json").read_text())
        native = [dict(row, profile="nvidia") for row in canonical["native_build_assets"]]
        self.payload["build-native-from-source.ps1"] = "".join(
            "Get-VerifiedSource '{filename}' '{url}' {bytes} '{sha256}'\n".format(**row) for row in native).encode()
        self.native_build = {"delivery": "publisher_cpu_with_source_nvidia", "cpu_artifact": descriptor.copy()}
        self._write_archive()
        manifest = self._outer_manifest()
        manifest["cpu_native_artifact"] = descriptor
        manifest["native_build_assets"] = native
        manifest["build_prerequisites"] = [dict(row, profile="nvidia") for row in canonical["build_prerequisites"]
                                            if row["identity"] in ("Visual Studio 2022 Build Tools", "Windows SDK", "Git for Windows", "MSYS2")]
        self._write_outer_manifest(manifest)
        return manifest, artifact

    def _run_native(self, artifact=None, profile="cpu", installable=True):
        command = [sys.executable, str(VERIFIER), "--manifest", str(self.manifest_path),
                   "--archive", str(self.archive), "--profile", profile]
        if artifact is not None:
            command += ["--native-artifact", str(artifact)]
        if installable:
            command += ["--require-installable"]
        return subprocess.run(command, capture_output=True, text=True, check=False)

    def test_publisher_cpu_route_passes_with_actual_bytes_without_build_prerequisites(self):
        self._publisher_cpu_manifest()
        result = self._run_native(installable=False)
        self.assertEqual(result.returncode, 0, result.stdout + result.stderr)
        artifact = self.root / "autoclip-cpu-test.zip"
        result = self._run_native(artifact)
        self.assertEqual(result.returncode, 0, result.stdout + result.stderr)
        result = self._run_native(artifact, profile="nvidia")
        self.assertNotEqual(result.returncode, 0)
        self.assertIn("required prerequisite is blocked", result.stderr)

    def test_publisher_cpu_requires_actual_artifact_and_matching_receipt_graph(self):
        manifest, artifact = self._publisher_cpu_manifest()
        result = self._run_native()
        self.assertNotEqual(result.returncode, 0)
        self.assertIn("actual CPU native artifact", result.stderr)
        for changes in ({"sha256": "0" * 64}, {"runtime_id": "foreign"},
                        {"qualification_receipt_sha256": "0" * 64}, {"profile": "nvidia"}):
            with self.subTest(changes=changes):
                candidate = json.loads(json.dumps(manifest))
                candidate["cpu_native_artifact"].update(changes)
                self._write_outer_manifest(candidate)
                result = self._run_native(artifact)
                self.assertNotEqual(result.returncode, 0, result.stdout + result.stderr)
        self._write_outer_manifest(manifest)
        artifact.write_bytes(b"substituted artifact")
        result = self._run_native(artifact)
        self.assertNotEqual(result.returncode, 0)
        self.assertIn("CPU native artifact", result.stderr)

    def test_publisher_cpu_cannot_select_source_build_tools_or_assets(self):
        for group in ("native_build_assets", "build_prerequisites"):
            manifest, artifact = self._publisher_cpu_manifest()
            manifest[group][0]["profile"] = "both"
            self._write_outer_manifest(manifest)
            result = self._run_native(artifact, installable=False)
            self.assertNotEqual(result.returncode, 0)
            self.assertIn("NVIDIA", result.stderr)

    def test_publisher_cpu_rejects_unqualified_receipt_even_when_all_hashes_match(self):
        manifest, artifact = self._publisher_cpu_manifest()
        descriptor = manifest["cpu_native_artifact"]
        receipt = json.loads(self.payload[descriptor["qualification_receipt_path"]])
        receipt["decision"] = "UNQUALIFIED_CANDIDATE"
        data = encoded(receipt)
        self.payload[descriptor["qualification_receipt_path"]] = data
        descriptor["qualification_receipt_sha256"] = digest(data)
        self.native_build["cpu_artifact"] = descriptor.copy()
        self._write_archive()
        updated = self._outer_manifest()
        manifest["target_release"] = updated["target_release"]
        manifest["setup_payload"] = updated["setup_payload"]
        self._write_outer_manifest(manifest)
        result = self._run_native(artifact)
        self.assertNotEqual(result.returncode, 0)
        self.assertIn("exact distribution receipt", result.stderr)

    def test_publisher_cpu_skips_blocked_nvidia_msys_routes_but_checks_metadata(self):
        manifest, artifact = self._publisher_cpu_manifest()
        base = next(row for row in manifest["build_prerequisites"] if row["identity"] == "MSYS2")
        for row in [base, base["signature"], base["installer_key"], *base["packages"],
                    *(row["signature"] for row in base["packages"])]:
            row["delivery_classification"] = "BLOCKED"
        self._write_outer_manifest(manifest)
        result = self._run_native(artifact)
        self.assertEqual(result.returncode, 0, result.stdout + result.stderr)
        base["signature"]["bytes"] = 1
        self._write_outer_manifest(manifest)
        result = self._run_native(artifact)
        self.assertNotEqual(result.returncode, 0)
        self.assertIn("MSYS2 archive signature identity", result.stderr)

    def test_qualified_component_routes_are_eligible_without_wizard_release_approval(self):
        canonical = json.loads(
            (ROOT / "release/manifests/installer-dependencies-v1.json").read_text()
        )
        component_names = {"uv", "Gyan FFmpeg", "Git for Windows", "MSYS2", "Python"}
        native = canonical["native_build_assets"]
        self.payload["build-native-from-source.ps1"] = "".join(
            "Get-VerifiedSource '{filename}' '{url}' {bytes} '{sha256}'\n".format(**row)
            for row in native
        ).encode()
        self._write_archive()
        manifest = self._outer_manifest()
        manifest["native_build_assets"] = native
        manifest["build_prerequisites"] = [
            row for row in canonical["build_prerequisites"]
            if row["identity"] in component_names
        ]
        self.assertEqual(len(manifest["build_prerequisites"]), 5)
        self.assertEqual(len(native), 9)
        self._write_outer_manifest(manifest)
        result = self._run(require_installable=True)
        self.assertEqual(result.returncode, 0, result.stdout + result.stderr)

        # Eligibility of those artifacts must not unblock the unresolved vendor route.
        for name in ("Visual Studio 2022 Build Tools", "Windows SDK"):
            with self.subTest(unresolved=name):
                unresolved = next(row for row in canonical["build_prerequisites"]
                                  if row["identity"] == name)
                manifest["build_prerequisites"].append(unresolved)
                self._write_outer_manifest(manifest)
                result = self._run(require_installable=True)
                self.assertNotEqual(result.returncode, 0, result.stdout + result.stderr)
                self.assertIn(f"required prerequisite is blocked: {name}", result.stderr)
                manifest["build_prerequisites"].pop()

    def _msys_archive_manifest(self):
        manifest = self._outer_manifest()
        base = next(row for row in json.loads(
            (ROOT / 'release/manifests/installer-dependencies-v1.json').read_text()
        )['build_prerequisites'] if row['identity'] == 'MSYS2')
        base.update(
            filename='msys2-base-x86_64-20260611.tar.xz',
            url='https://github.com/msys2/msys2-installer/releases/download/2026-06-11/msys2-base-x86_64-20260611.tar.xz',
            bytes=53555380,
            sha256='a2d047e8ee213c3c6a49a8de427eb1069df12207c0422ff1b3cbb5c905c34221',
            artifact_kind='archive', archive_format='tar.xz',
            delivery_classification='DIRECT_RECIPIENT_DOWNLOAD',
            installer_arguments=[], success_exit_codes=[], reboot_behavior='none',
        )
        base['signature'] = dict(
            filename=base['filename'] + '.sig', url=base['url'] + '.sig', bytes=566,
            sha256='076f5623b702d5016cf0253e1d14a6bd4870a90243243e96409b227f0d5bf70f',
            delivery_classification='DIRECT_RECIPIENT_DOWNLOAD', redirect_hosts=base['redirect_hosts'],
        )
        base['installer_key'] = dict(
            filename='installer-signer.asc',
            url='https://keyserver.ubuntu.com/pks/lookup?op=get&search=0x0EBF782C5D53F7E5FB02A66746BD761F7A49B0EC',
            bytes=52107,
            sha256='a247a92716ab322770e800793c10136dd22a6ea4691fdd2b9c72d4cfc5221082',
            fingerprint='0EBF782C5D53F7E5FB02A66746BD761F7A49B0EC',
            delivery_classification='DIRECT_RECIPIENT_DOWNLOAD', redirect_hosts=['keyserver.ubuntu.com'],
        )
        for package in base['packages']:
            package['delivery_classification'] = 'DIRECT_RECIPIENT_DOWNLOAD'
            package['signature']['delivery_classification'] = 'DIRECT_RECIPIENT_DOWNLOAD'
        manifest['build_prerequisites'] = [base]
        return manifest

    def test_msys_archive_requires_exact_signature_key_and_all_child_routes(self):
        manifest = self._msys_archive_manifest()
        self._write_outer_manifest(manifest)
        result = self._run(require_installable=True)
        self.assertEqual(result.returncode, 0, result.stdout + result.stderr)
        changes = [
            lambda base: base.update(artifact_kind='installer'),
            lambda base: base.pop('signature'),
            lambda base: base['signature'].update(sha256='0' * 64),
            lambda base: base['installer_key'].update(fingerprint='0' * 40),
            lambda base: base['installer_key'].update(bytes=1),
            lambda base: base['signature'].update(delivery_classification='BLOCKED'),
            lambda base: base['packages'][0]['signature'].update(redirect_hosts=['wrong.example.org']),
            lambda base: base['packages'][0].update(delivery_classification='BLOCKED'),
        ]
        for change in changes:
            with self.subTest(change=change):
                manifest = self._msys_archive_manifest()
                change(manifest['build_prerequisites'][0])
                self._write_outer_manifest(manifest)
                result = self._run(require_installable=True)
                self.assertNotEqual(result.returncode, 0, result.stdout + result.stderr)

    def test_msys_archive_shape_is_checked_even_while_route_blocked(self):
        manifest = self._msys_archive_manifest()
        manifest['build_prerequisites'][0]['delivery_classification'] = 'BLOCKED'
        manifest['build_prerequisites'][0]['signature']['bytes'] = 1
        self._assert_rejected(manifest)

    def test_native_build_assets_must_match_pinned_recipe(self):
        native = {
            "filename": "source-1.tar.xz", "url": "https://source.example.org/source-1.tar.xz",
            "bytes": 7, "sha256": digest(b"source!"),
            "delivery_classification": "DIRECT_RECIPIENT_DOWNLOAD",
            "redirect_hosts": ["source.example.org"], "profile": "both",
        }
        self.payload["build-native-from-source.ps1"] = (
            "$source = Get-VerifiedSource '{filename}' '{url}' {bytes} '{sha256}'\n".format(**native)
        ).encode()
        self._write_archive()
        manifest = self._outer_manifest()
        manifest["native_build_assets"] = [native]
        self._write_outer_manifest(manifest)
        self.assertEqual(self._run().returncode, 0)
        for assets in ([], [dict(native, sha256="0" * 64)], [native, native]):
            with self.subTest(assets=assets):
                manifest["native_build_assets"] = assets
                self._write_outer_manifest(manifest)
                result = self._run()
                self.assertNotEqual(result.returncode, 0, result.stdout + result.stderr)
                self.assertIn("native build asset", result.stderr)

    def test_native_build_assets_cannot_be_omitted(self):
        self.payload["build-native-from-source.ps1"] = (
            "Get-VerifiedSource 'source.tar.xz' 'https://source.example.org/source.tar.xz' 1 '" + "a" * 64 + "'\n"
        ).encode()
        self._write_archive()
        self._write_outer_manifest()
        result = self._run()
        self.assertNotEqual(result.returncode, 0, result.stdout + result.stderr)
        self.assertIn("native build asset", result.stderr)

    def test_installable_requires_exact_redirect_host_policy(self):
        prerequisite = {
            "identity": "fixture-tool", "version": "1", "architecture": "x64",
            "profile": "cpu", "publisher": "Fixture", "purpose": "test",
            "delivery_classification": "DIRECT_RECIPIENT_DOWNLOAD",
            "url": "https://vendor.example.org/tool.zip", "bytes": 1,
            "sha256": digest(b"t"), "detection": "fixture", "post_install_check": "fixture",
            "license_evidence": "synthetic fixture", "installer_arguments": [],
            "success_exit_codes": [], "reboot_behavior": "none",
        }
        for hosts in (None, ["*.example.org"], ["other.example.org"]):
            with self.subTest(hosts=hosts):
                manifest = self._outer_manifest()
                manifest["build_prerequisites"] = [dict(prerequisite, redirect_hosts=hosts)]
                self._write_outer_manifest(manifest)
                result = self._run(require_installable=True)
                self.assertNotEqual(result.returncode, 0, result.stdout + result.stderr)
                self.assertIn("redirect host policy", result.stderr)
        manifest["build_prerequisites"][0]["redirect_hosts"] = ["vendor.example.org"]
        self._write_outer_manifest(manifest)
        result = self._run(require_installable=True)
        self.assertEqual(result.returncode, 0, result.stdout + result.stderr)

    def test_installable_source_requires_safe_url_and_host_policy(self):
        for changes in ({"redirect_hosts": []}, {"url": "https://example.org:444/release.zip"},
                        {"url": "https://example.org/release.zip#fragment"}):
            with self.subTest(changes=changes):
                manifest = self._outer_manifest()
                manifest["target_release"].update(changes)
                self._write_outer_manifest(manifest)
                result = self._run(require_installable=True)
                self.assertNotEqual(result.returncode, 0, result.stdout + result.stderr)
                self.assertIn("redirect host policy", result.stderr)

    def test_installable_publisher_and_external_routes_require_host_policies(self):
        for group in ("publisher_wheels", "external_assets"):
            with self.subTest(group=group):
                manifest = self._outer_manifest()
                entry = manifest[group] if group == "publisher_wheels" else manifest[group][0]
                entry["redirect_hosts"] = []
                self._write_outer_manifest(manifest)
                result = self._run(require_installable=True)
                self.assertNotEqual(result.returncode, 0, result.stdout + result.stderr)
                self.assertIn("redirect host policy", result.stderr)

    def test_archive_hash_mismatch_fails(self):
        manifest = self._outer_manifest()
        manifest["target_release"]["sha256"] = "0" * 64
        self._assert_rejected(manifest)

    def test_external_asset_missing_from_selection_fails(self):
        manifest = self._outer_manifest()
        manifest["external_assets"] = []
        self._assert_rejected(manifest)

    def test_direct_download_cannot_be_a_setup_payload_member(self):
        path = "vendor/nvidia-installer.exe"
        self.payload[path] = b"third-party installer"
        self._write_archive()
        manifest = self._outer_manifest()
        manifest["setup_payload"].append({
            "path": path,
            "sha256": digest(self.payload[path]),
            "delivery_classification": "DIRECT_RECIPIENT_DOWNLOAD",
        })
        self._assert_rejected(manifest)

    def test_unindexed_nested_file_fails(self):
        with zipfile.ZipFile(self.archive, "a", zipfile.ZIP_DEFLATED) as archive:
            archive.writestr("unexpected/cache.bin", b"unindexed bytes")
        # The outer archive digest also changes; preserve it so this specifically
        # exercises exact member inventory checking.
        manifest = self._outer_manifest()
        self._assert_rejected(manifest)

    def test_publisher_wheel_must_use_direct_recipient_classification(self):
        manifest = self._outer_manifest()
        manifest["publisher_wheels"]["delivery_classification"] = "BUNDLE_ALLOWED"
        self._assert_rejected(manifest)

    def test_nested_archive_cannot_hide_forbidden_vendor_binary(self):
        path = "payload/vendor-runtime.zip"
        self.payload[path] = nested_zip({"NVIDIA/cuda-installer.dll": b"vendor binary"})
        self._write_archive()
        self._write_outer_manifest()

        result = self._run()

        self.assertNotEqual(result.returncode, 0, result.stdout + result.stderr)
        self.assertIn("prohibited", result.stderr.lower())
        self.assertIn("cuda-installer.dll", result.stderr.lower())

    def test_nested_first_party_assets_are_allowed(self):
        self.payload["payload/first-party-assets.zip"] = nested_zip({
            "assets/intro.txt": b"AutoClip first-party help text",
            "assets/LICENSE": b"First-party asset terms",
        })
        self._write_archive()
        self._write_outer_manifest()

        result = self._run()

        self.assertEqual(result.returncode, 0, result.stdout + result.stderr)

    def test_escaping_nested_symlink_is_rejected(self):
        nested = io.BytesIO()
        with zipfile.ZipFile(nested, "w") as archive:
            link = zipfile.ZipInfo("assets/outside-link")
            link.create_system = 3
            link.external_attr = 0o120777 << 16
            archive.writestr(link, b"../../outside")
        self.payload["payload/linked-assets.zip"] = nested.getvalue()
        self._write_archive()
        self._write_outer_manifest()

        result = self._run()

        self.assertNotEqual(result.returncode, 0, result.stdout + result.stderr)
        self.assertIn("link", result.stderr.lower())


if __name__ == "__main__":
    unittest.main()
