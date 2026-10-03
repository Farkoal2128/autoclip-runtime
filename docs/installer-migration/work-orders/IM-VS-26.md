# IM-VS-26 — separate protected admin engine experiment

Prepared and fixture-verified, 2026-10-01. Author performed no VM operation, vendor acquisition/authentication/execution, certificate import, policy change or production change. Root owns the VM, inline elevation, complete observer and later gate disposition. Only the new diagnostic, its focused fixtures and this report are owned here; all previous frozen sources and receipts remain preserved.

## Authorization and evidence boundary

Parent authorized this bounded engine-only diagnostic after reporting actual cold-baseline absent evidence SHA `0f3901d53f559dfde0980e8acc91771c90c68e8ea37bcdf6d863e6c9faf6105f` and actual VS25 fresh acquisition/native authentication primary519353 bytes/SHA `4ecb53f064b1e5c48020366fa5256ba620483b7d72b9817854a5746308fdd1de`. Those are parent-reported actual guest results, not this author's experiments. Selected rights and native VM vendor terms were already accepted; this report adds no legal or publication approval.

Canonical migration remains `BLOCKED`. This is a first-party diagnostic, not a production installer/engine implementation. There is no product installation, custom extraction, hand-copied engine, certificate-store modification, unknown latest download or network fallback.

## Frozen interface

| New artifact | Bytes | SHA-256 |
| --- | ---: | --- |
| `D:\AutoClip-Inno-Migration\vm-transfer\vs-admin-engine-probe.ps1` |14415| `b869faec13fd8e71f608418d08aa8a59f2144da20ef8d29e03f5c1fb8394309c` |
| `D:\AutoClip-Inno-Migration\vm-transfer\vs-admin-engine-probe.Tests.ps1` |4845| `f7d642bfe0ede8be4ee976ad7da97b6c24ddaaafa5c2b5b5e3ff365a67d67223f` |

Default emits `READ_ONLY_PLAN`, exit0, without writes, acquisition or vendor execution. The only operational switch is `-RunEngineUpdate`; no destination, manifest, vendor URL, argument or trust-override parameter exists. Operational context must be elevated native64 `autocliplab` before any first-party imports or writes. Root must supply the independent complete observer and externally verify the cold VM/snapshot identity and VBox cable OFF before the explicit operation.

**Do not elevate `-File` against an ordinary-writable driver path.** Root verifies the exact first-party bytes, gzip/base64 embeds them in fixed inline code, verifies the decompressed SHA against the literal frozen hash, then dot-sources the verified text via `ScriptBlock.Create` with `-RunEngineUpdate`. Trusted native system PowerShell runs that fixed encoded command through UAC. The fixture exercises this decoder without the operational switch, plus corrupt-literal-pin refusal. Source14415 bytes compresses to5296 bytes/base64 7064 characters; the resulting UTF16 `-EncodedCommand` fits Windows'32767 character limit. Root owns construction/transmission/elevation of the operational command; no mutable receipt or ordinary script file grants admin-code authority.

## Fixed inputs, locking and protection

Fixed input root: `C:\Users\autocliplab\AppData\Local\Temp\vs cold-65a14b08`. No HTTP/helper GET is performed. Existing first-party helpers are opened with no write/delete sharing, exact literal length/hash checked, text read from the same held stream, and only parsed function definitions imported; helper driver bodies never run:

- `vs-opc-signature-probe.ps1`,12218 bytes/SHA `58fcd8ce1af84f465d29a1eda36be49a244663f89051a1334e8f9d98fddcfc46`.
- `vs-opc-installed-map-probe.ps1`,14416 bytes/SHA `f0b92c001bca4e2792103abfb25068003bda903872a638050729d8b8b2dab2d6`.

Two vendor inputs only:

- `vs_BuildTools-17.14.41.exe`,4473792 bytes/SHA `37bb0fb429d163ecebd272a865d11a37b906d152bef960da2ddb29c2e2fd6eeb`.
- `vs_installer.opc`,50363030 bytes/SHA `62f68d0d6e2adce5cd65f549cbda234358c1cbda442af4de1c3f7ae43fb8b5a6`.

New absent `ProgramData\ac-engine-<random>` root has a protected DACL and **Administrators owner**, SYSTEM/admin FullControl, recipient ReadAndExecute plus native Synchronize only. Recipient owner is deliberately not used: ordinary ownership would allow DACL changes. Exact ACL identities/rights are checked, including the inherited vendor-copy ACLs. Every ancestor rejects reparse points. Sources are hash-verified while held readlocked, copied with CreateNew, flushed and verified, and protected outputs opened/pinned/readlocked through native use; no overwrite or reuse. No vendor executes from the ordinary input root. Native TEMP/TMP and working directory are the protected stage. Stage/engine/system locations are fixed C: paths, not inherited environment selections; PATH and PSModulePath select fixed Windows system locations before cmdlet autoload. Identity is read from the native Windows token, not USERNAME; the executing process must be the fixed native system powershell.exe. Environment is restored afterward.

