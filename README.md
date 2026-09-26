# AutoClip Windows runtime

This repository distributes the Windows runtime build of AutoClip. It contains
the installer, launch script, copyright license and release checks. The
versioned release asset contains the AutoClip wheel, its 76 Python dependency
wheels, and a source/notice supplement. Development research, plans, skills,
tests and roadmap files are not part of this repository.

## Install

This release supports **Windows x64 and Python 3.11**. Install [uv](https://docs.astral.sh/uv/getting-started/installation/),
then download `install.ps1` from the tagged release or this repository, inspect
it, and run it in PowerShell:

```powershell
powershell -ExecutionPolicy Bypass -File .\install.ps1
```

The script downloads the pinned release archive, checks its SHA-256, verifies
every packaged file, creates a Python 3.11.16 environment and installs all
Python packages without fetching dependencies from the network. It installs
under `%LOCALAPPDATA%\AutoClip\v11` by default. It will not overwrite an
existing directory. The release archive is about 250 MiB.

After installation:

```powershell
& "$env:LOCALAPPDATA\AutoClip\v11\Start-AutoClip.ps1"
```

AutoClip then opens locally at `http://127.0.0.1:8000`. You must supply
`ffmpeg` and `ffprobe` with `libass` and `libx264` separately. Ollama and
model weights are optional external installations for local AI operation;
hosted providers use your own configured credentials. The release asset does
not contain these external tools or models.

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
