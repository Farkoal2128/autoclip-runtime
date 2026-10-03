# IM-WIZ-37 — Native finalization child observation fixture

## Authorization and ownership

Parent authorized only the external generator
`D:/AutoClip-Inno-Migration/vm-transfer/inno-final-process-test.py` and this report.
No production, vendor, VM, compiler, Setup, uninstaller, or publication operation
was performed by this producer. Root owns native compilation/execution and the
production correction. Installer readiness precedes the requested generated
uninstaller test; this work does not execute that test.

## Required behavior and concrete boundary

A display failure after a successful finalizer launch must not escape while its
original child is still running. The minimum proposed production correction is
to move the existing `try` immediately after successful `Shell.Exec`, bringing
`SetText` and `Show` inside the existing `finally` child wait. No new process
wrapper, restart, cancellation, or kill is proposed.

Input `installer/AutoClip.iss` SHA256:
`0c41fc3cf1f9c955b29134f4b0a88c531b03a5b66e35925f15515fa466f1507a`.
The exact `FinalizeSetupReceipt` tail, lines 998–1021, is copied from
`Shell := CreateOleObject('WScript.Shell')` through its closing `end` and blank
separator. The generator refuses any source-pin mismatch before output creation.

Each source line has a packet mapping to its generated line. The only tail
changes are `DownloadPage.SetText/Show/Animate/Hide` calls replaced by inert UI
stubs and one inserted `FixtureProcess := Process` after actual `Shell.Exec`.
The stub either throws at SetText, throws at Show, or succeeds. Actual production
wait loops, exception handling, output reads, exit/receipt checks, and completion
assignment remain copied. Fixture request preparation replaces production
finalizer inputs with a pinned first-party PowerShell child; no receipt producer
or product code runs.

The child writes a PID/native64 ready record, waits two seconds, writes a terminal
receipt, and exits zero without stdout/stderr. The observer catches the call's
exception and immediately reads the preserved original COM child's Status and
ProcessID; it reads ExitCode only when terminal. It has no wait, sleep, restart,
or kill. The interactive fixture stays open so the parent can observe the same
original child's eventual termination without concealing the immediate result.

## Native procedure pending with root

1. Compile the baseline SetText fixture using approved exact ISCC; precreate its
   unique protected native LocalAppData fixture directory and copy the pinned
   child there as `fixture-child.ps1`.
2. Run the inert fixture interactively. Retain `observed-process.txt`, ready and
   terminal records, exact process identity, source/setup pins, and native logs.
   A meaningful RED is `caught_error=FIRST_PARTY_SETTEXT_FAILURE` with immediate
   status 0 and `NOT_TERMINAL`. If the child already terminated before injection,
   that run cannot establish this RED; preserve it as inconclusive.
3. Root applies only the agreed production try placement correction, regenerates
   against the new exact source pin, and runs both SetText/Show failures and the
   control. GREEN requires immediate status 1/exit 0 in all three; each failure
   retains its corresponding controlled exception and incomplete flag, while
   control has no exception and completed flag true. Verify native64/PID binding.

Every fixture has a unique non-product AppId/root, `CreateAppDir=no`,
`Uninstallable=no`, `CreateUninstallRegKey=no`, and no Files/Run entries. The parent
must protect fresh fixture directories before execution; the generator does not
claim it verified VM ACLs. Existing observation/ready/terminal records cause
refusal and are preserved. This is a native event/process boundary test, not full
installer, health, vendor, or uninstaller qualification.

## Preparation verification performed

Working directory: `D:/Projects/autoclip-runtime`.

```powershell
python D:/AutoClip-Inno-Migration/vm-transfer/inno-final-process-test.py --source installer/AutoClip.iss --expected-source-sha256 0c41fc3cf1f9c955b29134f4b0a88c531b03a5b66e35925f15515fa466f1507a --output-dir D:/AutoClip-Inno-Migration/vm-transfer/wiz37-process-fixtures
```

