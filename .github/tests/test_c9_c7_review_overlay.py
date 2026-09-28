"""Reviewed C7 notice delivery must not remain pending in current metadata."""

import hashlib
import importlib.util
import unittest
from pathlib import Path


SCRIPT = Path(__file__).resolve().parents[2] / "scripts" / "build-source-routed-release.py"
spec = importlib.util.spec_from_file_location("source_routed_release", SCRIPT)
module = importlib.util.module_from_spec(spec)
spec.loader.exec_module(module)


class C7ReviewOverlayTest(unittest.TestCase):
    def test_current_review_binds_exact_decision_and_two_components(self):
        review = b"attributable v33 C7 decision\n"
        path = "notices-and-source/component-evidence/cr09-v33-independent-c7-review.md"
        rule = {
            "artifact_sha256": "a" * 64,
            "member_path": "bin/libopenblas.dll",
            "member_sha256": "b" * 64,
            "components": ["mingw-w64-runtime", "winpthreads"],
            "review_path": path,
            "review_sha256": hashlib.sha256(review).hexdigest(),
            "current_review_scope": "exact v33 C7 notice/mapping continuity only",
        }
        asset = {"sha256": rule["artifact_sha256"], "member_path": rule["member_path"],
                 "member_sha256": rule["member_sha256"], "components": [
                     {"name": name, "fulfillment_status": "exact_notice_delivered_focused_independent_review_pending"}
                     for name in rule["components"]]}
        files = {path: review}
        with self.assertRaisesRegex(ValueError, "Stale current C7 review state"):
            module.validate_c7_review_overlay([asset], rule, files.__getitem__)
        for component in asset["components"]:
            component["previous_review_state"] = {"fulfillment_status": component.pop("fulfillment_status")}
            component["fulfillment_status"] = "exact_notice_delivered_independent_v33_review_carried_forward"
            component["current_review"] = {"path": path, "sha256": rule["review_sha256"],
                                            "scope": "exact v33 C7 notice/mapping continuity only"}
        module.validate_c7_review_overlay([asset], rule, files.__getitem__)
        asset["components"][0]["current_review"]["scope"] = "all MinGW notices legally cleared"
        with self.assertRaisesRegex(ValueError, "C7 review evidence mismatch"):
            module.validate_c7_review_overlay([asset], rule, files.__getitem__)
        asset["components"][0]["current_review"]["scope"] = rule["current_review_scope"]
        files[path] = b"altered"
        with self.assertRaisesRegex(ValueError, "C7 review evidence mismatch"):
            module.validate_c7_review_overlay([asset], rule, files.__getitem__)


if __name__ == "__main__":
    unittest.main()
