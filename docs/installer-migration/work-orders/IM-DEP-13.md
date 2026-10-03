# IM-DEP-13: exact publisher CPU Setup candidate and blocked review

Date: 2026-10-02. Root produced the first consumer successor from the exact
r18 application (75 publisher wheels), qualified r2 native component, current
controlled bootstrap/helpers and the preserved original distribution review.
Production used `scripts/build-publisher-cpu-release.py` with explicit input
hashes; the actual CPU installability verifier passed (1,152 indexed members,
75 publisher wheels, three external assets). The guarded `scripts/build-inno.py`
then compiled the complete CPU Setup with Inno Setup 7.1.0.

## Immutable r1 identities

Files under `D:/acpu-1002-3343baed/consumer-release-r1`:

| File | Bytes | SHA-256 |
| --- | ---: | --- |
| autoclip-publisher-cpu-v41-r1.zip | 225926390 | 47c807bf054b433be1c316bb18005f506ce85e62f48ddf1e93b2b566782bec19 |
| installer-dependencies-cpu-v1.json | 36460 | 7f87431aa6c330ce0837a47d3a087e38526dea7ca5dac3c8ea1a058c9551edfb |
| install-publisher-cpu.ps1 | 425197 | 3e29d4d787acfe8e7b15f3681ee0a48e5a4e26dc4abd09147bdb62b7015f157f |

Setup under `D:/acpu-1002-3343baed/inno-cpu-candidate-r1`:
`AutoClip-Setup-v1.exe`, 3407499 bytes, SHA-256
`5895fc24aa18a984d6f28f00db5c2fd5395eb2ae8141a8426b550b26c158b5c5`.
Its build receipt remains `UNVERIFIED_CANDIDATE`.

The unchanged qualified native component is 66665645 bytes, SHA-256
`46ee07feb45b12e31c83fd49283f2053c729ca6f2073326b11a036d7c609f437`.
CPU requires no recipient Build Tools, SDK, MSYS2 or Git. NVIDIA retains its
separate source route and unresolved Microsoft dependency rows; its hardware
tests remain deferred. Historical v40 and its blocked CPU graph are unchanged.

## Actual blind review

Frozen 30-file packet:
`D:/Projects/autoclip-runtime-evidence/IM-DEP-13-cpu-candidate-r1`.
Packet manifest SHA-256:
`dd11208e8fa986cb1e7d456c4a89ba9255feac68ffd7d977b5d2978caa5b908d`.
Fresh-context read-only review independently checked every row and inspected
the actual source/EXE metadata. It stopped at its first concrete blocker:
CPU displayed NVIDIA terms and required Microsoft consent even when the
Microsoft runtime was already valid. No remaining review boundary was approved.

Separate review under `D:/Projects/autoclip-runtime-evidence/IM-DEP-13-review-r1`:

- `review.md`: 026c3d8865dccb99abe1389b97a7374c9164e1c46207bb45e4df8871e4bc26ad.
- `checks.json`: 3d6ac1fac573af33c4b7a6d3c39245799a9fe519ff98e15d246b37f7ebcaac76.

Root read the full review and verified its hashes. This is same-session internal
independent technical review, not external/human approval, legal advice or
publication authorization. IM-DEP-14 records the compiled behavioral correction;
root independently reran its focused test successfully. A newly frozen candidate
and fresh review are required. r1 bytes and their blocked disposition remain intact.

## Remaining work

No complete Setup was executed in a VM, no generated uninstaller ran, and no
publication occurred. Clean recipient install, real CPU transcription/media/
render/health, installed notices/source, failure and lifecycle checks remain.
The user explicitly resolved uninstall actor scope on this date: stop AutoClip
and its updater, check owned files and preserve anything modified or unknown.
IM-UN-06/07 implement the receipt consumer and native hook; the earlier stronger
unrelated concurrent-writer interpretation is not a production requirement.
Retain existing ADS checks and preservation tests. Test the exact generated
uninstaller after the production installer works, then release when sufficient.

## Fresh consumer r2 and pre-VM review

The r1 candidate is preserved. IM-DEP-14 fixes its consent failure. IM-UN-08
adds verified native prelaunch ownership because Inno holds DAT exclusively
before either cleanup callback. Root repeated the compiled uninstall diagnostic,
actual cleanup CLI regression and actual positive/negative Finalize CLI checks;
all passed. Those fixtures do not qualify a generated uninstall lifecycle.

New files under `D:/acpu-1002-3343baed/consumer-release-r2`:

| File | Bytes | SHA-256 |
| --- | ---: | --- |
| autoclip-publisher-cpu-v41-r2.zip | 225946870 | dbee7e0dee9de62823a0bab869d4bd132173874a03d03d92fdee396e6cdfc46c |
| installer-dependencies-cpu-v1.json | 36460 | 2f34273e00347c90437303be88586eefb773022de0ec17e4e2b5bb6043268fda |
| install-publisher-cpu.ps1 | 425197 | 10ecee948a5c757b842835fc3806c9476e191d5133a855cac7c85770f9127465 |

`D:/acpu-1002-3343baed/inno-cpu-candidate-r2/AutoClip-Setup-v1.exe`:
3430296 bytes, SHA-256
`fafc1f92066325a68e59eb3acee05d0fc30921727aefc4c3b991308e75091e77`.
Build receipt SHA-256
`7a2a9b3bb5c4fc50fd5053620111e9f6a2132f5a808c784ed3497dfead3c5f9b`;
it remains `UNVERIFIED_CANDIDATE`. Qualified native r2 bytes are unchanged.

