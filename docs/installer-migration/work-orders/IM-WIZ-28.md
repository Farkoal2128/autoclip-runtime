# IM-WIZ-28 — refresh the actual-source observation fixture

Status: preparation complete; **actual runtime UI RED/GREEN unperformed**. Parent authorized only three new external r6 files and this additive report. Every older packet/file, production source, server, VM and live process remains untouched by the agent.

## Exact basis and bounded changes

Parent supplied updated actual production Inno source `5ac511edd0445b447f4dcdaf6d73178c07ff1200d1677a9db53529bb70f35a4f` and supervisor `3d16b5bbba61e8d9a3ee61769a6ed5e9077b324a6b285cc9aa751d7d7abe83cc`; both were independently rehashed before preparation. The Inno source selects native x64 Setup and its actual source-build command uses normal `AddQuotes(ExpandConstant('{sys}\WindowsPowerShell\v1.0\powershell.exe'))`. Parent reports redirected-stdin verification for the supervisor's reserved-input-loop correction; this agent did not execute that runtime test.

r6 builder refreshes only the frozen source/helper pins, exact native-expression extraction, and actual-source fixture labels. It extracts the complete current observation suffix and actual `PollBuildCancellation`. Existing readiness/prerequisite prefix seams, held first-party bootstrap, UI-refresh throw seam and PID receipt remain. Reversing the throw-call replacement and PID receipt recovers the original suffix byte-for-byte. Terminal-only diagnostics are retained outside that suffix; live supervisor pipes remain unread.

Parent reconciled official Inno7.1 documentation: native x64 Setup defaults to 64-bit installation mode, including the corresponding HKCU64 uninstall view. This fixture uses that default; it does not claim retained 32-bit installation mode. Source5ac is unchanged. Explicit mode wording in a future production guard candidate remains parent-owned and does not require another preparation variant here.

New controller-r6 changes **only** the expected helper pin from95a405 to3d16. Tests reverse that pin and require exact equality with the entire frozen old controller. Original handles/PID/start identity, early-return receipt, release signal, terminal observation, no automatic kill/retry, fresh-root refusal and read-only default therefore retain the existing control flow. Root owns runtime action and archive disposition.

## Preparation RED → GREEN

The new test ran first against preserved r5 and exited1 as expected: `Fresh packet must bind the updated actual source/supervisor basis.` This is a preparation-basis assertion, not runtime UI RED.

```powershell
& D:/AutoClip-Inno-Migration/vm-transfer/inno-observation-fixture-r6.tests.ps1 -PacketPath C:/Users/beilo/AppData/Local/Temp/ac-observation-36af445f43cd4a97acc3fdd6745cb627/packet.json
& D:/AutoClip-Inno-Migration/vm-transfer/inno-observation-fixture-build-r6.ps1 -Compile -RuntimeParent 'C:\Users\autocliplab\AppData\Local\Temp'
& D:/AutoClip-Inno-Migration/vm-transfer/inno-observation-fixture-r6.tests.ps1 -PacketPath C:/Users/beilo/AppData/Local/Temp/ac-observation-00ae15f144d94e5c9f6de514200748cc/packet.json
```

Results: expected preparation exit1, approved host ISCC syntax compilation exit0, final focused checks exit0. Checks validate current source/helper pins, actual compiled normal native expression/x64, host/guest path binding, every helper command pin and packet hash, exact suffix/Poll bodies, terminal diagnostics, and controller pin-only equality/default. No fixture EXE, VM, vendor installer, product installation, server mutation, process kill/release/retry or security disable was performed by the agent. Compilation is not behavioral RED.

## Frozen files

External files under `D:\AutoClip-Inno-Migration\vm-transfer`:

- `inno-observation-fixture-build-r6.ps1`: `3b6efeac46e965c24d5ef644efc1d6029c789c33fa96fb82d555025371b87b49`.
- `inno-observation-fixture-r6.tests.ps1`: `a129ed54b0599494572de93b26112002942e48e5e832cef87f9ce5ca585514c6`.
- `inno-observation-fixture-controller-r6.ps1`: `cbb80b60e18593cac269cf8e4b87b6440450c5600d6e299b40a8dc4dd35f4795`.

Host physical root: `C:\Users\beilo\AppData\Local\Temp\ac-observation-00ae15f144d94e5c9f6de514200748cc`.

Guest logical root: `C:\Users\autocliplab\AppData\Local\Temp\ac-observation-00ae15f144d94e5c9f6de514200748cc`.

- `packet.json`: `c3f7434fc22f60e2584848961bbd3664cee98a2c29d66786430a585759497f74`.
- `fixture.iss`: `f91c4a86f713677ac5eff6ec6af2f1801363cd368a9ada715786a40c10aa3584`.
- `observation-fixture.exe`: `5a8844fcd768693a8e11f1b2172de6a06a8331c5b77bebabe5fb869f1ae3053f`.
- Actual copied supervisor: `3d16b5bbba61e8d9a3ee61769a6ed5e9077b324a6b285cc9aa751d7d7abe83cc`.

Transfer all nine exact `packet.files` plus `packet.json` to the fresh protected guest root, preserving names/hashes. Transfer the new controller separately with its exact hash; do not use old controller6b7, which intentionally rejects the new helper pin. No compiler files are transferred. Root executes the new readlocked controller only after reviewing the distinct runtime action with explicit `-RunFixture`, exact guest `-PacketPath`, and packet SHA above. Controller defaults remain no-operation.

Qualification still requires actual native supervisor/worker startup, held-worker readiness, injected UI fault, early-return evidence and original-process terminal receipts. No guard fix or production observation result is claimed here. This packet supplies no product, GPU/media/uninstall, wizard acceptance or release qualification result.
