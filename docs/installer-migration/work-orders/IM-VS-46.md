# IM-VS-46: direct Build Tools installation route

## Decision and scope

This is a read-only route recommendation. No vendor binary, VM, host installer,
download, agreement, or production source was run or changed here. The current
Microsoft rows remain `BLOCKED`; this report does not qualify the wizard.

The shortest next product experiment is the **already installed, exact checked
Microsoft installer engine** on the prepared recipient VM, using its supported
default install command. The fixed 17.14.41 bootstrapper is the fallback
candidate for an engine-absent recipient, not the first product experiment:
VS40 showed that a bootstrapper can acquire and execute a temporary engine
through a mutable latest alias even when the product bootstrapper itself is
pinned (`IM-VS-40.md:66-87`). An extra layout-generation operation is not
required for the direct route (`contract-v1.md:414-429`).

The current VM engine is a **warm input**, not a fresh-recipient production
qualification. VS29 compared all 868 installed files with authenticated OPC
members, without missing, extra or changed members; its outer process failed
while observing terminal state, so the original native exit remains unknown
(`IM-VS-29.md`, full primary SHA-256
`c58388acef285d67e383127d2a9d352f850f6248f12894f34ef7e5cc1f770c21`).
Recheck the exact installed image/868 closure immediately before the product
action and again after it. Do not promote that warm observation into a claim
about installing the engine on a fresh recipient.

## Supported command boundary

[Microsoft's CLI reference](https://learn.microsoft.com/en-us/visualstudio/install/use-command-line-parameters-to-install-visual-studio?view=vs-2022)
allows programmatic product installation through the installed
`C:\Program Files (x86)\Microsoft Visual Studio\Installer\setup.exe`, started
with a working directory outside its own directory. The blank command is
install; repeat `--add` for each component. `--installChannelUri` and
`--installCatalogUri` apply to install, while `--channelUri` must accompany
`--installChannelUri` and governs the future update source. `--quiet` enables
`--noUpdateInstaller`'s documented fail-with-nonzero behavior when an installer
update is required. `--norestart` is supported with quiet. `--wait` is for the
bootstrapper only and must **not** be passed to installed `setup.exe`.

The bounded candidate arguments for that exact installed engine are:

```text
--productId Microsoft.VisualStudio.Product.BuildTools
--channelId VisualStudio.17.Release
--installPath "C:\Program Files (x86)\Microsoft Visual Studio\2022\BuildTools"
--channelUri "C:\ProgramData\ac-layout-f175f729\layout\ChannelManifest.json"
--installChannelUri "C:\ProgramData\ac-layout-f175f729\layout\ChannelManifest.json"
--installCatalogUri "C:\ProgramData\ac-layout-f175f729\layout\Catalog.json"
--add Microsoft.VisualStudio.Component.VC.Tools.x86.x64
--add Microsoft.VisualStudio.Component.Windows11SDK.26100
--addProductLang en-US
--downloadThenInstall --quiet --noUpdateInstaller --norestart
```

The path is the current VM's protected seed root, not a reusable production
path. Select and recheck the actual protected recipient paths at invocation.
The expected local Catalog is 17,954,732 bytes/SHA-256
`f0a50ea157222c29abd5ea6ff01bfc3c33b04e011c5e45ee2ca38ef0778e5643`;
the ChannelManifest is 91,781 bytes/SHA-256
`fca418ba94ffbcfb7a2b25f10f16f39dd09660568d21eef4bd3f274cb0b27b8c`
(`contract-v1.md:353-375`). Use the local pinned channel for both installation
and future update source; do not use the existing `Response.json`'s mutable
`https://aka.ms/vs/17/release/channel` update source. If `--installCatalogUri`
fails, Microsoft says the channel manager can fall back to the catalog URI in
the install channel; therefore its presence is **not** proof that the selected
Catalog was used. Retain the channel's contradictory declared Catalog identity
and the 140 payload size conflicts separately; never replace an expected pin.

[Microsoft's Build Tools component list](https://learn.microsoft.com/en-us/visualstudio/install/workload-component-id-vs-build-tools?view=vs-2022)
lists both explicit component IDs. Selecting those two avoids the broader
`VCTools` workload and `--includeRecommended`. `--downloadThenInstall` directs
the vendor to finish downloads before product installation; it does not give
AutoClip an inspection pause. Omit `--noWeb`: Microsoft says it prevents product
package downloads from the web and does not prevent installer update checks.
This direct route needs the official recipient package downloads. Omit
`--useLatestInstaller`, layout switches, unreviewed response files and a remote
`--channelUri`.

## Smallest qualification sequence for the parent

1. Finish exact SDK terms inspection and record explicit VM consent for both
   Build Tools and applicable SDK terms. Production wizard consent remains a
   separate recipient decision (`contract-v1.md:397-402`); the current Inno
   Microsoft link is VC Runtime terms, not Build Tools terms
   (`installer/AutoClip.iss:152-155,675-686`).
2. In the VM, check the protected local Catalog/Channel signatures, sizes,
   hashes and path permissions, the exact installed `setup.exe` identity and
   complete 868-file engine closure immediately before launch. Confirm no
   conflicting Build Tools instance/installer operation. Capture the exact
   argument array and original native process identity/terminal state.
3. Run the one supported quiet direct install with recipient network available
   for official product packages. Preserve native logs and package resolution.
   Reject installer self-update, unknown executable selection, metadata
   fallback to a different Catalog/channel, different product/version,
   unexpected component or publisher, hash/signature failure, nonterminal
   observation, unexpected restart and any unreviewed source. Do not treat the
   verified bootstrapper hash alone as verification of nested downloads.
4. Recheck Catalog/Channel and engine identities; inspect vendor logs for
   selected metadata, package/hash validation and final status. Verify the
   installed Build Tools product/version, exact VC and SDK component records,
   SDK 10.0.26100.7705 headers/libs, `vswhere`, `vcvars64.bat`, compiler
   version and a real x64 compile/link/run. Separate an observed product pass
   from the still needed fresh-recipient engine and full Inno wizard tests.

Microsoft documents [quiet initial installation examples](https://learn.microsoft.com/en-us/visualstudio/install/command-line-parameter-examples?view=vs-2022).
The current contract intentionally permits quiet only after informed consent,
and still requires all incoming artifact, nested payload, signature, publisher,
version, staging and pre-execution integrity checks (`contract-v1.md:414-440`).
Vendor command support and a warm VM product result do not alone establish
those requirements for a new recipient. No whole-machine complete trace is
added as a gate; use exact input/output identities, vendor logs and supported
vendor integrity/version controls, while preserving unknowns as `BLOCKED`.
