# IM-PY-02: read-only Python preflight

Authorization: parent work order permits changes only to
`installer/install-python.ps1`, `installer/preflight.ps1`,
`tests/InstallerPythonInstall.Tests.ps1`, `tests/InstallerPreflight.Tests.ps1`
and this report. Parent owns manifest, Inno packaging, build receipt and guest
qualification. No Python installation, agreement acceptance, commit or
publication was performed.

## Requirement and contract

The installer contract-v1 preflight must reuse a verified exact Python 3.11.9
x64 installation registered outside PATH. A WindowsApps execution alias must
never be executed as a capability probe. Checking capabilities must not
download, install, write logs/receipts, request consent or change files.

The helper adds a separate `-CheckOnly` parameter set. On Windows x64 it uses
the same registered/standard-location discovery and native capability check
as installation. Success prints only the selected absolute executable path
and exits 0. Missing or incompatible candidates produce no stdout and exit 2.
The installation parameter set retains mandatory InstallerPath, ManifestPath
and LogDirectory, plus explicit AcceptPythonTerms. CheckOnly does not accept
those installation parameters.

The reused probe verifies a valid PSF Authenticode publisher before execution,
exact interpreter version/architecture, required standard library capabilities,
headers and import library. Its `-I -B` options isolate imports and prevent
bytecode cache writes. Python aliases on PATH are not discovery candidates.

Preflight invokes the absolute native Windows PowerShell executable with the
sibling `install-python.ps1 -CheckOnly`. It does not invoke `python --version`.
Parent integration must extract that sibling beside preflight. The Python
version must be exactly 3.11.9. No other prerequisite detection was changed.

## RED and GREEN

Before production changes, the new helper test failed because CheckOnly was
unknown: expected exit 0 for registered Python, got exit 1. The preflight test
failed with `Registered valid Python outside PATH must satisfy preflight
through CheckOnly.` The fixtures control registry, signature and native process
boundaries while executing the actual helper entry point in a child PowerShell.

A second RED strengthened the read-only behavior: requiring `-B` caused the
registered fixture to fail with expected exit 0, got 2. Adding `-B` to the
native probe made it GREEN. The tests assert registered selection outside PATH,
missing and unsigned-alias exit 2, no alias execution, unchanged scratch file
paths/hashes, and preserved parameter sets. Existing installer consent, pin,
signature, cancellation, failure, pending reboot, post-check and reuse cases
still pass. Preflight's existing CPU/GPU separation and read-only tests pass.

Executed commands from `D:\Projects\autoclip-runtime`:

```powershell
powershell -NoProfile -NonInteractive -ExecutionPolicy Bypass -File tests/InstallerPythonInstall.Tests.ps1 -ExistingPythonPath C:\Users\beilo\AppData\Local\Programs\Python\Python311\python.exe
powershell -NoProfile -NonInteractive -ExecutionPolicy Bypass -File tests/InstallerPreflight.Tests.ps1
powershell -NoProfile -NonInteractive -ExecutionPolicy Bypass -File installer/install-python.ps1 -CheckOnly
powershell -NoProfile -NonInteractive -ExecutionPolicy Bypass -File installer/preflight.ps1 -ManifestPath D:\Projects\autoclip-runtime\release\manifests\installer-dependencies-v1.json -CheckIdentity Python -RequireReady
git diff --check -- installer/install-python.ps1 installer/preflight.ps1 tests/InstallerPythonInstall.Tests.ps1 tests/InstallerPreflight.Tests.ps1 docs/installer-migration/work-orders/IM-PY-02.md
```

All commands passed. The real host CheckOnly selected the already installed
`C:\Users\beilo\AppData\Local\Programs\Python\Python311\python.exe` with exit 0.
The real Python-only preflight returned ready true, blocked false and no missing
items. The real native probe also passed exact identity, stdlib and headers.
No host or VM installation was run. Clean-guest packaging and broader release
qualification remain parent-owned; this helper evidence does not promote a
blocked production delivery classification.
