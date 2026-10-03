# IM-VS-16 — read-only seeded-layout engine qualification

## Scope and current contract

Parent authorized the new `D:/AutoClip-Inno-Migration/vm-transfer/vs-seeded-layout-probe.ps1`, adjacent first-party fixture tests, and this report only. No existing probes, evidence, source manifest, installer, Inno audit, VM, vendor files or release were changed. No memory was used. Actual model/inference telemetry is not exposed.

Read `contract-v1.md`'s Microsoft 17.14.41 integrity-source decision and IM-VS-14. The expected standalone Catalog is deliberately authenticated/pinned at 17,954,732 bytes / `f0a50ea157222c29abd5ea6ff01bfc3c33b04e011c5e45ee2ca38ef0778e5643`; the exact Channel is 91,781 bytes / `fca418ba94ffbcfb7a2b25f10f16f39dd09660568d21eef4bd3f274cb0b27b8c`. Preserve the channel-declared external Catalog 30,443,537 bytes / `6e470016e4324c84c255ffd0beb3767d17ec89cc8561e9409ee3e1f6d29400f5` and 140 declared/observed payload-size conflicts. Choosing the independently authenticated expected Catalog does not claim equality to that declaration.

After the initial support investigation, the parent explicitly directed a read-only complete installed-engine mapping before any proposed two-phase engine preparation/layout execution. That is the implemented boundary. This probe does not copy a seed, generate new response controls, execute a vendor bootstrap/engine, prepare/update the engine, create a layout, reinstall the product, import certificates, acquire network artifacts or promote the production route.

## Parent interface and output

```powershell
# Default is a read-only plan; -PostResult alone also remains a plan.
powershell.exe -NoProfile -File .\vs-seeded-layout-probe.ps1

# Parent-owned ordinary guest read-only mapping; local receipt:
powershell.exe -NoProfile -ExecutionPolicy Bypass -File .\vs-seeded-layout-probe.ps1 -MapInstalledEngine

# Optional compact first-party post, only when parent enables networking:
powershell.exe -NoProfile -ExecutionPolicy Bypass -File .\vs-seeded-layout-probe.ps1 -MapInstalledEngine -PostResult
```

Explicit mapping requires ordinary `autocliplab`, native64 PowerShell/OS and an unelevated token before writing its fresh receipt. It reads source layout `C:/Users/AUTOCL~1/AppData/Local/Temp/acvs-fd9e3fbd6cec/layout` and the adjacent existing `vs-layout-expected-inventory.json` pinned by SHA `545b140236b4765a964c14708dcbf1e6131497a58c1655be081631b4f8a91397`. It compares **all 409 original source files**, not only selected controls; the schema must contain exactly 397 payload rows with nonempty catalog_sources. No new closure is guessed or payload declared-size conflict overwritten.

Every file is read with `FileShare.Read`, denying concurrent writers while its bytes are hashed. JSON inventory hashing/parsing use the same locked file handle. The pinned OPC is hash-checked again on the handle held open during archive/member inspection. These are read-only snapshot observations; they do not keep every source/installed file locked after the diagnostic or authorize later execution without immediate rechecks. Reparse ancestors/descendants, unsafe relative names, reserved Windows names, duplicate/case-colliding members and unexpected installed files fail closed. File-tree enumeration visits directories individually rather than traversing an unchecked reparse subtree.

The fresh `%TEMP%/autoclip-vs-seed-map-<uuid>/receipt.json` has a current-SID owner and protected DACL with inherited FullControl only for current SID, SYSTEM and Administrators, verified after creation. Source/engine files are never written. Failed checks preserve partial source/OPC/installed evidence; failure before protected output has only stdout error. No failed root is deleted.

Receipts record complete raw expected OPC inventory, actual installed inventory, source comparison, control records, bootstrap signature/version, OPC internal manifest identity and exact missing/extra/changed paths. The mapping is **literal Contents/ removal** into `${env:ProgramFiles(x86)}/Microsoft Visual Studio/Installer`, retaining all relative paths including resources/app. No file extension selector, mutable-file exception or version-only shortcut is used.

Statuses: `EXACT_INSTALLED_ENGINE_CONTENTS_MATCH` / exit 0 only for the full raw tree; `INSTALLED_ENGINE_DIFFERENCES` or other failed preflight / exit 2 otherwise. In all cases `vendor_execution=false`, `source_mutation=false`, `engine_preparation_executed=false`, `opc_signature_verification_executed=false`, and `production_route=BLOCKED`. This diagnostic does not invoke a vendor OPC signature verifier; its complete member identity is derived from the exact pinned OPC bytes.

