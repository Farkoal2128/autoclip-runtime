# IM-WIZ-34 - pinned source receipt integration

Status: authorized source integration complete and frozen for parent composition.
Owned only install.ps1, run-source-build.ps1, new
InstallerSetupReceiptSource.Tests.ps1 and this report. Parent retains receipt
helper, Inno, builder, contract and final native integration ownership. No app,
manifest, archive/immutable recipe, historical report, existing test, VM,
vendor, Setup, uninstaller or publication action was changed/executed here.

## Requirement, caller interface and compatibility

Contract-v1 inspected SHA256:
`3eb9e4fbfb08d5aeb58f5b0aaa5a57ae044795d7bf537d9febed763c9f966f35`.
Parent added the explicit source/final receipt section during this work; the
reconciled final contract SHA is
`315b7d21959d458bab0047917d938e2c954ce61f5a56edff39a25bb63f07688f`.
The approved receipt route must establish provenance before release overwrite
or source/tool execution, write the source handoff before marker inside the
existing commit boundary, and preserve no-pin standalone behavior.

Added optional source parameters `SetupReceiptHelperSha256` and
`BootstrapIdentitySha256`. Supplying either requires both valid pins and existing
health/dependency pins. Bootstrap imports fixed adjacent
`write-setup-receipt.ps1` (repository installer/ fallback) from verified bytes
**once**, retaining helper functions/proof in source scope. Context is the
approved nine fields: actual root, fixed release ID/profile and exact archive,
release-manifest, dependency, bootstrap, new receipt-helper and health-helper
pins. `source_helper_sha256` denotes the receipt producer helper pin.

Supervisor accepts typed JSON `SetupReceiptHelperSha256` only. Actual Worker
injects `BootstrapIdentitySha256=$BootstrapSha256` from its already-held source
pin; JSON-supplied BootstrapIdentitySha256 remains unsupported and rejected
before worker launch. Native hidden/responsive/cooperative behavior is unchanged.
Root wires the new helper pin; it must never supply the bootstrap identity in
remote/generated JSON. Standalone with neither new pin follows the retained
path. Existing completed-root refusal is preserved; final-shell repair is
parent-owned Inno work.

## Minimum source changes

Managed matching partials call actual `Assert-SetupStartingProvenance` immediately
after the existing manifest/root recognition, before the first subsequent
native prerequisite/tool boundary. Unknown .venv/publisher-wheel data is refused
and preserved. Empty protected managed roots are accepted for fresh preparation;
no-pin empty-root handling is unchanged. Static-only and authenticated dynamic
partials keep matching retry; only an actually registered proof allows the
known source-handoff file through the existing later scan.

For a fresh route, keep the original archive hash guard, stage just the exact
bounded release-manifest ZIP entry outside the release in protected attempt
storage (or a fresh protected temp stage), obtain actual starting proof, then
create a recipient/SYSTEM/Admin protected child directory before Expand-Archive.
All entry/archive handles close on failure/success. Existing post-extraction
manifest/file validation and recipe stay in place. Snapshot is retained for
diagnostics; no release mutation precedes proof. A managed empty root obtains
the same fresh proof after pinned manifest staging.

After existing actual health and required launcher/native extension publication,
the actual completion action calls `Write-SetupSourceReceipt` before writing
marker. Producer failure propagates without a marker. Denied marker write leaves
the valid handoff and authenticated launcher available to the next matching
source attempt. Completed-marker repair is not enabled in bootstrap.

## RED and GREEN evidence

Before production edits, actual source slices/actions failed these commands:

```powershell
powershell -NoProfile -File tests/InstallerSetupReceiptSource.Tests.ps1 -Case Early
powershell -NoProfile -File tests/InstallerSetupReceiptSource.Tests.ps1 -Case Completion
powershell -NoProfile -File tests/InstallerSetupReceiptSource.Tests.ps1 -Case Fresh
```

Each exit1: actual early source accepted foreign dynamic partial before the
following native-boundary sentinel; actual launcher/receipt completion reached
marker without a handoff; actual fresh source extracted without registered
provenance/protected child. Ownership validation/producer were not mocked.

