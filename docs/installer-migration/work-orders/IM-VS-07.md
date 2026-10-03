# IM-VS-07 — interactive offline Build Tools guest probe

Status: first-party probe frozen; parent owns guest execution, native UAC /
agreement interaction and installed capability verification. Production route
remains **BLOCKED**. This worker ran no vendor executable, host installation,
layout acquisition, VM or network mutation. Only this report and scratch
`D:\AutoClip-Inno-Migration\vm-transfer\vs-install-guest-probe.ps1` were added.

## Input evidence and bounded interface

Read the existing runtime/installer instructions and IM-VS-05/06 evidence.
The parent supplied a separate real guest supported `--verify` receipt at
`D:\AutoClip-Inno-Migration\vm-vs-verify-75f7abaf5edb.json`. This worker rehashed
and read that primary file: SHA-256
`75f7abaf5edb6a7c5ebae1d05ba07d743dd12407ba22f3d1d1950a051a67ed6e`,
status VERIFIED_EXACT_LAYOUT_ONLY, numeric exit0, PID1168 terminal,409/409
comparison with no differences both before and after. That parent-performed
operation verifies layout only. The earlier acquisition's missing numeric exit
remains a failed receipt; no exit is inferred and no original handle is restarted.

Probe input layout is fixed to the parent-observed guest stage:
`C:\Users\AUTOCL~1\AppData\Local\Temp\acvs-fd9e3fbd6cec\layout`.
It uses first-party comparator and expected inventory already downloaded in
that protected parent. No new input or vendor payload is downloaded by this
probe. All vendor bytes remain recipient-acquired and on guest.

Default emits READ_ONLY_PLAN / exit0 and performs no native execution, file
validation, staging, CIM query or HTTP request. The installation branch requires
both explicit switches:

```powershell
# Download/verify this first-party probe while VM networking is still connected.
# In the same guest PowerShell session, before parent disconnects the VM NIC:
Import-Module CimCmdlets
# Parent disconnects the VM NIC, then invokes the already-downloaded script:
& .\vs-install-guest-probe.ps1 -InstallBuildTools -RequireNetworkDisconnected
```

Parent must verify probe SHA-256
**`27cce427423f14d580f2d6dd005b53b685ca8062783a39681f3ba8bd8c339f02`**
and preserve the previous `/processes` result before running it. Preloading CIM
in the same session avoids depending on NetAdapter module loading after network
disconnection. The script uses native CIM, never `Get-NetAdapter` or network
Enable/Disable methods. Failure to read native metadata blocks launch.

## Prelaunch checks and exact command

The explicit branch requires protected, current-recipient-owned staging with
only current SID / SYSTEM / Administrators allowed and no reparse ancestors.
It retains an observation mutex and rejects active common VS setup / Windows
Installer process names so native operations are serialized. It checks:

- exact bootstrap4,473,792 bytes / SHA-256
  `37bb0fb429d163ecebd272a865d11a37b906d152bef960da2ddb29c2e2fd6eeb`;
- Valid Microsoft Authenticode signer organization, ProductVersion17.14.41,
  FileVersion17.14.37710.0 and BuildTools product name;
- comparator SHA-256
  `fc7c45a56d5205c765ce7ff55aa1b3fcc92c24086c9eeaabbb8bd986854bc767`
  and expected inventory SHA-256
  `545b140236b4765a964c14708dcbf1e6131497a58c1655be081631b4f8a91397`;
- actual pinned comparator exit0, `matches:true`, expected409 and actual409;
- nonexistent `disabled-update.chman` before and immediately before launch;
- CIM adapter disconnection both before comparison and immediately before launch.

The network guard rejects connected2, transitional1/3/8/9/12, malformed or
unknown status, enabled adapters with unknown state and absent/failed metadata.
Known disconnected / disabled states and explicitly disabled or logical dummy
adapters can pass. It examines physical and virtual adapters. This is a
supplemental observation, not network containment: Microsoft marks the queried
Win32_NetworkAdapter class deprecated and IPv4-limited. Parent's actual
hypervisor NIC disconnection is required containment evidence; this script
changes no adapter, firewall, certificate or antivirus settings.

Fixed native arguments (the bootstrap path is fixed and verified above):

```text
--noWeb --wait --channelUri "C:\Users\AUTOCL~1\AppData\Local\Temp\acvs-fd9e3fbd6cec\disabled-update.chman" --installChannelUri "C:\Users\AUTOCL~1\AppData\Local\Temp\acvs-fd9e3fbd6cec\layout\ChannelManifest.json" --installCatalogUri "C:\Users\AUTOCL~1\AppData\Local\Temp\acvs-fd9e3fbd6cec\layout\Catalog.json" --channelId VisualStudio.17.Release --productId Microsoft.VisualStudio.Product.BuildTools --add Microsoft.VisualStudio.Component.VC.Tools.x86.x64 --add Microsoft.VisualStudio.Component.Windows11SDK.26100 --addProductLang en-US
```

There are no quiet/passive, broad workload, optional/recommended, custom RunAs,
agreement acceptance automation or interactive `--norestart` arguments. The
signed bootstrap is launched visibly with Diagnostics.ProcessStartInfo,
UseShellExecute=true and Normal window style; native UAC and agreement UI remain
under parent interaction. User acceptance authorization applies only to these
VM tests. Fixed arguments select defaults; parent must inspect actual native UI
selection and agreements before continuing.

