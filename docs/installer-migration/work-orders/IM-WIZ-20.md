# IM-WIZ-20 — prepare the Inno observation-failure fixture

Status: preparation complete; **behavioral RED/GREEN unperformed**. Parent owns runtime action review and execution. No production change is authorized by this work order.

## Requirement and scope

`contract-v1.md` requires observing the original source worker through terminal state, including observation failures. WIZ-18 identified that `RunSourceBuild` repeats `DownloadPage.Animate` in `finally`; another UI exception can escape that final observation loop. This packet tests that actual control flow with a held first-party worker. It does not install AutoClip, invoke prerequisites, acquire vendor bytes, accept terms, run `/AUDIT`, exercise cancellation ordering, or test uninstall.

Parent authorized only new external fixture builder/controller/tests and this report. The actual supervisor remains unchanged. Parent explicitly authorized its normal recipient `AutoClip/Setup/locks` empty target lock; preserve that lock and its parents. All fixture inputs, target, attempt, logs and held bootstrap live in a fresh protected TEMP directory. Foreign existing Setup ACLs fail preflight. No Setup executable or VM action was executed during preparation. Earlier notice `/AUDIT` actions were automatically rejected; this packet does not retry them or change their scope.

## Faithfulness and seams

Builder extracts the current `RunSourceBuild` observation suffix from `BuildActive := True;` to its end, plus the entire actual `PollBuildCancellation`. The readiness/prerequisite/acquisition prefix is replaced by fixed first-party fixture paths and arguments. Observation loops, `try/finally`, exit evaluation and cleanup are retained. The only observation call replacement is `DownloadPage.Animate` to `FixtureAnimate`; one PID receipt statement is inserted after actual `Started := True`. Tests reverse both changes and require exact original suffix equality. Poll's real code is retained; this scenario leaves cancellation pending false.

`FixtureAnimate` calls actual Animate until the bootstrap signals held-worker readiness, then records the fault seam and throws on every refresh. The actual unmodified supervisor launches its actual worker mode, which invokes the pinned held bootstrap. No parallel supervisor/worker observation model is substituted. Empty manifest and downloader inputs are hashed/readlocked by the real supervisor but never interpreted as product/vendor instructions.

Controller requires explicit `-RunFixture` and an exact packet SHA. It locks all frozen input files, reuses the actual supervisor's path/ACL function, checks ordinary-user context, and refuses reused stages. It captures Setup PID/start, original supervisor PID/start and worker PID/start. After the UI seam is reached, it samples whether Setup already left observation while both original processes remain held, preserves that primary receipt, then releases the bootstrap and waits for those original processes. Terminal status must match worker identity/helper pin and integer-zero exits. Logs and state remain preserved. Readiness/terminal timeouts leave live processes and logs intact; no automatic kill/retry. The sampling includes 500ms for exception unwinding; runtime evidence must show the fault and held state rather than treat compilation as a behavioral verdict.

## Frozen preparation

- Inno production source: `53d8c0a614884cfb8b2ed3ca334d43daf49ad2c91c835851f7e4c4c41495efd7`.
- Actual supervisor: `95a40597f6d196ad3ae23a6bc5a869899f5c0602fb89dcd2de11bf6277475ae0`.
- Approved ISCC 7.1: `d06ebd38f38e3cee60a3c50cc45bd449d77e0bc6a5cabc607ea9886808e4de1a`.
- Builder: `c039856569a1665c8d86110d01a0f6f84626ec4a9577023df5e08a18fb03f2b8`.
- Focused tests: `94e8ec0d116efb2b637fe4b37a7454ecc458cad56ffcb900e83fa6dabd988d7a`.
- Controller hash is reported with the handoff (this report avoids self-dependent hash cycles).

Compiled packet root: `C:\Users\beilo\AppData\Local\Temp\ac-observation-9045a1a99f87452b9c591e41e0d2fc74`.

- `packet.json`: `ef631c36de20681d38bdc66ce5ec5dd5c7c77c63459daf4a51ae55ad641d62e8`.
- `fixture.iss`: `42b5e413c8477b41074c93c8d85a5eaeaf64502fb2cc8b3d3a84ec91abe64c05`.
- `observation-fixture.exe`: `b902b05e41ced5cdcc6047dd49a300fb534cf829e0763d986bd06dd952886eaf`.

The fixture embeds this TEMP path; it is not relocatable. A different recipient context needs a newly reviewed build/packet. Earlier unsuccessful syntax-only stages are preserved; final compilation exits zero. No EXE has run.

## Exact performed commands and results

```powershell
& D:/AutoClip-Inno-Migration/vm-transfer/inno-observation-fixture.tests.ps1
& D:/AutoClip-Inno-Migration/vm-transfer/inno-observation-fixture-build.ps1 -Compile
```

Focused checks PASS: exact reversible extraction, actual poll boundary, missing-boundary rejection, PowerShell parsing, no-operation controller default, and actual controller rejection of wrong packet hash and tampered input before process creation. Approved compiler exits 0 and reports successful compile. These are preparation checks; they do not demonstrate the reported observation bug or its correction. No production files were edited.

Pending root review: authorize the distinct first-party runtime fixture action, run this exact packet in the same ordinary-user context, inspect full logs/process identities and early-return/terminal receipts, and only then use actual RED to authorize a minimal production correction. A subsequent GREEN must extract the corrected production procedure and preserve the same failure scenario; source pins must intentionally change. This fixture provides no installation, application, media, GPU, wizard acceptance or uninstall result.
