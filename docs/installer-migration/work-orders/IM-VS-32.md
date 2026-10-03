# IM-VS-32 — next prerequisite step after the cold engine observation

Status: read-only mapping, 2026-10-02. This work order changes only this report. No acquisition, VM operation, vendor execution, source change or gate promotion occurred.

## Evidence and decision

Rehashed the 617,024-byte primary `D:/AutoClip-Inno-Migration/vm-vs29-engine-primary-c58388acef28.json`: SHA256 `c58388acef285d67e383127d2a9d352f850f6248f12894f34ef7e5cc1f770c21`. Its original receipt remains `FAILED_PRESERVED`, phase `engine_update`, with vendor execution recorded and **unknown outer native PID12768 exit**. First-party driver exit2 is not a vendor exit. The current native authentication and actual retained vendor logs report successful OPC verification, engine extraction, inner setup exit0 and installer finalization exit0. The complete installed868 path/length/SHA triples match the VS25 authenticated OPC inventory; the captured process snapshot has no currently matching VS/setup/msiexec names. This is output identity and vendor-reported component success, not a reconstructed outer exit or complete past process/module trace.

There is no need to repeat a cold engine-only action solely to fill that historical missing exit field. The current recipient can support the next bounded layout preparation and qualification. IM-VS-31 fixes the actual native-handle observation bug, with host tests for exits0/7; its cold-absence guard prevents replay on this now-installed engine. Preserve both the original failure and corrected test evidence. Root decides gate status. The final fresh CPU Inno wizard must still exercise the actual corrected supervisor, prerequisite acquisition/install, application/media flow and lifecycle; this observation cannot substitute for it.

## Smallest reusable preparation

1. Acquire the397 selected product payloads directly in this recipient with the existing `vs-pinned-preload-probe-r2.ps1` (15,769 bytes, SHA256 `fcc4bab2e423303c5dd11ac4b3139b5c61fe1bef45f1a57a0865c79b26826fe8`). After root's source verification, its explicit ordinary native64 guest invocation is:

   ```powershell
   powershell.exe -NoProfile -File <verified-first-party-probe> -PreloadPayloads
   ```

   Default invocation is read-only. The explicit operation creates a fresh protected short stage, downloads to safe hash cache names through the unchanged protected downloader, and copies locked verified bytes to the manifest-approved vendor paths. It executes no vendor code. Its fixed first-party dependencies are downloader SHA256 `75ac92e4108a6fd3165617b2c94be02b44ca86c61a5397672d898eaa38635ad6`, inventory `545b140236b4765a964c14708dcbf1e6131497a58c1655be081631b4f8a91397`, and derived397-row manifest `15d558e950e713b20ff16c0347b0bf933087adfd1b06b3c0148f5aab74cf0efc`. Retain its actual new receipt/stage; do not substitute the old warm VS20 receipt or transfer vendor bytes from another VM/host.

2. Acquire or derive the missing controls through the approved recipient sources, preserving all exact expected identities. The current cold acquisition contains the bootstrapper/OPC, not the old warm Catalog/Channel/certificate source. Selected Catalog is17,954,732 bytes/SHA256 `f0a50ea157222c29abd5ea6ff01bfc3c33b04e011c5e45ee2ca38ef0778e5643`; Channel is91,781 bytes/SHA256 `fca418ba94ffbcfb7a2b25f10f16f39dd09660568d21eef4bd3f274cb0b27b8c`. IM-VS-02 records the official Catalog URL:

   `https://download.visualstudio.microsoft.com/download/pr/bc92e2cb-33de-4a0c-995d-efa817f16b16/6e470016e4324c84c255ffd0beb3767d17ec89cc8561e9409ee3e1f6d29400f5/VisualStudio.vsman`

   Its URL/channel-declared hash differs from the intentionally selected observed body. Keep that conflict and all140 declared/observed size differences. The following controls need no additional vendor download: authenticated OPC member `Contents/vs_installer.version.json` is121 bytes/SHA256 `e78a1053a6d59ad60ba8105623181b013c0ffc452216caada2699046f191974f`; the authenticated selected Catalog's Base64 DER `signature.keyInfo.x509Data[2]` is the1,521-byte manifest root SHA256 `847df6a78497943f27fc72eb93f9a637320a02b561d0a91b09e87a7807ed7c61`, and `signature.counterSign.x509Data[2]` is the1,521-byte counter-sign root SHA256 `df545bf919a2439c36983b54cdfc903dfa4f37d3996d8d84b4c31eec6f3c163e`. The latter also matches the expected OPC-root certificate file. Read-only decoding of the exact host Catalog confirmed both certificate pins; perform any recipient output creation from the held authenticated recipient inputs with CreateNew and full pin checks. This creates ordinary layout files, not certificate-store imports.

   **Channel source remains a concrete acquisition gap:** the inspected frozen inventory has no URL for it, and VS22 uses an old warm file. No immutable official Channel endpoint or authenticated bootstrapper extraction operation is established by this report. A mutable `aka.ms` channel must deliver the exact expected pinned/authenticated bytes or fail; it cannot authorize adopting a replacement identity. Resolve this small source question before the seed/vendor action. Reuse existing JSON/OPC authentication functions only from their verified frozen sources; their old driver paths are not current acquisition evidence.

