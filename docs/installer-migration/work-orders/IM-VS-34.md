# IM-VS-34 — selected Channel source in the fixed bootstrapper

Status: read-only source resolution, 2026-10-02. Only this report was created. No host vendor download/execution, VM/server operation, dependency installation or source mutation occurred. Other writers and every frozen diagnostic remain preserved.

## Source resolved

The exact selected bootstrapper `D:/AutoClip-Inno-Migration/vs_BuildTools-17.14.41.exe` is4,473,792 bytes/SHA256 `37bb0fb429d163ecebd272a865d11a37b906d152bef960da2ddb29c2e2fd6eeb`. Its appended7z archive contains:

| Data member | Bytes | SHA256 |
| --- | ---: | --- |
| `vs_bootstrapper_d15/vs_setup_bootstrapper.json` |247|`476919b575ff8b9020d699d410b13d6308dbcbd986511003a4b6c56112587549`|
| `vs_bootstrapper_d15/vs_setup_bootstrapper.config` |658|`641a449fc79826364839ae4239169ca513bf9e259d86765f69930338d22252c2`|

The JSON has exactly these selected identities:

```json
{
  "installChannelUri": "https://aka.ms/vs/17/release/525981922_-560036080/channel",
  "productId": "Microsoft.VisualStudio.Product.BuildTools",
  "channelId": "VisualStudio.17.Release",
  "channelUri": "https://aka.ms/vs/17/release/channel"
}
```

The exact byte hash above refers to the embedded247 bytes, including their mixed line endings, not this displayed formatting. The configuration independently says `IsFixed=true`, `productSemanticVersion=17.14.41+37710.0.(september.2026)` and `DownloadUrl=https://aka.ms/vs/17/release/525981922_-560036080/installer`. The latter is an installer endpoint, **not** the Channel endpoint. The selected `installChannelUri` is the concrete missing acquisition source from IM-VS-32. The generic `channelUri` is the historical mutable update source and must not replace it.

The exact selected Channel91781-byte body is not a standalone archive member, and this investigation did not demonstrate an embedded copy of its bytes. The fixed metadata supplies its source URL; it does not turn an `aka.ms` redirect into an immutable body guarantee. No current redirect chain or delivered body was fetched on the host. Existing guest native authentication of the same exact bootstrapper supplies the operational authenticated-container evidence; this read-only host extraction establishes which metadata belongs to those fixed bytes, not a new host trust-chain qualification.

## Smallest recipient plan

Root can add this **one fixed source URL** to the existing bounded control acquisition, alongside the previously established Catalog URL. No bootstrapper extraction dependency needs to be added to the recipient: preserve the exact metadata hashes/source linkage in its first-party control record and use the reviewed literal URI. If recipient extraction is desired as a diagnostic cross-check, it must treat the container only as data and require the same two member pins; launching its extractor/bootstrapper is unnecessary for Channel acquisition.

Use the existing SHA-pinned production protected downloader with a derived diagnostic Channel row, safe destination `ChannelManifest.json`, `DIRECT_RECIPIENT_DOWNLOAD`, bytes91781, SHA256 `fca418ba94ffbcfb7a2b25f10f16f39dd09660568d21eef4bd3f274cb0b27b8c`. Its manifest/data inputs remain verified/read-locked, and output is created in the new protected recipient stage. The source is:

`https://aka.ms/vs/17/release/525981922_-560036080/channel`

Inspect/preserve the actual recipient HTTPS redirect hops; only the explicit official `aka.ms` and `download.visualstudio.microsoft.com` hosts are candidates for this narrowly scoped source. The helper already rejects an unapproved host, non-HTTPS URI, unsafe destination, excessive redirects and changed body size/hash. If this endpoint currently requires a different hop, fails to deliver the exact bytes, or is inaccessible, preserve the failure instead of accepting a new host/body or switching to generic latest. This report does not claim the candidate two-host route was exercised.

Before seed/vendor use, verify the resulting exact Channel through the existing frozen JSON authentication functions and normal native chains, then require BuildTools channelRelease/product17.14.41/build17.14.37710.0 and the preserved signed Catalog association. The selected Catalog body remains17,954,732 bytes/SHA256 `f0a50ea157222c29abd5ea6ff01bfc3c33b04e011c5e45ee2ca38ef0778e5643`; its channel-declared30,443,537/`6e470016…` conflict is unchanged. Actual redirect/body success and current authentication are the remaining acquisition observations; no new framework, approval flow, tracing condition or engine replay follows from finding this URL.

## Methods and limits

Read-only standard-library PE resource enumeration found icons/dialog/version/manifest resources, not a Channel source. The bootstrapper has an appended7z archive at offset435876. Native Windows `tar -tf` listed its members, but `tar -xOf` reported an LZMA unsupported-options error; no files were extracted to disk. Existing installed `C:/Program Files/7-Zip/7z.exe` successfully read only the two metadata members to stdout using `x -so`. Python `subprocess.run(..., capture_output=True)` hashed the exact binary stdout. Full bootstrap bytes/hash were checked before the reads and byte equality again afterward. No vendor assembly was loaded or executed.

Exact successful commands were `7z.exe x -so <exact bootstrap> vs_bootstrapper_d15/vs_setup_bootstrapper.json` and the corresponding `.config` member. Searches of existing selected Channel/inventory/work-order evidence found no previously recorded final redirect URL. This report resolves the source linkage while retaining the need for actual recipient acquisition and current authentication. Canonical prerequisite and final fresh Inno wizard gates are unchanged.
