# IM-VS-06 — diagnostic guest layout probe preparation

Status: first-party preparation frozen; vendor acquisition and guest execution
belong to the parent. Production Microsoft route remains **BLOCKED**. User
agreement authorization is limited to the specified VM tests, not blanket
production terms. No vendor executable or VM operation was run by this worker.

## Scope and behavior

Prepared only `vs-layout-guest-probe.ps1`, `vs-layout-test-manifest.json`, and
metadata-only copies of the IM-VS-05 inventory/comparator under
`D:\AutoClip-Inno-Migration\vm-transfer`, plus this report. Production helpers,
canonical manifest, server, and other probes were not edited. Applied the
previously read runtime updater/architecture contract and Ponytail Full.

Default execution emits `READ_ONLY_PLAN`, exits0, and performs no downloads,
staging, posting, or vendor execution. Explicit `-AcquireLayout` additionally
requires a 64-hex `-DownloaderSha256` supplied by the parent for its current
frozen production helper. The probe does not hardcode a stale helper digest.
The first-party HTTP transfer serves code/metadata only; every acquired input
is hash checked before execution. Input GET and summary POST use30sec timeouts.

Acquisition creates a fresh short TEMP directory on NTFS, rejects reparse TEMP
ancestors, disables ACL inheritance, assigns current SID ownership, and grants
only current SID / SYSTEM / Administrators FullControl with child inheritance.
The frozen protected downloader acquires the bootstrap directly from the fixed
Microsoft HTTPS URL. Independent bootstrap checks require:

- 4,473,792 bytes and SHA-256
  `37bb0fb429d163ecebd272a865d11a37b906d152bef960da2ddb29c2e2fd6eeb`;
- valid Authenticode with signer organization Microsoft Corporation;
- ProductVersion17.14.41, FileVersion17.14.37710.0, and product name
  `Microsoft Visual Studio BuildTools`.

These identify the bootstrap, not the subsequently resolved installer engine
or installed compiler. The exact metadata and valid signature were separately
observed read-only on the existing host bootstrap during preparation.

The sole vendor command is fixed layout acquisition:

```text
<verified bootstrap> --layout "<fresh protected stage>\layout" --add Microsoft.VisualStudio.Component.VC.Tools.x86.x64 --add Microsoft.VisualStudio.Component.Windows11SDK.26100 --lang en-US --wait
```

No product install, workload expansion, recommended/optional component flag,
silent/passive product command, agreement click, certificate import, security
exclusion, restart, or retry is implemented. `Start-Process` launches the
background layout helper with Hidden window style and redirected stdout/stderr;
it does not supply quiet/passive product flags. The returned PID and exact UTC
start time are persisted immediately as `live-process.json`; `--wait` is the
bootstrapper flag. Polling waits at most45minutes. Timeout records the exact
process still running and exits failure without killing or restarting it.

After success or failure, available vendor layout paths/bytes/SHA-256 and
timestamp-selected `dd_bootstrapper_*` / `dd_setup_*` log copies are retained in
the protected guest stage. Timestamp-selected logs are explicitly labeled as
candidates, not proven PID attribution. Full inventory, comparison differences,
native exit, error and log hashes remain in `full-receipt.json` and
`resolved-layout-inventory.json` locally. An acquisition failure or drift is
retained, not repaired or removed. Inventory during a running timeout is a
point-in-time observation and cannot establish a completed layout.

The verified first-party comparator checks all409 frozen IM-VS-05 layout files
and rejects missing/extra/mismatched/reparse entries. Only verified comparator
inputs may execute, including the observation path after an input failure.
An exact comparison yields `exact_layout_acquired_unqualified`; drift yields
`layout_drift`. Neither status approves production or installs anything.

Only a compact summary is posted to existing
`http://10.0.2.2:8765/processes`; the full inventory is never POSTed. Parent must
preserve the previous endpoint result before execution because that server
overwrites it. A failed POST is reported to stderr; the full guest receipt is
retained. `live-process.json` is the early on-guest observation artifact while
the final POST waits for completion/timeout.

## Frozen inputs and invocation

All four files are first-party code or diagnostic metadata, with no vendor
payload copies:

| File under vm-transfer | SHA-256 |
| --- | --- |
| `vs-layout-guest-probe.ps1` | `2fafe7ac7c5b0fc2e1219fdeae19f7bc88b418234e063416bf916d48bd056bf7` |
| `vs-layout-test-manifest.json` | `1a4ef3085c59b740a866f8652650f3415b1c51c31a59b8e3288fd2e92ab7f7e7` |
| `vs-layout-expected-inventory.json` | `545b140236b4765a964c14708dcbf1e6131497a58c1655be081631b4f8a91397` |
| `vs-Test-Layout.ps1` | `fc7c45a56d5205c765ce7ff55aa1b3fcc92c24086c9eeaabbb8bd986854bc767` |

The test manifest marks this isolated diagnostic bootstrap acquisition
DIRECT_RECIPIENT_DOWNLOAD and `test_fixture_only:true`, while recording
`production_route:BLOCKED`. It does not alter the canonical classification.
Its only redirect host is `download.visualstudio.microsoft.com`.

Parent can inspect the default with:

```powershell
powershell.exe -NoProfile -File .\vs-layout-guest-probe.ps1
```

Parent supplies the full current helper hash after checking the served transfer
copy equals the frozen canonical helper:

```powershell
powershell.exe -NoProfile -File .\vs-layout-guest-probe.ps1 -AcquireLayout -DownloaderSha256 '<parent-verified-current-full-64-hex-helper-hash>'
```

