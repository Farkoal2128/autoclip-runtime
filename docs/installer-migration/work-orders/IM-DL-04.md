# IM-DL-04: nested MSYS2 and native build asset selection

Authorization: parent work order explicitly assigns implementation of nested
MSYS2 package/signature selection and subsequently adds native build asset
selection. Owned files: `installer/download-artifact.ps1`,
`tests/InstallerDownload.Tests.ps1`, and this report. Other writers own the
manifest, caller integration, build verification and guest qualification.
No manifest/classification, Inno, installer or vendor installation changes
were made by this slice.

Requirement/contract: `contract-v1.md` protected exact official acquisition
and dependency identity rules, with the MSYS2 offline trust qualification
context in IM-MS-02. Classification: installer/updater. Preserve the existing
downloader's URL, redirect, byte/hash, TEMP path, cache and cancellation
boundaries; do not maintain another package list.

## Selection and policy

The actual current schema is a `build_prerequisites` row with identity `MSYS2`,
containing `packages[]` and each package's nested `signature` object. It does
not use `proposed_packages`. The helper resolves a package by its exact identity
or filename, and a detached signature by its exact filename. MSYS2 parent,
package and selected artifact must permit `DIRECT_RECIPIENT_DOWNLOAD`.
Signature selection also respects a blocked package. The selected child owns
its exact URL, bytes, SHA-256 and redirect host allowlist; parent GitHub hosts
are not substituted for package repository hosts.

Matched package metadata must identify a nonempty identity, version and
architecture, a safe filename matching their `.pkg.tar.zst` combination, and
the associated `<package-filename>.sig` signature. Existing pin/host validators
then reject malformed hash, size, URL or host data. Matches join the existing
ambiguity count across target release, build prerequisite, external, publisher
and nested MSYS2 entries. Duplicate package/signature rows and cross-group
collisions fail before a request.

The parent-authorized `native_build_assets[]` group resolves by identity or
filename exactly like external assets, using one added selection expression.
Its fields are supplied by the parent from the hash-checked native build
script. No native source-script parsing or duplicate maintained list was
added to the downloader. Existing public script/function parameters remain
unchanged.

## TDD and verification

Exact focused command from `D:\Projects\autoclip-runtime`:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File tests/InstallerDownload.Tests.ps1
```

- MSYS2 RED: before implementation, exit 1 with `Pinned ... route is
  unavailable` for package identity, package filename and detached signature
  filename. Tests invoked the real resolver with fixture manifests and response
  mocks; no source-string assertions were used.
- MSYS2 GREEN: after implementation, exit 0. Cases prove all three selections,
  blocked parent/package/signature rejection before transport, malformed
  package path and signature hash rejection, missing child host policy,
  cross-group ambiguity and duplicate nested signature matches.
- Native asset RED: before its selection expression, exit 1 with unavailable
  routes for native identity and filename.
- Final GREEN: after both changes, the exact focused command exited 0 under
  Windows PowerShell 5.1. Native identity/filename, blocked native route and
  native/external ambiguity cases passed. All prior external/publisher,
  redirect, size/hash, cache, timeout, absolute-path, reparse, header/body
  cancellation and target-release cases also passed.

Additional exact checks:

```powershell
git diff --check -- installer/download-artifact.ps1 tests/InstallerDownload.Tests.ps1 docs/installer-migration/work-orders/IM-DL-04.md
Get-FileHash installer/download-artifact.ps1,tests/InstallerDownload.Tests.ps1 -Algorithm SHA256
```

Scoped whitespace verification exited 0. Final handoff hashes:

- Helper SHA-256:
  `0906007f227e4cdc42bc65455380473520f92612f994d8928b6aee4c22b0b7af`.
- Tests SHA-256:
  `d3e9cb3386fc6f4e035d2ac4de1a0db8f3b7527abb74f40dc9e9f8cd141704c0`.

## Limits and parent handoff

Tests demonstrate selection/policy behavior using mock response bytes and the
real downloader's verification and staging code. No new real MSYS2 package,
signature or native source/wheel download was performed by this slice. The
canonical MSYS2 route was BLOCKED when inspected and remains rejected by this
helper until the parent intentionally changes its authorization. Earlier
IM-DL-03 real official artifact checks are historical evidence for the shared
transport, not new network or guest evidence for this snapshot.

The parent can now stage exact files through the unchanged script interface
using their manifest filenames as `Identity`. Byte/SHA-256 verification of
signature files is not cryptographic trust verification; signed package trust
and the real offline transaction remain the separate guest qualification.
No vendor installer, package manager, guest transaction, source compilation,
wizard, media, human/legal or publication check was executed by this work order.
