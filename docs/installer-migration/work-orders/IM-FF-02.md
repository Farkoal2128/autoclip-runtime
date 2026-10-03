# IM-FF-02 — Exact FFmpeg essentials recipient route

Reviewed 2026-10-01. This is a same-session internal evidence investigation,
not a blinded final setup review, legal opinion, actor-rights decision, or
publication approval. Only this report is owned by this work order. No manifest,
installer, application, native-build recipe, host installation, VM, or release
was changed. Scratch extraction and a generated media probe are described below.

## Recommendation and present disposition

Select the exact official **Gyan 9.0.1 essentials ZIP** for the proposed
recipient-owned FFmpeg CLI route. It supplies the required `ass` filter,
`libx264` encoder, and FFprobe, proven with these exact local executables. Acquire
the ZIP from the publisher's pinned GitHub release, verify it before extraction,
keep its `LICENSE` and `README.txt` accessible to the recipient, and run the CLI
as a separate subprocess. Preserve the codec-free FFmpeg/PyAV source-build route.

The evidence supports that bounded recipient acquisition and unmodified CLI
execution route. It does **not** support AutoClip bundling, mirroring, a populated
redistributed tool cache, or claiming complete supplier source/notice compliance.
The current dependency manifest still selects the full ZIP and is `BLOCKED`;
this report does not edit or automatically reclassify that entry. The exact
essentials route needs a new manifest selection and actual guarded wizard
qualification before it becomes an installable setup input.

## Inspected identities

