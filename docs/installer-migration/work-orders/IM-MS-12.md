# IM-MS-12 — private MSYS2 wizard integration

Status: bounded implementation and focused behavioral checks complete; real native orchestration and full setup qualification pending. All canonical MSYS2 inputs remain BLOCKED. No publication, legal acceptance, or installer approval is established.

## Authorization and ownership

Parent assignment IM-MS-12 authorizes only `installer/AutoClip.iss`, `tests/InstallerMsys2Wizard.Tests.ps1`, and this report. The parent owns the builder, manifest, contract, bootstrap and guest. The package agent owns the package helper. Other agents' changes were preserved. No vendor install, base extraction, GPG, bash, pacman, agreement acceptance, reboot or protection change was performed in this work order.

Requirements come from the assigned wizard behavior and `contract-v1.md` sections “Per-user base receipt and execution authority” and “Package receipt and source-build startup”. Runtime updater/architecture rules apply. No contract or immutable v40 recipe bytes were changed.

## Implemented behavior

- An authenticated manifest-derived summary always displays the private MSYS2 prerequisite, official publisher, version, purpose, classification, all thirteen source URLs and known byte sizes, elevation/restart behavior and official component license link. A separate explicit MSYS2 prerequisite decision precedes acquisition, including when an unrelated system MSYS2 exists. Existing Microsoft/NVIDIA checkbox indices, CPU default, optional GPU and Python restart/consent decisions are preserved.
- The protected downloader uses `-Identity MSYS2 -MsysInputs -ManifestSha256` and the exact base filename/hash. Preparation occurs after verified Python and before source-build acquisition/execution.
- A fixed native PowerShell command, kept in the existing Inno source, verifies and holds read-only locks on the setup-bound manifest, base TAR, three fixed MSYS2 helpers, Python helper and preflight helper. There is no user-selectable orchestration script or new orchestration library. It requires the exact DIRECT manifest row. The frozen helpers independently validate the archive/signature/key/package pins and ordinary-user platform authority.
- Python is selected only from native `install-python.ps1 -CheckOnly`: exit zero, exactly one output line, canonical absolute existing `python.exe`. No Python path is guessed.
- Each fresh attempt uses `ProgramData\acm-<8 lowercase hex>\msys64` and a matching fresh `LocalAppData\acm-log-<8 hex>` receipt directory outside the extraction parent. The base helper creates/protects these locations and rejects unsuitable volumes, paths, elevated tokens and preexisting roots. Partial roots/logs are preserved and their actual log path is recorded; no retry deletion or system-root reuse occurs.
- The base result/root/receipt are bound before packages. The returned package object must have schema 1, VERIFIED_PINNED_PACKAGES, exact root, manifest/base receipt hashes, private HOME and nonempty post-install closure. It is atomically written using CreateNew, Flush(true), and a no-overwrite move into the protected base log directory. The wrapper rechecks the stored receipt, protected paths, exact base fields/Boolean flags, extraction receipt hash/counts, full post-package code snapshot including `ucrt64/bin/**`, and a native preflight capability check at the selected root.
- Native child exit codes are captured immediately for Python and preflight. Base/package PowerShell script failures terminate under ErrorActionPreference Stop and cannot become success from an unrelated LASTEXITCODE. Successful output consists of exactly four lines: root, base receipt path, package receipt path, lowercase package receipt SHA256. Inno rejects extra lines, foreign/nonmatching paths or uppercase/nonhex hashes. Same-attempt reuse rechecks identities/closure/capabilities and requires the identical receipt framing/hash.
- Cancellation is signaled serially through the existing cancel file, passed to the base helper, and checked around package preparation and native capability verification. The package helper currently has no in-transaction cancellation switch: it may finish a running transaction, after which cancellation prevents prepared status/source build. This limitation is explicit; no cancellation is treated as success.
- Before the wrapper's final capability query, ambient Bash startup/environment inputs and exported functions are cleared; PATH/HOME/MSYSTEM are constrained and CWD is the selected root. This is confined to the fresh native child. Existing helpers restore their child caller environment. The parent-owned bootstrap must independently verify the authenticated TAR-derived private HOME startup files before immutable source-build login queries.
- Source build receives `-MsysBash`, `-MsysPackageReceiptPath`, `-MsysPackageReceiptSha256` and `-MsysBaseArchivePath`. Actual PrepareToInstall exits before source build on every MSYS failure.

