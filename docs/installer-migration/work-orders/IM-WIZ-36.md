# IM-WIZ-36 - exact source size and native finish-page fixture preparation

Status: bounded byte verification and external fixture preparation complete.
This opening section records the preparation agent's scope; root's later
actual native RED/GREEN results appear in the final section below.
Owned only this report and
`D:/AutoClip-Inno-Migration/vm-transfer/inno-final-ui-test.py`. No production,
compiler, VM, vendor, native Setup or uninstaller execution occurred. Parent
owns all native RED/fix/GREEN operations. User's production-installer-first,
then generated-uninstaller-before-release ordering remains binding.

## Confirmed pre-WIZ-34 bytes

Current install.ps1: **411748bytes**, SHA256
`a09ccee22724855ab6b31321397b5deec9e02946795ebf781893b910d21a2734`.
Immediate pre-WIZ34: **407214bytes**, SHA256
`2e2372a0c29cfa933eebccb0cb4495a179c3ad249ed747f8f5db048b32edbe2d`.
Net change4534bytes. IM-WIZ-16's frozen report independently records407214bytes;
WIZ31 observed the same prior source SHA before implementation.

Executed an ordinary Python standard-library read-only check: read current raw
bytes and reversed only the eight recorded WIZ34 regions **in memory**, preserving
CRLF: two parameters; verified import/context; managed-empty-root predicate;
early partial-proof call; fresh staging/ACL functions; protected root creation
branch; proven handoff scan allowance; completion producer call. Every reversal
matched exactly once. The reconstructed raw file had407214bytes and matched the
entire prior SHA exactly. No reconstructed file was written. Therefore all
other prior bytes, including embedded terms/native recipe/helper data, are
unchanged; this conclusion does not depend on a broad Git HEAD diff.

EmbeddedPrerequisiteTerms block specifically:318039bytes, SHA256
`547a57d219ccc13eeb4a5f951a1bbedad20d5d79ee77f6c9fdd7fde4ceb6ccae`,
byte-identical in current and reconstructed prior file. The earlier summary's
1407214byte value was incorrect. There is no evidence it described actual script
bytes or serialized transport; do not reinterpret it as measured evidence.

## Concrete finish-page timing finding

Inspected production AutoClip.iss SHA256
`40c65622d4f86ff21d8886351551eb9d2bcb9204f797027961b7c4edd5fbccc6`.
CurStepChanged1022-1037 writes failure heading/body during ssPostInstall;
GetCustomSetupExitCode1038-1041 returns20 on incomplete receipt. No production
CurPageChanged existed in this snapshot.

