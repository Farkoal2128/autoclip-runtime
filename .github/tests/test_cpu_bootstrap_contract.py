"""Guard the clean Windows CPU bootstrap inputs and validation boundaries."""

import unittest
from pathlib import Path


ROOT = Path(__file__).resolve().parents[2]


class CpuBootstrapContractTests(unittest.TestCase):
    def test_installer_provisions_and_validates_native_tools(self) -> None:
        installer = (ROOT / "install-source-build.ps1").read_text(encoding="utf-8")
        for item in (
            "MSYS2.MSYS2",
            "20260611",
            "Git.Git",
            "Microsoft.VisualStudio.2022.BuildTools",
            "Microsoft.VisualStudio.Workload.VCTools",
            "Microsoft.VisualStudio.Component.Windows10SDK.20348",
            "mingw-w64-ucrt-x86_64-nasm",
            "'make', 'diffutils', 'pkgconf'",
            "$git.Source --version",
            "where cl.exe",
            "nasm -v",
            "make --version",
            "pkg-config --version",
        ):
            with self.subTest(item=item):
                self.assertIn(item, installer)
        self.assertEqual(installer.count("-requires Microsoft.VisualStudio.Component.VC.Tools.x86.x64 -property installationPath"), 2)
        self.assertNotIn("-requires Microsoft.VisualStudio.Component.VC.Tools.x86.x64 Microsoft.VisualStudio.Component.Windows10SDK.20348", installer)
        self.assertIn("Join-Path $_.FullName 'um\\Windows.h'", installer)

    def test_cpu_receipt_records_profile_and_build_inputs(self) -> None:
        builder = (ROOT / "build-native-from-source.ps1").read_text(encoding="utf-8")
        self.assertIn("profile = if ($InstallNvidiaGpu) { 'nvidia' } else { 'cpu' }", builder)
        self.assertIn("build_prerequisites", builder)
        self.assertIn("cmake_arguments", builder)


if __name__ == "__main__":
    unittest.main()
