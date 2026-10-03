# IM-VS-13 — corrected immutable JSON diagnostic

## Authorized scope

Parent assigned only the new `D:/AutoClip-Inno-Migration/vm-transfer/vs-json-signature-probe-r2.ps1`, a bounded runnable fixture beside it, and this report. No original probe/report or failed guest evidence was modified. No operational host `-VerifyJson`, VM control, vendor assembly load/execution, certificate import, installation, manifest, release, memory, or policy workaround was performed.

The diagnostic remains read-only by default. Ordinary native64/unelevated `autocliplab`, fresh protected receipts, optional OS online-chain flags and compact post behavior retain IM-VS-11's interface and restrictions. `production_route` remains `BLOCKED`; the contradictory externally declared catalog pin is unresolved.

## Requirement correction and evidence

The parent executed the original probe in the guest. Its preserved summary `D:/AutoClip-Inno-Migration/vm-vs-json-first-check-a8d37260ed95.json` records exact file/digest checks passing for both metadata files, followed by `RSA SHA256 PKCS1 signature failed.` This author read that summary, not the full guest receipt or VM. The summary binds the full guest receipt SHA `ea44fa53a8b9ff899d2c8a67c66acd0925c705db239b3f99c8a5a2b0dff795c0`.

Independent static escalation found an error in the prior reconstructed serializer: method 2126 IL offset 0x35 uses `ldc.i4.2`, passed to InsertTab at 0x36 and Concat at 0x3c. Each NestedSchema level adds **two tabs** to child entries. This IL finding was supplied by the investigator; this author did not load vendor DLLs or repeat IL inspection.

| Signing-message line | Original tabs | Correct tabs |
| --- | ---: | ---: |
| keyValue opening | 1 | 1 |
| rsaKeyValue opening | 2 | 3 |
| modulus/exponent | 3 | 5 |
| rsaKeyValue closing | 2 | 3 |
| keyValue closing | 1 | 1 |

SignInfo order/format, x509Data certificate order/indentation, and CRLF remain identical. The corrected message grows from 7,013 to **7,019 bytes**. The prior message pins described the wrong reconstruction, not the vendor's signed bytes.

| File | Original message SHA256 | Correct message / recovered signed SHA256 |
| --- | --- | --- |
| Catalog.json | `5b55a72c8f5e5ee3fd5d2f080beca86d45b81a6d4c1dae6b9392974c5774a7fb` | `9756c62b2aa625eb7c9cb046590de337d233ae4b131a265df2ba0754072fc35f` |
| ChannelManifest.json | `46a9921ffc4cbe9b2d03f1e9355155cdca65a3bb5af9cd130e0320acbdebed06` | `dd5edc7e9f81354df36ce4ea155c2c25e41ef225b225ced598578537407dc882` |

The runnable fixture independently decodes the pinned metadata RSA modulus, exponent and signature as unsigned integers, computes modular exponentiation using OS/.NET `BigInteger.ModPow`, and checks the recovered 256-byte PKCS1 v1.5 encoding: bytes 0/1 are 00/01, every padding byte 2–203 is FF, separator 204 is 00, and the next 19 bytes are SHA256 DigestInfo prefix `3031300d060960864801650304020105000420`. Its final 32 bytes match both corrected message hashes. This is read-only integer/byte analysis of primary metadata, not the operational guest verifier, certificate trust, or vendor code execution. Actual metadata `RSA.VerifyData`, CMS and OS-chain execution remain guest work.

## Meaningful RED → minimum change → GREEN

Created the runnable fixture before r2 production changes, then executed:

```powershell
powershell.exe -NoProfile -File D:/AutoClip-Inno-Migration/vm-transfer/vs-json-signature-probe-r2.Tests.ps1 -OriginalProbe
```

Exit 1. Both exact fixture file and prefix digest checks passed. RED printed both original 7,013-byte message hashes disagreeing with the independently recovered signed DigestInfo values in the table. It collected both failures and then threw; no assertion was weakened or skipped.

