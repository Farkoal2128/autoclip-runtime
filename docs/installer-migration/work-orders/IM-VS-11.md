# IM-VS-11 — JSON signature diagnostic preparation

## Authorization and boundary

Parent authorized only `D:/AutoClip-Inno-Migration/vm-transfer/vs-json-signature-probe.ps1` and this report. No VM control, vendor installation or assembly execution, certificate-store import, canonical manifest change, release, or memory use. The script is a laboratory diagnostic using Windows/.NET cryptography. Its custom serializer was reconstructed from static vendor IL; it is not an officially documented or supported vendor verifier.

Production remains `BLOCKED`: successful checks on these local metadata bytes do not resolve the contradictory channel-declared external catalog beginning SHA `6e470...`, size `30,443,537`, or establish legal/release qualification.

## Interface

```powershell
# Read-only default, including when the optional switches are present:
powershell.exe -NoProfile -File .\vs-json-signature-probe.ps1 -OnlineRevocation -PostResult

# Parent-owned ordinary guest run, local crypto checks only:
powershell.exe -NoProfile -ExecutionPolicy Bypass -File .\vs-json-signature-probe.ps1 -VerifyJson

# Optional OS trust/revocation checks and compact laboratory result post:
powershell.exe -NoProfile -ExecutionPolicy Bypass -File .\vs-json-signature-probe.ps1 -VerifyJson -OnlineRevocation -PostResult
```

`-VerifyJson` requires `autocliplab`, native64 PowerShell/OS, and an unelevated token before mutation or operational validation. Inputs are fixed to `C:/Users/AUTOCL~1/AppData/Local/Temp/acvs-fd9e3fbd6cec/layout`. It checks regular files, no reparse ancestors, exact size and SHA256, then uses that same in-memory byte snapshot for all checks:

| File | Size | SHA256 |
| --- | ---: | --- |
| Catalog.json | 17,954,732 | `f0a50ea157222c29abd5ea6ff01bfc3c33b04e011c5e45ee2ca38ef0778e5643` |
| ChannelManifest.json | 91,781 | `fca418ba94ffbcfb7a2b25f10f16f39dd09660568d21eef4bd3f274cb0b27b8c` |

Fresh `%TEMP%/autoclip-vs-json-<uuid>` output is created with protected DACL, current recipient SID owner, and inherited FullControl ACEs only for that SID, SYSTEM, and Administrators. The owner/ACL are inspected before marking the output writable. No unrelated cleanup occurs. Failure before protected output verification produces stdout error without writing a receipt; later failures preserve partial document flags in the protected full receipt.

`receipt.json` schema 1 records separate exact-file, content digest, reconstructed message, RSA, CMS signature-only, timestamp imprint/time/signer binding, and OS-chain flags. Certificate subjects, issuers, SHA256/thumbprints, validity UTC and extensions are recorded. Each requested chain result records purpose, verification UTC, policy, all chain and element statuses, and chain certificates. Successful completion status is `DIAGNOSTIC_CRYPTO_CHECKS_COMPLETED`, exit 0; structural/crypto failure status is `FAILED`, exit 2. Completion does not mean chain trust succeeded: every chain result remains separate. `legal_qualified` and `production_qualified` are always false, route always `BLOCKED`.

Optional `-PostResult` is disabled by default and requires verified guest context. It posts a compact result binding the full local receipt path/SHA256 to `http://10.0.2.2:8765/processes`, limited to 1 MiB UTF8 and a 10-second timeout. It does not post full certificates or metadata. No TLS/certificate bypass is used. Parent controls when networking is enabled.

## Checks and evidence sources

The static investigation agent supplied exact formatting: four signInfo lines with one initial TAB, fixed order signatureMethod/digestMethod/digestValue/canonicalization, literal `"key" : "value"`, commas except last, CRLF, no wrapper. KeyInfo adds tab-indented keyValue/rsaKeyValue with modulus/exponent, then x509Data array in its original certificate order; no outer keyInfo wrapper. Message is UTF8 concatenation of those two blobs. Both messages are 7,013 bytes:

- Catalog: `5b55a72c8f5e5ee3fd5d2f080beca86d45b81a6d4c1dae6b9392974c5774a7fb`.
- Channel: `46a9921ffc4cbe9b2d03f1e9355155cdca65a3bb5af9cd130e0320acbdebed06`.

Content digest follows the investigated loader: first literal `"signature"`, preceding prefix truncated through its final comma. The exact pinned files contain no BOM. Matched Base64 SHA256 digests:

- Catalog: `OCxEsM2FC2orlyyiF7ARJvlk+RhjapezG651bYdPQp8=`.
- Channel: `qQSpdZizKr1EoAC0MsqXEVllzCN4U8msQDNzquf7HIw=`.

RSA uses the first embedded signing certificate's public key, verifies that its modulus/exponent match keyInfo, and verifies decoded signatureValue over the reconstructed message with SHA256/PKCS1. The first certificate is not made a trusted root.

