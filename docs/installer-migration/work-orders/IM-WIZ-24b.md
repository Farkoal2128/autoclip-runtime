# IM-WIZ-24b — proposed normal-native-path control

Status: additive fixture preparation complete; **runtime RED/GREEN unperformed**. Parent explicitly authorized a separate proposed correction control after freezing IM-WIZ-24's x64-only packet. No previous files/packet, production code, VM, server, live processes or vendor component was modified/executed.

## Proposed control

r5 retains `SetupArchitecture=x64`, but composes its startup executable with `AddQuotes(ExpandConstant('{sys}\WindowsPowerShell\v1.0\powershell.exe'))`. This intentionally differs from current production's `ApplyPathRedirRulesForCurrentProcess` expression. It is labeled `PROPOSED_NORMAL_NATIVE_PATH` in packet metadata and as a proposed control in the fixture AppName. It is a test candidate, not verified production behavior or a shipping architecture configuration.

The actual observation suffix, UI failure seam, held first-party bootstrap, supervisor95a405, terminal-only diagnostics and controller6b7be633 remain unchanged. Guest paths/pins and protected-fresh-root transfer rules are the same. No security feature is disabled. The original live r2 failure and terminal r3 failure remain preserved under root ownership. The underlying startup failure and whether this normal native path resolves it remain runtime questions.

## Preparation verification

New r5 tests were written first and run against frozen r4. Expected exit1: `Proposed control must compose the normal native path without a Sysnative/extended-path transformation.` This is preparation RED for the newly authorized control, not evidence that current production observation failed.

Exact commands:

```powershell
& D:/AutoClip-Inno-Migration/vm-transfer/inno-observation-fixture-r5.tests.ps1 -PacketPath C:/Users/beilo/AppData/Local/Temp/ac-observation-c18a1c9bac334730a770cd4df39e650a/packet.json
& D:/AutoClip-Inno-Migration/vm-transfer/inno-observation-fixture-build-r5.ps1 -Compile -RuntimeParent 'C:\Users\autocliplab\AppData\Local\Temp'
& D:/AutoClip-Inno-Migration/vm-transfer/inno-observation-fixture-r5.tests.ps1 -PacketPath C:/Users/beilo/AppData/Local/Temp/ac-observation-36af445f43cd4a97acc3fdd6745cb627/packet.json
```

Results: expected preparation exit1, approved host ISCC exit0, focused checks exit0. Checks inspect actual compiled source normal-path composition, absence of the prior redirection/Sysnative producer, x64 directive and proposed label, generated guest arguments, every helper path/hash reference, physical packet hashes, and byte-faithful observation/diagnostic bodies. Native process startup and UI fault were not executed. No compile is described as behavioral RED/GREEN.

## Frozen handoff

- New builder `inno-observation-fixture-build-r5.ps1`: `3724d8a88e5713945a193bed5fe2a3575ee6fadf724dc29751eeea8ec183d5d0`.
- New tests `inno-observation-fixture-r5.tests.ps1`: `e59d53158311c494c728cb1b33096959b81a72d3a9d1cd4591e5beb22cb2fd05`.
- Unchanged controller: `6b7be6337ae5d25f21774086140c465b1834c708f6b7fb5e548dd65a3ef02b7e`.
- Unchanged supervisor: `95a40597f6d196ad3ae23a6bc5a869899f5c0602fb89dcd2de11bf6277475ae0`.

Physical host root: `C:\Users\beilo\AppData\Local\Temp\ac-observation-36af445f43cd4a97acc3fdd6745cb627`.

Logical guest root: `C:\Users\autocliplab\AppData\Local\Temp\ac-observation-36af445f43cd4a97acc3fdd6745cb627`.

- `packet.json`: `9b3dca03267299dc960c9208448e801842a0f6df643afd706ced7c39e80399cc`.
- `fixture.iss`: `0920b9092d2e2686eb882d5c0dbdbc0639cd964956aa08a485ee66e3e5e7820d`.
- `observation-fixture.exe`: `283b7e7815d7e9ae7dfc28a1443121d26862ad8d80b6c3927bf836e2a8d6fd7d`.

Parent transfers all nine exact packet files plus packet.json into its fresh protected logical root; no compiler file transfer. Parent reviews the distinct runtime action and executes the unchanged controller only with that exact packet pin. Qualification requires actual native startup, held-worker readiness, injected UI fault, original-process identity and terminal evidence. Any later production launch-path change remains parent-owned and depends on that evidence. No product installation, GPU/media/uninstall, wizard acceptance or release result is established.
