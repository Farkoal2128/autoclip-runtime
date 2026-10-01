"""Current app successor must keep the legal and asset map tied to wheel bytes."""

import importlib.util
import io
import tempfile
import unittest
import zipfile
from pathlib import Path


SCRIPT = Path(__file__).resolve().parents[2] / "scripts/build-v41-current-app-successor.py"


class CurrentAppSuccessorTests(unittest.TestCase):
    def test_committed_builder_only_allows_newline_conversion(self):
        spec = importlib.util.spec_from_file_location("current_app_successor", SCRIPT)
        module = importlib.util.module_from_spec(spec)
        spec.loader.exec_module(module)
        self.assertTrue(module.source_matches_commit(b"one\ntwo\n", b"one\r\ntwo\r\n"))
        self.assertFalse(module.source_matches_commit(b"one\ntwo\n", b"one\nthree\n"))

    def test_app_row_follows_exact_wheel_assets(self):
        spec = importlib.util.spec_from_file_location("current_app_successor", SCRIPT)
        module = importlib.util.module_from_spec(spec)
        spec.loader.exec_module(module)
        with tempfile.TemporaryDirectory() as folder:
            wheel = Path(folder) / "autoclip.whl"
            with zipfile.ZipFile(wheel, "w") as archive:
                archive.writestr("autoclip/assets/licenses/NOTICE.txt", "notice")
                archive.writestr("autoclip/static/assets/index-new.js", "new")
            row = {
                "filename": "autoclip.whl", "bytes": 1, "sha256": "old",
                "record_rows": 2,
                "legal_files": ["autoclip/assets/licenses/NOTICE.txt"],
                "legal_sha256": {"autoclip/assets/licenses/NOTICE.txt": "old"},
                "data_assets": ["autoclip/static/assets/index-old.js"],
                "data_sha256": {"autoclip/static/assets/index-old.js": "old"},
            }
            updated, notices = module.refresh_app_row(row, wheel)
            self.assertEqual(updated["bytes"], wheel.stat().st_size)
            self.assertEqual(updated["sha256"], module.sha(wheel.read_bytes()))
            self.assertEqual(updated["data_assets"], ["autoclip/static/assets/index-new.js"])
            self.assertEqual(updated["data_sha256"]["autoclip/static/assets/index-new.js"], module.sha(b"new"))
            self.assertEqual(notices["autoclip/assets/licenses/NOTICE.txt"], b"notice")


if __name__ == "__main__":
    unittest.main()
