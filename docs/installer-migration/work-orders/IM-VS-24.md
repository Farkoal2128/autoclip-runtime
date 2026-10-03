# IM-VS-24 — native OPC package authentication diagnostic

Status: prepared and native first-party fixture verified, 2026-10-01. Operational vendor OPC authentication **not executed** on host or guest by this author. Own only two new diagnostic files and this report; preserve all prior frozen sources/receipts. Root owns VM/server actions and production contracts/classifications.

## Requirement and minimum implementation

Parent authorizes IM-VS-23's bounded native verifier. Explicit `-VerifyOpc` must authenticate exact incoming OPC bytes, all868 Contents/raw manifest/member pins, all869 required signed parts, the exact Microsoft signer DER and its normal current Windows chain, before any separately authorized vendor engine operation. Native verification grants no engine installation, product consent or release approval.

Use built-in .NET Framework `WindowsBase` `PackageDigitalSignatureManager`; no custom XMLDSIG implementation or new dependency. Outer SHA verification and `Package.Open(stream, Open, Read)` use the **same native read-locked stream** through verification. Import only function definitions from frozen IM-VS-17 AST, hash/length checked and held readlocked. Its unchanged raw OPC inventory helper opens a second read-only handle to the same file **while the outer native handle denies write/delete sharing**; it cannot observe independently mutable input. This preserves the reviewed raw ZIP/member/path defenses instead of rewriting the inventory function. Neither frozen helper driver nor vendor code executes.

Require exactly one signed package signature, native `VerifySignatures(false)==Success`, and coverage of `/manifest.json` plus every exact `/Contents/<relative path>` from the full pinned inventory. Record native signed part list and any missing inputs. Keep independently pinned outer50363030-byte SHA, raw manifest `1ed363...`,868 members/131469618 bytes and complete member hashes. Coverage of additional standard package-signature metadata may be recorded; the outer pin and frozen complete raw inventory prohibit accepting different incoming code/data.

Clone native signer certificate as data, compare exact DER SHA, and require operational simple name `Microsoft Corporation`. Use normal Windows `X509Chain`: current actual UTC, code-signing purpose `1.3.6.1.5.5.7.3.3`, Online revocation, ExcludeRoot, NoFlag,10-second URL retrieval. Record policy, actual UTC, chain statuses/elements and leaf validity. No imports, trusted-root override, ExtraStore, NoCheck, backdating, ignored revocation errors or timestamp-based acceptance. Authentication may retrieve normal CA/revocation data; root should perform it before NIC isolation and inspect the recorded guest clock. API incompatibility, failed signature/coverage/pin or trust failure preserves a failure receipt and exits2. There is no fallback.

## Exact expected signer established read-only

From the existing hash-verified host evidence OPC, read the only X509Certificate element in `package/services/digital-signature/xml-signature/q31b9wt__60v3c0306sfcjch.psdsxs` as base64 DER; standard-library SHA and native X509 metadata parsing, no signature/chain check or extraction:

- 1816 DER bytes, SHA `b1262c21335765e1d3ce69ebaf06a989554ededabbd4cddd66e2312b926229b1`.
- Subject `CN=Microsoft Corporation, OU=OPC, O=Microsoft Corporation, L=Redmond, S=Washington, C=US`; simple name `Microsoft Corporation`.

This pin comes from the selected outer OPC identity `62f68d0d6e2adce5cd65f549cbda234358c1cbda442af4de1c3f7ae43fb8b5a6`. Embedded identity alone is not trust; the actual native crypto and normal Windows chain still must pass in the guest. Encoded timestamp is not authenticated by this diagnostic (`timestamp_validated=false`). Existing IM-VS-17 warm engine mapping and old source failure keep their original scopes.

## Context, inputs and receipts