Official [MSYS2 license information](https://www.msys2.org/license/) explains that components have individual licenses and metadata is maintained on a best-effort basis. The wizard requests review/authorization; it does not assert that one project license covers every component or waive applicable obligations. Original component notices remain the frozen helpers' archive-preservation responsibility.

## RED / GREEN and boundaries

Preimplementation command:

```powershell
powershell.exe -NoProfile -ExecutionPolicy Bypass -File tests/InstallerMsys2Wizard.Tests.ps1
```

RED: exit 1, `Actual MSYS wizard behavioral entry point missing: MsysResultPaths`. The test required the new executable decision interface before implementation.

GREEN: the same command compiles unchanged actual Pascal decision bodies with the exact pinned ISCC, substitutes only acquisition/native boundaries with first-party Pascal fixtures, and executes thirteen cases: decline, success, reuse, tampered retry, download failure, base failure, package failure, capability failure, cancellation, extra output, foreign root, foreign log and uppercase hash. It also evaluates the actual PrepareToInstall body and asserts zero source-build calls after failures, exact four bootstrap inputs after success, and no MSYS reacquisition during retry.

The diagnostic has no production helper files, PowerShell/native process children, archive extraction or vendor calls. It creates only first-party fixture files in its own Inno temporary directory and aborts before installation. A valid native-shaped trailing newline is covered. Generated actual orchestration commands are parsed by the PowerShell 5.1 AST parser. Only explicitly selected actual SafePath/Pin/Protected functions and the Boolean-field loop are evaluated in isolated first-party fixtures: traversal/relative paths, changed pins, modification while read-locked, inheritable-only foreign writes and string Boolean claims are rejected. The full orchestration command is never evaluated by the host test.

An initial ACL fixture's Set-Acl call required SeSecurityPrivilege. The fixture was changed to the ordinary .NET Directory.SetAccessControl API and passed. A compile replay initially passed a nested JSON argument array; its usage-error evidence was preserved and the replay was corrected with an explicit string[] cast. Neither was a production behavior change or a vendor operation.

Final GREEN evidence directory:

`C:\Users\beilo\AppData\Local\Temp\autoclip-msys-wizard-c91507155b6a43bb8e2c2f191306a224`

It contains exact diagnostic source, compile log, executable, all case result/command files and successful-case bootstrap arguments; first-party guard fixtures remain preserved.

Builder regression command:

```powershell
& 'C:\Users\beilo\AppData\Local\Programs\Python\Python311\python.exe' -I -B -m unittest discover -s .github/tests -p test_inno_build.py
git diff --check -- installer/AutoClip.iss
```

Result: seven builder tests PASS; diff check PASS. Existing Python diagnostic assertions were not edited or rerun. Its earlier endpoint remediation and remaining blocked cases stay as recorded in IM-PY-03; the new no-native-child MSYS decision diagnostic passed on the host and does not resolve that separate finding.

## Frozen identities and compilation

| File | SHA256 |
| --- | --- |
| installer/AutoClip.iss | a383369aca66be0d344bff2cb24a2a2b8235097c7461fb5b1dce04bc7927265d |
| tests/InstallerMsys2Wizard.Tests.ps1 | d5112473e8642e6f1046557478610fb32154638fb3fe2760f5039c3e2d8f8653 |
| exact ISCC.exe | d06ebd38f38e3cee60a3c50cc45bd449d77e0bc6a5cabc607ea9886808e4de1a |

The final production source was compiled directly for syntax/embedding verification only. The installable builder gate was not bypassed for an installation or promotion. Canonical BLOCKED remains unchanged.

Final compile-only evidence:

`C:\Users\beilo\AppData\Local\Temp\im-ms-12-compile-799ee3c8ca98475c8500db5e35ef1062`

This directory contains source.iss, compile-arguments.json, compile.log and compile-receipt.json. Compilation exited zero; unexecuted compile-only setup SHA256 is `ed16c5d62c5f582de66723ede8ab64e914ad6a99f6c598b7726e0d8d14d5106c`. Exact replay command (use a fresh output directory by changing only the first argument):

```powershell
[string[]]$compileArgs = Get-Content '<evidence>\compile-arguments.json' -Raw | ConvertFrom-Json
& 'D:\AutoClip-Inno-Migration\InnoSetup7\ISCC.exe' @compileArgs
```

The compile argument record binds current helper/source/manifest hashes. Parent integration must rebuild against its final exact helper/bootstrap/manifest snapshot; this compiler result is not a qualified candidate or install receipt.

## Remaining qualification

The full fixed PowerShell command, real ordinary-user base/packages, complete wizard flow, runtime source build/activation, endpoint behavior of production Setup, cancellation during a real native transaction, VM UI and recipient agreement remain unperformed in this work order. The parent owns their qualification. Native helpers' full-success counts are not asserted from synthetic fixture execution. No unrelated source, manifest, builder, dependencies, protection settings, global PATH or VM state was changed. Production/test files are frozen for parent integration/review.
