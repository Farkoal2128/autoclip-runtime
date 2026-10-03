# IM-WIZ-26 - reserved input variable correction

Status: authorized bounded correction complete; actual host RED/GREEN and adjacent
regression verification passed. Ordinary collaborator evidence, not guest or
release qualification. Root owns Inno integration and compiled packet renewal.

## Requirement and interface

A noninteractive source supervisor with redirected stdin left open must start
the pinned first-party producer, observe its terminal state and propagate its
exit without consuming or waiting for input. Existing secure input pins, typed
arguments, worker identity/status, logs and cooperative cancellation remain the
contract. No public parameter, schema or completion policy changed.

Read-only inspection of all helper usages found one reserved `$input` local,
inside the secure-input loop. IM-WIZ-25 records primary ConsoleHost/Executor
sources and the native COM mechanism. The entire production change renames that
loop variable and its two references to `$buildInput`. No production stdin
closure, new process control or dependency was added.

## Meaningful RED then GREEN

New `tests/InstallerBuildInput.Tests.ps1` copies the **actual** helper into fresh
protected ordinary-user staging. It uses correctly pinned fake bootstrap,
manifest, downloader and typed JSON; native Windows PowerShell is started through
Diagnostics.Process with redirected stdin left open. The fake bootstrap writes
an entry receipt and waits for a first-party release file. The test validates
the held producer PID against actual RUNNING worker status, releases that same
producer, then requires supervisor terminal observation and exit7 while input
remains open. No vendor, network, VM or compiled Setup executes.

Before the rename, the test exited1: no producer entered during8s with stdin
open. Closing the **same original** supervisor input allowed worker entry and
normal completion. PID55016, handle2796, start
`2026-10-02T06:19:14.1058858Z` remained bound throughout; workerPID46840 finished
and supervisor/status both reported exit7. No kill or restart occurred.

After the rename, the same test exited0: producer entered with stdin open and
the supervisor observed terminal exit7 with stdin still open. PID10044,
handle2704, start `2026-10-02T06:19:40.5240290Z`; workerPID46388. Input was closed
only after the terminal observation, as test cleanup. Protected fixtures/logs
remain available. An earlier diagnostic run failed on missing readiness before
the test was adapted to release the producer after closing original input; that
original process also finished normally after its existing release file was
supplied. It was not killed or restarted.

Exact commands, executed on ordinary native64 Windows PowerShell5.1:

```powershell
powershell -NoProfile -File tests/InstallerBuildInput.Tests.ps1
# RED exit1 before production change; GREEN exit0 after change.
powershell -NoProfile -File tests/InstallerBuildProcess.Tests.ps1
# GREEN exit0: chatty logs, pins/types, exit7, cancellation, commit orderings,
# startup cancellation and malformed/foreign/reparse commit rejection.
git diff --check
```

The new test tests actual helper behavior and never mocks the reserved-variable
behavior. It retains pending original processes on an observation timeout and
does not infer completion from logs or marker presence. This host result
reproduces the missing-entry shape but does not assert a qualified fix for R5;
root must execute its own exact pinned guest composition.

## Frozen inputs and evidence

- `installer/run-source-build.ps1`: 18,916bytes, SHA `3d16b5bbba61e8d9a3ee61769a6ed5e9077b324a6b285cc9aa751d7d7abe83cc`.
- `tests/InstallerBuildInput.Tests.ps1`: 6,776bytes, SHA `e3b8e3a61c588071061de8b37c71647ec8e716893762c10211442c3c358d1ed1`.
- Preserved old wrapper `D:/AutoClip-Inno-Migration/run-source-build-95a40597f6d196ad.ps1`: SHA `95a40597f6d196ad3ae23a6bc5a869899f5c0602fb89dcd2de11bf6277475ae0`.
- RED `C:/Users/beilo/AppData/Local/Temp/autoclip-build-input-5d6d5d862aa64ca4bff4d2186c6ddb40/observation.json`: SHA `a082455a126a39ca303742cc01d0b9f743235e3c73e3363aed5b9d20450fdca1`.
- GREEN `C:/Users/beilo/AppData/Local/Temp/autoclip-build-input-59624cab51ba41fb833b2894cc45ff55/observation.json`: SHA `5c5ca368d5fe838c5a8f0ac5f9c92781a23855d7418ac9171fd14bbcbbb7fb69`.

Only the helper, new focused test and this report belong to this correction.
Historical frozen reports, bootstrap, immutable recipe/archive, Inno, VM drivers
and server source snapshots were preserved. The new helper pin invalidates old
compiled packets; root must refresh their exact input receipt before use.
