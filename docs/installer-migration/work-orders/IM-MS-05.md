# IM-MS-05: v40 native-build receipt login boundary

Status: read-only contract and caller trace complete; source-build route still
requires clean guest qualification. Only this report was added. No selected
archive, recipe, manifest, binary, VM, keyring, or system state was changed.
This is internal engineering analysis, not independent technical approval or
a release gate decision.

## Exact immutable source and caller chain

The selected public v40 ZIP at
`D:\AutoClip-Inno-Migration\autoclip-source-build-v40-provenance-continuity.zip`
has 1,108 entries, 173,196,134 bytes, SHA-256
`f2b3be779294bc55d6f5f56c2a780a2d6b863486f3af9bd7d19f30051961fc9f`.
Its top-level `build-native-from-source.ps1` and embedded provenance copy are
byte-identical, each 16,418 bytes, SHA-256
`f384d9f55c78b5dd47cb7432fa7a0003e7ae6e07984f06a7231d42fdeed8e832`.
This report reads those exact ZIP members; the similar live
`release/scripts/build-native-from-source.ps1` is not a substitute for them.
The ZIP's `release-manifest.json` also enumerates the recipe. Mutating its
extracted copy would fail `install.ps1:925-938` file size/hash checks and
violate the immutable reviewed release boundary. The [runtime architecture](../../runtime-update-architecture.md)
requires a new native identity/review if the recipe or build inputs change.

Call chain for the selected guarded route:

| Producer/caller | Exact behavior |
| --- | --- |
| `install.ps1:804-814` | Accepts `-MsysBash` or defaults to `C:\msys64\usr\bin\bash.exe`; validates leaf existence, derives root by three parent levels, prepends that root's `ucrt64\bin` and bash parent to process PATH. |
| `install.ps1:815-836` | With `-NoPrerequisiteAcquisition`, package/tool probes use `--noprofile --norc -c`; missing packages fail before legacy `-lc` upgrade/install. These installer probes do **not** themselves clear inherited `BASH_ENV`. The separate preflight helper does (`installer/preflight.ps1:103-109`). |
| `install.ps1:1034-1040` | Defaults CPU/NVIDIA build cache to `$ExternalCache\native-build-v11-20260926-<profile>` and passes the *same* `-MsysBash` string to the extracted exact recipe. It copies the resulting receipt into the release. |
| Exact ZIP recipe lines 56-79, 153-159 | Checks `-MsysBash` exists, may derive the same root for NASM, prepends its parent to PATH, and invokes it with plain `-c` for the codec-free FFmpeg script. |
| Exact ZIP recipe line 214 | At final receipt creation, invokes `& $MsysBash -lc "pacman -Q $_"` for each of `make`, `diffutils`, `pkgconf`, and `mingw-w64-ucrt-x86_64-nasm`. This is the remaining login-shell path. It does not check each native exit status or output shape there. |
| `update.ps1:478` | Forwards an explicit `-MsysBash` to `install.ps1` on an update. The separate live `release/scripts/install-source-build.ps1` also accepts it, but is not the selected ZIP's recipe or the guarded caller traced here. |

