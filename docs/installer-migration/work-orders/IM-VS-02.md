# IM-VS-02: exact Build Tools / SDK recipient route investigation

Status: bounded investigation complete; production route remains unqualified.
Only this report was changed. No installer, manifest, prerequisite, certificate
store or VM was modified. No terms were accepted. No installer was executed.
Parent owns integration and guest qualification. User-confirmed noncommercial
use and VS use rights are acknowledged separately from recipient agreement.

The smallest documented route is a recipient-created local Microsoft layout,
selected by the two explicit components already present in the audited layout,
followed by interactive native installation from that layout. No broad workload,
recommended-components expansion, AutoClip mirror or bundled Microsoft payload
is needed for this route. Exact engine behavior during initial interactive
installation remains unresolved; the available verification log cannot prove it.

## Governing sources

- Repository `docs/runtime-update-architecture.md:200-208` requires versioned
  terms presentation, affirmative receipt, and native Microsoft Build Tools/VC
  agreement UI. Lines 203–206 explicitly retain that UI. This is a repository
  policy, not an independently established Microsoft prohibition on passive
  installation. It was preserved during this investigation.
- `docs/installer-migration/contract-v1.md` requires direct allowed acquisition,
  exact identity/pins, checks immediately before execution, serialized vendor
  installers, installed capability verification and pending reboot handling.
