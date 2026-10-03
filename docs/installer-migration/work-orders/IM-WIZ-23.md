# IM-WIZ-23 — read-only native PowerShell startup research

Status: ordinary collaborator research complete. Owned only this report.
This is not blind independent review, executed remediation, or a closed runtime
gate. No production, fixture, VM, executable, mitigation, certificate, registry,
vendor or live-process change was performed.

## Exact inspected evidence

Read and independently SHA-checked
`D:/AutoClip-Inno-Migration/vm-wiz22-startup-primary-5d98effeecdb.json`:
`5d98effeecdb66207fb7d722566fff3cf13d3fec7f9e361287721af6598ab96e`.
Captured at `2026-10-02T05:52:35.2596707Z`.

The captured setup log identifies Inno7.1.0 **32-bit**, Windows10.0.26200 x64,
ordinary user, no administrative install mode, 32-bit install mode and parent
RedirectionGuard enforcing. The source-build supervisor exited **-65536**;
stderr says the shell failed during initialization and identifies the
`System.Net.ServicePointManager` type initializer. Stdout is empty. Setup then
records fatal InitializeWizard failure, deinitializes and closes its log.

Relevant primary file records:

- `setup.log` SHA `5e84b159e41c5691c6068999df23cf9c3a48f89da345ab84dbe4109ac81a5301`.
- `supervisor-stderr.log` SHA `f7eae4cdbc459016c08e505a1fa56568b2a1812c28f966e736d13195cb6ae47a`.
- Fixture packet SHA `86958c490659e368bee4bbcf5a2257675b82012a2805dc5cc8dc8f040be6e2b9`.
- Fixture executable SHA `5318e6e962fb63b13ed63c025f7f2603a26d6a8e05051c6137fb7c7c98862801`.

Production Inno source was still SHA
`53d8c0a614884cfb8b2ed3ca334d43daf49ad2c91c835851f7e4c4c41495efd7`;
supervisor SHA
`95a40597f6d196ad3ae23a6bc5a869899f5c0602fb89dcd2de11bf6277475ae0`.
The inspected `.iss` sets `ArchitecturesAllowed=x64os` and omits
SetupArchitecture. Source build and two other asynchronous launch paths use
WScript.Shell.Exec with ApplyPathRedirRulesForCurrentProcess on native
PowerShell; cancellation reuses BuildRequestCommand. Parent confirms r3 used
that exact production executable expression and native64 process observation.

Parent reports no attempt/worker exists and all matching r3 processes are
terminal. The capture contains no worker readiness, attempt status or UI fault
seam evidence. It therefore proves startup failure before the intended worker
observation test, not a successful UI-observation RED. The distinct older
literal-System32/SysWOW64 fixture remains live and preserved; this primary's
empty process list does not establish its disposition.

## What official sources establish

