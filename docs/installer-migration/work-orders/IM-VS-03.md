# IM-VS-03: Build Tools 17.14.41 metadata and engine pin follow-up

Status: read-only investigation complete; exact recipient installation route
remains unqualified. This is an implementation collaborator's technical report,
not a blind review, legal approval, or permission to accept vendor agreements.
Only this report was added. No installer, layout creation, product installation,
certificate import, agreement acceptance, or host/guest change was performed.

## Governing boundary

`AGENTS.md`, `skills/runtime-updater/SKILL.md`,
`docs/runtime-update-architecture.md:188-208`, and
`docs/installer-migration/contract-v1.md` require exact pinned inputs, recipient
consent, native Microsoft agreement UI, post-install capability checks, and no
unreviewed runtime promotion. [IM-VS-02](IM-VS-02.md) records the minimal
Build Tools/SDK layout, exact component selection, layout inventory, and prior
verification logs. Its 409-file local layout is investigation evidence, not a
distributable AutoClip asset or a qualified clean-machine installation.

## Exact channel/catalog discrepancy

On 2026-10-01, the local files in
`D:\AutoClip-Inno-Migration\vs-layout-26100` still hashed as follows:

| File | Bytes | SHA-256 |
| --- | ---: | --- |
| `ChannelManifest.json` | 91,781 | `fca418ba94ffbcfb7a2b25f10f16f39dd09660568d21eef4bd3f274cb0b27b8c` |
| `Catalog.json` | 17,954,732 | `f0a50ea157222c29abd5ea6ff01bfc3c33b04e011c5e45ee2ca38ef0778e5643` |
| `Layout.json` and identical `Response.json` | 372 each | `05e563d29311a3537a0132e6c99925677e9ef1fbc1dbc6eaf4223d4fc50803d9` |
| `vs_installer.opc` | 50,363,030 | `62f68d0d6e2adce5cd65f549cbda234358c1cbda442af4de1c3f7ae43fb8b5a6` |
| `vs_BuildTools-17.14.41.exe` | 4,473,792 | `37bb0fb429d163ecebd272a865d11a37b906d152bef960da2ddb29c2e2fd6eeb` |

The local channel's `Microsoft.VisualStudio.Manifests.VisualStudio`
payload entry names `VisualStudio.vsman`, size **30,443,537**, SHA-256
`6e470016e4324c84c255ffd0beb3767d17ec89cc8561e9409ee3e1f6d29400f5`,
at this exact Microsoft URL:

`https://download.visualstudio.microsoft.com/download/pr/bc92e2cb-33de-4a0c-995d-efa817f16b16/6e470016e4324c84c255ffd0beb3767d17ec89cc8561e9409ee3e1f6d29400f5/VisualStudio.vsman`

I streamed the **raw HTTP body** of that URL into SHA-256 without saving or
decompressing it. One GET used `Accept-Encoding: identity`; a second used
`Accept-Encoding: gzip`, `Cache-Control: no-cache`, and `Pragma: no-cache`.
Both returned HTTP 200, the same URL, **17,954,732 bytes**, and SHA-256
`f0a50ea157222c29abd5ea6ff01bfc3c33b04e011c5e45ee2ca38ef0778e5643`,
exactly matching local `Catalog.json`. Both responses advertised
`Content-Length: 17954732`, no `Content-Encoding` or `Vary`, the same ETag
`"0xB9BB9F38B9E5BB399742E1ECD63A7B4C2729479C5B4EF8BD7494D42F62B7AA0F"`,
and `Last-Modified: Thu, 10 Sep 2026 23:59:43 GMT`. The body begins with
plain JSON. The channel and returned catalog both identify Build Tools
**17.14.41 / build 17.14.37710.0**.

**Established:** The mismatch is in the official channel's declared
size/hash versus the bytes now served at its own URL. It is not an HTTP gzip
transfer or local `Catalog.json` corruption. **Not established:** why the
publisher's metadata and response disagree, whether the URL was changed after
publication, or whether an alternative official endpoint still serves the
declared `6e470...` bytes. The historical Microsoft `--verify` success in
IM-VS-02 proves that the vendor accepted that local layout on that verification
path; it does not make the two SHA-256 values equal or qualify installation.
Do not silently substitute one value for the other or claim the channel's
declared payload pin was checked successfully.

## Smallest vendor-supported candidate route

