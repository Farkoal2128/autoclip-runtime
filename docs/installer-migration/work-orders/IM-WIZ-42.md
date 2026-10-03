# IM-WIZ-42 - Source supervisor display-tail sharing race

## Authorization and requirement

Parent assigned this bounded installer/updater diagnosis and TDD fix after the
user resumed installer/uninstaller/updater completion. Owned files are
`installer/run-source-build.ps1`, focused tests, and this work order. Other
writers own candidate/bootstrap/dependency/Inno changes; none were edited here.
Runtime AGENTS, runtime-updater skill and runtime architecture apply.

Contract-v1 source-build observation/progress sections require observing the
actual worker to terminal, retaining input/target locks and full logs, and
propagating actual exit/cancellation decisions. Display output is not authority
for success. A wizard reader temporarily denying tail write sharing must not
abort worker observation. No public schema, exit semantics or contract changes.

## Diagnosis and RED before production edits

The supplied r7 supervisor pin matches the original source exactly:
`aebfed994aa8d033de2d324bbb8a42b07e2f5f93f38f28aae13ad5940aead2d2`.
Supplied bootstrap logs show 78 installed packages, compatible dependencies,
isolated health/home 200 and commit started, while status remains RUNNING with
null exit and tail remains early VC terms. They do not contain supervisor stderr;
the historical r7 cause is therefore not directly captured.

Tracing all Save-BuildTail callers and the Inno LoadStringsFromFile consumer
identified a race: WriteAllText cannot overwrite a tail held by a reader that
denies write sharing. Actual native Windows PowerShell 5.1 reproduction used the
unaltered supervisor, pinned inert first-party bootstrap/manifest/downloader/
arguments, real protected paths and input locks, valid commit bindings, and a
held FileShare.Read handle. No vendor execution, acquisition or source build.

RED command:

```powershell
powershell.exe -NoProfile -ExecutionPolicy Bypass -File tests/InstallerBuildTail.Tests.ps1
```

Exit 1: `RED: tail reader prevented real terminal exit/status for success;
supervisor exit=1 status=RUNNING`. Captured supervisor stderr reports
WriteAllText tail.txt IOException, file in use. The inert worker wrote its valid
COMMIT_STARTED record and completed; the supervisor waited in finally but did
not publish terminal status. This reproduces the historical signature without
asserting that the unavailable historical stderr said the same thing.

Preserved RED directory:
`C:/Users/beilo/AppData/Local/Temp/autoclip-build-storage-1df98fcf664f4e209e25f3301c7437e4`.
Its supervisor `.err` SHA256 is
`4cb014d92a0f9299cc013550020d52af3b3aa5c7aa071bc4d32303de4d04697d`.
Its copied supervisor SHA256 remains the original `aebfed...` pin above.

## Minimal implementation and source-of-truth reconciliation

Save-BuildTail catches only IOException native error 32/33 around the display
WriteAllText call and skips that optional frame. Path/owner/DACL checks remain
outside the catch. All other I/O errors remain fatal. Full stdout/stderr,
status publication, worker exit, commit/cancellation and target/input locks are
unchanged. No refactor or new dependency.

The pre-edit BuildProcess baseline passed actual chatty/exit7/live-cancellation/
security cases, then failed `Actual immutable recipe boundary selection differs`
at its uniqueness assertion. The AST predicate counted every IF containing the
native invocation, including the legitimate newer publisherCpu outer IF
(current lines 1608-1641) and original inner IF (1637-1639). Parent authorized
reconciling this stale test assumption. The test now selects the unique actual
native CommandAst and its nearest IF, then joins the actual native suffix and
common post-producer AST statements. Native fixture explicitly selects source
mode. Original CPU/NVIDIA stage counts 6/8, all cancellation assertions, actual
completion/reuse call checks and malformed commit checks remain intact.

## GREEN and focused verification

All commands below executed from `D:/Projects/autoclip-runtime` on native
Windows PowerShell `5.1.26100.9444`, exit 0:

