# IM-FF-07 - guest discovery alias correction

## Authorization and scope

Parent assigned read-only investigation of the preserved IM-FF-06 failure, a new r2 first-party diagnostic probe and fixture tests, and this report. Only these new files were changed. The original IM-FF-06 probe/tests/manifest, canonical downloader, archive helper, runtime-path helper, manifest and contracts remain unchanged. This worker performed no VM action, host vendor download/execution, guest operation, production promotion or release.

Requirement: persistent venv discovery must identify the exact retained manifest-pinned executables after parent PATH restoration. A Windows short/long alias for that same file is acceptable; another file with identical bytes is not. Diagnostic compact process evidence must retain the actual keyed native-operation values. No production public interface or contract changes were needed.

## Preserved primary evidence and cause

Independently inspected and hash checked parent-transported evidence:

| Host primary | SHA-256 |
| --- | --- |
| vm-ff06-failure-summary-6ebf1dbdc7d9.json | 6ebf1dbdc7d9f4af6ab87cac4bd5239cd4b17b476ecb4e5e5701d0b2265cf37d |
| vm-ff06-failure-primary-1e5ee0281d94.json | 1e5ee0281d94789753ecdc12b197807387c29c3290849bc005bdfc34730353fd |
| vm-ff06-discovery-logs-f1ceca7397a1.json | f1ceca7397a121ed30eb6e7698a80f9d7a43f863495ab650a8766f5563314f2d |

The 148,594-byte full primary records all twelve upstream native operations with integer exit 0 and no live process. Full extraction/inventory retained 45 files and 49 ZIP members. Before-registration discovery returned `[null,null]`; after-registration discovery returned long paths under `C:\Users\autocliplab\AppData\Local\Temp\acff guest 708fb158f46f`. The probe constructed expected paths under `C:\Users\AUTOCL~1\AppData\Local\Temp\acff guest 708fb158f46f` and compared the strings directly. The registration receipt and persistent .pth also identify the long managed directory; both discovery child stderr streams were empty. The full inventory's ffmpeg/ffprobe hashes match the frozen manifest pins.

This establishes why the original assertion failed. The original overall result remains FAILED. It does not establish a completed r2 qualification, synthetic media success, AutoClip application smoke or whole-wizard readiness. A separate compact projection defect used Select-Object on OrderedDictionary entries and emitted null process fields; the full primary retained them correctly.

## Minimal r2 changes

- Validate both discovered and expected paths as absolute regular files, reject unsafe syntax and every reparse ancestor before normalization.
- Normalize the existing paths with .NET Framework `System.IO.Path.GetFullPath`, then require ordinal case-insensitive equality. This expands the actual existing 8.3 alias in the supported Windows PowerShell environment.
- Select each executable's unique manifest pin, freshly hash the observed canonical file and require the pin. Record discovered, expected and canonical paths, size and hash in `persistent_discovery.verified_files`.
- Project compact native-operation fields by explicit dictionary keys, preserving label/PID/start UTC/integer exit/live status.

No hash-only acceptance, alternate managed directory, production bypass, test URL in production or helper change was introduced. Existing read locks, complete extraction/member checks and native timeout behavior are preserved.

## Behavioral RED and GREEN

The new companion uses AST-extracted actual probe functions/assignment/old discovery statement rather than source-presence assertions. Real disposable NTFS files have .exe names but contain first-party text and are never executed. `GetShortPathNameW` obtains a real distinct alias; absence of one fails the fixture rather than skipping qualification.

Before the corrections, the command below demonstrated the compact projection failure (`RED: actual compact receipt loses ordered-dictionary native process evidence`) and the actual old discovery assertion failure (`Persistent venv FFmpeg discovery differs`) with long observed paths and short expected paths to the same files. After the corrections the same focused command passed:

```powershell
& "$env:SystemRoot\System32\WindowsPowerShell\v1.0\powershell.exe" -NoProfile -File D:\AutoClip-Inno-Migration\vm-transfer\ffmpeg-guest-route-probe-r2.Tests.ps1
```

GREEN exit 0 covers:

- Parser and default read-only behavior with operational boundaries configured to throw.
- Diagnostic manifest differs from canonical only in the FFmpeg classification.
- Actual first-party native argument vector, integer exit 7 and live timeout observation followed by natural completion without kill/restart.
- Actual Python ZIP inventory rejects retained notice tampering and extra files.
- Actual keyed compact projection preserves PID 31415, fixed start UTC, exit 7 and live false.
- Real 8.3/long alias resolves to the same two freshly pinned canonical files.
- A foreign same-hash copy, changed retained bytes and a real junction ancestor are rejected.

Fixtures remove only their checked disposable TEMP directories; junction removal is nonrecursive. No vendor payload, FFmpeg executable, operational MSYS/VS root or canonical source was copied, mutated or executed by these tests.

## Frozen files and parent invocation

Under `D:\AutoClip-Inno-Migration\vm-transfer`:

| New file | SHA-256 |
| --- | --- |
| ffmpeg-guest-route-probe-r2.ps1 | 7b1c93ee80d9f80fe8ed00e354c9b76cbfd23bc5018784488be4533420081a9a |
| ffmpeg-guest-route-probe-r2.Tests.ps1 | f8c83b82a51308d180fd5225211af7e6e510f99984b71e2cb6df0bf1a4fcde83 |

Original probe hash remains `7699feeb3ff3336b9d81193259cf4605bf9539466efe7d02f573c382135081ee`; original tests remain `2af1a746e38544d8f10a696ac3a520680502b7ac3f3f1e0c8e3d1802e582509f`. The r2 retains the five frozen input pins and FFmpeg-only clone listed in IM-FF-06.

Parent inspection and guest execution only:

```powershell
powershell.exe -NoProfile -File .\ffmpeg-guest-route-probe-r2.ps1 -QualifyFfmpeg -SyntheticMedia -PostResult
```

The activation switch is mandatory; default is read-only. SyntheticMedia/PostResult are optional. This runs the full route in a fresh protected ordinary-user guest stage, with official vendor acquisition through the frozen downloader; it does not resume or alter the original failed stage. Full receipt/logs stay in the guest, compact summary uses the existing endpoint. Root owns transfer, VM execution and preservation of prior endpoint evidence.

## Limits

Host fixture verification qualifies the new first-party assertion/projection behavior only. The r2 has not been run in the real guest by this worker. .NET Framework Windows path normalization is the tested environment; no Unix or alternate PowerShell-runtime portability claim is made. Production remains BLOCKED and vendor rights, human playback, application integration and whole-wizard gates remain outside this preparation.