Exit 0. In-memory Python `compile()` passed. A separate PowerShell here-string
piped to `python -` independently compared every mapped generated line with the
original source line, applying only the four declared UI substitutions; every
remaining line including line endings was equal. It verified exactly one inserted
COM-reference line per fixture and all three artifact hashes. All passed. A
second `python -` check invoked the generator with a zero source pin: nonzero
exit and exact pin-rejection message, with no output directory created. Neither
check compiled or executed native fixtures.

## Frozen preparation outputs

| Output | SHA256 |
| --- | --- |
| External generator | `9012278f67f9bfc5bc94b88e5d15c765285384014d76889a86ed14aadf1f2e33` |
| First-party child | `a9eb9d72c9ba40b8b04c1d34a81a24b8f35d54aaafca158d8e817420ea312944` |
| Baseline SetText source | `d3567f7b35adf2ecb447a277854dd797dab9e94548e12671aac70c3c3128ac05` |
| Baseline Show source | `d3f1f7dbad74c20be3c0f9b99dad5d7da01d2b555a8493002b0a4eb2fd15b066` |
| Baseline control source | `4129da1f1c8d6cef764f1fa1510f64f29d0c540027c8833d361efa84d8a292de` |
| Baseline packet | `0649885b9a26a734a672c35dd7467c2d319db92a84c0a0a5a5dff72537a1d2c4` |

Packet:
`D:/AutoClip-Inno-Migration/vm-transfer/wiz37-process-fixtures/wiz37-process-fixture-packet-b32d1f25349f44b884a7a6d4ad34a200.json`.
It records all generated source/child paths, input pins, extraction span, explicit
line map, and `compiled=false`, `executed=false`. This producer has demonstrated
preparation checks only; actual native RED/GREEN remains root's work.

## Root native execution and unresolved cleanup contradiction

The preparation above is historical. Root compiled and executed inert fixtures
in `AutoClip-Inno-Win11-Direct-20261002` (UUID
`e6661e4b-cdcd-4e1c-baa3-cb34ad5cd3c0`), ordinary native64 `autocliplab`,
Windows build 26200, no GPU passthrough. These fixtures have no product payload,
registration, vendor operation or uninstaller. Production Setup remains unrun.

The unchanged runnable verifier is
`D:/AutoClip-Inno-Migration/vm-transfer/verify-wiz37-observation.py`.
For each retained primary, root ran `python <verifier> <primary>`. It checks the
immediate original COM child Status/ExitCode, source/child pins, native64/PID
binding, original controlled error and completion flag. The parent driver waits
for its original GUI process handle; the immediate observer does not wait.

| Case | Exact production source SHA256 | Immediate child | Verifier result | Primary evidence SHA256 |
| --- | --- | --- | --- | --- |
| Baseline SetText failure | `0c41fc3cf1f9c955b29134f4b0a88c531b03a5b66e35925f15515fa466f1507a` | PID11236, Status0, NOT_TERMINAL | RED, exit1 | `6aa34f0f166405063f8d4a01a11e794ff23bfb0f73b58f342064020bbc6deeb2` |
| SetText failure after moving try | `0dfd2be44c052bf1e4b249437daa04d5a89e4d0c797105fd6d08144d794e322c` | PID2880, Status0, NOT_TERMINAL | Still RED, exit1 | `74085f9c16f58d594cf5aa3f74b17e070df1849dcb2c2a6f8e8beb919b1c1fb3` |
| Control after moving try | `0dfd2be44c052bf1e4b249437daa04d5a89e4d0c797105fd6d08144d794e322c` | PID9292, Status1, exit0 | PASS, exit0; no error, complete=true | `95c22a4777443e68aef1bc8b97871d393443cecb02277f3e400ba2ac3d2a6b0e` |

Primary files are respectively `vm-wiz37-red-primary-6aa34f0f1664.json`,
`vm-wiz37-greensettext-primary-74085f9c16f5.json` and
`vm-wiz37-control-primary-95c22a477744.json` under
`D:/AutoClip-Inno-Migration`. The attempted fix's filename contains `green`;
its measured result is still RED. Both failure cases retain exactly
`FIRST_PARTY_SETTEXT_FAILURE` and complete=false. Later terminal files do not
repair the immediate observation failure.

