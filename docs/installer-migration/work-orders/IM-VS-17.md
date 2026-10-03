# IM-VS-17 — independent OPC-to-installed-engine diagnostic

## Authorized scope and preserved failure

Parent authorized only new `D:/AutoClip-Inno-Migration/vm-transfer/vs-opc-installed-map-probe.ps1`, its adjacent fixture tests, and this report. No previous diagnostic, evidence, canonical contract/manifest, vendor file, installed engine, payload or VM was changed. No acquisition, vendor execution, copy, certificate import, source reconstruction or production promotion occurred. No memory used; actual model/inference telemetry remains not exposed.

The original IM-VS-16 source gate remains authoritative for its larger scope and is unchanged. Its preserved primary guest receipt is `D:/AutoClip-Inno-Migration/vm-vs-engine-map-source-failure-primary-f4abe6645aa9.json`, SHA256 `f4abe6645aa9fec54d8b8ad30ca64c838bceb86761d25ca4fecaa4318e87f327`. This author read the actual receipt: status `FAILED`, phase `source_inventory`, actual 41 of expected 409 files, 368 missing, zero extra, zero changed. Its actual inventory records the exact expected Catalog, ChannelManifest, OPC and bootstrap bytes still present. The cause of disappearance is **not established**. Nothing was automatically redownloaded or repaired.

The new diagnostic tests only the surviving pinned OPC against the current installed engine. It explicitly sets `source_inventory_verified=false` and `original_layout_gate=NOT_PERFORMED` in plan, receipt and summary. Even a positive installed match does not qualify the 409-file product source, seed creation, acquisition or layout execution.

## Interface and exact inputs

```powershell
# Host/guest default; no mutation, mapping, post or vendor execution:
powershell.exe -NoProfile -File .\vs-opc-installed-map-probe.ps1

# Parent-owned ordinary guest mapping; local protected receipt:
powershell.exe -NoProfile -ExecutionPolicy Bypass -File .\vs-opc-installed-map-probe.ps1 -MapInstalledEngine

# Optional compact result only after parent enables networking:
powershell.exe -NoProfile -ExecutionPolicy Bypass -File .\vs-opc-installed-map-probe.ps1 -MapInstalledEngine -PostResult
```

Explicit mapping requires ordinary `autocliplab`, native64 PowerShell/OS and an unelevated token before creating its output. The fixed guest input is `C:/Users/AUTOCL~1/AppData/Local/Temp/acvs-fd9e3fbd6cec/layout/vs_installer.opc`:

- OPC: 50,363,030 bytes / SHA256 `62f68d0d6e2adce5cd65f549cbda234358c1cbda442af4de1c3f7ae43fb8b5a6`.
- Raw internal manifest: SHA256 `1ed363d4207dfbb0f0a813558349ce53719f39a0d0fb6710171257bad01de356`.
- Complete Contents tree: 868 regular files / 131,469,618 uncompressed bytes. Every raw member hash must equal the corresponding internal manifest declaration, with exact counts/installSize and no duplicate declarations.
- Version-control member: `Contents/vs_installer.version.json`, 121 bytes / SHA256 `e78a1053a6d59ad60ba8105623181b013c0ffc452216caada2699046f191974f`. Its claimed version is recorded but supplies no closure authority.

The mapping strips literal `Contents/` and retains every relative file under `${env:ProgramFiles(x86)}/Microsoft Visual Studio/Installer`, including resources/app. All installed files are enumerated and hashed; missing, changed and unknown additional files are separately reported. No extension selector, exclusion or version-only shortcut is introduced.

## Reuse, safety and receipt

Copied the frozen IM-VS-16 diagnostic into a new absent path after verifying original SHA `da857185bccc68232592cd3bcc47d5da1ef30b648d16c9ef886aaa81b70898c1`. Retained seven helper function definitions **exactly unchanged**, confirmed by AST extent-text comparison: context, absolute/reparse path, safe relative path, stream SHA256, locked file record, pinned OPC/internal manifest inventory, and complete tree comparison. No dot-sourcing of a script body with `exit` or executable side effects occurs. Removed the unused product JSON reader and original whole-source/bootstrap preflight only from this separately scoped diagnostic.