Root's exact CPU installability command includes `--native-artifact` and
passes: 1154 indexed release members, 75 publisher wheels, three external assets.
An initial root invocation omitted that argument and correctly failed its
actual-native-artifact requirement. An initial producer invocation used shortened
review filenames and failed before outputs; the corrected invocation uses the
unchanged exact component-distribution review/disposition hashes. Neither
failure led to a requirement bypass or rebinding of historical evidence.

Fresh read-only packet:
`D:/Projects/autoclip-runtime-evidence/IM-DEP-13-cpu-candidate-r2`, 73 files;
manifest SHA-256
`0f91f0cf1a517b263a82f859f344206714ddf4c47ea45cdb8d0a50989d32d868`.
A new reviewer receives no prior turns or memory. Its scope is eligibility for
the authorized VM tests. Installed application, generated-uninstaller lifecycle
and publication acceptance remain pending.

Completed separate r2 review returns `ELIGIBLE_FOR_AUTHORIZED_CPU_VM_TESTS`.
Root read its full methods/findings, verified the review artifacts and repeated
all 73 frozen-file hashes. Review SHA-256
`4e39f77c2dff32a28cb21cf8ff9fc808eea561c52b2bb385cfffcabb329abffd`;
checks SHA-256
`869f85c8d5bc3a6c4f9ef868fd548db0503787ac003da1f922cadad9fc792c16`.
The unchanged builder suite passes all 14 checks in byte-identical writable
TEMP copies. The initial frozen-attribute fixture failures remain recorded;
no assertion was changed. This is same-session internal independent technical
verification at pre-VM scope; no external, human, rights or publication approval
is inferred.

## VM baseline and first-party media

Fresh test VM `AutoClip-PublisherCPU-Win11-20261002`, UUID
`b0f1491c-9f7e-4a00-ac43-26bae99fc5c1`, uses 8 GiB, six CPUs, NAT and no GPU
passthrough. Pre-install snapshot:
`c687a818-d1dd-4150-b2ef-984d795c81f6`. Native USB tablet input resolves the
earlier mouse problem; the native VirtualBox soft keyboard provides guest input.
Current Windows Programs and Features visibly lists exactly Edge, OneDrive
and Remote Desktop Connection. Program Files contains ten stock directories.
`Windows.old` exists: this is a current-installation baseline, not a forensic
empty-disk claim. Guest Additions are absent. Setup prerequisite probes still
must establish the actual capability state.

Primary UI/configuration baseline under `D:/acpu-1002-3343baed`:
`vm-cpu-baseline-20261002.json`, SHA-256
`7a116f9fdc0b52351c80cdafd5ec5c24d2d4c8cb30340a74e0a9b33e9fb7955d`.
First-party synthetic speech/video lives in `vm-media-fixture-r1`;
fixture record SHA-256
`df139ead19dad2cc9021d929c0c5bf1572643fb90f9e313646b3b3a232efc173`.
The 27.005079-second WAV uses the existing Microsoft David voice. Host-only
FFmpeg encoded the 640x360 H264/AAC source; duration/audio/video checks pass.
No host encoder is transferred. Source MP4 SHA-256
`09631a9e21297376802a298562ff89ad0e464479ba87ce916d916b1764223c52`.

A read-only native VISO carries the exact r2 Setup, exact candidate/native
archives for protected cache qualification, and owned test media. Mapping
SHA-256 `41046034dc12272c515dfc9f8cdca64d38680e72125183630f4d52b83d077e7d`.
The public release URLs are still unpublished; local cache testing cannot prove
public delivery. No AutoClip Setup, vendor installation, generated uninstaller
or release was executed during this preparation.

## Actual r2 wizard run in progress

On 2026-10-02 at approximately 20:44 UTC, root used the normal guest UI to
advance the exact reviewed r2 Inno Setup. CPU remained selected. The actual
prerequisite summary passed. Attempting to advance the Python terms page
without its checkbox produced the expected refusal. Root then applied the
user's existing Python and Visual C++ Runtime consent for VM tests only;
the CPU Microsoft page required no compiler or SDK consent.

Guest Explorer copied the two exact candidate ZIPs from the read-only DVD
into the active Inno scratch directory `is-W2ACQEC54M.tmp`. This qualifies the
private verified-cache route, not unpublished public release URLs. The actual
Python.org 3.11.9 x64 progress UI showed Standard Library installation. Setup
subsequently entered its protected-download and CPU runtime installation page.
Completion, installed application checks and the generated-uninstaller test
remain pending; no complete installation or release is claimed here.

The run subsequently failed before runtime staging with `Unexpected verified
FFmpeg executable path.` at `install.ps1:613`. Durable attempt:
`C:/Users/autocliplab/AppData/Local/AutoClip/Setup/logs/source-build-is-W2ACQEC54M.tmp-1`.
Live failure snapshot `1aa65bfd-5bc2-421c-b01a-574006bb9661` preserves this run.
IM-DEP-15 reproduces the exact error with the actual archive and a genuine
Windows short TEMP path; it normalizes the existing TEMP directory once.
Root independently repeated its actual integration test: PASS, exit 0.