Copied the original to a new absent r2 path, changed only the nested indentation literal, the two expected signing-message hashes, and expected message length. `git diff --no-index -- <original> <r2>` confirmed those four change locations; its exit 1 is the expected difference result. Trust, digest, signature algorithms, timestamps, guest context/ACL guards and chain policies were not relaxed.

Then executed:

```powershell
powershell.exe -NoProfile -File D:/AutoClip-Inno-Migration/vm-transfer/vs-json-signature-probe-r2.Tests.ps1
```

Exit 0, with:

```text
GREEN: Catalog.json pinned content digest; 7019-byte custom message matches recovered PKCS1 SHA256 DigestInfo 9756c62b2aa625eb7c9cb046590de337d233ae4b131a265df2ba0754072fc35f.
GREEN: ChannelManifest.json pinned content digest; 7019-byte custom message matches recovered PKCS1 SHA256 DigestInfo dd5edc7e9f81354df36ce4ea155c2c25e41ef225b225ced598578537407dc882.
GREEN: parse/default, first-party RSA valid/tampered, synthetic DER valid/invalid, and guest-context fixtures.
```

The fixture reads only exact host metadata inputs `D:/AutoClip-Inno-Migration/vs-layout-26100/Catalog.json` and `ChannelManifest.json`, requiring their assigned file sizes and SHA256 before parsing. It AST-loads actual probe function definitions without running its operational body. It also tests a fresh first-party RSA key with persistence disabled (valid signature accepts; mutated text rejects), synthetic TSTInfo SHA256 imprint/UTC time and malformed DER rejection, accepted ordinary guest context plus three rejected contexts, PS5.1 parsing, and the real read-only default with `-OnlineRevocation -PostResult` present. No native vendor executable or operational metadata OS signature check is called by the fixture.

## Frozen artifacts and parent interface

| Artifact | SHA256 |
| --- | --- |
| New vs-json-signature-probe-r2.ps1 | `2a779ae9a2c1591342223e21880df9965c6a304c953c8fc6d50da64e4337b251` |
| New vs-json-signature-probe-r2.Tests.ps1 | `9ab3705063e8fa04b1afa8012080df2be1b617b93d09f9591d6c37fa3d28d992` |
| Preserved original vs-json-signature-probe.ps1 | `5dee1dfe27a934595032d2ef4095456b3e203f7681a6e8b3013aee75d26dc996` |
| Preserved failed guest summary | `a8d37260ed956fce485a8710b1873627dbdf749088d4b83547e9a7537b92081b` |

All four hashes were executed with `Get-FileHash -LiteralPath ... -Algorithm SHA256` after GREEN.

Parent may inspect/copy r2 and run it in the ordinary guest:

```powershell
powershell.exe -NoProfile -ExecutionPolicy Bypass -File .\vs-json-signature-probe-r2.ps1 -VerifyJson
# Only when parent chooses OS revocation retrieval and restores networking:
powershell.exe -NoProfile -ExecutionPolicy Bypass -File .\vs-json-signature-probe-r2.ps1 -VerifyJson -OnlineRevocation -PostResult
```

## Qualification limits

This corrects an investigator/producer reconstruction error. The original guest failure is not evidence that the vendor signatures are invalid. Conversely, the corrected serializer and recovered digest relation do not prove OS-chain trust, revocation, timestamp CMS validity, external channel authority, legal rights or production readiness. Parent must retain the actual r2 guest receipt and its separate RSA/CMS/timestamp/chain flags. The custom format remains reconstructed rather than an officially supported vendor verifier.

The unchanged OS API boundaries are documented by Microsoft in [SignedCms.CheckSignature](https://learn.microsoft.com/en-us/dotnet/api/system.security.cryptography.pkcs.signedcms.checksignature?view=windowsdesktop-9.0) and [X509ChainPolicy.RevocationMode](https://learn.microsoft.com/en-us/dotnet/api/system.security.cryptography.x509certificates.x509chainpolicy.revocationmode?view=net-9.0). Signature-only CMS results do not establish certificate trust. Online-chain URL timeout remains per URL, not aggregate; past verification time with current revocation data is not historical revocation proof. No whole setup, source build, NVIDIA, signing, publication or legal gate is closed by this work order.
