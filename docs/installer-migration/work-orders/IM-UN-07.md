# IM-UN-07: integrate finite cleanup with the generated Inno uninstaller

Date: 2026-10-02. Parent assignment follows the user's instruction to stop
AutoClip/updater, remove owned installed files and preserve modified/unknown
files. Exact generated-uninstaller testing follows the working production
installer. This work owns Inno/builder integration and focused tests; the
receipt/cleanup helper producer has separate ownership.

## Contract and integration

Five durable helpers are installed under the protected Setup root:
`uninstall-owned-release.ps1`, `write-setup-receipt.ps1`,
`remove-owned-file.ps1`, `run-source-build.ps1` and `update.ps1`.
The builder locks their inputs, supplies their exact hashes and a finite
`SetupHelperRows` inventory, and records their provenance in its candidate
receipt. The finalization request supplies those helper rows to the separate
receipt producer. Existing historical snapshots/public bootstrap pins remain
unchanged.

The final installation receipt is published before its independent SHA-256
anchor, `installation-receipts/<release-id>.sha256`. Anchor publication checks
the descriptor, exact final file size/hash, COMPLETE identity and protected
scope, then creates the finite anchor atomically. Identical retry succeeds;
changed existing evidence is preserved. Setup completion is reported only
after anchoring succeeds.

`InitializeUninstall` calls read-only, pinned consumer preflight. It performs
no cleanup. The consumer validates the final receipt, canonical release root,
generated native pair and complete uninstall-registration snapshot. Unknown
authority/helper/receipt/native/registration state rejects initialization.
The shared runner holds all five helper inputs against modification while
the consumer executes. Child exit, single-result framing, schema and expected
status/context fields must agree.

Cleanup runs only at post-confirmation `usUninstall`. A nonzero child or
invalid result stops native uninstall using the documented `Abort` event
route, preserving the native shell and receipt for failure recovery.
Schema-valid REMOVED/PRESERVED results permit native teardown. PRESERVED
reports retain the receipt/anchor and explain where manual-review evidence
is kept. Modified/unknown files are expected preservation outcomes.

Installed notices and the Start Menu shortcut use `uninsneveruninstall`;
the finite consumer removes only matching owned instances. Native Inno
cannot independently erase those modified objects. Durable helpers remain
native managed and are removed after the consumer releases its input locks.
New owned shortcut directories receive the existing protected directory ACL;
existing directories are validated for owner/path/foreign writes without
changing their ACL. Trusted inherited ACLs remain supported.

For a clean REMOVED outcome, only the pinned receipt/removal helpers and a
finite retirement checkpoint are copied into protected Setup logs before
native teardown. `usPostUninstall` checks the native pair and registration
are absent, then uses the existing owned-file remover on the exact receipt
and anchor rows. Changed evidence is preserved. Logs/cache and the bounded
checkpoint/helper copies remain diagnostic evidence; no recursive deletion
or ordinary hash-then-Pascal-delete shortcut was introduced.

Official references inspected:
[uninstall code](https://jrsoftware.org/ishelp/topic_scriptuninstall.htm),
[events](https://jrsoftware.org/ishelp/topic_scriptevents.htm),
[Abort](https://jrsoftware.org/ishelp/topic_isxfunc_abort.htm),
[installation order](https://jrsoftware.org/ishelp/topic_installorder.htm),
[file flags](https://jrsoftware.org/ishelp/topic_filessection.htm),
[shortcut flags](https://jrsoftware.org/ishelp/topic_iconssection.htm).
The Abort documentation specifically permits termination from
`CurUninstallStepChanged(usUninstall)`. Installation order places finalized
native uninstall files before post-install receipt generation.

## RED and GREEN

Working directory: `D:/Projects/autoclip-runtime`.

```powershell
powershell.exe -NoProfile -NonInteractive -File tests/InstallerUninstallWizard.Tests.ps1
python -m unittest discover -s .github/tests -p test_inno_build.py
powershell.exe -NoProfile -NonInteractive -File tests/InstallerPublisherCpuConsent.Tests.ps1
git diff --check -- installer/AutoClip.iss scripts/build-inno.py .github/tests/test_inno_build.py tests/InstallerUninstallWizard.Tests.ps1
```

Compiled RED recorded `Initialization omitted read-only preflight or
performed cleanup` in
`C:/Users/beilo/AppData/Local/Temp/autoclip-uninstall-wizard-eb75c573620949be94449cfe41c29cdc/result.txt.log`.
Builder RED showed the updater remained writable during compilation and
`uninstall_helper_sha256` was absent from the build receipt.

GREEN: the actual callback bodies compile and execute against an inert
consumer boundary, proving initialization does not clean, only the confirmed
stage cleans, failed cleanup aborts native continuation, clean post-native
completion retires evidence, and PRESERVED outcomes retain evidence. All
actual runner/anchor/retirement/shortcut Pascal command functions compile;
their captured PowerShell commands parse.

Actual private protected fixtures exercise final-anchor creation, identical
retry and rejection of changed receipts. The captured retirement command
uses the real existing removal helper against only two fixture evidence
files: changed evidence is preserved, exact evidence is removed after
simulated absent native files/registration. This check found and corrected a
PowerShell array-concatenation bug in the finite expected-path list.
No project uninstall key was mutated and no installed runtime was removed.

All 14 builder tests pass, including original assertions and write/rename
locks extended to the new helper inputs. The existing compiled CPU consent
regression passes. Scoped whitespace validation passes. No tests were
disabled or assertions weakened.

The focused diagnostic also compiles the actual `FinalizeSetupReceipt`
procedure, constructs its five-helper request/context/source-handoff and
executes a first-party producer fixture with the actual request hash. It
confirms the anchor callback precedes Setup completion. This producer
fixture is a boundary check; the separate real finalization CLI regression
owns receipt producer and native registration behavior.

## Limits and remaining gate

These are same-session implementation checks, not blind approval. The
consumer's separate tests own process/selection/file/registration behavior.
This work did not run a generated uninstaller, vendor installer or VM
lifecycle and did not publish. Root owns the new immutable archive/full
Setup compile, exact review and working-installer verification, followed by
the actual generated uninstall test. Inno's real native file/registry ordering
and sharing behavior still require that lifecycle evidence. GPU hardware
tests remain deferred by the user.

### Concrete native DAT blocker discovered by root

Root inspected the exact official
[Inno 7.1.0 uninstall source](https://raw.githubusercontent.com/jrsoftware/issrc/is-7_1_0/Projects/Src/Setup.Uninstall.pas):
`OpenUninstDataFile` opens the DAT without sharing, and `RunSecondPhase`
reopens it for exclusive read/write before `InitializeUninstall`. The current
consumer's separate `Get-SetupReceiptFile` read of that DAT therefore cannot
be accepted as a working generated-uninstaller preflight. The unlocked
first-party DAT fixtures do not prove that sharing boundary.

Integration is held at this production blocker. No conditional hash skip,
CRC-as-cryptographic-pin reinterpretation or native sharing bypass was added.
Root is reconciling a documented authority/handoff route before a new
candidate can pass this gate. The same source places native uninstall-data
deletion before `usPostUninstall`, supporting the intended retirement order,
but no actual generated-uninstaller lifecycle claim follows from source
inspection alone.
