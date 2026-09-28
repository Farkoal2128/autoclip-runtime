# Runtime and application update architecture

Status: architecture contract. The current V11 full installer still installs
a complete 79-wheel environment into each versioned release directory. The
CR-11 app-only updater is published for application updates on the compatible
V11 runtime; the fully separated runtime layout below remains a target design.

## Layers and identity

The bootstrap installer provisions prerequisites, one immutable Windows x64
Python runtime, then one AutoClip app release. Routine updates reuse the
installed runtime if its complete compatibility contract matches. A runtime
contains Python, shared Python packages, native dependencies such as PyAV and
CTranslate2, CUDA libraries, and runtime-owned notices/source material. An app
release contains the AutoClip package, compiled frontend, app-owned notices,
and app metadata. Code or UI changes normally produce only an app asset.

The conceptual managed layout is:

```text
%LOCALAPPDATA%\AutoClip\
  runtimes\<runtime-id>\.venv
  runtimes\<runtime-id>\runtime-manifest.json
  apps\<app-release-id>\
  active.json
  Start-AutoClip.ps1
```

The runtime ID must identify an immutable reviewed environment, for example
`win-py311-cuda12-v1`; it is not merely a Python-version label. Its
schema-versioned manifest records platform, architecture, exact Python and
dependency/native identities, sizes, and SHA-256 values. Each app has a
unique exact-byte release ID and a schema-versioned manifest naming its
`required_runtime`, asset URL, size, and SHA-256. Multiple app releases can
share one runtime. A changed runtime dependency or ABI gets a new ID; the
old runtime remains available while referenced by current or rollback state.

For a recipient-side native build, the immutable ID identifies the source
commits/archive hashes, build recipes and allowed configuration. Generated
wheel bytes can differ between hosts. The installer records their exact local
hashes and the installed native DLL hashes in a build receipt, verifies wheel
integrity and runtime behavior before activation, and checks the installed
hashes against that receipt on later update/rollback. Such a release needs
clean-machine build and review evidence before it becomes a public pin.

## Update and rollback

The updater fetches a small immutable release manifest, validates its schema
and pinned hashes, verifies the installed required runtime, downloads that
runtime only if absent or incompatible, then downloads the app asset. It
stages each layer separately, checks dependency compatibility and isolated
health/home, and only then atomically selects the app/runtime pair in
`active.json`. The stable launcher and managed shortcuts follow the selected
pair. App layers must be isolated without modifying the shared environment;
an app-wheel-only `--no-deps` layer or equivalent controlled import mechanism
is acceptable after tested import resolution. No Windows symlink privilege or
global `PATH` mutation should be required.

Rollback selects the previous verified app. If current and previous apps use
the same runtime, it requires no network or dependency reinstall. If they use
different runtimes, retain both until the previous app is no longer a rollback
target. Retain at least current and previous verified app states; cleanup may
remove only unreferenced managed layers under an explicit retention policy.
Project databases, media, transcripts, exports, settings, and credentials
remain outside managed release cleanup. App-data schema migration may limit
rollback even when binaries remain; each release must state that impact.

## Failure, repair, and migration

Failed downloads, 404s, invalid manifests, wrong hashes, corrupt archives,
insufficient disk space, and failed health checks must leave the previous
active state and launcher usable. Clean partial downloads safely. Repair a
damaged app without downloading a healthy runtime; repair a damaged runtime
only when needed. Before large transfers, report their size and check enough
space for download plus staging where practical.

Known V11 monolithic installations are migration inputs. Validate the old
manifest and installed environment before deciding whether its dependency
bytes can seed the shared runtime. Stage the split layout alongside the old
install, verify it, then activate; retain the old install until rollback and
retention decisions permit cleanup. Never reinterpret an old release ID as a
new runtime ID or destructively reshape a completed install.

## Publication and proof

Classify each change as app-only, runtime, installer/updater, or mixed. Build,
test, review, publish immutable assets, download and verify their public bytes,
then promote the installer/manifest pin and test the real update path. Public
`main` must not reference an asset that is still draft or absent. Keep app
and runtime inventories/notices separate so unchanged source material is not
redownloaded with each app update. Every remote production asset is pinned by
SHA-256 or an approved stronger check; reject mutable asset URLs, unsupported
manifest schemas, archive traversal, and unverified code.

The permanent bandwidth regression is: when app B requires an already
verified runtime used by app A, updating A to B downloads the app asset and
downloads **zero** runtime assets. Also test runtime-required updates,
same/different-runtime rollback, a known legacy install, and failure before
activation. Record fresh-install and normal-update transfer sizes per release.
A future content-addressed wheel store or binary patch scheme needs its own
justification; it is not part of this baseline architecture.
# Source-build profile selection

For a new source-built runtime, the updater retains the active runtime's
NVIDIA profile when its verified native build receipt reports `profile=nvidia`
and the selected installer supports `-InstallNvidiaGpu`. A user can request
`-CpuOnly` to select the CPU profile for the new runtime. The updater rejects a
profile-preserving update when the selected installer lacks the NVIDIA option;
it does not silently change the selected profile. Explicit `-InstallNvidiaGpu`
and `-CpuOnly` cannot be combined. This policy does not alter an installed
runtime or the public release pin.
When a target source build already exists, its native receipt must match the
requested or preserved profile before the updater selects it.

Publisher cache preparation defaults to ordinary dependency wheels. Explicit
`-InstallNvidiaGpu` also includes the optional Python wheels declared in
`external_assets`. `-Offline` requires verified cached bytes for every selected
wheel and never downloads missing or corrupt entries. The source-build installer
forwards NVIDIA selection when using `-OfflinePublisherCache`; source checkouts,
CUDA Toolkit, build tools and models retain separate acquisition requirements.

## Source-build prerequisite consent

Source-build installers and publisher-cache preparation expose `-AcceptNvidiaTerms`
and `-NonInteractive`; installers/updaters also expose `-AcceptMicrosoftTerms`.
These are explicit recipient declarations after reviewing the versioned terms,
not defaults implied by NVIDIA profile preservation. Without an acceptance switch,
interactive runs require the exact response `ACCEPT`; unattended runs fail before
acquiring or installing the selected prerequisite. CUDA's existing valid build
root can be reused without a new Toolkit install; cuBLAS authorization is separate.
CPU mode never presents or accepts NVIDIA terms. Already installed valid Microsoft
inputs do not trigger provisioning consent.

The exact terms snapshots and their hashes are recorded in `prerequisite-terms.json`.
Presentation includes a version, primary URL and local copy. Each affirmative
declaration writes a receipt under the artifact cache's `terms` directory. It
does not claim independently verified authority or entitlement. Microsoft Build
Tools/VC installers retain their native agreement UI rather than quiet/package
agreement acceptance. Equivalence of downloaded reference terms to exact installer
terms remains a reviewer question, and the native agreement is still presented.
No automatic script or test may provide a real recipient's acceptance without
their authorization.