```powershell
powershell.exe -NoProfile -ExecutionPolicy Bypass -File tests/InstallerBuildTail.Tests.ps1
powershell.exe -NoProfile -ExecutionPolicy Bypass -File tests/InstallerBuildProcess.Tests.ps1
powershell.exe -NoProfile -ExecutionPolicy Bypass -File tests/InstallerBuildStorage.Tests.ps1
powershell.exe -NoProfile -ExecutionPolicy Bypass -File tests/InstallerBuildInput.Tests.ps1
powershell.exe -NoProfile -ExecutionPolicy Bypass -File tests/InstallerBuildComposition.Tests.ps1
git diff --check -- installer/run-source-build.ps1 tests/InstallerBuildProcess.Tests.ps1 tests/InstallerBuildTail.Tests.ps1
```

Tail regression proves held-reader actual success 0, nonzero 7, accepted cancel
1223 and invalid commit rejection with readable stderr. Actual shared function
also rejects a tail directory I/O failure and foreign-writable tail without
mutation. Process tests prove full chatty logs, bounded tail, Unicode arguments,
native stage cancellations, commit/cancel ordering, startup and invalid commits.
Storage/input/composition prove durable logs, real held stdin, target exclusion,
different-root independence, retry, alias identity and unsafe paths. No valid
tests disabled or assertions weakened.

Frozen implementation/test pins:

| File | Bytes | SHA256 |
| --- | ---: | --- |
| installer/run-source-build.ps1 | 19346 | aa5f2051a64627951899c146b2a992e6c42d52c9c90295e7bf539b16b2f74100 |
| tests/InstallerBuildTail.Tests.ps1 | 8418 | 380f6e1e66632d40d7f20b970dfd6884b1995cb7644ffe3a641f1da6eae6b196 |
| tests/InstallerBuildProcess.Tests.ps1 | 18470 | 5d89d93a66415bd703a4a51a3c8c4a3ec4f259cdda6c2c3172a474e36a277cf5 |

Parent owns candidate rebuild/pin reconciliation, installed-release VM smoke,
broader repository verification and technical review. This worker performed
no vendor UI, release, publication or cleanup and makes no historical r7 or
installed candidate GREEN claim. Per-run model telemetry is not exposed.

## Addendum - reviewer-observed fixture acquisition race

Parent subsequently authorized only this test and work-order correction;
production supervisor remains frozen at `aa5f2051...` above. Reviewer primary
`D:/Projects/autoclip-runtime-evidence/IM-DEP-13-review-r8/InstallerBuildTail.stderr.log`
records the original fixture Open tail read handle failing with sharing
IOException at test line 55 before the worker assertions. Its SHA256 is
`55eef82e6bf99d70c047836919d2ce20a53229123cc068b95f39504a7329c11a`.
The review retry passed, confirming a test acquisition timing failure rather
than a production terminal regression. This is pre-correction failure evidence;
no new production changes or fabricated production RED.

Test reader acquisition now retries only native sharing errors 32/33 for at
most two seconds while the actual supervisor remains live. Failure to establish
the reader is still a test failure; all other I/O failures propagate immediately.
Once established, the same reader remains held through actual terminal exit;
the success/nonzero/cancellation/invalid-commit assertions are unchanged.

A real exclusively opened fixture file proves reader acquisition rejects when
no read handle becomes available by its short deadline while the actual
supervisor stays alive. Actual Save-BuildTail also proves the held reader skips
the old frame and that publication resumes after that same handle is released.
Neither check mocks the sharing or supervisor behavior.

Executed from `D:/Projects/autoclip-runtime`, native PowerShell 5.1, both exit 0:

```powershell
powershell.exe -NoProfile -ExecutionPolicy Bypass -File tests/InstallerBuildTail.Tests.ps1
git diff --check -- tests/InstallerBuildTail.Tests.ps1
```

Current test is 10112 bytes, SHA256
`2bf4d85e088566afe95a5cb48bb75a5976bd7ea98bc7aee5f86fcd46bc8f58e3`.
The earlier test hash in the frozen table identifies the reviewed predecessor.
No other file changes, VM, vendor action, acquisition, release or cleanup in
this addendum. The parent retains compiled r8 candidate ownership.
