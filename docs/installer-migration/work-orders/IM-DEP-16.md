# IM-DEP-16: canonical TEMP for the shared protected download callback

Date: 2026-10-02. Root assigned the actual r3 CPU VM failure after source
staging. Ownership: `install.ps1`, existing
`tests/InstallerSecureAcquisition.Tests.ps1`, and this record. No VM, vendor,
acquisition, publication, or commit action was performed by this implementer.

## Requirement and actual failure

The existing guarded acquisition contract must accept exact approved bytes
under a regular local TEMP directory when Windows supplies an 8.3 alias.
Retain all helper/manifest/URI/size/hash/classification, regular-path,
destination equality and reparse checks. There is no public contract change.

Root observed actual r3 guest stderr:
`Protected downloader returned unexpected bytes or path.` at generated
`install.ps1:572`. The preserved failure snapshot is
`c664d611-50fa-49a9-9726-9782db8cdda5`; the attempt is
`source-build-is-KY4LZUIX00.tmp-1`. This follows the separate IM-DEP-15 FFmpeg
fix. Corrected actual VM execution remains root's responsibility.

## Root cause and implementation

`Invoke-AutoClipSecureDownload` created staging directly from `$env:TEMP` and
compared the downloader's normalized returned path with that unnormalized
spelling. As reproduced in IM-DEP-15, .NET expands existing Windows short
aliases. The downloader creates the staging file before the caller normalizes
its return, so that normalization expands the existing alias.

The shared fix is one line: normalize the existing TEMP directory before
appending the fresh `autoclip-secure-<guid>` staging name. The guarded default
callback and all its consumers use this function; no per-consumer workaround
or changed downloader is required. The exact returned-path, size and hash
checks are unchanged.

The regression uses a genuine Windows 8.3 alias for process TEMP while running
the existing actual archived Prepare callback, native source callback,
content-addressed callback and installer external-asset invocation. It mocks
only the existing HTTP response boundary. Protected downloader resolution,
staging, bytes and path validation remain real. Process TEMP is restored in
the fixture's finally block.

Remaining bootstrap TEMP consumers were inspected: the FFmpeg initializer
already normalizes existing TEMP; terms display normalizes both roots; fresh
Setup provenance and legacy archive staging use file paths without this
returned-path equality comparison. No further direct-TEMP equality consumer
was found in `install.ps1`. Publisher-native Python staging and managed FFmpeg
registration were also inspected; no analogous TEMP-return comparison was
found there. This inspection does not qualify those paths in the guest.

## RED, GREEN and regression commands

Working directory: `D:/Projects/autoclip-runtime`.

```powershell
powershell.exe -NoProfile -NonInteractive -File tests/InstallerSecureAcquisition.Tests.ps1
```

RED before production edit with the genuine short-TEMP fixture:
`Protected downloader returned unexpected bytes or path.` After the one-line
fix: GREEN, exit 0. All four actual callback producers, strict pins, private
TEMP manifest snapshot, default restoration, unknown URI, changed sizes and
hashes, missing callback metadata, alternate streams, reparse destinations,
changed publisher/outer/helper bytes, blocked routes and ambiguity checks pass.

Additional regressions, both PASS with exit 0:

```powershell
powershell.exe -NoProfile -NonInteractive -File tests/InstallerDownload.Tests.ps1
powershell.exe -NoProfile -NonInteractive -File tests/InstallerFFmpegIntegration.Tests.ps1
```

The downloader retains redirect, classification, size/hash, retry and
verified/corrupt-cache behavior. The real exact FFmpeg archive integration
retains short-TEMP extraction, complete notices, rerun/foreign rejection,
native venv startup, helper pins and stage ordering.

Final hashes:

| File | SHA-256 |
| --- | --- |
| `install.ps1` | `f007bb27712a617c750f6fbee4dd911d2574b57538d2bcbe7a8ae0769ef1cb8e` |
| `tests/InstallerSecureAcquisition.Tests.ps1` | `0fdfb06bc1769903324df06fe131fc6290d49cd4dac754403d5bcf7847943451` |

`git diff --check -- install.ps1 tests/InstallerSecureAcquisition.Tests.ps1`
passed. Historical r2/r3 source, Setup and receipts are not rebound. Actual
corrected installer/application/generated-uninstaller testing and fresh
candidate review remain pending with root. NVIDIA hardware remains deferred.
