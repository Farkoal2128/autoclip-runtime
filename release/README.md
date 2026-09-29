# Release source inputs

This directory contains repository-maintained inputs used to construct and review AutoClip Windows runtime releases.

- `scripts/` — source-build installers, prerequisite helpers, cache tooling, and native build recipes. Release construction copies these into generated archives using their established root-level filenames.
- `manifests/` — publisher-wheel and source-artifact input manifests used by release tooling.
- `review/` — hash-bound review rules, notices, and component evidence used by successor builders.

The stable public commands remain at the repository root: `install.ps1`, `update.ps1`, `update-app.ps1`, and `Start-AutoClip.ps1`.

Do not treat a path move in this repository as permission to alter published release bytes or provenance identities. Release tooling preserves the logical archive/provenance names where required.
