# IM-PY-01: exact Python installer helper

Authorization: parent work order explicitly authorizes implementation of CPU
prerequisite provisioning under the Inno migration. Ownership is limited to
`installer/install-python.ps1`, `tests/InstallerPythonInstall.Tests.ps1`, and
this report. Other writers own the manifest, Inno shell, source builder and
VM qualification. No Python installation, commit or publication was performed.

Requirement: installer contract-v1 inputs/dependency policy and installation
steps 2–4 require explicit recipient vendor terms, approved pinned inputs,
verification immediately before execution, fixed arguments, vendor exit
interpretation and an independent installed capability check. Runtime architecture
requires preserving shared installations and avoiding global PATH changes.
This is an installer/updater change; no app/runtime identity was changed.

## Helper contract

Run Windows x64 PowerShell 5.1 as the recipient, using an absolute local
`-InstallerPath`, `-ManifestPath`, `-LogDirectory`, and the explicit
`-AcceptPythonTerms` declaration after presenting the terms. The helper consumes
schema 1 `build_prerequisites` with exactly one Python row: version `3.11.9`,
architecture `x64`, official exact URL, nonempty size/SHA-256 and
`DIRECT_RECIPIENT_DOWNLOAD`. A `BLOCKED` production row fails closed.

Success stdout is only the selected absolute Python executable. The vendor
owns Python and its registration; AutoClip never uninstalls or deletes it.
Valid registered 3.11 installations are reused after native checks; existing
incompatible registered installations or occupied target directories require
manual resolution. Fresh installation selects
`%LOCALAPPDATA%\Programs\Python\Python311`. Ancestor reparse points, UNC paths,
quoted paths and adjacent `unattend.xml` are rejected.

Fixed arguments: `/passive /norestart /log "<unique-log>" InstallAllUsers=0
TargetDir="<fixed-per-user-target>" PrependPath=0 AppendPath=0 Include_exe=1
Include_lib=1 Include_dev=1 Include_pip=1 Include_launcher=0
InstallLauncherAllUsers=0 AssociateFiles=0 Shortcuts=0 Include_doc=0 Include_test=0
Include_tcltk=0 Include_tools=0 Include_debug=0 Include_symbols=0 CompileAll=0`.
No manifest-supplied command line, download, PATH mutation or production mock
switch exists. Immediately before Start-Process, the helper checks file
size/hash and valid Authenticode with exact PSF certificate CN.

| Exit | Meaning |
| --- | --- |
| 0 | Exact identity and capability verified, installed or reused |
| 20 | Recipient terms declaration missing/declined |
| 21 | Unsupported platform/schema/pin/route |
| 22 | Payload size/hash/path or adjacent unattend override rejected |
| 23 | Invalid signature or wrong PSF signer |
| 24 | Existing incompatible Python or target collision |
| 25 | Vendor execution failure; raw vendor code in receipt |
| 26 | Native installed identity/capability check failed |
| 1602 | Vendor cancellation (also normalizes HRESULT cancellation) |
| 3010 | Pending reboot, no post-check or successful Python selection |

Unique JSON receipts record timestamp, terms declaration/source/hash, consumed
manifest hash, installer hash, arguments, raw vendor exit, status, selected
Python and vendor log path. Vendor log files exist only after the vendor runs.
An invalid/unwritable log directory prevents receipt creation and fails at the
PowerShell boundary. Parent orchestration must serialize all vendor installers,
protect staging/manifest bytes, retain logs and pending state, and only resume
a 3010 result after reboot. This helper does not activate AutoClip or claim
ownership of any shared prerequisite.

The native `-I` Python check requires exact `(3,11,9)`, Windows, pointer size 8,
matching executable/base prefix, `Python.h`, `pyconfig.h`, `python311.lib`,
and imports for ctypes, ssl, sqlite3, bz2, lzma, venv, ensurepip and sysconfig.
SSL identity, SQLite query, and compression round trips must work. A vendor
exit of 0 alone does not pass the prerequisite.

## Primary evidence and manifest recommendations

