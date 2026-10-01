"""A changed app wheel must never inherit the prior wheel's review decision."""

import importlib.util
import unittest
from pathlib import Path


SCRIPT = Path(__file__).resolve().parents[2] / "scripts/build-v41-sequential-successor.py"


class SequentialSuccessorTests(unittest.TestCase):
    def test_new_wheel_review_remains_pending(self):
        spec = importlib.util.spec_from_file_location("sequential_successor", SCRIPT)
        module = importlib.util.module_from_spec(spec)
        spec.loader.exec_module(module)
        row = {"review_disposition": "scoped_app_wheel_continuity_supported",
               "disposition": "pending_exact_successor_review"}
        result = module.pending_app_row(row)
        self.assertEqual(result["review_disposition"], "pending_exact_new_app_wheel_review")
        self.assertEqual(result["disposition"], "pending_exact_successor_review")
        self.assertEqual(row["review_disposition"], "scoped_app_wheel_continuity_supported")


if __name__ == "__main__":
    unittest.main()
