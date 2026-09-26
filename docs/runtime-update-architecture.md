# Runtime and application update architecture

Status: target contract for future updater work. The current V11 scripts still
install a complete 79-wheel environment into each versioned release directory.
This document does not claim the split updater is implemented or released.

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
