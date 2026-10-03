# IM-VS-05 — direct guest layout preparation

Status: preparation complete; Microsoft route remains **BLOCKED / diagnostic**.
User authorization for Python 3.11.9 and native Microsoft Build Tools 17.14.41 /
VC Runtime agreement acceptance applies only to parent-run VM tests. This report
does not authorize publication, resolve vendor metadata conflicts, or qualify
connected installation. No vendor installer, guest, firewall, certificate store,
or antivirus setting was changed by this worker.

## Scope and governing evidence

Read `AGENTS.md`, `skills/runtime-updater/SKILL.md`,
`docs/runtime-update-architecture.md`, migration contract v1, and IM-VS-02/03/04.
Used Ponytail Full: retain Microsoft's layout mechanism and add only a first-party
inventory plus a read-only comparator. No canonical manifest/source was changed.
Only this report was added in the repository. Preparation artifacts live under
`D:\AutoClip-Inno-Migration\vs-guest-preparation`; they contain metadata, code,
and small first-party test strings, with no vendor payload copies.

## Current host baseline and official download map

Rehashed every regular file in `D:\AutoClip-Inno-Migration\vs-layout-26100`:
**409 files, 1,367,089,194 bytes**. `layout-inventory.json` contains every exact
relative layout path, observed bytes, SHA-256, and all matching catalog package /
version / filename / declared size / official URL associations. The 397 payload
files total **1,289,700,306 bytes**, match catalog SHA-256 values, and map to
**397 unique URLs / 432 package associations**. All URLs passed HTTPS, port 443,
no credentials/fragment, and exact `download.visualstudio.microsoft.com` host
checks. These are discovered inputs, not new approved production classifications.

**Additional discrepancy:** 140 files (140 associations) have a catalog-declared
size different from their actual hash-matching bytes. For example,
`Microsoft.Build.vsix` declares 14,058,953 bytes but the corresponding local
`payload.vsix` is 15,215,102 bytes, SHA-256
`dd60a169e94ae9a682ac1a83c2785588392114ac65164eb5605acd89ee7f2426`.
An official HEAD request on 2026-10-01 returned HTTP 200 / Content-Length
15,215,102 at that exact URL. The inventory retains both values; do not use
`catalog_sources.bytes` as if it were verified downloaded length. A diagnostic
direct-download manifest must deliberately use the baseline row's observed
`bytes` and `sha256`, retain the conflicting declaration, and remain unqualified.
No cause for these size differences was established.

Known control acquisition pins (full URLs below):

| File | Observed bytes | SHA-256 | Origin / preparation |
| --- | ---: | --- | --- |
| `vs_BuildTools-17.14.41.exe`, identical `vs_setup.exe` | 4,473,792 each | `37bb0fb429d163ecebd272a865d11a37b906d152bef960da2ddb29c2e2fd6eeb` | Fixed official bootstrapper; guest can acquire same URL for both paths |
| `Catalog.json` | 17,954,732 | `f0a50ea157222c29abd5ea6ff01bfc3c33b04e011c5e45ee2ca38ef0778e5643` | Observed official response; channel-declared pin conflicts |
| `ChannelManifest.json` | 91,781 | `fca418ba94ffbcfb7a2b25f10f16f39dd09660568d21eef4bd3f274cb0b27b8c` | Vendor layout output; independently pinned public URL not established |
| `vs_installer.opc` | 50,363,030 | `62f68d0d6e2adce5cd65f549cbda234358c1cbda442af4de1c3f7ae43fb8b5a6` | Official URL from historical bootstrap log; current HEAD agrees on size |
| `Layout.json`, identical `Response.json` | 372 each | `05e563d29311a3537a0132e6c99925677e9ef1fbc1dbc6eaf4223d4fc50803d9` | Generated configuration; first-party may recreate selection semantics |
| `Response.template.json` | 26,333 | `6e016c4e259f739f2e65a68f2ffa80a1d85179d41e82e83e0bd9830eb1940639` | Vendor template; direct public URL not established |
| `vs_installer.version.json` | 121 | `e78a1053a6d59ad60ba8105623181b013c0ffc452216caada2699046f191974f` | Vendor engine metadata output; not a selection configuration |
| `certificates/manifestRootCertificate.cer` | 1,521 | `847df6a78497943f27fc72eb93f9a637320a02b561d0a91b09e87a7807ed7c61` | Vendor certificate bytes; direct endpoint not established |
| `certificates/manifestCounterSignRootCertificate.cer`, `certificates/vs_installer_opc.RootCertificate.cer` | 1,521 each | `df545bf919a2439c36983b54cdfc903dfa4f37d3996d8d84b4c31eec6f3c163e` | Vendor certificate bytes; direct endpoint not established |