OPC hash verification and member inspection use the same read-locked archive handle (`FileShare.Read`). File hashing denies writers for the duration of each read. Absolute paths and ancestors/descendants reject reparse points; names reject traversal, Windows-invalid/reserved names, duplicate/case collisions. These are snapshot reads, not locks held after completion or permission to execute the engine later.

Fresh `%TEMP%/autoclip-vs-opc-map-<uuid>/receipt.json` retains full expected/actual inventories and differences. The directory has current-SID owner and protected DACL with inherited FullControl for only current SID, SYSTEM and Administrators, inspected before receipt writing. Partial failures are preserved; failed directories are not cleaned. Failure before protected output has stdout error only.

Statuses remain `EXACT_INSTALLED_ENGINE_CONTENTS_MATCH` / exit 0 for full equality, `INSTALLED_ENGINE_DIFFERENCES` or other failure / exit 2 otherwise. Every outcome retains production `BLOCKED`, false vendor/source mutation, false engine preparation, false OPC-signature-verifier execution, false original source verification and the original failed primary receipt's hash. Raw pinned OPC/member identity is not labeled independent OPC certificate-trust verification.

Optional post to the existing local laboratory `/processes` endpoint includes all difference names and binds full receipt path/SHA. It is disabled by default, requires verified guest context, and is capped at 1 MiB UTF8/10-second timeout. No certificate/TLS bypass.

## RED/GREEN and exact commands

Before creating the new diagnostic, copied/adapted the first-party fixture and ran:

```powershell
powershell.exe -NoProfile -File D:/AutoClip-Inno-Migration/vm-transfer/vs-opc-installed-map-probe.Tests.ps1
```

Exit 1: `RED: independent pinned OPC/installed engine mapping diagnostic absent.`

After the bounded production change, the same command returned exit 0:

```text
GREEN: independent OPC/installed pair without original product files; manifest/member hashes, exact/changed/missing/extra DLL, unsafe members, wrong OPC pin, context guards, parser and readonly default.
```

Fixtures use actual reused functions on a first-party ZIP/engine pair without Catalog or original product payload files, validate internal manifest/member equality, accept exact files, reject changed/missing/extra DLLs, wrong outer OPC pin, invalid/reserved/traversal/duplicate/case names, and manifest disagreement. They retain context fixtures, PS5.1 parsing, actual default `-PostResult` remaining read-only, and explicit independent-scope output assertions. Fake EXE/DLL byte markers are never executed. Only fixture-owned TEMP paths are cleaned after resolved absolute ownership checks.

Executed AST comparison of the seven reused function definitions against the hash-verified original; all matched exactly. Executed `Get-FileHash -LiteralPath` on new probe/fixture and preserved original/primary evidence after GREEN. Read/parsed the preserved primary receipt and independently confirmed the 41/368/0/0 counts and surviving selected byte records. No operational `-MapInstalledEngine` ran on the host or guest by this author.

## Frozen artifacts and remaining work

| Artifact | SHA256 |
| --- | --- |
| New vs-opc-installed-map-probe.ps1 | `f0b92c001bca4e2792103abfb25068003bda903872a638050729d8b8b2dab2d6` |
| New vs-opc-installed-map-probe.Tests.ps1 | `637a9cf641df80b7fdbbd43b810f7838a0672692eb0bd61c6ec8b9f82565ea33` |
| Preserved IM-VS-16 probe | `da857185bccc68232592cd3bcc47d5da1ef30b648d16c9ef886aaa81b70898c1` |
| Preserved original guest primary failure | `f4abe6645aa9fec54d8b8ad30ca64c838bceb86761d25ca4fecaa4318e87f327` |

Root owns VM transfer, inspection and execution of the readonly guest mapping. The resulting full receipt must establish actual installed differences; no result is inferred from version or host observations. Missing original payload forensics remain a separate task. No vendor operation, engine preparation, native layout creation, whole wizard, legal or production gate is qualified here.
