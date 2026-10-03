# IM-WIZ-21 — read-only investigation of fixture readiness timeout

Status: investigation complete; fixture correction proposed for parent authorization. **No behavioral RED, source change, compilation, Setup execution, VM operation, retry, release signal, or process termination was performed by this work order.** Only this new report is owned by the agent.

## Primary evidence

Parent-preserved `D:\AutoClip-Inno-Migration\vm-wiz20-readiness-timeout-primary-fc75bbf4802c.json`, 11014 bytes, independently verified SHA `fc75bbf4802cde9cd34016e4788e5be30fe61dc1d8c522cd34c77bdecbf49604`. Observation UTC: `2026-10-02T05:39:19.0325714Z`. Its metadata/full text and CIM rows are the primary basis; host screenshots were viewed read-only as supplemental evidence.

Observed chain:

- Setup loader PID8816, started `2026-10-02T05:34:40.8425712Z`.
- Actual Inno engine `observation-fixture.tmp` PID5736, parent8816.
- Supervisor PowerShell PID12348, parent5736. Command requests `C:\Windows\System32\WindowsPowerShell\v1.0\powershell.exe`; actual CIM `ExecutablePath` is **`C:\Windows\SysWOW64\WindowsPowerShell\v1.0\powershell.exe`**.
- The primary contains no attempt directory/status/stdout/stderr, worker-ready, UI-fault, setup-return, or setup.log file. The original chain remains live in this observation; no terminal result is established.

Important correction to the initial parent summary: `supervisor.pid` **is present** in primary file metadata, five bytes, SHA `015e81eddfab44be16ac53a8653feab50859b4c5508a915679e33c271d2b54df`. Its `text` is null because the observer reads only `.log/.json/.txt`. Independently hashing ASCII `12348` produces exactly that hash. Thus the inserted receipt after `Started := True` was reached, and `Shell.Exec` returned. The primary does not support a claim that synchronous `Shell.Exec` remained blocked.

No held-worker readiness means the intended UI fault was not reached. The controller's readiness timeout is a failed fixture startup observation, not a behavioral RED for leaving an actual running worker. The controller preserved the original processes and did not retry/kill/release them.

## Confirmed harness mismatch

Frozen r2 builder SHA `fe10dc0aa4c21ffddf6db1fad7724f90780de467eebef696c8cfed57b7bac517` uses a literal System32 executable in its command prefix. Current production `RunSourceBuild` instead builds its executable with `AddQuotes(ApplyPathRedirRulesForCurrentProcess(True, ExpandConstant('{sys}\WindowsPowerShell\v1.0\powershell.exe')))`. The fixture copied the observation suffix but replaced this preparation prefix, losing that native-path rule.

The actual CIM executable proves that this run entered 32-bit PowerShell. Therefore the fixture did not reproduce the production native launch boundary. It must correct that mismatch before supporting a production observation verdict. The evidence does **not** yet identify why the 32-bit process remained alive without creating the attempt; do not claim that all 32-bit PowerShell startup is broken or that architecture is the proven underlying stall cause.

Read-only trace found that generated arguments, parameter names, SHA references, held-bootstrap parameters, and supervisor required arguments align. The actual supervisor remains SHA `95a40597f6d196ad3ae23a6bc5a869899f5c0602fb89dcd2de11bf6277475ae0`; its existing WIZ17 first-party native tests exercised compatible bootstrap/held-process patterns. No reason was found to fork its worker or storage logic.

The earlier hypothesis that `InitializeWizard` failed before launching the supervisor is contradicted by the live child and PID receipt. Lifecycle timing may merit later examination, but it is not the minimum presently evidenced correction. The fixture also does not retain WScript supervisor StdErr/StdOut; absence of those logs limits diagnosis of pre-attempt errors. Existing attempt worker logs cannot cover an attempt that was never created.

## Minimum next preparation, pending authorization

Create a new immutable fixture revision, preserving this failed packet/process chain and all previous files. In the fixture preparation prefix, reuse the **exact production native executable expression** above and append the existing logical guest command arguments. Keep the extracted observation suffix, throwing UI seam, held bootstrap, controller and unmodified supervisor intact. Do not add a shipping hook or change production observation logic before actual behavioral RED.

At the preparation level, first demonstrate that the existing compiled-source prefix differs from the exact production native expression, then verify the new generated/compiled prefix uses that exact expression while preserving guest paths, pins and the observation body. This preparation RED/GREEN is separate from runtime RED. Parent must review any compiled packet and distinct runtime action; no automatic retry of the original stage is proposed.

For the eventual runtime evidence, record actual supervisor native executable/PID/start independently, require actual worker readiness, preserve all existing logs, and then evaluate whether Setup leaves observation while that original worker is held. If native startup still fails, preserve that new failure and diagnose it rather than label the production UI defect verified. Existing live original processes need their own explicit parent disposition; this report neither terminates nor restarts them.

## Performed read-only checks

- `Get-FileHash` independently verified primary, frozen r2 builder, controller and supervisor.
- Parsed primary JSON and inspected full file metadata, relevant text, UTC and CIM process rows.
- Read exact frozen compiled `fixture.iss`, held bootstrap, controller readiness loop and actual supervisor parser/startup/worker paths.
- Read production native launch expression and WIZ17 evidence/tests.
- Computed ASCII PID receipt hash, matching original `supervisor.pid` metadata exactly.

No tests or runtime experiments were executed for this documentation-only investigation. It establishes no product, GPU, media, wizard acceptance, uninstall, or release result.
