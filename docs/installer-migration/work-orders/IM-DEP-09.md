# IM-DEP-09: publisher CPU manifest and guarded builder route

Date: 2026-10-02. Parent explicitly authorized bounded implementation under
`cpu-native-artifact-v1.md`. Owned only:

- `scripts/verify-installer-manifest.py`
- `scripts/build-inno.py`
- `.github/tests/test_installer_manifest.py`
- `.github/tests/test_inno_build.py`
- `docs/installer-migration/work-orders/IM-DEP-09.md`

Root owns release/installer manifests, receipts/disposition, Inno and candidate
production; the bootstrap writer owns its assigned PowerShell files. No other
writer's files, frozen CPU helper or source packet were edited. No acquisition,
vendor action, consent, VM, actual Inno compilation or publication occurred.

## Additive contract for the producer

Outer installer schema1 may contain `cpu_native_artifact`. It requires:

```text
identity == runtime_id: safe immutable lowercase runtime ID
filename: safe lowercase ZIP basename
url: HTTPS with an exact redirect_hosts policy
bytes: positive integer
sha256: exact lowercase SHA256
delivery_classification: DIRECT_RECIPIENT_DOWNLOAD
profile: cpu
redirect_hosts: exact permitted hosts including the initial URL host
qualification_receipt_path: indexed path in the release archive
qualification_receipt_sha256: exact indexed receipt SHA256
```

Its entire descriptor must equal release schema3
`native_build.cpu_artifact`, with
`native_build.delivery='publisher_cpu_with_source_nvidia'`. Descriptor presence
and that delivery mode must agree. The indexed, hash-bound qualification receipt
has integer `schema_version=1`,
`decision='QUALIFIED_COMPONENT_DISTRIBUTION'`, and an `artifact` object binding
the exact `runtime_id`, `filename`, `bytes` and `sha256`. Additional receipt
evidence metadata is permitted. A label or receipt parser does not establish
reviewer authority; root supplies the actual scoped disposition after review.

The new route retains precisely nine source/build asset identities matching the
release's pinned native recipe, each `profile=nvidia`. Visual Studio 2022 Build
Tools, Windows SDK, Git for Windows and MSYS2 remain required identities in the
source NVIDIA graph, all `profile=nvidia`; VS/SDK remain `BLOCKED`. CPU cannot
select those rows. MSYS2 archive/signature/key/package metadata is always checked;
its installability is enforced only when its profile is selected. Existing
descriptor-free routes and all original assertions retain their behavior.

Verifier CLI adds optional `--native-artifact <local exact ZIP>`.
Metadata-only graph checks may omit it. Publisher CPU `--require-installable`
requires it, checks actual filename/bytes/SHA256, and invokes the existing
standalone CPU helper's `validate(raw, runtime_id)` without extraction or native
execution. NVIDIA retains the unresolved vendor-prerequisite rejection.

## Guarded builder

Builder CLI adds optional `--native-artifact` and `--bootstrap`. An omitted
bootstrap uses the existing canonical `install.ps1`; an explicit successor path
is locked and pinned without replacing canonical v40 pins. Actual native ZIP,
CPU helper, selected bootstrap and root-requested existing VC-runtime helper
remain protected by Windows read-sharing locks through verification and compiler
invocation. The verifier receives the actual native path.

Publisher CPU compiler defines:

```text
NativeCpuEnabled=1
CpuNativeIdentity
CpuNativeRuntimeId
CpuNativeFilename
CpuNativeSha256
CpuNativeBytes
CpuNativeHelperSha256
VcRuntimeHelperSha256
PythonPrerequisiteHelperSha256
```

The Python alias retains the existing `PythonHelperSha256` definition too. Existing
compiler defines/options remain. The candidate receipt remains
`qualification=UNVERIFIED_CANDIDATE`, and adds the exact CPU descriptor, actual
native input hash/size, CPU/VC helper hashes and selected bootstrap path/hash.
The parent-owned `installer/install-vc-runtime.ps1` bytes were inspected and
hashed, not edited or executed; its observed SHA256 is
`5c5a31b9fc22281bc4cfb8cc919efb5beb7724943e9ffdbb2ff06c9bdceb3e47`.

## RED and verification

Exact commands from `D:\Projects\autoclip-runtime`:

```powershell
python -m unittest discover -s .github/tests -p test_installer_manifest.py -v
python -m unittest discover -s .github/tests -p test_inno_build.py -v
python -m py_compile scripts/verify-installer-manifest.py scripts/build-inno.py .github/tests/test_installer_manifest.py .github/tests/test_inno_build.py
git diff --check -- scripts/verify-installer-manifest.py scripts/build-inno.py .github/tests/test_installer_manifest.py .github/tests/test_inno_build.py docs/installer-migration/work-orders/IM-DEP-09.md
```

Meaningful verifier RED: a publisher CPU installable graph without an actual
artifact returned success (`AssertionError: 0 == 0`), before the required actual
artifact gate existed. The positive new-route CLI also failed because its new
argument was absent. Minimum route validation made both GREEN. Builder RED:
the positive successor build failed because `--native-artifact`/`--bootstrap`
were absent. Parent's later VC-helper requirement first demonstrated missing
compiler pin and successful mutation of its unlocked isolated copy; adding its
lock/pin made those checks GREEN.

Final focused results: 22 manifest tests pass (17 original + 5 new) and 14 builder
tests pass (11 original + 3 new). No original assertion was changed or disabled.
New tests prove exact receipt/descriptor binding, actual ZIP requirement and
substitution rejection, unqualified decision rejection even when every hash is
consistent, CPU exclusion of source tools/assets, unselected blocked MSYS route
handling with retained metadata validation, preserved NVIDIA blocking, successor
bootstrap/compiler/receipt pins and real Windows write/rename exclusion for native
ZIP, CPU helper, VC helper and selected bootstrap. After build completion the
same isolated input copies can be written again, proving lock release.

Tests reuse the existing CPU ZIP/RECORD fixture with synthetic native bytes and
explicitly synthetic receipt decisions. They exercise real validators and fake
compiler subprocess output; they establish no actual component distribution
approval. A probe initially confused an exception's absent `winerror` with a
successful write; it was corrected to assert `errno=13` and rename `winerror=32`,
matching the existing Windows lock tests. That fixture-reporting issue was not a
production failure or claimed RED behavior.

Compilation and scoped whitespace checks pass. Actual reviewed r2 artifact,
release graph, real compiler/Setup, installed CPU import/media/transcription,
rollback/uninstaller and final review remain root checks. The originally supplied
native ZIP was reported blocked by notice closure during this work; it was not
promoted, modified or treated as qualified here.

Suggested commit: `feat: bind publisher CPU artifacts to installer candidate builds`.
