# IM-VS-47: direct installed-engine product diagnostic preparation

## Authorization and scope

Parent authorized one external diagnostic and focused tests, following reviewed IM-VS-46 and contract-v1 direct-install qualification. Root owns consent, protected first-party staging, UAC, recipient network and operation. No VM/vendor action, host vendor acquisition, terms acceptance or production file/contract change occurred here. VS45 was unnecessary and no reader was created.

The diagnostic invokes the exact installed engine's default install command with the IM-VS-46 literal arguments. It does not launch a bootstrapper, mutable latest alias or layout generation. Production remains BLOCKED, including after native success. This warm-engine experiment cannot qualify fresh-recipient engine acquisition or the final Inno wizard.

## Frozen files and checks

| File under D:/AutoClip-Inno-Migration/vm-transfer | Bytes | SHA-256 |
| --- | ---: | --- |
| vs-admin-direct-install-probe.ps1 | 20035 | ef7737be4e2ad8667cbe99643fa7ece8575a84e0c3549efbba63924a6e435b49 |
| vs-admin-direct-install-probe.Tests.ps1 | 3689 | fdc6d5d5ec9900845d5c84c1353b9cd05b5da30127554e66a581799df7fee09f |

The path, pin, protected-copy, administrator ACL, connected NIC and file-record functions are reused verbatim from VS40's frozen 7edcaaaa source. Authenticated helper functions are imported as AST function definitions only from held, literal SHA-pinned files; no helper driver executes:

- `vs cold-65a14b08/vs-opc-signature-probe.ps1`: 12218B/58fcd8ce1af84f465d29a1eda36be49a244663f89051a1334e8f9d98fddcfc46.
- `vs cold-65a14b08/vs-opc-installed-map-probe.ps1`: 14416B/f0b92c001bca4e2792103abfb25068003bda903872a638050729d8b8b2dab2d6.
- `vs s-eaff683d/vs-json-signature-probe-r3.ps1`: 20909B/075e882f8af958bc98ad7304970efdd31621bdcec94c478a1478e05c09903973. Root must stage these exact first-party bytes if absent.

Both roots are under `C:/Users/autocliplab/AppData/Local/Temp`. Frozen VS36 JSON authentication primary under the seed parent remains 210068B/ca647e67878cecded40988c12b6e2f6953b2475e01b5b6e284170db5f2755fe4. Exact held Catalog/Channel hashes link to its RSA/CMS/timestamp flags. Existing frozen JSON chain functions recheck both document signer and timestamp chains at current and signed times; no new crypto or trust override is introduced. Signed UTC is parsed from the exact authenticated `gen_time`, rather than attempting to cast serialized `/Date(...)` text.

Source Catalog/Channel/OPC remain in protected `C:/ProgramData/ac-layout-f175f729/layout`:

- Catalog 17954732B/f0a50ea157222c29abd5ea6ff01bfc3c33b04e011c5e45ee2ca38ef0778e5643.
- Channel 91781B/fca418ba94ffbcfb7a2b25f10f16f39dd09660568d21eef4bd3f274cb0b27b8c.
- OPC 50363030B/62f68d0d6e2adce5cd65f549cbda234358c1cbda442af4de1c3f7ae43fb8b5a6. Native package/current normal trust and exact signed raw manifest/868-member closure are rechecked.

Installed setup.exe at `C:/Program Files (x86)/Microsoft Visual Studio/Installer/setup.exe` is 3181432B/f63840dda38637614aa982b94b1d544f0b54026f465c22f78d30765a130a2b73, version4.10.30.62513, Valid Microsoft/current normal chain. Complete engine868 inventory is checked before and after. Selected setup and all input metadata remain readlocked through invocation. Local product root must genuinely be absent, `_Instances` must be absent/empty without suppressed access errors, and native process baseline must have no conflicting installer operation. Root still independently confirms no existing registered instance; `_Instances` observation alone is not universal registration enumeration.

Preserved VS42 PID11228 and any matching native installer process are conflicts. The diagnostic does not kill or retry them. An active VS42 operation blocks this experiment; neither process-name absence nor saved VM state establishes terminal closure.

## Consent and root invocation

Default returns READ_ONLY_PLAN without side effects. Explicit operation requires elevated native64 autocliplab, protected administrator-owned first-party driver, separate `-AcceptSdkVmTerms` and `-AcceptBuildToolsVmTerms`, plus an exact SHA-pinned first-party acceptance receipt. Proposed receipt schema (parent must bind actual authorization, no acceptance inferred):

- `scope`: `VM_TESTS_ONLY`.
- `build_tools_accepted` and `sdk_accepted`: JSON booleans true.
- `build_tools_terms_sha256`: 2f66b86a00e8d9833789897ce23d05a4a2dbea370cf39c8c1098dbc17d0e7bdc.
- `sdk_rtf_sha256`: 0f4a26ac9dc50066f8a1bfeaaf3f092d1b9e4791df5487b9f3c31e7c3dc4d7f5.

The SDK receipt must come from the pending exact consent decision; prior Build Tools acceptance does not establish it. Root supplies reviewed receipt path/hash only after acceptance:

```powershell
powershell.exe -NoProfile -File <protected-driver> -RunInstall -AcceptSdkVmTerms -AcceptBuildToolsVmTerms -TermsReceiptPath <actual-reviewed-first-party-receipt> -TermsReceiptSha256 <actual-receipt-sha256>
```

Native argument array is exactly IM-VS-46: product/channel IDs, absent BuildTools installPath, same local ChannelManifest for channelUri/installChannelUri, local Catalog for installCatalogUri, only VC.Tools.x86.x64 and Windows11SDK.26100, en-US, downloadThenInstall/quiet/noUpdateInstaller/norestart. No wait/noWeb/useLatestInstaller/force. Absolute installed setup.exe uses trusted System32 CWD, system PATH/PSModulePath, fresh administrator-owned ProgramData stage and TEMP/log outputs. Original process handle/start are captured immediately, receipt native identity is materialized before waiting, raw stdout/stderr drain asynchronously; native terminal exit/times are preserved before stream completion checks. No kill, timeout or retry. 3010 is retained as reboot-required without automatic restart; all other nonzero codes fail closed.

## RED/GREEN and limits

Executed on host:

```powershell
powershell.exe -NoProfile -File D:/AutoClip-Inno-Migration/vm-transfer/vs-admin-direct-install-probe.Tests.ps1
```

RED exit1 before source creation: direct diagnostic absent. GREEN exit0 after implementation: exact literal arguments, separate consent refusal, native context, absent-product/instance/conflict refusal, pinned signed-time conversion, real first-party hash/readlock/CreateNew-copy/no-overwrite, administrator ACL objects, actual native cmd exits0/7 preserving original handle/start/terminal times, read-only default. Parser checks passed. No vendor behavior or applied administrator ACL was tested on host. No fake vendor-success assertion was used.

Driver preserves new scoped dd_* log snapshots, full raw stdout/stderr, metadata/engine post-inventories and full local receipt; snapshot read/errors are recorded. Logs/module monitoring are explicitly incomplete. Native zero/3010 only produces VENDOR_TERMINAL_REVIEW_REQUIRED. Root must inspect resolved source/catalog identity despite documented fallback, vendor package validation/publisher/version evidence and any unknown executed-source indication, then independently verify actual product17.14.41, exact VC+SDK component records, SDK10.0.26100.7705 headers/libs, vswhere, vcvars64, cl version and real x64 compile/link/run. Nested acquisitions are not approved by a native exit alone. No whole-machine tracing gate or automatic promotion is added.
