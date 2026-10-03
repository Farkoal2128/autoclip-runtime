# IM-DEP-08: guarded publisher CPU bootstrap

Date: 2026-10-02. Parent assignment authorizes Stage A-D implementation under
`cpu-native-artifact-v1.md`. Ownership: `install.ps1`,
`installer/run-source-build.ps1`, `tests/InstallerPublisherCpu.Tests.ps1`, and
this work order only. Existing unrelated changes were preserved. No vendor,
VM, publication or uninstall action was performed.

## Interface and implementation

New bootstrap/strict worker parameters: `CpuNativeArtifactPath`,
`CpuNativeHelperSha256`, `PythonPrerequisiteHelperSha256`. The protected outer
manifest's `cpu_native_artifact` supplies identity, filename, HTTPS URL,
bytes/SHA-256, CPU profile, direct delivery and qualification receipt path/hash.
Selected CPU requires all three parameters, secure acquisition and
`NoPrerequisiteAcquisition`; partial, blocked and substituted inputs reject.
The archive and helper validation failures never fall back to source compilation.
The release's schema3 `native_build.cpu_artifact` matches the descriptor's six
core fields and `runtime_id`; delivery is `publisher_cpu_with_source_nvidia`.
Descriptor acquisition participates in the existing exact secure pin matching.

CPU skips Git executable verification and the complete existing native
MSYS/Git/VS/SDK prerequisite action. Ordinary runtime prerequisites remain.
The pinned Python helper runs CheckOnly in native x64 PowerShell and yields one
absolute registered python.org interpreter. uv venv receives that exact path,
`--no-managed-python` and `--no-python-downloads`. Both helper files remain open
with FileShare.Read, denying write/delete during path execution.

Native staging calls the standalone helper into `publisher-wheels/cpu-native`
for the two wheels and `publisher-wheels/cpu/native-artifact` for build/source
and notices. Separate staging avoids collision with existing publisher wheels.
Only the two release-selected, hashed/size-bound wheels are atomically published
into the existing CPU wheelhouse. Exact existing bytes are reused; corrupt bytes
reject and unrelated publisher files remain untouched. Original producer receipt
stays unchanged under native-artifact/build. Installed receipt adds the artifact
identity/hash/size, producer path/hash and helper pin. Existing wheel integrity,
offline installation, OpenBLAS, pip check, CPU import, health, completion and
resume checks remain downstream.

Optional NVIDIA retains the original source route when no CPU archive/helper
parameters are supplied, even when the outer manifest also describes CPU.
GPU plus CPU artifact parameters rejects. This retains route semantics and
does not qualify the outstanding NVIDIA/compiler/vendor graph.

## RED and verification

Working directory: `D:/Projects/autoclip-runtime`.

```powershell
powershell.exe -NoProfile -NonInteractive -File tests/InstallerPublisherCpu.Tests.ps1
```

RED before production: missing `Initialize-AutoClipPublisherCpu`, exit1.
GREEN: actual descriptor selection/rejection, optional GPU route, release
substitution rejection, actual entire prerequisite action skipped with
throw-on-probe substitutes, strict worker arguments, actual standalone helper
composed with bootstrap using authentic synthetic ZIP/RECORD fixtures, existing
publisher wheel retention, repeat staging, corrupt-cache rejection, pinned
CheckOnly execution and exact uv interpreter/download flags. Native fixture
payloads are inert; no native behavior is claimed by this test.

These regression commands passed:

```powershell
powershell.exe -NoProfile -NonInteractive -File tests/InstallerSecureAcquisition.Tests.ps1
powershell.exe -NoProfile -NonInteractive -File tests/InstallerNoAcquisition.Tests.ps1
powershell.exe -NoProfile -NonInteractive -File tests/InstallerMsys2SourceGuard.Tests.ps1
powershell.exe -NoProfile -NonInteractive -File tests/InstallerBuildInput.Tests.ps1
powershell.exe -NoProfile -NonInteractive -File tests/InstallerCompletion.Tests.ps1
powershell.exe -NoProfile -NonInteractive -File tests/InstallerCompletedSourceReuse.Tests.ps1
git diff --check -- install.ps1 installer/run-source-build.ps1 tests/InstallerPublisherCpu.Tests.ps1
```

NoAcquisition and Completion initially failed because their AST/substring
selection encountered the new containing blocks. Production was reshaped to
retain their tested boundaries; no existing assertions were altered. They then
passed. BuildComposition was also executed and failed at
`Actual PreparePython LogDirectory argument could not be resolved.` Its
Inno-specific assertion and Inno source were outside this assignment and left
unchanged; root was notified. Clean consumer Inno installation and actual CPU
operations remain parent integration acceptance, followed by exact generated
uninstaller tests and review/release. Current implementation is frozen for
parent integration; candidate distribution qualification is not claimed.
