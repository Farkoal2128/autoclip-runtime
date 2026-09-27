# AutoClip Windows runtime

This repository distributes the Windows runtime build of AutoClip. It contains
the installer, PowerShell updater, launch script, copyright license and
release checks. The
versioned release asset contains the AutoClip wheel, its 78 Python dependency
wheels, and a source/notice supplement. Development research, plans, skills
and roadmap files are not part of this repository; its small workflow tests
verify release installation and updates.

## Install

This release supports **Windows x64**. Paste this single line into PowerShell;
you do not need to download `install.ps1` first:

```powershell
irm https://raw.githubusercontent.com/Farkoal2128/autoclip-runtime/main/install.ps1 | iex
```

The command runs this repository's current installer directly from GitHub.
Review [install.ps1](install.ps1) before running it if you prefer. The installer
uses Windows Package Manager (`winget`) to install missing `uv` and a full
FFmpeg/ffprobe build, and checks that FFmpeg has `libass` and `libx264`. It
uses a compatible Python 3.11 already on the machine when available. Otherwise
`uv` downloads Python 3.11, with a `winget` Python 3.11 fallback if that
download is unavailable. It downloads the pinned release archive,
checks its SHA-256 and every packaged file, then installs all 79 Python wheels
offline, including the CUDA 12 cuBLAS and cuDNN runtime packages used by
AutoClip's GPU Whisper path. It installs under
`%LOCALAPPDATA%\AutoClip\v11-20260926-notice-correction` by default and will not overwrite
an existing installation. The release archive is about 1.34 GB.
If an earlier installer stopped at `Python 3.11.16 installation failed`,
rerun the same one-paste command to install this release in its new directory.
An interrupted installation of this exact release can resume after its
manifest and files are verified, including rebuilding its Python environment.
Completed installations made by this installer and
unrecognized existing directories remain protected from overwrite.
Windows Package Manager (Microsoft App Installer) must be available if a tool
is missing. The installer may prompt for system permission or package terms.

After installation:

```powershell
& "$env:LOCALAPPDATA\AutoClip\v11-20260926-notice-correction\Start-AutoClip.ps1"
```

AutoClip then opens locally at `http://127.0.0.1:8000`. Ollama is optional for
local AI. If you want it, install it separately with:

```powershell
winget install --exact --id Ollama.Ollama --source winget
```

For a first local model to try, run:

```powershell
ollama pull llama3.1:8b
```

Then choose **Ollama** as the AI provider in AutoClip Settings and enter
`llama3.1:8b` as its model. This is a starting option, not a quality or speed
guarantee; the model download is about 4.9 GB and is separate from AutoClip.
Hosted providers use your own configured credentials. The release asset
contains none of these external tools or models.

The packaged NVIDIA libraries live inside this release's Python environment;
AutoClip registers their DLL directories when transcription starts. You do not
need the full CUDA Toolkit, a global `PATH` change, or manually downloaded DLLs.
On a machine without a usable NVIDIA GPU, Whisper can run on the CPU; the CUDA
runtime packages remain installed but unused. An NVIDIA driver compatible with
your GPU and these CUDA 12 libraries is still required for GPU inference.
To inspect acceleration and dependencies, run:

```powershell
& "$env:LOCALAPPDATA\AutoClip\v11-20260926-notice-correction\.venv\Scripts\autoclip.exe" doctor
```

If you installed the earlier `v11-no-raw-zip` runtime and see a missing
`cublas64_12.dll` error, close AutoClip and use the updater below. It installs
this release beside the old one and keeps the old runtime available for
rollback. Do not use a source-checkout editable-install command for the
packaged runtime.

## Settings and AI providers

In **Settings**, choose an AI provider and model for highlight selection,
configure its API key where needed, and select a Whisper model and language for
transcription. A separate optional Whisper model can transcribe newly found
clips before Review. You can also set clip length and maximum count, choose a
browser for download cookies, and set the export ratio, audio level, hardware
encoding preference and SRT output. Review offers manual clip
re-transcription. On Windows, **Settings → This machine → Desktop shortcut**
can create or recreate an AutoClip launcher on your desktop, so later starts
do not require a PowerShell window.

The supported provider choices are **Anthropic**, **OpenAI-compatible**,
**Google Gemini**, and **Ollama** (local, no API key). The OpenAI-compatible
base URL may be configured for services such as OpenRouter, Groq and DeepSeek,
or a local LM Studio server. Provider availability, model names and API costs
depend on your account and configuration.

