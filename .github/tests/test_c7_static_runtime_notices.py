"""External static toolchain notices must be mapped to the exact binary."""

import hashlib
import importlib.util
import unittest
from pathlib import Path


SCRIPT = Path(__file__).resolve().parents[2] / "scripts" / "build-source-routed-release.py"
spec = importlib.util.spec_from_file_location("source_routed_release", SCRIPT)
module = importlib.util.module_from_spec(spec)
spec.loader.exec_module(module)

OPENBLAS = "8b04387766efc05c627e26d24797ec0d4ed4c105ec14fa7400aa84a02db22b66"
DLL = "e824cf9fc22e5949807ce995a32e413a345fb97e63e6d10cfbf41aa86382193c"


class StaticRuntimeNoticeTest(unittest.TestCase):
    def test_exact_external_dll_rejects_missing_or_incorrect_component_notices(self):
        runtime = b"runtime grant\n"
        threads = b"winpthreads grant\n"
        files = {
            "notices-and-source/component-evidence/mingw-runtime.txt": runtime,
            "notices-and-source/component-evidence/winpthreads.txt": threads,
        }
        required = {
            "artifact_sha256": OPENBLAS,
            "member_path": "bin/libopenblas.dll",
            "member_sha256": DLL,
            "notices": [
                {"component": component, "path": path, "sha256": hashlib.sha256(files[path]).hexdigest()}
                for component, path in (
                    ("mingw-w64-runtime", "notices-and-source/component-evidence/mingw-runtime.txt"),
                    ("winpthreads", "notices-and-source/component-evidence/winpthreads.txt"),
                )
            ],
        }
        asset = {
            "filename": "OpenBLAS-0.3.30-x64.zip",
            "sha256": OPENBLAS,
            "member_path": "bin/libopenblas.dll",
            "member_sha256": DLL,
            "components": [{"name": "openblas", "license_paths": [{"path": "openblas-license"}]}],
        }
        with self.assertRaisesRegex(ValueError, "Missing static runtime notice route"):
            module.validate_static_runtime_notice_routes([asset], [required], files.__getitem__)
        asset["components"] = [
            {
                "name": row["component"],
                "binary_path": required["member_path"],
                "binary_sha256": DLL,
                "license_paths": [{"path": row["path"], "sha256": row["sha256"]}],
            }
            for row in required["notices"]
        ]
        module.validate_static_runtime_notice_routes([asset], [required], files.__getitem__)
        asset["components"][1]["binary_sha256"] = "0" * 64
        with self.assertRaisesRegex(ValueError, "Static runtime notice binary mismatch"):
            module.validate_static_runtime_notice_routes([asset], [required], files.__getitem__)
        asset["components"][1]["binary_sha256"] = DLL
        files[required["notices"][1]["path"]] = b"modified"
        with self.assertRaisesRegex(ValueError, "Static runtime notice hash mismatch"):
            module.validate_static_runtime_notice_routes([asset], [required], files.__getitem__)


if __name__ == "__main__":
    unittest.main()