CMS uses OS `SignedCms.Decode` and `CheckSignature(true)`, requires one signer and RFC3161 TSTInfo content OID, and binds its signer certificate bytes to counterSign.x509Data[0]. Signature-only verification explicitly does not establish certificate trust. A small bounded DER reader decodes the TSTInfo SHA256 imprint and signed GeneralizedTime. The imprint must equal SHA256 of the UTF8 **base64 signatureValue text**, and signed times must be Catalog `20260910230631.676Z`, Channel `20260910230629.019Z`. Unsigned counterSign.timestamp text is recorded separately and supplies no trusted time.

`-OnlineRevocation` separately builds OS chains for code-signing purpose `1.3.6.1.5.5.7.3.3` and timestamp purpose `1.3.6.1.5.5.7.3.8`, at current UTC and the signed timestamp UTC. Policies are Online revocation, ExcludeRoot, NoFlag, and a 10-second URL retrieval timeout. Embedded certificates go only into the in-memory ExtraStore; OS trusted roots remain authoritative. The timeout is per URL, not a guaranteed aggregate duration. A past verification time with current revocation information does not reconstruct historical revocation knowledge.

Independent static investigation provenance, supplied by the investigation agent: pinned OPC SHA `62f68d0d6e2adce5cd65f549cbda234358c1cbda442af4de1c3f7ae43fb8b5a6`, embedded Microsoft.VisualStudio.Setup.dll SHA `eef5c2bf3de9a7e2667e056894769fde8aae19c911d67bc9e388a59bdc69dcea`, method rows 2118/2121/2124–2126/2141–2143/2229–2230/2236–2237/2242/2247. This author did not load that DLL or repeat IL analysis.

## RED and host GREEN

Before implementation, executed:

```powershell
$candidate='D:/AutoClip-Inno-Migration/vm-transfer/vs-json-signature-probe.ps1'
if (!(Test-Path -LiteralPath $candidate)) {
    throw 'RED: read-only JSON signature diagnostic and validation functions absent.'
}
& $candidate
```

Observed exit 1 and the exact missing-diagnostic message.

Host-only GREEN used `[Management.Automation.Language.Parser]::ParseFile`, then `powershell.exe -NoProfile -File <probe> -PostResult -OnlineRevocation`, confirming parse success, exit 0, read-only status and false operational/network flags. Actual function definitions were extracted from the AST without executing the operational script body:

1. Read the two authorized host fixtures at `D:/AutoClip-Inno-Migration/vs-layout-26100`; checked the exact size/file SHA, `Get-JsonPrefixDigest` equality, and `Get-JsonProbeMessage` length 7,013 plus both message SHA pins. Both passed.
2. Generated an isolated first-party RSA key, signed first-party UTF8 text with SHA256/PKCS1, and tested `Test-JsonProbeRsa`. Valid signature passed; a mutated message failed. No vendor metadata RSA signature was verified on the host.
3. Actual `Assert-JsonProbeContext` accepted ordinary autocliplab/native64 fixture and rejected foreign user, non-native64, and elevated fixtures.
4. Actual DER reader rejected indefinite length. A first-party synthetic TSTInfo with SHA256 zero imprint and signed time `20260910230631.676Z` parsed correctly with UTC kind; corrupted sequence tag was rejected. An initial synthetic harness accidentally nested a byte array; correcting its fixture concatenation produced GREEN. That harness error is not behavioral RED.

Final parser/default command:

```powershell
$path='D:/AutoClip-Inno-Migration/vm-transfer/vs-json-signature-probe.ps1'
$errors=$null
$tokens=$null
$null=[Management.Automation.Language.Parser]::ParseFile($path,[ref]$tokens,[ref]$errors)
if ($errors.Count) {throw ($errors | Out-String)}
& powershell.exe -NoProfile -File $path -OnlineRevocation -PostResult
if ($LASTEXITCODE -ne 0) {throw 'Readonly default failed.'}
Get-FileHash -LiteralPath $path -Algorithm SHA256
```

Frozen script SHA256: `5dee1dfe27a934595032d2ef4095456b3e203f7681a6e8b3013aee75d26dc996`.

## Primary OS documentation and remaining limits

Microsoft's [SignedCms.CheckSignature documentation](https://learn.microsoft.com/en-us/dotnet/api/system.security.cryptography.pkcs.signedcms.checksignature?view=windowsdesktop-9.0) distinguishes signature-only verification from certificate validation. [X509ChainPolicy.RevocationMode](https://learn.microsoft.com/en-us/dotnet/api/system.security.cryptography.x509certificates.x509chainpolicy.revocationmode?view=net-9.0) documents the separate chain revocation setting. Those APIs document OS crypto, not the reconstructed vendor JSON serializer.

No operational `-VerifyJson`, actual metadata RSA/CMS verification, certificate-chain/revocation retrieval, guest DACL/output receipt, network POST, VM or vendor installation ran on the host or guest by this author. Parent must inspect/run the frozen candidate in the ordinary guest and retain its receipt. Positive results authenticate these pinned local bytes within the reconstructed diagnostic; they do not settle contradictory external-channel authority, whole installer support, legal rights, source-build qualification, signing, or publication.
