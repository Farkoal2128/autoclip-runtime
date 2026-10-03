# Controlled CPU native artifact, version 1

Requirement: the user's 2026-10-02 IM-DEP research disposition authorizes a new
publisher-built CPU runtime so consumers do not need the native build toolchain.
This artifact supplements the existing installer migration; v40 is unchanged.

## Candidate and ownership

Produce a new immutable Windows x64 CPython 3.11 CPU identity. The candidate
contains the two controlled PyAV 18.1.0 and CTranslate2 4.8.2 wheels, their exact
native/build configuration, producer receipt/provenance, corresponding source
and applicable original notices. It starts `UNQUALIFIED_CANDIDATE`; building or
inventory validation is not distribution/release approval. Never overwrite an
existing output, relabel an older build or silently compile on the consumer.

Reuse the existing native recipe and verifier: FFmpeg 8.1.2 shared libraries
with GPL/nonfree/x264/x265/autodetection disabled; precisely seven FFmpeg DLLs
in PyAV; CTranslate2 uses oneDNN 3.1.1 static, OpenBLAS and compiler OpenMP,
with CUDA/cuDNN/MKL/Intel OpenMP disabled. Native CPU and NVIDIA configurations
have different identities; adding vendor DLLs cannot enable CUDA in this CPU
build. Optional NVIDIA requires its own GPU-capable artifact and receipt.

Preserve exact Python distribution identity: python.org 3.11.9 x64, rather than
an unqualified uv-managed interpreter. uv may create the isolated build/runtime
venv using that verified absolute interpreter, with automatic downloads disabled.
The producer records the actual existing authorized MSVC/SDK/MSYS2/uv/Git/NASM
identities, all source/submodule revisions, build script hashes, source changes,
configuration and output hashes. Producer tools are not consumer prerequisites.

## Distribution boundary

Do not ship Microsoft runtimes/installers, OpenBLAS binaries, NumPy wheels,
NVIDIA payloads, third-party executable build tools or populated vendor caches
inside this native artifact. Their applicable direct recipient routes remain.
Inspect every actual wheel member, DLL/PYD/import, original notice and embedded
library. Retain matching complete source and source modifications/configuration;
document practical replacement/relinking for dynamically linked LGPL FFmpeg.
The publisher route receives a new exact distribution disposition, independent
of prior private recipient-build permission.

The schema1 `native-artifact-manifest.json` binds identity/profile/platform,
exact file rows (path/bytes/SHA256), producer receipt and source associations.
The producer includes actual configuration and provenance. Artifact inputs and
names must reject traversal, reparse escapes, duplicate/case-colliding members,
unexpected binary payloads, substituted build outputs and inconsistent profiles.
All selected wheels must pass their existing ZIP/RECORD/native verifier before
packaging. Retain original evidence with its original hashes.

## Installer acceptance

Only after exact distribution qualification may a new manifest select this
artifact. The protected downloader retains official/publisher source policy,
exact filename/size/hash, redirect constraints, signature checks where required,
verified-cache reuse and corrupt-cache rejection. Build Tools/SDK/MSYS2/native
Git/build-wheel acquisition is absent from this consumer route. Required runtime
dependencies remain explicit. Missing/corrupt native input fails before activation;
there is no recipient-build fallback. Existing v40 remains a separate route.

Test exact Inno installation on clean Windows without the development toolchain:
ordinary-user imports, media decode, CPU int8 transcription, health/render,
notices, download/failure/retry, upgrade/rollback and reinstall. Test the exact
generated uninstaller after installation is ready, preserving user data/shared
prerequisites. Freeze and review final binary/artifact/manifest evidence before
promotion. Unperformed NVIDIA hardware tests remain explicitly deferred.