Bootstrap URL:
`https://download.visualstudio.microsoft.com/download/pr/bc92e2cb-33de-4a0c-995d-efa817f16b16/37bb0fb429d163ecebd272a865d11a37b906d152bef960da2ddb29c2e2fd6eeb/vs_BuildTools.exe`

OPC URL:
`https://download.visualstudio.microsoft.com/download/pr/e5f740e0-92f9-49d7-ab3b-5d17b84108fd/62F68D0D6E2ADCE5CD65F549CBDA234358C1CBDA442AF4DE1C3F7AE43FB8B5A6/vs_installer.opc`

Catalog URL:
`https://download.visualstudio.microsoft.com/download/pr/bc92e2cb-33de-4a0c-995d-efa817f16b16/6e470016e4324c84c255ffd0beb3767d17ec89cc8561e9409ee3e1f6d29400f5/VisualStudio.vsman`

The ChannelManifest declares that Catalog URL as **30,443,537 bytes / SHA-256
`6e470016e4324c84c255ffd0beb3767d17ec89cc8561e9409ee3e1f6d29400f5`**.
Current HEAD returned 17,954,732 bytes; IM-VS-03's two raw GETs matched the
observed `f0a50...` baseline. The conflict is unchanged. Neither observed-byte
pinning nor a vendor `--verify` success fulfills the channel's declared pin.

The generated selection configuration has only BuildTools product, Release
channel, local install channel/catalog paths, `en-US`, and exactly
`Microsoft.VisualStudio.Component.VC.Tools.x86.x64` plus
`Microsoft.VisualStudio.Component.Windows11SDK.26100`. The configuration's
`channelUri` is mutable `https://aka.ms/vs/17/release/channel`. First-party
configuration can express these choices, but must not invent vendor templates,
certificate bytes, signed manifests, or engine metadata. Do not manually
reconstruct a supposedly supported 409-file layout from unexplained controls.

## Smallest supported guest route and required qualification

1. Parent transfers only the first-party preparation metadata/probe. Acquire
   bootstrapper directly in guest using protected downloader and the observed
   exact pin above. The host layout is never served, mirrored, or copied to guest.
2. A recipient-created Microsoft layout fills the controls and payloads using
   Microsoft's supported command. From an elevated guest PowerShell, after
   parent authorizes the diagnostic acquisition and records network behavior:

```powershell
& 'C:\AutoClipCache\vs_BuildTools-17.14.41.exe' --layout 'C:\AutoClipCache\vs-17.14.41' --add Microsoft.VisualStudio.Component.VC.Tools.x86.x64 --add Microsoft.VisualStudio.Component.Windows11SDK.26100 --lang en-US --wait
$LASTEXITCODE
```

This native acquisition is not protected by the AutoClip helper for every
vendor request. Historical creation contacted a `latestinstaller.json` URL and
mutable installer discovery before downloading engine 4.10.30.62513; fixed
product bootstrapper does not freeze the engine. Newly fetched bytes and host
transitions therefore require observation and exact comparison before any
offline install. Do not add `--includeRecommended`, broad workloads, `--fix`,
or silent product installation to this command.

3. Before installation, compare all 409 guest paths/bytes/hashes, including
   engine and controls, using transferred first-party inventory. Any missing,
   extra, mismatched, or reparse entry fails with exit 2. Independently run:

```powershell
& 'C:\AutoClipCache\vs-17.14.41\vs_BuildTools-17.14.41.exe' --layout 'C:\AutoClipCache\vs-17.14.41' --verify --wait
$LASTEXITCODE
powershell.exe -NoProfile -File 'C:\AutoClipCache\vs-preparation\Test-Layout.ps1' -LayoutPath 'C:\AutoClipCache\vs-17.14.41' -InventoryPath 'C:\AutoClipCache\vs-preparation\layout-inventory.json'
```

Microsoft documents `--verify` as checking missing/invalid layout files, needing
control metadata, and working only for the latest release of a minor version.
Fixed bootstrappers are described as almost deterministic. Record actual guest
logs and repeat the independent comparison after vendor verification. These
commands were not run on guest by this worker. Historical host verify evidence
in IM-VS-02 is not a new guest result.

4. Parent owns network disconnection and native interactive install after
   Python. Candidate fixed arguments retain native agreement UI:

```powershell
& 'C:\AutoClipCache\vs-17.14.41\vs_BuildTools-17.14.41.exe' --noWeb --wait --channelUri 'C:\AutoClipCache\disabled-update.chman' --installChannelUri 'C:\AutoClipCache\vs-17.14.41\ChannelManifest.json' --installCatalogUri 'C:\AutoClipCache\vs-17.14.41\Catalog.json' --channelId VisualStudio.17.Release --productId Microsoft.VisualStudio.Product.BuildTools --add Microsoft.VisualStudio.Component.VC.Tools.x86.x64 --add Microsoft.VisualStudio.Component.Windows11SDK.26100 --addProductLang en-US
$LASTEXITCODE
```