New immutable r3 keeps every native/vendor/helper pin and the source release
base. Canonical bootstrap SHA-256:
`444d86dcd7dbbae71af6a285a58693c11bfc72a9f3f70b537b696f0a3f6b7cba`.
Under `D:/acpu-1002-3343baed/consumer-release-r3`, the ZIP is 225946871 bytes,
SHA-256 `6f1e6b90f6ff6b1f9e9ebe28d67bb2572ff264c6c04f18b68cbfd3ca4c2cfdb4`;
manifest SHA-256 `e7be6f17c6ecf3bbe345ad9b90b3b6667631c67d9664490c412f1ca8142fda07`;
generated bootstrap SHA-256
`813f06276fbddc5f4d3f5f185937e3ffea3b32a81bb413e4a3a2797fef13cf73`.
The actual required CPU graph passes. New Inno candidate in
`inno-cpu-candidate-r3` is 3430304 bytes, SHA-256
`5ddfcb936f2fce00fef22c362898a67b803fccd10f608e02f6cd232fe0948670`;
receipt SHA-256 `79ea046b4e3b67f14b27846fe7beb408b849ed0baec8f87e45c927f786ad095b`.
Its review, corrected VM run, application and uninstaller remain pending.

## r3 technical review and actual retry

Fresh blinded same-session review independently verified all 75 frozen inputs,
the actual required CPU graph, 55 distinct Python tests, compiled consent
diagnostic and genuine short-TEMP FFmpeg integration. Disposition:
`ELIGIBLE_FOR_AUTHORIZED_CPU_VM_TESTS`; no blocking findings at that scope.
Review SHA-256: `cc69d7e02585ee0d631a31fb6f0a04ec59fec351f9dcca431a67ade871662f08`.
Checks SHA-256: `4383607da89950a084834721835183a17dafb8dfd7b7ff80186978c9f6573a2d`.
Outputs remain under `D:/Projects/autoclip-runtime-evidence/IM-DEP-13-review-r3`.
This does not close actual Setup/application/uninstaller or publication gates.

Root launched the exact reviewed r3 Setup in the existing failure-recovery VM
on 2026-10-02 around 21:14 UTC. CPU remained the default. Preflight passed;
the exact installed Python from r2 was reused and its consent page skipped.
The CPU Microsoft page requested only Visual C++ Runtime terms. Root applied
the user's existing VM-only consent. The two exact candidate archives were
copied through guest Explorer from the read-only r3 DVD into active Inno
scratch `is-KY4LZUIX00.tmp`; protected verification remains enabled. Installation
started around 21:18 UTC. This is a retry test, not yet a clean-baseline result
or public-download qualification. Actual completion remains pending.

The actual retry subsequently failed with `Protected downloader returned
unexpected bytes or path.` at generated `install.ps1:572`; root read the
durable stderr in guest Notepad. Source staging now exists, unlike r2's earlier
FFmpeg failure. Live snapshot `c664d611-50fa-49a9-9726-9782db8cdda5`
(`PublisherCPU-R3-Worker-Failure-20261002`) preserves the attempt. Its frozen
disk identity is `53df7bbf-bec6-40e6-9d03-6c309fa66f0b`. IM-DEP-16 investigates
the shared protected download caller's short-TEMP path equality. No complete
Setup, generated uninstaller or release is claimed.

Root exported the frozen r3 disk through native VBoxManage and extracted only
six attempt files with the existing native 7-Zip GUI. Primary record:
`D:/acpu-1002-3343baed/vm-r3-failure-primary/primary-manifest.json`, SHA-256
`1e81ed879e815be234dcda5537c9712c9df7bc80989aa082ffbfe812d54cb80f`.
Actual 510-byte stderr SHA-256:
`59aba20fa2857c2b792106c520f58bda85518e083fbee821aabb32d9b33e5cca`.
The staged source manifest SHA-256 is
`62bc44b824d5e1c2dc3bae119c1f7f86fc0b0e472d5d2b8b1a626df2a57354d9`.
The live snapshot's disk view contains a zero-byte `status.pending`, whereas
guest Explorer showed `status.json`: no terminal-status claim is derived from
that extracted file. Copied bytes do not establish preserved ACLs.

IM-DEP-16 reproduced the actual downloader guard failure through the immutable
archive's real callbacks with genuine Windows short TEMP. Normalizing the
existing TEMP root at shared download staging fixes all four caller paths;
root independently repeated the focused test, exit 0. Helper/vendor pins and
strict destination/size/hash checks are retained. Canonical bootstrap SHA-256:
`f007bb27712a617c750f6fbee4dd911d2574b57538d2bcbe7a8ae0769ef1cb8e`.

New immutable r4 under `D:/acpu-1002-3343baed/consumer-release-r4`:
ZIP 225946868 bytes / `ad6ad00f082078d2f1be487a27189f93785114cd931a19e781bc967e95072b4b`;
selected manifest / `c5eec23b665915ea5f9e1e0f554f93d0ccf030e00d1d2f5df194ac65c485a85f`;
generated bootstrap / `6947b96b8f4dc3756465190580f17b191d0771eb9cd4d8fcf40b82ed4b9922f4`.
Actual CPU installability graph passes with the unchanged exact native r2 ZIP.
Inno candidate under `inno-cpu-candidate-r4`: 3430289 bytes /
`0c7f3130eb7e6a82d57e4eb7104349aa8e1f0acac8d39aa7155f6e48cb24b329`;
producer receipt / `cb9a17bb8913f0cab09ba6b59c3d915d037dba3645b3777e62663fd11a245f5b`.
Fresh blinded pre-VM review packet indexes 77 verified frozen files; manifest
SHA-256 `49d25dbcedeaf811504819ba166ee115e52ff76f1e819029f4eab6094e1cf9f4`.
Actual corrected r4 VM confirmation remains pending.

