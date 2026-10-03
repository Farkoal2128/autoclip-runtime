# IM-WIZ-22 — native-path fixture revision and terminal startup diagnostics

Status: fixture preparation complete; **Setup runtime RED/GREEN unperformed**. Parent authorized only new r3 builder/tests and this report. Existing fixture files, failed packet, actual live processes, controller, supervisor and production sources remain unchanged.

## Requirement and minimal change

IM-WIZ-21's primary established that the r2 literal System32 command launched actual SysWOW64 PowerShell, differing from production's native launch expression. r3 extracts that exact expression unambiguously from pinned production `RunSourceBuild` and composes it with the existing guest-fixed argument suffix. No native-path rule is reimplemented. The actual production observation suffix is unchanged from r2, including its original `try/while/finally` control flow, existing UI fault seam and PID instrumentation.

Fixture-only startup diagnostics run after `RunSourceBuild` returns/raises to its outer fixture handler. The fixture preparation declarations retain the actual WScript Process reference globally instead of locally; no observation-suffix statement changes. A separate diagnostics procedure first requires the existing Started PID receipt, then checks actual `Process.Status`. Only terminal status permits reading both `StdOut.ReadAll` and `StdErr.ReadAll` into preserved files. Live status records `LIVE_UNREAD` and reads neither pipe. Diagnostic errors are preserved separately and cannot replace the original observation outcome. This is test instrumentation only; no shipping hook or production correction was introduced.

## Preparation evidence

The new focused test was written before changing the r3 builder. Its first invocation had a test syntax error (not RED); that test syntax was corrected before the meaningful run. Against the preserved r2 packet, the corrected test exited1 with expected failure:

`Compiled fixture must compose the exact production native executable expression with its argument suffix.`

This demonstrates the preparation/command-composition defect, **not the UI observation behavior**. After the minimal builder revision, approved ISCC exits0 and the test exits0. The focused test checks the actual generated/compiled source expression, its logical guest paths and each physical input hash reference, packet file hashes, actual extracted observation body and reversible byte equality, and compilation of the terminal-only diagnostics. Diagnostics guard inspection is static; their pipe behavior has not been exercised at runtime.

Exact commands:

```powershell
& D:/AutoClip-Inno-Migration/vm-transfer/inno-observation-fixture-r3.tests.ps1 -PacketPath C:/Users/beilo/AppData/Local/Temp/ac-observation-184aacea88ba4dceb588ba72a70d3f89/packet.json
& D:/AutoClip-Inno-Migration/vm-transfer/inno-observation-fixture-build-r3.ps1 -Compile -RuntimeParent 'C:\Users\autocliplab\AppData\Local\Temp'
& D:/AutoClip-Inno-Migration/vm-transfer/inno-observation-fixture-r3.tests.ps1 -PacketPath C:/Users/beilo/AppData/Local/Temp/ac-observation-6974b200d9fe4c939a006bc157d13e22/packet.json
```

Results: expected preparation exit1, compiler exit0, final focused test exit0. No Setup/VM/vendor/admin action, live process disposition, cleanup, release signal or server mutation was performed by the agent. Parent's later read-only waiting-thread primary does not establish the underlying SysWOW64 startup cause; this correction repairs a confirmed harness mismatch without making that causal claim.

## Exact frozen packet and interface

- New builder `inno-observation-fixture-build-r3.ps1`: SHA `caf7e6de085f6b6f2f84d5a328cbaf91f79eb885e8b7c38caa55fd27e0545334`.
- New test `inno-observation-fixture-r3.tests.ps1`: SHA `bbe93eb485d59b6a0a237ff1802d294fcde1c0cb01e00b48b0e492f8f7e8579e`.
- Unchanged controller: SHA `6b7be6337ae5d25f21774086140c465b1834c708f6b7fb5e548dd65a3ef02b7e`.
- Unchanged actual supervisor: SHA `95a40597f6d196ad3ae23a6bc5a869899f5c0602fb89dcd2de11bf6277475ae0`.
- Extracted production Inno source: SHA `53d8c0a614884cfb8b2ed3ca334d43daf49ad2c91c835851f7e4c4c41495efd7`.
- Approved host ISCC: SHA `d06ebd38f38e3cee60a3c50cc45bd449d77e0bc6a5cabc607ea9886808e4de1a`.

Physical host root: `C:\Users\beilo\AppData\Local\Temp\ac-observation-6974b200d9fe4c939a006bc157d13e22`.

Logical guest root: `C:\Users\autocliplab\AppData\Local\Temp\ac-observation-6974b200d9fe4c939a006bc157d13e22`.

- `packet.json`: SHA `86958c490659e368bee4bbcf5a2257675b82012a2805dc5cc8dc8f040be6e2b9`.
- `fixture.iss`: SHA `6ee0d457761e70e0b0453aa43705aff0ab6477f8214f39b0767fb825027bd6d1`.
- `observation-fixture.exe`: SHA `5318e6e962fb63b13ed63c025f7f2603a26d6a8e05051c6137fb7c7c98862801`.

Transfer all nine `packet.files` plus `packet.json` byte-for-byte to a fresh protected logical guest root; preserve filenames and verify all hashes. Use the unchanged exact controller with that guest `-PacketPath` and packet pin after root reviews the distinct runtime action. No compiler directory/file transfer is needed. Old r2 stage/live process preservation and disposition remain separate.

The later runtime must independently record the actual native supervisor executable, require held-worker readiness and the UI fault seam, and observe the original processes to terminal state. A new startup failure is preserved as such. This packet does not claim behavioral RED, installed application qualification, GPU/media behavior, uninstall, wizard acceptance or release readiness.
