# IM-DEP-11: protected VC runtime and recovery integration

Date: 2026-10-02. Root integration for the authorized publisher CPU route.
The CPU consumer still needs the Microsoft runtime; removing recipient build
tools does not remove this dependency. Existing protected VC helper bytes and
terms/capability/reboot policy are retained.

## Behavior and RED / GREEN

`install.ps1` and the strict `installer/run-source-build.ps1` worker now accept
the exact `VcRuntimeHelperSha256` passed by the CPU Inno worker. Before fetching
external assets, CPU runs the pinned VC helper in CheckOnly mode. A ready
four-DLL capability result avoids the vendor download. Missing capability
uses the exact acquired vendor path and explicit Microsoft consent. Native
helper execution must emit one schema1 record agreeing with the child exit
code. Reboot, busy, contradictory and failed results stop installation.

The new `tests/InstallerPublisherVc.Tests.ps1` first failed because the actual
bootstrap had no protected VC handoff. Its first integration attempt exposed
PowerShell native `-File` argument semantics: Boolean hashtable values are
strings rather than switch parameters. The minimum correction passes bare
CLI switches. A fixture variable was also renamed to prevent PowerShell
dynamic scope from selecting the production helper. Final GREEN executes only
the inert first-party helper for ready, missing, reboot, busy, contradictory
and install-declaration cases, and rejects a missing helper pin. No vendor
process was installed or accepted by these checks.

The existing matching-incomplete-root recovery had lost the separately
reviewed r18 `--force` addition in the current bootstrap. New
`tests/InstallerResumeVenv.Tests.ps1` demonstrated RED on the actual branch,
then GREEN after restoring `@('--clear', '--force')`. The destructive options
are limited to an existing environment in a previously validated incomplete
root. Absent environments and completed/unproven roots receive neither option.
Existing completed-source tests still reject overwrite/substitution and retain
the same files. Historical r18 source bytes and reviews remain unchanged.

`InstallerPythonPin.Tests.ps1` now distinguishes the two original literal
python.org3.11.9 source calls from the additive CPU call. Both original pin and
no-download assertions remain; the CPU call additionally must use the verified
absolute interpreter with managed Python and automatic downloads disabled.

## Root verification

Working directory `D:/Projects/autoclip-runtime`:

```powershell
powershell.exe -NoProfile -NonInteractive -File tests/InstallerPublisherVc.Tests.ps1
powershell.exe -NoProfile -NonInteractive -File tests/InstallerResumeVenv.Tests.ps1
powershell.exe -NoProfile -NonInteractive -File tests/InstallerPythonPin.Tests.ps1
powershell.exe -NoProfile -NonInteractive -File tests/InstallerPublisherCpu.Tests.ps1
powershell.exe -NoProfile -NonInteractive -File tests/InstallerVcRuntime.Tests.ps1
powershell.exe -NoProfile -NonInteractive -File tests/InstallerVcReboot.Tests.ps1
powershell.exe -NoProfile -NonInteractive -File tests/InstallerNoAcquisition.Tests.ps1
powershell.exe -NoProfile -NonInteractive -File tests/InstallerSecureAcquisition.Tests.ps1
powershell.exe -NoProfile -NonInteractive -File tests/InstallerPublisherCpuWizard.Tests.ps1
powershell.exe -NoProfile -NonInteractive -File tests/InstallerBuildComposition.Tests.ps1
powershell.exe -NoProfile -NonInteractive -File tests/InstallerCompletedSourceReuse.Tests.ps1
python -m unittest discover -s .github/tests -p test_installer_manifest.py
python -m unittest discover -s .github/tests -p test_inno_build.py
```

All PASS; manifest22 and builder14 tests. CPU wizard checks execute compiled
Pascal fixtures; protected prerequisite tests use inert process boundaries.
The existing PythonWizard diagnostic compiled but Windows security blocked
execution in IM-DEP-10; no security override or retry was attempted.

## Actual component smoke and review

Root independently rehashed the r2 review/report/inspection outputs, matching
their published local identities. The exact component disposition is
`QUALIFIED_COMPONENT_DISTRIBUTION`; it is separate from Setup release review.

New external host diagnostic
`D:/acpu-1002-3343baed/control/prove-cpu-native-import.py` creates an unmanaged
python.org3.11.9 environment, installs both exact r2 native wheels and two
hash/size-verified existing publisher dependencies offline, and places only
the exact pinned external OpenBLAS DLL. Actual PyAV/CT2 imports pass; CPU
supports int8/int8_float32/float32 and PyAV decodes16,000 audio samples.
Primary receipt: `D:/acpu-1002-3343baed/host-native-smoke/receipt.json`.
This host evidence is not model inference, clean Windows/Inno installation,
installed-notice qualification, lifecycle acceptance or NVIDIA evidence.

Full candidate production, clean VM installation/media, exact generated
uninstaller and final review remain separate acceptance work. Canonical public
v40 pins were not promoted and no publication occurred.
