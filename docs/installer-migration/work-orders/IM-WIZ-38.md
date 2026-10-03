# IM-WIZ-38 — Source-build display-error child observation

## Requirement and ownership

Contract-v1 requires setup to observe its exact started supervisor until terminal
state even if display fails. Root owns production correction and all native VM
actions. The collaborator prepared only new external fixtures/driver/compile
records in `D:/AutoClip-Inno-Migration/vm-transfer/wiz38-source-process`.
No collaborator ran VM, vendor, product or uninstaller operations. Current task
order remains production-ready installer, exact generated-uninstaller
cleanup/data preservation, then release.

## Frozen baseline and fixture scope

The complete RunSourceBuild function in current full source8fed equals frozen
source0dfd literally, verified under input locks. Baseline snapshot SHA256:
`0dfd2be44c052bf1e4b249437daa04d5a89e4d0c797105fd6d08144d794e322c`.
Current compile-time full source SHA256:
`8feddb2c308949dd64d06de15a30b9e2f9dc6f105727d5380f1fea470d7ab7cc`.
Actual function tail853–888, Started/Result/BuildCancelPending state, exception
handlers and original process waits are copied. UI/control calls are replaced
with inert storage/calls; cancellation poll is a no-op and is not qualified by
these tests. The observer immediately reads the preserved original COM child
Status/PID and terminal-only ExitCode, without waiting/killing/restarting.
The actual native64 first-party child writes PID-bound ready/terminal records,
waits two seconds and exits0. No product payload, vendor, ARP or uninstaller exists.

External preparation packet
`wiz38-source-fixture-packet-0a843602a36e4657b5326ceb2d4db43a.json` SHA256
`b46298e3c49b48eab80a95cc11d74120c1564debdb10c4175c11bc980635bf7a`;
generator SHA256
`4746e52b39b21f46787776a14c6db079cc177b70566ae896be209b79f7c48da9`.
Exact compile receipt `wiz38-source-compile.json` SHA256
`d44d308d2d48e700f3549a7a5482a825c34b359378ba61c1e92f292b6d9cd83d`.
All three actual approved ISCC exits0, with inputs/compiler closure locked
through compilation. The initial compiler-wrapper warning incident and first
binary were preserved separately; no integer compiler success was inferred
for that first interrupted wrapper invocation. Full commands/pins/limits are
in the frozen external `COMPILE_HANDOFF.md`, SHA256
`97af2590e86c783517297f8f3a200816ec28855966ffcbc777868e7e744a98c5`.

## Root native baseline RED

Environment: `AutoClip-Inno-Win11-Direct-20261002`, UUID
`e6661e4b-cdcd-4e1c-baa3-cb34ad5cd3c0`, ordinary native64 autocliplab,
Windows build26200, no GPU passthrough. Native parent driver is pinned SHA256
`e33fc5b0a34416421168ef2bd566d0611cf90c01ccb7f9132eb5c4a0138215f9`.
Its four changes from driver37 are exact spec/URL restrictions and operation
name. The driver retains the original GUI handle/start before waiting, and
reads the already-written immediate observation after root presses Finish.

The first loader incorrectly treated binary HTTP Content as text and refused
its pin before staging/child launch. Native output subsequently confirmed
`System.Byte[]`; host independently confirmed the response is
application/octet-stream, 4396 bytes, with the expected unchanged driver hash.
The corrected loader hashes RawContentStream bytes before decoding the verified
script. This is a transport correction with the same expected hash, not TDD RED
or a verification bypass. The frozen driver/fixtures were not changed.

Body-once spec `wiz38-bodyonce-spec-299641f4.json` SHA256
`597c6cbf3a461cadcd03ac3fb1b8cecf3933f381b502b8ebb69f41dcb119a77f`.
Compiled EXE2845851 bytes/SHA256
`e99fd4ca98ede05d0a57a4c5dc216587222d389f255abbb8bd0f21c468a85339`.
Actual immediate child7720: Status0/NOT_TERMINAL, original
FIRST_PARTY_BODY_ANIMATE_FAILURE, two Animate calls, source_build_result=false.
Later matching terminal records do not repair the early-return assertion.
Original GUI4084/handle1148, start2026-10-02T14:17:13.7171757Z,
exit2026-10-02T14:17:51.7825632Z/native0; GUI0 is not the behavioral assertion.

Primary `D:/AutoClip-Inno-Migration/vm-wiz38-bodyonce-red-primary-318421da9a62.json`
SHA256 `318421da9a623ab318d40aea6b0e20fb2b0bcfc25951c98302e789e352500ebc`.
Root retained it by CreateNew, then ran:

```powershell
python D:/AutoClip-Inno-Migration/vm-transfer/wiz38-source-process/verify-source-observation.py D:/AutoClip-Inno-Migration/vm-wiz38-bodyonce-red-primary-318421da9a62.json
```

Expected RED, exit1: original supervisor still running when source-build
observation returned. Verifier SHA256
`77aab6bdbc9f702015461c37e7e0345a4793e17fbd206571f612fee61a499e2e`.
It additionally binds native64/PIDs, exact source/child/failure mode and result.
Repeated-cleanup failure and correction/GREEN remain pending.

## Repeated cleanup display failure: distinct RED

Root then ran the frozen body-and-cleanup fixture with spec SHA256
`6f31a699d8abe94d5ca9be2244a93cfff58c752d538f0e8834275f0ff6a55a3a`;
EXE2845860 bytes/SHA256
`bfa0dbada7c4b0e4d7bdac60beac59a92c34b5af5ec3c782472c89698af15236`.
Actual child4244 was immediately Status1/exit0, but the original body error had
been lost: caught_error empty, 27 Animate calls, source_build_result=false.
The same unchanged verifier exited1 on original-error retention. This case is
not described as a live-child failure. Later cleanup exceptions cleared the
pending body exception; that differs from body-once's early return.

Primary `D:/AutoClip-Inno-Migration/vm-wiz38-bodyrepeat-red-primary-64e7f5c8f286.json`
SHA256 `64e7f5c8f286ed16caa311e465f4164341933ca255f1975cba2a41050f190056`.
Original GUI5116/handle1668, start2026-10-02T14:19:31.5829668Z,
exit2026-10-02T14:20:23.5184506Z/native0. Matching ready/terminal PID/native64
records, exact source/spec/child bindings, and inert fixture scope are retained.

After these two meaningful native failures, root applied the minimum production
correction to RunSourceBuild: ProcessError local initialized before work, inner
except captures the original body message before existing responsive cleanup,
and rethrow after cleanup. Original supervisor/requester wait loops and
cancellation logic remain. Finalizer implementation is unchanged from WIZ37.
New production SHA256:
`f1d2bb68aa65c5bf559a1534ec036db9cf4e1b98bbf24a5336add3b676b0e090`.
Fresh exact-source fixture regeneration/compilation and native GREEN are pending;
the code change is not claimed qualified by the preceding failures.

Root syntax command `python D:/AutoClip-Inno-Migration/compile-current-inno-r2.py`
passed actual ISCC exit0 against f1d2. Output
`D:/AutoClip-Inno-Migration/im-wiz-35-syntax-m12foxa1/AutoClip-Setup-v1.exe`,
3394061 bytes/SHA256
`8af7036fa5ebc87091471c1e1cf54fb71f1a65ddc81694f3daef602ea6540d3d`.
This is `SYNTAX_COMPILE_ONLY_UNEXECUTED`, not an installed or release-qualified
candidate. `git diff --check` passed with existing LF/CRLF warnings. Current
contract SHA256 remains
`78ced490df6c6fcad6de2e060605cb0a53ef887c91e450331308f0df47123277`;
canonical prerequisite manifest/classifications remain unchanged.

## Fresh source-build failure cases GREEN

The collaborator regenerated exactly the same three injections from current
f1d2, preserving the observer and all verifier expectations. Fresh header/tail
line maps match current production after the declared UI substitutions and
original-child reference insertion. An independent in-memory replacement of
only RunSourceBuild with its old function recovers the entire prior8fed hash,
proving all bytes outside this function, including finalizer, remain unchanged.
No reconstructed production source was written.

Commands, run by the collaborator with approved compiler/input read locks:

```powershell
python D:/AutoClip-Inno-Migration/vm-transfer/wiz38-source-process/prepare-source-fixtures-r2.py
& D:/AutoClip-Inno-Migration/vm-transfer/wiz38-source-process/compile-source-fixtures-r2.ps1
```

Both exit0; all three actual ISCC exits0. Old generator/fixtures/packet/driver
remain unchanged. New generator SHA256
`28e7ecd9ea551fe3cdb4ea3febc26b3458ca55e72966ee182cea616f528a6a15`;
new packet `wiz38-source-r2-fixture-packet-c1008504888a4e75ac2b8d4e2dd4e313.json`
SHA256 `9b8c93e09dbc67897ce35079e355e4430660b81f1aa4e04738d585c573914567`;
new compile receipt SHA256
`ac46070506a6d7d7d62b721cfe66a063bb7f7adc4c98e8dc8c6584054a520c32`.
Frozen external `R2_COMPILE_HANDOFF.md` SHA256
`e6eb1bf4f8328de26bc2f432b22b692475b0629d2078845a3176e76be971fd6d`
records all exact source/spec/compiler/binary pins and preparation limits.