The first r4 technical review independently passed its checks but disclosed
historical-verdict exposure in this work order; it does not close a strict
blind-review gate. Root froze a separate objective packet containing 65 exact
source/binary/contract/policy/notice/test inputs, excluding producer work orders
and generated bytecode. Manifest SHA-256:
`158847a06dda24d640e9324fcb8c5c9fca24f3c7bb82b924a3976a28c6580956`.
Another fresh reviewer verified all65 inputs before/after, actual CPU graph,
short-TEMP acquisition and FFmpeg, consent/receipt checks, and independently
recompiled the exact matching Setup EXE. Disposition:
`ELIGIBLE_FOR_AUTHORIZED_CPU_VM_TESTS`.
Objective review SHA-256:
`5f78972ab4ef1ecdcda528ff2252b23bd9f1faf817775c3bd5c20a69c3aff51e`;
checks SHA-256:
`8a8fdba55f4b21ee02a7ef86e77e5511b010ebcbc9a94d415905ba0321d8ab14`.
Root read and rehashed both outputs. This is internal technical verification,
not complete installation, source/public delivery or publication approval.

Root retained the two failed-run VM snapshots and created a separate linked
clone from the untouched pre-install snapshot for clean r4 qualification:
`AutoClip-PublisherCPU-CleanWin11-20261002-r4`, UUID
`1028c2e7-9e40-49cf-9703-cc17f4a4e664`. Its initial 8GiB boot paused with
`HostMemoryLow`; root changed only that new test clone to4GiB and restarted
before Setup. Windows reached its normal desktop and exact r4 DVD.
Baseline record `D:/acpu-1002-3343baed/vm-cpu-r4-clean-baseline.json` SHA-256
`bf6659517ce7a4589a5109e71680822b78007281cc6d1fe7923daec1e6245c41`.
R4 DVD mapping SHA-256:
`bf2f28455dbf7a4fd68da35f75ec6cb39dddc7ba0d73ef033be763e031e7e757`.
Root began launching the exact r4 Setup through normal guest Explorer around
21:43 UTC; all actual acceptance checks remain pending.

The actual clean r4 wizard passed preflight, detected missing Python and
requested its versioned terms, followed by Visual C++ Runtime terms only.
Root applied the user's existing VM-only declarations. Guest Explorer copied
both exact candidate ZIPs into active helper scratch `is-XTQUV32S8X.tmp`;
the launcher-only scratch `is-ST2OV7KWAQ.tmp` was inspected but not seeded.
Root clicked Install around21:50 UTC. No toolchain, MSYS2 or NVIDIA consent
was requested for CPU. Completion and application/uninstaller acceptance
remain pending.

## R4 cancellation and immutable r5 successor

Actual r4 stopped at native VC elevation with a665-byte stderr read in guest
Notepad: `Protected VC preparation failed: unresolved; This command cannot be
run due to the error: The operation was canceled by the user.` Frozen live
snapshot `c0e7ac9a-1efc-493f-a660-a6d736374b89` retains that attempt.
IM-DEP-17 corrects native launch error preservation with a real missing-file
RED/GREEN and inert cancellation/unknown-launch state checks. Root independently
repeated `InstallerVcRuntime.Tests.ps1`, exit0. Actual successful VC execution
and complete Setup are still pending. User will handle native UAC prompts;
Computer Use cannot approve security permissions.

Root resumed after the requested pause. D: was full and VirtualBox had paused
with `BLKCACHE_IOERR` / `VERR_DISK_FULL`. Root native-moved the unattached r2 VHD
to `C:/AutoClip-VM-Evidence/publisher-cpu-r2-failure-evidence.vhd` and verified
identical SHA256 before/after:
`bb9b846487b53235d4f30844b08129f7e8919754377cb0788d57cc33a6bb35bf`.
Its medium UUID remains `50db5ee5-a591-4788-a37a-96a7c89cd93b`.
Immutable relocation record SHA256:
`b1611be228fd88b03e99601591fce06ba4b9f6fd2c9862ed1607b3c3913f3eda`.
Historical receipts remain unchanged. Root resumed the failed VM, closed Setup,
requested ACPI shutdown, then powered off this owned test VM after it remained
running. Its preserved snapshot was not removed.

New immutable r5, under `D:/acpu-1002-3343baed/consumer-release-r5`:
ZIP225946963 bytes / `338cec2b9499c26d2fac10ba4905bfa21b65ae91c7b03c77f983a52f4f05c698`;
manifest / `524dc30641d03a11b4ebce9cf422831d26316d753d077114d4e3fe11cc0564f4`;
bootstrap / `974fddd60fb5df7286f4a3b22811de32756f924038b07fdf8175c0c0be3f2608`.
Actual CPU graph passes1154members,75publisher wheels,3external assets.
An initial producer invocation reached validation but wrote no outputs because
root omitted the new parent directory. Root created it and repeated successfully.
Native r2 component is unchanged. New Inno Setup SHA256:
`a166e1481178fd822d8d0f7dd70ada9922ac8b66e1ed0bc30194ee199a9e64d6`;
receipt / `f1b5dd3170b8382527ebea08633f3c86af30826cccef6032ae94758a26586c7c`.
Its state remains `UNVERIFIED_CANDIDATE`.

