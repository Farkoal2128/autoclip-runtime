"""A dependency/app successor must reject incomplete or inconsistent inputs."""

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


SCRIPT = Path(__file__).resolve().parents[2] / "scripts" / "validate-dependency-app-successor.py"
spec = importlib.util.spec_from_file_location("dependency_app_successor", SCRIPT)
module = importlib.util.module_from_spec(spec)
spec.loader.exec_module(module)


def wheel(path: Path, name: str, version: str, *, license_text=b"grant", sbom=None) -> None:
    stem = f"{name}-{version}.dist-info"
    files = {
        f"{stem}/METADATA": (
            f"Metadata-Version: 2.4\nName: {name}\nVersion: {version}\n"
            f"License-Expression: MIT\nLicense-File: LICENSE\n"
        ).encode(),
        f"{stem}/licenses/LICENSE": license_text,
        f"{name}/__init__.py": b"pass\n",
    }
    if sbom is not None:
        files[f"{stem}/sboms/components.json"] = json.dumps(sbom).encode()
    records = []
    for member, data in files.items():
        digest = base64.urlsafe_b64encode(hashlib.sha256(data).digest()).rstrip(b"=").decode()
        records.append((member, "sha256=" + digest, str(len(data))))
    records.append((f"{stem}/RECORD", "", ""))
    text = io.StringIO(newline="")
    csv.writer(text, lineterminator="\n").writerows(records)
    with zipfile.ZipFile(path, "w") as archive:
        for member, data in files.items():
            archive.writestr(member, data)
        archive.writestr(f"{stem}/RECORD", text.getvalue())


class DependencyAppSuccessorTest(unittest.TestCase):
    def test_verifies_wheel_record_and_exact_metadata(self):
        with tempfile.TemporaryDirectory() as directory:
            path = Path(directory) / "pillow-12.3.0-py3-none-any.whl"
            wheel(path, "pillow", "12.3.0")
            info = module.verify_wheel(path)
            self.assertEqual(info["name"], "pillow")
            self.assertEqual(info["version"], "12.3.0")
            self.assertEqual(info["license_expression"], "MIT")
            self.assertEqual(len(info["legal_files"]), 1)
            with zipfile.ZipFile(path, "a") as archive:
                archive.writestr("pillow/__init__.py", b"tampered")
            with self.assertRaisesRegex(ValueError, "Duplicate|RECORD"):
                module.verify_wheel(path)

    def test_new_publisher_row_must_bind_exact_wheel_and_pypi_url(self):
        with tempfile.TemporaryDirectory() as directory:
            path = Path(directory) / "pillow-12.3.0-py3-none-any.whl"
            wheel(path, "pillow", "12.3.0")
            row = dict(package="pillow", version="12.3.0", filename=path.name,
                       tags=["py3-none-any"], bytes=path.stat().st_size,
                       sha256=hashlib.sha256(path.read_bytes()).hexdigest(),
                       url="https://files.pythonhosted.org/packages/pillow.whl",
                       publisher_identity="PyPI project pillow", delivery_policy="publisher")
            module.validate_publisher_delta(path, row)
            with self.assertRaisesRegex(ValueError, "publisher"):
                module.validate_publisher_delta(path, dict(row, sha256="0" * 64))
            with self.assertRaisesRegex(ValueError, "publisher"):
                module.validate_publisher_delta(path, dict(row, url="https://example.org/pillow.whl"))

    def test_requires_committed_app_source_and_reviewed_delta(self):
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory)
            app = root / "autoclip-0.1.0.dev0-py3-none-any.whl"
            wheel(app, "autoclip", "0.1.0.dev0")
            with self.assertRaisesRegex(ValueError, "app source"):
                module.validate_app_build_receipt_consistency(app, {}, lambda *_: b"")
            with self.assertRaisesRegex(ValueError, "review"):
                module.validate_review_delta({})

    def test_sbom_declarations_require_exact_component_dispositions(self):
        with tempfile.TemporaryDirectory() as directory:
            path = Path(directory) / "pillow-12.3.0-py3-none-any.whl"
            sbom = {"bomFormat": "CycloneDX", "components": [
                {"bom-ref": "pkg:generic/native@1", "name": "native",
                 "version": "1", "purl": "pkg:generic/native@1"}]}
            wheel(path, "pillow", "12.3.0", sbom=sbom)
            info = module.verify_wheel(path)
            self.assertEqual(info["sbom_components"][0]["bom_ref"], "pkg:generic/native@1")
            with self.assertRaisesRegex(ValueError, "review.*component"):
                module.validate_review_delta({
                    "schema_version": 1, "reviewer": "fixture", "publisher_wheel_sha256": info["sha256"],
                    "component_dispositions": [], "app_wheel_sha256": "a" * 64,
                    "publisher_legal_files": info["legal_files"],
                    "app_legal_files": [{"path": "app/LICENSE", "sha256": "b" * 64}],
                }, publisher=info, app_sha="a" * 64)


if __name__ == "__main__":
    unittest.main()
