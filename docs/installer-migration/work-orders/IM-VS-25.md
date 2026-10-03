# IM-VS-25 — bounded cold engine acquisition/preflight

Status: prepared and fixture-verified, 2026-10-01. No VM/server operation, vendor download, vendor cryptographic check or vendor execution performed by this author. Own only two new diagnostic files and this report; root owns the clone, contracts and later execution. Prior frozen files and evidence are unchanged.

Parent reports saved clone `AutoClip-Inno-Win11-ColdEngine-20261001`, UUID `f1004585-84b8-42b7-9659-ab74a09c3c76`, from a clean snapshot. This author did not inventory/start it; **do not infer a cold state from that name**.

## Scope and interface

Keep the workflow small: this helper provides read-only baseline inspection and explicit acquisition/preflight. **It has no vendor-launch interface**. The separately documented native engine command remains root-owned, as the assignment permits. No giant UAC/module-monitor/controller or custom engine installation is introduced.

```powershell
# Default: plan only, including when PostResult is present.
powershell.exe -NoProfile -File <verified-probe>

# Read-only ordinary-user baseline; stdout JSON, no stage/download/vendor detector.
powershell.exe -NoProfile -File <verified-probe> -InspectBaseline

# Separate explicit fresh official acquisition and native authentication only.
powershell.exe -NoProfile -ExecutionPolicy Bypass -File <verified-probe> -AcquireOnly -PostResult
```

Each explicit mode requires ordinary native64 unelevated `autocliplab` before writes/network. Baseline and acquisition switches are mutually exclusive. Default remains `READ_ONLY_PLAN`, exit0, no writes/network/post. Baseline checks supported engine directory, ProgramData instance directory, both-view Setup/Instances registry signals and matching installer/product ARP records without invoking `vswhere`, installer code or MSI enumeration. Existing empty engine/instance directories, registry signals or product records stop acquisition; registry access errors fail closed. Baseline is explicitly scoped to checked locations, not a global proof that Windows contains no nonstandard installation. Root must establish clean snapshot/VM/OS identity independently.

## Exact direct acquisition and native preflight

Fresh protected root shorter than80 characters, with a space; recipient owner and protected recipient/SYSTEM/admin-only ACL. No supplied artifact identity, destination, old-cache reuse, host mirror or previous-VM vendor transfer. Current production downloader performs direct official HTTPS acquisition, exact redirect host `download.visualstudio.microsoft.com`, length/hash checks, and safe destination validation.

| Artifact | Bytes | SHA-256 |
| --- | ---: | --- |
| `vs_BuildTools-17.14.41.exe` |4473792| `37bb0fb429d163ecebd272a865d11a37b906d152bef960da2ddb29c2e2fd6eeb` |
| `vs_installer.opc` |50363030| `62f68d0d6e2adce5cd65f549cbda234358c1cbda442af4de1c3f7ae43fb8b5a6` |

Bootstrap URL is the current canonical manifest's fixed official source:

`https://download.visualstudio.microsoft.com/download/pr/bc92e2cb-33de-4a0c-995d-efa817f16b16/37bb0fb429d163ecebd272a865d11a37b906d152bef960da2ddb29c2e2fd6eeb/vs_BuildTools.exe`

OPC URL is the pinned official endpoint retained in IM-VS-02's vendor log/HEAD evidence:

`https://download.visualstudio.microsoft.com/download/pr/e5f740e0-92f9-49d7-ab3b-5d17b84108fd/62F68D0D6E2ADCE5CD65F549CBDA234358C1CBDA442AF4DE1C3F7AE43FB8B5A6/vs_installer.opc`

The new diagnostic manifest is generated from these exact two rows, semantically compared before acquisition, hash-recorded and native readlocked. Its direct-recipient classification applies only to the authorized diagnostic; the production parent remains `BLOCKED`. Hold probe, all first-party controls, generated manifest and downloaded vendor inputs readlocked through preflight. No write/delete sharing. Stage and files reject reparse points and wrong ACLs.

Only function definitions are imported from hash/length-verified first-party helper ASTs; their drivers never run:

- `download-artifact.ps1`,19545 bytes/SHA `75ac92e4108a6fd3165617b2c94be02b44ca86c61a5397672d898eaa38635ad6`.
- `vs-opc-signature-probe.ps1`,12218 bytes/SHA `58fcd8ce1af84f465d29a1eda36be49a244663f89051a1334e8f9d98fddcfc46`.
- `vs-opc-installed-map-probe.ps1`,14416 bytes/SHA `f0b92c001bca4e2792103abfb25068003bda903872a638050729d8b8b2dab2d6`.

Bootstrap: normal Windows `Get-AuthenticodeSignature` must return Valid and Microsoft publisher; native current Online/NoFlag/code-signing chain must pass. Exact ProductVersion `17.14.41`, FileVersion `17.14.37710.0`, OriginalFilename `vs_buildtools.exe` checked. Those resource values were independently read from existing pinned host evidence without execution; their actual guest values still require preflight.

