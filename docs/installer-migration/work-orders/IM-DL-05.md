# IM-DL-05 — protected MSYS2 input batch

Status: helper implemented and focused Windows PowerShell5.1 verification
passed. Parent owns Inno integration and manifest disposition. No vendor network
request, executable, VM command, or installation was performed in this slice.

## Requirement and contract impact

Under the runtime updater skill, architecture and installer migration contract,
the MSYS2 wizard download phase must stage one exact base archive, its detached
signature, the installer signing key, and the manifest's five packages plus
their signatures before returning a usable base path. It must retain the same
protected single-artifact transport, cancellation and cache policy, validate
every required route before first HTTP, and bind the sequence to setup's exact
manifest bytes. Ownership was only `installer/download-artifact.ps1`,
`tests/InstallerDownload.Tests.ps1`, and this report. No other source/manifest
was edited; frozen VS probe2fafe7... was preserved.

Opt-in CLI extension:

```powershell
powershell.exe -NoProfile -File <absolute-download-artifact.ps1> -ManifestPath <absolute-manifest.json> -ManifestSha256 <setup-bound-64-hex-sha256> -Identity MSYS2 -DestinationPath <existing-TEMP-parent>\msys2-base-x86_64-20260611.tar.xz -MsysInputs [-CancelPath <absolute-TEMP-signal>]
```

Dot-source API `Get-InstallerMsysInputs` accepts the same arguments except the
switch. It returns only the verified absolute base path after all13 inputs
are available. Default CLI and `Get-InstallerArtifact` retain their ordinary
single-artifact behavior. `ManifestSha256` without `MsysInputs`, publisher
manifest in batch mode, nonexact MSYS2 identity, or incorrect base destination
is rejected. This introduces an installer integration boundary but changes no
HTTP API, release schema, delivery classification or installer selection pins.

## Minimum implementation

Extracted existing artifact resolution/metadata policy and destination policy
into shared internal functions. Single downloads and batch preflight use those
same checks; the transport implementation was not duplicated. Batch enumerates
the canonical MSYS2 row dynamically, without a second list of package names,
versions or pins. Exactly one20260611 tar.xz base row, one signature, one signing
key with the existing required fingerprint, and exactly five distinct packages
with one signature each are required. Names must be safe and unique. Extra
artifact children, cross-group alias collisions, blocked parent/child routes,
invalid pins/hosts, unsafe paths and corrupt cached files fail before HTTP.

The batch opens the actual normalized manifest path with FileAccess.Read and
FileShare.Read, hashes that open handle against the supplied setup binding,
and retains the handle through preflight and all13 ordinary downloader calls.
Windows sharing semantics prevent writers/deletion while allowing the helper's
normal manifest rereads. This also rejects an already-open incompatible writer
before downloading. [Microsoft FileShare documentation](https://learn.microsoft.com/dotnet/api/system.io.fileshare)
supports this behavior; the suite independently attempted real writes during
every fake HTTP request and observed IOException with manifest bytes intact.

Each input retains its own exact bytes/hash, HTTPS443 URL and redirect host
policy, native certificate checks, five-hop bound, body/header time bounds,
absolute regular TEMP destination, reparse rejection, cooperative cancellation,
no overwrite, and exact-cache verification. Failed or cancelled sequences keep
completed verified files; retries reuse them. Only unverified temporary bytes
are removed by the existing single-artifact cleanup. This is acquisition only:
OpenPGP verification, extraction, base trust and package transaction remain
responsibilities of the separate MSYS2 helpers.

## RED and GREEN evidence

Exact focused command, run repeatedly from `D:\Projects\autoclip-runtime`:

```powershell
& "$env:SystemRoot\System32\WindowsPowerShell\v1.0\powershell.exe" -NoProfile -File tests/InstallerDownload.Tests.ps1
```

First RED: test called actual `Get-InstallerMsysInputs` for the required13-input
sequence; function was absent, producing CommandNotFoundException / exit1.
After initial implementation, an additional meaningful RED showed an undeclared
`extra_payload` child was accepted even with a fully cached batch:
`Batch must reject extra.*child before HTTP.` / exit1. Added closed child
validation rather than weakening that requirement.

Intermediate harness corrections: the unsafe signature name was already
rejected by existing package metadata validation, so the assertion accepts that
specific error as well as unsafe-filename rejection; the fixture copied from
the canonical outer manifest already had `external_assets`, so the deliberate
ambiguity fixture uses Add-Member -Force. Neither change relaxes behavior.

GREEN uses six-byte first-party `pinned` bodies at the existing mocked HTTP
response boundary. It executes real resolver, filesystem staging, hashes,
streaming, cache and cancellation code. No test transport parameters or fake
URLs were added to production. New assertions prove:

- exactly13 requests and13 verified files, returning only the base path;
- fully verified cache emits zero requests;
- attempted manifest writes fail during requests;
- blocked final child under a DIRECT parent, wrong/change-bound manifest hash,
  invalid key fingerprint, unsafe filename, duplicate package, sixth package,
  cross-group package/base filename ambiguity, undeclared child, unapproved last
  redirect host, relative destination and corrupt cache fail before any request;
- HTTP503 on request5 preserves exactly four verified files; retry makes9
  requests and completes the batch;
- cancellation during request5 preserves four files, leaves no fifth output,
  and successful retry makes9 requests;
- the actual native PowerShell CLI `-MsysInputs -ManifestSha256` entrypoint
  returns the cached verified base successfully without network.

The original suite also passes unchanged behavior for single artifacts, release,
external/native assets, publisher manifest binding, nested MSYS2 selectors,
redirect rejection, byte/hash mismatch, blocked classification, cache corruption,
bounded stalled reads and cooperative header/body cancellation. No tests were
disabled. A final full focused run was made after normalizing the manifest lock
path. Repository-wide/Inno build and guest qualification are parent-owned gates.

## Frozen helper and test hashes

| File | SHA-256 |
| --- | --- |
| `installer/download-artifact.ps1` | `75ac92e4108a6fd3165617b2c94be02b44ca86c61a5397672d898eaa38635ad6` |
| `tests/InstallerDownload.Tests.ps1` | `83f071d4eab36eea960782a49675bd78f683b705c6b209a67130ea53d5a7ddfb` |

Limits: no actual thirteen-file vendor download or batch VM execution was
authorized; fixture bodies are not vendor archives/signatures. The lock protects
manifest bytes while held, not an untrusted operator supplying a different
manifest/hash pair. Setup must supply its independently verified binding and
reviewed route metadata. The batch requires five approved packages dynamically;
changing that contract requires an intentional future update. No native trust,
recipient installation, legal, blind review or publication gate is satisfied by
these helper tests.
