# IM-VS-35 — current recipient control acquisition only

Status: prepared and focused fixture-verified, 2026-10-02. Actual guest acquisition is unperformed by this author. Root owns server/VM/vendor operations. Only the two new external first-party files and this report were written; existing diagnostics, receipts, inventory and production downloader are unchanged.

## Requirement and boundary

IM-VS-32/34 identify the smallest preparation gap before layout qualification: the current recipient has the pinned bootstrapper/OPC and engine, but VS22's control source belongs to the old warm recipient. Prepare exactly nine pinned layout controls using current recipient inputs and official metadata URLs. No vendor launch, certificate import, current signature qualification, engine replay, generated layout approval, product installation or uninstall occurs. Canonical contracts/manifests are not changed. User rights/VM-term confirmations remain recorded by root.

## Frozen files and interface

| File under `D:/AutoClip-Inno-Migration/vm-transfer` | Bytes | SHA256 |
| --- | ---: | --- |
| `vs-recipient-controls-probe.ps1` |11,477|`cd4ba3355bb10c33402e0573b4dd240aa50cbd5a70c6989538e6ea25a6ec431a`|
| `vs-recipient-controls-probe.Tests.ps1` |4,433|`7f00c0ab84ea5004f0f0bf23f6399a180b4e894ad79d0abba83dd5e3d0d39efe`|

Default invocation is `READ_ONLY_PLAN`, exit0; no writes/network/vendor action. After root verifies the exact first-party source, explicit guest invocation is:

```powershell
powershell.exe -NoProfile -File <verified-first-party-driver> -AcquireControls
```

Requires ordinary unelevated native64 `autocliplab` before staging or network. Creates a fresh absent private `vs c-<uuid8>` stage and `controls` root shorter than80 characters. Uses recipient/SYSTEM/Administrators full-control ACLs; rejects reparse paths, foreign ownership/ACLs and existing targets. Source current guest root is fixed `C:/Users/autocliplab/AppData/Local/Temp/vs cold-65a14b08`, with its protected recipient-owned ACL checked. Bootstrapper and OPC copies use the unchanged VS22 `Copy-VsSeedControl` with held input readlocks, exact pins and CreateNew. `vs_setup.exe` is the identical pinned bootstrapper copy, not the different channel-listed setup bootstrapper.

Only first-party dependencies are fetched from `http://10.0.2.2:8765/`; exact bytes/SHA are verified and kept read-locked. Import verified function ASTs from the held stream, never execute their operational drivers:

- VS20 r2,15,769 bytes/`fcc4bab2e423303c5dd11ac4b3139b5c61fe1bef45f1a57a0865c79b26826fe8`: path/ACL/hash/readlock/JSON functions.
- VS22,16,942 bytes/`887ed9af03eff980b08603b280265282bc4520fcffe510834974d70e83013b00`: only `Copy-VsSeedControl`.
- Downloader,19,545 bytes/`75ac92e4108a6fd3165617b2c94be02b44ca86c61a5397672d898eaa38635ad6`: existing protected acquisition functions.
- Original409 inventory,470,838 bytes/`545b140236b4765a964c14708dcbf1e6131497a58c1655be081631b4f8a91397`: the single maintained source for all nine control byte/hash pins.

## Acquisition and derived data

A derived diagnostic-only two-row manifest takes expected pins from the frozen inventory, is created with CreateNew and held read-locked through downloader use. Official sources are:

- Catalog: `https://download.visualstudio.microsoft.com/download/pr/bc92e2cb-33de-4a0c-995d-efa817f16b16/6e470016e4324c84c255ffd0beb3767d17ec89cc8561e9409ee3e1f6d29400f5/VisualStudio.vsman`;17,954,732 bytes/`f0a50ea157222c29abd5ea6ff01bfc3c33b04e011c5e45ee2ca38ef0778e5643`; sole allowed host `download.visualstudio.microsoft.com`.
- Channel: `https://aka.ms/vs/17/release/525981922_-560036080/channel`;91,781 bytes/`fca418ba94ffbcfb7a2b25f10f16f39dd09660568d21eef4bd3f274cb0b27b8c`; narrowly allowed official hosts `aka.ms` and `download.visualstudio.microsoft.com`. IM-VS-34 binds this exact selected URI to fixed bootstrap metadata. Current redirects are unobserved here; root can inspect actual guest redirects. The helper enforces HTTPS/host policy/hop limit/exact delivered pins. Different host/body fails without adopting latest. The unchanged downloader does not return a complete redirect-hop receipt; `download_sources` records requested URLs/allowed hosts, not an observed chain.

From the pinned copied OPC, open a native ZIP read view over the same held stream, require one exact `Contents/vs_installer.version.json` entry, verify121-byte/SHA `e78a1053a6d59ad60ba8105623181b013c0ffc452216caada2699046f191974f` output before CreateNew. No assembly inside the OPC is loaded.

From the exact downloaded Catalog, decode only its existing signature DER arrays: `signature.keyInfo.x509Data[2]` for manifestRoot; `signature.counterSign.x509Data[2]` for manifestCounterSignRoot and the identical expected OPC-root file. All three derived outputs must match their canonical inventory pins before writing; no chain construction/import is performed. Catalog/Channel must also retain build17.14.37710.0 and semantic17.14.41 selection. The signed Catalog-reference conflict and140 payload size conflicts remain unchanged.

Final receipt requires exactly nine files and independently rereads each under native readlock. Status is deliberately `ACQUIRED_EXACT_9_CONTROL_PINS_AUTHENTICATION_PENDING`, with `signature_verification_performed=false` and `requires_current_authentication=true`. Full receipt persists locally on success/failure; partial stage survives. There is no HTTP result post, server mutation or retry loop.

## RED → GREEN evidence

Exact command:

```powershell
powershell.exe -NoProfile -File 'D:/AutoClip-Inno-Migration/vm-transfer/vs-recipient-controls-probe.Tests.ps1'
```

RED before implementation: exit1, `RED: exact recipient control derivation absent.` GREEN final focused execution: exit0. Tests import actual driver/helper functions and use only first-party synthetic bytes: exact three DER selections; unknown certificate rejection; native in-memory ZIP version extraction and wrong pin rejection; actual protected native CreateNew output; hash mismatch/unsafe relative path/existing destination rejection; original file preservation; held readlock blocks writes; actual default subprocess returns read-only plan. Fixture roots remain preserved under host TEMP. PS5.1 parser passed. No vendor download/signature operation or host/guest installer experiment occurred.

## Remaining integration

Root must review the fixed source/redirect policy and frozen snapshot before actual recipient acquisition. Current normal JSON/OPC/native bootstrap authentication remains a separate required step using already reviewed frozen helpers with new held inputs; old top-level verifier paths cannot be reused unchanged. Acquired-byte equality alone is not current native trust. Then bind the actual new control receipt together with the actual current397 acquisition to minimal seed preparation, review all incoming pins, qualify supported vendor layout generation, review generated inventory/vendor verification, and perform native interactive product installation/capability checks. Final fresh Inno CPU wizard and release evidence remain outstanding. No new approval flow or cold engine-only replay is added.
