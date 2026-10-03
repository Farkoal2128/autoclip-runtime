# IM-VS-31 — retain original native handle and start time

Prepared and focused fixture-verified, 2026-10-02. Parent authorized a bounded external first-party diagnostic correction only. Own the two new r2 files and this report; root owns actual VM state/logs and any later distinct qualification. No VM/server/acquisition/vendor action, production edit, old-driver edit or historical receipt edit occurred here. Report follows the existing installer-migration work-order directory convention.

## Preserved original failure

Parent reports the actual offline cold run used the frozen original driver SHA `b869faec13fd8e71f608418d08aa8a59f2144da20ef8d29e03f5c1fb8394309c`, UAC driver PID7940 terminal exit2. Guest evidence remains `C:\ProgramData\ac-engine-6b3d5693`, receipt status `FAILED_PRESERVED`, phase `engine_update`, error `You cannot call a method on a null-valued expression.`, vendor_execution=true/PID12768, with no recorded native vendor exit. This author did not read/operate the guest or infer that the Microsoft operation succeeded/failed with a particular exit. A first-party driver's exit2 is not the unknown vendor exit.

## Source-confirmed and reproduced cause

Original source starts the native process at line107, then executes the CIM/module sampling loop and `Process.Refresh` without first materializing the Process handle or caching native start time. At line121 it tries to obtain ExitCode and converts StartTime only after terminal state/Refresh. Finally waits only if the original Process still reports active. This can lose native process information after a quick exit.

The new focused fixture **extracts and executes the actual process stanza from the frozen original**, from its Start-Process statement through the statement before `post_inventory`. Only its launch inputs are first-party fixture values: trusted system `cmd.exe /d /c exit 7`, a new fixture temp root and an in-memory receipt. The actual CIM/module/500ms Refresh loop is executed; the tested behavior is not mocked or replaced.

RED before implementation: original stanza recorded exit_code=null, native_start_utc=null, native_exit_utc=null and the exact same null-valued-expression error. The test then exited1 because the corrected snapshot did not exist. Final RED recheck reproduced those same null fields/error again. This directly demonstrates the host failure mechanism and closely matches the reported guest error; it cannot retroactively supply the original guest native exit or prove an unrecorded guest stack location.

The stanza's receipt field `vendor_execution=true` remains unchanged while extracted into the fixture. **Its actual executable was harmless native cmd.exe, not a vendor prerequisite.** That label is not a claim of Microsoft installer execution by this author.

## Minimum correction and unchanged boundary

New `vs-admin-engine-probe-r2.ps1` differs from the original in exactly two locations:

1. Immediately after Start-Process and the existing launch-receipt initialization, materialize `$process.Handle`, capture `$process.StartTime` as UTC and record that saved native start immediately. Both belong to the original Process object; no GetProcessById/reopening or PID substitution is added.
2. After terminal wait, use the captured UTC start string instead of querying StartTime again after Refresh. The retained native handle allows the existing ExitCode/ExitTime getters to work in the actual quick-child fixtures.

Every other source byte/statement remains equivalent: fixed vendor arguments, context/token/system PowerShell/ACL/path/readlock/authentication/current-chain checks, cold baseline, NIC checks, standard output/error capture, point-of-use pins, post868 comparison, receipt status/failure handling and incomplete-monitoring fields. No production manifest/contract promotion, argument fallback, retry, tracing workaround or vendor trust waiver is added. The existing no-kill/no-retry and original-handle waiting behavior remains. This change is not a broader observer/finally redesign and does not guarantee child handles, exhaustive module coverage or arbitrary early-observer-failure exit recording.

The original VM may now contain vendor side effects even though its driver failed. Preserve and investigate that state; do not call it clean or repeat the operation automatically. R2 retains the original cold-absence guard and fixed input paths. Root must independently determine a suitable future distinct qualification context and review the new snapshot before any action; this report authorizes no VM retry.

## Exact verification

```powershell
powershell.exe -NoProfile -File 'D:\AutoClip-Inno-Migration\vm-transfer\vs-admin-engine-probe-r2.Tests.ps1'
git diff --no-index -- 'D:\AutoClip-Inno-Migration\vm-transfer\vs-admin-engine-probe.ps1' 'D:\AutoClip-Inno-Migration\vm-transfer\vs-admin-engine-probe-r2.ps1'
```

Focused test exit0: frozen original exact hash; exact original expected failure; actual corrected stanza with native cmd exit0 **and** exit7; nonzero materialized original handle; exact exit codes; non-null native start/exit in chronological order after the unchanged sampling/Refresh loop; read-only default plan/exit0. No vendor executable, setup, host vendor acquisition or VM operation. Fixture stdout/stderr/roots remain preserved. Diff command exit1 means differences exist; inspected output contains only the one added early capture line and one saved-start substitution described above.

No unrelated unit/build/release/installed smoke test is claimed. Default and process fixtures are the focused lowest-level proof for this diagnostic lifecycle change; actual Windows guest/vendor qualification remains root-owned and unperformed here.

## Frozen new files

| File | Bytes | SHA-256 |
| --- | ---: | --- |
| `D:\AutoClip-Inno-Migration\vm-transfer\vs-admin-engine-probe-r2.ps1` |14523| `142a8d52a92cea0b116933d82a8ee306e5d94ea0b74d392ed839c95afca21bdc` |
| `D:\AutoClip-Inno-Migration\vm-transfer\vs-admin-engine-probe-r2.Tests.ps1` |2835| `7ab453775cff82bdc30bcfa2c9348301faa5db7ac620b7d452beb895339adb15` |

Original driver remains14415 bytes/SHA `b869faec13fd8e71f608418d08aa8a59f2144da20ef8d29e03f5c1fb8394309c`, rechecked unchanged. Interface remains default read-only or explicit `-RunEngineUpdate`; root's trusted verified inline admin-code delivery remains a separate reviewed action, and no operational command was generated/run here. Ownership of this corrected frozen snapshot returns to root. Microsoft remains BLOCKED; original native result remains unknown until actual retained evidence resolves it.