Optional post to the existing local laboratory `/processes` endpoint binds full receipt path/SHA, reports all missing/extra/changed names, has a 1-MiB UTF8 bound and 10-second timeout. No TLS/certificate bypass or default post occurs.

## Exact OPC and controls

| Input/control | Bytes | SHA256 |
| --- | ---: | --- |
| vs_setup.exe / vs_BuildTools-17.14.41.exe | 4,473,792 each | `37bb0fb429d163ecebd272a865d11a37b906d152bef960da2ddb29c2e2fd6eeb` |
| vs_installer.opc | 50,363,030 | `62f68d0d6e2adce5cd65f549cbda234358c1cbda442af4de1c3f7ae43fb8b5a6` |
| Layout.json / Response.json | 372 each | `05e563d29311a3537a0132e6c99925677e9ef1fbc1dbc6eaf4223d4fc50803d9` |
| Response.template.json | 26,333 | `6e016c4e259f739f2e65a68f2ffa80a1d85179d41e82e83e0bd9830eb1940639` |
| vs_installer.version.json | 121 | `e78a1053a6d59ad60ba8105623181b013c0ffc452216caada2699046f191974f` |

Layout/Response contain relative local installChannelUri/installCatalogUri, immutable original `channelUri=https://aka.ms/vs/17/release/channel`, selected VC.Tools.x86.x64 and Windows11SDK.26100, and en-US. Response.template is catalog-generated and includes all applicable components/languages; it must not be substituted for the selected two-component response. A future explicit local response with disabled update channel would intentionally create new control bytes and require its own inventory; original controls are preserved.

OPC `Contents/vs_installer.version.json` has the exact same 121 bytes; fields include package version `4.10.30.302448642` and installerVersion `4.10.30.62513`. The OPC has **868 regular Contents files / 131,469,618 uncompressed bytes**, including all executables, DLLs, scripts, configurations and other data. Its raw `manifest.json` SHA is `1ed363d4207dfbb0f0a813558349ce53719f39a0d0fb6710171257bad01de356`; the helper requires its schema/count/installSize and checks every declared SHA256 against every raw member, with no missing/added/duplicate declaration.

The 397 payload rows have 432 catalog associations and use independently observed bytes/catalog SHA matches. The original baseline acquisition used a mutable engine before its final inventory was established; these fixed identities do not retroactively qualify that acquisition route.

## Support investigation and next bounded step

IM-VS-15 investigator supplied the historical existing-layout `--verify` log `C:/Users/beilo/AppData/Local/Temp/dd_bootstrapper_20261001112631.log`: adjacent OfflineFilePath at line 13, local OPC signature validation at 19, version comparison at 20, Using Offline package at 21, extraction at 24/25, setup launch at 27/29. That proves one complete existing-layout verification selected local OPC before engine execution; it does not prove fresh/incomplete seed creation chooses that package. The initial creation used a temporary installer OPC and contacted the mutable latest feed. This author did not execute those vendor transitions.

