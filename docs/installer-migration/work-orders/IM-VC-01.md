# IM-VC-01: refuse source work after VC runtime reboot request

Root-owned bounded correction under the existing installer contract's reboot
and failure rules. No dependency route, public interface, vendor arguments,
consent decision or distribution classification changes. Other agents own the
updater serialization files and read-only cleanup investigation.

## RED and GREEN

`powershell.exe -NoProfile -NonInteractive -File tests/InstallerVcReboot.Tests.ps1`

Before production modification, exit1: `RED: VC runtime reboot request allowed
source building to continue.` The test executes the actual installer AST
boundary, replacing only process execution with inert vendor outcomes. It
observes whether subsequent work is reached; it does not replace result handling.

After the minimal production guard, exit0. Vendor success0 continues;
3010 stops with an explicit reboot message; failures1603/1223 and native UAC
cancellation stop. Fixed `/install /norestart`, elevation and synchronous wait
arguments remain checked. No vendor code, VM, setup or uninstaller was executed.

Exact changed inputs:

- `install.ps1`: `d44c944426dc885c1360ba66fa9f5ca737340471b9b5c7cc3b35c005c48415db`
- `tests/InstallerVcReboot.Tests.ps1`:
  `e8a3ccbe296fc99694eec2c7f0da8f9f42a37dad1ab18877f8d1e19080fa727b`

Affected regressions, both exit0:

- `powershell.exe -NoProfile -NonInteractive -File tests/InstallerSecureAcquisition.Tests.ps1`
- `powershell.exe -NoProfile -NonInteractive -File tests/InstallerNoAcquisition.Tests.ps1`

## Scope and remaining qualification

This guard prevents continued source work in the attempt that observes3010.
It does not establish durable reboot state, prevent a pre-reboot rerun from
reusing newly installed DLLs, propagate a reboot classification into Inno, or
qualify post-reboot capability. Those remain required before production readiness.
VC signature/version protection and capability verification also remain open;
the existing single `vcomp140.dll` check is not complete runtime qualification.

The changed bootstrap needs a new bound compiler input/candidate. Historical
5b2994-bootstrap evidence and scoped reviews retain their original exact scope;
they do not approve these changed bytes. No generated candidate was rebuilt or
qualified here. Native uninstaller testing remains after production installer
qualification and before release, with NVIDIA hardware testing deferred.
