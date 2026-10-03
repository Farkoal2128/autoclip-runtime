# IM-UN-06: bounded receipt-owned cleanup consumer

Date: 2026-10-02. Authorization: recipient answered "Yes—stop AutoClip/updater
and preserve modified or unknown files". This resolves the stronger unrelated
writer exclusion requirement through an explicit actor cutoff in contract-v1.
Generated uninstaller tests remain after production installer readiness.

## Ownership and scope

Implementer owns uninstall-owned-release.ps1, InstallerUninstallReceipt.Tests.ps1,
the finite cleanup-helper extension to write-setup-receipt.ps1 and its existing
producer test, this work order and the contract addendum. Root/another writer
owns Inno integration. No VM, vendor, generated uninstaller or release executed.
Actual per-run model telemetry is not exposed.

## Behavior and interface

CLI arguments: ReceiptPath, ReceiptSha256, ReleaseId, InstallRoot,
ReceiptHelperSha256, RemovalHelperSha256, SourceBuildHelperSha256, UpdaterSha256;
optional Preflight. Caller validates its own compiled consumer pin and protected
receipt SHA anchor. Durable sibling dependencies are the exact five finite
names in the contract. The helper reuses the receipt library, native owned-file
primitive, updater selection mutex and source target lock. No downloads occur.

Preflight outputs schema1 VERIFIED_UNINSTALL_PREFLIGHT with release/root/receipt
hash. Cleanup outputs schema1 REMOVED or PRESERVED, removed paths, preserved
path/status rows and selection RESET/PRESERVED. Invalid authority, pins,
inventory, lock, native pair, registration or active reference fails before
file removal with exit1. Exact current-only state may reset; app/rollback
references remain refused and preserved. Root-bound owned desktop/CLI processes
are stopped; unknown release processes remain refused. Updater contention fails
before mutation. Only receipt rows are removed, with the existing ADS/hash/type/
ACL/handle checks unchanged. Unknown files and nonempty/unsafe directories stay.

Setup notices and exact Start Menu shortcut are consumer-owned cleanup; native
helper files, registration and generated uninstaller pair remain Inno-managed
after strict preflight. Finalize now accepts helpers[] and records the five
rows plus complete sorted registration values and absence of subkeys. Legacy
producer library calls may omit the additive helper set; cleanup rejects such
receipts. The actual new Finalize entry point requires the complete helper set.

## Evidence

`powershell.exe -NoProfile -NonInteractive -File tests/InstallerUninstallReceipt.Tests.ps1`
RED: receipt-owned uninstall consumer missing. GREEN: actual protected native
fixture removed unchanged bytes/owned empty directory, preserved modified,
unknown and actual ADS bytes; rejected duplicate/traversal inventory before any
partial removal. Fixture directories retained for evidence, no recursive erase.

`powershell.exe -NoProfile -NonInteractive -File tests/InstallerSetupReceipt.Tests.ps1`
New finite-helper behavioral case RED: Unsupported native output scope. GREEN:
all existing producer behavior plus exact five-helper receipt publication.

`powershell.exe -NoProfile -NonInteractive -File tests/InstallerSetupReceiptSource.Tests.ps1`
Actual early/source/completion checks passed, then existing Python-log-location
fixture failed: Actual Python log directory could not be resolved. No assertion
was weakened; this does not qualify source integration or generated uninstall.

## Remaining verification

Root must integrate anchored receipt metadata, durable pins, native callbacks,
preflight refusal and native managed rows. Start Menu AutoClip root must satisfy
the protected directory ACL required by the unchanged file primitive; otherwise
shortcut cleanup safely preserves it. Actual process stopping, full native
Registry64 comparison, repaired finalization, cleanup selection and generated
uninstaller still require integrated checks. No desktop shortcut ownership is
invented: the current final producer records folder and Start Menu links only.
An unrecorded Desktop link remains preserved pending an explicit producer row.
The exact generated uninstaller is tested after the installer is ready.

## Entry-boundary follow-up

Parent requested actual CLI verification after reviewing the initial core-only
test. The same test now starts native PowerShell children running the consumer
with isolated first-party receipt, inert native pair and actual HKCU Registry64
registration. Only native folder discovery and registry key location are
redirected to fixture scopes. Real receipt/hash/ACL/schema, pinned helpers,
selection mutex, source target lock, registration comparison and cleanup execute.
It verifies valid preflight without deletion; bad receipt/helper pins, foreign
SID, malformed schema/context, changed helper/native DAT, unknown registry
value/subkey and current/previous/app references all refuse before deletion.
Current-only selection resets, missing owned files remain retryable and a fully
removed root can be retried successfully.

Three behavioral failures drove small fixes:

- Missing-root retry RED reported PRESERVED; GREEN skips removal of an absent
  release root rather than interpreting its absence as unsafe.
- Actual first-party native process RED refused an unchanged identity because
  CIM truncates creation time to microseconds while the native API retains
  100ns ticks (observed difference 9 ticks). GREEN compares those same timestamps
  at CIM precision. The test launches an inert first-party process under the
  receipt-owned executable path with the actual desktop module command and
  observes it terminal at consumer return. A second actual root process with
  an unknown module command remains alive and leaves selection/files intact.
- Missing bootstrap identity field RED was accepted; GREEN reuses the exact
  context validator and checks the complete receipt fields/evidence bindings.

Parent authorized the minimal `AllowInheritedRoot` primitive overload for
validated active.json and the fixed Start Menu link. Inherited-base RED refused
exact owned current state; GREEN accepts a trusted inherited DACL while retaining
default protected-root rejection and foreign-write refusal. Actual CLI fixtures
also use trusted inherited AutoClip/Start Menu parents. The existing four-argument
native method still requires a protected root. Existing native owned-file guard
regression passed, including during-hash ADS preservation, locks, ancestor
rename/write exclusions, foreign ACLs, links, reparse and invalid-row cases.

