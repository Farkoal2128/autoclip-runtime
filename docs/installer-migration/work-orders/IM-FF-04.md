# IM-FF-04: release-owned FFmpeg startup PATH

Status: bounded helper and real disposable-venv behavior verified on host;
parent setup integration and installed AutoClip qualification remain pending.

## Authorization, ownership and contract

Parent work order IM-FF-04 explicitly authorizes persistent CLI discovery for
direct Python/Pythonw desktop startup and the app-only updater without changing
global PATH, the v40 archive or existing launchers. Owned files are
`installer/install-runtime-toolpath.ps1`,
`tests/InstallerRuntimeToolPath.Tests.ps1`, and this record. The parent owns
manifest disposition, retained tool staging, bootstrap/Inno integration and
completion/activation. No shared file was edited.

Requirement: the [installer contract](../contract-v1.md) requires verified
prerequisite capabilities and ordinary-user offline launch after validation.
The [runtime architecture](../../runtime-update-architecture.md) requires the
selected runtime to remain usable through app-only updates and rollback.

Inspected implementation boundaries:

- `install.ps1`, Install-AutoClipLaunchers, targets
  `.venv/Scripts/pythonw.exe -m autoclip.desktop` directly.
- `update-app.ps1`, Write-DesktopLauncher, selects a separate app layer with
  PYTHONPATH and launches the same runtime's Pythonw.
- MyAutoClip `src/backend/autoclip/system.py`, probe_ffmpeg, uses
  shutil.which for FFmpeg and FFprobe; its media pipeline invokes the CLI tools.
- `installer/install-tool-archive.ps1` already verifies the selected exact
  Gyan essentials executable hashes and capabilities. Its temporary extraction
  alone cannot persist process PATH for a future direct shortcut launch.

## Accepted interface and expected paths

The parent accepted this interface and fixed ownership rule:

```powershell
& installer/install-runtime-toolpath.ps1 -ReleaseRoot <verified-release-root> -ManagedToolRoot <verified-release-root>\tools\ffmpeg -ManifestPath <trusted-dependency-manifest>
```

Expected interpreter environment:
`<ReleaseRoot>/.venv`, isolated Python 3.11.9, with pyvenv.cfg,
Scripts/python.exe, Scripts/pythonw.exe and Lib/site-packages present.
The helper does not execute a caller-supplied Python, FFmpeg or script.

Managed bin:
`<ReleaseRoot>/tools/ffmpeg/ffmpeg-9.0.1-essentials_build/bin`.

New setup-owned file:
`<ReleaseRoot>/.venv/Lib/site-packages/autoclip_ffmpeg_path.pth`.

The parent must retain the complete unmodified official FFmpeg extraction under
that tool root, including supplier notices/readme/docs, before registration.
Invoke registration after venv creation and before final setup completion or
activation. Keep these files while the runtime is selected or retained for
rollback. This helper does not replace the archive extractor, capability/media
checks, lifecycle inventory or full runtime provenance verification.

Public/domain impact: additive setup-owned registration interface and receipt.
No existing launcher, app-only updater, v40 payload bytes, runtime identity,
global environment or production dependency classification was changed.

## Validation and publication

The helper requires schema 1 and exactly one DIRECT_RECIPIENT_DOWNLOAD Gyan
FFmpeg 9.0.1 x64 entry with the exact official essentials URL and these two exact
manifest AND local executable hashes:

| Relative path within ManagedToolRoot | SHA-256 |
| --- | --- |
| ffmpeg-9.0.1-essentials_build/bin/ffmpeg.exe | 72a489eccd008c2ec2c0a5856c5c75bc3d8bbfa90166c4566865c246445e6aa3 |
| ffmpeg-9.0.1-essentials_build/bin/ffprobe.exe | 19202b23c0043f15ad1b7bce2344f406fd52bd6efd8f995ce02e7392a1cec52f |

Unknown/wrong pins, versions, URL, architecture or classification fail closed.
ManagedToolRoot must equal ReleaseRoot/tools/ffmpeg. Local absolute drive paths
are required; traversal, empty/dot segments, unsafe characters, semicolon PATH
delimiters and reparse points in any relevant path/ancestor are rejected.
The site directory and interpreter files are always resolved under the exact
release's .venv, never a global or user site-packages directory.

The .pth has an ownership comment and one executable startup line. It prepends
only the managed bin to this Python process's inherited PATH, preserving other
entries. Repeated processing does not add repeated leading copies. The path is
UTF-8 hex data inside ASCII source, so spaces, non-ASCII text and supplementary
Unicode characters do not depend on .pth file locale or become Python syntax.

