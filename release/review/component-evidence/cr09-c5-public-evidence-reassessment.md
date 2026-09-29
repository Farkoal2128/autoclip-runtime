# CR-09 C5 public-evidence independent reassessment

2026-09-28. Independent engineering/compliance evidence reassessment of the exact
external OpenBLAS route used by the unpublished v32 successor. This is not
professional legal advice, organizational authority, release clearance or
publication approval.

## Scope and exact artifact

- OpenBLAS archive: `OpenBLAS-0.3.30-x64.zip`, 40,561,566 bytes,
  SHA-256 `8b04387766efc05c627e26d24797ec0d4ed4c105ec14fa7400aa84a02db22b66`.
- DLL: `bin/libopenblas.dll`, 51,076,488 bytes,
  SHA-256 `e824cf9fc22e5949807ce995a32e413a345fb97e63e6d10cfbf41aa86382193c`.
- Route: external publisher OpenBLAS input for the recipient-built CTranslate2
  CPU and NVIDIA profiles. NumPy's different OpenBLAS DLL remains separate.

The exact v32 raw archive was retained for this reassessment. Read-only static
inspection was used; no installer/build script/native binary was executed and
no publisher was contacted.

## New artifact-bound public evidence

The official OpenMathLib/OpenBLAS GitHub release metadata for `v0.3.30`
identifies `OpenBLAS-0.3.30-x64.zip` as a project release asset and records
the same 40,561,566-byte size and SHA-256 above. The exact release tag is
`v0.3.30` at commit `993fad6aebbce34a97d3f8c34d6d79d35b64cc48`.

The exact-tag OpenBLAS Windows installation documentation states that project
Windows release binaries are built with MinGW using:

`NUM_THREADS=64 TARGET=GENERIC DYNAMIC_ARCH=1 DYNAMIC_OLDER=1 CONSISTENT_FPCSR=1 INTERFACE=0`.

Generated files inside the exact archive independently corroborate the route:
the OpenBLAS configuration identifies Windows/x86_64/GCC/GENERIC/OpenBLAS
0.3.30, and its pkg-config metadata records DYNAMIC_ARCH, DYNAMIC_OLDER,
MAX_THREADS=64 and `-lgfortran`.

Static strings in the exact DLL identify an MXE
`x86_64-w64-mingw32.static` toolchain, GCC/GFortran 9.3.0 and MinGW-w64
8.0.0 paths. The DLL imports Windows system libraries rather than separate
libgfortran/libgcc/libwinpthread DLLs, supporting static incorporation of the
relevant toolchain runtime material. Public MXE history corroborates GCC 9.3.0
and MinGW-w64 8.0.0 as real MXE toolchain versions.

## C5 decision

The combined artifact-bound evidence now supports the previously missing
publisher/build facts sufficiently for this project's bounded
engineering/compliance review:

- exact publisher asset association;
- OpenBLAS release/tag association;
- documented project Windows release build route;
- GCC/MinGW/MXE toolchain family;
- exact GCC/GFortran 9.3.0 and MinGW-w64 8.0.0 binary provenance;
- static runtime incorporation evidence;
- OpenBLAS as an independent BSD-licensed module rather than GCC runtime code.

The GCC Runtime Library Exception eligibility question is therefore
**sufficiently supported by artifact-bound public evidence at this review
scope**. An exact private shell transcript, exact MXE checkout SHA or maintainer
attestation would add assurance but is no longer required for this bounded C5
decision. Do not generalize this result to other OpenBLAS binaries, NumPy's
different DLL, future toolchain builds or onward routes with changed bytes.

**C5 status: resolved at bounded engineering/compliance scope.**
The prepared publisher-contact request is superseded and should not be sent
unless a later independent reviewer identifies a new exact missing fact.

## New finding C7 — MinGW-w64 runtime / winpthreads notices

The same exact DLL contains MinGW-w64 runtime and winpthreads source/build
identifiers, including winpthreads source paths. The MXE static-target and PE
import evidence support that this material is incorporated into the DLL.

MinGW-w64 v8.0.0 supplies recipient-facing notice material specifically for
programs statically linked against its runtime:
`COPYING.MinGW-w64-runtime/COPYING.MinGW-w64-runtime.txt`.
Its winpthreads component separately supplies
`mingw-w64-libraries/winpthreads/COPYING`, including the applicable project
and derived-code binary-notice conditions.

The exact v32 notice/source packet does not presently map/deliver those two
notice files for the external OpenBLAS DLL.

**C7 status: correction required.**

Required correction:

1. obtain/pin exact MinGW-w64 v8.0.0 bytes for both notice files;
2. deliver both in the recipient notice/source route;
3. map both explicitly to
   `OpenBLAS-0.3.30-x64.zip!/bin/libopenblas.dll`;
4. keep MinGW-w64/winpthreads terms distinct from OpenBLAS BSD notices and the
   GCC Runtime Library Exception;
5. update the legal/component index, dependent manifests and provenance;
6. create a new immutable successor because release bytes change;
7. prove unchanged executable/app/native/dependency/terms bytes by exact member
   delta and run focused independent C7 review.

This finding alone does not justify rebuilding OpenBLAS, CUDA qualification,
native compilation, ASR/media reruns or a wholesale 79-row/574-entry review.

## CR consequence

The exact v32 ledgers remain historical attributable evidence and are not
silently rewritten. The current overlay is:

- CTranslate2/external OpenBLAS: no longer unresolved for C5 eligibility;
  **correction needed for C7 notice delivery**.
- NumPy private Microsoft DLL: remains unresolved under RC-03.
- optional cuBLAS actor/authority: remains unresolved under RC-03.
- historical cuDNN: remains excluded from the operative successor profiles.
- all 574 SBOM declarations retain their previous conservative notice/source
  scope; C7 is an external toolchain-runtime notice route, not a reason to
  restart those declarations.

RC-01/02 remain In review pending the exact C7 successor and focused
disposition. RC-03 is unchanged. RC-05 and RC-07/publication remain gated.
CH remains untouched.
