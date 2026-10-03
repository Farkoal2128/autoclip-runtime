# IM-DEP-10: Inno publisher CPU route

Date: 2026-10-02. Explicit parent assignment implements the authorized Stage
A-D CPU consumer path in `cpu-native-artifact-v1.md`. Owned files only:
`installer/AutoClip.iss`, `tests/InstallerPublisherCpuWizard.Tests.ps1`,
`tests/InstallerMsys2Wizard.Tests.ps1`,
`tests/InstallerBuildComposition.Tests.ps1`, and this report. Other writers'
files and existing changes were preserved.

## Behavior and handoff

`NativeCpuEnabled` defaults to 0. `UsePublisherCpu` requires both define1 and
the CPU profile. CPU skips MSYS summary/consent/preparation and the source
worker's MSYS-prepared gate, and never probes/acquires/extracts Git. It retains
preflight, Python consent/helper, uv, FFmpeg, protected downloader, cancellation,
existing completion/ownership and finalization checks. CPU native download goes
through `DownloadArtifact` with exact `CpuNativeIdentity`, filename and SHA.

CPU worker JSON contains `CpuNativeArtifactPath`, `CpuNativeHelperSha256`,
`PythonPrerequisiteHelperSha256`, and `VcRuntimeHelperSha256`; MSYS and Git
arguments are absent. Helper verification extracts and pins the standalone CPU,
existing Python and existing VC helper. CPU and VC files are conditional
dontcopy payloads. Root owns the bootstrap/worker VC interface integration.
GPU remains the separate source route; no CPU worker arguments or artifact are
selected. CPU progress uses installation wording; native source progress remains
for the source profile. Qualification of either profile is still enforced by
the parent manifest/builder and actual install gates.

## RED / GREEN

Working directory: `D:/Projects/autoclip-runtime`.

```powershell
powershell.exe -NoProfile -NonInteractive -File tests/InstallerPublisherCpuWizard.Tests.ps1
```

RED: before production changes, compiled actual Pascal `PrepareToInstall`
failed the CPU success case with `CPU developer prerequisite invoked: MSYS2`,
zero native downloads and zero builds. Preserved diagnostic evidence:
`%TEMP%/autoclip-publisher-cpu-wizard-dec468a40c23463291a5dfd432475e45`.

GREEN: pinned ISCC compiles actual Pascal decisions and executes five first-party
diagnostic cases: success, repeat retry, native download failure, cancellation
and missing uv. Developer-tool boundaries throw if invoked; native download
records exact identity/pin, worker fixture requires no Git/MSYS and exact native
file, completion/handoff remain required. The actual CPU worker-argument
function verifies three exact helper pins and emits four exact JSON fields.
CPU skips MSYS consent; GPU preserves it and receives no CPU arguments.
Final diagnostic evidence:
`%TEMP%/autoclip-publisher-cpu-wizard-327d0ed3648e491f9b2a6c0ad62d2fe0`.
No production helper, native payload or vendor installer is executed by these
Pascal fixtures.

```powershell
powershell.exe -NoProfile -NonInteractive -File tests/InstallerMsys2Wizard.Tests.ps1
powershell.exe -NoProfile -NonInteractive -File tests/InstallerBuildComposition.Tests.ps1
git diff --check -- installer/AutoClip.iss tests/InstallerMsys2Wizard.Tests.ps1 tests/InstallerBuildComposition.Tests.ps1 tests/InstallerPublisherCpuWizard.Tests.ps1
```

All PASS. The MSYS fixture was brought into current source-handoff semantics:
explicit NativeCpuEnabled0, actual UsePublisherCpu function, source ownership
file and SourceHandoffSha256 variable. All thirteen original source cases and
assertions remain. BuildComposition now resolves the actual PythonLogDirectory
function referenced by PreparePython; actual declined Python producer, protected
storage, real long/short/absent-target lock equivalence and foreign/reparse
rejections remain exercised.

## Remaining evidence

`powershell.exe -NoProfile -NonInteractive -File tests/InstallerPythonWizard.Tests.ps1`
compiled, then Windows blocked Start-Process for its diagnostic EXE with:
`Operation did not complete successfully because the file contains a virus or
potentially unwanted software.` No retry or security exclusion was attempted;
its runtime checks remain unperformed in this run. Root was notified.

Full final Setup syntax/bytes, clean VM CPU install/media/lifecycle and exact
generated uninstaller tests remain parent integration acceptance. No VM,
vendor acquisition/consent, production Setup execution, commit, publication or
release action occurred in this assignment. These owned files are frozen for
parent integration; this is implementation evidence, not release approval.