`disabled-update.chman` must not exist. Microsoft supports this for disabling
product update detection, but it is not an engine network containment proof.
`--noWeb` prevents product package downloads, not all installer update checks;
`--noUpdateInstaller` has documented protection when paired with `--quiet`,
which would suppress the required native UI. No interactive no-restart
guarantee is established. Parent must observe component selection, all native
terms, engine behavior, exit/reboot status, exact installed components, SDK
headers/libs, `cl.exe /Bv`, and an x64 compile/link. Missing trust must stop for
explicit resolution; this assignment does not import certificates or bypass
signature verification. Offline VM qualification cannot establish connected
production safety, vendor rights, or publication approval.

Sources inspected live: [Microsoft local layout workflow](https://learn.microsoft.com/en-us/visualstudio/install/create-an-offline-installation-of-visual-studio?view=vs-2022),
[command parameters](https://learn.microsoft.com/en-us/visualstudio/install/use-command-line-parameters-to-install-visual-studio?view=vs-2022),
and [network layout verification](https://learn.microsoft.com/en-us/visualstudio/install/create-a-network-installation-of-visual-studio?view=vs-2022).

## Executed checks and frozen first-party files

Inventory generation used PowerShell `Get-Content -Raw | ConvertFrom-Json`
against local Catalog, indexed all payloads by SHA-256, and enumerated
`Get-ChildItem -LiteralPath <host-layout> -File -Recurse | Sort-Object FullName`
with `Get-FileHash -Algorithm SHA256`, writing only metadata via
`ConvertTo-Json -Depth 7 | Set-Content -Encoding UTF8`.

Exact probe RED command (before implementation):

```powershell
& "$env:SystemRoot\System32\WindowsPowerShell\v1.0\powershell.exe" -NoProfile -File 'D:\AutoClip-Inno-Migration\vs-guest-preparation\Test-Layout.ps1' -LayoutPath 'D:\AutoClip-Inno-Migration\vs-layout-26100'
```

RED: script did not exist, exit -196608. This proves absent comparison tooling,
not a product regression. Initial implemented default inventory binding failed
with missing `\layout-inventory.json`; moving default resolution after `param`
fixed the actual PS5.1 entrypoint.

GREEN commands:

```powershell
& "$env:SystemRoot\System32\WindowsPowerShell\v1.0\powershell.exe" -NoProfile -File 'D:\AutoClip-Inno-Migration\vs-guest-preparation\Check-Probe.ps1'
& "$env:SystemRoot\System32\WindowsPowerShell\v1.0\powershell.exe" -NoProfile -File 'D:\AutoClip-Inno-Migration\vs-guest-preparation\Test-Layout.ps1' -LayoutPath 'D:\AutoClip-Inno-Migration\vs-layout-26100'
```

GREEN: five real first-party fixture checks passed (exact bytes, same-size
corruption, extra file, missing file, traversal inventory); host comparison
reported `matches:true`, expected_files409, actual_files409, no differences,
exit0. No native vendor execution is part of either script. Fixtures retained
under `fixture-*` contain only our strings, not vendor files.

Three native .NET `HttpWebRequest` HEAD probes used `AllowAutoRedirect=false`,
method HEAD, timeout30,000ms, and normal certificate checks; results saved as
`official-head-evidence.json`. Microsoft.Build, Catalog and OPC each returned
HTTP200, no Location header, and respective observed lengths15,215,102 /
17,954,732 / 50,363,030. No bodies downloaded; the other396 payload URLs were
not network-probed in this slice. The Catalog and OPC probes are control files.

| Preparation file | SHA-256 |
| --- | --- |
| `layout-inventory.json` | `545b140236b4765a964c14708dcbf1e6131497a58c1655be081631b4f8a91397` |
| `Test-Layout.ps1` | `fc7c45a56d5205c765ce7ff55aa1b3fcc92c24086c9eeaabbb8bd986854bc767` |
| `Check-Probe.ps1` | `e123a631e9c7bfb62d60dc90231825c4253260a3613f36f6971670989569a0d7` |

Remaining decisions: guest native acquisition under diagnostic authorization,
containment observation and offline execution by parent; rejection/disposition
of engine or inventory drift; vendor explanation or explicit diagnostic
disposition of catalog pin and payload size contradictions; actual native UI /
installed capability evidence. Public route stays blocked throughout this
preparation. No legal, blind technical, or publication gate was satisfied here.
