# IM-WIZ-41: incomplete setup must return failure

## Assignment

- Parent: qualify the conventional Inno installer, then test its exact generated
  uninstaller cleanup and data preservation before release.
- Authorization: implementation and native component verification.
- Governing contract: `contract-v1.md`, receipt failure must display incomplete
  setup and return a nonzero custom exit; terminal cleanup errors are failures.
- Agent: `/root/wizard_build_boundary`, external fixture preparation only.
  Configured specialist/model remains its existing assignment; actual routing
  is not exposed. Root owns production, documentation and VM execution.
- Parallel safe: preparation reads frozen sourceadadec while root completes
  WIZ40 controls. No concurrent production writer.

## Bounded task

Current `CurStepChanged` catches finalizer errors and sets `SetupReceiptError`,
but does not clear `SetupReceiptComplete`. The copied finalizer's cleanup-only
native WIZ40 control proves the flag can already be true when Hide raises.
`GetCustomSetupExitCode` currently consults only that flag. This is an inspected
caller/exit mismatch; native caller RED has not yet been executed.

Prepare the smallest inert native fixture copying exact `CurStepChanged` and
`GetCustomSetupExitCode`, with a fixed first-party finalizer stub setting the
flag before throwing. Preserve the actual caller/error/custom-exit behavior.
Prepare an unchanged-before-RED verifier requiring incomplete flag, error and
native/custom exit20, plus a normal control requiring exit0. Record exact maps,
source/artifact/spec/driver/verifier pins, native compiler codes and closure.

Owned files are fresh external `vm-transfer/wiz41-exit-preparation/` and bounded
serving artifacts. No repository code/docs, vendor acquisition or execution,
payload, registration, uninstaller, VM changes, publication or review approval.
The writer is a collaborator, not a blind reviewer. Root demonstrates actual
native RED before the minimum production correction and fresh native GREEN.

Source baseline SHA256:
`adadec44171690a0b9db52787cc3861c5edce92b10a06e200e32b0e698190f39`.
WIZ40 finalizer cleanup-only primary SHA256:
`83ce11552fa625e15e4954b54e875abb31cfb5028d52c21c38a903fba8721f16`.
This control is procedure evidence; its native fixture outer caller is not the
production `CurStepChanged`, so its exit0 does not prove the production exit bug.

## Required result and limits

Return actual artifact paths/pins, commands and observed failures or passes;
retain failed attempts and old bytes. Any correction needs a new immutable
review snapshot. No approval for old bytes carries forward. Full production
installer, installed application, exact uninstaller and release gates stay open.

## Actual native RED and minimum correction

Root executed the frozen failure fixture against adadec in the ordinary-user
Direct Windows11 VM. Actual `CurStepChanged(ssPostInstall)` displayed the native
fixed first-party error; actual `CurPageChanged(wpFinished)` showed the incomplete
heading. Root acknowledged the message and clicked Finish. The untouched parent
retained original PID4220/handle3396, start `2026-10-02T15:29:35.3969150Z`,
exit `2026-10-02T15:30:24.9296266Z`, actual native exit0. Finished observation
retained error but completion=true and custom exit0. This is caller/exit RED,
not actual application or receipt publication testing.

CreateNew-preserved primary:
`D:/AutoClip-Inno-Migration/vm-wiz41-failurered-primary-583e7c84e93c.json`,
1205 bytes, SHA256
`583e7c84e93c20662c9cdb99410905badfbd6333e28795c47fc10c88ca801d79`.
Spec `wiz41-failure-spec-d847f87d.json`, SHA256
`4923cd83a6204239d66f57f7624cbddf118392c937384cdabd26d4634cffdb9a`;
EXE2844977 bytes, SHA256
`d83f2673f4793e835e3323ecf470d5dd1a15793b5b3b7685c3ff6e96091935ef`.

Exact host verifier command:

```text
python D:/AutoClip-Inno-Migration/vm-transfer/wiz41-exit-preparation/verify-exit-observation.py D:/AutoClip-Inno-Migration/vm-wiz41-failurered-primary-583e7c84e93c.json --primary-sha256 583e7c84e93c20662c9cdb99410905badfbd6333e28795c47fc10c88ca801d79 --spec D:/AutoClip-Inno-Migration/vm-transfer/wiz41-failure-spec-d847f87d.json --spec-sha256 4923cd83a6204239d66f57f7624cbddf118392c937384cdabd26d4634cffdb9a --production-sha256 adadec44171690a0b9db52787cc3861c5edce92b10a06e200e32b0e698190f39
```

It exited1 at the stale completion flag assertion. Frozen verifier SHA256
`0b22d0128b8e816eed25ce6b597b8fe83873c568645588bcd12059fa8b0f10bd`
already expected native Inno7 finished page14 before compilation/handoff/native
RED, corrected during preparation from existing WIZ36 evidence. Root initially
misread the preliminary page8 draft as the frozen verifier and tried preparing
a new copy; the exact count guard refused before creating a file. No verifier
changed and no asserted failure requirement was weakened.

Initial direct `.ps1` invocation was refused by guest execution policy before
native launch. Root retained that screenshot, verified the exact protected driver
hash under a read lock, and used the existing first-party test scriptblock import
route. No execution-policy, certificate, signature or security setting changed.
Driver SHA256 is
`8d0846e5509f693b8ea02761571bf5f50d41a344f4e4f8068eb906a6f1531459`.
This route performed no vendor acquisition or execution.