Original GUI handles/start/exit were retained before waiting:

| Case | GUI PID / original handle | Start UTC | Exit UTC / native code |
| --- | --- | --- | --- |
| Baseline | 5184 / 3404 | 2026-10-02T13:39:48.8118738Z | 2026-10-02T13:40:56.2615464Z / 0 |
| Attempted fix | 12180 / 3792 | 2026-10-02T13:42:28.6652583Z | 2026-10-02T13:43:37.9008359Z / 0 |
| Control | 10300 / 2780 | 2026-10-02T13:47:05.8571190Z | 2026-10-02T13:54:26.5147709Z / 0 |

Native GUI exit0 is expected for these inert observers and is not the behavior
assertion. All observed children retain their matching native64 ready and
terminal PID records. No kill, restart or observer delay was used.

The production try relocation did compile with approved exact ISCC, but the
native failure disproves its sufficiency. A read-only runtime/source trace
identified nested `try Animate; except end` in finally as the next concrete
suspect; root is qualifying a separate scalar trace diagnostic. Normal control
PASS contradicts a general broken Variant Status comparison. Source-build
cleanup has analogous nested handlers and requires its own behavioral proof.

An earlier keyboard transfer lost the command prefix and caused a PowerShell
parser error before execution. Root preserved that transport failure, verified
an idle prompt/full replacement command, then ran the actual baseline above.
The parser error is not TDD RED. The fresh VM's initial restored clock differed
from later observations; root did not set or backdate it.

Independent host command `python .github/tests/test_inno_build.py` passed all
11 checks against current inputs. It does not establish native process cleanup,
production installer readiness or generated-uninstaller cleanup.

## Root cause established and finalizer correction GREEN

The separate trace actually ran, using BOM-free spec
`wiz37-tracebomfree-spec-15431196.json` SHA256
`5524261aa61a4136d871757d59013807697cc03747177cfa5a0e51a26ba89659`.
The original agent spec is preserved: its UTF-8 BOM made the existing text-based
transport hash differ, and that first attempt refused before staging/launch.
It is a transport refusal, not behavioral RED or a signature-check bypass.