Before typing acquisition, check the probe's full digest above. A final timeout
addition changed the initially inspected `d177e32...` candidate; parent was
notified to use **2fafe7...**. Probe is now frozen; report-only edits remain.

## Executed preparation checks and limits of RED

RED before implementing the new probe: exact path did not exist, so it could
not provide a read-only plan or enforce bootstrap validation. The check printed
`RED: absent guest probe cannot provide read-only plan or reject unsupported signed bootstrap version`
and exited1. This is missing diagnostic capability evidence, not a claim that
a historical vendor executable accepted invalid input. No vendor acquisition
RED/GREEN or guest runtime result is claimed here.

GREEN Windows PowerShell5.1 commands:

```powershell
& "$env:SystemRoot\System32\WindowsPowerShell\v1.0\powershell.exe" -NoProfile -File 'D:\AutoClip-Inno-Migration\vm-transfer\vs-layout-guest-probe.ps1'
& "$env:SystemRoot\System32\WindowsPowerShell\v1.0\powershell.exe" -NoProfile -Command 'function Start-Process { throw "native boundary unexpectedly executed" }; function Invoke-WebRequest { throw "network boundary unexpectedly executed" }; function Get-InstallerArtifact { throw "download boundary unexpectedly executed" }; & "D:\AutoClip-Inno-Migration\vm-transfer\vs-layout-guest-probe.ps1"'
```

Both returned READ_ONLY_PLAN / exit0. The second executes the actual complete
script with native/download/network boundaries set to throw, proving the
default avoids those boundaries. Repeated after the final timeout edit.

Parsed the actual script with
`[Management.Automation.Language.Parser]::ParseFile`, extracted the complete
`Assert-VsBootstrap` function AST, and executed it. The actual host bootstrap
passed its real read-only byte/hash/signature/version checks. Nine behavioral
fixture cases then mocked only native metadata boundaries `Get-Item`,
`Get-FileHash`, and `Get-AuthenticodeSignature`. The valid case passed; wrong
size, hash, trust status, publisher organization, product version, file version,
product name and reparse attributes each threw. This executes real validation
logic rather than checking source substrings. The fixture checks used:

```powershell
$tokens=$null; $errors=$null
$ast=[Management.Automation.Language.Parser]::ParseFile('D:\AutoClip-Inno-Migration\vm-transfer\vs-layout-guest-probe.ps1',[ref]$tokens,[ref]$errors)
$node=$ast.Find({param($n)$n -is [Management.Automation.Language.FunctionDefinitionAst] -and $n.Name -eq 'Assert-VsBootstrap'},$true)
. ([scriptblock]::Create($node.Extent.Text))
Assert-VsBootstrap 'D:\AutoClip-Inno-Migration\vs-layout-26100\vs_BuildTools-17.14.41.exe'
function Get-Item {param($LiteralPath) $script:item}
function Get-FileHash {param($LiteralPath,$Algorithm) [pscustomobject]@{Hash=$script:hash}}
function Get-AuthenticodeSignature {param($LiteralPath) $script:signature}
foreach($case in @('valid','size','hash','signature','publisher','productversion','fileversion','productname','reparse')) {
 $script:item=[pscustomobject]@{Attributes=0;Length=4473792;VersionInfo=[pscustomobject]@{ProductVersion='17.14.41';FileVersion='17.14.37710.0';ProductName='Microsoft Visual Studio BuildTools'}}
 $script:hash='37bb0fb429d163ecebd272a865d11a37b906d152bef960da2ddb29c2e2fd6eeb'
 $script:signature=[pscustomobject]@{Status='Valid';SignerCertificate=[pscustomobject]@{Subject='CN=Microsoft Corporation, O=Microsoft Corporation, C=US'}}
 switch($case) {
  size {$script:item.Length=7}
  hash {$script:hash='0'*64}
  signature {$script:signature.Status='NotTrusted'}
  publisher {$script:signature.SignerCertificate.Subject='CN=Microsoft Corporation, O=Other Corporation, C=US'}
  productversion {$script:item.VersionInfo.ProductVersion='17.14.42'}
  fileversion {$script:item.VersionInfo.FileVersion='17.14.37711.0'}
  productname {$script:item.VersionInfo.ProductName='Microsoft Visual Studio Community'}
  reparse {$script:item.Attributes=[IO.FileAttributes]::ReparsePoint}
 }
 $accepted=$false
 try {Assert-VsBootstrap 'firstparty-native-boundary-fixture'|Out-Null; $accepted=$true} catch {}
 if($accepted -ne ($case -eq 'valid')) {throw ('Incorrect validation: '+$case)}
 Write-Output ('PASS bootstrap '+$case)
}
```

Explicit acquisition with malformed `-DownloaderSha256 invalid` threw before
staging/network/native execution, exit1. The initial test harness treated
expected native stderr as a terminating PowerShell error; repeating with caller
ErrorActionPreference Continue captured and asserted the correct exit1. No
test ran `-AcquireLayout` with a valid hash on the host.

Still unperformed: guest acquisition, actual process wait/timeout, receipt/log
capture and POST, vendor layout `--verify`, actual network endpoint observation,
native agreement UI, installed components and compile/link checks. Parent owns
those observations. IM-VS-05's409-file baseline and IM-VS-03 catalog declared
pin conflict remain unchanged, as do the140 declared-size discrepancies.
Microsoft layout may fetch or update an unreviewed installer engine outside
AutoClip's protected downloader. Exact bootstrap validation does not freeze
resolved packages, engine, or a native installation. A matched layout and even
vendor verification do not reconcile contradictory source metadata. No legal,
blind review, connected-production, or publication approval is established.
