---
name: runtime-updater
description: Govern AutoClip Windows installation, app and runtime updates, dependency packaging, release promotion, rollback, and repair. Use before changing installer/updater scripts, manifests, launchers, runtime versions, or GitHub release assets.
---

# AutoClip runtime updater

Read [the architecture contract](../../docs/runtime-update-architecture.md)
before changing the installer, updater, release metadata, dependencies, or
launcher. This skill governs future design and delivery; the current V11
installer and updater still use complete side-by-side environments.

## Classify and design

1. Classify the change as **app-only**, **runtime**, **installer/updater**, or
   **mixed**. Identify the requirement, affected manifest/state/public
   contracts, and any compatibility or migration impact before editing.
2. For an app-only change, reuse the installed compatible immutable runtime.
   Package only the versioned AutoClip application layer and its own assets.
   A changed AutoClip wheel, frontend, prompt, API, test, or document alone
   does not justify another complete CUDA/Python bundle.
3. For a dependency, native ABI, Python, CUDA, cuDNN/cuBLAS, PyAV,
   CTranslate2, or faster-whisper compatibility change, determine whether
   the existing runtime contract still holds. If it does not, assign a new
   immutable runtime ID, build and review it once, and publish it separately.
   Never mutate the bytes or meaning of an existing runtime ID.
4. Give each app release a unique identity for its exact bytes, even when
   package metadata still says `0.1.0.dev0`. Its manifest names a required
   runtime ID and pinned asset hash. Python 3.11 alone is insufficient proof
   of compatibility. Report expected fresh-install and normal-update bytes;
   an app-only update needing a gigabyte-scale download is a regression to
   investigate.

## Preserve activation and rollback

- Stage each app in its own directory; share the compatible runtime without
  modifying its dependencies. Do not require symlink privileges or global
  `PATH` changes. Run dependency/import, health/home, and applicable native
  checks before atomically changing `active.json`, the stable launcher, or
  managed shortcuts. Claim GPU inference only if exercised on GPU hardware.
- Keep the current and previous working app available. Keep every runtime
  referenced by those app states. Same-runtime rollback must require no
  download or dependency reinstall; different-runtime rollback uses the
  retained compatible runtime. Never remove project data, media, exports,
  settings, or credentials during release cleanup.
- On failure, including 404, network interruption, partial download, hash
  mismatch, manifest mismatch, and health failure, leave the active app,
  runtime, state file, launcher, and prior rollback target usable. Repair
  only the damaged layer. Migrate legacy monolithic installs side by side
  after validating their identity; do not transform a completed install in
  place or delete it before the new state passes verification.

## Implement and verify

1. Define or update schema-versioned app/runtime manifest and active-state
   contracts only when needed. Pin every remote production asset by SHA-256
   or an approved stronger mechanism. Reject unsupported future schema
   versions, archive traversal, unverified bytes, mutable `latest` URLs,
   and silent fallback to unknown releases. Preserve the required notices,
   licenses, and source material with the layer that owns them.
2. Use focused RED/GREEN tests for behavior changes. In particular, keep a
   regression proving that an app-only update fetches **zero runtime assets**
   when its required runtime is already installed and valid. Cover missing
   and incompatible runtimes, same/different-runtime rollback, legacy
   migration, corruption, interrupted transfer, and failed activation as
   applicable. Run repository checks and an installed-path smoke test.
3. Keep bootstrap responsibilities (prerequisites, first runtime, first app)
   separate from routine update responsibilities (small app release, rare
   runtime replacement, staging, verification, activation, rollback). Check
   reasonable free space before a large download and tell the user the
   expected app/runtime transfer sizes. Call an update app-only only if it
   truly avoids fetching the full runtime.

## Release order

Build, test, review, publish the immutable asset, download the **public**
asset, verify its bytes and hash, promote the public manifest or installer
pin, test the real update path, then merge/release. Never point public `main`
at an unpublished asset; that order previously caused a real 404. For GitHub
draft and large-upload recovery, follow the separate personal
`github-release-delivery` skill when available. Record exact source commit,
app/runtime identities, asset sizes and hashes, normal/fresh download sizes,
rollback behavior, CI/smoke results, and any remaining target-machine checks.

Prefer a shared immutable runtime plus small app bundles. A wheel-level
content-addressed store, binary deltas, and a custom resolver require a
separate demonstrated need; they are not prerequisites for this design.