This particular wheel set is Windows only. Linux, macOS and Docker are not
validated by this release; a GitHub test on those platforms cannot turn
Windows native wheels into compatible packages.

## Release contents

`autoclip-windows-py311-v11-20260926-notice-correction-final.zip` contains:

- `wheelhouse/`: 79 exact Python wheels, including the Windows PyAV and
  CTranslate2 replacements and two NVIDIA CUDA 12 runtime wheels.
- `notices-and-source/`: the accompanying license/notice texts, source
  archives, build records, NVIDIA wheel licenses, the cuDNN 9.10.2 terms and
  acknowledgements, and native-file inventory. The exact FFmpeg 8.1.2
  [source archive](https://github.com/Farkoal2128/autoclip-runtime/releases/download/v0.1.0-dev0-windows-v11-20260926-notice-correction/ffmpeg-8.1.2.tar.xz)
  is also a separate release asset; its configuration and build records are
  under `notices-and-source/source-and-build/` inside the ZIP.
- `release-manifest.json`: SHA-256 and size of every packaged file.
- `Start-AutoClip.ps1` and `LICENSE`.

The release archive is fixed to the tag in `install.ps1`. The installer checks
its own pinned archive hash before extracting it. The release source tree on
GitHub is not the installed application; the wheel in the release asset is.

The two NVIDIA wheels are pinned to `nvidia-cublas-cu12==12.4.5.8` and
`nvidia-cudnn-cu12==9.10.2.21`. Their exact wheel hashes, bundled license
texts and DLL inventory are in the release manifest and
`notices-and-source/nvidia-runtime/`. The versioned cuDNN 9.10.2
[acknowledgements](https://docs.nvidia.com/deeplearning/cudnn/backend/v9.10.2/reference/acknowledgements.html)
and [terms](https://docs.nvidia.com/deeplearning/cudnn/backend/v9.10.2/reference/eula.html)
are also preserved in the corrected archive. The wheel's historical
`License.txt` mentions `cudnn64_7.dll`; it is retained unchanged and does
not decide the cuDNN 9 terms. This technical packaging check is not a final
legal clearance of the asset.

## Updating

For application and UI changes on the current verified V11 runtime, close
AutoClip and run the smaller app-only updater:

```powershell
irm https://raw.githubusercontent.com/Farkoal2128/autoclip-runtime/main/update-app.ps1 | iex
```

It verifies the pinned app manifest and AutoClip wheel, reuses the installed
dependency environment without downloading the full runtime archive, checks
health/home in a disposable project home, then selects the new app. The
previous app remains available. To switch back without downloading runtime
dependencies, run:

```powershell
& ([ScriptBlock]::Create((irm https://raw.githubusercontent.com/Farkoal2128/autoclip-runtime/main/update-app.ps1))) -Rollback
```

This app-only command requires the compatible V11 runtime already installed
and selected by the full updater below. If the runtime is missing or its
dependency identity changes, use the full updater. The app-only release is
about 1.7 MB; it does not include the Python/CUDA dependency wheels. A
rollback changes the selected application code, not any project-data schema
migration performed after launch.

For a new dependency runtime or a first managed update, use the full updater:

Close AutoClip, then paste this line into PowerShell:

```powershell
irm https://raw.githubusercontent.com/Farkoal2128/autoclip-runtime/main/update.ps1 | iex
```

The updater downloads the current pinned installer from this repository. It
installs a newer release into its own versioned directory, checks its manifest,
Python 3.11 environment and isolated app health/home, then changes
`%LOCALAPPDATA%\AutoClip\active.json` and the stable launcher. It never
overwrites or removes an older runtime. A rerun on the active release is a
verified no-op. To start the selected runtime from PowerShell:

```powershell
& "$env:LOCALAPPDATA\AutoClip\Start-AutoClip.ps1"
```

If an existing AutoClip desktop shortcut points to a runtime installed under
`%LOCALAPPDATA%\AutoClip`, the updater retargets it after verification.
It warns and leaves a shortcut outside that directory unchanged; recreate that
shortcut from the updated app's Settings if you want it to launch the new
runtime. If an existing managed shortcut identifies a prior runtime, the
updater records it for rollback. Without such a shortcut, you can identify a
prior verified release explicitly with `-PreviousReleaseId` when running
the downloaded script. For an existing `v11` installation:

```powershell
& ([ScriptBlock]::Create((irm https://raw.githubusercontent.com/Farkoal2128/autoclip-runtime/main/update.ps1))) -PreviousReleaseId 'v11'
```

To select the previously recorded runtime again, close AutoClip and run:

```powershell
& ([ScriptBlock]::Create((irm https://raw.githubusercontent.com/Farkoal2128/autoclip-runtime/main/update.ps1))) -Rollback
```

Rollback switches the runtime and managed shortcut; it does not reverse any
project-data migration that might occur after you launch a newer application.
The updater's verification uses a disposable AutoClip home and does not open
your real project database. Project data and settings normally live under
`%USERPROFILE%\.autoclip` (or your configured AutoClip home), separate
from these runtime directories. Do not delete those data folders when
retiring an old runtime.

This updater follows the exact release pinned in `install.ps1`. A future
release must first publish a new asset, then update that installer's release
identifier, URL, archive hash, manifest hash and versioned install path.
`install.ps1 -ReleaseInfo -PrerequisitesOnly` is the updater's local interface:
it returns `ReleaseId`, `ArchiveSha256`, `ManifestSha256` and `ArchiveUrl`
without installing anything. Keep that output accurate when pinning a later
release. The updater downloads one copy of the installer and uses it for both
release selection and installation.

## Maintainer release promotion

1. Build the candidate archive and verify its wheel inventory, manifest,
   required notices, install behavior and review evidence.
2. Publish the immutable tagged GitHub Release asset. Do not replace an older
   published asset or reuse a tag for different bytes.
3. Download the asset through its public release URL without authentication.
   Verify the downloaded ZIP SHA-256 and its `release-manifest.json` SHA-256.
4. Only then change `install.ps1`'s release ID, URL, archive hash and manifest
   hash. A public `main` installer pointing at an unpublished asset is a
   broken release state: the updater will fail with a missing-download error.
5. Run `.github/scripts/verify-public-release.ps1`, the release regression
   checks, a clean Windows install and the updater/rollback smoke. Merge the
   installer-pin change only after those checks pass. CI downloads and hashes
   the public asset on pushes and pull requests that change `install.ps1`.

The verifier checks the exact URL returned by `install.ps1 -ReleaseInfo`.
Publishing a tag alone does not satisfy it; the named public asset must be
downloadable and match both pinned hashes.

## Copyright and attribution

AutoClip includes work from [artbyjazi/autoclip](https://github.com/artbyjazi/autoclip).
The MIT license and **Copyright (c) 2026 Jad Ghazi** notice are preserved
verbatim in [LICENSE](LICENSE) and the packaged AutoClip wheel. Font,
frontend, Python and native dependency notices accompany the release in
`notices-and-source/`. Those components retain their own terms.

## Release status

This versioned notice correction preserves the same 79 wheel bytes as the
app-refresh release while replacing its historical 77-wheel sidecar heading
and adding NVIDIA's versioned cuDNN 9.10.2 reference material. It also
includes the Lavender Mist light theme and local Ollama highlight
diagnostics with a conservative adaptive workload controller. A short paired
local-model run did not establish a speedup or equivalent clip quality; longer
creator evaluation remains open. The earlier creator-accepted CR-09G download
controls and CR-10 optional automatic clip-only transcription remain included.
Export all selected creates only the edited ZIP; previously created
source-resolution ZIP files and their download URLs remain available. Earlier
V11 installations remain separate. The archive SHA-256 pinned in `install.ps1`
is `52a4c6e978f207ecf4bd225e165b6e77a5d8ae04785419821e99cead3014298b`.

The full updater downloads about 1.34 GB when installing this runtime. For
application-only changes on an already installed compatible V11 runtime, the
published CR-11 app-only updater downloads the approximately 1.7 MB AutoClip
wheel instead; see [Updating](#updating). A first install or dependency change
still needs the full runtime archive.

The project owner directed public redistribution of this exact candidate.
The technical audit confirmed file identity and sampled Windows behavior; it
did not certify every nested component license obligation or the distributor's
Microsoft runtime entitlement. Review the accompanying terms before
redistributing or modifying this package. No Linux, macOS or Docker runtime
support is claimed for this release.
