# MSYS2 archive manifest and Inno input binding

Root integration work; implementation authorized by the installer migration.
This record qualifies bounded guards, not an installation or release.

## Contract and implementation

The canonical MSYS2 row now selects the official 20260611 TAR, its detached
signature and separately pinned installer key. The GUI artifact remains in
historical evidence. All MSYS2 routes remain BLOCKED. The versioned installer
contract defines an ordinary-user base receipt and explicitly rejects elevated
execution of recipient-writable MSYS2 code.

The manifest gate checks archive/signature/key identities, child HTTPS host
policies and all child delivery classifications. The downloader resolves the
signature/key children only when their parent route permits acquisition.
Preflight accepts the explicitly selected private MSYS2 root. The builder binds
the base, extraction and package helper hashes and the selected TAR hash into
compiler arguments and the build receipt. The Inno source embeds those three
first-party helpers and exposes their hashes in its existing audit mode; their
wizard orchestration is still pending.

Inspection of the authenticated TAR found that `etc/profile` also sources
`etc/msystem`, `etc/msystem.d/MSYS` and `etc/bash.bashrc`. The contract and both
MSYS2 writers were updated to include this startup closure. Ambient PS1/XDG
configuration and exported Bash functions cannot authorize extra startup code.

## Meaningful RED and GREEN

- `python -m unittest discover -s .github/tests -p test_installer_manifest.py`:
  RED: nine invalid archive/child cases were accepted. GREEN: all 16 tests pass.
- `powershell -NoProfile -ExecutionPolicy Bypass -File tests/InstallerDownload.Tests.ps1`:
  RED: the TAR signature route was unavailable. GREEN: child resolution,
  parent/child blocking, invalid metadata and redirect-policy cases pass with
  the HTTP response boundary mocked; the existing transfer tests also pass.
- `powershell -NoProfile -ExecutionPolicy Bypass -File tests/InstallerPreflight.Tests.ps1`:
  RED: explicit selected root was ignored. GREEN: the actual capability function
  uses the selected fixture root and retains native identity/version checks.
- `python -m unittest discover -s .github/tests -p test_inno_build.py`:
  RED: helper receipt keys/compiler definitions and archive definition absent.
  GREEN: all seven tests pass. The compiler boundary is a fake compiler; these
  tests prove arguments and receipts, not ISCC compilation or installation.
- `python -m unittest discover -s .github/tests` at the first integration slice:
  94 tests ran, one optional real-archive test skipped, remaining 93 passed.
  Later helper/startup and builder changes require their own final rerun.
- `powershell -NoProfile -ExecutionPolicy Bypass -File tests/InstallerSecureAcquisition.Tests.ps1`:
  PASS, actual guarded callbacks and HTTP-boundary fixtures.
- `python scripts/verify-installer-manifest.py --manifest release/manifests/installer-dependencies-v1.json --archive D:/AutoClip-Inno-Migration/autoclip-source-build-v40-provenance-continuity.zip`:
  PASS, 1108 release members, 74 publisher wheels, three external assets.
- The same command with `--require-installable` fails closed on blocked native
  input `ffmpeg-8.1.2.tar.xz`; no production setup was compiled by that gate.
- `git diff --check`: PASS; existing CRLF conversion warnings remain.

Manifest at this slice SHA256:
`90d6189f173526f9d1d9c9a5f40aa2135f49f59bb7fa23cd68fa61ba11ff2119`.
Preflight SHA256:
`41fb9fbac496eba3db79a4eac287102163b027c0a09c0c3141218c9142d66d27`.
Downloader child-resolution SHA256 before the separate batch slice:
`a0901450280dd7cc3f4fd69d0660974a10ce3db92fa00970b524b7fa9f7b0579`.

## Limits and next integration

The base writer's host test accidentally invoked real Python extraction.
Root independently observed the preserved protected directory
`C:\acmb-492cbb00`, 14546 files/1052 directories and no live matching extractor.
Root observation is `D:/AutoClip-Inno-Migration/host-msys-extraction-incident-observation.json`,
SHA256 `0bfd935f76965a8f1c124521c7185795fbb7d90d79c0e5f21a0c294cc1da7232`.
The writer's separate full inventory is recorded in IM-MS-10. This is an
unintended host test action, not a qualified installation. Operational host
tests were stopped; the harness now tests read-only entry/isolated guards.

The real guest Microsoft acquisition resolved exactly the 409 pinned files.
Its wrapper captured a null process exit code and correctly reported failure;
native console completion and inventory equality do not establish an exit-zero
receipt. The exact process was observed alive, then terminal after native
completion acknowledgement; it was not restarted. A separate supported vendor
verification operation is in progress. Product installation remains unperformed
at this slice. Preserve primary receipts before overwriting transport outputs.

Remaining work includes ordinary-user production MSYS2 provisioning/package
qualification, controlled source build, complete Inno CPU wizard installation,
installed health/media and lifecycle evidence, final distribution/SBOM/notices,
and the immutable blinded technical review. NVIDIA hardware tests are deferred
under the user's explicit no-passthrough instruction. No release gate closes
from this work order.

## Subsequent real guest layout verification

The separate supported Microsoft `--layout --verify --wait` operation is now
terminal with numeric exit code 0. Independent comparison before and after
verified all 409 files with zero differences. Primary evidence:
`D:/AutoClip-Inno-Migration/vm-vs-verify-75f7abaf5edb.json`, SHA256
`75f7abaf5edb6a7c5ebae1d05ba07d743dd12407ba22f3d1d1950a051a67ed6e`.
This verifies the exact cached layout only. The acquisition wrapper's null
exit remains a failed observation; catalog metadata conflicts remain unresolved.
An interactive offline product-install test is a separate subsequent operation.
