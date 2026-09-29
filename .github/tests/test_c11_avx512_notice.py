"""Selected CTranslate2 AVX512 code must have an exact recipient notice route."""

import hashlib
import importlib.util
import io
import unittest
import zipfile
from pathlib import Path


SCRIPT = Path(__file__).resolve().parents[2] / "scripts" / "build-source-routed-release.py"
spec = importlib.util.spec_from_file_location("source_routed_release", SCRIPT)
module = importlib.util.module_from_spec(spec)
spec.loader.exec_module(module)


class Avx512NoticeTest(unittest.TestCase):
    def test_selected_source_and_notice_are_bound(self):
        header = b"/* SIMD_Utils v0.2.5 BSD-2 */"
        notice = b"BSD 2-Clause License\nCopyright (c) 2019, JishinMaster\n"
        stream = io.BytesIO()
        with zipfile.ZipFile(stream, 'w') as archive:
            archive.writestr('third_party/avx512_mathfun.h', header)
        source = stream.getvalue()
        rule = {
            "component": "simd-utils-avx512-mathfun",
            "version_scope": "SIMD_Utils 0.2.5",
            "source_archive_path": "notices-and-source/source-and-build/ctranslate2-v4.8.2-source.zip",
            "source_archive_sha256": hashlib.sha256(source).hexdigest(),
            "header_path": "third_party/avx512_mathfun.h",
            "header_sha256": hashlib.sha256(header).hexdigest(),
            "notice_path": "notices-and-source/candidate-native-notices/simd-utils-avx512-mathfun-BSD-2.txt",
            "notice_sha256": hashlib.sha256(notice).hexdigest(),
            "upstream_license_url": "https://example.test/LICENSE",
        }
        files = {rule["source_archive_path"]: source, rule["notice_path"]: notice}
        mapping = {"component": rule["component"], "version_scope": rule["version_scope"],
                   "source_archive_path": rule["source_archive_path"],
                   "source_archive_sha256": rule["source_archive_sha256"],
                   "header_path": rule["header_path"], "header_sha256": rule["header_sha256"],
                   "license_expression": "BSD-2-Clause",
                   "selected_build_scope": ["CPU/default", "optional NVIDIA"],
                   "source_evidence": {"url": rule["upstream_license_url"],
                                       "sha256": rule["notice_sha256"]},
                   "fulfillment_status": "exact_notice_delivered_focused_independent_review_pending",
                   "license_paths": [{"path": rule["notice_path"], "sha256": rule["notice_sha256"]}]}
        module.validate_avx512_notice_route(mapping, rule, files.__getitem__)
        for bad in ({}, {**mapping, "header_sha256": "0" * 64},
                    {**mapping, "source_archive_sha256": "0" * 64},
                    {**mapping, "selected_build_scope": ["CPU/default"]},
                    {**mapping, "license_paths": []}):
            with self.assertRaises(ValueError):
                module.validate_avx512_notice_route(bad, rule, files.__getitem__)
        with self.assertRaises(ValueError):
            module.validate_avx512_notice_route(mapping, rule,
                {**files, rule["notice_path"]: b"wrong"}.__getitem__)
        with self.assertRaises(ValueError):
            module.validate_avx512_notice_route(mapping, rule,
                {**files, rule["source_archive_path"]: b"wrong"}.__getitem__)


if __name__ == "__main__":
    unittest.main()