3. Rebind the existing seed preparation to these actual current-recipient inputs, rather than invent another workflow. `vs-warm-layout-seed-probe.ps1` (16,942 bytes, SHA256 `887ed9af03eff980b08603b280265282bc4520fcffe510834974d70e83013b00`) provides the verified-copy/control logic, but **cannot run unchanged**: it requires old VS20 receipt `a84c9066…`, caches under `vs p-c77a1261`, and controls under `acvs-fd9e3fbd6cec/layout`. Those bindings deliberately fail closed on this guest. A distinct minimal snapshot must bind the new receipt/source paths and retain exact metadata/ACL/readlock checks. The existing seed design copies397 payloads plus9 pinned controls, authors two355-byte local controls (each SHA256 `3795c3caf73be477dbd22f4f967f23edaffae2d6743520178278ee34f559109b`), and records408 incoming files. It omits the original generated template. Preserve the original409 inventory separately.

## Remaining vendor behavior gap

After full incoming authentication, protect elevated executable/control write points, recheck installed868 against the authenticated OPC immediately before use, and disconnect the external guest NIC. Reuse the **proposed**, unexecuted IM-VS-21 layout arguments with the new reviewed root and exact bootstrapper:

```text
<protected exact bootstrapper> --layout <new protected layout> --add Microsoft.VisualStudio.Component.VC.Tools.x86.x64 --add Microsoft.VisualStudio.Component.Windows11SDK.26100 --lang en-US --quiet --wait --noUpdateInstaller --noWeb
```

Microsoft documents layout generation and local layout controls, but initial layout creation requires Internet access; this preseeded disconnected operation still needs actual vendor acceptance evidence. `--noUpdateInstaller` has its documented prevention guarantee with quiet mode. `--noWeb` does not prevent engine update checks. Install-only Catalog/Channel switches do not pin a layout command. Do not reconnect or accept a latest engine if this bounded operation fails. [Microsoft layout guide](https://learn.microsoft.com/en-us/visualstudio/install/create-a-network-installation-of-visual-studio?view=vs-2022), [command reference](https://learn.microsoft.com/en-us/visualstudio/install/use-command-line-parameters-to-install-visual-studio?view=vs-2022).

Success must produce an exact selected layout whose generated controls are reviewed and assigned new pins, with the complete new inventory and vendor `--verify`, before native product installation. The old `vs-layout-guest-probe.ps1` discovers an engine online; the old verify/install probes bind the historical409 source. None is runnable as the current qualified route unchanged. Retain their supported command patterns, native-handle waiting and capability checks, with current reviewed identities. The product step remains native interactive agreements, selected VCTools/SDK install and actual `vswhere`, compiler/SDK compile-link-run verification. Python and the full AutoClip wizard remain separate outstanding work.

## Verification and limits

Read the actual primary, current contract, IM-VS-02/18/21/22/24/25/26/27/28/29/31 and reusable driver source; rehashed the primary and both preparation drivers with `Get-FileHash -Algorithm SHA256`. Read-only comparison of the primary's installed engine members against VS25 found868 matching triples and no changed/extra members. No new tests apply to this documentation-only mapping. No vendor command above was executed, and no full trace completeness, fresh final wizard success or release readiness is claimed.
