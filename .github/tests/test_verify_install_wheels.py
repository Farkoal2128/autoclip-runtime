import base64
import hashlib
import importlib.util
import tempfile
import unittest
import zipfile
from pathlib import Path


SCRIPT = Path(__file__).resolve().parents[2] / "scripts" / "verify-install-wheels.py"
spec = importlib.util.spec_from_file_location("verify_install_wheels", SCRIPT)
module = importlib.util.module_from_spec(spec)
spec.loader.exec_module(module)


class WheelIntegrityTest(unittest.TestCase):
    def test_rejects_record_mismatch_before_install(self):
        with tempfile.TemporaryDirectory() as directory:
            wheel = Path(directory) / "sample-1-py3-none-any.whl"
            payload = b"actual payload"
            digest = base64.urlsafe_b64encode(hashlib.sha256(payload).digest()).rstrip(b"=").decode()
            with zipfile.ZipFile(wheel, "w") as archive:
                archive.writestr("sample/__init__.py", payload)
                archive.writestr("sample-1.dist-info/RECORD", f"sample/__init__.py,sha256={digest},{len(payload)}\n" "sample-1.dist-info/RECORD,,\n")
            self.assertEqual(module.verify_wheel(wheel), 2)
            with zipfile.ZipFile(wheel, "w") as archive:
                archive.writestr("sample/__init__.py", payload)
                archive.writestr("sample-1.dist-info/RECORD", "sample/__init__.py,sha256=wrong,14\n" "sample-1.dist-info/RECORD,,\n")
            with self.assertRaisesRegex(ValueError, "RECORD hash mismatch"):
                module.verify_wheel(wheel)


if __name__ == "__main__":
    unittest.main()