Objective review packet indexes69read-only files, excludes producer work orders
and previous Setup verdicts, and includes four added VC/runtime/wizard tests:
`D:/Projects/autoclip-runtime-evidence/IM-DEP-13-cpu-candidate-r5-objective`,
manifest SHA256 `026159c346efb096532111429b46168ff6ff56a8e490b7d8469d236b7f1b94dd`.
Fresh `blind_cpu_r5_objective` owns read-only pre-VM review of exact source,
contracts, notices, policy, bytes and tests. Allowed test/build scratch only;
no VM/vendor/security/release actions. Root owns integration and actual VM.
Actual per-run model telemetry is not exposed. A new linked clean test VM,
UUID `7b5f6662-5e6f-459f-8aa0-2bcb01bb9146`, derives from the untouched
pre-install snapshot. Its discarded memory was only the new clone's copy.
The baseline disk still performs Windows installation before reaching desktop;
no AutoClip Setup is launched until baseline and exact technical review pass.

Root additionally native-moved the unattached r3 VHD to
`C:/AutoClip-VM-Evidence/publisher-cpu-r3-failure-evidence.vhd`, retaining UUID
`e3bba1d6-eb35-4600-92d1-b41c11fe20d7` and exact before/after SHA256
`168cfd8488fb1f52f431491add42f128939326004d899583a920dbde4eee96ab`.
The initial move refused a sharing violation while the native7-Zip viewer held
it open. Root closed that viewer normally and completed the move. Relocation
record SHA256 `62431bbad1b4b2ca2d585c61cb44b7fa151ec901aae693360b781a7f54e75a69`.
R5 reached Windows desktop; root saved live clean-desktop snapshot
`e7dc20d9-4dc2-4355-8c15-6127ced3fbd4` before any AutoClip Setup.
Baseline record SHA256 `0a8d0bf6dc14d840b5da2e071309254b9475cf1e0d7af06bbfbb59a5dbf74807`;
exact read-only r5 DVD mapping SHA256
`fc31538563f3f8858b1b2d83261f15212be7c231a52300d449d281a1ecdf1981`.

Fresh r5 review is `BLOCKED_PRE_VM_TECHNICAL_VERIFICATION`: integrated receipt
cleanup failed at exact current-selection removal. Report SHA256
`d9774bb4e6d391a6bce6586938d21067a472142440b3c3064adf4b55fcb0c534`;
checks SHA256 `fc1dda812962035dbec91180541301eefadc109fe7dbaedacee090b3f035fdd6`.
Root read and rehashed both. Exact Setup independently rebuilds byte-identically;
77Python and9PowerShell suites passed. All69indexed inputs remain unchanged.
The verifier created an unindexed Python cache in the packet; automatic policy
rejected its removal, so it is preserved and explicitly documented rather than
retrying that cleanup. IM-UN-09 investigates the callback failure. Root's
independent same-packet/same-command/same-cwd reproduction passed, but that does
not resolve the failed review. No r5 Setup launch or eligibility claim yet.

IM-UN-09 could not retrospectively recover the original removal status. Root's
same-packet reproduction and two instrumented native workflows passed; the
historical failure remains unresolved. A bounded diagnostic correction now
retains `outcome=<finite status>` in the refusal. A real first-party read handle
holding exact active.json bytes demonstrated meaningful RED for the old generic
message, then GREEN for `outcome=LOCKED`, with selection/release preserved.
Subsequent normal cleanup and all safety assertions remain enabled. Root repeated
the final focused test including retained diagnostic copying: PASS0, fixture
`autoclip-uninstall-receipt-d0ff218b853a46349ced82543b43b410`.
New consumer SHA256 `127aabd282226510929a810c6997a870ae4f9cf6821a11757a8a36f740f0a305`.
The controlled LOCKED case is not proof of the original review failure's cause.

New immutable r6 in `consumer-release-r6`:
ZIP225946988 bytes / `80207dbd800d68b5e4ec2a6bd9596bc4d48b12743230afcd10eba753e34e4892`;
manifest / `d0dd8d58ef6e3815bde608857daf9a92218a9f2bbf0d10ff4b95e7189c292ea5`;
bootstrap / `40b915f45d81990e0237877d9f2a91d0e7bdd4f69650dc5811f17d6f638848d3`.
CPU graph remains PASS1154/75/3 with unchanged native r2.
Inno Setup / `06a614aa3281c8ab78a58a63ae6e256a30eca85de446ae4d5158100373a192f2`;
receipt / `1a7495683dcdf1271b9d0d2b27fe646dc7d04be5c1079055f844e19be647767a`.
Builder still writes `UNVERIFIED_CANDIDATE`.

Fresh objective r6 packet indexes70frozen files, including the exact immediate
base archive in addition to source/binary/contract/policy/notices/tests and scoped
component qualification. Manifest SHA256
`bdc5ee47015bca488d3b5bfc4cc7ef653cef27f54af64fe0ec30a35999def1e0`.
`blind_cpu_r6_objective` owns fresh read-only technical review, without prior
conversation, session memory, producer work orders or other Setup verdicts.
Only independent writable test/build scratch is allowed; no VM/vendor/security/
publication action. Actual model execution telemetry is not exposed.

