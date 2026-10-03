# IM-MS-13 — source-build MSYS2 startup guard

## Authorization and boundary

Parent explicitly assigned implementation in `install.ps1`, one focused behavioral test and this report. Installer/updater change under the runtime-updater skill and installer migration contract. Parent owns canonical contract/manifest, the package producer and Inno integration. No VM, vendor/MSYS execution, provisioning, publication or contract edits were performed by this worker.

Public optional inputs: `-MsysPackageReceiptPath`, `-MsysPackageReceiptSha256`, `-MsysBaseArchivePath`. Secure mode (`NoPrerequisiteAcquisition` plus `SecureAcquisitionManifestPath`) requires all inputs before prerequisite MSYS queries and again before the unchanged archived native build recipe. Legacy development/recovery keeps its existing route.

## Implementation

The guard rejects elevated tokens; verifies local, recipient-owned paths, protected root/receipt anchors, effective write ACLs and every ancestor for reparse points; holds read/shareRead locks on the manifest, receipt, archive, all selected code files and HOME startup files during each native action. It authenticates manifest/receipt SHA-256 and archive bytes/hash/20260611 identity, exact schema/status/root/private HOME, manifest linkage, base receipt digest syntax and the five manifest package versions.

It independently enumerates `usr/bin/**`, `ucrt64/bin/**`, `etc/profile.d/**`, `etc/post-install/**`, `etc/msystem.d/**`, `etc/profile`, `etc/bash.bashrc`, `etc/msystem`, `msys2_shell.cmd`; rejects extra, missing or duplicate receipt rows; verifies every size/hash and re-enumerates immediately before execution. Private HOME contains exactly `.bash_profile`, `.bashrc`, `.profile`, whose bytes/hash independently match regular, unique `msys64/etc/skel/` TAR members. Existing trusted `install-python.ps1 -CheckOnly` selects validated registered Python 3.11.9; its isolated Python stdlib `tarfile` inspection reads without extraction.

The environment scope saves/clears all contracted startup variables and all exported Bash functions. PATH includes the verified MSYS bins, System32/native PowerShell, selected Git/uv/Python directories, and existing absolute reparse-free Visual Studio/Windows Kits directories under known Program Files roots. It sets private MSYS HOME/UCRT64 and restores the caller environment after success/error. Parent additionally authorized fixed process-only Git `core.longpaths=true` via `GIT_CONFIG_COUNT/KEY_0/VALUE_0`; existing `GIT_CONFIG*` process values are cleared and restored. No global Git configuration or immutable recipe bytes changed.

## RED / GREEN

Exact repeated command, from `D:\Projects\autoclip-runtime`:

```powershell
& "$env:SystemRoot\System32\WindowsPowerShell\v1.0\powershell.exe" -NoProfile -File tests/InstallerMsys2SourceGuard.Tests.ps1
```

Initial RED (exit 1), before production edits: actual installer prerequisite section, replacing only MSYS executable invocation, ran **12** native fixture calls with missing bound inputs: `RED: secure source path invoked 12 MSYS calls without bound startup inputs.`

Additional meaningful REDs during bounded refinement: extra private HOME file accepted; fixed Git process configuration missing; injected Git configuration not restored; string schema `"1"` accepted. Each was followed by a focused GREEN implementation correction.

Final focused GREEN (exit 0): missing inputs block before native calls; qualified actual section runs exactly 12 native fixture queries; actual build entrypoint independently rejects missing binding and runs once with qualified inputs; tampered HOME/UCRT64 DLL, duplicate/extra code, elevated token, wrong package versions, malformed schema, changed manifest binding/archive, extra HOME file reject; real FileShare.Read rejects code/receipt write attempts; injected environment clears and restores on both success and action failure. Only native platform/Python/MSYS boundaries are mocked; actual parsing, ACL/path checks, hashing, independent enumeration, locks and environment logic execute.

Related PS5.1 commands (all exit 0):

```powershell
& "$env:SystemRoot\System32\WindowsPowerShell\v1.0\powershell.exe" -NoProfile -File tests/InstallerSecureAcquisition.Tests.ps1
& "$env:SystemRoot\System32\WindowsPowerShell\v1.0\powershell.exe" -NoProfile -File tests/InstallerNoAcquisition.Tests.ps1
& "$env:SystemRoot\System32\WindowsPowerShell\v1.0\powershell.exe" -NoProfile -File tests/InlineInstaller.Tests.ps1
& "$env:SystemRoot\System32\WindowsPowerShell\v1.0\powershell.exe" -NoProfile -File tests/InstallerFFmpegIntegration.Tests.ps1
& "$env:SystemRoot\System32\WindowsPowerShell\v1.0\powershell.exe" -NoProfile -File tests/InstallerPythonPin.Tests.ps1
```

## Frozen hashes

- `install.ps1`: `8aaf8b6ec6a49ce231bc9d836acc6ee99cf7f5ef02f772b0a63b24b399113de0`.
- `tests/InstallerMsys2SourceGuard.Tests.ps1`: `7b17b953d09a701ed36f0514f2370bdd187200eb5e9a86a781f5785c1bf0cffa`.

Existing concurrent changes in install.ps1 predated this assignment and were preserved; repository-wide diff totals include them.

## Evidence limits and integration

This consumer verifies bound post-install state and directly authenticated TAR/HOME; it does not repeat historical base initialization/signature/package transactions. Base receipt SHA syntax is checked, while setup binds the package receipt hash; no extra base receipt input is required by the agreed contract. Registered Python's capability/signature checks and actual vendor TAR inspection remain native integration responsibilities; tests supply native-boundary fixture output. No real MSYS source build or whole wizard completion is claimed.

Individual FileShare.Read locks prevent modification/replacement of selected existing files. They do not atomically prevent the same recipient from adding a new directory entry during a running build; independent enumeration and protected recipient ACLs qualify the state immediately before native execution. No administrator authority is granted by receipts. Other inherited compiler configuration variables outside the contracted startup scope remain outside this work order.

Inno must pass all three new inputs and a package receipt with the expanded post-install UCRT64 closure; parent owns that integration and canonical contract change.

Primary API documentation: [Python 3.11 tarfile](https://docs.python.org/3.11/library/tarfile.html), [.NET FileShare](https://learn.microsoft.com/en-us/dotnet/api/system.io.fileshare), [Git process configuration environment](https://git-scm.com/docs/git-config). GNU startup documentation fetch failed during this assignment; extra HOME file rejection follows the parent-agreed exact private-HOME contract, not an asserted new documentation finding.