# IM-DEP-15: correct verified FFmpeg staging under short TEMP aliases

Date: 2026-10-02. Root assigned the actual r2 CPU Setup failure to this
implementer. Ownership: `install.ps1`,
`tests/InstallerFFmpegIntegration.Tests.ps1`, and this record. Other writers
retain their files. No acquisition, vendor installation, VM action, commit,
publication, manifest change, or historical receipt rebinding was performed.

## Requirement and observed failure

The guarded bootstrap must accept the exact pinned FFmpeg archive under a
regular local TEMP directory, including Windows 8.3 aliases. It must retain
the existing archive/helper/executable pins, regular-path and reparse checks,
destination equality, complete notices, and isolated runtime registration.
This repairs implementation of the existing installer contract; it adds no
public interface or dependency.

Root reported actual r2 Setup reaching Python installation and protected
downloads, then failing in `Initialize-AutoClipFfmpeg` at bootstrap line 613:
`Unexpected verified FFmpeg executable path.` The guest stderr is 483 bytes
and contains no process TEMP or returned executable value. Explorer's long
folder spelling alone does not establish the process environment. Corrected
VM execution is still required to confirm this diagnosis for that guest.

## Diagnosis and minimum implementation

All callers and the shared archive helper were inspected. There is one
production caller of `Initialize-AutoClipFfmpeg`. The pinned archive helper
normalizes an existing destination with `[IO.Path]::GetFullPath`; .NET expands
existing short aliases. The caller previously retained the `Join-Path`
spelling from process TEMP and compared that spelling with the helper's
normalized executable result.

A host native path probe observed:

```text
Short        : C:\Users\beilo\AppData\Local\Temp\AUB719~1
FullExisting : C:\Users\beilo\AppData\Local\Temp\autoclip short path probe e3a532a5e6154a1faf1a4f56bd65b292
FullAbsent   : C:\Users\beilo\AppData\Local\Temp\AUB719~1\absent
```

Normalizing an absent staging name does not expand its existing alias on this
host. The one-line production fix therefore normalizes the existing TEMP
directory before appending the fresh staging name. The original path guard
still executes before creation; the exact expected executable comparison is
unchanged.

The existing integration fixture now invokes the actual initializer and
unchanged archive helper with a genuine short TEMP directory, using the
existing exact 111253802-byte archive:
`fec81ae03971d9dd4be3ebe02e263bd2ec1d789483f931bdba5f5715e65da2e9`.
It restores process TEMP immediately after invocation. This reproduces the
actual error before the production change; it does not mock extraction or
weaken a security assertion. The helper's before-fix returned path was not
captured; a separate attempted diagnostic invocation to capture both path
strings was rejected as `blocked by policy` and was not retried.

Two obsolete test assumptions initially prevented a complete run: the runtime
helper hash predated the documented IM-CPU-21 change, and completion ordering
still searched for the replaced raw WriteAllText producer. The fixture now
pins the actual IM-CPU-21 helper and explicitly requires the current
`Write-AutoClipCompletionFile` production call after registration. No valid
behavioral assertion was removed.

## RED, GREEN, and verification

Working directory: `D:/Projects/autoclip-runtime`.

```powershell
powershell.exe -NoProfile -NonInteractive -File tests/InstallerFFmpegIntegration.Tests.ps1
```

RED with the new genuine-short-TEMP fixture and unchanged production code:
`Unexpected verified FFmpeg executable path.` After the one-line fix: PASS,
exit 0. The full integration also verifies actual ASS/subtitles/libx264
capabilities, complete retained notices/tree inventory, rerun identity,
modified and foreign-file rejection, actual isolated Python 3.11.9 venv
startup discovery, persistent registration, helper/route rejection, stage
ordering, and process PATH/TEMP cleanup. Global user/machine PATH is unchanged.

```powershell
powershell.exe -NoProfile -NonInteractive -File tests/InstallerToolArchive.Tests.ps1 -RealFfmpegArchive D:/AutoClip-Inno-Migration/ffmpeg-9.0.1-essentials_build.zip
git diff --check -- install.ps1 tests/InstallerFFmpegIntegration.Tests.ps1
```

Both PASS, exit 0. The actual archive regression verifies executable hashes,
original notices/docs, ASS/x264/AAC rendering, FFprobe, decoded text, archive
traversal and hash rejection.

Final file SHA-256:

| File | SHA-256 |
| --- | --- |
| `install.ps1` | `444d86dcd7dbbae71af6a285a58693c11bfc72a9f3f70b537b696f0a3f6b7cba` |
| `tests/InstallerFFmpegIntegration.Tests.ps1` | `ba668a2617582f7047b8340409275cdd14d8e9b84667db4b5b1591e722463cb5` |
| Unchanged `installer/install-tool-archive.ps1` | `685cc6a5924e851dd5387704030a44e42db479a0e147fb994d3c716dc688f7f8` |
| Unchanged `installer/install-runtime-toolpath.ps1` | `c959d360a99155179262058ecc311edd9f36f14926b7edcdf239273e619e4f68` |

This is host reproduction and regression evidence. Root owns the fresh
immutable successor, review, corrected real VM retry, installed application
tests and later generated-uninstaller tests. No full installer, uninstaller,
NVIDIA, or publication gate is closed by this work order.
