# AutoClip Windows runtime

This repository distributes the Windows runtime build of AutoClip. It contains
the installer, launch script, copyright license and release checks. The
versioned release asset contains the AutoClip wheel, its 76 Python dependency
wheels, and a source/notice supplement. Development research, plans, skills,
tests and roadmap files are not part of this repository.

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
installs Python 3.11.16 through `uv`, downloads the pinned release archive,
checks its SHA-256 and every packaged file, then installs all 77 Python wheels
offline. It installs under `%LOCALAPPDATA%\AutoClip\v11-cr09g-cr10` by default and will
not overwrite an existing installation. The release archive is about 250 MiB.
Windows Package Manager (Microsoft App Installer) must be available if a tool
is missing. The installer may prompt for system permission or package terms.

After installation:

```powershell
& "$env:LOCALAPPDATA\AutoClip\v11-cr09g-cr10\Start-AutoClip.ps1"
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

`autoclip-windows-py311-v11-cr09g-cr10.zip` contains:

- `wheelhouse/`: 77 exact Python wheels, including the Windows PyAV and
  CTranslate2 replacements.
- `notices-and-source/`: the accompanying license/notice texts, source
  archives and build records.
- `release-manifest.json`: SHA-256 and size of every packaged file.
- `Start-AutoClip.ps1` and `LICENSE`.

The release archive is fixed to the tag in `install.ps1`. The installer checks
its own pinned archive hash before extracting it. The release source tree on
GitHub is not the installed application; the wheel in the release asset is.

## Updating

The one-paste command installs the pinned CR-09G/CR-10 V11 refresh only. Running it again
against an existing `%LOCALAPPDATA%\AutoClip\v11-cr09g-cr10` directory stops with an
"Install path already exists" message; it does not update in place. There is
no separate updater in this release. A future version needs a new release
asset, a new pinned archive hash in its installer, and an install path for that
version. Install and verify that version before retiring the old runtime, then
recreate the desktop shortcut from the new app. Project data and settings
normally live separately under `%USERPROFILE%\.autoclip` (or your configured
AutoClip home/storage location), so do not delete those folders when replacing
a runtime installation.

## Copyright and attribution

AutoClip includes work from [artbyjazi/autoclip](https://github.com/artbyjazi/autoclip).
The MIT license and **Copyright (c) 2026 Jad Ghazi** notice are preserved
verbatim in [LICENSE](LICENSE) and the packaged AutoClip wheel. Font,
frontend, Python and native dependency notices accompany the release in
`notices-and-source/`. Those components retain their own terms.

## Release status

This refresh includes the creator-accepted CR-09G download activity, ETA,
cancel and debug controls, and the creator-accepted CR-10 optional automatic
clip-only transcription before Review. The earlier V11 installation remains
separate. These creator verdicts apply to the reviewed Windows experience;
they do not certify every download condition or model pairing. The archive
SHA-256 pinned in `install.ps1` is
`d4643ec767c492c456bc0141b89c284a2174ca8df7edce5cb2a33a00a42e2bfd`.

The project owner directed public redistribution of this exact candidate.
The technical audit confirmed file identity and sampled Windows behavior; it
did not certify every nested component license obligation or the distributor's
Microsoft runtime entitlement. Review the accompanying terms before
redistributing or modifying this package. No Linux, macOS or Docker runtime
support is claimed for this release.