Default (including `-PostResult`) is `READ_ONLY_PLAN`, exit0, no network, stage, native verification or vendor execution. Explicit operation requires ordinary native-x64 unelevated `autocliplab` before machine writes or network. Create fresh protected recipient/SYSTEM/admin-only output with recipient owner; reject reparse ancestors and collision. Hold self and frozen helper read locks through operation. Fetch only first-party helper `vs-opc-installed-map-probe.ps1` from the existing laboratory service, verifying14416 bytes and SHA `f0b92c001bca4e2792103abfb25068003bda903872a638050729d8b8b2dab2d6` before importing AST functions.

Fixed recipient input, with no caller override:

`C:/Users/autocliplab/AppData/Local/Temp/acvs-fd9e3fbd6cec/layout/vs_installer.opc`

Exact50363030-byte outer SHA `62f68d0d6e2adce5cd65f549cbda234358c1cbda442af4de1c3f7ae43fb8b5a6`. Input and ancestors reject reparse points; full raw inventory uses frozen safe relative/member and closure checks. Full receipt includes every actual Contents byte/hash, signer, native signature/coverage results, chain and limits. It does **not** claim installed engine verification. No payload extraction, vendor code, product installation, certificate import, old cache rewrite or cleanup.

Protected `receipt.json` and failed root are preserved. Full UTF8 receipt ≤1000000 bytes posts `/python-wizard`, compact exact receipt path/hash posts `/processes` only with `-PostResult`; root coordinates endpoint ownership. All streams close in `finally`. A transport failure is separately recorded; it does not invent an operational pass.

## Native RED/GREEN verification

Exact command:

```powershell
powershell -NoProfile -File D:\AutoClip-Inno-Migration\vm-transfer\vs-opc-signature-probe.Tests.ps1
```

Initial RED exit1: `RED: native OPC authentication diagnostic absent.` After implementation, same command GREEN exit0 on Windows PowerShell5.1/native .NET:

- Actual native `PackageDigitalSignatureManager.Sign/VerifySignatures` on first-party package bytes: RSA/SHA256 self-signed certificate, code-signing EKU and embedded signer. Cryptography and signed coverage pass; ordinary system trust fails as required, and authentication remains false.
- Unsigned package, post-signature tampered part, incorrect signer DER pin and missing required signed part all reject.
- Real Windows held file handle rejects mutation and rename; wrong outer hash rejects, correct pin accepts.
- Parser and default `-PostResult` remain read-only; explicit operation in this host's wrong username context fails before stage/network/native vendor validation.

Certificate created in memory; fixture performs no certificate-store import. RSA provider persistence is explicitly disabled when the runtime uses a CSP; certificate/key objects are disposed. Unique first-party fixture roots are preserved. No package EXE/DLL byte marker executes. The selected vendor OPC's native signature, chain and clock remain **unperformed**; fixture success is not a Microsoft pass. No broad suite/app experiment needed for these isolated diagnostics.

## Frozen parent handoff

Files under `D:/AutoClip-Inno-Migration/vm-transfer/`:

| File | Bytes | SHA-256 |
| --- | ---: | --- |
| `vs-opc-signature-probe.ps1` |12218| `58fcd8ce1af84f465d29a1eda36be49a244663f89051a1334e8f9d98fddcfc46` |
| `vs-opc-signature-probe.Tests.ps1` |6289| `a3cff12066b15c1e68b77193dc00d255a4b433c4b404f06b88c407dff96a9cea` |

Root reviews and hash-checks the new probe before operation; serve this first-party probe and frozen `vs-opc-installed-map-probe.ps1`, without vendor mirrors. Explicit root-owned invocation:

```powershell
powershell.exe -NoProfile -ExecutionPolicy Bypass -File <verified-absolute-guest-probe-path> -VerifyOpc -PostResult
```

Successful status would be `AUTHENTICATED_EXACT_OPC_NORMAL_WINDOWS_TRUST` only. It does not execute/install the engine or broaden old review/legal/publication records. Root must inspect complete primary bytes/hash, required coverage, selected signer, chain/time and limits; recheck inputs immediately before any subsequent authorized vendor operation. Unsupported API or trust failure stops the route; canonical Microsoft remains `BLOCKED` until separate actual cold engine acquisition, native product/wizard/application and final gates pass.
