# IM-WIZ-24 — native x64 Setup fixture preparation

Status: preparation complete; **Setup runtime RED/GREEN unperformed**. Parent authorized only a new r4 external builder/tests/report. No production edits, VM/Setup execution, vendor action, security disable, process kill/release/retry, or server mutation occurred.

The preserved r3 startup primary `vm-wiz22-startup-primary-5d98effeecdb.json` was independently rehashed as `5d98effeecdb66207fb7d722566fff3cf13d3fec7f9e361287721af6598ab96e`. Its terminal-only pipe capture contains 151 bytes of stderr: shell initialization failed in `System.Net.ServicePointManager`; `supervisor-pipes-state.txt` records `TERMINAL_READ`. Worker readiness/UI fault were not reached, so this is not behavioral RED for the intended observation scenario. The original r2 live stall remains preserved under parent ownership.

## Authorized change and verification

r4 builder differs from frozen r3 by **one line only**: `SetupArchitecture=x64` under `[Setup]`. Its exact production native executable expression, guest path handling, observed procedure suffix, actual supervisor, held bootstrap, terminal-only diagnostics, and controller remain unchanged. A focused test removes that directive and requires byte-for-byte equality with r3. It also checks the actual compiled source has exactly one x64 directive, then reuses the existing r3 composition/pin/extraction checks. The proposed architecture change has not been proven to resolve startup at runtime.

Preparation RED was demonstrated before the builder change:

```powershell
& D:/AutoClip-Inno-Migration/vm-transfer/inno-observation-fixture-r4.tests.ps1 -PacketPath C:/Users/beilo/AppData/Local/Temp/ac-observation-6974b200d9fe4c939a006bc157d13e22/packet.json
```

Exit1, expected `Compiled fixture must select exactly one native x64 Setup architecture.` This is a preparation assertion, not runtime observation RED.

GREEN/compile commands:

```powershell
& D:/AutoClip-Inno-Migration/vm-transfer/inno-observation-fixture-build-r4.ps1 -Compile -RuntimeParent 'C:\Users\autocliplab\AppData\Local\Temp'
& D:/AutoClip-Inno-Migration/vm-transfer/inno-observation-fixture-r4.tests.ps1 -PacketPath C:/Users/beilo/AppData/Local/Temp/ac-observation-c18a1c9bac334730a770cd4df39e650a/packet.json
```

Approved host ISCC syntax compilation exit0; focused checks exit0. No EXE executed by the agent.

## Frozen packet

- Builder `inno-observation-fixture-build-r4.ps1`: `3c010537407fc06a6c054c620bca5f153634c0f0f1abcf1534b1442f8f7fe19c`.
- Tests `inno-observation-fixture-r4.tests.ps1`: `5f4b7a59317c23c7cfc502d98d3c3c0a5873e73bf266a233b7cee43d43d95266`.
- Reused r3 tests: `bbe93eb485d59b6a0a237ff1802d294fcde1c0cb01e00b48b0e492f8f7e8579e`.
- Unchanged controller: `6b7be6337ae5d25f21774086140c465b1834c708f6b7fb5e548dd65a3ef02b7e`.
- Unchanged actual supervisor: `95a40597f6d196ad3ae23a6bc5a869899f5c0602fb89dcd2de11bf6277475ae0`.
- Pinned production Inno source: `53d8c0a614884cfb8b2ed3ca334d43daf49ad2c91c835851f7e4c4c41495efd7`.

Host physical root: `C:\Users\beilo\AppData\Local\Temp\ac-observation-c18a1c9bac334730a770cd4df39e650a`.

Guest logical root: `C:\Users\autocliplab\AppData\Local\Temp\ac-observation-c18a1c9bac334730a770cd4df39e650a`.

- `packet.json`: `19a7cda015af45209d1eb767c92c2cd3a256a09a60334be02d4285be1b16ff9a`.
- `fixture.iss`: `952bf7b59ce31d242f088a6442423c5851b0fd8ad12e971dfa88ba13b426b3a2`.
- `observation-fixture.exe`: `f2a9adeb9a4c5c58c327ef1767a553ef01fecf736ff0def881db91f9f8961962`.

Parent transfers the nine exact `packet.files` plus `packet.json` into the fresh protected guest root, preserving filenames/hashes. No compiler file transfer is required. The unchanged controller consumes exact guest `-PacketPath` with the packet pin after root reviews the distinct runtime action. Actual native startup, held-worker readiness, fault observation and original-process terminal state remain required before any production bug fix or behavior qualification. No product, GPU, media, uninstall, wizard acceptance or release result is established.
