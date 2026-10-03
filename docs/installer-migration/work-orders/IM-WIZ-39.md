# IM-WIZ-39: exact completed source reuse for setup repair

## Assignment

- Parent objective: production Inno installer migration, then exact generated
  uninstaller cleanup/data-preservation testing, then authorized release.
- Authorization: implementation with contract-first behavioral RED/GREEN.
- Read-only contract inventory: `/root/repair_contract_inventory`,
  `contract_reviewer`; configured GPT-6.1 Sol/high, actual runtime routing not
  exposed. No implementation or blind approval role.
- Implementation: bounded source worker/health integration and focused tests.
  Root owns this contract and work order; writers must preserve others' changes.
- Governing sources: runtime updater skill/architecture and
  `docs/installer-migration/contract-v1.md` source ownership/finalization rules.

## Requirement and scope

An exact matching completed source layer can be verified without modifying it
and reused when recovering failed final setup receipt publication. Current
`install.ps1` rejects every completed marker before provenance verification.
The existing `Invoke-AutoClipAppHealth` also rewrites native-build-receipt.json,
which would invalidate a retained handoff. Use its existing pinned helper and
result validation with a read-only option; obtain fresh external health evidence.
Verify full provenance again before cooperative completion and return before
source extraction/build/launcher/marker writes. Retain exclusive worker target
locking and cancellation semantics. Preserve standalone no-pin refusal.

First prove failing behavior with focused actual source-boundary execution and
a pinned inert first-party health helper. Verify unchanged hashes and rejected
unknown/modified source, marker, identity and health/cancellation failures.
These fixture tests do not prove actual installed application health success.

## Allowed and forbidden actions

Allowed production edits: `install.ps1` completed-source guard and existing
health wrapper; focused tests under `tests/`. Root retains docs ownership.
Forbidden: vendor acquisition/installation/acceptance, VM manipulation,
uninstaller execution, source ownership weakening, broad unrelated rewrites,
receipt blanket replacement, publication or commit/push. The SDK consent
question remains pending. The previously rejected prerequisite-acquisition
command preparation must not be retried or bypassed.

## Remaining integration boundaries

Inno currently prepares prerequisites/downloads before invoking this worker;
an earlier wizard reuse route remains needed. The existing COMPLETE receipt
binds actual native uninstaller bytes; a changed native log can conflict.
Receipt renewal requires independent pre-mutation ownership validation and
an intentional pinned replacement contract, not this source reuse permission.
Historical producer hashes cannot be silently rebound to current code. Final
candidate install/lifecycle/health and generated uninstaller tests remain open.

## Evidence

Actual source guard RED was captured before implementation in
`D:/AutoClip-Inno-Migration/wiz39/red-e54ad85c5ca24dd287e5dff0aca9165d.log`:
valid completed source refused, native fixture child7 and test1. Source was
pre-WIZ39 SHA256
`a09ccee22724855ab6b31321397b5deec9e02946795ebf781893b910d21a2734`.

An additional real-child decision-lock race reproduced RED before the race fix:
`race-red-bf184e55d58f415f9a0fa3d069aef440.log`. The test held the actual
decision.lock until fresh health returned, changed an inert owned source file
while the child remained live, then released the lock. The source guard
incorrectly returned0, test1. Rechecking marker/provenance in the actual commit
action now refuses that change. The decision may truthfully remain COMMIT_STARTED
after this action fails; it is not a success marker, and the child returns failure.

Final source SHA256
`5b299406d9b007e4b2300db5953f2cfd5a14e9d6e0dadbb6b2fec4f18eefbea3`.
Implementation is limited to the existing health wrapper and completed-source
guard. Read-only health requires a pinned helper and new external protected
attempt, validates its actual returned result and preserves native receipt.
Reuse checks provenance before health, afterward and under the cooperative
decision lock, then returns before FFmpeg initialization and runtime work.

New `tests/InstallerCompletedSourceReuse.Tests.ps1` SHA256
`9a671e7c6c59de753dacd2e79806fcc6eeee99d18117fc3a84a65bd322c534b4`
executes actual extracted source/health/commit code with pinned inert first-party
health results and native filesystem/ACL/COM shortcuts. Thirty-two cases cover
valid reuse/read-only health, standalone refusal, changed/missing/unknown source,
directory/marker/provenance/producer/profile/SID conflicts, helper/result failures,
cancellation and deliberate mutations during health/decision-lock wait.
Unchanged source hashes are compared; deliberately mutated fixture bytes are
excluded only when independently checking preservation of all other outputs.

Two existing structural selectors now distinguish the normal versus reuse
health and commit calls without relaxing their ordering or behavioral assertions:
`InstallerBuildAppHealth.Tests.ps1` SHA256
`51fb90b81a5d790b56535cd7d80808c221030ab69d3655fdf1697471aeaec1b9`;
`InstallerBuildProcess.Tests.ps1` SHA256
`dba6f3971c1fa1d0f7978ce89b70f8d2c53c627a57784423d51b00bb1beec87f`.
Root explicitly authorized the latter after its old single-call selector failed
against the additional valid reuse branch. Existing cancellation checks remain.

Commands, each final exit0:

```powershell
powershell.exe -NoProfile -NonInteractive -File tests/InstallerCompletedSourceReuse.Tests.ps1
powershell.exe -NoProfile -NonInteractive -File tests/InstallerBuildAppHealth.Tests.ps1
powershell.exe -NoProfile -NonInteractive -File tests/InstallerSetupReceiptSource.Tests.ps1
powershell.exe -NoProfile -NonInteractive -File tests/InstallerSetupReceipt.Tests.ps1
powershell.exe -NoProfile -NonInteractive -File tests/InstallerCompletion.Tests.ps1
powershell.exe -NoProfile -NonInteractive -File tests/InstallerBuildProcess.Tests.ps1
git diff --check
python .github/tests/test_inno_build.py
```