The live [publisher release API](https://api.github.com/repos/GyanD/codexffmpeg/releases/tags/9.0.1)
lists the essentials asset as `uploaded`, with the size and digest below. Local
hashes were recomputed independently of the supplied work-order pin.

| Object | Bytes | SHA-256 |
| --- | ---: | --- |
| `ffmpeg-9.0.1-essentials_build.zip` | 111,253,802 | `fec81ae03971d9dd4be3ebe02e263bd2ec1d789483f931bdba5f5715e65da2e9` |
| `bin/ffmpeg.exe` | 102,856,192 | `72a489eccd008c2ec2c0a5856c5c75bc3d8bbfa90166c4566865c246445e6aa3` |
| `bin/ffprobe.exe` | 102,652,416 | `19202b23c0043f15ad1b7bce2344f406fd52bd6efd8f995ce02e7392a1cec52f` |
| `bin/ffplay.exe` | 104,339,968 | `39a9ba4f207fe9eecfb094e632998c29e1da88a5d5d23d0b8b71a357a7c47eb5` |
| `LICENSE` | 35,147 | `8ceb4b9ee5adedde47b31e975c1d90c73ad27b6b165a1dcd80c7c545eb65b903` |
| `README.txt` | 41,650 | `1c8c50e4df1623673ec236bafe774f3c4ee41a1e6b0cde05e31b7d89b31efa06` |

Local archive:
`D:\AutoClip-Inno-Migration\ffmpeg-9.0.1-essentials_build.zip`.
Publisher URL:
`https://github.com/GyanD/codexffmpeg/releases/download/9.0.1/ffmpeg-9.0.1-essentials_build.zip`.
Observed HTTPS HEAD redirect: `github.com` →
`release-assets.githubusercontent.com`, HTTP 302 then 200, final content length
111,253,802. This is an observed publisher delivery chain, not a test of the
wizard's redirect rejection or download implementation.

All 49 members passed Python `ZipFile.testzip()` CRC validation: 45 regular files
and four directory entries, 321,521,840 uncompressed bytes. The regular files
are three EXEs, 40 generated documentation/CSS files, `LICENSE`, and `README.txt`.
No DLL, source archive, library-specific license file, or build script is present.
Every member's size and SHA-256 was inspected. A reproducible inventory digest is
`15a00c7a33f0bd9bfa286421e02ac4b6a9dbeb10904dabd0c53d0305f309a4a0`:
sort rows by member path; each row has `path`, `bytes`, and `sha256`; serialize
the array as JSON with sorted keys, separators comma/colon, then one LF, UTF-8.

Authenticode inspection of `ffmpeg.exe` returned `NotSigned`. A publisher
signature requirement cannot be assumed satisfied; this route uses the exact
official publisher digest and extracted executable hashes as its recorded
identity evidence.

## Executed capability checks

Only the two audited EXEs were extracted to
`D:\AutoClip-Inno-Migration\ffmpeg-essentials-audit`; they were not installed or
placed on system PATH. These commands returned success:

- `ffmpeg.exe -version`: `9.0.1-essentials_build-www.gyan.dev`, GCC 16.1.0
  Rev2 from MSYS2. Configuration includes `--enable-gpl`, `--enable-version3`,
  `--enable-static`, `--enable-libass`, and `--enable-libx264`. It also enables
  x265 and numerous other libraries. No `--enable-nonfree` appears.
- `ffmpeg.exe -hide_banner -filters`: actual `ass` and `subtitles` filters.
- `ffmpeg.exe -hide_banner -encoders`: actual `libx264` and native AAC encoder.
- `ffprobe.exe -version`: matching 9.0.1 essentials identity/configuration.
- In the scratch directory, a generated 320×180 black video and 440 Hz sine
  audio, each one second long, were rendered with a locally authored ASS file:
  `ffmpeg.exe -y -hide_banner -f lavfi -i color=c=black:s=320x180:r=10:d=1 -f lavfi -i sine=frequency=440:duration=1 -vf ass=probe.ass -c:v libx264 -pix_fmt yuv420p -c:a aac -shortest probe.mp4`.
  Exit 0. Libass reported exact source commit
  `89cc0f4e450d64f74281a17d7f11ed05229665e8`; x264 reported core 165, r3223,
  revision `0480cb0`. FFprobe decoded the container metadata as H.264 video,
  AAC audio, 320×180, duration 1.000000 seconds. Output: 12,424 bytes, SHA-256
  `b3d77a072a7c962b52aa5fb8854ce4d1a84737759a4d1ed99c29734b0cd5dcba`.
- Decoding its first video frame to RGB24 produced exactly 172,800 bytes with
  4,002 nonzero color samples, confirming rendered text on the black source.

This proves the requested CPU CLI features on this prepared Windows host.
No AutoClip install, clean-VM run, transcription, human audio listening,
GPU inference, or end-to-end wizard check occurred.

The application hint in `src/backend/autoclip/cli.py:54` says Gyan Essentials
omits libass. That statement is false for this exact 9.0.1 archive. The runtime
source builder's errors also suggest a full build, but its actual checks require
the ASS filter and libx264 rather than the full variant name. No hint was edited.

## Delta from the previously inspected full ZIP

The existing full ZIP was independently rehashed again:
251,427,729 bytes, SHA-256
`2e8e28af97c2ae338ccef92e36da9b2a4cd21d0cad9dde093545606cb07f5b00`.
The essentials ZIP is 140,173,927 bytes smaller. Its FFmpeg executable is
119,373,312 bytes smaller. Comparing the two exact README configuration
sections gives 42 general external libraries and 13 hardware-interface entries
for essentials, versus 83 and 15 for full. Every essentials general-library
entry is also listed by full. These are producer configuration declarations,
not an independently reconstructed complete static-link SBOM.

The 41 general libraries present only in full are chromaprint, frei0r, ladspa,
lcms2, libaribb24, libaribcaption, libbluray, libbs2b, libcaca, libcdio,
libcodec2, libdav1d, libdavs2, libdvdnav, libdvdread, libflite, libilbc, libjxl,
liblc3, liblensfun, libmodplug, libmysofa, liboapv, libplacebo, libqrencode,
libquirc, librav1e, librist, libshine, libsnappy, libsoxr, libsvtav1,
libsvtjpegxs, libtwolame, libuavs3d, libvvenc, libxavs2, libxevd, libxeve,
libzvbi, and whisper. Narrower packaging does not establish a libass/x264-only
binary or close the remaining linked-library evidence.

## Exact source and notice mapping inspected

| Component | Exact source/notice evidence | What this establishes and leaves open |
| --- | --- | --- |
| FFmpeg core | README and release point to [commit `bf1b838f2ab88b4f8fd83443325c782ea0e0f7fa`](https://github.com/FFmpeg/FFmpeg/commit/bf1b838f2ab88b4f8fd83443325c782ea0e0f7fa). Its [COPYING.GPLv3](https://raw.githubusercontent.com/FFmpeg/FFmpeg/bf1b838f2ab88b4f8fd83443325c782ea0e0f7fa/COPYING.GPLv3) was fetched and exactly matches the ZIP's 35,147-byte LICENSE/hash. | Exact license text and asserted core source revision. No independent rebuild, proof of absence of patches, or complete corresponding-source closure. |
| libass | Runtime reports `89cc0f4e450d64f74281a17d7f11ed05229665e8`, agreeing with README `0.17.5-3-g89cc0f4`. Exact upstream [COPYING](https://raw.githubusercontent.com/libass/libass/89cc0f4e450d64f74281a17d7f11ed05229665e8/COPYING), 755 bytes, SHA `f7e30699d02798351e7f839e3d3bfeb29ce65e44efa7735c225464c4fd7dfe9c`, is ISC. | Source-level use/copy/distribution permission with copyright/permission notice retention. This notice is absent as a separate file in the publisher ZIP; nested copyright/notice fulfillment was not proved. |
| x264 | Runtime reports r3223, `0480cb0`, agreeing with README `v0.165.3223`. The official VideoLAN source [COPYING at that revision](https://code.videolan.org/videolan/x264/-/raw/0480cb0/COPYING) is GPLv2, 17,992 bytes, SHA `32b1062f7da84967e7019d01ab805935caa7ab7321a7ced0e30ebe75e5df1670`. Exact [x264.c](https://code.videolan.org/videolan/x264/-/raw/0480cb0/x264.c) header expressly permits GPLv2 or later. | Supports the GPL licensing route for this declared revision; commercial licensing is an upstream alternative, not evidence supplied here. No source-to-static-object reconstruction. |

The README's full external-version declaration is preserved below for review
traceability. Apart from FFmpeg, libass, and x264 above, these declared revisions
were not individually checked against exact upstream notice texts or build
objects. A version string is not a verified license disposition.

```text
AMF v1.5.2-2-gc35f613             aom v3.14.1-147-gec0dedc1a2
AviSynthPlus v3.7.5-362-gf4628d0a cairo 1.18.5
ffnvcodec n13.1.15.0-1-geddcea9   fontconfig 2.18.3
freetype VER-2-14-3              fribidi v1.0.16-5-g069a7e3
gmp 6.3.0-2                     gnutls 3.8.13-1
gsm 1.0.24                      harfbuzz 14.3.0-10-g9f2f0317
lame 3.100                      libass 0.17.5-3-g89cc0f4
libgme 0.6.6                    libiconv 1.19-1
libopencore-amrnb 0.1.6          libopencore-amrwb 0.1.6
libssh 0.12.0                   libtheora v1.2.0
libwebp v1.6.0-199-g94d3c4a      libxml2 v2.15.0-122-gddcb79dc
openAL 1.25.2                   openjpeg 2.5.4
openmpt libopenmpt-0.6.28-40-gefc11a27
opus v1.6.1-50-g3da9f7a6         rubberband v4.0.0
SDL release-2.32.0-228-ga2e7c76bd speex Speex-1.2.1-51-g0589522
srt v1.5.6-2-gfcae571            VAAPI 2.25.0.
vidstab v1.1.2-105-gc7a720a      vmaf v3.2.0-9-g4991d2b5
vo-amrwbenc 0.1.3               vorbis v1.3.7-37-g1b75110b
VPL 2.17                        vpx v1.16.0-184-g0cfc6da39
x264 v0.165.3223                x265 4.3-6-g9ddc216
xvid v1.3.7                     zeromq 4.3.5
zimg release-3.0.6-252-gf6cc75a
```

The general external-library configuration additionally names bzlib, lzma,
zlib, and mediafoundation without matching explicit versions in this version
section. The hardware section additionally lists CUDA/LLVM, CUVID, NVDEC,
NVENC, DXVA2, D3D11VA, D3D12VA, and libmfx without a complete version map.
Transitive libraries/toolchain objects may also exist; this is not complete
incorporation proof.

## Maintainer source/build publication

At release repository tree `46465995c991fe65c5de853fa79bddec09cd6c37`, the
publisher repository contains only README and `.github/FUNDING.yml`; it is a
[support and release mirror](https://raw.githubusercontent.com/GyanD/codexffmpeg/master/README.md),
not the complete build-source repository. The exact release contains binary
archives and points to FFmpeg core source. The ZIP gives configuration and
external versions. No complete source/build bundle or exact linked-component
source manifest was found in those inspected release locations.

Historical maintainer comments identify the MSYS2/MinGW GCC/GNU toolchain
([issue 91](https://github.com/GyanD/codexffmpeg/issues/91#issuecomment-1474806731))
and recommend media-autobuild_suite when asked for a build script
([issue 25](https://github.com/GyanD/codexffmpeg/issues/25#issuecomment-896110133)).
Those comments are not an exact 9.0.1 build recipe or proof that an arbitrary
suite checkout reproduces these binaries. Absence in these inspected locations
does not prove source is unavailable through every possible upstream channel.

## Is missing top-level source a recipient-use gate?

The project's Windows wheel requirement explicitly excludes the separately
supplied CLI from the codec-free PyAV wheel constraint. It requires an installed
index for acquired components, notices, and corresponding source **where
required**. The draft setup contract separately permits approved official direct
recipient download, retains licensing review, and forbids `BLOCKED` acquisition.
Neither inspected policy explicitly imposes AutoClip redistributor source-hosting
obligations on a recipient merely running a publisher-acquired CLI.

The exact shipped GPLv3 text distinguishes unmodified execution from conveyance
in sections 0, 2, 6, 9 and 10. Its execution/receipt provisions do not condition
running the program on downloading a corresponding-source package or accepting
a separate GPL click-through. Section 6 addresses object-code conveyance;
section 10 does not make recipients enforce others' compliance. The wizard still
needs the project's explicit download decision and accessible terms. This is a
reading of the inspected text, not an actor-specific legal conclusion.

[FFmpeg's checklist](https://ffmpeg.org/legal.html) expressly concerns LGPL
compliance when linking FFmpeg libraries. Applying that checklist mechanically
to the GPL CLI subprocess route would conflate two reviewed operations. In
particular it cannot justify disabling GPL/x264 in this separate CLI while
claiming the required libx264 behavior remains available.

Therefore, a blanket rule that **AutoClip must first publish complete Gyan
corresponding source before a recipient can run the downloaded CLI** is not
established by the inspected policy/text. Supplier corresponding-source and
static-library notice closure remains unresolved evidence. It matters for any
supplier-compliance conclusion and for a proposed AutoClip redistribution route;
it is not automatically the same gate as this recipient's unmodified CLI use.
No conclusion about patents, actual actor authority, or supplier entitlement is
made. Preserve every earlier full-build, PyAV, v40, and component review at its
original scope.

## Finite work before the route is installable

1. Select essentials as a new exact manifest input, with the ZIP and extracted
   executable pins above, licensing evidence, recipient notice/source entry
   point, approved HTTPS hosts, and explicit no-AutoClip-redistribution scope.
   Do not change the published PyAV source recipe or silently inherit the full
   variant's metadata. Retain incomplete supplier component mapping explicitly;
   do not call it complete static-library licensing clearance.
2. Implement the guarded recipient download/extraction path, preserve the
   original license/readme, verify selected EXE hashes and capabilities, and
   pass the absolute verified tool directory through the source-builder and
   final ordinary-user launcher. Archive/version presence alone is insufficient.
3. Run the real missing-FFmpeg wizard branch on clean Windows and exercise
   decline/cancel, wrong hash, wrong host/redirect, missing ASS/libx264/FFprobe,
   retry, and the installed media check. This report's local curl/Python probe
   does not satisfy those gates.

If a future operation conveys the EXEs through AutoClip or introduces library
linking, open a new operation-specific review for exact corresponding source,
build scripts, nested notices, and applicable rights. That work is outside this
bounded route recommendation. Other CPU prerequisite, final setup inventory,
lifecycle, human, legal, and publication gates remain independently owned.

## Policy snapshot inspected

| Input | SHA-256 at inspection |
| --- | --- |
| `docs/installer-migration/contract-v1.md` | `b49df2081c88e02d2d4d1c4a98fa165ddb76f66175aeb7d1e0e4ada30ff5dbfb` |
| `release/manifests/installer-dependencies-v1.json` | `718ffe5cac1ee18e97fac3775853f2d46f060fe9c8dcdfde739e677b6854c99d` |
| `docs/upstream-native-acquisition.md` | `df2e66a4b569bc8c5c76b4d14865787f63bbc6deda8bb1b1da97d4483de6a232` |
| MyAutoClip `docs/requirements/windows-wheel-distribution.md` | `66a022245ce83e4edd5cc1e0e69c3a40794bc4033762af7edf65f4f80e2831ea` |

These inputs are mutable working-tree documents. Their hashes delimit this
investigation; they do not identify an immutable final setup candidate.
