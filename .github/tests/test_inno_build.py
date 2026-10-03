"""Behavioral checks for guarded Inno candidate builds on Windows."""

import hashlib
import importlib.util
import json
import os
import shutil
import subprocess
import sys
import tempfile
import unittest
import zipfile
from pathlib import Path


ROOT = Path(__file__).resolve().parents[2]
BUILDER = ROOT / "scripts" / "build-inno.py"
SOURCE = ROOT / "installer" / "AutoClip.iss"
NOTICE_NAMES = (
    "inno-setup-7.1.0-LICENSE.txt",
    "uv-0.12.19-LICENSE-MIT.txt",
    "uv-0.12.19-LICENSE-APACHE.txt",
    "setup-tool-sources.md",
)


def digest(data):
    return hashlib.sha256(data).hexdigest()


def encoded(value):
    return (json.dumps(value, sort_keys=True, indent=2) + "\n").encode()


@unittest.skipUnless(os.name == "nt", "Inno build invocation is Windows-only")
class InnoBuildTests(unittest.TestCase):
    def setUp(self):
        self.temp = tempfile.TemporaryDirectory(prefix="inno build fixture ")
        self.addCleanup(self.temp.cleanup)
        self.root = Path(self.temp.name)
        self.archive = self.root / "release.zip"
        self.manifest_path = self.root / "installer-manifest.json"
        self.output = self.root / "output"
        self.output.mkdir()
        self.candidate = self.output / "AutoClip-Setup-v1.exe"
        self.candidate_bytes = b"synthetic setup candidate bytes"
        self.candidate_input = self.root / "fake-compiler-output.bin"
        self.candidate_input.write_bytes(self.candidate_bytes)
        self.marker = self.root / "iscc-called.txt"
        self.iscc = self.root / "fake-iscc.cmd"
        self._make_fake_iscc()
        self.payload = {"app/AutoClip.bin": b"first-party app payload"}
        self.wheel = {
            "filename": "example-1-py3-none-any.whl",
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

    def _make_fake_iscc(self):
        self.iscc.write_text(
            "@echo off\r\n"
            f'>>"{self.marker}" echo %*\r\n'
            f'copy /y "{self.candidate_input}" "{self.candidate}" >nul\r\n'
            f'copy /y "{self.candidate_input}" "{self.output / "AutoClip-Maintenance.exe"}" >nul\r\n'
            "exit /b 0\r\n",
            encoding="ascii",
        )

    def _write_archive(self):
        publisher = encoded({"schema_version": 1, "wheels": [self.wheel]})
        inventory = encoded({
            "schema_version": 1,
            "publisher_wheels": [self.wheel["filename"]],
            "external_assets": [self.external],
        })
        files = {
            **self.payload,
            "publisher-wheel-manifest.json": publisher,
            "distribution-inventory.json": inventory,
        }
        release = encoded({
            "schema_version": 3,
            "files": [
                {"path": path, "bytes": len(data), "sha256": digest(data)}
                for path, data in sorted(files.items())
            ],
            "publisher_wheels": [self.wheel],
            "external_assets": [self.external],
        })
        with zipfile.ZipFile(self.archive, "w", zipfile.ZIP_DEFLATED) as output:
            for path, data in files.items():
                output.writestr(path, data)
            output.writestr("release-manifest.json", release)
        self.release_manifest = release
        self.inventory = inventory
        self._write_outer_manifest()

    def _write_outer_manifest(self, build_prerequisites=None):
        archive = self.archive.read_bytes()
        manifest = {
            "schema_version": 1,
            "target_release": {
                "id": "fixture-v1",
                "url": "https://example.org/release.zip",
                "delivery_classification": "DIRECT_RECIPIENT_DOWNLOAD",
                "redirect_hosts": ["example.org"],
                "bytes": len(archive),
                "sha256": digest(archive),
                "manifest_sha256": digest(self.release_manifest),
                "distribution_inventory_sha256": digest(self.inventory),
            },
            "publisher_wheels": {
                "redirect_hosts": ["files.pythonhosted.org"],
                "manifest_path": "publisher-wheel-manifest.json",
                "sha256": digest(encoded({"schema_version": 1, "wheels": [self.wheel]})),
                "count": 1,
                "delivery_classification": "DIRECT_RECIPIENT_DOWNLOAD",
                "license_evidence": "synthetic fixture",
            },
            "external_assets": [self.external],
            "setup_payload": [
                {"path": path, "sha256": digest(data),
                 "delivery_classification": "BUNDLE_ALLOWED"}
                for path, data in sorted(self.payload.items())
            ],
            "compiler": {
                "identity": "Inno Setup compiler fixture",
                "version": "7.1.0",
                "url": "https://example.org/iscc.exe",
                "bytes": self.iscc.stat().st_size,
                "sha256": digest(self.iscc.read_bytes()),
                "delivery_classification": "SYSTEM_PROVIDED",
                "license_evidence": "synthetic fixture",
            },
            "build_prerequisites": build_prerequisites or [],
        }
        self.manifest_path.write_bytes(encoded(manifest))

    def _run(self, builder=BUILDER):
        return subprocess.run(
            [sys.executable, str(builder), "--manifest", str(self.manifest_path),
             "--archive", str(self.archive), "--iscc", str(self.iscc),
             "--output-dir", str(self.output)],
            capture_output=True, text=True, check=False, cwd=ROOT,
        )

    def _input_snapshot(self):
        snapshot = self.root / "locked-input-snapshot"
        for relative in (
            "scripts/build-inno.py", "scripts/verify-installer-manifest.py",
            "install.ps1", "installer/AutoClip.iss", "installer/preflight.ps1",
            "installer/install-tool-archive.ps1", "installer/download-artifact.ps1",
            "installer/install-python.ps1", "installer/install-msys2-base.ps1",
            "installer/extract-msys2-base.py", "installer/install-msys2-packages.ps1",
            "installer/install-runtime-toolpath.ps1",
            "installer/run-source-build.ps1",
            "installer/verify-installed-app.ps1",
            "installer/write-setup-receipt.ps1",
            "installer/uninstall-owned-release.ps1", "installer/remove-owned-file.ps1", "update.ps1",
            "update-app.ps1", "installer/initialize-selection.ps1", "installer/run-maintenance.ps1",
            "installer/AutoClip-Maintenance.iss",
            *(f"release/notices/{name}" for name in NOTICE_NAMES),
        ):
            destination = snapshot / relative
            destination.parent.mkdir(parents=True, exist_ok=True)
            shutil.copy2(ROOT / relative, destination)
        return snapshot

    def test_inputs_block_mutation_and_rename_during_compiler_then_unlock(self):
        snapshot = self._input_snapshot()
        observations = self.root / "mutation-observations.json"
        verifier_observations = self.root / "verifier-mutation-observations.json"
        mutation = self.root / "attempt-input-mutations.py"
        targets = [path for path in snapshot.rglob("*") if path.is_file()]
        targets.extend((self.manifest_path, self.archive, self.iscc))
        mutation.write_text(
            "import json,sys\nfrom pathlib import Path\n"
            f"paths = {list(map(str, targets))!r}\n"
            "results=[]\n"
            "for name in paths:\n"
            "    path=Path(name)\n"
            "    row={'path':name}\n"
            "    for operation in ('write','rename'):\n"
            "        try:\n"
            "            if operation=='write':\n"
            "                with path.open('r+b') as stream:\n"
            "                    stream.write(b'X')\n"
            "            else:\n"
            "                renamed=path.with_name(path.name+'.renamed')\n"
            "                path.rename(renamed)\n"
            "                renamed.rename(path)\n"
            "        except OSError as error:\n"
            "            row[operation]={'errno':error.errno,'winerror':error.winerror}\n"
            "        else:\n"
            "            row[operation]=None\n"
            "    results.append(row)\n"
            f"output=Path(sys.argv[1]) if len(sys.argv)>1 else Path({str(observations)!r})\n"
            "output.write_text(json.dumps(results))\n",
            encoding="utf-8",
        )
        self.iscc.write_text(
            "@echo off\r\n"
            f'>>"{self.marker}" echo %*\r\n'
            f'"{sys.executable}" "{mutation}"\r\n'
            f'copy /y "{self.candidate_input}" "{self.candidate}" >nul\r\n'
            f'copy /y "{self.candidate_input}" "{self.output / "AutoClip-Maintenance.exe"}" >nul\r\n'
            "exit /b 0\r\n", encoding="ascii",
        )
        verifier = snapshot / "scripts/verify-installer-manifest.py"
        verifier.write_text(
            "import subprocess,sys\n"
            f"subprocess.run([sys.executable,{str(mutation)!r},{str(verifier_observations)!r}],check=True)\n"
            + verifier.read_text(encoding="utf-8"), encoding="utf-8",
        )
        self._write_outer_manifest()
        expected = {str(path): digest(path.read_bytes()) for path in targets}

        result = self._run(snapshot / "scripts/build-inno.py")

        for observed in (verifier_observations, observations):
            self.assertTrue(observed.is_file(), result.stdout + result.stderr)
            for row in json.loads(observed.read_text()):
                self.assertIsNotNone(row["write"], row)
                self.assertEqual(row["write"]["errno"], 13, row)
                self.assertIsNotNone(row["rename"], row)
                self.assertEqual(row["rename"]["winerror"], 32, row)
        self.assertEqual(result.returncode, 0, result.stdout + result.stderr)
        receipt = json.loads((self.output / "AutoClip-Setup-v1.receipt.json").read_text())
        self.assertEqual(receipt["source_sha256"], expected[str(snapshot / "installer/AutoClip.iss")])
        self.assertEqual(receipt["manifest_sha256"], expected[str(self.manifest_path)])
        self.assertEqual(receipt["builder_sha256"], expected[str(snapshot / "scripts/build-inno.py")])
        # The builder process has finished: real write/rename succeeds for every input.
        for path in targets:
            self.assertEqual(digest(path.read_bytes()), expected[str(path)], str(path))
            with path.open("r+b") as stream:
                stream.write(b"X")
            renamed = path.with_name(path.name + ".after-build")
            path.rename(renamed)
            renamed.rename(path)

    def test_input_locks_release_in_same_process_after_success_and_failures(self):
        for outcome in ("success", "compiler-failure", "missing-helper", "changed-notice"):
            with self.subTest(outcome=outcome):
                snapshot = self._input_snapshot()
                self.output = self.root / outcome
                self.output.mkdir()
                self.candidate = self.output / "AutoClip-Setup-v1.exe"
                self.marker = self.output / "iscc-called.txt"
                self._make_fake_iscc()
                if outcome == "compiler-failure":
                    self.iscc.write_text(
                        f'@echo off\r\n>>"{self.marker}" echo called\r\nexit /b 7\r\n',
                        encoding="ascii",
                    )
                self._write_archive()
                if outcome == "missing-helper":
                    (snapshot / "installer/install-runtime-toolpath.ps1").unlink()
                elif outcome == "changed-notice":
                    (snapshot / "release/notices/uv-0.12.19-LICENSE-MIT.txt").write_bytes(b"changed")
                targets = [path for path in snapshot.rglob("*") if path.is_file()]
                targets.extend((self.manifest_path, self.archive, self.iscc))
                harness = self.root / "build-and-check-release.py"
                harness.write_text(
                    "import importlib.util\nfrom argparse import Namespace\nfrom pathlib import Path\n"
                    f"spec=importlib.util.spec_from_file_location('fixture_builder',{str(snapshot / 'scripts/build-inno.py')!r})\n"
                    "builder=importlib.util.module_from_spec(spec)\nspec.loader.exec_module(builder)\n"
                    f"args=Namespace(manifest=Path({str(self.manifest_path)!r}),archive=Path({str(self.archive)!r}),iscc=Path({str(self.iscc)!r}),output_dir=Path({str(self.output)!r}),profile='cpu')\n"
                    "failed=False\n"
                    "try:\n    builder.build(args)\n"
                    "except (OSError,ValueError,RuntimeError):\n    failed=True\n"
                    f"assert failed is {outcome != 'success'!r}, 'unexpected build disposition'\n"
                    f"for name in {list(map(str, targets))!r}:\n"
                    "    path=Path(name)\n"
                    "    with path.open('r+b') as stream:\n        stream.write(b'X')\n"
                    "    renamed=path.with_name(path.name+'.unlocked')\n"
                    "    path.rename(renamed)\n    renamed.rename(path)\n"
                    "print('all input handles released before process exit')\n",
                    encoding="utf-8",
                )

                result = subprocess.run([sys.executable, str(harness)], capture_output=True,
                                        text=True, check=False, cwd=ROOT)

                self.assertEqual(result.returncode, 0, result.stdout + result.stderr)
                self.assertIn("all input handles released before process exit", result.stdout)
                self.assertEqual(self.marker.exists(), outcome in ("success", "compiler-failure"))

    def _assert_cli_exists(self, result):
        self.assertNotRegex(result.stderr, r"can't open file .*build-inno\.py")

    def test_blocked_cpu_prerequisite_refuses_before_compiler_or_output(self):
        self._write_outer_manifest([{
            "identity": "CPU prerequisite fixture",
            "profile": "cpu",
            "delivery_classification": "BLOCKED",
            "reason": "test gate",
        }])

        result = self._run()

        self.assertNotEqual(result.returncode, 0, result.stdout + result.stderr)
        self._assert_cli_exists(result)
        self.assertIn("BLOCKED", result.stdout + result.stderr)
        self.assertFalse(self.marker.exists(), "ISCC was called despite a blocked CPU prerequisite")
        self.assertFalse(self.candidate.exists(), "candidate exists despite blocked prerequisite")

    def test_verified_unblocked_graph_invokes_compiler_and_writes_hashed_receipt(self):
        result = self._run()

        self.assertEqual(result.returncode, 0, result.stdout + result.stderr)
        self.assertTrue(self.marker.is_file(), "fake ISCC was not called")
        self.assertEqual(self.candidate.read_bytes(), self.candidate_bytes)
        receipt = json.loads((self.output / "AutoClip-Setup-v1.receipt.json").read_text(encoding="utf-8"))
        expected = {
            "archive_sha256": digest(self.archive.read_bytes()),
            "manifest_sha256": digest(self.manifest_path.read_bytes()),
            "iscc_sha256": digest(self.iscc.read_bytes()),
            "source_sha256": digest(SOURCE.read_bytes()),
            "preflight_sha256": digest((ROOT / "installer" / "preflight.ps1").read_bytes()),
            "tool_archive_helper_sha256": digest((ROOT / "installer" / "install-tool-archive.ps1").read_bytes()),
            "download_helper_sha256": digest((ROOT / "installer" / "download-artifact.ps1").read_bytes()),
            "python_helper_sha256": digest((ROOT / "installer" / "install-python.ps1").read_bytes()),
            "msys_base_helper_sha256": digest((ROOT / "installer" / "install-msys2-base.ps1").read_bytes()),
            "msys_extractor_sha256": digest((ROOT / "installer" / "extract-msys2-base.py").read_bytes()),
            "msys_packages_helper_sha256": digest((ROOT / "installer" / "install-msys2-packages.ps1").read_bytes()),
            "runtime_toolpath_helper_sha256": digest((ROOT / "installer" / "install-runtime-toolpath.ps1").read_bytes()),
            "source_build_helper_sha256": digest((ROOT / "installer" / "run-source-build.ps1").read_bytes()),
            "app_health_helper_sha256": digest((ROOT / "installer" / "verify-installed-app.ps1").read_bytes()),
            "uninstall_helper_sha256": digest((ROOT / "installer" / "uninstall-owned-release.ps1").read_bytes()),
            "removal_helper_sha256": digest((ROOT / "installer" / "remove-owned-file.ps1").read_bytes()),
            "updater_sha256": digest((ROOT / "update.ps1").read_bytes()),
            "notice_sha256": digest((ROOT / "release" / "notices" / "inno-setup-7.1.0-LICENSE.txt").read_bytes()),
            "builder_sha256": digest(BUILDER.read_bytes()),
            "verifier_sha256": digest((ROOT / "scripts" / "verify-installer-manifest.py").read_bytes()),
            "exe_sha256": digest(self.candidate_bytes),
        }
        for key, value in expected.items():
            self.assertEqual(receipt[key], value, key)
        self.assertEqual(receipt["notices"], [
            {"path": f"notices/{name}", "bytes": len(data), "sha256": digest(data)}
            for name in NOTICE_NAMES
            for data in [(ROOT / "release/notices" / name).read_bytes()]
        ])

    def test_native_maintenance_is_compiled_pinned_and_owned_by_setup(self):
        result = self._run()
        self.assertEqual(result.returncode, 0, result.stdout + result.stderr)
        receipt = json.loads((self.output / "AutoClip-Setup-v1.receipt.json").read_text())
        self.assertEqual(receipt["maintenance_exe_sha256"], digest(self.candidate_bytes))
        calls = self.marker.read_text().splitlines()
        self.assertEqual(len(calls), 2)
        self.assertIn("AutoClip-Maintenance.iss", calls[0])
        self.assertIn("AutoClip.iss", calls[1])
        self.assertIn("--define=MaintenanceExeSha256=" + digest(self.candidate_bytes), calls[1])
        self.assertIn('"path":"AutoClip-Maintenance.exe"', calls[1].replace('\\"', '"'))

    def test_missing_or_changed_license_refuses_before_compiler(self):
        for name in NOTICE_NAMES[:3]:
            for changed in (False, True):
                with self.subTest(name=name, changed=changed):
                    snapshot = self.root / f"snapshot-{name}-{changed}"
                    shutil.copytree(ROOT / "installer", snapshot / "installer")
                    self.output = snapshot / "output"
                    self.output.mkdir()
                    self.candidate = self.output / "AutoClip-Setup-v1.exe"
                    self.marker = snapshot / "iscc-called.txt"
                    self._make_fake_iscc()
                    self._write_outer_manifest()
                    (snapshot / "scripts").mkdir()
                    for script in (BUILDER, ROOT / "scripts/verify-installer-manifest.py"):
                        shutil.copy2(script, snapshot / "scripts" / script.name)
                    shutil.copy2(ROOT / "install.ps1", snapshot / "install.ps1")
                    shutil.copy2(ROOT / "update.ps1", snapshot / "update.ps1")
                    shutil.copy2(ROOT / "update-app.ps1", snapshot / "update-app.ps1")
                    notices = snapshot / "release/notices"
                    notices.mkdir(parents=True)
                    for notice_name in NOTICE_NAMES:
                        source = ROOT / "release/notices" / notice_name
                        if source.is_file():
                            shutil.copy2(source, notices / notice_name)
                    notice = notices / name
                    if changed:
                        data = notice.read_bytes()
                        notice.write_bytes(b"X" + data[1:])
                    else:
                        notice.unlink()

                    result = self._run(snapshot / "scripts/build-inno.py")

                    self.assertNotEqual(result.returncode, 0, result.stdout + result.stderr)
                    self.assertIn(name, result.stderr)
                    self.assertFalse(self.marker.exists(), "compiler ran with invalid notice")
                    self.assertFalse(self.candidate.exists())

    def test_setup_installs_all_notices_as_normal_persistent_files(self):
        source = SOURCE.read_text(encoding="utf-8")
        files = source.split("[Files]", 1)[1].split("[Icons]", 1)[0]
        for name in NOTICE_NAMES:
            with self.subTest(name=name):
                entries = [line for line in files.splitlines() if f'\\{name}"' in line]
                self.assertEqual(len(entries), 1)
                self.assertIn('DestDir: "{app}\\notices"', entries[0])
                self.assertNotIn("dontcopy", entries[0])

    def test_changed_archive_refuses_before_compiler_or_output(self):
        with self.archive.open("ab") as archive:
            archive.write(b"changed after manifest pin")

        result = self._run()

        self.assertNotEqual(result.returncode, 0, result.stdout + result.stderr)
        self._assert_cli_exists(result)
        self.assertFalse(self.marker.exists(), "ISCC was called for an archive that failed verification")
        self.assertFalse(self.candidate.exists(), "candidate exists for an archive that failed verification")

    def test_helper_runtime_pins_are_supplied_to_actual_compiler_invocation(self):
        result = self._run()
        self.assertEqual(result.returncode, 0, result.stdout + result.stderr)
        arguments = self.marker.read_text()
        for name, path in {
            "BootstrapSha256": ROOT / "install.ps1",
            "PreflightSha256": ROOT / "installer/preflight.ps1",
            "ToolArchiveHelperSha256": ROOT / "installer/install-tool-archive.ps1",
            "SecureDownloaderSha256": ROOT / "installer/download-artifact.ps1",
            "PythonHelperSha256": ROOT / "installer/install-python.ps1",
            "MsysBaseHelperSha256": ROOT / "installer/install-msys2-base.ps1",
            "MsysExtractorSha256": ROOT / "installer/extract-msys2-base.py",
            "MsysPackagesHelperSha256": ROOT / "installer/install-msys2-packages.ps1",
            "RuntimeToolPathHelperSha256": ROOT / "installer/install-runtime-toolpath.ps1",
            "SourceBuildHelperSha256": ROOT / "installer/run-source-build.ps1",
            "AppHealthHelperSha256": ROOT / "installer/verify-installed-app.ps1",
        }.items():
            self.assertIn(f"--define={name}={digest(path.read_bytes())}", arguments)

    def test_unpinned_direct_prerequisite_refuses_before_compiler(self):
        self._write_outer_manifest([{
            "identity": "CPU tool fixture",
            "profile": "cpu",
            "delivery_classification": "DIRECT_RECIPIENT_DOWNLOAD",
        }])

        result = self._run()

        self.assertNotEqual(result.returncode, 0, result.stdout + result.stderr)
        self.assertIn("CPU tool fixture", result.stderr)
        self.assertFalse(self.marker.exists())

    def test_python_artifact_and_terms_are_bound_to_actual_compiler_invocation(self):
        canonical = json.loads((ROOT / "release/manifests/installer-dependencies-v1.json").read_text())
        python = next(row for row in canonical["build_prerequisites"] if row["identity"] == "Python")
        python["delivery_classification"] = "DIRECT_RECIPIENT_DOWNLOAD"
        self._write_outer_manifest([python])

        result = self._run()

        self.assertEqual(result.returncode, 0, result.stdout + result.stderr)
        arguments = self.marker.read_text()
        self.assertIn(f"--define=PythonSha256={python['sha256']}", arguments)
        self.assertIn(f"--define=PythonTermsUrl={python['terms_url']}", arguments)

    def test_msys_archive_is_bound_to_actual_compiler_invocation(self):
        canonical = json.loads((ROOT / "release/manifests/installer-dependencies-v1.json").read_text())
        base = next(row for row in canonical['build_prerequisites'] if row['identity'] == 'MSYS2')
        for row in [base, base['signature'], base['installer_key']]:
            row['delivery_classification'] = 'DIRECT_RECIPIENT_DOWNLOAD'
        for package in base['packages']:
            package['delivery_classification'] = 'DIRECT_RECIPIENT_DOWNLOAD'
            package['signature']['delivery_classification'] = 'DIRECT_RECIPIENT_DOWNLOAD'
        self._write_outer_manifest([base])
        result = self._run()
        self.assertEqual(result.returncode, 0, result.stdout + result.stderr)
        self.assertIn(f"--define=MsysArchiveSha256={base['sha256']}", self.marker.read_text())

    def _publisher_cpu_graph(self):
        spec = importlib.util.spec_from_file_location("publisher_cpu_graph_fixture", ROOT / ".github/tests/test_installer_manifest.py")
        module = importlib.util.module_from_spec(spec)
        spec.loader.exec_module(module)
        fixture = module.InstallerManifestTests()
        fixture.setUp()
        self.addCleanup(fixture.doCleanups)
        manifest, native = fixture._publisher_cpu_manifest()
        self.archive.write_bytes(fixture.archive.read_bytes())
        manifest["compiler"]["bytes"] = self.iscc.stat().st_size
        manifest["compiler"]["sha256"] = digest(self.iscc.read_bytes())
        self.manifest_path.write_bytes(encoded(manifest))
        return manifest, native

    def test_publisher_cpu_build_binds_native_helper_actual_archive_and_selected_bootstrap(self):
        manifest, native = self._publisher_cpu_graph()
        bootstrap = self.root / "new-cpu-bootstrap.ps1"
        bootstrap.write_bytes(b"# synthetic independent successor bootstrap\n")
        result = subprocess.run(
            [sys.executable, str(BUILDER), "--manifest", str(self.manifest_path),
             "--archive", str(self.archive), "--iscc", str(self.iscc),
             "--output-dir", str(self.output), "--native-artifact", str(native),
             "--bootstrap", str(bootstrap)], capture_output=True, text=True, check=False, cwd=ROOT)
        self.assertEqual(result.returncode, 0, result.stdout + result.stderr)
        arguments = self.marker.read_text()
        artifact = manifest["cpu_native_artifact"]
        for key, value in {
            "NativeCpuEnabled": "1", "CpuNativeIdentity": artifact["identity"],
            "CpuNativeRuntimeId": artifact["runtime_id"], "CpuNativeFilename": artifact["filename"],
            "CpuNativeSha256": artifact["sha256"], "CpuNativeBytes": str(artifact["bytes"]),
            "CpuNativeHelperSha256": digest((ROOT / "installer/install-cpu-native-artifact.py").read_bytes()),
            "PythonPrerequisiteHelperSha256": digest((ROOT / "installer/install-python.ps1").read_bytes()),
            "VcRuntimeHelperSha256": digest((ROOT / "installer/install-vc-runtime.ps1").read_bytes()),
            "BootstrapSha256": digest(bootstrap.read_bytes()), "BootstrapScriptPath": str(bootstrap),
        }.items():
            self.assertIn(f"--define={key}={value}", arguments)
        receipt = json.loads((self.output / "AutoClip-Setup-v1.receipt.json").read_text())
        self.assertEqual(receipt["qualification"], "UNVERIFIED_CANDIDATE")
        self.assertEqual(receipt["cpu_native_artifact"], artifact)
        self.assertEqual(receipt["cpu_native_artifact_sha256"], digest(native.read_bytes()))
        self.assertEqual(receipt["cpu_native_helper_sha256"], digest((ROOT / "installer/install-cpu-native-artifact.py").read_bytes()))
        self.assertEqual(receipt["bootstrap_sha256"], digest(bootstrap.read_bytes()))
        self.assertEqual(receipt["vc_runtime_helper_sha256"], digest((ROOT / "installer/install-vc-runtime.ps1").read_bytes()))

    def test_publisher_cpu_missing_actual_archive_refuses_before_compiler(self):
        self._publisher_cpu_graph()
        result = self._run()
        self.assertNotEqual(result.returncode, 0)
        self.assertIn("actual CPU native artifact", result.stderr)
        self.assertFalse(self.marker.exists())

    def test_publisher_cpu_native_helper_archive_and_bootstrap_hold_real_windows_locks(self):
        manifest, native = self._publisher_cpu_graph()
        snapshot = self._input_snapshot()
        helper = snapshot / "installer/install-cpu-native-artifact.py"
        shutil.copy2(ROOT / "installer/install-cpu-native-artifact.py", helper)
        vc_helper = snapshot / "installer/install-vc-runtime.ps1"
        shutil.copy2(ROOT / "installer/install-vc-runtime.ps1", vc_helper)
        bootstrap = self.root / "locked-new-bootstrap.ps1"
        bootstrap.write_bytes(b"# synthetic locked successor bootstrap\n")
        observations = self.root / "native-input-lock-observations.json"
        probe = self.root / "try-native-input-writes.py"
        targets = [native, helper, vc_helper, bootstrap]
        probe.write_text(
            "import json\nfrom pathlib import Path\nresults=[]\n"
            f"for name in {list(map(str, targets))!r}:\n"
            "    path=Path(name)\n    row={'path':name}\n"
            "    for action in ('write','rename'):\n"
            "        try:\n"
            "            if action=='write':\n                with path.open('r+b') as source:\n                    source.write(b'X')\n"
            "            else:\n                renamed=path.with_name(path.name+'.changed')\n                path.rename(renamed)\n                renamed.rename(path)\n"
            "        except OSError as error:\n            row[action]={'errno':error.errno,'winerror':error.winerror}\n"
            "        else:\n            row[action]=None\n"
            "    results.append(row)\n"
            f"Path({str(observations)!r}).write_text(json.dumps(results))\n", encoding="utf-8")
        self.iscc.write_text(
            "@echo off\r\n" + f'"{sys.executable}" "{probe}"\r\n'
            + f'copy /y "{self.candidate_input}" "{self.candidate}" >nul\r\n'
            + f'copy /y "{self.candidate_input}" "{self.output / "AutoClip-Maintenance.exe"}" >nul\r\nexit /b 0\r\n', encoding="ascii")
        manifest["compiler"].update(bytes=self.iscc.stat().st_size, sha256=digest(self.iscc.read_bytes()))
        self.manifest_path.write_bytes(encoded(manifest))
        before = {path: digest(path.read_bytes()) for path in targets}
        result = subprocess.run(
            [sys.executable, str(snapshot / "scripts/build-inno.py"), "--manifest", str(self.manifest_path),
             "--archive", str(self.archive), "--iscc", str(self.iscc), "--output-dir", str(self.output),
             "--native-artifact", str(native), "--bootstrap", str(bootstrap)],
            capture_output=True, text=True, check=False, cwd=ROOT)
        self.assertEqual(result.returncode, 0, result.stdout + result.stderr)
        for row in json.loads(observations.read_text()):
            self.assertIsNotNone(row["write"], row)
            self.assertEqual(row["write"]["errno"], 13, row)
            self.assertEqual(row["rename"]["winerror"], 32, row)
        for path, expected in before.items():
            self.assertEqual(digest(path.read_bytes()), expected)
            with path.open("r+b") as stream:
                stream.write(b"X")


if __name__ == "__main__":
    unittest.main()