Final focused/regression logs under `D:/AutoClip-Inno-Migration/wiz39`:
`final-green-834921a79ee240a2b279c389711a0d0c.log`,
`final-regression-122758c621e24efe8d3caf3c2071f3da.log`, and
`final-pins-c59a76fd767f439a818b181e6c68b180.log`.
Root inspected test source and logs, then independently reran the focused
32-case test, exit0, in `root-focused-d5366645548b48f3abe3b1562f614d9b.log`.
Root also ran the current eleven builder checks, all pass.

The scoped-diff proof log
`scoped-diff-proof-454269f82f034316894d8e1e010bf68e.log` contains exact reverse
byte substitutions and diff. Root independently applied those five substitutions
in memory, each uniquely matched, and recovered the full pre-WIZ39 a09c hash.
All bytes outside the two authorized production regions remain unchanged;
no reconstructed source was written.

Preserved unsuccessful attempts include the old structural count failure, a
miscaptured final-focused log with no test evidence, and PowerShell5 JSON-array
enumeration assertion failures. The latter fixture enumeration was corrected
without changing expected source preservation. These are distinct from the two
meaningful behavioral REDs; their logs remain in place.

This is component helper verification, not actual installed health, full
supervisor completed reuse, Inno repair, final receipt renewal or release
qualification. Historical source producer identities remain exact; current
code cannot silently adopt an old source handoff. All earlier syntax-only Setup
binaries carry older bootstrap bytes and are not qualification of this source.
No production Setup, actual uninstaller, vendor or publication action ran.

## Follow-up: full supervisor composition verification

Root assigns `/root/completed_source_reuse` read-only production verification
against bootstrap5b2994 and the actual source supervisor. Owned outputs are new
external probes/logs under `D:/AutoClip-Inno-Migration/wiz39-full-worker/` only.
Use the smallest permitted exact completed fixture and pinned inert first-party
health helper; retain strict producer/ownership/descriptor/decision requirements,
actual worker and supervisor handles, terminal results and source byte proof.
No production, tests, docs, vendor, VM, uninstaller or release writes. A discovered
defect requires retained behavioral RED and root reconciliation before correction.
If allowed composition cannot be constructed without bypassing strict checks,
record that concrete limitation. Even a passing component composition does not
prove actual installed application health or full Inno repair.

## Actual full worker/supervisor component composition

Agent ran the unchanged bootstrap5b2994 and supervisore4cf86 with the actual
handoff producer against all1107 exact release-manifest rows. Existing archive
f2b3 was inspected for traversal/links/native installer/DLL contents, then copied
with unchanged bytes into a fresh protected stage. Its first-party AutoClip wheel
and required corresponding-source archives were retained unopened as static data.
Generated interpreter/native receipt and historical/fresh health helpers are inert
fixtures; the component dependency manifest binds those test helpers. This does
not qualify the production dependency manifestf968 or actual application health.

Executed command, exit0:

```powershell
powershell.exe -NoProfile -NonInteractive -File D:/AutoClip-Inno-Migration/wiz39-full-worker/full-worker-reuse-composition-v2.ps1
```

Final evidence stage:
`D:/AutoClip-Inno-Migration/wiz39-full-worker/composition-5fc2770172e946efbbcaf5cd41113956`.
Probe SHA256 `bf4b93a32e79bbafd254b531a0b215fa0337a4aaabc8bb305d600088ae9148a8`.
Success: original supervisor59300 and worker58828 naturally exited0; native worker
handle10928 retained and already terminal when caller returned. Verified completed
reuse stdout, fresh inert health descriptor and commit bind the exact context.
Primary `success-evidence.json`, SHA256
`d2efe75627c595a8dfb54f15f1cb5bc8d9962017de8a99c04942bb35b92e28a8`.

Cancellation: actual requester exited0, supervisor59308 terminal/status1223,
native worker58616 exited1 from the cancellation exception; supervisor maps the
accepted request to1223. Worker was already terminal when caller returned, cancel
record present and no commit. Primary `cancel-evidence.json`, SHA256
`c5d2bb1095c3fb4109c4a47630c42dca96754bba587a71e6816a349849e46948`.
Both raw primaries include original handles/times/terminal state, full unchanged
before/after inventory, actual input-write/target-lock denial while running, and
subsequent zero-byte lock release. No production files changed.

Root read the full external probe, exact run log and outcome summary. Independent
`python D:/AutoClip-Inno-Migration/check-wiz39-composition.py` exited0: both primary
hashes, terminal/handle/exit/commit/cancellation semantics, unchanged inventory and
all actual bound input bytes pass. This is root evidence reconciliation, not blind
review or actual installed application smoke proof.

Earlier retained probes accurately record inert-manifest rejection, the external
extractor's Windows permissions-only ZIP metadata refusal, foreign-write ACL
refusal of the original shared archive path, and an external status reader's
sharing race. The producer's exact refusal was not bypassed with a handwritten
handoff. A protected identical archive copy and corrected external status reader
resolved those fixture issues; no production assertion, pin or expected value
was weakened. Full Inno early reuse, native receipt renewal, qualified installation,
actual installed health, generated-uninstaller acceptance and release remain open.