1. After the recipient sees the exact publisher, component, elevation, size,
   reboot and applicable terms summary, obtain the fixed 17.14.41 Build Tools
   bootstrapper directly from Microsoft's URL and verify its exact size/hash.
   The [Microsoft release history](https://learn.microsoft.com/en-us/visualstudio/releases/2022/release-history)
   identifies this fixed version and build. Its signature is an additional
   identity check, not agreement acceptance or proof of nested payloads.
2. Have the recipient's Microsoft bootstrapper create a **local** minimal
   layout using only `Microsoft.VisualStudio.Component.VC.Tools.x86.x64`,
   `Microsoft.VisualStudio.Component.Windows11SDK.26100`, and `en-US`, as in
   IM-VS-02. This is the [documented layout creation route](https://learn.microsoft.com/en-us/visualstudio/install/create-a-network-installation-of-visual-studio?view=vs-2022).
   Do not distribute the layout or copy an AutoClip-populated Microsoft cache.
   Verify the resulting local control files, OPC, and every selected payload
   against an independently recorded exact inventory; reject any mismatch,
   including a changed engine. Then use Microsoft's `--verify`. Retain the
   versioned layout path, because [local layout installs retain that path for
   future servicing](https://learn.microsoft.com/en-us/visualstudio/install/create-an-offline-installation-of-visual-studio?view=vs-2022).
3. The proposed native **interactive** installation uses the verified local
   bootstrapper/layout, explicit local `--channelUri`, `--installChannelUri`,
   and `--installCatalogUri`, exact component IDs, and `--noWeb`. It must leave
   Microsoft's agreement UI to the recipient. The actual layout's
   `Layout.json` and `Response.json` contain a mutable `aka.ms` update channel;
   never rely on that default. [Microsoft's parameter reference](https://learn.microsoft.com/en-us/visualstudio/install/use-command-line-parameters-to-install-visual-studio?view=vs-2022)
   documents the local catalog/channel flags and says `--noWeb` prevents product
   package downloads, **not** all installer update checks.
4. Interpret cancellation, UAC denial, failure and reboot-required results
   separately. Process exit 0 is insufficient: verify exact VC Tools and SDK
   installation with `vswhere`, SDK headers/libs, `cl.exe /Bv`, and an x64
   compile/link before AutoClip can consider the prerequisite capable.

The independently observed `f0a50...` catalog hash can serve as an **explicit
candidate direct-download pin** for that exact response, with the channel's
contradictory declaration recorded and a fail-closed download check. It cannot
be represented as fulfillment of the channel's `6e470...` pin. A vendor-created
layout and independent inventory check avoid hand-assembling 409 files, but
neither automatically resolves the metadata conflict.

## Installer engine control remains the specific blocker

The local channel's setup bootstrapper metadata names installer **3.14**;
the inspected local `vs_installer.opc` and `vs_installer.version.json` name
**4.10.30.62513** / **4.10.30.302448642**. IM-VS-02's layout creation log
shows a lookup of `latestinstaller.json` and `aka.ms/vs/install/latest/installer`
before it obtained the exact local OPC. A fixed product bootstrapper therefore
did not itself freeze the engine during that run.

[Microsoft's offline update example](https://learn.microsoft.com/en-us/visualstudio/install/update-a-network-installation-of-visual-studio?view=vs-2022)
supports a separate `--quiet --update --wait --offline` engine update from a
local layout/OPC before product installation. This could prepare the pinned
engine after the recipient authorizes the vendor prerequisite, but it is a
machine-changing step and **was not executed here**. More importantly, that
documented update does not guarantee that a subsequent **interactive first
install** will refrain from checking or replacing the engine. Microsoft's
[parameter reference](https://learn.microsoft.com/en-us/visualstudio/install/use-command-line-parameters-to-install-visual-studio?view=vs-2022)
limits `--noUpdateInstaller`'s prevention guarantee to `--quiet`, which would
suppress the repository-required native agreement UI. `--noWeb` does not close
that gap. Network disconnection or a local file named `latest` is not a
documented pin for an internet-connected production installation.

### Bounded offline native-UI experiment

The [Microsoft local installation guide](https://learn.microsoft.com/en-us/visualstudio/install/create-an-offline-installation-of-visual-studio?view=vs-2022)
supports preparing the packages first, then disconnecting before installation;
its local-layout example uses `--noWeb`. A clean test guest can therefore
create its own exact layout from Microsoft's endpoints while connected, pass
the independent 409-file/control/OPC inventory and vendor `--verify`, then
**disconnect the guest network before launching the native interactive UI**.
The guest's recipient must make the terms and restart decisions. A proposed
first-install command, not executed here, is:

```text
"C:\AutoClipCache\vs-17.14.41\vs_BuildTools-17.14.41.exe" --noWeb --wait --channelUri "C:\AutoClipCache\vs-17.14.41\ChannelManifest.json" --installChannelUri "C:\AutoClipCache\vs-17.14.41\ChannelManifest.json" --installCatalogUri "C:\AutoClipCache\vs-17.14.41\Catalog.json" --channelId VisualStudio.17.Release --productId Microsoft.VisualStudio.Product.BuildTools --add Microsoft.VisualStudio.Component.VC.Tools.x86.x64 --add Microsoft.VisualStudio.Component.Windows11SDK.26100 --addProductLang en-US
```

Physical network isolation would prevent a **remote** installer self-update
during that run while preserving native agreement UI. Inspect the engine
version and executable hash before and after, local OPC use, every process
image and attempted network destination, exact installed product/components,
and the vendor logs. If the installer cannot proceed without contacting a
remote update feed, it fails the offline experiment; do not re-enable the
network to complete that candidate. If certificates or revocation cannot be
validated, follow [Microsoft's offline certificate guidance](https://learn.microsoft.com/en-us/visualstudio/install/install-certificates-for-visual-studio-offline?view=vs-2022)
and stop for a separately approved trust decision; do not bypass signatures
or silently alter the machine trust store. A preexisting shared installer or
cache could affect the result, so capture its state before the run and prefer
a clean guest. The layout must remain at its installed-path location for
future repair.

This experiment could qualify an **offline candidate** if its exact bytes,
native interaction, installed capabilities and failure behavior pass. It
would not prove that a normal internet-connected first install pins the
engine; that needs an official supported control or separate fail-closed
evidence. The channel/catalog contradiction remains recorded unchanged even
if the offline run succeeds. No guest operation may start until the recipient
has made any required terms decision.

**Disposition:** VS Build Tools and SDK remain `BLOCKED` for automated
clean-machine installation. The bounded offline guest experiment above is
the smallest next technical check after a recipient terms decision. If the
engine changes, an unpinned local input is used, or the catalog conflict
prevents reliable vendor validation, require a supported Microsoft
correction/control or a newly reviewed exact payload route. Guest observation
can establish what happened on that candidate; it is not a general engine
pin or approval for internet-connected installation.

Read-only checks performed: local SHA-256/JSON inspection, two raw official
GETs with response-header comparison, and primary Microsoft documentation
review. No install, RED/GREEN test, clean-machine result, vendor agreement,
legal determination, or independent review is claimed.