Root paused the idle clean r5 VM while code verification runs to bound unused
disk growth. It still has no AutoClip Setup execution. The exact r6 read-only DVD
is mounted there; mapping SHA256
`27029d669b3a03661f9ef7762539bd278216037ed30338d2867fc4a76e712d4a`.
Native NTFS compression of the two relocated unattached VHDs is in progress,
preserving logical evidence bytes; final result and hash checks remain pending.
No historical disk/archive/snapshot was deleted or rebound to new claims.
Root received, read and rehashed the completed fresh r6 review. It is
ELIGIBLE_FOR_AUTHORIZED_CPU_VM_TESTS only, with no blocking finding in the
performed scope. Report SHA256
`52040d1e94e7cd5b0f78545f6c212f9798284c78df417e4162153be42febb24a`;
disposition `bd0c7f51925dab1c3876aa10f57cde8d94f06613731bc20f4be5ab4b5594c665`;
checks `7298b180523ff926abeae12d70ad0a8e07d45cd6b9b5b87e012199deb465630d`.
All70packet files remain unchanged. Twelve relevant native PowerShell tests
passed; exact independent compile reproduces r6 Setup. Actual immediate-base,
native wheel/PE/source/notices and source-bundle checks pass within stated scope.

Native NTFS compression completed for the two relocated unattached VHD exports:
46807647232 logical bytes,39780577280 stored. Root rehashed both complete logical
files afterward: original r2/r3 SHA values unchanged. Read-only record
C:/AutoClip-VM-Evidence/vhd-compression-20261002.json SHA256
`a43e0e2b63941c6f658ef59e31ce92d50b773ba6b9346b72b379cbedcd8c76fa`.

Root resumed clean r5 VM and launched exact r6 Setup from its mounted DVD.
Observed actual CPU default, preflight, Python and Microsoft VC consent pages;
applied existing user VM terms consent. Python.org3.11.9 native UI installed.
The unpublished candidate URL was refused before root finished copying its
private cache; root used normal Explorer to seed only exact r6 and native r2
ZIPs under active is-K88ODTF60A.tmp. A redundant second paste was skipped.
The installer retains pin verification. Normal Back/Install now retries.
This private cache run does not establish public delivery or a complete install.
Actual generated-uninstaller testing remains after successful installer/app work.


## Actual r6 vendor success and new r7 candidate

The r6 VM reached official Python and Microsoft VC installation. The VC
native wizard reported success and its helper observed exit 0; AutoClip then
refused the DLL capability check. Explorer reported the System32
vcruntime140.dll signature valid, with Microsoft Windows Software Compatibility
Publisher CN and Microsoft Corporation O. IM-DEP-18 records the shared-check
correction and actual-function RED/GREEN. Failed VM state is preserved in
snapshot 48dc5ca8-169c-4db1-8c4b-e3ec22ab7cd1; no generated uninstall occurred.

Root repeated capability, VC state and reboot regressions; all passed. The
native loading boundary in the focused capability test is inert. No post-fix
VM qualification follows from those results.

New immutable r7 under D:/acpu-1002-3343baed:

| File | Bytes | SHA-256 |
| --- | ---: | --- |
| consumer-release-r7/autoclip-publisher-cpu-v41-r7.zip | 225947128 | b737e574d469f1cf69327d60d81f8674ca5bf047d5bc8360880203553871d629 |
| consumer-release-r7/installer-dependencies-cpu-v1.json | 36460 | a079c0836db331aad30f9c858bc15852a41414aa0b31d404b323c9a374a240ad |
| consumer-release-r7/install-publisher-cpu.ps1 | 425249 | d4fc7f8b07494f1d77eaf1a8d60e7a5d6d5801b6c8450d61b6773edae310d209 |
| inno-cpu-candidate-r7/AutoClip-Setup-v1.exe | 3430551 | 2ec0a2cb708e4b31f16fd4556bfea37f304fbc5d309cef176abe00575f1082e0 |
| inno-cpu-candidate-r7/AutoClip-Setup-v1.receipt.json | 4401 | c88f18bbc789967d1f697667f6aa179ee066e07e42b2846c65b18bf0dfe3019c |

The actual CPU gate passed: 1154 indexed members, 75 publisher wheels, three
external assets. Native component bytes and historical component scope remain
unchanged. Build receipt remains UNVERIFIED_CANDIDATE.

New 71-file objective packet:
D:/Projects/autoclip-runtime-evidence/IM-DEP-13-cpu-candidate-r7-objective.
Packet manifest SHA-256:
1f1e7c43ea155378ba34fd0d646be73b0f4ebc96705ead25f274c2e3991945db.
Fresh blind read-only technical review is pending; producer work orders and
prior Setup verdicts are excluded. Configured release_reviewer role is used;
actual per-run model telemetry is not exposed. Separate documentation agent
recorded IM-DEP-18 without editing source. The prior implementation agent hit
its usage limit; root completed the focused production correction.


### r7 packet metadata correction (Setup bytes unchanged)

