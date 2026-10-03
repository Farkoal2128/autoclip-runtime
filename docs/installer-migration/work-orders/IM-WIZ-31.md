# IM-WIZ-31 - setup completion and ownership evidence map

Status: bounded read-only preparation complete. Only this work order was added.
No implementation, test modification, installer/uninstaller execution, VM or
vendor action occurred. User sequencing is binding: finish and qualify the
production installer, then test its generated uninstaller before release.

## Inspected snapshot and requirement

SHA-256 at inspection:

- `installer/AutoClip.iss`: `af864b5b27db7dd6aa2f429cae5b74b7fa54e9cb750c32a60e0bc37e9ec78cea`.
- `install.ps1`: `2e2372a0c29cfa933eebccb0cb4495a179c3ad249ed747f8f5db048b32edbe2d`.
- `docs/installer-migration/contract-v1.md`: `19642ea7ad255317d25e1c3a46b6d024fea9d6a326bdca455afb8a731daba185`.

Contract-v1:94-103 requires a local installation receipt binding exact setup,
payload, manifest, source, notices and dependencies after ordinary-user health
validation. Source `.install-complete` is one input. Lines183-189 say the health
extension does not replace that final receipt. Lines194-208 require exact owned
files/shortcuts/registrations, preservation of unknown or modified files and
user/shared data, and setup-hash-bound completion. These requirements already
exist; implementation must not redefine a successful marker as final success.

## Producers and native coverage

| Output | Current producer/evidence | Minimum treatment |
| --- | --- | --- |
| `{app}/notices` four files | `.iss`:110-113 normal `[Files]`; builder:167-193 pins notices and exact compiler inputs | Reuse Inno file/uninstall log and known build pins; do not invent another notice extraction pipeline. |
| Start Menu AutoClip shortcut | `.iss`:115-116 `[Icons]`, release-root target/arguments | Reuse native shortcut ownership/logging. Existing install-folder pin concerns another shortcut. |
| Generated `unins*.exe/.dat`, per-user ARP registration | `.iss`:80-95 lowest privilege, fixed AppId, x64 setup; native defaults | Reuse native generated uninstaller and registration handling; no custom ARP or second uninstaller. Generated binary identity must be captured after generation for lifecycle evidence. |
| Release archive files and manifest | `install.ps1`:1252-1282 Expand-Archive and manifest size/hash validation | PowerShell-created files are outside normal Inno file installation. Bind verified archive inventory in final owned-release receipt. |
| `.venv/**`, staged `publisher-wheels/**`, other source-created wheel outputs | source:1310-1440 cache preparation, venv/install, wheel/native work | Need provenance-qualified exact regular-file inventory; eight DLL rows do not cover the environment. Recipient caches outside release stay excluded. |
| Retained `tools/ffmpeg/**` and `.inno-runtime-tools.json` | source:531-601 retained exact tool route; archive helper and runtime-toolpath helper | Reuse existing tool identity checks; include only exact managed release outputs, never temp MinGit/uv or shared tools. |
| `native-build-receipt.json`, `AutoClip.lnk`, `.install-complete` | source:1442-1482 native8 DLL rows, `setup_owned_launcher`, launcher-first marker-last commit | Existing native receipt extensions supply evidence, not full setup ownership. Final producer must bind these generated outputs after actual completion. |
| Durable attempt stdout/stderr/status/health result; MSYS/Python prerequisite receipts | contracted separate protected storage, health pointer source:180-188 | Retain as diagnostics/provenance. Do not treat logs, private build environment, caches or vendor installs as release-tree deletion authority. |