Official Inno7.1.0 [Setup.MainForm.pas](https://github.com/jrsoftware/issrc/blob/is-7_1_0/Projects/Src/Setup.MainForm.pas)
calls ssPostInstall at238, then ChangeFinishedLabel at253 or263. Consequently
that event's custom body can be replaced by native completion text. The
[event documentation](https://jrsoftware.org/ishelp/topic_scriptevents.htm)
defines CurPageChanged after the new page is shown. The minimal proposed
production correction is to apply failure labels on wpFinished using the
existing failure state; root must demonstrate the actual native failure before
making that correction and prove its actual native result afterward.

## External generator and exact boundaries

Generator SHA256
`cbbd375dc49548fa12dc9e56ef99c31e6f162a00ffdd44e5fbfa51458ec1ad2b`.
Exact invocation, executed only to generate source/JSON:

```powershell
python D:\AutoClip-Inno-Migration\vm-transfer\inno-final-ui-test.py --source installer/AutoClip.iss --expected-source-sha256 40c65622d4f86ff21d8886351551eb9d2bcb9204f797027961b7c4edd5fbccc6 --output-dir D:\AutoClip-Inno-Migration\vm-transfer\wiz36-ui-fixtures
```

The generator refuses a changed production pin; copies actual CurStepChanged,
GetCustomSetupExitCode, and optional actual CurPageChanged without altering
their bytes; records original/generated line spans and extracted procedure
hashes. Controlled FinalizeSetupReceipt is the sole injected product boundary:
failure raises `FIRST_PARTY_FINAL_RECEIPT_FAILURE`; success sets the existing
complete flag. Observer NextButtonClick records actual labels on the real Finish
click, after native ChangeFinishedLabel and production page events. It never
simulates those timing calls or substitutes expected labels.

Each fixture has unique nonproduct AppId/root, ordinary x64 interactive wizard,
Uninstallable=no/CreateUninstallRegKey=no/CreateAppDir=no, no Files/Dirs/Run,
no acquisition, vendor, app source or uninstaller. Parent must precreate the
packet's exact fresh `LocalAppData/Temp/wiz36-inno-ui-<token>` directory with
recipient/SYSTEM/Admin protected ACL. InitializeSetup refuses an absent root or
existing observation. The observer writes `observed-finished.txt` only there;
the generator does not create that VM directory or silently claim its ACL.

This agent's frozen prepared baseline packet (uncompiled/unexecuted):
`D:/AutoClip-Inno-Migration/vm-transfer/wiz36-ui-fixtures/wiz36-ui-fixture-packet-41bb8b89ad324c2bbc2190f1427b717a.json`,
SHA256 `d0680671cec6da4f970a191d0d3d32eec004ca48e7e78c1d921313bef4a3af40`.

- Failure `wiz36-final-ui-failure-2f189e5f709f46b1b686789fc2f642df.iss`: SHA `e01138063c5e154c22920d73ba7e7ea15da0b2d214d9939053b1787c272d7f69`.
- Success `wiz36-final-ui-success-f5148496f1e44c9ab887e97504eb5317.iss`: SHA `32fbccb761e017a20801cf5c9ff663698a14fce17de595f4381eafe3683adabe`.
- CurStepChanged exact extracted SHA `4969ad11e9d7ef0879f7343e3ab93c9caa691d1485a932f6ea5660e396d1c8fc`, source1022-1037 -> both fixture41-56.
- GetCustomSetupExitCode SHA `c61a49b2dc896740e2d33a057277c96a00a76082db58f4044e72bb9224c65574`, source1038-1041 -> both fixture58-61.
- Approved compiler observed read-only: `D:/AutoClip-Inno-Migration/InnoSetup7/ISCC.exe`, SHA `d06ebd38f38e3cee60a3c50cc45bd449d77e0bc6a5cabc607ea9886808e4de1a`.

Python in-memory syntax compilation passed. A separate standard-library check
compared every recorded generated procedure span's raw bytes against the source
span and passed for both fixtures. Earlier draft fixture packets were preserved;
the41bb packet above is this agent's frozen prepared baseline. No ISCC command or
fixture executable was run by this agent. git diff --check passed.

## Parent native RED/GREEN procedure and limits

Parent compiles the pinned baseline fixtures with approved ISCC, captures actual
compiler/exe hashes, and launches them **interactively** in its clean linked VM.
For failure, dismiss the actual error message, photograph/read the Finished page
before clicking Finish, then retain the fixture observer text and original
process exit. RED requires actual failure state/exit20 but body replaced by
normal native success text. Success control must keep normal completion body and
exit0. Quiet/live processes are preserved, never killed/restarted on timeout.

Only after meaningful native RED, root edits its production wpFinished event.
Regenerate from that new exact production hash, compile and rerun the same two
scenarios. GREEN requires actual incomplete body containing the controlled
failure plus preservation/incomplete-receipt wording, actual exit20, and normal
success body/exit0 in control. Screenshot and observer must agree. Do not use
/AUDIT, add fixture flags to production, execute uninstall, or describe an
extracted-event fixture as qualification of the full installer/receipt/build.
Native RED/GREEN are **pending parent execution**, not results of this report.

Parent subsequently reported a separate generated packet
`a19b57a037784a11afc6a222e48cb9c8`, SHA
`6769db3f2e132d0d636ec52bdaa416c373cb30be8812a9436f56312e5c25ee46`,
same production40c656 source, with both real ISCC commands exit0. Its failure
token74df5b43cd3c41919fba1e0782790741 and success
token7aca5a1d238943ce8ab29f15d8402992 are the parent's chosen upcoming VM input.
This is a parent-reported compiler result, not this agent's executed verification.
Our41bb fixture packet remains separately uncompiled/unexecuted; production UI
source had not yet been changed at that update.
# Root actual native RED/GREEN, 2026-10-02

Root generated its separate baseline packet `wiz36-red/a19b57a037784a11afc6a222e48cb9c8`,
SHA256 `6769db3f2e132d0d636ec52bdaa416c373cb30be8812a9436f56312e5c25ee46`,
and compiled both inert fixtures with approved ISCC7.1, exit0. Production event
source was `40c65622d4f86ff21d8886351551eb9d2bcb9204f797027961b7c4edd5fbccc6`.
The frozen generator remained `cbbd375dc49548fa12dc9e56ef99c31e6f162a00ffdd44e5fbfa51458ec1ad2b`.

Root ran the failure fixture interactively as ordinary native64 autocliplab in
VM `AutoClip-Inno-Win11-Direct-20261002`, UUID
`e6661e4b-cdcd-4e1c-baa3-cb34ad5cd3c0`, Windows11 Enterprise Evaluation26200,
8GB/6CPU. Each fixture had a fresh protected recipient-only directory. Pinned
first-party driver `wiz36-ui-driver.ps1`3608B/SHA256
`26970aecdf03df17ee978e6761a033a2d154da78734c591cbec9679c7af3061b`
held the fixture EXE readlocked, captured its original handle/start before waiting,
and retained actual terminal and Finish-click observation. All fixtures disable
uninstaller and registration, contain no application payload, and run no vendor.

## Observed RED

Failure fixture EXE3182724B/SHA256
`6ee746eecfea30457347bce7f288f136c6c3a9b91fe767599d4e4f7aeed19988`.
Original PID5428/handle3308 exited20. Heading was incomplete but actual body said
installation had finished, with no failure detail. Screenshot:
`D:/AutoClip-Inno-Migration/wiz36-red-finish-page.png`, SHA256
`9691e457258559697c1636cfa1b3596e3e06061727d13c0c03fd809d4bc51f91`.
Primary `vm-wiz36-red-primary-b530f40b3993.json`, SHA256
`b530f40b39933bdd45c3ea8fbc00264926b4a114d6cb411c71cd1051edf71916`.

Runnable check:

```powershell
python D:/AutoClip-Inno-Migration/vm-transfer/verify-wiz36-observation.py D:/AutoClip-Inno-Migration/vm-wiz36-red-primary-b530f40b3993.json
```

RED exit1 `Failure detail lost on actual Finish page`. This observes real Inno
event ordering and labels, with only finalization success/failure injected.

## Fix and observed GREEN

Root moved failure label assignment from ssPostInstall to CurPageChanged(wpFinished),
retaining the immediate error dialog and exit20. Production source SHA256 now
`0c41fc3cf1f9c955b29134f4b0a88c531b03a5b66e35925f15515fa466f1507a`.
Fresh green packet `wiz36-green/92238335a6db452fab8bf829858f6fc7`, SHA256
`1038c78dcb5d01051d88026cad220d751d5a787f78c3781d514f3e0f693dff92`.
Both freshly compiled fixtures use the new exact production handlers.

| Actual native scenario | Fixture EXE SHA256 | Original PID/handle | Exit | Result |
| --- | --- | --- | --- | --- |
| Failure | `354236470888e266c08593a53e00db850577405f4c2ef9ba9734fc8405a05ffc` | 8528/3888 | 20 | Failure detail and preservation text remain visible |
| Success | `2b19346b74405d86a812de1984fd9918f53451a0a22d82e32b2d6fd775c54719` | 4648/3956 | 0 | Normal completion heading and body retained |

Both passed the unchanged observation check, exit0. Failure primary SHA256
`c6335c571295dba85aff4f80f3fdb018dd39cebf55734b8544657f221a929aa8`
at `D:/AutoClip-Inno-Migration/vm-wiz36-greenfailure-primary-c6335c571295.json`;
success primary SHA256
`559e0dba85e10f18b44165ff35336bdf3f27f26dcb1f5640d04961663164afde`
at `D:/AutoClip-Inno-Migration/vm-wiz36-greensuccess-primary-559e0dba85e1.json`.
Check source SHA256
`c85e1b6b5d721e3c52015b63e7ec41d1adf596d9de144f6e9fea52fa61c2b957`.
Finish screenshots failure/success SHA256 respectively
`2864fedff219adfd8e59b4ae90d17c87e996e938bed4f71fb6d7aaa6cadf7512` /
`41b822e0c0c6d5eb775e9b3e1e46fbb4fb0c5324eff1c50d50f10ff589c58dd5`.

Full current source also compiles, exit0, via compile-current-inno-r2.py, with
all inputs readlocked. Unexecuted syntax output3394011B/SHA256
`5e6efb31ea4282df33a0ccce3c35ab5832f30e659d29c201d19780ff59f4d2a9`
at `D:/AutoClip-Inno-Migration/im-wiz-35-syntax-qtkerxjr/AutoClip-Setup-v1.exe`;
compile-inputs SHA256
`6f0cc9f43f0de6424d6dc712813b9f7043c00fb4684eb272bab144ce4d4b464a`.
That binary remains SYNTAX_COMPILE_ONLY_UNEXECUTED.

## Clock and baseline limits

The restored baseline initially reported guest UTC2026-09-27T08:02:49.9815874Z;
RED native timestamps retain that clock. Later GREEN runs reported current UTC
2026-10-02T13:18:01 and13:19:33. Root did not set or backdate either clock; cause
of this change was not investigated. No signature/current-time qualification is
inferred from the UI test. Baseline proves no AutoClip parent/ARP, BuildTools
root or installed VS engine. It also observed setup.exe PID6588 with unreadable
path; it does not prove no system installer activity. Full baseline735B/SHA256
`d453aca6d99482e311508bf35ad5d6a830203a38ddeb62f1e3d59a76d4862d28`
is retained at `D:/AutoClip-Inno-Migration/vm-direct-clean-baseline-d453aca6d994.json`.

Native UI fixture verification is complete for this narrow hook. It does not
qualify full source build/final receipt publication, prerequisites, desktop/media,
repair/reinstall, production readiness or release. SDK consent remains pending.
No uninstaller has run; user sequencing remains production-ready installer
first, exact generated-uninstaller cleanup/preservation afterward, then release.
