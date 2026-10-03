# IM-VS-23 — fresh engine route and native OPC authentication

Status: bounded read-only investigation, 2026-10-01. Only this report changed. No code, VM, vendor execution, native OPC signature verification, extraction, certificate import or production classification changed. This is internal evidence analysis, not blind review or permission to install/publish.

## Decision

The minimum viable route is **the Microsoft bootstrapper installing its own authenticated local engine**, followed by the native interactive product installer. Do not replace the vendor engine installation with a custom OPC extractor or copying 868 files into Program Files. A standard .NET OPC signature check can authenticate the selected engine package before vendor code; its result remains to be exercised on the exact guest package. Current warm mapping proves file identity only. Canonical Microsoft remains `BLOCKED` pending actual cold-recipient operation and the other staged-contract gates.

## What the official command contract proves

[Microsoft's minimal-layout guide](https://learn.microsoft.com/en-us/visualstudio/install/update-minimal-layout?view=visualstudio) separates engine update from product update and explicitly supplies an engine-only bootstrapper command with a local OPC argument:

```text
vs_enterprise.exe --quiet --update --offline C:\VSLayout\vs_installer.opc
```

The guide permits substituting the correct product bootstrapper name, including BuildTools. [The network update guide](https://learn.microsoft.com/en-us/visualstudio/install/update-a-network-installation-of-visual-studio?view=visualstudio) also documents bootstrapper `--quiet --update --wait --offline` using the OPC from its layout. These are supported **engine update** interfaces. Neither document establishes, by itself, successful creation of an **absent** engine on a fresh recipient. Treat that next cold test as qualification of this bootstrapper behavior, not an already documented completed fresh-install result.

[The command reference](https://learn.microsoft.com/en-us/visualstudio/install/use-command-line-parameters-to-install-visual-studio?view=vs-2022) makes `--noUpdateInstaller` fail nonzero when an update is required in quiet mode. It is a prevention control, not a documented command to populate an absent engine. It has no stated equivalent guarantee for the interactive product step; `--noWeb` prevents product package retrieval but does not stop engine update checks. Local Catalog/Channel/update URI switches govern **install**, and cannot be assumed to pin a layout operation. Therefore do not combine `--noUpdateInstaller` with the phase whose purpose is installing/updating that engine and infer it will work.

[The layout guide](https://learn.microsoft.com/en-us/visualstudio/install/create-a-network-installation-of-visual-studio?view=vs-2022) documents latest-engine defaults for recent bootstrappers and requires Internet/admin permissions for initial layout acquisition. Removing an explicit latest setting is not independent proof that a recent bootstrapper will use only our selected OPC. The warm IM-VS-21/22 preparation remains distinct from this cold question. Offline command results and actual execution sources must establish what happens; no fallback to an unreviewed latest package is acceptable.

## Native OPC verifier: feasible, separate from installation

On Windows PowerShell 5.1, use the installed .NET Framework `WindowsBase` implementation, not a new NuGet dependency or vendor assembly. [Package.Open](https://learn.microsoft.com/en-us/dotnet/api/system.io.packaging.package.open?view=windowsdesktop-10.0) accepts an existing stream with explicit `FileMode.Open` and `FileAccess.Read`. This permits reusing the same native read-locked file handle already hash-checked by our existing helpers, without extracting or loading package Contents.

[PackageDigitalSignatureManager.VerifySignatures](https://learn.microsoft.com/en-us/dotnet/api/system.io.packaging.packagedigitalsignaturemanager.verifysignatures?view=windowsdesktop-10.0) verifies package signatures, **not certificate trust**. Require `IsSigned`, nonempty signatures and `VerifySignatures(false)==Success`; an unsigned package is not a success. Then inspect [SignedParts](https://learn.microsoft.com/en-us/dotnet/api/system.io.packaging.packagedigitalsignature.signedparts?view=windowsdesktop-10.0) and relationship coverage: the exact 868 Contents and `manifest.json` must be authenticated, with no omitted executable/startup/data input or unexpected signature selection. Keep the existing pinned raw-manifest/member checks; signature success does not replace full inventory equality.

[Signer](https://learn.microsoft.com/en-us/dotnet/api/system.io.packaging.packagedigitalsignature.signer?view=windowsdesktop-10.0) supplies the embedded X.509 certificate as data. Microsoft also exposes [VerifyCertificate](https://learn.microsoft.com/en-us/dotnet/api/system.io.packaging.packagedigitalsignaturemanager.verifycertificate?view=windowsdesktop-9.0), but an explicit normal Windows `X509Chain` check provides recordable policy/status. Use [X509Chain.Build](https://learn.microsoft.com/en-us/dotnet/api/system.security.cryptography.x509certificates.x509chain.build?view=net-10.0) with system trust, verified current time, code-signing purpose, bounded URL retrieval, normal [Online revocation](https://learn.microsoft.com/en-us/dotnet/api/system.security.cryptography.x509certificates.x509chainpolicy.revocationmode?view=net-10.0) and [NoFlag verification](https://learn.microsoft.com/en-us/dotnet/api/system.security.cryptography.x509certificates.x509chainpolicy.verificationflags?view=net-10.0). Require the expected Microsoft signer identity/certificate pin plus successful chain, and record each element/status. No cert-store import, custom trusted root, NoCheck, ignored unknown-revocation or backdated validation is justified. Revocation/AIA retrieval may use the network during authentication; finish it before the root disconnects the guest NIC for vendor execution.

[SigningTime](https://learn.microsoft.com/en-us/dotnet/api/system.io.packaging.packagedigitalsignature.signingtime?view=windowsdesktop-10.0) does not establish a trusted timestamp policy. The exact OPC contains an additional encoded timestamp object; do not claim the package verifier authenticated that timestamp or choose a past validation time solely from it. If current normal chain validation fails, retain the failure and establish any timestamp policy separately before execution.

This route is technically available as a **native verifier design**. No `PackageDigitalSignatureManager` call ran in this work order; actual framework compatibility, signature result, certificate trust, revocation and guest clock remain unverified. A native OPC result also does not grant rights or prove Microsoft supports manually installing its Contents tree.

## Read-only actual artifact inspection

Read IM-VS-17/18/21/22 and frozen `vs-opc-installed-map-probe.ps1`, independently confirmed source SHA `f0b92c001bca4e2792103abfb25068003bda903872a638050729d8b8b2dab2d6`. Its reused functions check exact raw ZIP/internal manifest/member and complete installed tree identity; receipt explicitly has `opc_signature_verification_executed=false`.

Independently SHA-checked existing host evidence OPC: 50,363,030 bytes, `62f68d0d6e2adce5cd65f549cbda234358c1cbda442af4de1c3f7ae43fb8b5a6`. Read ZIP/XML using standard-library parsers without extracting or executing it. Observed one OPC XML signature part, 299,923 bytes, path `package/services/digital-signature/xml-signature/q31b9wt__60v3c0306sfcjch.psdsxs`; root relationships identify the standard OPC signature origin. XML declares RSA-SHA256, 874 Reference elements: 868 Contents references, `manifest.json`, signature origin, three relationship references and `#idPackageObject`. One embedded X.509 certificate and a separate encoded timestamp object are present. These are structural observations, **not cryptographic verification or signed-coverage approval**.

This provides a concrete reason to try the native OPC API before writing custom XMLDSIG/CMS handling. The historical guest 868-match primary `51d09969e655dc945e3697af77e0a71a928b99d2153cbc2ef731624c84bafd48` remains a warm observation. Original 409 source failure and all 140 size/channel contradictions remain retained.

## Next finite root work order

1. First add a bounded native OPC verifier diagnostic with a first-party signed/unsigned/corrupt/wrong-signer fixture. Operate on an exact pinned read-locked recipient OPC; record package-signature result, complete signed input coverage, selected signer DER/hash, normal chain policy/status and clock. Reuse existing inventory/path/read-lock helpers. No vendor code or cert import. A failed/unsupported parser or trust result stops here.
2. After that succeeds, use one **fresh VM snapshot with no existing Microsoft engine or product**; do not delete the warm engine. Prepare exact recipient-only inputs through the reviewed acquisition route. Recheck every bootstrap/OPC/control signature and pin before use, preserve the original selected package, and disconnect networking. The next bounded engine-only candidate is the documented bootstrapper pattern, substituted with the pinned BuildTools executable and explicit local OPC:

```text
<verified-bootstrapper> --quiet --update --wait --offline <verified-exact-vs_installer.opc>
```

This is a proposal, not an invocation or fresh-support verdict. Elevated engine-only operation must remain separate from interactive product consent. Record bootstrap exit and actual extracted/installed engine files, logs, child/module sources, before/after state, and any remote/update attempt. Require every executing vendor byte to derive from the pinned bootstrap/OPC and the complete resulting engine to equal all868 expected members; unknown code or a required latest update fails. Do not manually populate Program Files, reconnect to accept a different engine, or install product packages in this experiment.
3. Only an actual cold result can support the fresh engine phase in the conventional Inno wizard. Then retain native agreement UI for the separate complete-layout product install, isolate/qualify its engine-update behavior, and verify MSVC/SDK and AutoClip capability. Warm layout success, a trusted OPC or an engine-only exit0 cannot stand in for those stages.

If the documented engine-update interface refuses an absent engine, preserve that specific result and require a supported fresh engine interface or Microsoft clarification. Do not invent an undocumented installation procedure to close the gate.
