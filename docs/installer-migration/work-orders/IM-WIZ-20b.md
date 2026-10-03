# IM-WIZ-20b — bind the observation fixture to the guest context

Status: preparation complete; **Setup runtime RED/GREEN remains unperformed**. This additive report preserves IM-WIZ-20 and its frozen files/packet.

## Authorization and expected behavior

Parent authorized a new r2 builder/tests to address the host-only literal in IM-WIZ-20. Compile with the approved host ISCC, while embedding the fixed ordinary recipient guest TEMP parent. No compiler installation or compiler file transfer to the guest is needed. No production files, original builder/controller/tests/report, VM, server, vendor installers, or Setup runtime were changed/executed by this assignment.

New `-RuntimeParent` is required for compilation and accepts exactly `C:\Users\autocliplab\AppData\Local\Temp`. UNC, traversal, alternate streams, other user paths, and missing parents are rejected by exact allowlist equality without resolving the guest path on the host. The fresh physical host build directory and guest logical directory share the same unique `ac-observation-<guid>` basename. The packet records logical `root` and separate physical `build_root`. Arguments, bootstrap/helper/attempt command paths, fixed native guest PowerShell path, and compiled `FixtureRoot` literal all bind to the logical guest root. Input hashes continue to come from the physical frozen files.

Actual production observation extraction, UI fault seam, held first-party bootstrap, and unmodified supervisor are preserved. The controller remains frozen at `6b7be6337ae5d25f21774086140c465b1834c708f6b7fb5e548dd65a3ef02b7e`. Its guest preflight validates the actual protected recipient TEMP path and existing Setup ACLs before execution. Parent must create that fresh protected guest root and transfer every exact packet file before the distinct reviewed runtime action. This does not retry earlier rejected `/AUDIT` actions.

## Preparation RED → GREEN

The new test was written first and run against the preserved original packet:

```powershell
& D:/AutoClip-Inno-Migration/vm-transfer/inno-observation-fixture-r2.tests.ps1 -PacketPath C:/Users/beilo/AppData/Local/Temp/ac-observation-9045a1a99f87452b9c591e41e0d2fc74/packet.json
```

Exit 1, expected failure: `Compiled packet must bind the explicit guest logical root.` This proves the preparation defect, **not** the UI observation failure.

After the minimal r2 path change:

```powershell
& D:/AutoClip-Inno-Migration/vm-transfer/inno-observation-fixture-build-r2.ps1 -Compile -RuntimeParent 'C:\Users\autocliplab\AppData\Local\Temp'
& D:/AutoClip-Inno-Migration/vm-transfer/inno-observation-fixture-r2.tests.ps1 -PacketPath C:/Users/beilo/AppData/Local/Temp/ac-observation-184aacea88ba4dceb588ba72a70d3f89/packet.json
```

Compiler exit 0; focused test exit 0. Test checks actual generated JSON paths, actual compiled-source guest root/command/each helper hash, absence of the host root from compiled source, all physical packet file hashes, byte-faithful extracted observation body, and rejection of unsafe/unapproved runtime parents. No fixture Setup was run. Runtime observation RED and any production correction/GREEN remain pending parent execution/review.

## Frozen files and interface

New external files:

- `inno-observation-fixture-build-r2.ps1`: SHA `fe10dc0aa4c21ffddf6db1fad7724f90780de467eebef696c8cfed57b7bac517`.
- `inno-observation-fixture-r2.tests.ps1`: SHA `6fd67bcc1f3f32fb0ec90921c9ddd2eda4d06228d775dc3a617647d845391b07`.

Physical host packet root:
`C:\Users\beilo\AppData\Local\Temp\ac-observation-184aacea88ba4dceb588ba72a70d3f89`.

Logical guest packet root:
`C:\Users\autocliplab\AppData\Local\Temp\ac-observation-184aacea88ba4dceb588ba72a70d3f89`.

- `packet.json`: SHA `87fd2d24e2675ffde286004eb0a907ce7bfef6d925fbb8c68207c6091faf607a`.
- `fixture.iss`: SHA `5327cdee0ba1016b981659221788dbf106dbcddcac85b0c0d0da809deb0a420d`.
- `observation-fixture.exe`: SHA `9238c65882de0d20f36aa5bf92a9dae18146c1e1af6c4dd19b4c8540049558bb`.
- Actual supervisor: SHA `95a40597f6d196ad3ae23a6bc5a869899f5c0602fb89dcd2de11bf6277475ae0`.
- Extracted production Inno source: SHA `53d8c0a614884cfb8b2ed3ca334d43daf49ad2c91c835851f7e4c4c41495efd7`.

Transfer the nine named `packet.files` plus `packet.json`, verifying each hash. Preserve all filenames; the frozen controller readlocks every listed input, including compile logs/source. Transfer neither ISCC nor its installation directory. The compiled fixture runs only at the exact logical root.

Pending root-reviewed guest invocation uses the unchanged controller with `-RunFixture`, exact guest `-PacketPath ...\packet.json`, and `-PacketSha256 87fd2d24e2675ffde286004eb0a907ce7bfef6d925fbb8c68207c6091faf607a`. The agent did not execute this invocation. The fixture supplies no product installation, GPU, media, uninstall, wizard acceptance, or release qualification result.
