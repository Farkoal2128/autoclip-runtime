# IM-VS-27 — built-in process/image tracing preparation

Read-only investigation and documentation preparation, 2026-10-01. Own this new report only. No VM operation, trace start/stop, dependency acquisition, vendor execution, production edit or previous diagnostic modification was performed by this author. Root owns the live UI fixture and subsequent cold-engine experiment; wait for that independent fixture to be terminal before qualifying an engine trace. Canonical engine/release gates remain open.

This report creates no new contract, approval flow or perpetual tracing requirement. ETW is supporting evidence for root's bounded experiment. The actual goal remains exact resolved bootstrap/OPC/engine/payload identities with no unknown downloaded execution, established through pinned authentication, the independent installed-tree inventory and externally disconnected NIC. Limitations below qualify what a trace can prove; root reconciles them with that existing goal rather than requiring an unrestricted tracing infrastructure.

## Recommended route

Use the existing native `C:\Windows\System32\wpr.exe` command-line recorder, its built-in GeneralProfile in **file mode**, and native `C:\Windows\System32\tracerpt.exe` to decode the saved ETL. Microsoft documents that CLI WPR ships with Windows; WPA/WPRUI/Xperf need the separate toolkit and are unnecessary for this bounded capture. Actual existence, version, profile coverage and decoding on this particular cold guest are **not observed by this author**. [Microsoft WPR overview](https://learn.microsoft.com/en-us/troubleshoot/windows-server/support-tools/support-tools-xperf-wpa-wpr).

GeneralProfile must be inspected on the actual guest, rather than assuming its name means it covers required events. ProcessThread and Loader are the required kernel categories: process/thread lifecycle and image load/unload. Exported profile/collector information and a first-party short-child qualification must prove that those events are enabled and decoded. Light mode minimizes unrelated activity; use it only if its actual profile contains both required categories. Microsoft documents built-in profile variants, exports, file-mode temporary locations, status and stop; file mode avoids the circular in-memory window. [WPR commands](https://learn.microsoft.com/en-us/windows-hardware/test/wpt/wpr-command-line-options), [Microsoft WPR start/stop explanation](https://devblogs.microsoft.com/performance-diagnostics/wpr-start-and-stop-commands/).

## Root-only discovery and qualification

The commands below are a proposed procedure, **not execution evidence**. Use a trusted native admin shell with fixed system PATH/PSModulePath and literal system executables, NIC still OFF, and a new root-approved Administrators-owned protected trace directory (SYSTEM/admin writes; recipient ReadExecute). No supplied per-user path may grant elevated-code authority. `<trace-root>` is a root-verified concrete fresh ProgramData directory; placeholders must be resolved before execution. Capture complete stdout/stderr, return codes, UTC/QPC timing, file lengths/hashes and executable version/signature metadata.

First, read-only discovery:

```powershell
& 'C:\Windows\System32\wpr.exe' -help start
& 'C:\Windows\System32\wpr.exe' -help status
& 'C:\Windows\System32\wpr.exe' -help stop
& 'C:\Windows\System32\wpr.exe' -profiles
& 'C:\Windows\System32\wpr.exe' -status
& 'C:\Windows\System32\logman.exe' query -ets
& 'C:\Windows\System32\logman.exe' query providers 'Windows Kernel Trace'
& 'C:\Windows\System32\tracerpt.exe' -?
```

Existing active tracing is a conflict to reconcile with root, not permission to `-cancel`, replace or stop another recording. Discovery failures or missing native binaries stop this route; no new ADK/Sysinternals download is authorized by this report.

Then export the chosen built-in variant, a first-party metadata write performed only by root:

```powershell
& 'C:\Windows\System32\wpr.exe' -exportprofile GeneralProfile.Light '<trace-root>\GeneralProfileLightFile.wprp' -filemode
```

Require export success, hash the full profile and inspect its kernel provider keywords for ProcessThread **and** Loader; ensure file mode and record buffer settings. If absent, do not start that profile or silently substitute another one. Root can separately review the built-in verbose variant after exporting it. No custom WPR profile is needed unless actual discovery contradicts this route.

Before any vendor operation, qualify that exact profile in a separate short first-party-only trace. Root's fixture should launch several trusted system `cmd.exe /d /c exit 0` children with unique recorded parent/native handles, including at least one child which exits well under500ms, and record exact parent PID, child PIDs, start/exit/exit0 on the held native handles. This is a proposed fixture, not code added/executed here. Decode it and require each expected process start/end pair, parent association, command line and main executable image load; require the fixture's normal DLL loads to appear. This proves the particular recorder/decoder can observe children missed by polling; it does not establish future zero loss. Preserve the full qualification ETL/output separately. Do not mix it with the vendor experiment or accept a process-count-only summary.

## Root-only actual capture

After qualification, use a distinct protected capture root/temp subdirectory and an absent output ETL, with disk space checked. Microsoft documents `-recordtempto` and final stop/merge; use the actually supported native syntax and preserve every failure. This procedure assumes the inspected Light variant passed qualification:

```powershell
& 'C:\Windows\System32\wpr.exe' -start GeneralProfile.Light -filemode -recordtempto '<trace-root>\wpr-temp'
& 'C:\Windows\System32\wpr.exe' -status profiles
& 'C:\Windows\System32\wpr.exe' -status collectors -details
# Root verifies required kernel keywords, active file recording and initial zero loss.
# Root alone then runs the separately reviewed frozen IM26 inline command.
# Cover the root-chosen observation interval; record any relevant processes still alive.
& 'C:\Windows\System32\wpr.exe' -status collectors -details
& 'C:\Windows\System32\wpr.exe' -stop '<trace-root>\engine.etl' 'IM26 exact offline engine-only experiment' -skipPdbGen
```

Every command return code must be0, and full status/stop diagnostics preserved. `-skipPdbGen` avoids generating managed PDBs during merge; no symbol-server download, heap tracing, boot/autologger, registry policy, force-stop, reboot or memory-mode/circular capture is proposed. Stop/merge itself occurs after the vendor observation interval, using the same trace operation; it must not be mistaken for a vendor descendant. If collection fails during a live vendor operation, root still waits existing native handles and preserves the failed trace; no vendor timeout kill/retry or reconnect follows.

Parent exit alone does not prove every helper exited. Keep the system-wide session through a bounded root-chosen observation interval and record relevant live identities at stop, including service/broker-mediated activity. A legitimate long-lived service does not require perpetual recording; identify its bytes and lifetime, and preserve any unresolved attribution. Do not infer child termination from silence or require every Windows service to stop.

## Built-in decode and explicit completeness checks

```powershell
& 'C:\Windows\System32\tracerpt.exe' '<trace-root>\engine.etl' -o '<trace-root>\events.xml' -of XML -summary '<trace-root>\summary.txt' -report '<trace-root>\report.xml'
```

Microsoft documents ETL/XML/summary/report output and `-lr` as a less-restrictive best-effort mode. The initial decode should omit `-lr`; missing schema/payload must remain a decoding gap, rather than being relabeled complete by best effort. If needed for investigation, a separate `-lr` output may be retained alongside the failed strict output, without closing completeness. No dependency or custom ETL parser is introduced. [Native tracerpt](https://learn.microsoft.com/en-us/windows-server/administration/windows-commands/tracerpt).

Completeness is conditional on **all** of the following actual evidence:

1. Recorder started before the bootstrap start; trace includes start/end coverage beyond the last relevant process/image activity and a successful finalized stop. Preserve active provider/profile/buffer configuration, actual session identities and trace clocks, not only the command text.
2. Initial and final per-collector WPR status reports zero dropped/lost events and no loss/error warning. WPR documents collector loss reporting. Status captured immediately before stop alone cannot prove there were no subsequent losses.
3. Inspect **final ETL** header/loss information in the native decoded output: EventsLost=0, BuffersLost=0, valid final EndTime, expected sessions and no truncation. If multiple collectors contribute, require their individual loss accounting; a summary/global header must not hide a contributing logger. If this WPR/tracerpt version does not expose final per-source loss fields unambiguously, retain `loss_check=UNPROVEN`; root must resolve that gap before claiming complete capture. Do not invent zero values for absent fields. Microsoft defines these loss fields and notes EndTime=0 may mean an unfinalized log. [ETL header](https://learn.microsoft.com/en-us/windows/win32/api/evntrace/ns-evntrace-trace_logfile_header).
4. Preserve full ETL and decoded XML byte hashes/lengths, every native decoder warning/exit code, and actual event counts by provider/type. Required process/image payloads must decode; no silent event filtering, schema skipping, truncated export or process sampling substitutes for them.
5. Join process starts/ends using the process unique key when present and PID **with its lifetime**, not a global bare-PID map. Parent PID needs the parent's identity/lifetime at child creation. Process lifecycle data can include parent, command line and exit status. Report missing/ambiguous lifecycle pairs; do not treat rundown events as new starts or assume PID reuse is ancestry. [Process event schema](https://learn.microsoft.com/en-us/windows/win32/etw/process-v2-typegroup1).
6. Join image events using the payload's target ProcessId/lifetime, not blindly the logging thread/header PID. Preserve Load/Unload and DCStart/DCEnd rundown separately; an initial/final rundown is a snapshot, not proof of every intervening short load. Microsoft documents native image path/base/size/checksum/timestamp fields and loaded-image rundown. [Image events](https://learn.microsoft.com/en-us/windows/win32/etw/image-load).

Any loss, unfinalized trace, missing required provider, decoder gap or ambiguous operation lifetime prevents claiming complete process/image capture; retain the actual limits as supporting evidence. ETW zero-loss accounting covers the enabled categories and interval, not every possible code execution mechanism or every provider that was never enabled. This procedure can establish process/native-image event coverage when those checks pass; it cannot by itself prove full executable-byte provenance or replace exact OPC/installed-tree pins.

## Frozen IM26 review: child handles and code attribution

Read-only hash recheck of `vs-admin-engine-probe.ps1` returned unchanged SHA `b869faec13fd8e71f608418d08aa8a59f2144da20ef8d29e03f5c1fb8394309c`.

Inspected lines107–121 retain only the Start-Process bootstrap object/handle. Descendants are integer PIDs learned from periodic CIM snapshots; module lists are sampled. There are **no retained child process handles, independently captured child exit codes or guaranteed observation of quick children**. A quick child or intermediate parent can disappear before a sample; a reused known PID can cause unrelated process attribution. `WaitForExit` waits the exact parent and `--wait` asks vendor behavior to wait, but neither is independent proof of every child terminal state. The script's false completeness fields are correct; no edit to this frozen snapshot was made.

ETW supplies lifecycle evidence for exited quick children without reopening their PIDs. It does not retroactively supply native handles or allow safely opening a reused PID. For processes still alive, root may capture a native handle while independently validating the live start identity; do not claim root can retain handles for children already exited. If an acceptance boundary explicitly requires every child handle rather than complete lifecycle evidence, this unchanged probe does not satisfy it; any implementation revision needs a separate bounded work order/tests/hash/review.

System-wide recording helps reveal COM/SCM/MSI/broker launches outside simple bootstrap ancestry. Temporal proximity alone cannot assign an existing system service or unrelated process to this operation; preserve relevant commands, lifetime/module changes and vendor/service evidence. Attribute normal Windows DLLs to normal installed-system signatures/catalog provenance separately. Native image events contain paths and PE metadata, **not cryptographic SHA-256 of executed bytes**. Paths under Windows are not automatic trust, especially Temp. Same-path replacement/deletion before inspection remains a byte-provenance gap. Scripts, managed/JIT code, JavaScript/data loaded by Electron and memory-only execution are not all represented by native image events; authenticated868 OPC/installed-tree pins and required code/data evidence remain separate. Unknown vendor closure blocks the next transition.

## Full vendor log collection: actual locations over guesses

The IM26 diagnostic redirects stdout/stderr to protected stage files, sets inherited TEMP/TMP to its protected `tmp` and inventories files there after return. It does **not** collect all external log locations, export Windows event logs or guarantee logs are closed; `vendor_logs_complete=false` remains necessary.

Microsoft's setup troubleshooting documentation identifies its log collection tool and `%TEMP%\vslogs.zip`, and Microsoft staff identify native `dd_bootstrapper_*`, `dd_installer_*`, `dd_setup_*` logs in Temp. The exact set of names/locations for this cold operation is not guaranteed by that guidance. Do not download/execute Collect.exe as part of this bounded procedure. [Setup troubleshooting](https://learn.microsoft.com/en-us/visualstudio/install/troubleshooting-installation-issues), [Microsoft setup-log guidance](https://learn.microsoft.com/en-us/answers/questions/1047812/visual-studio-2022-download-stuck-at-0-bytes).

Root's before/after read-only inventories and actual command/log references should cover:

- Full protected engine stage/temp, stdout/stderr, receipt and any extraction/decompression log (`dd_*`, including `.txt`, not only `.log`).
- Recipient native temp `C:\Users\autocliplab\AppData\Local\Temp` and any actual other token/temp location revealed by native process/service evidence.
- `C:\Windows\Temp`; SYSTEM and service-profile temp locations **when that execution context is observed**. Do not assume the initiating shell's TEMP controls independently spawned services.
- `C:\ProgramData\Microsoft\VisualStudio\Packages`, installed engine/operation metadata and additional paths explicitly referenced by native commands or collected logs. Presence is not evidence that each directory necessarily contains logs.
- Additional Windows event logs only when the actual operation/logs reference them; this engine-only scope does not require a broad MSI/product event audit.

Record before/after file names, length/hash, UTC/timestamps and operation linkage; do not rely solely on LastWriteTime or file-prefix heuristics. Follow actual `--log`/`-Log` and nested log references, preserve success/failure child logs, and record missing/inaccessible/deleted/actively written logs as gaps. Reject reparse paths; copy closed readable files under held readlocks to new protected evidence files with exact byte/hash checks and no overwrite. Preserve complete raw bytes, not a tail or JSON-embedded excerpt; chunked transport needs chunk ordering and end-to-end length/hash verification. Process/image-only ETW does not exhaustively enumerate every log file write. Therefore a candidate-root search is a collection plan, **not proof of full log coverage**; unresolved references or unknown writer contexts retain the manual log gate.

## Disposition

Concrete next step: root completes the UI fixture, performs native discovery/export and a short first-party-only trace to establish the built-in observer's actual coverage/decoding. No vendor action is needed for that check. Root then decides the bounded engine experiment from the exact pins/protection/current authentication/NIC-off evidence, retaining trace limits accurately. Start/stop/decode the built-in recorder around that experiment if the discovered route works, then compare the resolved engine to authenticated868 pins and reconcile actual logs/observed unknown identities. No broad tracing implementation, new approval gate or actual completeness result is proposed here.

Verification performed here: primary Microsoft documentation review; `Get-FileHash` of unchanged IM26; `rg` source inspection of process/handle/log code. No RED/GREEN, guest discovery, trace capture, decoder qualification or runtime check was performed. No contracts, production, diagnostic script or test file changed. This report returns to root for bounded operational review.
