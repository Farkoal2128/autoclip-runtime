# IM-VS-43: locate selected SDK license bytes without installation

## Scope and evidence

Parent authorized preparation only of a recipient read-only Windows Installer database command. No VM operation, host vendor acquisition/execution, installer session, installation or production modification was performed. VS42 remains preserved and must not be killed or retried by this work.

Frozen 470,838-byte inventory SHA-256 `545b140236b4765a964c14708dcbf1e6131497a58c1655be081631b4f8a91397` identifies:

- `Win11SDK_10.0.26100,version=10.0.26100.15,productarch=neutral/Installers/Windows SDK EULA-x86_en-us.msi`
- 450,560 bytes; SHA-256 `f3958c26326c6aeb29cb91a62e8e7f2f4347b8847313d6a8041567b12d493bb6`
- Selected package Win11SDK_10.0.26100/version10.0.26100.15.
- Official source `https://download.visualstudio.microsoft.com/download/pr/6452c1f1-dc1e-413c-8b19-991b61870a8b/4adaf0e5ffed56dbbdd2e1a7928a69c9/windows%20sdk%20eula-x86_en-us.msi`.

IM-VS-02 previously inspected this exact MSI File table read-only and found `sdk_license.rtf` (248,573 bytes) and `sdk_third_party_notices.rtf` (22,279 bytes). It did not extract either file. A File-table row describes a packaged file; it does not itself expose its content as a COM record stream. Cabinet linkage must be established before a supported data-only extraction is prepared. No exact terms text or consent equivalence is claimed.

## Prepared command

`D:/AutoClip-Inno-Migration/vm-transfer/vs43-sdk-terms-command.txt`: 2,811 bytes; SHA-256 `fb4ea817294f5552dd6d4f7be9ba5f4188612a679ebd5fb58bbe45986abd87a8`.

Requires ordinary native64 autocliplab and existing reviewed Open-AdminPin/Assert-AdminPath functions. It holds the exact MSI readlock at fixed protected VS40 layout path, opens WindowsInstaller.Installer.OpenDatabase with mode0, then selects only table names, File identities/size/sequence, Media cabinet linkage, stream names and Binary names if present. It returns structured metadata without writing vendor data or invoking MSI session/action/commit methods. It does not extract guessed terms or create an output directory before extraction feasibility is known.

The [Microsoft OpenDatabase API](https://learn.microsoft.com/en-us/windows/win32/msi/installer-opendatabase) defines read-only mode0. [Record.ReadStream](https://learn.microsoft.com/en-us/windows/win32/msi/record-readstream) reads actual stream fields; it is not a cabinet decompressor. Thus this initial command intentionally discovers the missing source linkage instead of claiming that reading File metadata extracts the license.

## Verification and remaining work

PowerShell Parser.ParseFile completed without errors. No command was executed against Windows Installer or vendor bytes here; no behavioral GREEN is claimed. Root can review/run this read-only discovery command and preserve the resulting exact File/Media/stream linkage. If the license is cabinet-only, a separately bounded native cabinet data extraction must be prepared and reviewed; no administrative MSI install or custom-action session is needed. The exact 248,573-byte RTF, its measured hash and readable terms still remain required before requesting SDK consent.

## Root execution: read-only metadata, 2026-10-02

Root ran the frozen command in ordinary native64 autocliplab (PID13308) in the cold-engine Windows11 VM. Actual primary `D:/AutoClip-Inno-Migration/vm-vs43-sdk-metadata-primary-c1ff85f82b0a.json` is 5159 bytes, SHA256 `c1ff85f82b0a71a4d5d5f6d531aea732ea81f79dc43a82a9c7bad5536f39615a`. OpenDatabase mode0; no installer session or vendor execution. The actual File/Media records establish license file sequence4, Disk3/LastSequence4 and the exact external CAB named above. The `.value`/Count wrappers in the serialized rows are preserved. This is terms-location evidence only; subsequent actual extraction is separately recorded in IM-VS-44.