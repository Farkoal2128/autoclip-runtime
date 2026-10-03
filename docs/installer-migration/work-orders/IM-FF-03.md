# IM-FF-03: exact FFmpeg essentials archive helper

Authorization: parent work order authorizes extending the existing archive
helper to the exact Gyan FFmpeg 9.0.1 essentials recipient route. Ownership is
limited to this report, `installer/install-tool-archive.ps1`, and
`tests/InstallerToolArchive.Tests.ps1`. Root owns manifest, bootstrap/source
builder, launcher/.pth integration, Inno and VM qualification. No manifest,
launcher, download route, installed prerequisite or VM was changed here.

Requirement and contract: `docs/installer-migration/contract-v1.md` requires
allowed direct acquisition, exact archive identity, safe extraction, checks
before execution, installed capabilities and retained notices. The bounded
recipient operation and licensing limits are documented in
`docs/installer-migration/work-orders/IM-FF-02.md`. This change supports that
unmodified subprocess route; it does not authorize bundling, mirroring,
supplier-compliance claims or publication. Preserve the codec-free native
FFmpeg/PyAV source-build route.

## Interface and minimal implementation

Existing helper parameters are unchanged. `-Identity 'Gyan FFmpeg'` is the new
choice. Return stdout is the absolute selected `ffmpeg.exe` path, matching
the helper's existing executable-path convention. Its sibling is `ffprobe.exe`.
Scratch extraction remains a new directory under TEMP. MinGit and uv retain
their existing exact versions, signatures, executable paths and version checks.

The helper requires schema 1, one selected Gyan FFmpeg row, version `9.0.1`,
architecture `x64`, official essentials URL, `DIRECT_RECIPIENT_DOWNLOAD`,
archive bytes/SHA-256 and exactly these `executable_pins`:

| Manifest archive-relative path | SHA-256 |
| --- | --- |
| ffmpeg-9.0.1-essentials_build/bin/ffmpeg.exe | 72a489eccd008c2ec2c0a5856c5c75bc3d8bbfa90166c4566865c246445e6aa3 |
| ffmpeg-9.0.1-essentials_build/bin/ffprobe.exe | 19202b23c0043f15ad1b7bce2344f406fd52bd6efd8f995ce02e7392a1cec52f |

No new extractor abstraction or production bypass was introduced. The shared
extractor preserves the entire archive, including LICENSE, README and docs.
Existing traversal, rooted/drive paths, empty/dot segments, trailing dots/spaces,
symlink, duplicate case-insensitive entries and parent-reparse rejection remain.
Windows invalid filename characters/control bytes and reserved device aliases
are additionally rejected before extraction. The FFmpeg branch requires the
fixed `ffmpeg-9.0.1-essentials_build` root.

Both extracted executable hashes are checked before either is executed.
Their upstream bytes are unsigned; this bounded branch intentionally uses
the recorded publisher/archive/executable hashes, with no signature-bypass
switch. MinGit/uv still require their respective signatures. FFmpeg and FFprobe
must report exact `9.0.1-essentials_build-www.gyan.dev`; FFmpeg must list actual
`ass`, `subtitles` filters and `libx264` encoder. Failure removes only newly
created extraction staging; source ZIPs remain intact.

## Exact input and evidence scope

Official selected URL:

`https://github.com/GyanD/codexffmpeg/releases/download/9.0.1/ffmpeg-9.0.1-essentials_build.zip`

Local test input: `D:\AutoClip-Inno-Migration\ffmpeg-9.0.1-essentials_build.zip`,
111,253,802 bytes, SHA-256
`fec81ae03971d9dd4be3ebe02e263bd2ec1d789483f931bdba5f5715e65da2e9`.
The test creates a separate explicit direct-route fixture manifest. It does
not reclassify production or implicitly authorize downloads. Production FFmpeg
remains BLOCKED until root qualifies the guarded recipient route.

## RED / GREEN and checks

Before production edits, the new `-RealFfmpegArchive` test ran:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File tests/InstallerToolArchive.Tests.ps1 -RealFfmpegArchive D:\AutoClip-Inno-Migration\ffmpeg-9.0.1-essentials_build.zip
```

RED: `ParameterArgumentValidationError,install-tool-archive.ps1`: Gyan FFmpeg
did not belong to the existing `Git for Windows,uv` identity set.
After the bounded helper change, the same command passed.

The real test verifies original LICENSE/README hashes and retained FFmpeg/FFprobe
HTML documentation. It renders one second of generated black 320x180 video with
locally authored ASS text, x264 video and AAC sine audio; FFprobe must identify
one H.264 stream and one AAC stream. It decodes the first frame to RGB24 and
requires 172,800 bytes with nonzero samples, proving actual subtitle rendering
on the black input. All test media and extracted tools are removed from scratch.
No original recipient media was used or altered.

Rejection cases cover blocked FFmpeg route, wrong executable manifest pin,
archive hash, traversal, drive path, case duplicates, trailing-dot segments,
invalid wildcard filename and reserved NUL filename. The unsafe ZIP tests
require rejection before the staging directory exists.

Final combined regression command, exit 0 under Windows PowerShell 5.1:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File tests/InstallerToolArchive.Tests.ps1 -RealMinGitArchive D:\AutoClip-Inno-Migration\MinGit-2.55.0.3-64-bit.zip -RealUvArchive D:\AutoClip-Inno-Migration\uv-0.12.19-x64.zip -RealFfmpegArchive D:\AutoClip-Inno-Migration\ffmpeg-9.0.1-essentials_build.zip
git diff --check -- installer/install-tool-archive.ps1 tests/InstallerToolArchive.Tests.ps1 docs/installer-migration/work-orders/IM-FF-03.md
```

The combined command passed real FFmpeg media checks, exact MinGit and uv
extraction/signature/version checks, and the existing prerequisite-only
integration with `-NoPrerequisiteAcquisition`, including wrong uv signer rejection.
The diff check passed. These are prepared-host/local archive checks. Guarded
wizard download/redirect rejection, clean-machine provisioning, installed
ordinary-user media workflow, final setup inventory, technical review and
release gates remain root-owned and unperformed here.
