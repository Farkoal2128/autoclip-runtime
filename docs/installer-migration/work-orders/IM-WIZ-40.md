# IM-WIZ-40: cleanup display error preservation

## Assignment and governing requirement

The installer contract requires observation of the original source/finalizer
child until terminal state and retention of the original display error. A
fresh-context reviewer is inspecting the immutable component packet
`D:/AutoClip-Inno-Migration/wiz38-blind-review-0e903e87bfd04acb95bd92324ea7ebb5.zip`,
21702463 bytes, SHA256
`bda95f0cf84f2d875b17f9b19d7f6cd1bb2b2de93f5b11927496d497ecedfa92`.
It contains 82 pinned input rows plus snapshot manifest, exact sourcef1d2,
first-party fixture binaries and raw native primaries. No live source edits
change that packet. Review scope is native process/error boundaries; full
installer, lifecycle, rights and publication gates remain separate.

Reviewer `/root/native_process_blind_review` starts with no inherited turns,
does not use session memory and did not produce or debug the candidate.
Configured role `contract_reviewer`, GPT-6.1 Sol/high; actual routing not exposed.
Its only owned output is a new external verdict. No clean VM is assigned;
independent file/source/manifest/verifier checks are permitted. A review finding
ends this snapshot's review; correction requires a new snapshot and review.

## Reported finding; native reproduction pending

Reviewer reports unguarded cleanup display operations before ProcessError is
rethrown: source controls/Hide and finalizer Hide can replace the captured body
error. Previous fixtures used nonthrowing stubs for these cleanup operations.
Their actual passing cases retain their narrow original scope; they do not
prove this new failure branch. No production correction precedes native RED.

`/root/wizard_build_boundary` owns only fresh external fixture generation and
approved exact ISCC compilation. Root owns actual VM execution, unchanged
verifier RED/GREEN and subsequent production correction. The writer must
preserve old artifacts, copy exact source header/tail with declared stubs,
retain immediate original-child observation and pinned child, disable
uninstallation/registration/vendor execution and capture actual compiler exit
codes with readlocked inputs. It is an implementation collaborator, not reviewer.

Baseline injections: original SetText error followed by cleanup Hide error in
the finalizer; original Animate error followed by cleanup Hide error in source
build. Verify the original error and original child's immediate terminal state.
No wait in the observer may conceal an early return. Preserve exact source,
fixture, spec, child, driver, compiler and primary hashes before fixing.

No vendor acquisition/installation/acceptance, actual uninstaller, commit/push
or release is authorized by this component task. Production installer readiness
still precedes its exact generated uninstaller tests before release.

## Frozen review verdict and root reconciliation

Reviewer ended the immutable snapshot review with REQUEST CHANGES, F1:
`D:/AutoClip-Inno-Migration/wiz38-review-verdict-00f1bed36d9945f9818b2ec27bc38c64.md`
SHA256 `a0edea97979c7d92c7d7a24712d2ef2ad74869254f66579682451aae22f4634d`.
Root read the full separate verdict. All 82 manifest rows and archive match;
the reviewer independently compared fixture maps and unchanged finalizer tail,
checked exact artifact/spec/primary/PID bindings and executed host verifiers:
six historical/current GREEN records pass, two source baseline records fail for
their distinct recorded reasons. Reviewer executed no native binaries or VM.

F1 concerns error fidelity after the child wait, not evidence of an early-return
defect in those passing branches. Root accepts the concrete uncovered cleanup
Hide/control branch and proceeds with native reproduction before implementation.
The combined process/error contract gate remains open. Historical narrow RED/GREEN
evidence is retained; no approval carries to a changed source or executable.
Reviewer limits include omitted full compiler/helper closure, missing generator
base harness in the review packet, no independent regeneration/native runs, and
no full Setup/worker/cancellation/vendor/health/uninstaller/lifecycle evidence.
The next packet must include its fixture generation closure for meaningful
independent checking. This is a blinded same-session sub-agent review, not
external human or legal approval.

## Actual native RED and first correction

Root executed both exact baseline body+Hide fixtures in the ordinary-user Direct
Windows11 VM. Both unchanged pre-RED verifier checks exited1 because cleanup
Hide replaced the original body error. Original children were already terminal,
status1/exit0; this RED concerns error fidelity, not an early return.

| Baseline | Original GUI PID / handle | Original child PID | CreateNew-preserved primary SHA256 |
| --- | --- | --- | --- |
| Finalizer body+Hide | 3656 / 2652 | 2248 | `5d233243c02b7fc0f327a9ea920d102a69be56405a490e980a37b0afccae6ff5` |
| Source body+Hide | 3512 / 1836 | 8724 | `6cc6263fe53b9048b1c314dd4aee379db91af85370f28ec484cc22bd59b64f53` |

Root then guarded terminal source controls/Hide and finalizer Hide, retaining
`ProcessError` when already captured and recording cleanup-only errors. Source
SHA256 became `adadec44171690a0b9db52787cc3861c5edce92b10a06e200e32b0e698190f39`.
The external r2 generators' exact two-guard reversal recovers the entire baseline
SHA256, not only selected snippets. Complete generation closure35 named inputs
is in `vm-transfer/wiz40-hide-preparation/generation-closure-r2.json`, SHA256
`4128295565be65aa830976a3de20e1a056ca2f2ae9df380baf2deae5fdd88f8a`.
Both host verifiers and native driver bytes remained unchanged.

## Actual native r2 results and remaining source-result failure

