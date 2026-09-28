"""Current C5 review evidence must be associated with exact committed source."""

import hashlib
import importlib.util
import unittest
from pathlib import Path


SCRIPT = Path(__file__).resolve().parents[2] / "scripts" / "build-source-routed-release.py"
spec = importlib.util.spec_from_file_location("source_routed_release", SCRIPT)
module = importlib.util.module_from_spec(spec)
spec.loader.exec_module(module)


class C5ReviewProvenanceTest(unittest.TestCase):
    def test_missing_wrong_digest_and_wrong_git_object_are_rejected(self):
        raw = b"exact C5 reassessment\n"
        digest = hashlib.sha256(raw).hexdigest()
        rule = {
            "review_source_path": "review-component-evidence/cr09-c5-public-evidence-reassessment.md",
            "review_path": "notices-and-source/component-evidence/cr09-c5-public-evidence-reassessment.md",
            "review_sha256": digest,
        }
        provenance = {"committed_source_sha256": {}}
        read_member = {rule["review_path"]: raw}.__getitem__
        read_git = {rule["review_source_path"]: raw}.__getitem__
        with self.assertRaisesRegex(ValueError, "C5 source provenance mismatch"):
            module.validate_c5_review_source_provenance(provenance, rule, read_member, read_git)
        provenance["committed_source_sha256"][rule["review_source_path"]] = "0" * 64
        with self.assertRaisesRegex(ValueError, "C5 source provenance mismatch"):
            module.validate_c5_review_source_provenance(provenance, rule, read_member, read_git)
        provenance["committed_source_sha256"][rule["review_source_path"]] = digest
        with self.assertRaisesRegex(ValueError, "C5 source provenance mismatch"):
            module.validate_c5_review_source_provenance(
                provenance, rule, read_member, {rule["review_source_path"]: b"wrong"}.__getitem__)
        module.validate_c5_review_source_provenance(provenance, rule, read_member, read_git)


if __name__ == "__main__":
    unittest.main()