Actual trace primary `vm-wiz37-trace-primary-79e9976d6a4a.json`, SHA256
`79e9976d6a4a8b9782b576545250da01007a8e9f5ad4cc1bee81c22b08fa6e18`,
retains child9060 Status0/NOT_TERMINAL, original SetText exception and scalar
stage3. Thus finally and Animate ran, but control escaped at the nested handler's
end before stage4/Sleep. GUI5708/originalhandle3932 ran from
2026-10-02T14:01:31.3832893Z to 2026-10-02T14:02:24.0939035Z, exit0.
The [tagged Pascal Script runtime](https://github.com/jrsoftware/issrc/blob/is-7_1_0/Components/UniPs/Source/uPSRuntime.pas)
supports the inference: it retains the pending exception on entering finally,
while inner block completion redispatches that pending exception. Native trace
establishes the actual escape point in this fixture.

Root changed only finalizer exception handling: an inner except stores the
body error before the existing responsive cleanup finally runs; the error is
rethrown after the original child reaches terminal state. SetText/Show remain
inside the protected body. No kill, restart, observer wait, shared process wrapper
or production verification bypass was added. Current production source SHA256
is `8feddb2c308949dd64d06de15a30b9e2f9dc6f105727d5380f1fea470d7ab7cc`.
Contract-v1 now states immediate original-child observation and display-error
retention explicitly; its new SHA256 is
`78ced490df6c6fcad6de2e060605cb0a53ef887c91e450331308f0df47123277`.

Fresh generator `inno-final-process-test-r2.py` SHA256
`bbbc8bd6c86d66a4db765ece0a1792d18c78ecea318aa99b9ac27758e0bbec9d`
adds only the new local ProcessError declaration to the inert harness; exact
production tail mappings remain validated. Original generator/fixtures remain
unchanged. Packet under `vm-transfer/wiz37-captured/`, filename
`wiz37-process-fixture-packet-25283e0596d5438983c5aa6eb5993fd3.json`, SHA256
`df6680a1016851ae71ba6b1d454834afefaeeb64a83ce0236e32e186107a7de9`.

Compilation command:

```powershell
python D:/AutoClip-Inno-Migration/compile-wiz37-packet.py D:/AutoClip-Inno-Migration/vm-transfer/wiz37-captured/wiz37-process-fixture-packet-25283e0596d5438983c5aa6eb5993fd3.json df6680a1016851ae71ba6b1d454834afefaeeb64a83ce0236e32e186107a7de9
```

Exit0, all three actual ISCC exits0. Exact source/helper/packet/child/compiler
inputs remained read-locked through compilation; compiler closure agrees with
the preceding trace compilation. Every mapped tail line independently matches
production after the declared UI substitutions and original-child insertion.
Compilation records and logs are adjacent to each fresh fixture.

Root invoked the existing pinned native parent driver with each spec, pressed
Install/Finish only after inspecting foreground state, retained each primary by
CreateNew, and ran the unchanged verifier command given above:

| Case | Compiled EXE SHA256 / bytes | Spec SHA256 | Immediate child | Verification | Primary SHA256 |
| --- | --- | --- | --- | --- | --- |
| SetText | `5e5c873abf8e8ddeccae2cacd6f69a02bf467e722f1cea1102ee5a2fb92140b0` / 2845659 | `89ed515806620184d7e8477c469027a967ddc54fcbb4541f1418b0a291343ee4` | PID6172, Status1, exit0 | GREEN, exact original error; incomplete | `62a5162de1199961152796eb36cafd50e4c8b6e84a906cbb75f7da4f6ca48f48` |
| Show | `dda5d4902ab50863899e19da97afae7fd588ee144a38cbb1d517006e7d976fb2` / 2845648 | `6827a04dabefc174074fc562d796f59e1abb05c188c10c4984f297b6673b67f2` | PID4556, Status1, exit0 | GREEN, exact original error; incomplete | `de2bc6817381176f4e5baad5c932d5d457c1ebf38a31a9fe2c6b1b05f7106c3e` |
| Control | `96d78393083132662090cddc205b67681ee7ae87e352e184ce3fc7effe846edc` / 2845608 | `9d1058533f12f414f945dc076584009f4211431fb175a9dd8cb72dc36f6b667b` | PID5864, Status1, exit0 | GREEN, no error; complete=true | `804fe3070645092313791f5732fb0f2069eea108ee44e757f246170729575346` |

Primaries under `D:/AutoClip-Inno-Migration` are
`vm-wiz37-capturedsettext-primary-62a5162de119.json`,
`vm-wiz37-capturedshow-primary-de2bc6817381.json`, and
`vm-wiz37-capturedcontrol-primary-804fe3070645.json`.

| Case | GUI PID / original handle | Start UTC | Exit UTC / native code |
| --- | --- | --- | --- |
| SetText | 2072 / 3300 | 2026-10-02T14:06:34.3987313Z | 2026-10-02T14:07:37.6953951Z / 0 |
| Show | 9040 / 3308 | 2026-10-02T14:08:20.1635549Z | 2026-10-02T14:09:21.0299792Z / 0 |
| Control | 7688 / 3776 | 2026-10-02T14:09:52.5810296Z | 2026-10-02T14:11:16.8107946Z / 0 |

Root also ran `python D:/AutoClip-Inno-Migration/compile-current-inno-r2.py`:
actual syntax compile exit0, output
`D:/AutoClip-Inno-Migration/im-wiz-35-syntax-3r62jacx/AutoClip-Setup-v1.exe`,
3394098 bytes/SHA256
`64c8ed51f54dd02344c889dec7e15664cce2f5726c4cdfbbd309c6a3dd4c4d81`.
That full binary remains `SYNTAX_COMPILE_ONLY_UNEXECUTED`. `git diff --check`
passed with existing LF/CRLF warnings. No production candidate, vendor install,
actual generated uninstaller or release was executed. Native source-build
cleanup with analogous nested handlers remains a separate open finding; WIZ38
has prepared exact-tail fixtures. This finalizer GREEN does not close it.
