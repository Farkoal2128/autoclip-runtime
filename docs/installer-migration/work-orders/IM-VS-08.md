# IM-VS-08: offline layout entry point

Scope: parent guest diagnostic qualification under the user's existing
Build Tools VM-test consent. Production acquisition remains BLOCKED.

## Original terminal failure

IM-VS-07 invoked the exact signed bootstrap outside the verified layout,
with the layout as its working directory. After native UAC and Microsoft
agreement UI, it attempted to fetch its installer engine from a mutable
`aka.ms` URL despite `--noWeb`. The disconnected guest prevented acquisition.
Native UI displayed an installation-file download failure; closing that
terminal error produced numeric exit 5003. The recorded process PID 7804
was terminal, and an independent CIM query found no remaining vendor installer
process before another attempt began. No observation timeout caused a retry.

Primary receipt: `D:/AutoClip-Inno-Migration/vm-vs-offline-failure-1f128baeff62.json`,
SHA256 `1f128baeff627d25dd43bac02d62df2afde6a0d0db7f2e90e79d7202b1dbb4fd`.
Guest full receipt and logs remain at
`C:/Users/AUTOCL~1/AppData/Local/Temp/acvs-fd9e3fbd6cec/interactive-d2479fb22c9a`.
Screenshot: `D:/AutoClip-Inno-Migration/vm-vs-offline-install-ui-08.png`.

## Corrected candidate and check

The verified 409-file layout already contains `vs_setup.exe`, the exact
bootstrap bytes, adjacent to its pinned installer OPC/version/control files.
The new first-party diagnostic copy changes only the selected executable to
`layout/vs_setup.exe`; all signature, pin, layout comparison, network-off,
native interactive UI, exit and receipt checks are retained. The original
probe and report remain frozen historical evidence.

Actual default-plan behavioral check:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File D:/AutoClip-Inno-Migration/vm-transfer/vs-install-guest-probe.ps1
powershell -NoProfile -ExecutionPolicy Bypass -File D:/AutoClip-Inno-Migration/vm-transfer/vs-install-layout-probe.ps1
```

RED: original plan chose the external-stage bootstrap. GREEN: corrected plan
chose `layout/vs_setup.exe`, with `vendor_execution:false`. This check proves
entry-point selection only, not native installation.

Corrected probe SHA256:
`6464a7efe999277172e3f5350f82a207c7b2c6a6f9a450bcc0a98a092881caa1`.
The guest downloaded and hash-checked this first-party script while connected;
the host then disconnected VirtualBox NIC 1 before explicit native execution.
Vendor bytes were already recipient-downloaded, not host-served.

## Remaining qualification

Native product result, exact installed engine/component versions, `vswhere`,
compiler/SDK capability and x64 compile/link still need primary evidence.
Catalog hash/size contradictions are preserved; this diagnostic correction
does not silently replace channel pins or authorize a connected production
route. Whole Inno installation, installed media/lifecycle, final packaging and
blinded technical review remain separate gates.

## Real disconnected native product result

The corrected entry point reached the native Build Tools 17.14.41 component
screen without networking. The selected individual components were MSVC v143
x64/x86 tools and Windows 11 SDK 10.0.26100.7705. The native UI installed
132 packages and then reported Build Tools 17.14.41 installed. After closing
the completed native UI, the recorded process PID 12772 returned numeric exit
0, with `process_live:false`; no reboot-required result was reported.

Primary receipt: `D:/AutoClip-Inno-Migration/vm-vs-offline-install-b395d9c94420.json`,
SHA256 `b395d9c944202c12d7947ff5e4bf7705a7109e05ebc47f81fe17e285c89524a6`.
Full guest receipts/logs remain under
`C:/Users/AUTOCL~1/AppData/Local/Temp/acvs-fd9e3fbd6cec/interactive-6705e2e28f96`.
Screenshots include `vm-vs-layout-product-moved.png` (selected components),
`vm-vs-layout-install-progress.png` (package 130/132),
`vm-vs-layout-install-progress3.png` (installed version), and
`vm-vs-layout-terminal.png` (numeric exit).

This is a real prepared-VM native product result, not yet compiler/SDK
capability, clean full wizard or source-build qualification. NIC 1 remained
off throughout native execution and was re-enabled only after terminal state
to transfer first-party receipts. The installer attempted developer-news
network access; that optional UI content was unavailable. Product acquisition
control, catalog signature/conflict disposition and the full final candidate
remain open despite the successful offline installation.
