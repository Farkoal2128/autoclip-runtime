# IM-CPU-20 — preserve uv option array at its producer

Status: focused production fix and successor diagnostic driver prepared;
actual successor guest build pending. Parent owns guest execution and review.

## Actual failure and requirement

CPU19 invoked frozen source `019478...` once in the ordinary guest. The parent
provided preserved primary receipt `vm-cpu19-failure-primary-2d5afb801a7d.json`
and full logs `vm-cpu19-failure-logs-47cd1e3ffc9f.json`. Inspection shows actual
child PID 10412 terminal, exit 1, `source_build_performed:false`, stage
`C:\Users\autocliplab\AppData\Local\Temp\cpb-7ec0c2f38a7d`. uv rejected an
unexpected `-` during venv creation, before native compilation. Existing
VCOMP was detected; that does not qualify installation or source compilation.

Expected behavior is unchanged: the guarded source-install initial uv venv
call must pin Python 3.11.9 and pass exactly one intact
`--no-python-downloads` argument. Ordinary mode retains its existing download
behavior; the fallback remains explicitly pinned/no-download. No requirement,
runtime identity, dependency pin, recipe or public interface changes.

## Root cause and minimum change

Search found one producer of `$pythonDownloadOption` and the initial consumer
that splats it. The fallback consumer uses explicit flags. PowerShell 5.1
unwraps a one-element array returned through an `if` pipeline into a scalar
string; scalar splatting then passes characters as native arguments.

The existing test manually assigned an array and bypassed the actual producer.
The revised test evaluates the actual assignment AST before invoking both
actual uv command ASTs with a first-party native `.cmd` argument recorder.
RED exit 1 reproduced:

```text
venv --python 3.11.9 - - n o - p y t h o n - d o w n l o a d s <venv>
```

The only production change owned by this order is:

```powershell
$pythonDownloadOption = @(if ($NoPrerequisiteAcquisition) { '--no-python-downloads' })
```

The outer array subexpression preserves both one-element and empty-array
cases. Existing wizard/cancellation changes in source `6f2809...` were
preserved. No unrelated refactor, caller rewrite or new dependency was added.

## Frozen outputs and successor diagnostic

| Artifact | Bytes where recorded | SHA-256 |
| --- | ---: | --- |
| `install.ps1` | 393759 | `0a82cd0bf441b93a0074e43548f25c0d784fc8cd96c1fc3ba73b8f0cb20cf4d2` |
| `tests/InstallerPythonPin.Tests.ps1` | — | `b98056fe693483fa5fb5f2ced3c3e43d36da46a6988f263d8a274dd41fb61195` |
| `D:/AutoClip-Inno-Migration/vm-transfer/cpu-real-build-probe-r2.ps1` | 18904 | `a81fab4a6bd35229c746d50eab46dc89c7f0ca19c93c42e0c4964c900dcb2634` |
| `D:/AutoClip-Inno-Migration/vm-transfer/cpu-real-build-probe-r2.tests.ps1` | 4278 | `67da167c1f284be1272b2d1e6aa1111c5b167ecc15ed3931b2f1ff8bbee2ca56` |

The r2 driver is an exact text clone of the frozen CPU19 driver except for
the first-party bootstrap metadata basename/pin and matching child invocation
basename. It fetches `install-cpu20-0a82cd0bf441.ps1` and authenticates full
`0a82cd0b...` before invoking that absolute stage-local path. The root alone
will copy the frozen bootstrap to that distinct server filename. The existing
server `install.ps1`/CPU19 source and its original driver, report, failure,
stage and receipts remain unchanged. No automatic retry was initiated.

All IM-CPU-19 context, classification-only clone equality, fresh roots,
ordinary token, actual Python/VCOMP detection, protected official acquisition,
bound MSYS receipt/TAR, durable live PID/logs/observations, no timeout/retry/
kill, isolated child LOCALAPPDATA and full result checks remain identical.
Use final CPU clone `92fcd18...` and the fresh package receipt `429f0aef...`
bound to root `C:\ProgramData\acm-ee01cf00\msys64`, as recorded in IM-CPU-19.
The direct helper path still cannot qualify Inno, application/model/media,
uninstall or release. Uninstall execution remains after production-ready
installer qualification, as requested by the user.

## Exact verification

All commands ran on the host with first-party fixtures only, Windows
PowerShell 5.1. No vendor code/download or VM action was performed here.

```powershell
powershell -NoProfile -File tests/InstallerPythonPin.Tests.ps1
powershell -NoProfile -File tests/InstallerNoAcquisition.Tests.ps1
powershell -NoProfile -File tests/InstallerSecureAcquisition.Tests.ps1
powershell -NoProfile -File D:/AutoClip-Inno-Migration/vm-transfer/cpu-real-build-probe-r2.tests.ps1
git diff --check -- install.ps1 tests/InstallerPythonPin.Tests.ps1
```

Python-pin test: meaningful RED exit 1 before the production edit; GREEN
exit 0 after it. Both actual native argument calls pin 3.11.9; guarded initial
call passes intact no-download option; the actual guarded assignment is an
array of length 1 and ordinary assignment an array of length 0. Ordinary
initial invocation retains the Python pin without that guarded flag.
No-acquisition regression, secure callback regression and r2 driver fixtures
all exited 0. AST parsing found no errors; scoped diff check exited 0.
Actual successor guest build and all broader acceptance gates remain pending.