- [Exact release](https://www.python.org/downloads/release/python-3119/)
  and [3.11 Windows options](https://docs.python.org/3.11/using/windows.html)
  document offline installer components, per-user installation and feature flags.
- [Exact CPython 3.11.9 bootstrapper](https://raw.githubusercontent.com/python/cpython/v3.11.9/Tools/msi/bundle/bootstrap/PythonBootstrapperApplication.cpp)
  returns Win32 cancellation/reboot codes and reads adjacent `unattend.xml`.
- [WiX 3 Burn option parser](https://raw.githubusercontent.com/wixtoolset/wix3/wix314rtm/src/burn/engine/core.cpp)
  defines `/passive`, `/log` and `/norestart`.
- [Versioned Python terms](https://raw.githubusercontent.com/python/cpython/v3.11.9/LICENSE):
  SHA-256 `3b2f81fe21d181c499c59a256c8e1968455d6689d269aa85373bfb6af41da3bf`
  from downloaded raw upstream bytes. Includes PSF and historical license terms.
  This hash identifies that reference text; equivalence to installer UI and
  complete nested-component terms remains a qualification/reviewer question.

Recommend adding to the Python row: `signature_publisher: Python Software
Foundation`, `elevation: none (vendor runtime prerequisites may require UAC)`,
fixed `installer_arguments` above (with parent-resolved log/target placeholders),
`success_exit_codes: [0]`, `cancel_exit_codes: [1602]`,
`reboot_exit_codes: [3010]`, `reboot_behavior: pending; post-reboot capability
verification required`, `terms_url` and `terms_sha256` above, and the native
`post_install_check` specified here. Keep classification `BLOCKED` until exact
recipient acquisition, consent, clean-machine install and technical review
qualification are recorded. No manifest was edited by this work order.

Local artifact inspected, never executed:
`D:\AutoClip-Inno-Migration\python-3.11.9-amd64.exe`, 26216840 bytes,
SHA-256 `5ee42c4eee1e6b4464bb23722f90b45303f79442df63083f05322f1785f5fdde`.
Authenticode Valid; certificate subject
`CN=Python Software Foundation, O=Python Software Foundation, L=Beaverton,
S=Oregon, C=US`.

## TDD and verification

RED command: `powershell -NoProfile -ExecutionPolicy Bypass -File
tests/InstallerPythonInstall.Tests.ps1`. Before helper creation it failed with
`RED: Python prerequisite helper is missing.` A minimal success-only stub then
failed the behavioral assertion `Expected 20, got 0: Not implemented`.
This demonstrates pre-implementation consent RED. After implementation, temporary
source mutations separately demonstrated assertion RED for every required
boundary. These are regression-sensitivity checks, not pre-implementation
failures: consent `20 -> 0`, pin `22 -> 0`, signer `23 -> 0`, vendor failure
`25 -> 0`, reboot `3010 -> 25`, post-check failure `26 -> 0`, and successful
post-check `0 -> 26`. All mutant files were outside the repository and removed.
The exact executed mutation command, formatted across lines for readability:

```powershell
$source=Get-Content installer/install-python.ps1 -Raw
$mutations=@(
 @('consent','if (-not $AcceptPythonTerms)','if ($false)'),
 @('pin','$receipt.installer_sha256 -ne $pin.sha256','$false'),
 @('signer','CN=Python Software Foundation(,|$)','CN=Other Python Software Foundation(,|$)'),
 @('exit_failure','if ($process.ExitCode -ne 0)','if ($false)'),
 @('pending_reboot','if ($process.ExitCode -eq 3010)','if ($false)'),
 @('postcheck_failure','if (-not (Test-AutoClipPython $python))','if ($false)'),
 @('postcheck_success',"`$receipt.status = 'installed'; `$code = 0","`$receipt.status = 'installed'; `$code = 26")
)
$fixture=Join-Path $env:TEMP ('autoclip-python-mutant-'+[guid]::NewGuid().ToString('N')+'.ps1')
try {
 foreach($mutation in $mutations){
  $candidate=$source.Replace($mutation[1],$mutation[2])
  if($candidate -eq $source){ throw ('Mutation did not apply: '+$mutation[0]) }
  [IO.File]::WriteAllText($fixture,$candidate)
  $output=& powershell -NoProfile -ExecutionPolicy Bypass -File tests/InstallerPythonInstall.Tests.ps1 -HelperPath $fixture 2>&1
  if($LASTEXITCODE -eq 0){ throw ('Mutation escaped: '+$mutation[0]) }
  $assertion=@($output | Where-Object { $_.ToString() -match '^Expected [0-9]+, got' } | Select-Object -First 1)
  if(-not $assertion){ throw ('No behavioral assertion: '+$mutation[0]+': '+($output -join ' ')) }
  Write-Output ($mutation[0]+': RED '+$assertion[0])
 }
} finally { if(Test-Path -LiteralPath $fixture){ Remove-Item -LiteralPath $fixture } }
```

Executed from `D:\Projects\autoclip-runtime`:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File tests/InstallerPythonInstall.Tests.ps1
powershell -NoProfile -ExecutionPolicy Bypass -File tests/InstallerPythonInstall.Tests.ps1 -ExistingPythonPath C:\Users\beilo\AppData\Local\Programs\Python\Python311\python.exe
powershell -NoProfile -ExecutionPolicy Bypass -File tests/InstallerPythonPin.Tests.ps1
python -m unittest discover -s .github/tests -p test_installer_manifest.py
git diff --check -- installer/install-python.ps1 tests/InstallerPythonInstall.Tests.ps1
```

All passed under Windows PowerShell `5.1.26100.9444`; manifest suite ran 9 tests.
AST-loaded functions and function mocks cover consent decline, blocked route,
wrong size/hash/signer, invalid signature, adjacent override, vendor failure,
cancellation, pending reboot without premature capability checks, failed/successful
post-check and shared install reuse/collision. The optional existing-host test
ran the real native capability probe against already installed Python 3.11.9
x64 and rejected a missing interpreter. Mocks cannot establish actual installer
behavior. Full repository checks, clean-VM installation, reboot, lifecycle,
ordinary-user AutoClip workflow and exact setup review are parent-owned and
were not performed here. NVIDIA hardware testing remains deferred.

Changed files are exactly the two owned PowerShell files and this report.