## Process and result handling

Uses a Diagnostics.Process object and caches its Handle immediately after
launch while retaining PID and exact UTC start time. This follows the parent's
successful numeric-exit verify pattern and avoids the VS06 Start-Process null
ExitCode path. `live-process.json` is written in a fresh inherited-protected
`interactive-*` guest receipt directory before waiting. No handle is restarted.
The60minute observation limit leaves the exact recorded native process alive;
there is no Kill, forced CloseMainWindow, retry or restart. A terminal getter
must return an actual Int32 before any exit is recorded; null is not cast to0.

Exit0 is recorded as vendor_zero_pending_capability_checks,3010 as
reboot_requested_pending,1602 as recipient_declined_or_cancelled,1641 as
unexpected_reboot_failure, and other codes as vendor_nonzero_failure. Numeric
zero causes probe exit0 but remains `terminal_vendor_result_unqualified`.
It is not an installed-capability success claim. No restart is suppressed or
automated; an unexpected actual reboot may interrupt observation.

Full guest receipts record prelaunch metadata, native arguments, actual process
result and timestamp-selected native log paths/lengths/hashes. Logs themselves
stay guest; timestamp/name candidates are not asserted as exact PID attribution.
Preflight failures after safe staging validation also retain a full receipt.
If the staging path is unsafe, only stdout summary can be written safely.
Only a compact summary is attempted at existing `/processes` with10sec timeout.
Offline POST is expected to be unavailable; `summary.json` and
`full-receipt.json` remain guest. The probe never reconnects networking to post.
Parent must keep NIC disconnected while any recorded vendor operation remains
active and separately recover these first-party receipts after terminal state.

## Executed first-party verification

RED1: absent new diagnostic probe raised
`RED: explicit offline native-install preparation probe is absent.` / exit1.
This is preparation capability evidence, not a vendor regression result.
Meaningful guard RED2 executed the actual extracted guard function with mocked
native CIM metadata and showed that `NetEnabled='malformed'`, null connection
status was accepted as offline. Test raised
`RED: malformed native adapter metadata accepted as offline.` / exit1.
Added type and unidentified-adapter rejection; retained the assertion.

Final safe default check, Windows PowerShell5.1:

```powershell
& "$env:SystemRoot\System32\WindowsPowerShell\v1.0\powershell.exe" -NoProfile -Command 'function New-Object {throw "native process boundary unexpectedly executed"}; function Get-CimInstance {throw "native CIM boundary unexpectedly executed"}; function Get-FileHash {throw "file boundary unexpectedly executed"}; function Get-AuthenticodeSignature {throw "signature boundary unexpectedly executed"}; function Invoke-WebRequest {throw "network boundary unexpectedly executed"}; & "D:\AutoClip-Inno-Migration\vm-transfer\vs-install-guest-probe.ps1"'
```

GREEN: actual complete script returned READ_ONLY_PLAN / exit0 with those
boundaries set to throw. Final parser check had no errors. The actual bootstrap
validation function was extracted by function AST and passed real read-only
host metadata/hash/Authenticode checks on the preexisting exact bootstrap.
No vendor executable was run.

Actual guard function extraction for first-party fixtures:

```powershell
$t=$null; $e=$null
$a=[Management.Automation.Language.Parser]::ParseFile('D:\AutoClip-Inno-Migration\vm-transfer\vs-install-guest-probe.ps1',[ref]$t,[ref]$e)
$n=$a.Find({param($x)$x -is [Management.Automation.Language.FunctionDefinitionAst] -and $x.Name -eq 'Assert-VsOfflineNetwork'},$true)
. ([scriptblock]::Create($n.Extent.Text))
function Get-CimInstance {param($ClassName,$ErrorAction) if($script:cimThrows){throw 'firstparty CIM failure'}; $script:adapters}
```

GREEN19 guard cases: disconnected0, media-disconnected7, disabled5,
disabled/null state and logical dummy/null state pass; connected2,
connecting1, disconnecting3, authenticating8, authenticated9, credentials12,
unknown13, malformed status, enabled/null state, unidentified/null state,
malformed enabled metadata, virtual connected adapter, empty query and CIM
failure reject. These mock only the native query; real guard logic executes.

Unperformed by this worker: explicit install branch, real guest CIM guard,
native UAC/agreements, process wait/timeout and numeric product exit, receipt /
POST runtime and installed VC/SDK capability checks. Parent separately observes
native terms, `vcvars`, `cl.exe /Bv`, SDK headers/libs and x64 compile/link.
Exact bootstrap/layout verification does not prove those capabilities or bind
all possible installer engine behavior. Catalog declared pin and140 payload
size conflicts remain unresolved. No legal, blind review, public route or
publication approval is established.

Primary API references inspected: [Process.ExitCode](https://learn.microsoft.com/en-us/dotnet/api/system.diagnostics.process.exitcode)
and [Win32_NetworkAdapter connection state](https://learn.microsoft.com/en-us/windows/win32/cimwin32prov/win32-networkadapter).
Microsoft command constraints remain as recorded in IM-VS-05/06.
