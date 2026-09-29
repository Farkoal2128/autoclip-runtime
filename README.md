# AutoClip Windows runtime

This repository contains the Windows installer, updater, source-build recipe, and release metadata for [AutoClip](https://github.com/Farkoal2128/myAutoclip). The current release is [source-build v40](https://github.com/Farkoal2128/autoclip-runtime/releases/tag/v0.1.0-dev0-windows-source-v40-20260928). It supports Windows x64 and Python 3.11. CPU is the default; NVIDIA GPU support is optional.

## Install

Review [install.ps1](install.ps1), then run it from PowerShell:

```powershell
irm https://raw.githubusercontent.com/Farkoal2128/autoclip-runtime/main/install.ps1 | iex
```

The installer downloads the pinned 173,196,134-byte release ZIP, checks its SHA-256 and manifest, acquires required publisher inputs directly, and builds the native runtime on this Windows machine. It checks or provisions Python, FFmpeg tooling, Microsoft C++ Build Tools, and the Windows SDK as needed. It presents applicable prerequisite terms to the person installing. Allow time and disk space for the local build. The archive is a source-build package, not a prebuilt CUDA bundle.

To request the optional NVIDIA profile, use the installer's `-InstallNvidiaGpu` switch after reviewing its terms and prerequisites:

```powershell
$installer = irm https://raw.githubusercontent.com/Farkoal2128/autoclip-runtime/main/install.ps1
& ([ScriptBlock]::Create($installer)) -InstallNvidiaGpu
```

NVIDIA CUDA/cuBLAS inputs are acquired directly by the recipient under their applicable terms. AutoClip does not bundle, mirror, or distribute populated shared-cache copies of Microsoft or NVIDIA prerequisites. A supported NVIDIA driver is needed for GPU inference. CPU installation does not require the NVIDIA profile.

The default versioned install directory is under `%LOCALAPPDATA%\AutoClip`. The installer prints its exact launch command on success. `install.ps1 -ReleaseInfo` reports the public release ID, URL, archive digest, and manifest digest without installing. A completed installation is kept separate from earlier versions.

## Update and rollback

The [full updater](update.ps1) stages a new runtime beside the current one and changes the active selection only after verification. The [app-only updater](update-app.ps1) can use the separate [CR-11 application wheel](https://github.com/Farkoal2128/autoclip-runtime/releases/tag/v0.1.0-dev0-windows-app-20260926-cr11) with an exact compatible runtime; it does not need to download or rebuild runtime dependencies for a valid compatible install. Both updaters retain a verified previous selection for rollback. Consult [the update architecture](docs/runtime-update-architecture.md) before changing release pins or cleanup behavior.

For a managed full update after closing AutoClip:

```powershell
irm https://raw.githubusercontent.com/Farkoal2128/autoclip-runtime/main/update.ps1 | iex
```

For a compatible app-only update:

```powershell
irm https://raw.githubusercontent.com/Farkoal2128/autoclip-runtime/main/update-app.ps1 | iex
```

Project media, exports, settings, and credentials are outside managed runtime cleanup.

The newer [CH application source handoff](docs/ch-runtime-readiness.md) adds a
Pillow base dependency absent from v40. It is not yet a published app-only
update for v40; its runtime successor is being prepared separately.

## Releases and historical versions

| Route | Status |
|---|---|
| [Windows source-build v40](https://github.com/Farkoal2128/autoclip-runtime/releases/tag/v0.1.0-dev0-windows-source-v40-20260928) | Current Windows release; CPU default, optional NVIDIA. |
| [CR-11 app-only](https://github.com/Farkoal2128/autoclip-runtime/releases/tag/v0.1.0-dev0-windows-app-20260926-cr11) | Separate application wheel for exact compatible runtimes. |
| [Archived V11 releases](docs/archive/releases.md) | Historical assets retained for installed users, rollback, and provenance; no longer the new-install route. |

The reviewed v40 ZIP SHA-256 is `f2b3be779294bc55d6f5f56c2a780a2d6b863486f3af9bd7d19f30051961fc9f`; its internal `release-manifest.json` SHA-256 is `7fbf72038be30522bc176002082fddd92fd4e057159765726e77806a296658e2`. The [CR-09 publication record](https://github.com/Farkoal2128/myAutoclip/blob/main/docs/features/creator-ready-delivery/cr09-v40-publication-checkpoint.md) lists the bounded Windows checks and the historical release-event CI correction. Linux and macOS runtime support remain unqualified.

## Repository layout

The repository root is intentionally limited to the stable public entrypoints and high-level project folders:

- `install.ps1`, `update.ps1`, `update-app.ps1`, `Start-AutoClip.ps1`, and `app-release.json` keep their stable public locations.
- `release/scripts/` contains source-build installers, prerequisite helpers, cache tooling, and native-build recipes that are packaged into release artifacts.
- `release/manifests/` contains repository-side publisher/source input manifests.
- `release/review/` contains hash-bound review rules, third-party review material, and component evidence used by successor builds.
- `scripts/` contains release-construction and audit tooling; `.github/` contains CI and release checks; `tests/` contains local prerequisite tests; `docs/` contains architecture, acquisition, and historical release records.

Generated source-build archives keep their established root-level filenames. The release tooling resolves those logical names from `release/`, so this repository cleanup does not change the published v40 asset, public installer pins, or installed layout.

The Git tag for v40 preserves the published source snapshot. A later `main` commit corrected the app-manifest digest expected by the public updater; use the current `main` updater. The ZIP asset and its reviewed bytes did not change.

## Copyright and source

AutoClip incorporates work from [artbyjazi/autoclip](https://github.com/artbyjazi/autoclip). Its MIT notice is in [LICENSE](LICENSE). Dependency notices and corresponding source material accompany the versioned release asset. Recipients should review the applicable publisher terms before acquiring third-party prerequisites.
