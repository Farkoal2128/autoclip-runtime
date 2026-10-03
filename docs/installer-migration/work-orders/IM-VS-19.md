# IM-VS-19 — first-party pinned Microsoft payload preload

Status: prepared and fixture-verified, 2026-10-01. Guest acquisition is **not executed**. This diagnostic changes no production route or contract and executes no Microsoft code.

## Assignment and ownership

Parent authorized a new recipient-only acquisition diagnostic for exactly 397 Microsoft payload files. Ownership is limited to the three new files below and this work order. Root owns the canonical manifest, contract revision, VM, later vendor layout generation and product installation. Other writers' files and all historical evidence remain preserved. Classification: installer diagnostic; no application or runtime behavior revision.

Read runtime AGENTS, runtime-updater skill, runtime-update-architecture, installer contract, IM-VS-18 and the complete objective attachment. The current whole-layout execution gate remains in force; this script performs acquisition only, not layout generation or installation.

## Exact first-party inputs and source basis

- Frozen `vs-layout-expected-inventory.json`: 470,838 bytes, SHA-256 `545b140236b4765a964c14708dcbf1e6131497a58c1655be081631b4f8a91397`; 409 original files, of which 397 have 432 Catalog source associations. Observed payload bytes total 1,289,700,306. All URLs use `https://download.visualstudio.microsoft.com` with that exact redirect host policy.
- New diagnostic metadata derives only these 397 rows: original relative path as identity/filename, first recorded official association URL, independently observed byte size/hash, and every original Catalog association with its declared size. All 140 conflicting declared-size associations are retained; they are not silently corrected. This derives from the frozen inventory, not a mutable vendor feed.
- Unchanged production downloader `download-artifact.ps1`: 19,545 bytes, SHA-256 `75ac92e4108a6fd3165617b2c94be02b44ca86c61a5397672d898eaa38635ad6`. Its single-artifact function has no manifest-hash parameter; the diagnostic verifies and holds native read locks on both manifests and the helper through all invocations.
- Independently read actual guest OPC map `D:/AutoClip-Inno-Migration/vm-vs-opc-map-primary-51d09969e655.json`, SHA-256 `51d09969e655dc945e3697af77e0a71a928b99d2153cbc2ef731624c84bafd48`. It reports exact installed engine closure, 868 OPC members, no vendor execution and no original source inventory verification. It does not authorize this preloader or establish fresh engine acquisition. Original 368-missing source evidence is unchanged.

## Frozen prepared files

All paths below are under `D:/AutoClip-Inno-Migration/vm-transfer/`:

| File | Bytes | SHA-256 |
| --- | ---: | --- |
| `vs-pinned-preload-probe.ps1` | 13731 | `cda869256879983b0f191414dc2438633d180bb37af51f3390ff5adfbd5ab3cb` |
| `vs-pinned-preload-probe.Tests.ps1` | 6352 | `6f42f875ebfa86d26fdbbabad5cf657d78521fe47e91d01c0a819612fa8c2574` |
| `vs-pinned-preload-manifest.json` | 401840 | `15d558e950e713b20ff16c0347b0bf933087adfd1b06b3c0148f5aab74cf0efc` |

## Behavior and safeguards

Default invocation, even with `-PostResult`, returns `READ_ONLY_PLAN`, exit 0, no network or writes. Explicit `-PreloadPayloads` first requires ordinary `autocliplab`, native x64 Windows process/OS and no administrator token. It creates a fresh protected recipient/SYSTEM/administrators-only root shorter than 80 characters, whose generated name contains a space. Caller cannot supply destinations or artifact identities. A collision or reparse point stops the operation.

Hash-check and native read-lock the probe and all three first-party controls. Validate complete 397/432 metadata equality and expected totals before any vendor acquisition. Reject unsafe paths/URLs, changed rows/association sizes/classifications/redirect policies, missing/duplicate/extra rows and unknown manifest groups. Download all 397 freshly from their official URLs through the unchanged protected downloader; no original vendor cache reuse or host mirroring. Each file gets observed-size/SHA and ACL verification after acquisition and again after the complete set. Only a complete exact file set produces `VERIFIED_EXACT_397_OFFICIAL_PAYLOADS`.

`phase.json` records actual PID, completed count and current filename before every download. With `-PostResult`, an initial `/processes` observation supplies the protected stage and phase path; final full receipt goes to `/python-wizard` and compact result to `/processes`. Root must coordinate these mutable endpoints. Preserve stage and partial/failure receipt on errors; downloader's existing partial-file cleanup is unchanged. Observation timeout does not restart acquisition. The script restores TEMP/TMP and releases native read locks in `finally`.

No bootstrap, OPC or payload is executed or extracted; no certificate is imported. No generated layout controls, product installation, signatures, engine acquisition, whole-wizard success or licensing gates are claimed.

## Exact verification and evidence

```powershell
powershell -NoProfile -File D:\AutoClip-Inno-Migration\vm-transfer\vs-pinned-preload-probe.Tests.ps1
```

Initial RED, exit 1: `RED: exact Microsoft payload preloader absent.` New required acquisition behavior did not exist. After implementation, the same focused command exits 0: exact real 397/432 selection and byte total; 10 changed-manifest cases; 3 unsafe inventory cases; ordinary/native/unelevated guard; actual Windows read locks reject metadata write and rename; wrong control hash fails; first-party fake payload succeeds and corrupted bytes fail; unlocked control becomes writable; unchanged production downloader resolves the first/middle/last actual payload rows and verifies an existing first-party fake file without network; default remains read-only. Fixtures preserve their unique first-party temporary files. This is fixture evidence, not an actual Microsoft acquisition pass, signature check, or source-build result.

## Parent execution handoff

Serve only first-party code and metadata under the exact names `vs-pinned-preload-probe.ps1`, `download-artifact.ps1`, `vs-layout-expected-inventory.json`, `vs-pinned-preload-manifest.json`. Verify the frozen probe SHA before guest invocation:

```powershell
powershell.exe -NoProfile -ExecutionPolicy Bypass -File <verified-absolute-guest-probe-path> -PreloadPayloads -PostResult
```

Root alone runs VM actions. Collect exact receipt bytes/hash and inspect every payload before using any as a seed. Success would prove this bounded direct-acquisition step only. Canonical Microsoft delivery remains `BLOCKED`; vendor generation still requires the parent-controlled intentional contract/test revision and separate pre-execution checks.
