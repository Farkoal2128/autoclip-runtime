# IM-SEL-02: initialize verified runtime selection and reuse selected launchers

Date: 2026-10-03. Authorized installer/updater continuation; implementation is
limited to `installer/initialize-selection.ps1`, `update-app.ps1`, and focused
initial-selection/owned-stop tests. Other writers own Setup wiring, receipt
schema and native cleanup. No VM, vendor acquisition, publication or public pin
changes were performed by this work order.

## Requirement and boundary

Fresh installation must select its verified installed runtime before routine
app updates. The normal Start Menu launcher must resolve the selected runtime
and app through the existing updater-generated stable desktop launcher.
Initial activation never replaces another runtime/app selection or rollback
reference. Existing modified or unknown launchers remain intact.

Preparation accepts the hash-pinned finalization request, validates context,
source handoff, exact installed manifest/completion and a new isolated installed
health check, then creates only absent stable launcher bytes. An existing stable
launcher is accepted only when its bytes are exactly the updater-generated UTF-8 bytes.
The COMPLETE schema2 ownership receipt records the finite base launcher rows
before activation. Activation requires that exact receipt, its protected anchor,
all installed release/base rows, source handoff, and another actual health check.
Both phases use the existing recipient selection mutex. `active.json` is written
atomically only after the checks. Same exact initial state is a no-op; another
runtime, an app selection, or a previous rollback reference is refused.

The helper uses only pinned first-party receipt/updater bytes. It imports the
existing updater mutex, health and launcher functions; it adds no runtime
resolver or remote acquisition. Initialization writes no app manifest and makes
no new CPU compatibility or production readiness claim.

The optional updater `StopOwnedApp` callback runs after the selection mutex and
runtime identity checks, before the existing port check. The maintenance worker
supplies the separately pinned existing ownership verifier/stop function. The
normal standalone updater still requires the app to be stopped. Callback
refusal leaves selection intact; the selection mutex remains held across stop,
staging, activation and restoration. The callback has no authority on its own
and is not derived from an untrusted remote manifest.

## Evidence

RED before production edits:

```powershell
powershell.exe -NoProfile -ExecutionPolicy Bypass -File tests/InstallerInitialSelection.Tests.ps1
```

Failed: `RED: initial runtime selection helper is missing.` The test now executes
actual selection writes, conflict/idempotence checks, updater-generated stable
launchers, and preservation of changed launcher bytes. It also invokes the actual
pinned helper against unsupported COMPLETE receipts and mismatched anchors.
A real compiled inert first-party child returning exit1 is placed in a complete
source-handoff fixture: despite its retained successful health receipt, the
actual fresh child check fails before any selection/launcher mutation. This is
an orchestration fixture, not proof of an installed AutoClip health result.

GREEN commands:

```powershell
powershell.exe -NoProfile -ExecutionPolicy Bypass -File tests/InstallerInitialSelection.Tests.ps1
powershell.exe -NoProfile -ExecutionPolicy Bypass -File tests/UpdaterOwnedStop.Tests.ps1
powershell.exe -NoProfile -ExecutionPolicy Bypass -File tests/UpdaterSelectionLock.Tests.ps1
git diff --check
```

All passed. Owned-stop tests execute the actual updater entry and observe its
mutex from another native process during callback execution; unknown-process
refusal preserves the selection. An incomplete runtime prevents the callback.
Existing updater selection tests passed normal, already-current, rollback,
removal, restoration, unsafe ACL/reparse and abandoned-ownership paths.
`git diff --check` reports existing line-ending conversion warnings only.

`UpdateAppDatabaseRollback.Tests.ps1` was attempted without its mandatory
`InstalledRoot`/`FixtureRoot`; it did not run. Actual generated Setup, schema2
receipt success, installed application/media, uninstall, and production updater
integration remain parent-owned VM/release checks. No tests were disabled or
assertions weakened by this work order.
