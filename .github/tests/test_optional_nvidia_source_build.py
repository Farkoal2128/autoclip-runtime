"""Contract checks for the two recipient source-build install modes."""

import re
import unittest
from pathlib import Path


ROOT = Path(__file__).resolve().parents[2]


class OptionalNvidiaSourceBuildTests(unittest.TestCase):
    def test_cpu_default_and_explicit_nvidia_mode(self) -> None:
        installer = (ROOT / "install-source-build.ps1").read_text(encoding="utf-8")
        builder = (ROOT / "build-native-from-source.ps1").read_text(encoding="utf-8")
        updater = (ROOT / "update.ps1").read_text(encoding="utf-8")

        self.assertRegex(installer, r"\[switch\]\$InstallNvidiaGpu")
        self.assertRegex(updater, r"\[switch\]\$InstallNvidiaGpu")
        self.assertIn("$arguments.InstallNvidiaGpu = $true", updater)
        self.assertRegex(installer, r"if \(\$InstallNvidiaGpu\) \{\s*if \(-not \$CudaRoot")
        self.assertRegex(installer, r"if \(\$InstallNvidiaGpu\) \{\s*\$nvidiaSmi")
        self.assertIn("if ($InstallNvidiaGpu) { 'autoclip[gpu]==0.1.0.dev0' } else { 'autoclip==0.1.0.dev0' }", installer)
        self.assertRegex(builder, r"\[switch\]\$InstallNvidiaGpu")
        self.assertRegex(builder, r"if \(\$InstallNvidiaGpu\) \{\s*if \(-not \$CudaRoot")
        self.assertIn("'-DWITH_CUDA=OFF'", builder)
        self.assertIn("'-DWITH_CUDA=ON'", builder)
        self.assertIn("install_nvidia_gpu", builder)
        self.assertFalse(re.search(r"\[Parameter\(Mandatory\)\]\[string\]\$CudaRoot", builder))


if __name__ == "__main__":
    unittest.main()
