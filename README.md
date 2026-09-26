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
& ([scriptblock]::Create((Invoke-RestMethod 'https://raw.githubusercontent.com/Farkoal2128/autoclip-runtime/main/install.ps1')))
```

The command runs this repository's current installer directly from GitHub.
Review [install.ps1](install.ps1) before running it if you prefer. The installer
uses Windows Package Manager (`winget`) to install missing `uv` and a full
FFmpeg/ffprobe build, and checks that FFmpeg has `libass` and `libx264`. It
installs Python 3.11.16 through `uv`, downloads the pinned release archive,
checks its SHA-256 and every packaged file, then installs all 77 Python wheels
offline. It installs under `%LOCALAPPDATA%\AutoClip\v11` by default and will
not overwrite an existing installation. The release archive is about 250 MiB.
Windows Package Manager (Microsoft App Installer) must be available if a tool
is missing. The installer may prompt for system permission or package terms.

After installation:

```powershell
& "$env:LOCALAPPDATA\AutoClip\v11\Start-AutoClip.ps1"
```

AutoClip then opens locally at `http://127.0.0.1:8000`. To install optional
Ollama for local AI in the same pass, append `-InstallOllama` to the one-line
command. You must still choose and pull a local model with `ollama pull
<model>`; model weights are not in the release. Hosted providers use your own
configured credentials. The release asset contains none of these external
tools or models.

## Settings and AI providers

In **Settings**, choose an AI provider and model for highlight selection,
configure its API key where needed, and select a Whisper model and language for
transcription. A separate optional Whisper model can transcribe newly found
clips before Review. You can also set clip length and maximum count, choose a
browser for download cookies, and set the export ratio, audio level, hardware
encoding preference and SRT output. Review offers manual clip
re-transcription.

The supported provider choices are **Anthropic**, **OpenAI-compatible**,
**Google Gemini**, and **Ollama** (local, no API key). The OpenAI-compatible
base URL may be configured for services such as OpenRouter, Groq and DeepSeek,
or a local LM Studio server. Provider availability, model names and API costs
depend on your account and configuration.

This particular wheel set is Windows only. Linux, macOS and Docker are not
validated by this release; a GitHub test on those platforms cannot turn
Windows native wheels into compatible packages.

## Release contents

`autoclip-windows-py311-v11.zip` contains:

- `wheelhouse/`: 77 exact Python wheels, including the Windows PyAV and
  CTranslate2 replacements.
- `notices-and-source/`: the accompanying license/notice texts, source
  archives and build records.
- `release-manifest.json`: SHA-256 and size of every packaged file.
- `Start-AutoClip.ps1` and `LICENSE`.

The release archive is fixed to the tag in `install.ps1`. The installer checks
its own pinned archive hash before extracting it. The release source tree on
GitHub is not the installed application; the wheel in the release asset is.

## Copyright and attribution

AutoClip includes work from [artbyjazi/autoclip](https://github.com/artbyjazi/autoclip).
The MIT license and **Copyright (c) 2026 Jad Ghazi** notice are preserved
verbatim in [LICENSE](LICENSE) and the packaged AutoClip wheel. Font,
frontend, Python and native dependency notices accompany the release in
`notices-and-source/`. Those components retain their own terms.

## Release status

The project owner directed public redistribution of this exact candidate.
The technical audit confirmed file identity and sampled Windows behavior; it
did not certify every nested component license obligation or the distributor's
Microsoft runtime entitlement. Review the accompanying terms before
redistributing or modifying this package. No Linux, macOS or Docker runtime
support is claimed for this release.