The exact recipe's cache branch (lines 129-149) returns **before** the FFmpeg
invocation and final `-lc` receipt query when a matching receipt and two
verified wheel hashes/config are already present. Its reuse check compares
source hashes/commits, wheel count/profile and FFmpeg config; it does not
record the MSYS2 root path, default keyring, profile-file identity or a bash
adapter. Cache reuse therefore cannot serve as a clean-build test of this
login boundary. A new isolated `-NativeBuildRoot` (or a proven exact cache-key
match under the [architecture's native cache policy](../../runtime-update-architecture.md))
is required for qualification; do not re-label a wheel built under another
unreviewed MSYS2 state as a fresh result. Post-build receipt verification
must check the four `msys2_packages` strings against exact expected versions,
not accept arbitrary output or an empty query from line 214.

## Why a fully initialized private root is the smaller candidate

The [GNU Bash startup reference](https://www.gnu.org/software/bash/manual/html_node/Bash-Startup-Files.html)
states that noninteractive `--login` executes `/etc/profile`, then the first
readable `~/.bash_profile`, `~/.bash_login`, or `~/.profile`; noninteractive
shells can also execute `BASH_ENV`. Merely having a private root does **not**
make `-lc` safe. A preexisting user profile, extra `profile.d` script,
inherited `BASH_ENV`, or uninitialized default keyring can execute code or
refresh keys before `pacman -Q` runs.

[IM-MS-04](IM-MS-04.md) identifies the exact signed 2026-06-11 TAR's five
`/etc/post-install/*.post` scripts and the local, refresh-free initialization
experiment. Its `07-pacman-key.post` enters the refresh branch **only when the
default `/etc/pacman.d/gnupg` directory is absent**. [IM-MS-03](IM-MS-03.md)
uses a separate `autoclip-pinned-*` keyring for the five-package transaction;
that isolated keyring alone does not satisfy this default-directory test.
The exact TAR's skeleton `.bash_profile` sources `.bashrc`, which returns
immediately for a noninteractive shell; both are delivered bytes. The actual
recipient's home files are mutable and must not be assumed to equal skeleton.

The minimal candidate is therefore to pass the **real, verified native
`<private-root>\usr\bin\bash.exe`** through the existing `-MsysBash` parameter,
after the TAR root has passed a complete protected extraction/inventory check,
the default keyring has passed explicit local `pacman-key --init` and
`--populate msys2`, one first login has completed under guest network
isolation, and IM-MS-03's signed, repository-free package transaction has
passed. No recipe, argument, or root-path shim is then needed. Before the
guarded source build, fail closed unless:

1. The derived three-parent MSYS root is the intended protected short-ASCII
   NTFS root, with no substituting/reparse parent or altered `bash.exe`.
   Verify the exact installed package versions/capabilities and signed base
   provenance. Keep the protected root immutable to untrusted writers during
   build.
2. The default gnupg directory is complete and locally trusted, not merely an
   empty directory that would suppress the upstream refresh branch. Verify
   shipped `/etc/profile`, all sourced post-install and `profile.d` scripts,
   `/etc/bash.bashrc`, and any loaded home startup file against an allowlisted
   exact byte inventory after package installation. Reject additions or
   modifications. Resolve `HOME` to a private protected location with known
   skeleton files or an intentionally empty, reviewed profile set; do not run
   against an ordinary user's mutable dotfiles. Include `.bash_logout` in the
   scan if present.
3. Clear `BASH_ENV` and `ENV` before the guarded `install.ps1` probes and for
   the complete source-build child process,
   and constrain other startup-affecting environment state (including `HOME`,
   `GNUPGHOME`, `MSYSTEM`, `MSYS2_PATH_TYPE`, and PATH) to the selected root and
   reviewed build tools. Capture and restore caller environment outside the
   operation. The exact recipe itself sets `MSYS2_PATH_TYPE=inherit`, so PATH
   must retain required compiler tools while selecting its native MSYS paths
   first.
4. In a fresh guest, observe the exact `-lc` receipt calls after a full build:
   no keyserver request or profile mutation outside expected private paths,
   exact four `pacman -Q` results, and a receipt that agrees with independent
   non-login package queries. A prior successful first login is evidence of
   initialization, not proof future user/profile files stayed unchanged.

These are qualification conditions, not an assertion that the current guest
or installer already enforces them. The receipt `-lc` is a **local query**;
no publisher download is needed for it. The full native recipe separately
fetches exact pinned source archives and Git commits, so disabling all network
for the whole build is not a substitute for controlling this startup boundary.

## Adapter alternative and disposition

A first-party adapter passed as `-MsysBash` could map only `-lc` to
`--noprofile --norc -c` and delegate `-c` unchanged. It must be a real leaf
at `root\usr\bin\...` or both callers' three-parent root derivation would
select the wrong UCRT64 directory; it would also be prepended to PATH and
used for the FFmpeg build. A PowerShell `.ps1` or CMD wrapper would need
specific proof that `& $MsysBash`, argument arrays, quoted FFmpeg environment
variables, stdout/stderr, and `$LASTEXITCODE` behave exactly like native bash
in both `install.ps1` and the selected recipe. An extra first-party file in
the vendor tree needs its own protected identity and provenance, and it is a
new effective build input missing from the v40 recipe/cache identity. The
cache and receipt would need to distinguish it before reuse. This exceeds
the root/preflight route and is **not recommended without a demonstrated
uncontrollable profile caller**. Do not replace vendor `bash.exe`, alter the
ZIP, or use a wrapper to hide an incomplete MSYS2 initialization.

**Decision:** Keep real bash and qualify a fully initialized, immutable
private root plus controlled login startup state. This preserves the exact
selected v40 recipe and existing `-MsysBash` call chain. If the guest cannot
bound `HOME` or prevent unexpected profile/network effects, the source-build
route remains blocked at this boundary; then evaluate a separately pinned
adapter with a new cache/provenance contract. No automated acquisition,
terms decision, installed-runtime completion, or classification changes are
approved by this report.

Read-only checks: exact ZIP hash/entry/member inspection, install/update and
preflight caller tracing, exact recipe cache/receipt analysis, TAR startup
file inspection, GNU Bash primary manual, repository architecture and
IM-MS-03/04 cross-check. No execution, RED/GREEN, guest qualification or
external approval was performed.
