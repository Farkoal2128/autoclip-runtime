# IM-PY-03: conditional Python provisioning in Inno

Status: implementation and compiler boundary checks complete; revised compiled
diagnostic reuse passed in the VM, but the full suite is incomplete after the
guest executable disappeared before targeted decline rerun. Production Python remains
BLOCKED. This report does not establish installation, legal, or release approval.

## Scope and observable contract

Parent authorized changes only to `installer/AutoClip.iss`,
`scripts/build-inno.py`, `.github/tests/test_inno_build.py`,
`tests/InstallerPythonWizard.Tests.ps1`, and this report. Existing eight embedded
inputs, managed FFmpeg arguments and x64os restriction are preserved. No vendor
installer, agreement acceptance, reboot, publication, or commit was performed.

Reuse exact full registered Python through the existing pinned preflight/helper.
Only a missing compatible interpreter shows a separate explicit Python terms
declaration. Decline prevents acquisition. Terms URL and exact installer SHA256
are derived from the manifest row and bound into the compiler invocation. After
download, recheck helper and manifest pins immediately before provisioning;
successful helper exit additionally requires native capability verification.
Cancellation, launch/download/vendor failure and failed postcheck stop setup.

Exit 3010 never means success. An atomic owned marker binds the Python helper hash
and native OS boot ticks; same-boot retries remain pending even when Python now
passes capability checks. Changed boot clears only the exact owned marker and
still requires capability verification. Foreign/reparse marker paths fail closed.
Helper pending-reboot receipts provide a fallback if marker writing failed.
Silent setup does not request an automatic restart; interactive setup reports
pending restart through Inno's preparation state.