The first r7 objective review stopped at BLOCKED_EXACT_SETUP_CORRESPONDENCE:
its two independent rebuilt EXEs match each other (c2dacaf161dcf1816eb7cf6ae4bb862d0064c1905d7d51f2d210d0e1158ccfdf,
3430450 bytes), but differ from the frozen r7 Setup. The first packet copier
preserved bytes while replacing source last-write times. Metadata sensitivity
was a hypothesis in that review, not then a proven cause. Root read the full
review and rehashed its outputs under IM-DEP-13-review-r7-objective:
review.md 2bbbbdd9d3c2ba70d0ab06d2dfd483316532b44cb632c0e723657cd799263bc5;
disposition.json 45ec6e872999e184b3e3cb677e3bf37d1a4577144ebc8d719ba67454814bf338;
checks.json b476f5735bb4fc2fccbee176097210708941553020b2b4c3072a1283c3b2ef58.
Those packet/rebuild bytes and the blocked disposition remain intact.

Root created a distinct 71-file packet using stdlib shutil.copy2, verifying
all original byte identities unchanged and each last-write time preserved,
then indexing mtime_ns as well as hashes/sizes. Packet:
D:/Projects/autoclip-runtime-evidence/IM-DEP-13-cpu-candidate-r7-objective-r2;
manifest SHA-256 45a20fdb4cc83872b4d925b12bd4d57ba494ce57901f6178a601e0ab6d1530be.
A fresh-context read-only reviewer receives only this objective packet and
pinned compiler. No candidate production code or Setup bytes were changed.

The r7 clean-desktop linked clone is UUID d376f6ed-883d-4c4d-bd91-9a4a79a031ad,
from baseline e7dc20d9-4dc2-4355-8c15-6127ced3fbd4. Its read-only r7 DVD SHA
is 2f295fcac36835a34a832dfae1e68b41182ee2fbd287e906c04b6a6c3f23e461.
Baseline record vm-cpu-r7-clean-baseline.json SHA-256
c52931a0ef55312ab2584f141155d741c6ac2d8203d9201e1ae2f1e257685ee3.
The old r5 VM is powered off; its failed r6 snapshot remains preserved.

A separate read-only explorer located ten stable task-owned 512 MiB zero-filled
native removal fixtures. Root compressed only those files with native NTFS
compact, leaving paths and bytes intact. Each full before/after SHA matches;
no evidence was deleted or moved. New compression receipt:
C:/AutoClip-VM-Evidence/test-fixture-compression-20261002.json,
SHA-256 4aeb58d316913f83d3ccba90725b010e5eb511f0f01c2d80ba08fc13b202ed85.
C free space rose to about 24.4 GB. Existing immutable failure VHDs were untouched.


### Fresh r7 metadata packet review completed

The fresh blind reviewer returned ELIGIBLE_FOR_AUTHORIZED_CPU_VM_TESTS, with
no blocking finding. Metadata-preserving independent compilation exactly
reproduced Setup 2ec0a2cb708e4b31f16fd4556bfea37f304fbc5d309cef176abe00575f1082e0.
All 71 indexed byte/size/mtime identities remained unchanged. Actual host
four-DLL loading, three focused VC checks, app Git identity, baseline/component
mappings and 58 native PE/RECORD checks passed at their stated scopes.

Root read the full report and rehashed separate IM-DEP-13-review-r7-metadata
outputs: review.md f655af6e1ab23e424629017cc01fa8f356b7d5244e37ef9d2ffd75ac14ef97b4;
disposition.json 031ea360154875147171d83208d75f5666889fc20cb00d6b857f93596737dea7;
checks.json ac9bc7ae2b18a4f13b839386ffc47e37a29eebcca7cb2241fea0a8c80e7282d4.
This is same-session internal independent technical review for pre-VM scope,
not external/human/legal approval or completed installation/uninstall/release.
Root now begins exact r7 production Setup in the prepared clean clone.

### r7 actual failure logs and user stop boundary (2026-10-02)

Actual Setup displayed failure after native Python and VC runtime dialogs
completed. Root preserved live failure snapshot
`7911ff0e-17f5-4731-b3b3-b42a9fe9d5b0` and exported its disk to
`D:/Projects/autoclip-runtime-evidence/IM-DEP-13-r7-failure-primary-20261002/r7-failure-snapshot.vhd`
(24,297,428,480 bytes; full export hash not computed in this bounded check).
Guest UI input was inconsistent; no original log was intentionally saved or
changed. The snapshot predates log-viewer interaction.

User shut down r7 and supplied `drive-download-20261003T013350Z-1-001.zip`.
Its preserved copy `user-supplied-attempt-logs.zip` is 53,947 bytes, SHA-256
`396d5ddde848089397d6f2295dc916bc865906230915231915a4786f22d9359c`.
Eight bounded entries were retained under `supplied-logs/` and individually
hashed. Actual attempt spelling from status is
`source-build-is-H1LOCQ0M6M.tmp-1` (zero after Q).
The source worker, bootstrap, dependency and archive identities match r7 pins.

Supplied stdout reports native staging verified, 78 wheel ZIPs / 9,412 RECORD
rows verified, launcher created and installation completed. Stderr records
78 packages installed and dependency compatibility passed. The separate
health receipt reports actual installed Python 3.11.9 and health/home HTTP 200,
`VERIFIED_HEALTH_HOME`, child exit 0. These are isolated checks; desktop,
media, inference, generated uninstall and updater qualification remain pending.

