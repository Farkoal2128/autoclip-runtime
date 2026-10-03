# IM-SEL-01: updater selection serialization

## Assignment

- Parent: conventional production Inno installer; exact generated uninstaller
  test after installer qualification, then authorized release. NVIDIA deferred.
- Authorization: implementation, contract-first TDD for updater selection safety.
- Preferred role: implementer, GPT-6.1 Sol/medium; actual routing not exposed.
- Owned files: `update.ps1`, `update-app.ps1`, new
  `tests/UpdaterSelectionLock.Tests.ps1`, and one new external evidence report.
- Not alone: preserve others' edits; root owns contract/docs. Do not edit installer
  source/bootstrap/receipt, removal primitive, manifests or existing tests.
- Dependencies: read AGENTS, updater skill/architecture, new activation/cleanup
  contract section, IM-UN-03 report. RED must precede production edits.
- Parallel safe: separate read-only investigation of ADS native safety.

## Bounded implementation

Use standard .NET native named Windows mutex, not another persistent disk-lock
subsystem. One `Global` name per current SID and canonical local base (versioned
prefix plus SHA256) permits cross-session exclusion. Restrict and independently
check actual mutex owner/DACL to recipient/SYSTEM/Administrators. Fail closed
against foreign/precreated/ambiguous authority. Same-base aliases normalize to
one name; different bases remain independent. Reject reparse alias paths. Keep
PS5 standalone script compatibility; investigate any existing Windows PS7 support
before changing that boundary. No helper/code download, dependency or plugin.

Acquire before first activation/reference read, retain through complete runtime/
app updater transaction, including rollback, normal and already-current paths,
installer child completion, restoration and exceptions. Release and dispose on
every outcome. Contention fails before mutations. Abandoned ownership may be
acquired, but full normal validation under the new ownership remains mandatory.
Selection-before-target ordering: source-only installer children must not
reacquire this selection mutex. Do not change active/app state schema or payload
selection, media behavior, GPU/default policy, public pins or immutable archives.

Reuse existing patterns; small identical inline lock helper in the two standalone
scripts is acceptable when extracting a shared module would break standalone
delivery. Do not turn this into a generic locking framework or test-only switch.

## Required proof

Write smallest real ordinary-user protected inert two-process tests. Demonstrate
RED before production changes: actual updater cannot reach first state read or
any writer while another participant holds selection. Exercise both actual
script entry/transaction boundaries, not merely a mock Write-AtomicText or source
string check. Existing script functions may be extracted/imported for the lock
API test, but this alone cannot prove transaction lifetime. Record any fixture
adaptations honestly; installed-app/release gates remain unexecuted.

Cover same-base/case/separator exclusion, different-base independence, release
after failure/return, unsafe mutex/reparse authority, and actual updater early
failure before acquisition/download/manifest/application execution when held.
No network/server substitution in production, no runtime/vendor acquisition,
actual user data/installs, VM, generated installer/uninstaller, policy/trust/clock,
signing, consent or publication actions. Preserve first-party fixture/process
ownership and do not kill unrelated processes. Use own bounded children only.

Return exact RED/GREEN, tested lifetime/caller scope, file hashes/diff, parser and
affected existing regression results, fixture paths and known legacy/PS7 limits.
Stop on unresolved contract conflict; don't weaken or update valid existing
assertions merely to obtain GREEN. This work closes no installation, ADS
preservation, generated-uninstaller, legal or release gate.

## Returned evidence and root integration

Implementation report, root inspected and hash checked:
`D:/AutoClip-Inno-Migration/selection-lock-ims01-3dbe74239d7a4d19b2bdf8c141fe6b77.md`
(47064 bytes; SHA256
`d7201752eb07f87b04aa83a4942a18c46fee384eb8300982bc484fadc66bd141`).
The agent records actual-entry RED before production changes, focused GREEN,
seven affected regression passes and all inert lifetime-test adaptations.
Preferred implementer role was used; actual model/reasoning routing is not exposed.

Frozen files:

- `update.ps1`: `1ac50999b779b2a768daa63af6f3a06c48d48c204f2d9f2a5014a31be10a08e9`
- `update-app.ps1`: `370af12a859b9cf52280f2c5f57c3e0868f1577940d6d661899ba0b510311e71`
- test: `68d541157af2a5e9efbb6a93418696997ab129d33e5305b548fd3e46d822345d`

Root inspected the identical acquisition helpers, complete outer transaction
boundaries and source of the lifetime/authority tests. Independently reran
`powershell.exe -NoProfile -NonInteractive -File tests/UpdaterSelectionLock.Tests.ps1`:
exit0, protected retained fixture
`C:/Users/beilo/AppData/Local/Temp/autoclip-selection-ba004a428b7e481bb9f5ed2dd23973db`.
Actual-entry contention/authority/exception tests and adapted inert full
transaction/rollback/restoration tests passed. Parser and `git diff --check`
passed. This is internal verification of participating updater serialization;
PS7, cross-session runtime, installed updater/app, immutable older nonparticipants
and native generated-uninstaller qualification remain separate and unverified.
