"""The current GCC runtime row must distinguish C5 review from old pending state."""

import hashlib
import importlib.util
import unittest
from pathlib import Path


SCRIPT = Path(__file__).resolve().parents[2] / "scripts" / "build-source-routed-release.py"
spec = importlib.util.spec_from_file_location("source_routed_release", SCRIPT)
module = importlib.util.module_from_spec(spec)
spec.loader.exec_module(module)


class C5ReviewOverlayTest(unittest.TestCase):
    def test_current_review_requires_exact_evidence_and_historical_pending_fields(self):
        evidence = b"attributable C5 reassessment\n"
        path = "notices-and-source/component-evidence/cr09-c5-public-evidence-reassessment.md"
        digest = hashlib.sha256(evidence).hexdigest()
        rule = {
            "artifact_sha256": "a" * 64,
            "member_path": "bin/libopenblas.dll",
            "member_sha256": "b" * 64,
            "component": "gcc-fortran-runtime",
            "review_path": path,
            "review_sha256": digest,
            "current_version_scope": "GCC 9.3.0 identified in exact DLL; precise object set not independently enumerated",
        }
        component = {
            "name": "gcc-fortran-runtime",
            "fulfillment_status": "pending_exact_publisher_build_evidence",
            "exception_eligibility": "pending",
            "build_evidence": [],
            "required_input": "private publisher build log",
        }
        asset = {
            "sha256": rule["artifact_sha256"],
            "member_path": rule["member_path"],
            "member_sha256": rule["member_sha256"],
            "components": [component],
        }
        with self.assertRaisesRegex(ValueError, "Missing historical C5 review state"):
            module.validate_c5_review_overlay([asset], rule, {path: evidence}.__getitem__)

        old = {key: component.pop(key) for key in (
            "fulfillment_status", "exception_eligibility", "build_evidence", "required_input")}
        component.update(
            historical_review_state=old,
            fulfillment_status="exact_notices_delivered_c5_supported_bounded_review",
            exception_eligibility="supported_by_artifact_bound_public_evidence",
            build_evidence=[{"path": path, "sha256": digest}],
            optional_higher_assurance_input="private publisher build log or maintainer attestation",
            current_review={
                "path": path,
                "sha256": digest,
                "scope": "bounded engineering/compliance review for exact external OpenBLAS DLL",
            },
            version_scope=rule["current_version_scope"],
        )
        module.validate_c5_review_overlay([asset], rule, {path: evidence}.__getitem__)
        component["version_scope"] = "precise incorporated object set pending publisher evidence"
        with self.assertRaisesRegex(ValueError, "Stale current C5 version scope"):
            module.validate_c5_review_overlay([asset], rule, {path: evidence}.__getitem__)
        component["version_scope"] = rule["current_version_scope"]
        component["current_review"]["sha256"] = "0" * 64
        with self.assertRaisesRegex(ValueError, "C5 review evidence mismatch"):
            module.validate_c5_review_overlay([asset], rule, {path: evidence}.__getitem__)


if __name__ == "__main__":
    unittest.main()