The helper publishes complete bytes by flushing an exclusively created temporary
file in the same site directory, then moving it to the final name without
replacement. An existing exact owned file is idempotent; any other content or
foreign/reparse file is preserved and rejected. Concurrent publication can only
adopt the exact same content; it cannot replace a competing file. Unrelated
site-packages files are untouched.

Returned receipt fields: release_root, venv_root, managed_bin, pth_path,
pth_bytes, pth_sha256, manifest_sha256 and both executable_pins. The caller must
bind this receipt to its verified setup/runtime installation receipt. No receipt
asserts full AutoClip, redistribution or release approval.

Primary Python references:
[Python 3.11 site initialization](https://docs.python.org/3.11/library/site.html)
documents startup processing of executable .pth lines and PATH adjustment.
[Python isolated mode](https://docs.python.org/3.11/using/cmdline.html#cmdoption-I)
documents ignoring Python environment variables/user site; runtime site startup
still runs. The real test below confirms this on Python 3.11.9.

## Behavioral RED and GREEN

Exact focused command:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File tests/InstallerRuntimeToolPath.Tests.ps1 -RealFFmpegArchive D:/AutoClip-Inno-Migration/ffmpeg-9.0.1-essentials_build.zip
```

RED before production helper creation: exit 1,
"Isolated venv startup must discover the managed FFmpeg and FFprobe without
launcher PATH changes." The test created a real disposable venv and verified
that pre-registration startup did not select the managed tool paths. The
production helper did not exist, so expected startup discovery failed; this was
not a mock, parsing error or absent fixture failure.

GREEN after implementation: exit 0, final focused rerun exit 0.

Actual checks:

- Python 3.11.9 stdlib venv creation with --without-pip; no dependencies,
  vendor installer or download was executed.
- Real exact local FFmpeg/FFprobe bytes extracted into the fixture's fixed
  managed path; fixture manifest declares DIRECT only for validation tests.
  The production manifest stays unchanged/BLOCKED.
- Release directory includes spaces, U+00E9 and U+1F680.
- Real `python.exe -I` startup proves shutil.which returns both exact managed
  paths, process PATH equals the expected prepend plus inherited PATH, and
  sys.prefix is the expected release venv.
- Real hidden `pythonw.exe -I` startup writes the same discovery results to
  a fixture JSON file.
- A real separate marker module loaded via app-layer PYTHONPATH coexists with
  startup tool registration. This proves the overlay environment boundary,
  not an actual AutoClip update or desktop session.
- Exact receipt hash and repeat registration pass.
- BLOCKED classification, changed manifest pin, changed actual FFprobe bytes,
  foreign managed root, traversal, a real directory junction, incompatible
  pyvenv.cfg and foreign .pth content all reject.
- Foreign .pth bytes and an unrelated .pth file are preserved.
- Parent process PATH and saved user/machine PATH values remain unchanged.

The disposable interpreter/probe runs prove startup discovery; they do not
execute AutoClip, invoke the FFmpeg media pipeline or close installed-release
acceptance. No launcher, archive or dependency manifest edit was made.

## Parser, whitespace and remaining gates

PowerShell 5.1 parsing passed for both scripts:

```powershell
$paths=@('installer/install-runtime-toolpath.ps1','tests/InstallerRuntimeToolPath.Tests.ps1')
foreach ($path in $paths) {
    $tokens=$null; $errors=$null
    [void][Management.Automation.Language.Parser]::ParseFile((Join-Path (Get-Location) $path),[ref]$tokens,[ref]$errors)
    if ($errors.Count) { throw ($errors | Out-String) }
}
git diff --no-index --check -- /dev/null installer/install-runtime-toolpath.ps1
git diff --no-index --check -- /dev/null tests/InstallerRuntimeToolPath.Tests.ps1
git diff --no-index --check -- /dev/null docs/installer-migration/work-orders/IM-FF-04.md
```

No whitespace diagnostics remain; no-index exit 1 means the new files differ
from /dev/null. LF/CRLF working-copy notices are not failures.

Parent integration still must stage the retained complete official tool tree,
call this helper on the exact candidate runtime, bind the receipt to setup
ownership/cleanup, and verify actual direct desktop launch, app-only selection,
rollback and the installed media workflow. Existing independent vendor,
technical review and publication gates remain separate.

Suggested commit message:
`installer: persist verified FFmpeg discovery in the release venv`.
