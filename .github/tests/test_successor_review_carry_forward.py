"""Successors retain exact committed C5/C7 review associations."""

import hashlib
import importlib.util
import json
import unittest
from pathlib import Path


SCRIPT = Path(__file__).resolve().parents[2] / "scripts" / "build-review-successor.py"
spec = importlib.util.spec_from_file_location("review_successor", SCRIPT)
module = importlib.util.module_from_spec(spec)
spec.loader.exec_module(module)


class ReviewCarryForwardTest(unittest.TestCase):
    def test_preserves_every_prior_source_association(self):
        raw = b"prior exact source\n"
        digest = hashlib.sha256(raw).hexdigest()
        prior = {"review-component-evidence/prior.md": digest,
                 "scripts/build-review-successor.py": "0" * 64}
        current = {"scripts/build-review-successor.py": "1" * 64}
        module.preserve_prior_source_associations(
            prior, {"review-component-evidence/prior.md": raw}.__getitem__, current)
        self.assertEqual(current["review-component-evidence/prior.md"], digest)
        self.assertEqual(current["scripts/build-review-successor.py"], "1" * 64)
        with self.assertRaisesRegex(ValueError, "Prior source association differs"):
            module.preserve_prior_source_associations(
                prior, {"review-component-evidence/prior.md": b"wrong"}.__getitem__, {})

    def test_retains_both_review_rules_and_committed_evidence(self):
        files = {}
        source = {}
        for label in ("c5", "c7"):
            review_path = f"review-component-evidence/{label}.md"
            archive_path = f"notices-and-source/component-evidence/{label}.md"
            raw = f"exact {label} review\n".encode()
            rule = {"review_source_path": review_path, "review_path": archive_path,
                    "review_sha256": hashlib.sha256(raw).hexdigest()}
            rule_path = f"review-{label}-current-state.json"
            files[rule_path] = json.dumps(rule).encode()
            files[review_path] = raw
            source["notices-and-source/build-provenance/current/" + rule_path] = files[rule_path]
            source[archive_path] = raw

        hashes = {}
        module.carry_forward_review_provenance(source.__getitem__, files.__getitem__, hashes)
        self.assertEqual(set(hashes), set(files))
        self.assertEqual(hashes, {name: hashlib.sha256(raw).hexdigest()
                                  for name, raw in files.items()})

        source["notices-and-source/component-evidence/c7.md"] = b"wrong"
        with self.assertRaisesRegex(ValueError, "C7 review evidence differs"):
            module.carry_forward_review_provenance(source.__getitem__, files.__getitem__, {})

    def test_retains_avx512_rule_and_notice_source(self):
        notice = b"exact SIMD notice\n"
        rule = {"notice_source_path": "review-component-evidence/simd-LICENSE",
                "notice_path": "notices-and-source/component-evidence/simd-LICENSE",
                "notice_sha256": hashlib.sha256(notice).hexdigest(),
                "notice_bytes": len(notice)}
        raw_rule = json.dumps(rule).encode()
        files = {"review-avx512-notice.json": raw_rule,
                 rule["notice_source_path"]: notice}
        source = {"notices-and-source/build-provenance/current/review-avx512-notice.json": raw_rule,
                  rule["notice_path"]: notice}
        hashes = {}
        module.carry_forward_avx512_provenance(source.__getitem__, files.__getitem__, hashes)
        self.assertEqual(hashes, {name: hashlib.sha256(raw).hexdigest()
                                  for name, raw in files.items()})
        source[rule["notice_path"]] = b"wrong"
        with self.assertRaisesRegex(ValueError, "AVX512 notice differs"):
            module.carry_forward_avx512_provenance(source.__getitem__, files.__getitem__, {})


if __name__ == "__main__":
    unittest.main()
