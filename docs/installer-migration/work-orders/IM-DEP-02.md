# IM-DEP-02: consumer alternative to recipient native compilation

Date: 2026-10-02. Read-only contract reviewer assignment under the user's request
to clear dependencies or choose a consumer-better alternative. Root integrates
this decision; no artifact or runtime identity has been changed by this record.

## Chosen route for qualification

Build the controlled CPU native profile once on the publisher's authorized
build machine, then deliver a newly identified immutable native artifact.
Retain exact controlled PyAV/FFmpeg and CTranslate2/oneDNN configuration; keep
Microsoft runtime, OpenBLAS, NumPy and optional NVIDIA on their existing direct
recipient routes. Existing v40 compatibility and historical approvals retain
their original scope. GPU testing remains explicitly deferred.

This could eliminate recipient Build Tools/SDK, MSYS2/NASM, native Git checkout
and build-wheel installation. It still requires Python, application packages,
FFmpeg CLI and runtime prerequisites, with appropriate consent/integrity and
capability checks. It is a candidate architecture, not a qualified release.

Recipient compilation was an earlier project choice recorded in
`docs/upstream-native-acquisition.md`; the inspected PyAV BSD, CTranslate2 MIT,
oneDNN Apache and FFmpeg LGPL grants do not themselves require recipient
compilation. A publisher binary route must satisfy its own exact incorporated
component, copyright/source and linking obligations. Private-build evidence is
not onward-distribution approval.

## Rejected immediate replacement

Unmodified upstream Windows wheels change the current native graph:

- PyAV 18.1.0 selects FFmpeg vendor build `8.1.2-1`; its versioned build enables
  x264/x265 and additional libraries. That conflicts with the current controlled
  configuration and seven-DLL native verifier.
- CTranslate2 4.8.2's Windows build uses MKL/oneDNN and explicitly copies Intel
  OpenMP and `cudnn64_9.dll`. It is not an unchanged replacement for the current
  OpenBLAS/system-VCOMP profile and excluded NVIDIA payload policy.

The reviewer checked upstream metadata/build source, not downloaded wheel
contents. No binary was downloaded or executed. Exact package inspection could
refine the inventory but would not preserve the existing profile by itself.

Primary sources inspected:

- [PyAV 18.1.0 license](https://raw.githubusercontent.com/PyAV-Org/PyAV/v18.1.0/LICENSE.txt)
- [PyAV FFmpeg selection](https://raw.githubusercontent.com/PyAV-Org/PyAV/v18.1.0/scripts/ffmpeg-8.1.json)
- [FFmpeg vendor build 8.1.2-1](https://raw.githubusercontent.com/PyAV-Org/pyav-ffmpeg/8.1.2-1/scripts/build-ffmpeg.py)
- [CTranslate2 4.8.2 license](https://raw.githubusercontent.com/OpenNMT/CTranslate2/v4.8.2/LICENSE)
- [CTranslate2 Windows build](https://raw.githubusercontent.com/OpenNMT/CTranslate2/v4.8.2/python/tools/prepare_build_environment_windows.sh)
- [oneDNN 3.1.1 license](https://raw.githubusercontent.com/oneapi-src/oneDNN/v3.1.1/LICENSE)
- [FFmpeg binary distribution guidance](https://ffmpeg.org/legal.html)

## Concrete acceptance for the new artifact

1. Bind exact source, producer toolchain, configuration, wheel/DLL inventory and
   final artifact hashes under a new immutable identity and receipt contract.
2. Verify absence of private Microsoft DLLs, NVIDIA payloads, NumPy wheels and
   prohibited populated caches. Preserve direct vendor routes.
3. Deliver exact matching source, modifications/build configuration, notices and
   applicable practical replacement/relink rights. Review actual final bytes.
4. Install on clean Windows without compilers: actual imports, media decode,
   CPU int8 transcription, health/render and failure-before-activation/rollback.
5. Qualify the exact Inno executable, then test its generated uninstaller in the
   user's required order, obtain the scoped technical review and release only
   when the remaining gates pass.

The exact v40 follow-up already resolves NumPy/private-Microsoft and optional
cuBLAS questions for its documented direct-recipient/no-AutoClip-redistribution
scope. Historical pending statements are not new universal entitlement blockers.
No automatic approval rejection may be circumvented by this decision.