After meaningful WIZ40 source-result RED and WIZ41 caller RED, root made two
minimum source changes: reset `RunSourceBuild.Result` before rethrowing a captured
error, and reset `SetupReceiptComplete` in the actual finalizer catch. Current
source SHA256 is
`61c2b52b9512ca5f829e582920e59db48b98ecbc836bce288eb9921a398f52f6`.
Original CRLF and unrelated bytes were preserved. Fresh source/body/control and
caller failure/normal native GREEN fixtures are being prepared; no success or
review approval is claimed before their actual execution.

## Actual corrected failure GREEN

Fresh exact source61c2 failure fixture now passes unchanged verifier0b22:
GUI7720/handle2796, start `2026-10-02T15:42:38.0132270Z`, exit
`2026-10-02T15:43:18.7838390Z`. Actual error message and incomplete heading
remain; completion=false, custom exit20 and natural native exit20.
Primary1208 bytes, SHA256
`5d9929198938c191dd0717a3486e77ae583477154a966c69fbe788dbfaf430b6`,
preserved at `D:/AutoClip-Inno-Migration/vm-wiz41-failuregreen-primary-5d9929198938.json`.
Spec `wiz41-greenfailure-spec-90a7ca31.json`, SHA256
`661a1e132ccad3a05de2edc124ec73e987497cde91a0372677f6994f1b8b1a90`;
EXE2844984 bytes, SHA256
`a11b7c9d064e6be8a39f25b015a92d184ba684ffba57966b87599664646436de`.
Root ran the same verifier command with these exact new primary/spec/source
pins; exit0. Normal native control remains pending at this entry.

The full source61c2 syntax compile exited0, output
`D:/AutoClip-Inno-Migration/im-wiz-35-syntax-cpc1838_/AutoClip-Setup-v1.exe`,
3394407 bytes, SHA256
`7be9551140473c6d5c9bccffcab9904caca36bd9c0517ddec14aa56ff2296eb1`.
Compile-input receipt SHA256
`43c4b96631fcca5a02b0ef945cfa1b348434c330918a0bd0875f7d8c19026845`.
This full binary is UNEXECUTED, not a production installation pass.
Root `python .github/tests/test_inno_build.py` passed11 checks after the changes.

## Actual normal control and fresh review

Normal native control passes unchanged verifier0b22 against source61c2:
GUI10040/handle3880, start `2026-10-02T15:44:25.6968747Z`, exit
`2026-10-02T15:45:38.7990015Z`, completion=true, no error, custom/native exit0.
Primary1174 bytes, SHA256
`ad5b07e1ef8e9dd36c4b8dad8841ee6b2e5eda38b942fd3daabb8c80befb033b`,
at `D:/AutoClip-Inno-Migration/vm-wiz41-successgreen-primary-ad5b07e1ef8e.json`.
Spec `wiz41-greensuccess-spec-9294c62d.json`, SHA256
`91370b21dd3ec091294a32d18750ce78f22334e9a08c82fd2d6a3f0abd15fb34`;
EXE2844927 bytes, SHA256
`2527cd4548db6bcf44df93141c462a5783ea632125cfbcef6a4954166c698484`.
Root invoked the same unchanged verifier with these exact pins; exit0.

Fresh immutable technical review packet:
`D:/AutoClip-Inno-Migration/wiz40-blind-review-5e1111d6f5f24332b2eb8acc159518b8.zip`,
47436208 bytes, SHA256
`5f1338d06e6a01a05edc5e9fd7a1c6ff4b4bc62bbb77406183128c9f5f52d660`,
279 pinned rows plus snapshot manifest. It includes current source, objective,
policies/contract, full unexecuted syntax-only installer/helper inputs, historical
exact snapshots, generator/base harness/driver/verifier/compiler closure, inert
fixture binaries and raw native primary evidence. Historical mutable input paths
map to frozen exact snapshots. Incidental producer narrative reports captured by
directory-wide read locks are omitted with transparent pins; no producer rationale
or requested verdict is supplied.

Reviewer `/root/native_error_review_r2`, `contract_reviewer`, starts without
inherited turns or session memory and did not produce/debug the changes. Configured
GPT-6.1 Sol/high; actual routing not exposed. Owned output is one new external
verdict; fresh scratch file/hash/map/host verifier checks only. No clean VM is
assigned and no native/Setup/vendor/uninstaller execution is permitted. Candidate
source/binaries remain frozen during review. Root may continue independent
read-only ownership inventory and first-party worker composition verification.
This review cannot qualify full installer, repair/health, legal rights, lifecycle,
actual generated uninstaller or publication. Disposition remains pending.

## Returned scoped verdict

Fresh reviewer returned
`D:/AutoClip-Inno-Migration/wiz40-review-verdict-15c9f4d17f61453396724e4951e3a05f.md`,
SHA256 `0da3b641051982feeb818fdeb1f0674e909c777b770b2b3ebc5780632e67e707`
(root recomputed the hash and read the complete verdict).
Disposition is PASS only for the frozen process/error/completion component scope.
The reviewer independently checked 279 manifest rows, retained source mappings,
baseline reversal, current compile bindings and six primary-record verifiers.
No native binaries or full installation were executed by the reviewer.

Two historical control fixture closures are absent from the packet; current
retained finalizer/source controls independently cover the scoped behavior.
The omitted historical closure is not qualified. This is a blinded same-session
sub-agent technical review, not external, human, legal or release approval.
Full production installer and exact generated uninstaller remain unverified.
