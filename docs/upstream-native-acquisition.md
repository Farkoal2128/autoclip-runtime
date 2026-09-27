# Upstream native acquisition for the next Windows runtime

Status: unpublished 75-wheel source-build candidate technically validated on
one Windows machine, 2026-09-26. The published V11 ZIP and its installer pin
are unchanged. A new runtime identity and asset are required;
the old archive cannot be described as source-installed because its wheels
already contain the native files below.

## Required routing

| Component in the current release | New recipient-side route | Release requirement |
| --- | --- | --- |
| `VCOMP140.DLL` inside the controlled CTranslate2 wheel | Remove it from the published wheel. Install Microsoft's x64 Visual C++ Redistributable from a pinned Microsoft download, then verify the system DLL and CTranslate2 CPU inference. | Confirm the Microsoft package actually supplies the required OpenMP DLL on a clean Windows target. Record the Microsoft installer hash and version; do not copy its DLL into the AutoClip asset. |
| NVIDIA cuBLAS 12.4.5.8 and cuDNN 9.10.2.21 wheels | Omit both wheels from the AutoClip asset. Download their exact Windows wheels from NVIDIA's PyPI publications into an isolated staging directory and verify filename, size and SHA-256 before installation. | Preserve the NVIDIA terms and acknowledgements at the user-facing installation location. Test GPU inference and loader discovery. |
| OpenBLAS DLL inside the controlled CTranslate2 wheel | Fetch the exact official OpenBLAS v0.3.30 Windows release from OpenMathLib and verify both the archive and `bin/libopenblas.dll` hashes before placing it next to `ctranslate2.dll`. | The v5 local candidate omits it from the modified wheel and sidecar; CPU and GPU probes pass. Exact published-asset review remains. |
| FFmpeg DLLs inside the controlled PyAV wheel | User selected recipient-side compilation. Omit PyAV from the AutoClip ZIP; fetch the pinned FFmpeg 8.1.2 and PyAV 18.1.0 source archives, build codec-free FFmpeg with MSVC/MSYS2, then build and repair the local PyAV wheel. | Verify the built FFmpeg configuration excludes GPL, nonfree, x264 and x265; run PyAV decode and check the locally built wheel and bundled DLLs before activation. |
| oneDNN 3.1.1 inside `ctranslate2.dll` | User selected recipient-side compilation. Omit CTranslate2 from the AutoClip ZIP; fetch the exact oneDNN and CTranslate2 Git commits and build oneDNN static plus CTranslate2 locally with CUDA, OpenBLAS and compiler OpenMP. | Verify exact source commits, native imports, CPU int8 and GPU float16 inference; fail the install before activation if any build or probe fails. |

## Install and update contract

The new versioned asset must contain only the application, dependency wheels
still delivered by AutoClip, and their notices/source. Its manifest must list
every packaged byte and an external-assets section with exact publisher URLs,
filenames, sizes and SHA-256 values. The installer must reject changed or
missing external assets, use temporary staging, verify wheel `RECORD` and ZIP
integrity, and leave the active runtime and rollback state untouched on failure.
The first install needs network access to the publishers; an explicit local
cache option may support offline installation only after the same verification.
The updater must retain the old runtime under its old ID, install and probe the
new one side by side, then switch activation. The CR-11 app-only compatibility
pin must be extended only after the new runtime passes its own checks.

Changing the host of a binary does not determine its license obligations.
Review the actual new wheels, build outputs, applicable notices and recipient
workflow as new assets before claiming CR-09 distribution clearance.

## Recipient source-build candidate

The local 75-wheel candidate omits both native wheels. Its build script requires
Visual Studio 2022 C++ Build Tools, MSYS2 with NASM, CUDA toolkit 12.8, and
Python 3.11. The FFmpeg archive and PyAV sdist have pinned sizes and SHA-256;
oneDNN and CTranslate2 are checked out at exact Git commits. The script builds
in an isolated root and produces wheels for the installer's external
wheelhouse. CTranslate2 uses CUDA dynamic loading so CPU imports do not
require a CUDA DLL, and includes `sm_120` for the currently tested GPU.
The old 77-wheel local candidate remains historical technical
evidence; its prebuilt PyAV and CTranslate2 members do not satisfy the user's
recipient-build choice. The v11 local candidate includes the versioned cuDNN
9.10.2 documents and passed a fresh isolated install with integrity checks
of all 79 wheel ZIPs and 9,296 `RECORD` rows, dependency and PyAV/CTranslate2
CPU/CUDA capability checks. The v10 predecessor passed health/home, MP4/AAC
decode and tiny-model CPU/GPU inference on the prepared Windows machine;
its v9 predecessor passed updater receipt and
rollback/reselection checks. Public release still requires
clean-machine prerequisite/download checks and independent exact-delivery
review.
The local candidate installer is `install-source-build.ps1`; it takes an exact
`-ArchivePath`, and can take `-MsysBash`, `-CudaRoot`, `-ExternalCache` and
`-NativeBuildRoot` for a prepared Windows toolchain and resumable builds.
For the next candidate, the default source build is CPU capable without CUDA
or NVIDIA runtime wheels. Pass `-InstallNvidiaGpu` to the installer or updater
to request the CUDA 12.8 build and NVIDIA runtime wheels; `-CudaRoot` selects
the toolkit if `CUDA_PATH` is unavailable. CPU and NVIDIA native build caches
and receipts use separate profiles. AMD cards use the CPU path pending a
separately designed and verified AMD acceleration backend.
`update.ps1` forwards those options and leaves the old active runtime in
place until the new install and isolated health/home check succeed. The
public `install.ps1` remains pinned to the existing reviewed artifact.