Normal bootstrap Authenticode Valid/Microsoft publisher, current Online/NoFlag code-signing chain, exact product17.14.41/file17.14.37710.0/original filename are required. OPC native WindowsBase authentication uses the same held protected stream and exact Microsoft DER signer pin, current normal chain and signed-part coverage of raw manifest plus all868 Contents. Inventory requires868 files/131469618 bytes/raw manifest SHA `1ed363d4207dfbb0f0a813558349ce53719f39a0d0fb6710171257bad01de356`; version member121 bytes/SHA `e78a1053a6d59ad60ba8105623181b013c0ffc452216caada2699046f191974f` binds4.10.30.62513. NIC OFF may prevent an uncached revocation fetch: failure stops without NoCheck/import/backdating/offline waiver.

Supported engine/instance directories, both-view SetupInstances and matching VS ARP records are rechecked absent. Native physical adapter inventory must be nonempty and every adapter disconnected/disabled, in addition to root's external VBox OFF proof. This scoped baseline is not proof of every possible nonstandard installation.

## Exact native command and restart policy

Protected bootstrap runs with fixed `--quiet --update --wait --norestart --offline <quoted protected OPC>`. Microsoft documents the engine-only offline bootstrap update and distinguishes it from the subsequent product update. [Network installation update](https://learn.microsoft.com/en-us/visualstudio/install/update-a-network-installation-of-visual-studio?view=vs-2022).

Microsoft's command reference documents `--norestart` paired with quiet/passive for install/update/modify and describes installerOnly as equivalent to `--update`, for preparing clients. Applying the general reboot-suppression option to this engine-only command is the supported documented reading; acceptance by this exact pinned bootstrap parser remains unperformed and must be captured, with no argument-removal retry if rejected. Return3010 is recorded as reboot required, not automatic restart authorization. [Command parameters](https://learn.microsoft.com/en-us/visualstudio/install/use-command-line-parameters-to-install-visual-studio?view=vs-2022).

No timeout kill, retry, reboot request or network reconnect exists. Start-Process returns the exact native parent handle; WaitForExit waits that same handle, including after observer failure. Standard output/error go to complete stage files. Native start/exit, exit code and observed reboot registry signals are recorded. `--wait` is relied upon for the vendor's child-wait behavior; sampling cannot independently prove all children terminated.

## Observation and manual gates retained

Supplemental CIM/process-module polling records newly seen parent/descendant commands, creation timestamps, images, module paths and observation errors. It can miss short-lived processes/images/modules; PID tracking can be ambiguous after reuse. **It is not a complete code trace** and does not authenticate runtime module bytes. Root must arrange an independent complete process/image/module observer before vendor launch, bind actual bytes/normal system DLL provenance separately, and review unknown vendor closure before any next operation. `monitor_complete=false` and `system_module_attribution_complete=false` are explicit in every receipt.

Post-return full installed tree comparison reuses exact pinned map functions against the previously authenticated868 inventory; no path exclusions or altered expectations. Missing/extra/changed output is retained. Exact tree match alone does not prove runtime closure or full installer support.

Full output files, stage/tmp vendor logs/extracted bytes and full JSON receipt remain locally preserved, with hashes/lengths inventoried when readable. No receipt-size cap, network post or truncation applies; large receipts/logs require root chunked transport with complete-byte hashes. Native vendor logs outside the protected TEMP root are **a required root manual collection/review**, alongside any process still alive and complete return/reboot/UAC observations. `vendor_logs_complete=false` explicitly prevents treating this limited stage collection as all vendor logs. Observer/file-inventory failures are retained. Root must keep NIC OFF until deciding terminal/closure state; no script output authorizes reconnect or product transition.

Terminal success means only `ENGINE_EXPERIMENT_RETURNED_REVIEW_REQUIRED` (exit0); a failure preserves stage/error/receipt and exits2. Even exit0 leaves production blocked and root manual gates open. Actual cold engine parser/operation support, elevated ACL persistence/UAC, native process behavior, vendor logs and installed output were **not tested by this author**.

## Focused verification

RED: the new fixture command exited1, `RED: bounded admin diagnostic absent`, before the diagnostic was created. Implementation then exposed Windows' automatic Synchronize bit on ReadAndExecute; the expected allowed bitmask was corrected while retaining write rejection.

Exact GREEN command:

```powershell
powershell.exe -NoProfile -File 'D:\AutoClip-Inno-Migration\vm-transfer\vs-admin-engine-probe.Tests.ps1'
```

Exit0: context rejection, missing/up NIC rejection, admin-owned protected ACL data, recipient write rejection, exact quoted engine arguments/restart suppression, SHA/size drift, actual native readlock write refusal, real CreateNew copy and preserved existing target, mismatch-before-create, read-only default, compressed verified inline default/Windows length bound and corrupt inline pin refusal. Fake first-party payloads only; no vendor invocation or trusted-root import. Fixture temp files are preserved. Production/unit/build/VM checks are not claimed by these diagnostic-only fixtures.

No executable production file or canonical requirement/contract was edited. The requirement is this parent's bounded IM26 assignment; observable production boundaries remain unchanged. Ownership returns to root with the exact snapshot above; later edits require a new snapshot/review.