The worker status instead remains RUNNING with null exit code, while commit
records COMMIT_STARTED and the wizard displayed failure. This points to the
supervising/finalizing path; the supplied logs do not establish the exact
cause or prove complete wizard installation. No fix or retest followed the
user's explicit stop-after-logs instruction.

Native VBox confirms r7 poweroff and its retained disk chain accessible.
User authorized removal of the older ColdEngine and Direct disks. Root
verified backups of 13 small configuration/NVRAM/log files, then unregistered
both old VMs using native no-delete unregister. Automatic approval review
rejected the subsequent exact two-file removal command with only
`blocked by policy`. Both VDIs remain (80,498,130,944 combined logical bytes);
no files were deleted or disk space reclaimed. Cold RAM and the Clean working
reference were preserved. Backup/status directory:
`C:/AutoClip-VM-Evidence/retire-inno-cold-direct-20261002/`.

Final log/retirement receipt in the r7 evidence directory:
`log-check-and-retirement-status.json`, SHA-256
`46f59aaa9a1cea0422e4259fb1391604921ec410035ba020799e7ba73369a80e`.
Work stopped at the user's boundary with r7 off. No release, uninstaller test,
updater test or NVIDIA hardware result is claimed.

## Authorized resume and r8 candidate (2026-10-02)

User resumed installer/uninstaller/updater work with Ponytail full and explicit
multi-agent direction. `r7_supervisor_contract` traced the display/observation
boundary read-only; `r7_supervisor_fix` owns the bounded fix and focused tests.
IM-WIZ-42 records actual RED on the unchanged supervisor and GREEN on the fix.
The supplied historical r7 logs omit supervisor stderr, so reproduction of the
same failure signature does not establish the original exception.

Root independently reran native PowerShell Tail and Process tests, both PASS,
and `python -m unittest discover -s .github/tests -p test_inno_build.py`, 14 PASS.
The guarded builder generated `D:/acpu-1002-3343baed/inno-cpu-candidate-r8` using
unchanged exact r7 CPU bootstrap, archive, dependency manifest and R2 native
artifact. New Setup: 3,430,626 bytes, SHA-256
`4e617da88c02ef82a66a095f4e235e3f6b9197a98e07c9756b35d0c410eda14e`.
Build receipt SHA-256
`f573f3ebaee9c5807feff2bde7276bbe48dd7f40a9826c9a01ac742090eca91b`;
status remains `UNVERIFIED_CANDIDATE`. Supervisor pin is
`aa5f2051a64627951899c146b2a992e6c42d52c9c90295e7bf539b16b2f74100`.

Frozen objective packet:
`D:/Projects/autoclip-runtime-evidence/IM-DEP-13-cpu-candidate-r8-objective`.
Its 80 indexed files preserve source mtimes and exact bytes; packet manifest
SHA-256 `ddd1abbdfd15487954e6ec1e5c8628f35c2d125954b718e8a6228ae5da1dd52b`.
Fresh-context `blind_cpu_candidate_r8` performs independent technical review.
Earlier raw user-supplied r7 logs are included only as historical evidence.

Root prepared one linked r8 VM from the clean r5 baseline snapshot
`e7dc20d9-4dc2-4355-8c15-6127ced3fbd4`, preserving r7. The clean snapshot
included saved RAM: initial DVD attachment refused saved/restoring state;
after ordinary VM resume, native attachment of the r8 read-only VISO succeeded.
VISO SHA-256 `ce324027bf53d20200c24f3d8897e694d7c6ac6a86f2168aa58588f7e5acccc9`.
The guest is at the clean desktop; no r8 Setup execution has occurred yet.
Computer Use input coordinates were inconsistent on the secondary monitor;
root requested the user's window move before further installer interaction.

`vm_lifecycle_plan` traced the actual consumer updater entry points read-only:
Setup bundles the full update script but creates only the fixed app shortcut.
The app-only updater is not bundled, and the current published app manifest
does not name this CPU runtime. `r7_supervisor_contract` is examining the
smallest native GUI route and activation/ownership boundaries. These findings
are pending integration work, not installed updater verification. Root still
owns actual VM application/media, generated uninstall, updater and release work.

## Cross-computer VM handoff (2026-10-02 local date)

User requested commit/push of the information needed to move VM testing to
another computer. Current continuation is documented in
[`../VM-HANDOFF.md`](../VM-HANDOFF.md), with a hashed separate transfer bundle
record in `../vm-handoff-transfer.json`. Git carries source/tests/contracts and
work records; the local bundle carries private candidate ZIPs, exact compiled
Setups, complete r8 objective/review material, compiler and owned test media.
No VM disks, saved RAM, release publication or public CPU pin promotion occur.

Fresh r8 blind review allows bounded CPU VM tests, with `release_eligible:false`.
The wizard subsequently reached its Python terms page; no complete installation
or lifecycle result was obtained. At handoff native host inspection reports r8
`aborted`. Root does not restart it for the transfer.

The maintenance implementation agent stopped with stable source/no active
commands. Its newer guarded compile succeeded, but is unreviewed and untested
in a real guest. Root repeated all 150 Python checks (one skip) and seven
focused native supervisor/selection/maintenance suites, all PASS. Handoff
retains missing integration documentation, native GUI callback qualification,
successful schema2 install/activation, app/media, generated uninstall and
real update/rollback as outstanding work. The new Setup cannot inherit r8's
technical disposition. Read-only `vm_handoff_audit` checked transfer needs and
limits; root owns source integration and Git delivery.