Root inspected Ready/Finish screens, retained each original process handle and
times, and CreateNew-preserved each raw primary. All original children were
immediately status1/exit0, with no observer wait, kill or restart.

| r2 case | GUI PID / handle | Child PID | Primary SHA256 | Unchanged verifier |
| --- | --- | --- | --- | --- |
| Finalizer body+Hide | 10800 / 3272 | 8312 | `129981d4122c0c98d6d02d113465ed09e25f1844e25e901c8bbee20c0406cd02` | PASS original SetText error, complete=false |
| Source body+Hide | 12444 / 3276 | 2468 | `f82dedba3cad8804ad3002d9aaeac72ee9c8076cd44dc1a3aa0247c4b5980943` | PASS original Animate error, result=false |
| Finalizer cleanup only | 2368 / 1916 | 8472 | `83ce11552fa625e15e4954b54e875abb31cfb5028d52c21c38a903fba8721f16` | PASS cleanup error, copied body flag=true |
| Source cleanup only | 5384 / 3788 | 1368 | `5cfec909810754f15a121c84f29bfaf0e6bea118286a633cfe534065dca426f0` | RED exit1, result=true instead of false |

The fourth result is a real uncovered failure: the function assigns true before
cleanup raises, and the inert native caller retains that result despite the
exception. The frozen control verifier explicitly required false before native
RED and has not been weakened. A minimum source-result correction and fresh
native GREEN are still required. WIZ41 separately tests production caller/custom
exit behavior; the control's procedure flag and fixture exit are not proof of
the production setup exit.

Raw primaries are under `D:/AutoClip-Inno-Migration/vm-wiz40-<case>-primary-<hash12>.json`;
each contains full source/spec/artifact pins, original handles/times, child
ready/terminal records, observation/hash and actual integer native exit.
Root invoked the pinned driver37/38 with exact serving spec name/hash, then:

```text
python <verify-hide-observation.py|verify-hide-controls.py> <primary> --primary-sha256 <table-pin> --spec <serving-spec> --spec-sha256 <exact-spec-pin> --production-sha256 adadec44171690a0b9db52787cc3861c5edce92b10a06e200e32b0e698190f39 --kind finalizer|source
```

Exact spec and EXE pins are frozen in the r2 compile output rows and serving
specs; full methods/paths are in `IM-WIZ-40-R2-HANDOFF.md`, SHA256
`f056d0f74abffe411a8cc02cd26d2c463be9d747db291c992d2b5e48871b0682`.

Root's full syntax-only compile against adadec/current bootstrap5b2994 exited0:
`D:/AutoClip-Inno-Migration/im-wiz-35-syntax-7dehnkqs/AutoClip-Setup-v1.exe`,
3394377 bytes, SHA256
`1da87934f31624b1018ba24fe83271c4248a7c1be99d84c1597e54213f3c8d8c`.
Compile-input receipt SHA256
`a3c8f3418349b4ab4e4eb4da892cfa1f4f4b51e6f4a8ff22374d417207b59706`.
This full binary remains UNEXECUTED. `python .github/tests/test_inno_build.py`
passed11 cases and `git diff --check` passed with existing line-ending warnings.
No new blind review approval, production setup, actual uninstaller or release
result follows from these component tests.

After the retained source cleanup-only RED, root resets function Result to false
before rethrowing `ProcessError`. WIZ41's independently reproduced caller RED
also requires clearing the completion flag in `CurStepChanged`'s catch. Current
source61c2 replaces adadec; fresh native controls/body cases and exit checks are
pending. Old source, fixtures, verifiers and primary records remain unchanged.
Root independently ran `python D:/AutoClip-Inno-Migration/check-wiz40-maps.py`:
all four r2 exact line maps and both whole-baseline reversals pass. This check
does not replace the still-failing native source-result control.

## Fresh corrected source native GREEN

Against source61c2, the unchanged pre-RED source cleanup-only verifier now passes:
GUI9232/handle1764, original child7656 immediately status1/exit0, cleanup error
retained and source result=false. Raw primary SHA256
`df730209e51f1ab1e49982ed968359de6209504e6ee5ee52aaae4b8d4636abde`.
Fresh body+Hide regression also passes: GUI7292/handle3788, child12912 immediately
status1/exit0, original Animate error retained, result=false. Raw primary SHA256
`5a0a6e2afb368c45b5877f90957f1ff55541cb8114de3d328f147c4a9c2a483c`.
Both original GUI processes naturally exited0 as inert observation fixtures;
this is not the product install exit. Full handles/times are in the raw primaries.

Specs respectively `wiz38-returncontrol-spec-4f1da0d3.json`, SHA256
`0d10a3d113d4dd13901b6f11bc45f7aef885fda80a9c58f2fa89f3dafc0647dc`,
and `wiz38-returngreen-spec-6012853b.json`, SHA256
`b8ad0b285e6dea5116255b741a44edf90bcb4c5054c2d2bb77ae58c210bd648e`.
Their exact EXE/input/source-map pins are in the combined handoff report SHA256
`4de65f757e6d2ca40fe400dcfa09298c6b3ff1fd54b3fd6f1ff9c93c09c0d1d5`;
complete generation closure207 named paths SHA256
`f1d34021045b7e4536e8daf98975b179f5a7b7793ab6a858da59943bc76fe903`.
Root used unchanged ba89/control and ac01/body host commands with exact primary,
spec and production61c2 pins, `--kind source`; both exited0. Prior RED records
remain intact. Fresh caller/custom-exit and blind review are separate.