Microsoft documents an **engine-only** offline update from an already updated layout: [Update a network installation](https://learn.microsoft.com/en-us/visualstudio/install/update-a-network-installation-of-visual-studio?view=vs-2022), and [Minimal offline layout](https://learn.microsoft.com/en-us/visualstudio/install/update-minimal-layout?view=visualstudio), including explicit local OPC with `--quiet --update --offline`. A complete pinned baseline copy is closer to that documented starting point than an incomplete seed. The investigator found no inspected instruction specifically prohibiting this engine-only approach. It remains conditional; this probe does not perform it.

Microsoft's [command-line documentation](https://learn.microsoft.com/en-us/visualstudio/install/use-command-line-parameters-to-install-visual-studio?view=visualstudio) establishes bootstrapper layout management, latest-installer defaults for recent bootstrappers, and that noWeb alone does not suppress engine-update checks. Quiet plus noUpdateInstaller fails if an installer update is required; keepLayoutVersion concerns the product version. [Response-file documentation](https://learn.microsoft.com/en-us/visualstudio/install/automated-installation-with-response-file?view=visualstudio) supports an explicitly authored `--in` response. These documented components do not alone establish fresh-seed initial engine selection or ordinary-user engine-update/elevation behavior.

The safe next step is the parent-owned ordinary guest mapping below. If any code bytes differ, preserve the exact primary difference list and do not launch layout code. If the complete raw tree matches, the parent may review the documented engine-only preparation/handoff and a new protected complete seed/explicit local response, with physical NIC disconnection, signature/ACL/input locks and immediate rechecks before any vendor execution. Product installation must still retain native interactive vendor terms. No unsupported flag, arbitrary latest engine, authority bypass or production fallback is supplied here.

## Meaningful RED/GREEN and executed commands

First created the bounded runnable fixture, then ran before implementation:

```powershell
powershell.exe -NoProfile -File D:/AutoClip-Inno-Migration/vm-transfer/vs-seeded-layout-probe.Tests.ps1
```

Exit 1: `RED: pinned OPC/control and installed engine comparison probe absent.`

After the initial comparison implementation, added the internal-manifest negative fixture **before** implementing manifest verification. Re-ran the same command: exit 1, `Manifest/raw member hash disagreement accepted.` The attacker fixture has a correctly pinned outer first-party ZIP but one incorrect declared DLL/EXE member SHA, so the failure tests the missing internal binding rather than only an outer hash guard.

Added the minimum internal manifest/member equality and locked JSON read. Re-ran the same command: exit 0:

```text
GREEN: manifest/member hashes, exact tree, changed/missing/extra DLL, unsafe/duplicate/case-colliding OPC names, wrong OPC pin, context guards, parser and readonly default.
```

Fixtures create only owned first-party temporary ZIP/files (fake EXE/DLL byte markers are never executed). They test exact tree acceptance; changed, missing and extra DLL rejection; unsafe/traversal/reserved/duplicate/case names; wrong outer OPC pin; manifest/member disagreement; context guards; PS5.1 parse; and actual read-only default. Cleanup checks the resolved absolute task-owned root stays under TEMP and matches its created GUID prefix before native PowerShell removal. An initial GREEN attempt exposed the need to explicitly load both OS System.IO.Compression assemblies on PS5.1; adding those references resolved it.

Also executed read-only exact original host source comparison, first verifying both first-party input pins:

```powershell
$verifier='D:/AutoClip-Inno-Migration/vm-transfer/vs-Test-Layout.ps1'
$inventory='D:/AutoClip-Inno-Migration/vm-transfer/vs-layout-expected-inventory.json'
if ((Get-FileHash -LiteralPath $verifier -Algorithm SHA256).Hash -ine 'fc7c45a56d5205c765ce7ff55aa1b3fcc92c24086c9eeaabbb8bd986854bc767' -or
    (Get-FileHash -LiteralPath $inventory -Algorithm SHA256).Hash -ine '545b140236b4765a964c14708dcbf1e6131497a58c1655be081631b4f8a91397') {throw 'Frozen comparer inputs changed.'}
& $verifier -LayoutPath D:/AutoClip-Inno-Migration/vs-layout-26100 -InventoryPath $inventory
```

Exit 0: matches true, expected_files=409, actual_files=409, differences empty. No vendor execution.

Finally AST-loaded the actual first-party functions without running operational `-MapInstalledEngine`, invoked `Get-SeedOpcInventory` on the exact host OPC with its fixed SHA, and checked all 868 raw members, total bytes, manifest hash/member equality and exact version-member hash. `Get-SeedPinnedJson` checked the known inventory on its locked handle. Output: `GREEN: actual pinned OPC 868 raw Contents/131469618 bytes match internal manifest, exact manifest SHA, exact version control member, locked pinned JSON inventory.` No installed host engine was mapped by this author.

## Frozen artifacts and evidence limits

- Probe SHA256: `da857185bccc68232592cd3bcc47d5da1ef30b648d16c9ef886aaa81b70898c1`.
- Fixture SHA256: `7999ce01fe04a71feb2abf615b2ed92c99207bbc44b4b9dc0e7ae93e719114da`.

The independent investigator reported a separate **host-only** installed comparison: all 868 names present, but only 686 raw hashes matching, 182 differing (6 EXEs, 175 DLLs, one TXT) despite the same claimed engine version. This report does not treat that as guest evidence. The new probe requires complete raw equality and preserves actual guest differences rather than weakening the selector to match a version claim.

Parent must inspect/run the frozen probe and retain the actual guest receipt before any engine/layout action. No guest mapping, seed copy, generated response, vendor engine update, layout generation, native product installation, certificate import or network acquisition was performed here. No whole wizard, legal, publication or production qualification is asserted.
