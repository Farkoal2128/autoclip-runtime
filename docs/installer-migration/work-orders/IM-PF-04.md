# IM-PF-04: native platform guard

Authorization: parent explicitly assigned the native platform implementation
and expected behavior. Owned files: `installer/preflight.ps1`, new
`tests/InstallerPlatform.Tests.ps1`, and this report. No manifest, classification,
Inno or bootstrap changes were made. Existing PF03 MSYS2 and Python checks and
the parent's preflight/audit tests were preserved.

Requirement/contract: `contract-v1.md` Platform and identity supports Windows
10/11 native x64 desktop, excluding ARM64/emulation, x86, server and older
Windows. Classification: installer/updater. Unsupported or unverified platforms
must fail before capability execution or machine changes.

## Implementation

Immediately after validating the input manifest schema, preflight reads
`Win32_OperatingSystem` and `Win32_Processor` with the built-in CIM cmdlet.
It requires exactly one OS row, `ProductType=1` desktop/workstation, a strictly
integral build number of at least 10240, and a nonempty processor list containing
only `Architecture=9` native x64. Missing, ambiguous, mixed, malformed and failed
native observations are rejected. Process architecture environment variables
are not consulted; emulated process values cannot substitute for native CIM
architecture.

Rejection writes a readable native Windows 10/11 x64 desktop requirement to
the requested report, returns the existing JSON shape with `ready=false`,
`blocked=true` and a blocked Windows platform row, and exits 2 regardless of
the optional readiness switches. This exit precedes all capability probes.
Supported platform flow continues through the existing checks.

## RED and GREEN

Exact commands from `D:\Projects\autoclip-runtime`:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File tests/InstallerPlatform.Tests.ps1
powershell -NoProfile -ExecutionPolicy Bypass -File tests/InstallerPreflight.Tests.ps1
git diff --check -- installer/preflight.ps1 tests/InstallerPlatform.Tests.ps1 docs/installer-migration/work-orders/IM-PF-04.md
Get-FileHash installer/preflight.ps1,tests/InstallerPlatform.Tests.ps1 -Algorithm SHA256
```

Before production edits, the first command exited 1. The real preflight script
ran against an empty dependency manifest with only the native CIM boundary
mocked. ARM64, server, pre-Windows-10 and missing/mixed/malformed native fixtures
were all incorrectly accepted with exit 0, `ready=true`, `blocked=false`.
These were actual script results, not source-presence assertions.

Final GREEN: the same platform command exited 0 for sixteen boundary cases:
Windows 10/11 native x64 acceptance; ARM64, x86, server/domain controller, older
build rejection; absent processor/OS, mixed processors, multiple OS records,
malformed/overflow build, malformed architecture, missing product type and CIM
failure rejection. Rejected cases assert exit 2, JSON status and readable report.
No production bypass flag or environment override was added.

The existing preflight suite exited 0 on the real developer host, including
PF03 read-only MSYS fixture behavior, Python CheckOnly and prior capability
and reporting cases. Read-only native observations on this host were OS
ProductType 1, BuildNumber 26200 and processor Architecture 9. No actual MSYS
execution occurred. Scoped whitespace validation exited 0.

## Frozen handoff and limits

- Preflight SHA-256:
  `65ad2220347bf2ca0fadee25622ab33d48f00f95292974c92b2ea8eab6346409`.
- Platform tests SHA-256:
  `44135c950c80a94caf55048260503dfda9736de55a2b5202115954b98b98364d`.

This is mocked native-boundary evidence plus a focused suite on the existing
native x64 desktop. It does not qualify actual ARM64, x86, Windows Server,
Windows 10 hardware, emulation, a clean VM setup, prerequisite installation,
Inno executable behavior, media workflow or publication. The parent separately
owns the Inno `ArchitecturesAllowed=x64os` guard and exact candidate checks.

Primary references inspected:
[Win32_Processor Architecture](https://learn.microsoft.com/en-us/windows/win32/cimwin32prov/win32-processor)
and [Win32_OperatingSystem ProductType/BuildNumber](https://learn.microsoft.com/en-us/windows/win32/cimwin32prov/win32-operatingsystem).