Fixed native PowerShell calls use `ExecWithNativeSysDir`. The initial candidate's
64 bit install mode directive did not change the setup executable's bitness and
was removed. The official [native system directory execution reference](https://jrsoftware.org/ishelp/topic_isxfunc_execwithnativesysdir.htm)
states that this function disables WOW64 redirection for a 32 bit installer;
plain Exec needs explicit native path handling. The existing downloader's
explicit WScript path handling is preserved. The x64os restriction is unchanged.

## RED and current verification

Meaningful preimplementation RED: the compiler invocation test failed because the
Python artifact hash define was absent. The test executes the actual builder
against its fake compiler boundary; it does not assert production source text.

After the minimal builder change:

```powershell
& 'C:\Users\beilo\AppData\Local\Programs\Python\Python311\python.exe' -I -B -m unittest discover -s .github/tests -p test_inno_build.py
```

Result: six tests PASS, including Python artifact/terms compiler binding and
existing builder regression coverage.

Additional focused regression commands:

```powershell
& .\tests\InstallerPythonInstall.Tests.ps1
& .\tests\InstallerPreflight.Tests.ps1
git diff --check -- installer/AutoClip.iss scripts/build-inno.py .github/tests/test_inno_build.py tests/InstallerPythonWizard.Tests.ps1 docs/installer-migration/work-orders/IM-PY-03.md
```

Result: Python installation boundary, CheckOnly and preflight tests PASS;
preflight MSYS2 and blocked/GPU separation regressions PASS; whitespace check
PASS. These tests do not install vendor software.

The new focused PowerShell test extracts actual Pascal decision blocks without
rewriting those decisions. It substitutes acquisition, native process launch,
boot identity and the diagnostic state location only. The native fake helper
requires 64 bit PowerShell and the expected manifest/argument boundary. No hook
or bypass is present in production. Scenarios: reuse, decline, success, failed
postcheck, cancellation, vendor failure, download failure, launch failure,
same-boot pending, changed-boot retry, marker-write failure and foreign state.

The exact compiler successfully compiled the diagnostic. Host launch was blocked:
`Operation did not complete successfully because the file contains a virus or
potentially unwanted software.` The first blocked temporary executable was
removed by ordinary test cleanup before its hash could be recorded. No Defender
settings, exclusions or implementation changes to evade detection were made.
Compiled behavioral GREEN is therefore not yet claimed.

## Frozen diagnostic export

Export command:

```powershell
& .\tests\InstallerPythonWizard.Tests.ps1 -ExportRoot 'D:\AutoClip-Inno-Migration\python-wizard-diag-61e074c49a9b49f18f1036fbf58654e6' -ExportOnly
```

The export contains only first-party fake inputs, diagnostic source, production
source snapshot, compiler log, diagnostic executable, runner and hash receipt.
It was compiled but not relaunched on the host. Protected directory DACL grants
SYSTEM, Administrators and beilo access; no broad public grant. Exact exported
path lookup in `Get-MpThreatDetection` returned zero attributable records.

Compiler SHA256:
`d06ebd38f38e3cee60a3c50cc45bd449d77e0bc6a5cabc607ea9886808e4de1a`.

Diagnostic executable SHA256:
`93cc49d7341c050f16323baeba21366d647e0fe284488f734cd4e755a4ef5a2f`.

Runner SHA256:
`7d4c01634fbeb0fc0c306e50f05309f6bf6fbd68a48c9d472e7e898302e58ddb`.

Copy the complete export folder to the parent's authorized VM and execute native
PowerShell with `-NoProfile -ExecutionPolicy Bypass -File <folder>\run-diagnostic.ps1`.
Expected result: one PASS summary after twelve cases. Each case preserves a
result `.txt` and native boundary `.trace`. The executable aborts during wizard
initialization and cannot enter installation. If VM protection denies it too,
record the behavioral qualification as blocked without weakening protection.

Frozen source SHA256 values:

| File | SHA256 |
| --- | --- |
| installer/AutoClip.iss | a0d83e6905979a07c0fc44749aa365a29bd9c560e6af6dfb888c6038cd82c6cd |
| scripts/build-inno.py | 72d6c6c1a0de0bc831104cab7125cd91c4141ec1a1b6d4dc082425a473fa4df5 |
| .github/tests/test_inno_build.py | 44ac7c9920c1eac9b21961336e27a2f7faba976b3283d32baa6d38f0a5f70c68 |
| tests/InstallerPythonWizard.Tests.ps1 | 3b0c4aaabae96235d4cf07075416a9911d96fed47da6a74d11a811fd7ea0b8ec |

## Limits

No complete production wizard installation or real reboot occurred. The
diagnostic uses fake native helpers and download output, while existing Python
helper tests establish its separate validation/provisioning contract. Current
BLOCKED manifest classification prevents production promotion. Real recipient
agreement and real installer qualification remain with the parent.

## VM behavioral RED and revised candidate

The parent ran the exact original diagnostic executable in its isolated VM with
protection unchanged. Receipt:
`D:\AutoClip-Inno-Migration\vm-python-wizard-20261001.json`.
The reuse case failed: two native calls, no helper trace, no acquisition, and
consent-required outcome instead of successful capability reuse. This is an
executed behavioral RED, not an endpoint protection block. Original executable
SHA256 `93cc49d7341c050f16323baeba21366d647e0fe284488f734cd4e755a4ef5a2f`
and export remain unchanged.

Narrow host reproduction of the exact original fake helper under native
System32 PowerShell returned 0 and wrote `check`; syntax/argument shape is valid.
The fake child requires a 64 bit process before writing its trace. The supported
native execution fix above addresses the setup's 32 bit native launch boundary.
Fresh diagnostic preserves `.txt.native` files containing exact command and
launch/exit code. The registered reuse assertions and child bitness assertion
remain unchanged.

New compiled candidate export:
`D:\AutoClip-Inno-Migration\python-wizard-diag-2b6610dacfd04c7e927b110575c827c1`.
Same runner command and twelve cases; parent VM execution pending.

| Revised file | SHA256 |
| --- | --- |
| diagnostic executable | d923544d210302beab4ee4eb90d2b1236b00009f4ea38b486f7139f86c9d64c7 |
| diagnostic source | 82be36b1f2cb844e8441086c90db1706fc35e03e8a03281c9aed836821cafda7 |
| runner | 345222e68f07563526c4639c39295db88ff45ab91f8926566e69251cc07dd61a |
| installer/AutoClip.iss | efa9b95e74b16835645318e3cb58cd51358ab5b02c320a9c34fc6b62deb55b2f |
| tests/InstallerPythonWizard.Tests.ps1 | 86995d0290cb41a47891d8792ae9242f68079ff17905b2034d026f29797adadf |

Builder and builder-test hashes above remain current. Original frozen values
above are retained as historical evidence. No production approval transfers
from either diagnostic candidate.

## Frozen diagnostic state audit after guest disappearance

Parent's revised VM run verified registered reuse: result
`0|2|1|0|||`, native capability exits 0, and trace `check/check`.
The next decline case produced no result. Its executable subsequently could
not be resolved or hashed in the guest before a targeted rerun. A security
tray alert was observed; attributable detection evidence is not yet available.
This does not prove quarantine or a production security finding. Full diagnostic
qualification remains incomplete. No third executable, protection change,
restoration, exclusion or assertion weakening was attempted.

Receipt `D:\AutoClip-Inno-Migration\vm-python-wizard-20261001.json`, revised-run
SHA256 `05aad8ac782b10192e7e19d41b50aa9924488285e2ddd9b68fb98637a4397e75`,
records the exact `d923544d...c9d64c7` executable. Parent also reported later
independent native PowerShell Utility module loading failures/stalls. This
audit does not establish their cause.

Read-only methods: inspect the exact frozen `diagnostic.iss`, both fake native
helper scripts and `run-diagnostic.ps1`; search mutation APIs/environment paths;
parse each PowerShell input with its AST; verify all exported file hashes against
`export-receipt.json`. All exported pins match. All three scripts parse without
errors. Production and test hashes remain `efa9b95e...deb55b2f` and
`86995d02...797adadf` respectively.

| Inspected boundary | Effects present in source |
| --- | --- |
| Standalone exported runner | Sets only process-local `AUTOCLIP_PYTHON_DIAG_CASE` and `AUTOCLIP_PYTHON_DIAG_RESULT`; launches the exact diagnostic; may kill that exact process on timeout. The standalone runner does not restore its two variables on failure. The repository test restores them in `finally`. |
| Fake preflight | Reads extracted fake manifest; appends `check` to supplied result trace; returns fake capability code. |
| Fake install helper | Writes `registered.txt` beside extracted fake manifest; pending receipt under its extracted `fixture-state/logs/python`; appends result trace. Real-looking `LogDirectory` argument is accepted but unused. No vendor executable is launched. |
| Pascal native-state block | Reads/writes/deletes only diagnostic `{tmp}/fixture-state` owned marker and sibling temporary files; boot identity is substituted in the test. |
| Pascal downloader replacement | Writes a plaintext installer fixture inside `{tmp}` and result trace; no network acquisition. |
| Pascal initialization/native boundary | Extracts three fake inputs under Inno temporary directory; writes result and `.native` files to supplied result location; aborts before installation. |

No inspected source assigns global/user/machine environment, PATH, PSModulePath,
PSHOME, registry values, persisted execution policy, module files, services,
Defender configuration or Windows system files. Fake scripts can auto-load
PowerShell Utility commands such as ConvertFrom-Json/ConvertTo-Json, but contain
no module-path change, module removal or module-file mutation. Process-local
diagnostic variable assignments cannot explain a fresh independent native
PowerShell process being unable to import Utility.

Result paths are test inputs and are not generally sandboxed by the diagnostic;
the parent's executed route placed them in its owned guest TEMP export folder.
The real LocalAppData path appearing in actual extracted provisioning arguments
does not cause writes there because the embedded fake helper ignores it. The
production source snapshot shipped for review is not included as executable
input in the diagnostic's `[Files]` section.

Conclusion from source inspection: no intentional persistent machine mutation
or Utility module damage mechanism was found. This is bounded first-party source
evidence, not a forensic proof about Inno's native engine, operating system logs,
security-product side effects, another guest process, or the missing executable.
Parent owns guest investigation; no new guest action was taken by this agent.

## Attributable endpoint remediation: remaining cases blocked

Parent preserved a protection receipt, verified here read-only:
`D:\AutoClip-Inno-Migration\vm-python-protection-20261001-0e2fbbc91f76.json`.
Its SHA256 is
`0e2fbbc91f76b87a6cabe684b359666bc3112e10d673d566c21a73c1517333cb`.
The parent filtered Get-MpThreatDetection to the exact diagnostic guest path
prefix and matched Get-MpThreat only by the resulting ThreatID. No unrelated
threat history was used for this conclusion.

The revised candidate's detection resource names
`C:\Users\autocliplab\AppData\Local\Temp\autoclip-python-wizard-diag-22ba81e32cb5438c9b174266b79021a1\diagnostic\python-wizard-diagnostic.exe`.
The corresponding executed binary was hash-bound by the VM execution receipt
to SHA256
`d923544d210302beab4ee4eb90d2b1236b00009f4ea38b486f7139f86c9d64c7`.
The endpoint detection record itself identifies the resource path, not a binary
SHA256; the hash attribution comes from the separate preserved execution receipt.

| Recorded field | Value |
| --- | --- |
| ThreatID | 2147731250 |
| ThreatName | Trojan:Win32/Bearfoos.A!ml |
| SeverityID | 5 |
| ActionSuccess | true |
| ThreatStatusID | 3 |
| IsActive | false |
| DidThreatExecute | false |
| Initial detection | 2026-10-01 15:20:58 PDT (22:20:58 UTC) |
| Remediation | 2026-10-01 15:21:18 PDT (22:21:18 UTC) |

The record also names the original `611e1a529dbc4a5b84ae21e901eb8cfd`
diagnostic guest path under the same ThreatID. Exact revised-candidate file
disappearance was independently observed before targeted decline rerun.

Qualification is now **registered reuse PASS; remaining eleven strict cases
blocked by attributable endpoint remediation**. The diagnostic assertions are
unchanged. The endpoint's DidThreatExecute field is recorded as reported; it
does not negate the separately observed benign reuse diagnostic execution.

This evidence establishes a real security-product detection and successful
remediation against the diagnostic resource. It does not determine whether the
detection is a false positive, prove production malware, prove production
installer safety, or explain the independent Utility-module import failures.
No real production setup installation was performed. No new candidate,
restoration, exclusion, protection change or detection-evasion change was made.
Production/test sources and both candidate exports remain frozen. Root continues
other eligible work; this diagnostic qualification is not promoted to complete.
