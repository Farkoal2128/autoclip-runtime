# IM-VS-10 — ordinary guest C++ capability probe preparation

## Scope and requirement

Parent authorized preparation of `D:/AutoClip-Inno-Migration/vm-transfer/vs-capability-probe.ps1` and this report only. No VM control, vendor installation, canonical manifest change, or release action. The parent reports the offline guest installation completed with numeric exit 0 and 132 packages; this author did not execute or independently qualify that installation.

The probe defaults to read-only JSON planning. `-VerifyInstalled` requires username `autocliplab`, native 64-bit PowerShell/OS, and an unelevated token before mutation or native execution. It selects exactly one complete/launchable BuildTools instance through signed absolute `vswhere.exe`, requiring both VC x86/x64 tools and Windows11SDK.26100. Expected installation version is `17.14.37710.0`, product display version `17.14.41`, compiler prefix `19.44.`, and SDK files version directory `10.0.26100.0`. It records the discovered default VC toolset version instead of guessing its final build number.

## Interface and receipt

```powershell
# Read-only; even -PostResult alone cannot post or execute.
powershell.exe -NoProfile -File .\vs-capability-probe.ps1

# Parent-owned ordinary guest run, offline receipt only:
powershell.exe -NoProfile -ExecutionPolicy Bypass -File .\vs-capability-probe.ps1 -VerifyInstalled

# Parent may add this only after restoring guest networking:
powershell.exe -NoProfile -ExecutionPolicy Bypass -File .\vs-capability-probe.ps1 -VerifyInstalled -PostResult
```

`-PostResult` sends only a compact result to the existing local guest laboratory endpoint `http://10.0.2.2:8765/processes`, with a 10-second timeout and no TLS/certificate bypass. It is disabled by default and requires successful context verification. Post failure is reported separately and does not invent or replace capability evidence.

Output is a fresh `%TEMP%/autoclip-vs-capability-<uuid>` directory, created with a protected DACL owned by the current SID, with inherited FullControl ACEs only for that SID, SYSTEM, and Administrators. Its owner and ACEs are inspected after creation. Existing destination and reparse ancestors are rejected. Receipt writing requires this successful protection check. No unrelated paths are cleaned or removed.

`receipt.json` schema version 1 stores status, phase/error, output path/SDDL/user SID, full stdout/stderr/exit/arguments for each native command, installation metadata, required component IDs, file paths/sizes/SHA256/signatures/versions, toolset version, PE machine, optional engine/VCOMP metadata, and explicit false NVIDIA/OpenMP execution claims. Compact stdout/post contains the full receipt path and SHA256. Terminal statuses are `VERIFIED_X64_COMPILE_LINK_RUN` or `FAILED`; exit is respectively 0 or 2. The production route remains `BLOCKED` in either case. Failure before protected output creation has no durable receipt and returns its error in stdout.

## Behavior prepared

- Absolute Microsoft-signed installer `vswhere.exe`, compiler, and System32 `cmd.exe`; file/ancestor reparse rejection. Required component selection comes from supported `vswhere -requires` semantics. Full package metadata, when available, is separately recorded from the matching installed `_Instances/<id>/state.json`; it is not mislabeled as an expanded vswhere package response.
- Existing VC headers/libs and Windows SDK Windows.h, UCRT stdio.h, x64 kernel32.lib/ucrt.lib are checked and hashed. `VsDevCmd.bat` and the discovered default toolset marker are also hashed.
- Each child gets a controlled initial System32/SystemRoot PATH and owned TEMP/TMP. Compiler/link flags and inherited VS/VSCMD/VC/SDK setup markers are removed from the child environment. The caller's environment is unchanged. `cmd /d /v:off` disables AutoRun and delayed expansion; verified absolute paths reject quotes, percent expansions, line breaks, NUL, and reparse ancestors. Static generated batches call `VsDevCmd -arch=x64 -host_arch=x64 -winsdk=10.0.26100.0`.
- `cl /Bv` is captured without source. Its expected nonzero diagnostic exit is retained; version output must contain 19.44. Separate compile/link must exit 0, output PE machine must be 0x8664, and running the first-party executable must exit 0. The fixed source includes windows.h and checks 64-bit pointers plus GetCurrentProcessId. Native command timeout is 180 seconds; only the exact started process is killed on timeout.
- Installed engine candidates are inspected for valid Microsoft signatures and exact file version `4.10.30.62513`; absence of that discoverable version is explicitly recorded. Optional System32 vcomp140.dll is recorded with Microsoft signature and a minimum-version result for `14.44.35211.0`, without OpenMP execution. Neither optional observation manufactures a successful engine-acquisition or OpenMP qualification.

## RED and host GREEN evidence

Before implementation, executed:

```powershell
$candidate='D:/AutoClip-Inno-Migration/vm-transfer/vs-capability-probe.ps1'
if (-not (Test-Path -LiteralPath $candidate)) {
    throw 'RED: readonly VS capability probe plan and context guards are missing.'
}
& $candidate
```

Observed exit 1 with the expected missing-probe message. No production probe existed at RED.

Executed host-only verification using PowerShell 5.1:

1. `[Management.Automation.Language.Parser]::ParseFile(...)` returned no parse errors.
2. `powershell.exe -NoProfile -File D:/AutoClip-Inno-Migration/vm-transfer/vs-capability-probe.ps1` returned exit 0 and parsed `READ_ONLY_PLAN`, `native_execution=false`, `post_result=false`.
3. The same command with `-PostResult` still returned the read-only plan without posting.
4. AST-extracted actual `Assert-ProbeContext` accepted `autocliplab/64-bit/unelevated` and rejected different-user, non-native64, and elevated fixtures.
5. AST-extracted actual `Get-ProbePeMachine` accepted a bounded synthetic MZ/PE x64 header and rejected a corrupted PE signature.
6. AST-selected the actual two child-environment clearing loops, applied them to a disposable `ProcessStartInfo` containing CL, VSCMD_VER, __VSCMD_PREINIT_PATH, and VCINSTALLDIR markers, and confirmed all four were removed. An initial harness selected the wrong AST property and failed; correcting `Body.Statements` to `Body.EndBlock.Statements` made the actual production statements execute and pass. This harness error is not counted as behavioral RED.

Exact final verification output: `GREEN: parser, default including -PostResult remains readonly, production child-environment cleaning AST fixture.` Previous fixture output: `GREEN: PS5.1 parse, read-only default, three rejected contexts, accepted ordinary guest fixture, x64/malformed PE fixtures.`

Frozen probe SHA256: `1d21903d4dde93e5b5094d5ed8a8a13f48f47f069bbedf3b5944e8abd443ca35`.

## Primary references and limits

Microsoft documents developer command setup and the toolchain environment in [Use the Microsoft C++ Build Tools from the command line](https://learn.microsoft.com/en-us/cpp/build/building-on-the-command-line?view=msvc-170). Microsoft's [vswhere examples](https://github.com/microsoft/vswhere/wiki/Examples) establish that all IDs passed to `-requires` must be installed by default.

Only preparation, parsing, default behavior, and pure/child-environment fixtures ran on the host. No installed guest compiler, SDK, engine, signature, DACL, compile/link, native executable, or network post was tested by this author. Parent must execute the frozen probe as the ordinary guest user and inspect the actual receipt. Installed metadata and trusted signatures are runtime observations, not an independently pinned whole compiler execution closure. A child timeout does not qualify any surviving child processes. This laboratory probe is not the production installer, and cannot close unresolved catalog/engine acquisition, legal, signing, release, whole wizard, NVIDIA, or source-build gates.