Root executed the fresh once/repeated-failure fixtures through the same native
driver38 and used the unchanged verifier77aab6 command above against each
CreateNew-preserved primary. Both returned verification exit0/GREEN:

| Case | Spec SHA256 | Compiled EXE SHA256 / bytes | Immediate child | Original error / result | Primary SHA256 |
| --- | --- | --- | --- | --- | --- |
| Body once | `9608aeaad22f92d6246a47cb39d2ca78192486a79af2a29a909f2ed1380715f9` | `fc6c8a8442eeb23ee96e7f25a1a835d62bc60be16e3ebed6551801b7d83de4af` / 2845876 | PID10140, Status1, exit0 | FIRST_PARTY_BODY_ANIMATE_FAILURE / false, 27 Animate calls | `cad46951cb263fd3c3444e3755c073bf61757012abf0b424e8dd798f947b2dfb` |
| Body and cleanup | `d318577dc43e25c61086632c60fcf88c2d4e78eafbba8b0e5153d5a82e1e822f` | `5dd79e4f404052f405be7a45353b1bac0311c16d2e940fb34527d786d173f1f8` / 2845915 | PID9460, Status1, exit0 | FIRST_PARTY_BODY_ANIMATE_FAILURE / false, 27 Animate calls | `efec3360d3e73f8417db255c98fee123c3197f5b790787647db6eac4739095cc` |

Primary names under `D:/AutoClip-Inno-Migration`:
`vm-wiz38-greenonce-primary-cad46951cb26.json` and
`vm-wiz38-greenrepeat-primary-efec3360d3e7.json`.

| Case | GUI PID / original handle | Start UTC | Exit UTC / native code |
| --- | --- | --- | --- |
| Body once | 11152 / 3496 | 2026-10-02T14:26:57.1901428Z | 2026-10-02T14:28:02.2738197Z / 0 |
| Body and cleanup | 11824 / 1608 | 2026-10-02T14:29:02.4443133Z | 2026-10-02T14:30:31.2271308Z / 0 |

Original native64 ready/terminal PID bindings and exact source/child hashes
passed. No observer wait, restart or kill masked early return. Repeated cleanup
errors no longer erase the original body message. Control execution is pending;
these are inert process-boundary tests, not actual cancellation, product Setup,
health, vendor or generated-uninstaller qualification.

Independent current host checks: 16 manifest tests and 11 builder tests pass.
No production Setup, shared prerequisite installation, actual uninstaller,
commit/push or release operation was performed. First-party fixture execution
does not qualify the final production installer.

## Normal completion GREEN and scoped disposition

Root completed the current native control fixture after visually confirming
Ready to Install, then the actual Finish page. The original GUI process8372,
handle2652, started2026-10-02T14:31:57.0357788Z and exited
2026-10-02T14:39:37.2161857Z with native code0. The time includes waiting for
the operator's Install/Finish actions; it is not source-build duration.

Spec `wiz38-greencontrol-spec-6eca4627.json` SHA256
`69835a6de0a1c0494990065a1f0be437ed6765310a05e86c79a05c01f15c5b1c`
binds the current production sourcef1d2, compiled fixture2845806 bytes/SHA256
`8ce8ed1343c1d2148ff29a40278658b961e5c1807d6f0695ccda10451282b277`
and the unchanged first-party childa9eb9d72. Actual child2440 was immediately
Status1/exit0 when RunSourceBuild returned, caught_error empty,
source_build_result=true, 26 Animate calls. Ready/terminal native64/PID
bindings passed without a host observer wait.

Root validated the spec/original GUI PID/failure-mode binding, preserved the
complete primary with CreateNew, and ran the unchanged verifier:

```powershell
python D:/AutoClip-Inno-Migration/vm-transfer/wiz38-source-process/verify-source-observation.py D:/AutoClip-Inno-Migration/vm-wiz38-greencontrol-primary-a6c7c4be6a52.json
```

Exit0/GREEN. Primary SHA256
`a6c7c4be6a52dc04ccf68e3738655afe2c8bc2b276583845d59c754f4502d2c3`.
All three corrected cases now pass the same verifier used for the two distinct
baseline failures. The source-build display-exception finding is closed at
this native process-boundary scope. This is root-executed component verification,
not blind independent review or production installer approval. Actual cancellation,
fresh prerequisite acquisition/install, full Setup, health, generated-uninstaller
cleanup/data preservation and release qualification remain open. The user's
order remains production installer ready, then its generated uninstaller tests,
then release. NVIDIA execution tests remain explicitly deferred.