OPC: reuse native WindowsBase package authentication from IM-VS-24 on its held stream; same exact DER Microsoft signer, normal current chain, complete raw868 member inventory and raw manifest SHA `1ed363d4207dfbb0f0a813558349ce53719f39a0d0fb6710171257bad01de356`, all869 required signed parts. Version member is read as data without extraction:121 bytes/SHA `e78a1053a6d59ad60ba8105623181b013c0ffc452216caada2699046f191974f`, installerVersion `4.10.30.62513`. No certificate import/override, NoCheck, backdating, unknown latest, custom extraction or product installation.

Success status is only `ACQUIRED_AUTHENTICATED_COLD_ENGINE_INPUTS_ONLY`. Full primary includes baseline, exact source URLs/control/artifact pins, bootstrap trust/version, complete OPC Contents inventory, signature/chain results/version and proposed argument array. It cannot prove engine installation or vendor acceptance of the cold operation. On failure preserve full receipt and partial root, exit2; no fallback/retry over failed identities. Restore TEMP/TMP and close locks. Full UTF8 receipt ≤1000000 bytes posts `/python-wizard`, compact receipt path/hash `/processes`; root coordinates mutable endpoints. Native independent SHA code can write/hash a failure receipt even if first-party helper transport fails before AST import.

## Focused RED/GREEN

```powershell
powershell -NoProfile -File D:\AutoClip-Inno-Migration\vm-transfer\vs-cold-engine-probe.Tests.ps1
```

Initial RED exit1: `RED: cold recipient acquisition/preflight diagnostic absent.` GREEN after implementation exit0: absent fixture signals accept; existing empty engine and product metadata reject; exact two official rows accept and six URL/size/hash/host/path/extra-row drifts reject; six bootstrap trust/publisher/exact-version/identity data mutations reject; real pinned input read lock blocks mutation and wrong hash rejects; wrong user/native/elevation contexts reject; actual default stays read-only and host acquisition context fails before stage/network. Fixtures use first-party bytes only and preserve unique roots. Bootstrap data guard is fixture validation, not a mocked Authenticode result counted as real vendor trust. Frozen IM-VS-24 native cryptographic fixtures retain their original scope.

No cold VM baseline, official download, current vendor chain or engine operation is claimed performed.

## Exact separate root-owned engine experiment

[Microsoft's minimal-layout guide](https://learn.microsoft.com/en-us/visualstudio/install/update-minimal-layout?view=visualstudio) documents engine-only bootstrapper update with an explicit local OPC. [Its network-update guide](https://learn.microsoft.com/en-us/visualstudio/install/update-a-network-installation-of-visual-studio?view=visualstudio) supplies quiet/update/wait/offline. These interfaces are documented for existing-client engine updates; success on an **absent** engine remains unknown. [The command reference](https://learn.microsoft.com/en-us/visualstudio/install/use-command-line-parameters-to-install-visual-studio?view=vs-2022) makes noUpdateInstaller a prevention/failure control with quiet, so do not append it to the phase whose purpose is installing/updating the engine.

After root verifies actual clone identity/baseline and successful exact acquisition primary, reopen and revalidate inputs under held native read locks, inspect recorded clock/trust freshness, and have root verify the cold guest NIC is **OFF** before any vendor code. Use supported native UAC to enter an administrator PowerShell in that guest. Fixed argument array, using PowerShell's native path quoting:

```powershell
# Both variables are reviewed absolute paths from the exact acquisition receipt.
& $bootstrap --quiet --update --wait --offline $opc
$LASTEXITCODE
```

This helper does not run that command, grant elevation, disconnect NIC or accept product terms. Parent already confirms VM terms/rights; engine-only operation remains separate from native product agreement UI. No product command/component arguments or automatic product transition are permitted.

Root captures the **actual** parent/child handles, command line/elevation/UAC or refusal result, vendor exit/reboot status, all vendor logs, image/module paths and hashes, before/after supported engine/instance state, and any network/update attempt. Observe/wait the same live handles; timeout alone is not terminal and does not restart. Reuse frozen complete `Compare-SeedTree` against all868 authenticated OPC rows after the actual operation. Engine files must match exact closure, and executing vendor code must derive from the authenticated bootstrap/OPC; normal Windows system modules are separately attributable. Unknown vendor source, attempted latest fetch, extra/changed/missing code, product transition, nonzero result or UAC refusal preserves evidence and stops. Do not hand-copy files into Program Files, install certificate roots or reconnect to accept a new engine.

A real cold result is needed before this phase can be added to the conventional Inno wizard. Full product layout generation/verification, interactive MSVC/SDK installation, CPU application and final payload/review gates remain separate. Canonical Microsoft stays `BLOCKED`.

## Frozen handoff

Files under `D:/AutoClip-Inno-Migration/vm-transfer/`:

| File | Bytes | SHA-256 |
| --- | ---: | --- |
| `vs-cold-engine-probe.ps1` |15687| `f0902896fae7f11c95ef997f53d37ceefb4d3717a7ee6df9e6d84d751c9b2211` |
| `vs-cold-engine-probe.Tests.ps1` |5194| `e3e39bae409ae38e9d52ba66d10f12dd66812e2c29528335a5af924c987dda18` |

Serve only the new first-party probe and the three frozen first-party helpers above. Root reviews source/expected identities before transferring/hash-checking and running the explicit modes. No vendor file is served or copied from the host/warm VM. Ownership returned; no subsequent edit without a new assignment or parent coordination.