- [Microsoft fixed release history](https://learn.microsoft.com/en-us/visualstudio/releases/2022/release-history)
  lists Build Tools 17.14.41, September 15, 2026, build 17.14.37710.0.
- [Microsoft layout creation](https://learn.microsoft.com/en-us/visualstudio/install/create-a-network-installation-of-visual-studio?view=vs-2022)
  supports a fixed-version bootstrapper and selected components. Layout paths
  must be shorter than 80 characters; creation requires network/admin access.
- [Microsoft local layout installation](https://learn.microsoft.com/en-us/visualstudio/install/create-an-offline-installation-of-visual-studio?view=vs-2022)
  uses the same selected components and `--noWeb`. Retain the layout at its
  recorded path for future repairs/updates.
- [Microsoft command parameters](https://learn.microsoft.com/en-us/visualstudio/install/use-command-line-parameters-to-install-visual-studio?view=vs-2022)
  define the flags and restrictions below.
- [Microsoft response files](https://learn.microsoft.com/en-us/visualstudio/install/automated-installation-with-response-file?view=vs-2022)
  states command-line values override response defaults except merged multi-value
  inputs; interactive users may change selected components.
- [Microsoft client deployment](https://learn.microsoft.com/en-us/visualstudio/install/deploy-a-layout-onto-a-client-machine?view=vs-2022)
  defines exit codes and says `--noWeb` fails when selected components are absent.
- [Microsoft initial installation UI](https://learn.microsoft.com/en-us/visualstudio/install/install-visual-studio?view=vs-2022)
  documents license/privacy acknowledgment through the native Continue button.

## Local inventory and resolved identities

Read-only audit rechecked `D:\AutoClip-Inno-Migration\vs-layout-26100`:
409 files, 1,367,089,194 bytes. Of these, 397 files totaling 1,289,700,306
bytes match SHA-256 payload entries in the exact local Catalog.json. All matching
payload URLs use `download.visualstudio.microsoft.com`. Those matches cover
156 distinct catalog package IDs; duplicate hash associations explain 432
matching URL records. The complete catalog includes unselected components and
other hosts; this audit does not approve those unrelated catalog entries.

The remaining 12 files are catalog/channel/layout/response/template control
files, two identical Build Tools bootstrapper copies, the installer OPC/version
file, and three certificate files. They require separate pin/provenance handling.

| Input / resolved component | Identity |
| --- | --- |
| Product and channel | Build Tools 17.14.41; 17.14.37710.0; VisualStudio.17.Release |
| VC component | Microsoft.VisualStudio.Component.VC.Tools.x86.x64, 17.14.36510.44 |
| Actual x64 compiler package | Microsoft.VC.14.44.17.14.Tools.HostX64.TargetX64.base, 14.44.35229 |
| SDK component | Microsoft.VisualStudio.Component.Windows11SDK.26100, 17.14.37011.9 |
| SDK wrapper package | Win11SDK_10.0.26100, 10.0.26100.15; 229 payload records |
| SDK EULA MSI ProductVersion | 10.1.26100.7705; distinct from wrapper/catalog versions |
| Installer OPC metadata | version 4.10.30.302448642; installerVersion 4.10.30.62513 |
| Channel bootstrapper metadata | version 3.14.2094.286130193; installerVersion 3.14.2094.42856 |

The audited Layout.json / Response.json selects only the VC tools component,
SDK 26100, and en-US. It does not select `Microsoft.VisualStudio.Workload.VCTools`.
Current preflight/source-builder detection uses the VC tools component, so that
minimal selection agrees with detection. Existing broad provisioning uses the
workload plus `--includeRecommended`; do not transplant that larger selection
into this partial layout without regenerating/qualifying its closure.

## Pins and official acquisition endpoints

| File | Bytes | SHA-256 |
| --- | ---: | --- |
| vs_BuildTools-17.14.41.exe / identical local vs_setup.exe | 4,473,792 each | 37bb0fb429d163ecebd272a865d11a37b906d152bef960da2ddb29c2e2fd6eeb |
| Catalog.json | 17,954,732 | f0a50ea157222c29abd5ea6ff01bfc3c33b04e011c5e45ee2ca38ef0778e5643 |
| ChannelManifest.json | 91,781 | fca418ba94ffbcfb7a2b25f10f16f39dd09660568d21eef4bd3f274cb0b27b8c |
| Layout.json / identical Response.json | 372 each | 05e563d29311a3537a0132e6c99925677e9ef1fbc1dbc6eaf4223d4fc50803d9 |
| Response.template.json | 26,333 | 6e016c4e259f739f2e65a68f2ffa80a1d85179d41e82e83e0bd9830eb1940639 |
| vs_installer.opc | 50,363,030 | 62f68d0d6e2adce5cd65f549cbda234358c1cbda442af4de1c3f7ae43fb8b5a6 |
| vs_installer.version.json | 121 | e78a1053a6d59ad60ba8105623181b013c0ffc452216caada2699046f191974f |
| certificates/manifestRootCertificate.cer | 1,521 | 847df6a78497943f27fc72eb93f9a637320a02b561d0a91b09e87a7807ed7c61 |
| certificates/manifestCounterSignRootCertificate.cer / vs_installer_opc.RootCertificate.cer | 1,521 each | df545bf919a2439c36983b54cdfc903dfa4f37d3996d8d84b4c31eec6f3c163e |

Bootstrapper official endpoint (manifest and Microsoft release history):

`https://download.visualstudio.microsoft.com/download/pr/bc92e2cb-33de-4a0c-995d-efa817f16b16/37bb0fb429d163ecebd272a865d11a37b906d152bef960da2ddb29c2e2fd6eeb/vs_BuildTools.exe`

Installer engine official endpoint, resolved in the historical Microsoft
bootstrapper log and checked with a fresh HEAD returning 200 / 50,363,030 bytes:

`https://download.visualstudio.microsoft.com/download/pr/e5f740e0-92f9-49d7-ab3b-5d17b84108fd/62F68D0D6E2ADCE5CD65F549CBDA234358C1CBDA442AF4DE1C3F7AE43FB8B5A6/vs_installer.opc`

Example exact compiler payload from catalog:

`https://download.visualstudio.microsoft.com/download/pr/aa209763-134c-427b-9960-9ca54ccc1734/f4ad3cee4ef18e9f36382399261de27be6910ab3467178d7e687377ec841306d/Microsoft.VC.14.44.17.14.Tools.HostX64.TargetX64.base.vsix`

26,662,704 bytes; SHA-256
`f4ad3cee4ef18e9f36382399261de27be6910ab3467178d7e687377ec841306d`.

SDK wrapper official endpoint:

`https://download.visualstudio.microsoft.com/download/pr/6452c1f1-dc1e-413c-8b19-991b61870a8b/a10fcd81bdecc2d766f6cd044d8eb027/winsdksetup.exe`

1,451,232 bytes; SHA-256
`6fa0fa27db77a909f5ecb35183cb26a969a6775936780936fe239e4f9c66b458`.
Nested CAB/MSI/VSIX inputs have individual official URLs/sizes/SHA-256 values
in the pinned catalog; no standalone SDK latest redirect is necessary.

### Catalog pin conflict

The ChannelManifest's VisualStudio.vsman entry declares 30,443,537 bytes,
SHA-256 `6e470016e4324c84c255ffd0beb3767d17ec89cc8561e9409ee3e1f6d29400f5`,
at this exact official URL:

`https://download.visualstudio.microsoft.com/download/pr/bc92e2cb-33de-4a0c-995d-efa817f16b16/6e470016e4324c84c255ffd0beb3767d17ec89cc8561e9409ee3e1f6d29400f5/VisualStudio.vsman`

Fresh GET with `Accept-Encoding: identity` returned 17,954,732 bytes, SHA-256
`f0a50ea157222c29abd5ea6ff01bfc3c33b04e011c5e45ee2ca38ef0778e5643`,
exactly local Catalog.json. Response has no Content-Encoding and identifies
17.14.41. Thus Catalog.json can be acquired directly as these observed bytes,
but its channel-declared size/hash do not match. This is a source-of-truth
conflict requiring explicit resolution/evidence before automated promotion;
do not silently rewrite either pin or claim channel payload verification.

## Supported commands and unresolved initial-install behavior

The exact historical layout creation arguments were:

```text
D:\AutoClip-Inno-Migration\vs_BuildTools-17.14.41.exe --layout D:\AutoClip-Inno-Migration\vs-layout-26100 --add Microsoft.VisualStudio.Component.VC.Tools.x86.x64 --add Microsoft.VisualStudio.Component.Windows11SDK.26100 --lang en-US --wait
```

This investigation did not rerun them. Historical bootstrapper log
`%TEMP%\dd_bootstrapper_20261001112202.log` shows a latestinstaller.json feed
lookup and mutable `https://aka.ms/vs/install/latest/installer`, resolving to
the exact pinned OPC above. A fixed product bootstrapper alone therefore does
not freeze its installer engine.

The subsequent historical verify used:

```text
D:\AutoClip-Inno-Migration\vs-layout-26100\vs_BuildTools-17.14.41.exe --layout D:\AutoClip-Inno-Migration\vs-layout-26100 --verify --wait
```

`dd_bootstrapper_20261001112631.log` records local OPC signature verification,
use of that offline OPC, and exit 0. `dd_setup_20261001112639.log` records
verification complete without problems; paired errors file is empty.
These prove the historical layout-verification path used the exact local
engine. They do not prove first interactive client installation follows the
same path on a clean or already provisioned machine.

Candidate interactive guest qualification command, not executed here:

```text
"C:\AutoClipCache\vs-17.14.41\vs_BuildTools-17.14.41.exe" --noWeb --wait --channelUri "C:\AutoClipCache\vs-17.14.41\ChannelManifest.json" --installChannelUri "C:\AutoClipCache\vs-17.14.41\ChannelManifest.json" --installCatalogUri "C:\AutoClipCache\vs-17.14.41\Catalog.json" --channelId VisualStudio.17.Release --productId Microsoft.VisualStudio.Product.BuildTools --add Microsoft.VisualStudio.Component.VC.Tools.x86.x64 --add Microsoft.VisualStudio.Component.Windows11SDK.26100 --addProductLang en-US
```

| Flag | Documented constraint |
| --- | --- |
| --wait | Bootstrapper only; also wait for its process and capture exit |
| --noWeb | Prevents product package downloads; does not itself stop installer update checks |
| --channelUri | Update source; use pinned local channel instead of current aka.ms default |
| --installChannelUri | Install channel; requires channelUri alongside it |
| --installCatalogUri | Install catalog; applies to install, ignored for other verbs |
| --noUpdateInstaller | Documented prevention guarantee is with quiet; failure if required update cannot occur |
| --norestart | Supported with passive or quiet; cannot claim it as supported interactive suppression |

Local channel/catalog flags select exact product metadata and remove the
mutable product update source. The channel contains an older 3.14 setup
bootstrapper reference, whereas the actual layout carries installer 4.10.
Neither catalog nor channel has a vs_installer.opc pin. No inspected official
source establishes that these product flags suppress all engine self-update
on an internet-connected first interactive install. Do not present network
isolation as a production route or infer a guarantee from the verify log.

[Microsoft's offline update example](https://learn.microsoft.com/en-us/visualstudio/install/update-a-network-installation-of-visual-studio?view=vs-2022)
uses `--quiet --update --wait --offline` for the engine, then a separate
product update. It is evidence for that documented update workflow; it does
not establish a full interactive first-install guarantee here.

[Microsoft's interactive update UI](https://learn.microsoft.com/en-us/visualstudio/install/update-visual-studio?view=vs-2022)
describes a restart prompt. It supports expecting a user decision in that UI,
but does not prove the exact clean Build Tools/SDK initial installation cannot
restart unexpectedly. Qualification must observe this path, decline/postpone
Restart, retain 3010 as pending, and reject 1641 as unexpected initiated reboot.
0 is only a process result: recheck exact installed toolset, SDK headers/libs,
and an x64 compile/link before considering the prerequisite capable.

## Terms and direct recipient feasibility

Both exact catalog and channel Build Tools en-US rows name
`https://go.microsoft.com/fwlink/?LinkId=2179911`. It resolves to
[Microsoft's Build Tools terms page](https://visualstudio.microsoft.com/license-terms/vs2022-ga-diagnosticbuildtools/).
The linked [March 2024 DOCX](https://visualstudio.microsoft.com/wp-content/uploads/2024/03/Visual-Studio-2022-Diagnostic-Build-Tools-Agent-License_Update-March-2024_EN.docx)
was fetched into memory: 34,395 bytes, SHA-256
`2f66b86a00e8d9833789897ce23d05a4a2dbea370cf39c8c1098dbc17d0e7bdc`,
matching the repository's build-tools terms reference. It names Visual Studio
2022 debuggers, agents and Build Tools. No inspected wording requires an
interactive click specifically; that does not waive the repository UI policy
or independently establish equivalence to all exact nested SDK terms.

The local SDK EULA MSI is 450,560 bytes, SHA-256
`f3958c26326c6aeb29cb91a62e8e7f2f4347b8847313d6a8041567b12d493bb6`.
Its File table, opened read-only, names `sdk_license.rtf` (248,573 bytes) and
`sdk_third_party_notices.rtf` (22,279 bytes). Their text was not extracted or
asserted equivalent to another snapshot. Native UI remains the agreement route.

The vendor-created recipient layout route can avoid AutoClip mirroring: obtain
the fixed signed bootstrapper and exact OPC/payload bytes directly from the
official URLs, then generate vendor control files locally. All 397 product
payloads have exact Microsoft catalog routes, and OPC has the resolved official
route above. No Microsoft-hosted complete 409-file layout archive was identified.
Do not label an AutoClip-hosted copy or prepopulated shared cache as direct
recipient acquisition. Regeneration must reproduce the expected inventory and
resolve the catalog pin conflict and engine behavior before approval.

[Microsoft offline certificate guidance](https://learn.microsoft.com/en-us/visualstudio/install/install-certificates-for-visual-studio-offline?view=vs-2022)
requires trusted signature chains and explains that layouts carry certificate
files. This investigation did not import them. Any missing trust or shared
installer collision must fail for explicit resolution; AutoClip must not silently
change trust stores or claim rollback ownership of VS/SDK/shared prerequisites.

## Read-only checks and next evidence

Performed: control/bootstrapper SHA-256 and Authenticode inspection; JSON
identity/dependency inspection; every local file hashed and compared to exact
catalog payload hashes; read-only OPC ZIP metadata; existing Microsoft creation
and verify logs; SDK MSI OpenDatabase mode 0 File/Property queries; official
HEAD/GET and terms hash comparison; Microsoft documentation review.
No tests or RED/GREEN are claimed for this documentation-only investigation.

Root's next evidence decision is the exact interactive initial-install engine
route: observe process/images/logs and network requests for the pinned local
channel/catalog/OPC path on the guest, without clicking agreements or restart
without specific recipient authorization. Resolve the channel/catalog pin
disagreement independently. Keep VS and SDK classification BLOCKED until these
technical, agreement and installed-capability checks qualify the route.