1. Inno defaults SetupArchitecture to x86. Setting x64 builds a native64 setup;
   `ArchitecturesAllowed=x64os` restricts eligible OSes but does not set the
   executable architecture. [SetupArchitecture](https://jrsoftware.org/ishelp/topic_setup_setuparchitecture.htm).

2. The redirection function makes the path accessible to the specified target
   process. It always produces extended-length syntax, including when no
   rewrite occurs: current32/native64 path becomes Sysnative; current64 path
   remains System32 with the prefix. [ApplyPathRedirRules](https://jrsoftware.org/ishelp/topic_isxfunc_applypathredirrules.htm).

3. Inno explicitly documents that launching a native64 child using the
   ApplyPath/Sysnative spelling is wrong for a child needing access to that
   spelling. ExecWithNativeSysDir instead performs a bounded native launch
   without that alias. Microsoft's redirector documentation independently
   states Sysnative is a virtual alias unavailable to64 applications.
   [ExecWithNativeSysDir](https://jrsoftware.org/ishelp/topic_isxfunc_execwithnativesysdir.htm),
   [Microsoft file-system redirector](https://learn.microsoft.com/en-us/windows/win32/winprog64/file-system-redirector).

4. A TypeInitializationException wraps an underlying exception; its type name
   is insufficient to identify the failed operation. This primary contains no
   inner exception, stack or failed config path. [Microsoft exception documentation](https://learn.microsoft.com/en-us/dotnet/api/system.typeinitializationexception?view=netframework-4.8.1).

5. .NET Framework network settings can reside in application or machine config.
   Microsoft reference source derives client configuration from AppDomain setup
   configuration and entry assembly, with a native module-path fallback;
   AppDomainSetup defaults tie app base/configuration to the executable location.
   GetModuleFileName can preserve the loaded path's format. Thus an executable
   spelling unsuitable inside the child is a plausible configuration-path
   mechanism, not proven as this captured exception's inner cause.
   [Network configuration](https://learn.microsoft.com/en-us/dotnet/framework/configure-apps/file-schema/network/servicepointmanager-element-network-settings),
   [ClientConfigPaths reference source](https://github.com/microsoft/referencesource/blob/main/System.Configuration/System/Configuration/ClientConfigPaths.cs),
   [AppDomainSetup reference source](https://github.com/microsoft/referencesource/blob/main/mscorlib/system/AppDomainSetup.cs),
   [GetModuleFileName](https://learn.microsoft.com/en-us/windows/win32/api/libloaderapi/nf-libloaderapi-getmodulefilenamew).

6. Inno documents RedirectionGuard as affecting its own Setup/Uninstall process,
   **not inherited by children**. Therefore the logged parent enforcing status
   alone does not support blaming this native PowerShell initialization on
   inherited guard policy. No mitigation or certificate bypass is supported by
   the evidence. [RedirectionGuard](https://jrsoftware.org/ishelp/topic_setup_redirectionguard.htm).

Official docs/reference source were inspected as current sources; the installed
compiler binary itself was not reverse-engineered and CLR reference source
does not establish the exact guest's internal stack.

## Narrow qualification recommendation, not production authorization

Keep the preserved failed r3 packet as baseline. Parent can qualify a fresh
first-party fixture varying only SetupArchitecture=x64, retaining existing
launch expression, pinned inputs, ordinary token, async observation and
security settings. Log the resolved executable string and actual architecture.
This removes Sysnative while leaving the extended prefix, so it separates the
alias question from prefix compatibility. A success must reach actual worker
readiness and the existing observation seam, then terminally observe the same
worker; startup alone does not satisfy the intended behavioral gate.

If that variant still fails, a separate native64 fixture using ordinary
System32 spelling can isolate extended-prefix behavior. If only this variant
works, prefix compatibility is supported; if both fail, inspect the actual
underlying config/assembly exception before proposing host remediation.
PathConvertSuperToNormal exists, but its documentation limits use to known
extended-path incompatibility; this report does not establish that condition
or propose unconditional conversion.
[PathConvertSuperToNormal](https://jrsoftware.org/ishelp/topic_isxfunc_pathconvertsupertonormal.htm).

Native SetupArchitecture=x64 is a small candidate fitting the existing x64os
requirement and retaining the current WScript asynchronous interface. Preserve
ArchitecturesAllowed=x64os rather than expanding platform support. Review the
changed default64 install mode, system constants and uninstall registration
view before promotion. ExecWithNativeSysDir is a documented alternative for a
32-bit setup, but its Exec-style API does not directly supply the current
WScript process object/PID/Status observation; replacing that interface requires
separate scoped contract and behavioral verification.
[64-bit installer differences](https://jrsoftware.org/ishelp/topic_64bit.htm),
[Install mode differences](https://jrsoftware.org/ishelp/topic_32vs64bitinstalls.htm).

## Performed verification and limits

Performed local read-only Get-FileHash/Get-Content/rg checks on the exact primary,
production source and local compiled-fixture source, plus official Inno and
Microsoft documentation/source inspection. No new runtime test, RED/GREEN
remedy, app/media/GPU test, VM action, vendor action, process disposition,
compile or uninstall was performed. User's production-ready installer before
uninstaller testing order remains. No release gate is closed by this report.
