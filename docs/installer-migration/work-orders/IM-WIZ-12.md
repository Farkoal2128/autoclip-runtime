# IM-WIZ-12 — stop bootstrap work after cooperative cancellation

Status: focused host behavioral checks passed; frozen for integration.
Parent authorized cancellation assertions in `install.ps1`, the relevant
actual-source behavioral fixture, and this report. Root owns contract/UI work.
No source recipe, server copy, diagnostic driver, VM, vendor executable,
network acquisition, compiled setup or uninstaller was changed/executed.

## Requirement and minimum change

The immutable v40 recipe is a synchronous invocation that itself runs several
native commands. Its internal commands cannot observe the bootstrap's signal.
Cancellation therefore waits for that entire invocation to return. Once it
returns, the bootstrap must stop before its next controlled native command or
receipt/marker/launcher work. This clarifies actual cancellation latency rather
than promising a check inside an unchanged immutable recipe.

Before this change the bootstrap checked before recipe entry and before the
completion marker, but not between recipe return and subsequent commands.
Only `Assert-AutoClipBuildCancellation` calls were added: after recipe return,
before native receipt copy, wheel verifier, offline uv install, OpenBLAS
extraction, pip check, CPU import, NVIDIA lookup and each GPU command, installed
native receipt enumeration and final receipt write. Existing completion checks
and helper behavior remain intact. No cancellation path means each new check
returns immediately; no process is killed or restarted.

Starting source pin observed:
`0a82cd0bf441b93a0074e43548f25c0d784fc8cd96c1fc3ba73b8f0cb20cf4d2`.
The live CPU20 VM's separately frozen source copy was not touched.

## RED / GREEN

Before production edits, extended the existing test to execute the actual
AST-selected post-recipe control slice. Only native/filesystem action boundaries
were first-party fixture functions. The real cancellation checker and actual
control flow remained production code. The synthetic recipe creates a real
signal during its invocation. Exact command:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File tests/InstallerBuildProcess.Tests.ps1
```

RED: exit 1, `RED: cancellation after recipe allowed subsequent bootstrap side
effects: 6`. The unmodified source copied its receipt, verified wheels, installed
packages, extracted OpenBLAS, checked packages and ran its CPU import boundary
despite the signal.

GREEN after minimum assertions: exit 0. The final fixture covers **18** actual
control-flow scenarios: cancellation after recipe and each subsequent mocked
CPU/NVIDIA command, plus two uncancelled controls with `CancelPath` absent.
Signals prevent every later action; controls still reach all expected commands.
These NVIDIA cases execute only first-party functions and do not claim hardware
or native NVIDIA verification. Existing chatty-worker, pin/ACL/path, exit7,
terminal cancellation1223 and completion-marker race tests also pass.

Adjacent exact commands, each exit 0:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File tests/InstallerMsys2SourceGuard.Tests.ps1
powershell -NoProfile -ExecutionPolicy Bypass -File tests/InstallerNoAcquisition.Tests.ps1
powershell -NoProfile -ExecutionPolicy Bypass -File tests/InstallerSecureAcquisition.Tests.ps1
powershell -NoProfile -ExecutionPolicy Bypass -File tests/InstallLaunchers.Tests.ps1
git diff --check
```

Diff check emitted existing CRLF warnings only. Existing assertions were kept.

## Frozen files

| File | SHA256 |
| --- | --- |
| `install.ps1` | `c78b1a751de590bd845ad8e0c7d3319a4e3abedffb084647595aa9bdaddd739e` |
| `tests/InstallerBuildProcess.Tests.ps1` | `cf5f750ebe6a50d5506c8a8c97dc3cdfe5c37d5ff968eb42cedb32b210c7fc4f` |

## Limits and late commit decision

Cancellation is checked before each listed bootstrap boundary; it is not an
atomic protocol across signal creation and filesystem writes. Existing checks
cover a signal before the marker and immediately after it, removing only the
exact new unchanged marker before launcher work. A signal arriving just after
the final check can overlap `Install-AutoClipLaunchers`. Inno's cancelled flag
must reject final success, but these checks do not prove that every such late
signal leaves no launcher. Root must define the late commit/cancellation policy
or qualify a stronger coordinated boundary before making that broad claim.
This assignment did not invent or alter activation policy.

Actual source build, exact compiled wizard responsiveness/cancellation,
installed health/media workflow and lifecycle verification remain separate
gates. Uninstaller execution still waits until the installer works and is
production ready, then occurs before release.