Inno native [Files documentation](https://jrsoftware.org/ishelp/topic_filessection.htm)
distinguishes normal copies from `dontcopy` temporary extraction. Almost every
embedded helper here is `dontcopy`, so its presence in the compiler does not log
the dynamically built release tree as installed files. Native
[Icons](https://jrsoftware.org/ishelp/topic_iconssection.htm),
[Uninstallable](https://jrsoftware.org/ishelp/topic_setup_uninstallable.htm) and
[CreateUninstallRegKey](https://jrsoftware.org/ishelp/topic_setup_createuninstallregkey.htm)
already provide shortcut, uninstaller and ARP mechanisms. The
[UninstallDelete documentation](https://jrsoftware.org/ishelp/topic_uninstalldeletesection.htm)
warns against broad application-directory deletion; adding recursive wildcard
cleanup would conflict with the exact-file preservation requirement.

Native logging alone is not evidence of preserving modified notice/shortcut
bytes. The contract's modified-file rule must also be checked for native-owned
outputs in the later lifecycle assignment; do not claim that native defaults
provide hash-sensitive deletion. Decide a bounded guard strategy there.

## Present completion gap and smallest next producer

`.iss`:875-948 PrepareToInstall runs the pinned source build, then checks marker,
manifest hash and launcher existence. There is **no** CurStepChanged or
ssPostInstall receipt producer in the inspected file. Returning success from
PrepareToInstall precedes the normal setup stage and its native output creation.
The build-side `.receipt.json` (builder:167-193) identifies compiler inputs and
output exe; it is not a recipient installation receipt.

The next authorized implementation should add one bounded final producer invoked
after native setup outputs exist (the ssPostInstall event is the documented
post-install boundary in [Inno event documentation](https://jrsoftware.org/ishelp/topic_scriptevents.htm)).
Reuse the existing verified source manifest, native launcher/health evidence,
exact compiled pins and native registration mechanisms. Bind the actual setup
exe hash, release/payload/manifest/dependency identities, recipient/root/profile,
validated health evidence and exact additional owned release outputs. Refuse
missing or conflicting evidence and propagate producer/write failure before
claiming final success. Do not mutate immutable source recipe/archive or make
the source marker carry setup-shell success.

Define the small receipt schema/path and its own evidence-container ownership
explicitly before production edits. A receipt cannot recursively hash itself;
do not silently invent self-inventory semantics. Native generated outputs and
runtime outputs should have distinct scopes within that one record, with empty
directory cleanup limited to recorded owned paths. No implementation is
authorized by this preparatory document alone.

## Partial-tree provenance conflict to resolve first

Source:928-940 recognizes an incomplete root by matching release-manifest hash
and absent marker. Source:1288-1304 rejects unexpected files except complete
`.venv/` and `publisher-wheels/` prefixes, native receipt, authenticated launcher
and retained FFmpeg outputs. Those broad prefix allowances permit an unrelated
regular file under an accepted prefix to survive a retry. They are retry
allowances, **not ownership evidence**. Also archive extraction precedes that
scan (1252-1253). The native receipt `installed_files` added at1442-1451 contains
only eight native DLLs; it does not authenticate every existing prefix file.

Consequently a final recursive scan after successful retry would promote any
pre-existing allowed-prefix file into setup ownership, contrary to preservation
requirements. Minimum safe initial scope is a proven fresh release root plus
producer-owned outputs. For partial retries, require prior exact producer
evidence for retained dynamic files or fail closed while preserving them;
the parent must settle that behavior and its contract/test impact before
implementation. Do not infer provenance from path prefix, owner SID, matching
manifest alone, successful health or marker presence. A required ownership
producer cannot bypass this conflict by claiming the entire tree.

## Focused behavioral RED proposal and reusable checks

Use the lowest executable first-party filesystem test, with fresh protected
staging, fake inert regular release/venv/tool files, actual manifest pins and a
real COM-generated fixture shortcut. No vendor/install/health process is needed
for this inventory test. Invoke the actual new producer boundary with explicit
bound terminal evidence; before its implementation demonstrate missing final
receipt as RED. GREEN must prove root/setup/payload bindings, exact file bytes
and hashes, and exclusion of an injected unrelated file. Negative cases: changed
pin, duplicate/traversal path, reparse descendant, foreign writable receipt,
receipt-write failure, missing terminal health evidence, and a partial root
containing `publisher-wheels/unrelated.txt` or `.venv/unrelated.txt`. That partial
case must be preserved and refused or independently excluded by prior evidence,
never silently listed as owned. These are proposed tests, not executed results.

Reuse `InstallerCompletion.Tests.ps1` actual-AST action, real shortcut, marker
failure/retry and foreign-output fixtures; `InstallerBuildAppHealth.Tests.ps1`
bound-result fixtures; `InstallerBuildProcess.Tests.ps1` terminal status and
commit binding; `InstallerBuildStorage.Tests.ps1` protected regular-path/DACL
patterns. Existing `InstallerMsys2Wizard.Tests.ps1` extracts actual
PrepareToInstall with inert final RunSourceBuild boundary, but does not prove
ssPostInstall or runtime inventory. Its compiled fixture execution was previously
refused: reuse extraction/compile-only patterns subject to parent authorization,
do not execute a refused fixture as an alternate route. Existing source helpers
`Read-AutoClipSecureInput`, `Assert-AutoClipSecurePath`,
`Assert-AutoClipMsysProtectedPath`, `Get-AutoClipLauncherPin` and
`Write-AutoClipCompletionFile` offer established validation patterns; keep their
scope and ordinary-user authority limits.

After producer GREEN and exact production installer readiness, parent should
assign generated-uninstaller behavior and then run the user's required actual
uninstaller test on that exact ready installer. No uninstall testing occurred
in this work order; readiness and release remain open.
