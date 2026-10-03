# IM-ACQ-01: guarded source-build acquisition

Authorization: parent explicitly assigned `install.ps1`, one focused acquisition
test and this report. Other writers own the outer dependency manifest, protected
downloader, Inno flags/build, receipts and guest qualification. Existing edits
were preserved. No immutable extracted file, vendor installation, agreement,
commit or publication was changed/performed by this slice.

## Requirement and contract

Installer contract-v1 requires approved exact official HTTPS inputs, protected
staging, rejection of unknown/blocked routes and revalidation before use.
This changes the installer/updater layer without changing a release/runtime ID
or the pinned v40 archive and scripts. Runtime architecture governs activation,
shared caches and rollback; no activation behavior was changed.

The accepted opt-in API adds these three string parameters to `install.ps1`:

- `-SecureAcquisitionManifestPath`
- `-SecureAcquisitionManifestSha256`
- `-SecureDownloaderSha256`

They must be provided together with `-NoPrerequisiteAcquisition`. With no secure
inputs the legacy route remains available. The downloader filename is fixed to
`download-artifact.ps1` beside the executing installer; there is no caller-chosen
downloader path. Parent Inno integration must extract that sibling and supply
the two expected hashes from its fixed build inputs.

Initialization checks both file pins and local paths. Every guarded download
reads/rechecks helper and outer manifest bytes, rejects reparse ancestors,
relative/UNC/traversal/stream paths, and matches requested URI/size/SHA-256 to
exactly one approved artifact. Candidates come from outer prerequisites,
external assets, native build assets and target release, plus the separately
pinned publisher-wheel manifest. Duplicate matches fail closed; optional cuBLAS
is not arbitrarily selected from overlapping inventories. No alternate wheel
list was added.

Verified helper bytes are executed in memory; verified outer/publisher bytes
are snapshotted into a fresh private TEMP directory. The existing protected
downloader reads those snapshots and writes only within TEMP. Its returned
path, size and hash are checked before copying to the existing native-cache
temporary destination. Paths are rechecked before copying and cleanup. The
immutable cache helpers retain their own size/hash verification and publication.

The actual existing callback API is `(URI, destination)`. The callback asserts
and uses the dynamic caller's bound `Sha256` and `Size`; absence or a mismatch
fails before network access. Explicit callbacks cover the outer publisher-cache
script, external assets, release acquisition and optional pinned CUDA helper.
Scoped defaults cover implicit native source/build-wheel calls after immutable
scripts redefine the upstream helper. PowerShell treats scriptblock defaults as
factories, so the default factory returns the callback itself. Defaults are
copied and restored in the installation's existing `finally` block.

The parent added `native_build_assets` for the two source archives and seven
build wheels mechanically derived from exact v40; the protected downloader's
resolver is owned by another agent. The original 74 publisher wheels remain
the pinned publisher-manifest inventory. Existing verified cache hits remain
subject to the immutable helper's checks and do not perform acquisition.

## MSYS detection steering

The parent additionally identified first-login MSYS profile key refresh as an
unguarded side effect. With `NoPrerequisiteAcquisition`, outer package discovery,
package rechecks and tool probes now use `--noprofile --norc -c`; legacy probes
retain `-lc`. Package updates already fail before execution under that switch.

The exact immutable native builder uses `-c` for the build itself but `-lc` at
line 230 to record MSYS package versions. Inspected host `/etc/profile` lines
108-110 unconditionally source `/etc/post-install/*.post`; the inspected
`07-pacman-key.post` initializes/populates/refreshes if `/etc/pacman.d/gnupg` is
absent. No inspected environment hook skips that loop. Setting HOME or
CHERE_INVOKING alone cannot remove it. Parent follow-up can qualify initialization
from the exact bundled keyring before native build, or approve a first-party
wrapper supplied through the existing MsysBash parameter to translate `-lc`
into non-login arguments with the inherited UCRT64 environment. Neither route
was implemented or qualified here; immutable files were preserved.

## RED and GREEN evidence

Initial preimplementation RED: the focused test rejected the missing guarded
acquisition function with `unapproved URI cannot be rejected before download`.
The actual archive callback tests then caught two implementation scope/default
errors before GREEN: script-qualified state was invisible inside the extracted
Prepare script, and storing a callback directly as a parameter default invoked
it with binding metadata instead of the requested URI. The corrected factory
and dynamic scope passed the actual archive functions, including redefinition.

For the later MSYS steering, meaningful preimplementation RED was
`Guarded MSYS2 detection must not load login profiles or trigger post-install
key refresh.` The guarded non-login change made that test GREEN. A subsequent
legacy assertion caught single-string splatting into characters; preserving
the argument array made both routes GREEN.

The focused test verifies the actual v40 ZIP SHA-256 before extracting the
unchanged upstream, Prepare and native build scripts into scratch. It executes
the actual installer's Prepare/external call expressions and the actual archive
Get-VerifiedSource/Get-PinnedUpstreamAsset/Get-ContentAddressedAsset bodies.
Only the protected downloader's HTTP response boundary is mocked, returning a
seven-byte fixture; production contains no mock/bypass parameter. Four protected
transfers verify wheel/source staging through private TEMP snapshots. Unknown
URI, wrong caller size/hash, absent caller pins, partial inputs, unguarded secure
inputs, blocked/duplicate routes, changed helper/outer/publisher inputs, alternate
streams and an actual junction ancestor are rejected before mock network access.
The exact production finally restoration preserves the prior defaults object.

Executed from `D:\Projects\autoclip-runtime`:

```powershell
powershell -NoProfile -NonInteractive -ExecutionPolicy Bypass -File tests/InstallerSecureAcquisition.Tests.ps1
powershell -NoProfile -NonInteractive -ExecutionPolicy Bypass -File tests/InstallerNoAcquisition.Tests.ps1
powershell -NoProfile -NonInteractive -ExecutionPolicy Bypass -File tests/InlineInstaller.Tests.ps1
powershell -NoProfile -NonInteractive -ExecutionPolicy Bypass -File tests/InstallLaunchers.Tests.ps1
C:\Users\beilo\AppData\Local\Programs\Python\Python311\python.exe -I -B -m unittest discover -s .github/tests -p test_cpu_bootstrap_contract.py
git diff --check -- install.ps1 tests/InstallerSecureAcquisition.Tests.ps1 docs/installer-migration/work-orders/IM-ACQ-01.md
```

All passed, including three Python contract tests. The tests require the exact
local v40 archive at `D:\AutoClip-Inno-Migration`; no live asset transfer or full
installation was run. Native Git clones/fetches remain the immutable builder's
commit-pinned route, outside this byte-asset downloader slice. Guest native build,
MSYS login side effects, network cancellation, actual vendor installation,
health/lifecycle, final setup review and release qualification remain open and
parent-owned. This evidence does not qualify a generated setup or waive policy.

Owned changed files: `install.ps1`,
`tests/InstallerSecureAcquisition.Tests.ps1`, and this report.
