# IM-VS-36 — JSON authentication driver with a current controls root

Status: prepared and focused fixture-verified, 2026-10-02. No actual VM authentication, vendor execution/download, server action, certificate import or trust-store change was performed by this author. Root owns concrete guest invocation. Only these two new external first-party files and this report were changed; frozen r2 and earlier receipts remain preserved.

## Requirement and minimal change

IM-VS-35 prepares nine exact controls in a new current-recipient protected root. Frozen JSON authentication r2 always reads the old warm layout path, so it cannot authenticate the new acquisition. Add one explicit `ControlRoot` binding while preserving all existing signature, timestamp, file/message pin, serializer, CMS and normal native chain behavior.

New r3 is a distinct copy of frozen r2 SHA256 `2a779ae9a2c1591342223e21880df9965c6a304c953c8fc6d50da64e4337b251`. Every original function definition is byte-for-byte identical, verified by AST function-body comparison in the focused test. There is no new cryptographic implementation. The differences are the new parameter/root binding, three small root/ACL/readlocked-file functions, input root recorded in the receipt, and holding the exact document stream through its existing verification phase.

`ControlRoot` must be an existing canonical absolute local-drive path strictly under the current native TEMP root. Validate its protected recipient-owned parent, root ownership and ACLs: only recipient, SYSTEM and Administrators full control; no reparse ancestor/root, relative path, parent traversal or foreign actor. Perform root validation after the ordinary native64 `autocliplab` context guard and before creating output or performing crypto/network. Each document also gets the same path/ACL checks and a held FileShare.Read stream; exact size/hash is checked on those same read bytes. Original strict Catalog/Channel/message/timestamp checks remain unchanged.

Default remains read-only even with `ControlRoot`, `OnlineRevocation` and `PostResult` supplied: it reports the requested root, operational/online/post flags false, creates nothing and exits0. There is no fallback to the historical root when verification is requested without a valid root.

## Frozen files and exact invocation

| External file under `D:/AutoClip-Inno-Migration/vm-transfer` | Bytes | SHA256 |
| --- | ---: | --- |
| `vs-json-signature-probe-r3.ps1` |20,909|`075e882f8af958bc98ad7304970efdd31621bdcec94c478a1478e05c09903973`|
| `vs-json-signature-probe-r3.Tests.ps1` |4,830|`f89ffeb247e2df03a537082770317470a067826b7ab5418b3d7ff120f6776468`|

After root verifies the exact first-party driver and actual VS35 protected control root, the operational interface is:

```powershell
powershell.exe -NoProfile -File <verified-r3-driver> -VerifyJson -OnlineRevocation -ControlRoot '<actual VS35 stage>\controls'
```

`-PostResult` remains the existing optional compact first-party receipt post; no post was invoked by this author. The driver reads only exact Catalog17,954,732 bytes/SHA256 `f0a50ea157222c29abd5ea6ff01bfc3c33b04e011c5e45ee2ca38ef0778e5643` and Channel91,781 bytes/SHA256 `fca418ba94ffbcfb7a2b25f10f16f39dd09660568d21eef4bd3f274cb0b27b8c` from that root. No arbitrary additional documents or vendor code are loaded.

For actual authentication, root must inspect all document pins/signatures/imprint/timestamp binding and every returned chain result. Preserve r2's scope: `DIAGNOSTIC_CRYPTO_CHECKS_COMPLETED` alone does not assert all chains trusted or production qualification. `OnlineRevocation` is required for the current chain observations; normal chain policy remains Online/ExcludeRoot/NoFlag with code-signing and timestamp purposes, current UTC plus signed UTC checks, memory-only extra certificates, no root import, backdating substitution or trust override. Signed-time checks with current revocation data are not independent historical revocation proof. The custom vendor JSON serializer remains reconstructed, not an officially supported vendor verifier. Catalog's conflicting channel declaration is preserved.

## RED → GREEN verification

Exact RED command:

```powershell
powershell.exe -NoProfile -File 'D:/AutoClip-Inno-Migration/vm-transfer/vs-json-signature-probe-r3.Tests.ps1' -Legacy
```

Actual frozen r2 ignored the requested `ControlRoot`; focused test failed exit1 with `RED: legacy driver ignores requested current ControlRoot.` No operational verification ran.

Exact GREEN command:

```powershell
powershell.exe -NoProfile -File 'D:/AutoClip-Inno-Migration/vm-transfer/vs-json-signature-probe-r3.Tests.ps1'
```

Final execution passed exit0. Tests verify requested root binding and actual readonly subprocess; all original r2 function bodies unchanged; PS5.1 parsing; real protected native directories/files with spaces; relative/traversal/outside-TEMP, foreign owner, foreign ACL and actual junction rejection; same-stream exact size/hash reading; held readlock blocks writes; wrong size/hash rejection; actual unchanged native RSA valid and tampered first-party fixtures. Fixture files/junctions remain preserved. One test-only PowerShell array arithmetic expression was corrected before final GREEN; it did not change implementation behavior or expected assertions.

No actual Microsoft metadata crypto, revocation traffic, guest execution or vendor layout/install test was performed. Root must obtain and review the actual current recipient result, then preserve held-input linkage for later OPC/engine checks and seed preparation. This diagnostic authenticates reviewed inputs within its recorded limits; it grants no native execution, uninstall, publication or release gate.
