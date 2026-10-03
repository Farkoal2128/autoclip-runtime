# IM-VS-20 — exact Microsoft payload filename mapping

Status: new r2 acquisition diagnostic prepared and fixture-verified, 2026-10-01. No guest, vendor acquisition or vendor execution performed by this work order.

## Requirement, cause and scope

Parent authorizes the minimum acquisition-path correction for IM-VS-19. Own only new r2 probe, its fixtures, and this report. Canonical dependency manifest, downloader, contract, frozen IM-VS-19 and original failed guest stage are unchanged. This is acquisition diagnostic work; no native layout or product installer execution is authorized.

Independently hashed/read primary `D:/AutoClip-Inno-Migration/vm-vs-preload-failure-primary-b76bc5772247.json`: SHA-256 `b76bc57722472e36925dc265d153071c26c8270b5e663ef6a3662a7993fb9551`, status `FAILED_PRESERVED`, 267 verified artifact rows. Error: `Unsafe download destination: require a regular file under TEMP.` Original stage: `C:/Users/autocliplab/AppData/Local/Temp/vs p-e513347b`.

Next exact manifest row, index 267:

`Win11SDK_10.0.26100,version=10.0.26100.15,productarch=neutral/Installers/Application Verifier arm64 External Package (DesktopEditions)-arm64_en-us.msi`

The unchanged production downloader intentionally permits only letters/digits/period/underscore/plus/hyphen in a destination basename. The official filename contains spaces and parentheses. All other protections remain appropriate. Correction belongs to the shared diagnostic acquisition mapping, not a broadened production regex.

## Minimum correction

The new r2 downloads each manifest-selected artifact into a generated protected `download-cache/<exact-sha256>.payload` filename using unchanged downloader SHA `75ac92e4108a6fd3165617b2c94be02b44ca86c61a5397672d898eaa38635ad6`. The complete 397-row/432-association metadata remains unchanged SHA `15d558e950e713b20ff16c0347b0bf933087adfd1b06b3c0148f5aab74cf0efc`; all 140 size conflicts remain recorded. There are 391 unique content hashes, so duplicate content is reused only after the real downloader checks exact size/hash within the fresh run's protected cache.

`Copy-VsPinnedPayload` validates manifest-approved relative path grammar and containment, source/output ACLs, reparse safety and exact source cache basename. It opens a native read lock, verifies source byte length/SHA **before target creation**, copies only those locked bytes to the exact vendor relative path using `CreateNew` and no sharing, flushes, and verifies target ACL/length/SHA. Existing target files/directories fail without overwrite; copy failures remain preserved. Receipt rows retain URL, filename, exact byte/hash, actual target path and source cache path. Final whole-set hash checks remain in place. Production guard and every other IM-VS-19 safeguard are retained.

Every run creates a new protected short root with a space in its name. No original 267-file cache reuse is implemented; the old stage and primary failure remain untouched. Cache plus mapped files need up to approximately 2.58 GB beyond earlier retained stages. No files are executed/extracted, no certificates imported, and no generated vendor controls are authored.

## RED/GREEN evidence

Exact command:

```powershell
powershell -NoProfile -File D:\AutoClip-Inno-Migration\vm-transfer\vs-pinned-preload-probe-r2.Tests.ps1
```

Meaningful RED before implementation, exit 1: the unchanged production destination guard rejected the **actual index-267 official relative basename**, accepted the generated safe hash cache name, then the test failed because `Copy-VsPinnedPayload` did not exist. The first fixture attempt had a PowerShell dot-source variable type collision in its fixture's `$identity`; that fixture defect was corrected to `$mappingIdentity` before recording this behavioral RED.

GREEN after implementation, exit 0: unchanged guard still rejects the original official basename; actual unchanged downloader validates an existing first-party fake source under the safe hash cache name without network; verified copy produces the official filename including its spaces/parentheses; an existing target is rejected and unchanged; source content/hash and cache basename mismatches stop before creating a target; five unsafe relative paths reject. All inherited real 397/432 equality, metadata drift, ordinary/native/unelevated context, native write/rename read locks, corruption, parser and read-only default tests pass. Fixtures are first-party only and preserve their unique temporary roots.

This is fixture verification, not a full guest preload pass or any vendor execution/signature/license/wizard gate.

## Frozen handoff

New files under `D:/AutoClip-Inno-Migration/vm-transfer/`:

| File | Bytes | SHA-256 |
| --- | ---: | --- |
| `vs-pinned-preload-probe-r2.ps1` | 15769 | `fcc4bab2e423303c5dd11ac4b3139b5c61fe1bef45f1a57a0865c79b26826fe8` |
| `vs-pinned-preload-probe-r2.Tests.ps1` | 10237 | `cce3691f371ae47f46dc455306ddc7c618c2be4bc4e14322c99ec04f9d827f4d` |

Original probe remains SHA `cda869256879983b0f191414dc2438633d180bb37af51f3390ff5adfbd5ab3cb`. Root serves only first-party r2 probe plus unchanged `download-artifact.ps1`, `vs-layout-expected-inventory.json` and `vs-pinned-preload-manifest.json`. After root verifies the probe hash, root alone may invoke:

```powershell
powershell.exe -NoProfile -ExecutionPolicy Bypass -File <verified-absolute-r2-guest-path> -PreloadPayloads -PostResult
```

Initial `/processes` POST identifies probe `vs-pinned-preload-r2`, PID/stage and live `phase.json`; every artifact updates the local phase file. Final full receipt `/python-wizard`, compact `/processes`; coordinate mutable endpoint ownership. Preserve failed/partial stages. Do not restart on observation timeout. Acquire complete primary receipt and verify all397 final targets before any later separately authorized stage. Canonical Microsoft route remains `BLOCKED`.