The Python composition failure was a stale fixture shape: actual PreparePython
now calls PythonLogDirectory. The test follows that actual function, additionally
requires exact AutoClip/PythonSetupLogs, then runs the original real producer/
source composition assertions. Full InstallerSetupReceiptSource.Tests.ps1 PASS.
No production Python behavior or previous preservation assertion changed.

Commands all PASS:

```powershell
powershell.exe -NoProfile -NonInteractive -File tests/InstallerUninstallReceipt.Tests.ps1
powershell.exe -NoProfile -NonInteractive -File tests/InstallerOwnedFileRemoval.Tests.ps1
powershell.exe -NoProfile -NonInteractive -File tests/InstallerSetupReceipt.Tests.ps1
powershell.exe -NoProfile -NonInteractive -File tests/InstallerSetupReceiptSource.Tests.ps1
git diff --check
```

Actual application/installed-model processes and the generated native
uninstaller remain integrated VM checks; these first-party boundary fixtures
do not qualify the final installer or native uninstall callback ordering.

## IM-UN-08 consumer and Finalize evidence

Root's versioned Inno source inspection identified a production blocker:
the generated native process owns DAT read/write exclusively before callbacks.
The actual CLI fixture opened that DAT with ReadWrite/FileShare.None and the
old callback produced expected RED, exit1 with its exact sharing violation.

The authorized minimal route adds LaunchNativeUninstall to the same consumer.
It validates anchored receipt, five helpers, EXE/DAT/optional MSG bytes, size,
authority, regular single-link identity and absence of unknown streams before
native launch. It writes one fresh protected uninstall-handoffs/<nonce>.json,
binding recipient/root/receipt hash, launcher PID/path/exact start and native
hashes plus observed identity/metadata. It then releases selection/target and
input read handles before launching native Inno, retaining only the protected
handoff read handle while waiting. This releases DAT for Inno's exclusive open
and does not block native receipt/helper retirement. Callback reacquires
selection then target through authority/state validation and cleanup.

Callback requires HandoffPath/HandoffSha256, exact schema, live launcher identity
and actual recipient-owned ancestry containing the verified native binary (its
same-hash native temp copy is allowed). Accessible native bytes are rehashed;
DAT uses a zero-data-access Win32 identity/metadata query that works with the
exclusive native handle. DAT content hash scope remains the prelaunch check.
No CRC, continuously held DAT/selection lock, or atomic unrelated-writer
guarantee is claimed. Direct invocation, stale handoff or wrong ancestry refuses.

NativeSilent is permitted only in launch mode and adds exactly VERYSILENT and
NORESTART native arguments. No arbitrary forwarding is implemented. Finalize
requires native_uninstaller, uninstall_command and quiet_uninstall_command in
the pinned request; both actual registry commands must match exactly, and the
finite native path must bind to the generated pair. Compiled Inno's protected
request is the command authority; the writer does not claim to authenticate
arbitrary PowerShell text independently. The complete native path and sorted
registration values are retained in the final receipt.

GREEN uses an actual separate first-party native EXE holding DAT read/write with
FileShare.None throughout the real consumer callback. The native lifetime/ancestry
boundary is real; the fixture has no generated Inno uninstaller behavior. It
proves callback validation/cleanup under that conflict, same actual root-bound
process stopping, after-prelaunch DAT metadata refusal, beforelaunch changed-byte
refusal, stale/wrong-process refusal and both default/quiet launch modes. A root
unknown file with all recorded rows removed produces PRESERVED without deleting
those bytes, preventing false receipt retirement. Once that fixture-owned file
is explicitly removed, missing-file/root retry returns REMOVED.

InstallerSetupFinalize.Tests.ps1 now includes a positive actual native CLI call.
It uses real producer source/health/launcher proof, a protected pinned request,
five exact helpers, an inert pair and real isolated HKCU Registry64 values. It
verifies COMPLETE publication, all eleven native rows, both registered loader
commands, native path, actual final receipt hash and request-result handoff.
Only native folder discovery and the HKCU namespace are redirected. No vendor
installer, generated AutoClip uninstaller or VM was executed.

All four repeated commands PASS, followed by diff check PASS:

```powershell
powershell.exe -NoProfile -NonInteractive -File tests/InstallerUninstallReceipt.Tests.ps1
powershell.exe -NoProfile -NonInteractive -File tests/InstallerSetupFinalize.Tests.ps1
powershell.exe -NoProfile -NonInteractive -File tests/InstallerOwnedFileRemoval.Tests.ps1
powershell.exe -NoProfile -NonInteractive -File tests/InstallerSetupReceiptSource.Tests.ps1
git diff --check
```

Consumer SHA256: 89440e2d696ca4225c2efa2ecee3afaa1eaf82a9688eba218db684c960f34a30.
Writer SHA256: 1bc730f7ddd57f7eb82a2d1e03d91b7a3f285a262517a0eabd6fdf6e6ba21aa4.
Native removal helper SHA256 remains
9f514a716d2b05ef55dc81abf3c3079ed710a451d3cc12657b63d5233b5481f5.
Exact generated native temp-copy lifetime, final installed registration and
installer-then-uninstaller VM evidence remain with root before release.

Root's versioned primary-source review subsequently confirmed the original
uninstaller engine/live launcher remains valid through InitializeUninstall and
usUninstall, but the original engine is terminated during native Perform before
usPostUninstall. The launcher reports only NATIVE_ORIGINAL_PROCESS_EXITED,
native_original_exit_code and native_post_uninstall_observed=false. It does not
equate that original-process exit with complete native teardown or receipt
retirement. The existing separately qualified post-native evidence is required.