A further meaningful RED found normal producer composition:

```powershell
powershell -NoProfile -File tests/InstallerSetupReceiptSource.Tests.ps1 -Case Composition
```

Exit1 `Receipt staging must be protected.` Actual Inno Python LogDirectory was
resolved into isolated first-party LocalAppData, actual Python helper declined
terms before vendor execution but produced its directory/receipt, and its
AutoClip parent inherited trusted permissions without a protected bit. Source
fresh proof incorrectly rejected that existing parent. Parent authorized and
implemented the receipt-helper's **absent-target-only** protected-bit removal.
Existing targets still require protected DACL; source creates the new protected
child after proof. Parent ACL/Python receipt remain unchanged. This coordinated
helper revision belongs to parent and does not rewrite WIZ33 historical pins.

The empty-protected-root predicate was separately tested RED before its small
managed-only source change: actual early source rejected an empty protected
release. It now takes the fresh staging/proof route without relaxing standalone
or foreign-file behavior.

Final focused command:

```powershell
powershell -NoProfile -File tests/InstallerSetupReceiptSource.Tests.ps1
```

Exit0, six PASS groups: actual early partial/empty/static/no-pin boundaries;
actual completion with real COM shortcut, real helper inventory and handoff
before denied marker followed by actual successful retry scan/action; actual
fresh archive/manifest/protected root; two real first-party native worker routes
checking held-source identity injection and JSON bypass refusal; actual declined
Python producer composition without parent ACL/receipt changes; actual fixed
helper import with paired/changed pins and no-pin path. Final fixture preserved:
`C:/Users/beilo/AppData/Local/Temp/autoclip-source-receipt-e0e939c4f7ab4496a3440b6a93b5ab8c`.

The early native sentinel represents the next source side-effect boundary; no
vendor was invoked. Completion uses real first-party files/shortcut and an
explicit marker failure fixture, not a fake ownership verdict. Native fake
bootstrap tests identity plumbing only, never app health.

## Adjacent verification

All executed with exit0; no existing test/assertion was changed:

```powershell
powershell -NoProfile -File tests/InstallerCompletion.Tests.ps1
powershell -NoProfile -File tests/InstallerBuildAppHealth.Tests.ps1
powershell -NoProfile -File tests/InstallerBuildStorage.Tests.ps1
powershell -NoProfile -File tests/InstallerBuildInput.Tests.ps1
powershell -NoProfile -File tests/InstallerBuildProcess.Tests.ps1
git diff --check
```

These cover existing launcher/denied-marker retry,18 health-boundary fixtures,
durable/concurrent target storage, original-input terminal behavior, chatty
native workers, typed/hash/ACL/reparse checks, nonzero exit, cancellation and
both commit orderings. The final focused source command was rerun after the
managed-empty-root predicate adjustment. Compiler/actual native setup event
composition and full source build remain parent verification.

## Frozen interface and limits

- Bootstrap SHA256 `a09ccee22724855ab6b31321397b5deec9e02946795ebf781893b910d21a2734`.
- Supervisor SHA256 `e4cf86c90b1b7d750c7aec58628b34aa457505ac8cdedec8f8424255a183313d`.
- New integration test SHA256 `59c062240d3506270dc07168e4b7ffccc3b32738b86ced06ee3cd5d673ba5e18`.
- Parent-owned producer at final verification SHA256 `ebca5009c6c44521b1abc1793e9543d41d0ce910f689f8fccee800062345ee0f` (includes parent's final CLI and absent-parent correction).

Old packets need new exact bootstrap/supervisor/helper input pins and compiler
receipt. Root must wire/prove the final native event timing, actual registry
queries, setup success/failure display and final receipt publication. These
host tests do not qualify the immutable vendor recipe, actual application health,
native Setup/uninstaller, GPU, production readiness or release. User's generated
uninstaller test remains strictly after production installer readiness and before
release. No speculative target chooser or universal legacy partial adoption was
implemented.
