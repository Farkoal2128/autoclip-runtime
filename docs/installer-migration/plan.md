# Inno Setup migration plan

Status: in progress; no setup candidate is qualified or published.

Current dependency priority (2026-10-02): IM-DEP-01 separates component delivery
permission from whole-installer qualification, clearing fourteen parent blocks
and twelve MSYS2 child blocks without changing artifact pins or release gates.
CPU installability now fails at Visual Studio Build Tools; SDK is independently
blocked. IM-DEP-02 selects a new controlled publisher-built CPU native artifact
for qualification to remove those recipient development-tool prerequisites.
Current v40 remains source-built; this alternative is not yet implemented or
approved. Historical statuses below retain their snapshot scope.

User-directed test order: get the production installer working first, then
test its exact generated uninstaller before release. Compare the installed
ownership inventory with the remaining files and registrations: all unchanged
AutoClip-owned installation files and owned shortcuts must be removed. Check
user-data and shared-prerequisite preservation separately. Do not infer this
from Inno's setup-shell uninstall log; helper-created runtime files need their
own ownership evidence. Uninstall execution is deferred until that candidate
is ready for production testing, not waived.

## Sequence and gates

1. **Repository baseline:** fetch upstream `main`, preserve local commits,
   record the divergence and baseline checks. Done: `origin/main` at
   `9a1ce539bda1468c326ada0ebea5a067d6b81bc5` is an ancestor of clean
   starting HEAD `ccc14a25014a35daf9e2de2edc595f8e02927671`; fast-forward
   merge reported already up to date. Seven local commits were preserved; no
   conflict occurred. Baseline PowerShell parse and LICENSE check passed; five
   installer-focused PowerShell scripts passed; 59 existing Python unittests
   passed; Python compile checks passed. These checks cover the existing
   PowerShell route, not an Inno executable.
2. **Contract and manifest:** the draft version 1 contract and v40-derived
   dependency inventory are in place. The exact v40 public ZIP was downloaded
   and verified at 173,196,134 bytes and SHA-256
   `f2b3be779294bc55d6f5f56c2a780a2d6b863486f3af9bd7d19f30051961fc9f`.
   It has 1,108 members, 74 publisher wheel references, and three external
   assets. Required CPU build-tool acquisition records remain `BLOCKED`.
3. **RED/GREEN:** nine manifest tests pass, including nested prohibited-file
   and escaping-symlink rejection. The verifier passed against the downloaded v40 ZIP and its
   `--require-installable` check rejects the current CPU graph at `uv`. Three
   guarded-build tests pass after RED for the missing script. The Inno
   preflight test went RED when its helper was absent and is GREEN. A focused
   test against the prior committed `install.ps1` observed winget, pacman, and
   Python fallback acquisition despite a guard request; the new
   `-NoPrerequisiteAcquisition` path blocks all three in the same test.
4. **Source and diagnostic build:** Inno Setup 7.1.0 compiles the draft wizard.
   The CPU profile is default; at this first snapshot NVIDIA was selectable
   but cuBLAS remained blocked. The exact EXE `/AUDIT` test extracts and checks the four
   declared embedded files. This is a diagnostic compile, not an installable
   or qualified release candidate. The guarded build script refuses to
   compile while a required CPU prerequisite is blocked. Diagnostic EXE:
   `D:\AutoClip-Inno-Migration\diagnostic-20261001\AutoClip-Setup-v1.exe`,
   version 1.0, 2,533,184 bytes, SHA-256
   `841ded81de84212f8464b30683f330a083aa95f92797ce2a4a2486555e828020`.
   Its separate `AutoClip-Setup-v1.UNQUALIFIED.receipt.json` binds compiler,
   source, archive, manifest, notice, and output hashes. The exact EXE's
   `/AUDIT` test passed for that snapshot. Later source changes make this EXE
   stale; it is not a candidate for installation or release.
   A later direct diagnostic compile at
   `D:\AutoClip-Inno-Migration\diagnostic-20261001b\AutoClip-Setup-v1.exe`
   produced a 2,533,308-byte EXE with SHA-256
   `874b302e6cdca1da7e83014b61193b8238616085bef10641552ed5276d1acd5b`.
   Its adjacent `UNQUALIFIED` receipt binds the changed source and dependency
   manifest; `/AUDIT` matched the four declared embedded files. It is still
   blocked at required CPU prerequisites and has no installation evidence.
   The subsequent MinGit manifest selection required another diagnostic
   compile: `D:\AutoClip-Inno-Migration\diagnostic-20261001c\AutoClip-Setup-v1.exe`,
   2,533,426 bytes, SHA-256
   `38cc2c17609927bf093880119b50750663893e13c5c14b420f2842ca989babe3`.
   Its adjacent `UNQUALIFIED` receipt and four-file `/AUDIT` passed. This is
   a historical diagnostic snapshot. After adding the MinGit extraction helper,
   a newer `D:\AutoClip-Inno-Migration\diagnostic-20261001e\AutoClip-Setup-v1.exe`
   compiled at 2,535,874 bytes, SHA-256
   `76dfcd2a5da1d5885aae6bc1c7f57f2aa03d423185434c3ad0b2ac18f0fe5ee4`.
   Its adjacent `UNQUALIFIED` receipt binds five embedded files and `/AUDIT`
   matched all five. After optional NVIDIA consent and GPU guards, the current
   diagnostic is `D:\AutoClip-Inno-Migration\diagnostic-20261001f\AutoClip-Setup-v1.exe`,
   2,536,591 bytes, SHA-256
   `769420e7ef57c2bc7947690853dc92c6f904742bf414d05e48cf17b8a7478448`.
   Its five-file `/AUDIT` passed. After unifying MinGit and uv extraction and
   pinning both `uv venv` calls to Python 3.11.9, the current diagnostic is
   `D:\\AutoClip-Inno-Migration\\diagnostic-20261001g\\AutoClip-Setup-v1.exe`,
   2,537,149 bytes, SHA-256
   `e5df8d785af8d6b8744a8526c3f79d0ae0e4bb20127fb68f5eb325fb83e775bc`.
   Its adjacent `UNQUALIFIED` receipt and five-file `/AUDIT` passed. The current
   source, after manifest wording and uv signer preflight changes, compiled as
   `D:\\AutoClip-Inno-Migration\\diagnostic-20261001h\\AutoClip-Setup-v1.exe`,
   2,537,194 bytes, SHA-256
   `da7acb4e787a4f8cdb0e6286df98a18a499c22681134bd98d66da3eea63c07e5`.
   Its adjacent `UNQUALIFIED` receipt and five-file `/AUDIT` passed. None of
   these diagnostics is a qualified install candidate.
5. **Verification:** run focused and repository checks, inspect the complete
   final setup payload, test the exact executable on clean Windows, and run an
   installed ordinary-user media workflow. On resuming the old VM, its saved
   state showed an existing AutoClip browser; that state is a prepared machine,
   contrary to the earlier clean-state description. The original was preserved.
   A linked clone `AutoClip-Inno-Win11-Clean-20261001` was created from exact
   snapshot `01a6fa87-d161-4279-ba9d-a661ada94ee2`. Guest inventory confirms
   no AutoClip directory, Python registration, VS installation, MSYS2, Git, uv,
   FFmpeg or FFprobe. Windows' Python app alias is present. Keyboard console
   control and a loopback first-party-only test transfer server work without
   Guest Additions. No setup installation has been executed on this clone.
   NVIDIA hardware is unavailable in this VM; its hardware tests are deferred
   at the user's direction and must be reported as unverified.
6. **Blind technical review:** freeze an immutable candidate and send a fresh
   reviewer only the objective requirements, applicable contracts and policies,
   exact hashes, candidate code/binary, and primary evidence. Rebuild and
   re-review changed candidates. This is separate from legal and human gates.
7. **Promotion:** make Inno Setup the documented canonical end-user entry point
   only after the exact candidate passes applicable acceptance and release
   gates. Retain historical PowerShell routes for recovery/development as
   documented. The user has authorized publication once the required gates
   pass; they have not passed for the present diagnostic builds.

## Open decisions and blockers

Latest component progress is recorded in the final section of
`evidence-2026-10-01.md` and work orders IM-DL-01/02/03, IM-PY-01/02,
IM-FF-02/03, IM-MS-01/02/03, IM-TOOL-01 and IM-VS-02. Historical diagnostic
counts and hashes above remain tied to their original snapshots. No current
guarded candidate passes the production dependency gate. Next integration:
Python helper extraction/consent/provisioning, FFmpeg runtime availability,
guarded publisher/external callbacks, explicit MSYS2 offline trusted execution,
and exact Microsoft layout orchestration; then exact wizard/lifecycle/media tests.

- The selected public v40 payload is a recipient-side native build. Clean CPU
  install needs exact, permitted routes for uv, FFmpeg, Git, MSYS2 packages,
  Visual Studio Build Tools/SDK, and Python. Existing winget and pacman
  resolution is not yet an exact pinned dependency inventory.
- Metadata records exact bootstrap URLs, sizes, and hashes for uv, FFmpeg,
  Git, MSYS2, Build Tools, and Python. All six bootstrap artifacts have now
  been downloaded and locally rehashed. Five MSYS2 package files and their
  signatures were also checked, and an official Visual Studio layout for C++ tools and
  SDK 26100 passed Microsoft's layout verifier. These local checks do not yet
  provide a complete recipient installation or consent route. The existing
  winget agreement-suppression flags cannot be inherited by the guarded wizard.
- User has authorized release once sufficient evidence exists and deferred
  NVIDIA hardware tests. CPU clean-install, final payload, consent, lifecycle,
  ordinary-user application smoke, and technical review gates still prevent
  promotion or publication.
- Local integration checks: the earlier 74 Python unit tests passed; focused PowerShell
  preflight, no-acquisition, prior installer consent/launcher tests, public
  v40 pin verification, Python compile, and `git diff --check` passed. A
  warning about a duplicate synthetic ZIP member arose in one existing Python
  fixture. No installed ordinary-user AutoClip run or clean-VM setup run was
  performed on the diagnostic EXE.
- Unpublished local successors are not public release inputs by default.
- Resolve artifact-level notice, source, and direct-recipient policies using
  primary evidence. No prior scoped review approves the new setup executable.
- The selected v40 archive references the exact NumPy 2.4.6 Windows wheel.
  The later [v40 independent follow-up](https://github.com/Farkoal2128/myAutoclip/blob/c66a289f875b168477ce789b5ea6a23c499f893d/docs/features/creator-ready-delivery/cr09-v40-independent-release-followup.md)
  resolved its private Microsoft DLL row at the publisher acquisition and
  no-AutoClip-redistribution scope. This does not approve a changed route,
  upstream legal entitlement, or the new Inno wrapper. Verify that setup keeps
  the exact publisher pin and direct-recipient route without bundling, mirroring,
  or a populated shared cache; review the new candidate separately.
- Establish clean Windows and GPU test environments, and an appropriately
  licensed bounded media fixture.
- Confirm the existing source-build dependencies that are truly runtime needs
  versus build-only tools before defining the recipient wizard summary.
- MinGit's exact ZIP now passes hash, traversal, signature, version, and local
  extraction checks. The same helper also passes the exact uv ZIP and signed
  executable checks. The diagnostic wizard conditionally downloads both and
  passes their verified executables into the source builder. Their manifest
  routes remain `BLOCKED` until redirect policy and clean-machine recipient
  download are verified; local extraction alone is not a release route.
- Optional NVIDIA now has a separately linked cuBLAS terms checkbox and a
  software path to the existing pinned CUDA/cuBLAS recipient download helpers.
  The exact-v40 review covers that direct publisher route. A missing GPU/driver
  blocks only the NVIDIA profile, and the source builder refuses to complete a
  selected NVIDIA installation when GPU detection fails. NVIDIA hardware
  installation and inference tests remain deferred as requested.

Latest continuation: IM-DL-04 resolves exact MSYS2 packages/signatures and
native-build assets through the protected downloader. The dependency gate now
binds nine native-build artifacts to the immutable v40 recipe, with focused
RED/GREEN evidence and exact publisher/external redirect-host requirements.
The real guest's five-package MSYS2 transaction passed with the NIC disconnected,
using a new isolated local trusted keyring and exact before/after package checks;
see the latest evidence section and its receipt hash. The base provision wrapper
and complete wizard remain unqualified. Current work covers secure callbacks,
read-only preflight detection, persistent managed FFmpeg discovery, and the
documented Microsoft native-UI experiment. Recipient agreement consent is
pending separately from the user's confirmed non-commercial use and VS rights.

Integration continuation: managed FFmpeg bootstrap and persistent venv discovery
are implemented and focused-tested (IM-FF-05). The native platform guard and
Inno `x64os` restriction are implemented (IM-PF-04). The latest completed Python
suite at that integration state passed 78 tests. Diagnostic k predates these
changes and has no approval for current source. IM-PY-03 owns the next Python
wizard/consent/reboot integration slice. The second GUI base experiment still
has no successful process receipt; the fresh official TAR/default-keyring/one
offline-login route is being tested separately (IM-MS-04). CPU full install,
ordinary-user media and lifecycle tests, final payload/receipts and blind review
remain open. NVIDIA hardware tests remain deferred by user instruction.

Continuation: explicit recipient agreement consent for Python 3.11.9 and native
Microsoft Build Tools 17.14.41 / VC Runtime is now recorded for VM tests only.
The fixed MSYS2 socket helper passed the real disconnected five-package
transaction on the fresh TAR root; the existing helper still requires the GUI
artifact, so production TAR integration remains open. IM-MS-08 implements the
contracted Python standard-library extraction boundary. The compiled Python
diagnostic reuse case passed; its other eleven cases are blocked by confirmed
Defender remediation of the diagnostic EXEs. No protection bypass or approval
for a changed installer hash is permitted. Real consented prerequisite tests,
complete CPU setup, installed media/lifecycle, final payload and review gates
remain required before publication.

The real consented Python helper installation now passed in the VM: official
download identity and PSF signature, absent-to-installed detection, exact native
capability checks, vendor exit 0 and unchanged user PATH. The full Inno wizard
has not yet performed that installation. IM-MS-08's exact-archive host tests
passed all thirteen cases; its fresh guest Python-extraction/signature/native
mode test also passed. Initialization, packages and guarded source build on
that Python-extracted root remain unverified. IM-VS-05 prepared the exact
409-file layout comparison and
official direct-download metadata. Its catalog size/hash discrepancies and
installer engine acquisition remain explicit; Microsoft installation and the
complete source build are still unperformed in the guest.

Current archive integration: the canonical MSYS2 row now selects the exact
official TAR/signature/installer key, all still BLOCKED. The per-user receipt
contract rejects elevated helper execution. Manifest/download/preflight/build
bindings have meaningful RED/GREEN evidence in
[the integration record](work-orders/IM-DL-05-integration.md); the Inno payload
includes the three first-party MSYS2 helpers, with orchestration pending.
IM-MS-09 implements the qualified base receipt consumer. IM-MS-10 owns base
provisioning and records its unintended, stopped host extraction test and
preserved partial directory; operational qualification remains in the VM.
The guest Microsoft layout matches all 409 expected files, but the acquisition
wrapper's exit capture failed; a separate vendor verification is required.
Complete CPU wizard/source-build/media/lifecycle and final review/release gates
remain open. NVIDIA hardware tests remain deferred.

The subsequent supported vendor layout verification passed with numeric exit
0 and independent exact 409-file comparisons before and after. See the primary
receipt in `evidence-2026-10-01.md`; the failed acquisition exit observation and
catalog discrepancies are preserved. The offline interactive product-install
test is separate and cannot close installed capability or wizard gates alone.

Latest integration: the corrected layout-local Microsoft native install
returned numeric exit 0, and the prepared ordinary-user guest passed real x64
compile/link/run using the installed MSVC/SDK (IM-VS-08/12). The compiler probe
display-text defect has focused RED/GREEN and preserved primary failure/pass
receipts. Exact uv license texts now exist (IM-TOOL-02), with setup notice/source
index integration in IM-TOOL-03. The requested compiled notice audit was rejected
by automatic tool policy before execution; it remains unverified.

MSYS2's fresh ordinary-user production base/package chain passed, with the
full base and package primary receipts transported and independently hashed
(IM-MS-14). The original source guard rejected the contracted inherited-root
ACL; IM-MS-16 corrected that mismatch with meaningful RED/GREEN and then
passed the real guest prerequisite query and environment restoration tests.
The corrected Microsoft JSON diagnostic passed both documents' RSA/CMS,
timestamp bindings and all eight normal Windows trust/revocation chains;
the full primary receipt is preserved (IM-VS-14). The authenticated standalone
Catalog is now an intentional expected-artifact contract selection; its
conflicting vendor declaration remains recorded. Supported pre-execution
engine/control acquisition is still required (IM-VS-15/16).
Neither component progress nor compile-only source evidence closes whole CPU Inno/source-build/media,
lifecycle/failure, final payload/SBOM/notices, blind review or release gates.
NVIDIA hardware tests remain deferred under the user's standing instruction.

The IM-BUILD-04 snapshot held all 19 exact input files against concurrent writes/renames
from validation through receipt creation, with real Windows race and cleanup
RED/GREEN evidence (IM-BUILD-04). That Python verification snapshot ran 99
tests: 98 pass and one optional archive test is skipped. This does not qualify
compiler support files outside the enumerated inputs or the final setup.
IM-ACQ-18's real guest read-only inventory additionally records exact legal
members of all seven acquired native build-tool wheels. Truncated displayed
text is labeled and does not replace the full retained package notices.
The supported recipient-only private CPU build remains a separate test from
whole-wizard installation, installed application/media and publication.

Current continuation: IM-VS-17's separately scoped actual guest comparison
matches all 868 installed engine files to the pinned OPC, with no differences;
the complete primary receipt is preserved. The earlier original-layout
41-of-409 failure is unchanged. IM-VS-18 supports the intentional staged
acquisition contract, with all execution inputs prevalidated and generated
controls reviewed before product installation; no vendor generation has run
under that revision. IM-DL-06 acquired all nine native inputs through the
current protected downloader in a fresh ordinary-user guest stage. IM-FF-06
passed complete acquisition/extraction/CLI checks but its path assertion
failed when discovery returned the long username alias. Its primary and
startup logs are preserved; a corrected diagnostic requires independent path
and file-pin checks before acceptance. Full source build and wizard gates
remain open.

IM-FF-07 now passes the corrected actual guest component run, including exact
canonical executable pins, persistent discovery and synthetic video/audio
render/decode; original IM-FF-06 failure is retained. This does not close the
real installed AutoClip workflow gate. IM-VS-19's 267-file acquisition failure
is preserved; IM-VS-20's safe cache-name/locked copy correction passed focused
RED/GREEN and its fresh 397-file guest acquisition is in progress.

That IM-VS-20 acquisition completed: all 397 exact files/1,289,700,306 bytes
match the unchanged pinned metadata; primary a84c9066a7f5 is preserved. This
does not qualify vendor layout generation, fresh engine acquisition or the
whole Microsoft wizard. IM-VS-21 records the bounded warm-engine experiment
and Microsoft's documented initial-layout Internet requirement.

Actual CPU19 stopped before compilation on a PowerShell scalar-splat defect;
CPU20's one-line correction has meaningful native argument RED/GREEN. The
fresh CPU20 attempt then created the real pinned Python venv but failed because
the FFmpeg startup guard accepts standard-library `version` and not uv's
`version_info` field. Both full primary failures and logs are preserved.
IM-CPU-21 addresses the exact producer metadata mismatch. Full CPU build is
still unqualified. Inno integration compiles only; cancellation review found
post-recipe/startup/finalization gaps, with scoped fixes and protected commit
serialization in progress (IM-WIZ-10/11/12/13). No uninstall or release pass
is inferred from this progress.

IM-CPU-21's exact uv configuration regression is GREEN: the shared guard
accepts either unambiguous pinned `version` or `version_info` while rejecting
duplicates, conflicting versions and non-isolated environments. Its new actual
guest attempt (child PID1548, start2026-10-02T03:33:59.595343Z) is still running
and reached native FFmpeg compilation; no completed CPU build is claimed.
IM-VS-22's protected incoming seed preparation is separately in progress,
without vendor execution or a supported-layout claim.

Current Inno integration includes the source supervisor as the twentieth locked
build input. All 11 first-party builder tests and actual supervisor cancellation
fixtures pass. Startup requests use the protected decision broker; only exit0
accepts cancellation, and170 reports completion already begun. Syntax compilation
passes, but the resulting private diagnostic setup was not executed. IM-WIZ-14
identified launcher/marker retry ordering, now assigned to IM-WIZ-15. Exact
wizard/UI, application/media, lifecycle and final distribution gates remain open.
Uninstaller execution follows production-ready installer qualification, then
cleanup/preservation checks, then release; no uninstall has run.

Continuation: CPU21's production source child reached terminal exit 0, built
both pinned CPU native wheels and installed/checked 77 packages. The diagnostic
then failed while looking for those wheels under `ExternalCache` instead of
`InstallRoot`; its primary and full logs remain preserved. IM-CPU-23 validates
the existing completed stage without rebuilding. Whole CPU setup success remains
unqualified. VS22 seed preparation and VS24 native OPC authentication passed at
their component scopes; fresh-machine engine installation remains open.

IM-WIZ-15 fixes launcher-before-marker completion and safe matching-partial
retry, with real COM/locked-file RED/GREEN. IM-CPU-22 supplies the installed
isolated health/home helper. IM-WIZ-16 binds it into managed source builds before
completion; its 18 process scenarios and adjacent checks pass. Root reran all
11 builder tests with 21 protected inputs, the real first-party ASGI health
fixture and default preflight, all exit 0. These are component/fixture checks,
not exact setup qualification. Actual installed health validation is in progress.
IM-WIZ-17 addresses durable logs and same-target worker exclusion. Inno syntax
must be recompiled after these source changes; prior setup hashes are historical.

Follow-on CPU23 validation passed on the existing completed CPU21 component,
with full logs independently reassembled and hash-checked. Actual installed
isolated app health/home also passed; desktop/media/transcription and exact
wizard gates remain open. WIZ17 real worker/storage tests and root's latest
11 builder tests pass. Current Inno syntax compiles with exact health/supervisor
pins and durable attempt selection; output6006n1qk is unexecuted and uses
canonical BLOCKED metadata. Warm guest was saved after evidence preservation;
the separate cold-engine clone is the next prerequisite qualification context.

WIZ18 internal collaborator review found three scoped gaps. WIZ19 resolves the
actual Python log-producer conflict and an absent-target Windows alias race with
meaningful RED/GREEN; root composition and final11 builder tests pass. WIZ20
prepares an actual observation-failure fixture for the remaining conditional
Inno cleanup gap; neither runtime RED nor a production fix is claimed yet.
Latest syntax output_zd_yqpr is unexecuted and remains metadata-blocked.

The separate cold clone's native baseline confirms absence at supported Microsoft
locations and of per-user Python registration. VS25 exact official recipient
bootstrap/OPC acquisition, native signature/current normal trust and complete868
member authentication passed; no vendor installation ran. Guest NIC is now
disconnected. VS26 prepares a bounded protected elevated engine-only experiment;
actual cold compatibility remains unknown. Installer qualification continues
before the user-ordered exact uninstall cleanup/preservation test and release.

WIZ20 actual observation fixture did not reach worker readiness; its original
processes/logs are preserved. WIZ22 corrects the fixture native-path mismatch,
but its actual native launch exits-65536 with a PowerShell ServicePointManager
initialization error before a build attempt. WIZ23 investigates that failure;
WIZ24 prepares a native-x64 Setup variant with unchanged observation/supervisor
behavior. Production remains unchanged until the minimum correction is qualified.
The conditional UI-fault RED/GREEN is still open. Native tracing discovery passed;
encoded elevated qualification preparation was automatically rejected, with no
trace/vendor execution. Installer qualification still precedes uninstall testing.

WIZ24b's normal native launch reached System32 PowerShell but remained blocked
before worker readiness. WIZ26 reproduced that input-dependent startup in the
actual host supervisor: its reserved `$input` loop variable caused PowerShell
to await redirected input. Renaming the local and its references passed the
same real-process test with stdin open. Root reran that test, all11 builder
tests and composition/alias checks. These results do not qualify the guest.
Root integrated native-x64 Setup and normal System32 asynchronous launches,
retaining x64os and per-user identity while selecting64-bit installation mode. Current
syntax compilation passes with the new supervisor pin; exact VM observation
qualification is assigned to WIZ28. The conditional UI-fault test, production
prerequisite route and later exact uninstaller remain open.

WIZ28 reached actual held-worker readiness and produced the intended UI-fault
RED in the ordinary cold VM. The original worker/supervisor were subsequently
observed terminal after cooperative release; complete raw evidence is preserved.
Root guarded the two cleanup UI calls separately and explicitly retained the
observed64-bit installation mode. Updated syntax compile passes. WIZ29 owns
one fresh compiled packet for actual runtime GREEN. No uninstaller ran.

WIZ29 actual compiled ordinary-VM observation test passed: Setup remained
observing while the injected display failure and original worker were held,
then waited through the original worker/supervisor terminal exit0. Full raw
primary and closed logs are preserved. Root rechecked raw file hashes, all11
builder tests and all10 source-supervisor regression groups, exit0. This closes
the conditional cleanup-display gap at that test's scope, not normal setup.
The canonical required Microsoft prerequisite route remains BLOCKED. VS28/29
reconcile the bounded cold-engine evidence method with the user/contract;
complete ETW is not a new gate, and the rejected encoded tracing action remains
unperformed. Installer qualification, later exact uninstaller and release stay
ordered as requested.

VS29 actually installed the cold Microsoft engine with NIC disconnected.
The driver failed during terminal process observation and preserved an unknown
outer vendor exit. Independent output comparison matches every authenticated
OPC member (868 files, no exclusions); preserved vendor logs report exit0.
The VM is now engine-present. Root verified primaryc58388 and all raw log pins.
VS31 reproduces the diagnostic failure with a native first-party process and
qualifies its minimal handle/start capture correction with real exit0/7 tests.
No corrected vendor replay, VCTools/SDK installation or full wizard pass follows.
VS32 maps the next supported layout/product step on the existing verified
engine; the separate full fresh CPU wizard requirement remains open.

VS33 current-recipient397 official payload acquisition passed its full pinned
receipt checks (primaryb912823e,392083bytes), with all432 catalog associations
and140 declared-size differences retained. No vendor execution/layout/product
operation occurred. VS34 identified the selected install-channel endpoint as
data inside the pinned fixed bootstrapper. VS35 prepares missing control
acquisition and derivation; current normal authentication and native layout
acceptance remain required. CPU24 maps the actual archived installed media APIs
and a bounded recipient model route. No uninstaller has executed.

VS35 actual current-recipient control acquisition completed with original
native10888/handle3316/exit0. All9 canonical pins match; full6760-byte primary
c129999b is preserved. Its status deliberately leaves authentication pending.
VS36 then authenticated the current Catalog/Channel: exact file/message pins,
RSA/CMS signatures and timestamp linkage passed, plus all8 normal native
current/signed-time chain results. Original13100/handle3716 exited0; full210068
primaryca647e67 is preserved. Root inspected every flag and chain status.
These are metadata authentication results within the reconstructed serializer's
documented limits; they do not qualify a vendor-generated layout or installer.

VS37 actual incoming seed preparation produced all408 expected path/length/hash
triples at the current recipient, including397 payloads,9 exact controls and2
locally authored355-byte controls. Full552453-byte primary8300e91e is preserved.
Original native6104/handle3652 exited0 with no stderr; the separately preserved
631-byte terminal observation98253b54 binds its original start and exact receipt.
It records no vendor execution, engine recheck or layout/product installation.
VS38 prepares the separate protected native layout operation; original engine
exit uncertainty remains preserved. CPU25 prepares the installed media smoke,
with real inference/render execution unperformed. Required installer production
qualification still precedes exact uninstaller cleanup/preservation testing.

VS38 actual protected native layout exited5007: vendor log identifies unsupported
`--noWeb` in layout generation. Full2,230,545-byte primary2d74d969 and both raw
native logs are preserved. Independent full408/868 inventory comparisons match
their frozen primaries. VS39 removes only that invalid layout argument, retaining
NIC isolation, pins, protected staging and no installer updates; root-focused
RED/GREEN passed. Actual supported-argument layout, vendor verification/product
capability and final generated Inno qualification remain outstanding. Uninstaller
execution follows installer production readiness and precedes release.

VS39 is now terminal5003: the supported-argument bootstrapper attempted its fixed
installer-engine URL with NIC OFF and failed DNS12007. Full2230813-byte primary
7bcc7d69 and raw native logs are preserved; complete408/868 comparisons still
match. A bounded internal contract review is evaluating supported normal online
layout acquisition and required validation. Production route remains BLOCKED;
no uninstaller has executed, and readiness still precedes that lifecycle test.

### VS40 connected layout terminal failure

Exact retained native run10152 terminated87; parent11496 terminated2. Full primary
`D:/AutoClip-Inno-Migration/vm-vs40-layout-primary-8b1cf8ae7063.json`, SHA256
`8b1cf8ae7063e4938d0daa8ca869f2fbc3c84541a88849799ad8638abcbe398b`:
all408 source/copied/after and868 installed engine before/after verified unchanged.
Native logs prove latest-alias OPC acquisition/extraction and temporary layout
engine execution. Resolved URL names the selected digest but independent temporary
OPC hash was not retained. Native client exit87 cause remains unresolved. See
work-orders/IM-VS-40.md for primary log/stream bindings and diagnostic limits.
No product setup/uninstall or production/release readiness is established.
User sequencing remains: installer production readiness first, then exact generated
uninstaller cleanup/preservation verification before release; no uninstall run yet.
### Microsoft supported direct-install qualification decision

The root intentionally amended contract-v1 to permit a supported direct route
and documented quiet installation after explicit informed recipient acceptance
of exact Build Tools and applicable SDK terms. The earlier native-interactive-only
rule was a project choice; silent mode remains insufficient consent. Layout-only
controls remain required when that route is used. Incoming/nested artifact pins,
signatures, version controls, safe staging and exact capability checks are retained.
No canonical dependency is promoted: Build Tools and SDK remain BLOCKED.
Contract SHA256 now `3eb9e4fbfb08d5aeb58f5b0aaa5a57ae044795d7bf537d9febed763c9f966f35`;
manifest SHA256 now `f9689639b6227756fc9164dde57e713f4b755bea59f3cd2bf93dfffe5621b774`.
Only the blocked Build Tools explanatory reason changed in the manifest; identity,
version, URL, sizes, hashes and classification remain as before. Historical
90d6189f manifest fixtures/candidates retain their original scope and are not
approval for this new manifest. Current16 manifest behavioral checks pass via
`python .github/tests/test_installer_manifest.py`; git diff --check passes.
Exact SDK terms extraction, consent binding, fresh-recipient route execution and
final candidate review remain open. No installer success or publication claim.
### CPU26 actual prepared-machine media component GREEN

After actual CPU25 fixture RED, one measured-duration fixture correction passed
constructionRED/GREEN and actual recipient run8024/originalhandle3640 exit0.
Real installed app CPU/int8 transcribed62 words, rendered8.0s1080x1920H264/AAC,
passed fullAVdecode and non-silent audio(-17.8dBmean/-1.5dBmax), preserving source.
Exact component evidence311601 bytes/SHA256
`57b7aeed795ea79f6cc509a8b3644c3101124c2fe2dddb0ea55f4a2c9e6fd97e`;
root independently bound actual result/logs/output metadata and viewed readable
sample captions. See IM-CPU-25/26 for exact RED/GREEN, guest-time lag and limits.
This is prepared-machine runtime component evidence. Exact Setup install,
ordinary desktop/browser, lifecycle/uninstaller and fresh-recipient dependency
qualification remain open; no NVIDIA, listening or final release claim.

### Receipt integration component verification

WIZ33/WIZ34 source ownership now reaches the compiled Inno finalization hook;
the builder binds and holds the receipt helper and exact notice rows. Native
PowerShell rejection tests, actual filesystem/COM receipt tests and all six
source integration groups pass. Native Inno registration uses a trailing
InstallLocation separator; the corrected fixture demonstrated RED, then both
producer checks were fixed and GREEN. Eleven builder tests pass. See WIZ35 for
exact current pins and syntax-only candidate identity. Canonical prerequisite
classifications remain BLOCKED; syntax compilation is not production readiness.

Read-only review found Finish-page failure text is overwritten by native Inno
after ssPostInstall. WIZ36 prepares an inert native event fixture for actual
RED/GREEN; it has no prerequisites, payload, registration or uninstaller.
The retained cold VM was saved without killing its pending help operation.
A separate linked clean VM permits independent fixture testing. SDK consent is
still pending; no acceptance is inferred. Production installer readiness still
precedes exact generated-uninstaller cleanup/preservation and release.

WIZ36 native interactive fixture reproduced the overwritten failure body (RED)
with actual exit20. Moving labels to CurPageChanged(wpFinished) passed unchanged
native observation checks: failure retains its detail/preservation text and
exit20, while success retains normal completion and exit0. Actual original
handles, Finish-click text and screenshots are retained in IM-WIZ-36. This
inert fixture has no vendor, payload, registration or uninstaller. Full current
source compiles but that syntax-only binary remains unexecuted. The separate
display-exception process-observation finding is still open.

### Finalizer display-exception native RED/GREEN

WIZ37 reproduced original-child Status0 after an injected display exception.
Moving try alone still failed. A separate native scalar trace established that
the nested cleanup exception handler redispatched the pending body exception
before Sleep. Capturing the body error before cleanup and rethrowing after the
same child exits passed unchanged immediate-observation checks for SetText,
Show and control. All retain exact native child/PID bindings; no observer wait,
kill or restart masks the assertion. See IM-WIZ-37 for original handles,
source/spec/binary hashes, preserved failed attempts and primary evidence.
Current source8fed compiles; its full syntax-only binary remains unexecuted.

RunSourceBuild has analogous nested cleanup handlers. WIZ38 prepared exact
native source-build tail fixtures, including repeated cleanup display failure;
that separate finding remains open until its native RED/correction/GREEN.
The canonical prerequisite manifest remains unchanged and BLOCKED. SDK consent
remains pending, with no acceptance inferred. Automatic approval review rejected
preparation of a fresh VM prerequisite-acquisition command with only "blocked by
policy"; no command file, acquisition or vendor action resulted, and root did
not retry or bypass that rejection. Independent first-party native process tests
continued. Production installer readiness still precedes exact generated
uninstaller cleanup/data-preservation testing and release; none has run.

WIZ38 actual native baseline now shows two failures: body-once returns with
child7720 still running, while repeated cleanup errors wait for child4244 but
lose the original display error. Both fail the same unchanged verifier for
their distinct reasons. Root captured the body error before cleanup and added
rethrow after cleanup in RunSourceBuild; sourcef1d2 syntax compiles, with no
change to the WIZ37 finalizer. Fresh native GREEN remains pending; exact
commands/pins/primary evidence are retained in IM-WIZ-38. No product installer,
actual generated uninstaller or release operation has run.

WIZ38 corrected native body-once, body-and-cleanup and normal completion now
all pass the unchanged immediate original-child/error/result verifier. The
control child2440 was Status1/exit0 with no caught error and result=true;
CreateNew-preserved primary SHA256
`a6c7c4be6a52dc04ccf68e3738655afe2c8bc2b276583845d59c754f4502d2c3`.
See IM-WIZ-38 for exact spec/binary/source pins and original GUI handle/times.
The source-build display-exception finding is closed at component scope.
This does not qualify actual cancellation or production Setup. SDK consent,
fresh prerequisite qualification, final candidate review/install/health and
other lifecycle work remain open. Qualify the production installer first,
then test that exact generated uninstaller's cleanup and data preservation
before release. No production Setup or actual uninstaller has run.

WIZ39 is implementing exact completed source reuse for setup repair: unchanged
ownership/identity verification and fresh external health, without rebuilding
or rewriting completed source bytes. Root updated the contract before behavioral
RED/GREEN. Early wizard reuse and qualified native receipt renewal remain separate
integration requirements. A fresh-context review of the frozen WIZ37/38 process
component packet reports a cleanup Hide/control error-preservation gap; WIZ40
prepares exact inert native reproduction before correction. Existing passing
fixtures did not inject this branch. No full installer review approval is claimed.

VS49's actual metadata-only guest query now finds neither original setup.exe6588
nor parent2564. Old exit codes and roles remain unknown; different concurrent
installers still need checking before launch. This read-only query did not retry
the rejected acquisition command. SDK consent/acquisition/vendor qualification
and final installer/lifecycle/ordinary-user tests remain open. Exact generated
uninstaller testing remains after production installer qualification and before
release.

WIZ39 actual source-boundary verification is now GREEN: exact completed reuse
and read-only external health preserve owned source bytes, with rejected altered
identity/inventory/health and accepted cancellation. A real decision-lock race
was RED and is fixed by provenance recheck inside the cooperative commit action.
Thirty-two focused cases and five affected regression scripts pass; root inspected
the actual source/test/logs, independently reran the focused suite, and verified
an exact reverse of only the two production regions recovers the whole prior
bootstrap hash. Current bootstrap5b2994 replaces a09c; all historical syntax
binaries remain bound to their old bytes. Full worker/installed health, earlier
Inno reuse and native receipt renewal remain unverified; this is not full repair.

WIZ40 reproduced the blind review's original-error replacement in both native
process procedures, then guarded final controls/Hide. Corrected body+Hide cases
and finalizer cleanup-only now pass unchanged verifiers. Source cleanup-only is
still RED: the function retains result=true when cleanup raises. WIZ41 prepares
native caller/custom-exit verification because an already-set completion flag
can survive `CurStepChanged`'s catch. Neither finding is waived or tested by source
string assertions. No corrected final candidate review has begun. Exact source,
fixture, compiler and raw primary evidence is retained in IM-WIZ-40/41. Production
installer readiness, then exact generated-uninstaller cleanup/data-preservation
testing, then release remain the required order.

WIZ40/41 now have actual corrected component GREEN under unchanged pre-RED
verifiers: source cleanup-only returns false, body+Hide retains original error
after child termination, incomplete native setup exits20, and normal completion
exits0. Current source61c2 and bootstrap5b2994 syntax compile; the full diagnostic
EXE remains unexecuted. A new frozen279-row packet is undergoing a fresh-context
blinded same-session technical review; no approval is claimed. WIZ39 full-worker
composition verification and IM-UN-01 read-only ownership integration inventory
continue independently. Actual generated-uninstaller tests remain after production
installer qualification. Pending SDK consent and rejected prerequisite-acquisition
command preparation remain unresolved; no vendor retry or publication occurred.

WIZ39 full actual worker/supervisor composition now passes with exact archive
static rows and the actual handoff producer: completed reuse exits0, accepted
cancellation maps native worker1 to supervisor/status1223, both workers are
terminal at caller return, source hashes/inventory stay identical, and input/
target locks enforce then release. Root inspected the probe/log and independently
checked raw primary/input hashes and outcomes. Generated runtime/health are inert;
production dependencies, installed actual app, early wizard reuse and native
receipt renewal remain unverified. IM-UN-01 confirms a missing bounded cleanup
consumer/durable helper/native hook; no generated uninstaller has been tested.

The fresh WIZ40/41 blind technical review now passes its exact frozen component
scope. Root read and hash-checked the separate verdict; six supplied primary
record verifiers were independently replayed. Missing historical control closure
is explicitly excluded. This disposition qualifies neither full production
installer nor uninstaller. IM-UN-02 next proves a bounded owned-file removal
primitive on inert first-party fixtures; production native uninstall testing
still follows installer qualification and precedes release.

IM-UN-02 exact owned-file primitive now has behavioral RED/GREEN and root's
independent ordinary-user host test pass. Same native handle hashes and marks
the file for deletion; ancestor read handles exclude writes/renames, reparse and
foreign-writer paths are refused. A concrete directory sharing defect was caught
and fixed. Only inert first-party fixture files were used. No native uninstall
hook, authenticated durable helper delivery or whole receipt consumer exists yet.
IM-UN-03 is reconciling updater activation concurrency and native DAT ownership
before those changes. Actual generated-uninstaller qualification remains deferred
until the production installer works; no release or GPU qualification is claimed.

Later IM-UN-02 ADS preservation test is RED: unchanged default content with unknown
alternate-stream data is removed, and an actual compatible native ADS writer can
create data during hashing. The default-stream handle guard is insufficient for
file-wide preservation. Current helper is not ready for native integration.
Earlier component GREEN is retained at its narrower historical scope; assertion
and contract remain intact. IM-UN-03's returned native/selection decision is
planning evidence only; DAT runtime pinning and retirement still need resolution.

IM-UN-02 now fixes the two reproduced ADS-loss cases with bounded same-held-handle
stream guards before/after hashing; root independently reran the focused Windows
ordinary-user test successfully. Preexisting and observed during-hash unknown
streams survive. Current helper905b/test03c3 are explicitly UNQUALIFIED: a final
stream-query-to-disposition gap remains, and no ordinary nonparticipating writer
exception has been approved. IM-UN-04 records that contract/actor limit. No native
hook/durable delivery/complete receipt consumer or generated-uninstaller test
exists yet. Production installer qualification is still open (SDK consent and
rejected prerequisite-acquisition preparation unresolved). Keep the required
order: production installer works, then exact generated-uninstaller cleanup/data
preservation acceptance, then authorized release; NVIDIA hardware tests deferred.

IM-SEL-01 now implements participating updater serialization with native named
mutexes and complete transaction release. Root independently reran the focused
ordinary-user tests successfully; actual entry exclusion and inert full-lifetime
tests retain separate scopes. PS7, installed/cross-session behavior and immutable
older nonparticipants remain unverified. IM-UN-05 established no maintained
qualified whole-object removal mechanism; the unresolved ADS boundary is retained
and no TxF dependency or actor exception was adopted. Neither result qualifies
the generated uninstaller.

IM-VC-01 corrects the reproduced VC runtime3010 continuation: an explicit reboot
refusal now stops that source attempt. Meaningful actual-boundary RED/GREEN and
two affected acquisition regressions pass with inert process outcomes. Durable
reboot state, Inno restart classification and actual post-reboot capability still
need implementation/qualification. Bootstrap is now d44c9444; prior5b2994 evidence
and reviews do not approve these changed bytes. No new setup executable was built.

Current root checks: 16 manifest and11 guarded-build unit tests passed.
The actual CPU `verify-installer-manifest.py --require-installable` invocation
still rejects `ffmpeg-8.1.2.tar.xz` as a blocked native build asset; seven common
build prerequisites and nine native inputs remain BLOCKED. Required CPU routes,
pending SDK consent and the earlier automatic approval rejection of fresh VM
prerequisite-acquisition command preparation (`blocked by policy`) remain open.
That rejected action was not retried or bypassed. No production-ready claim,
actual generated-uninstaller execution, vendor installation or release occurred.

IM-PY-04 fixes a real reboot receipt handoff disagreement: the helper writes
PythonSetupLogs, while the prior consumer/diagnostic used obsolete Setup/logs/python.
One shared production path now serves helper arguments and receipt recovery.
Root independently reran eight actual generated-command behaviors with real
helper-produced inert receipts: same-boot pending3010 blocks; changed boot
allows normal verification; foreign/malformed/reparse state is preserved/refused.
The native diagnostic was compiled/exported only; native Pascal/reboot lifecycle
remain unexecuted. Current ISS is5397ac; historical61c2 evidence does not approve
these changed bytes. IM-VC-02 helper implementation is in progress and is not yet
wired into the wizard or compiler closure. No installer completion is claimed.

Current publisher CPU successor update (2026-10-02): IM-DEP-03 froze the prior
metadata correction; IM-DEP-04 independently qualified the exact fresh r2 native
component's source/notice distribution. IM-DEP-11/12 wired and packaged a distinct
consumer route. IM-DEP-13 records the actual CPU installability gate PASS and full
Inno compilation. This supersedes the earlier current CPU graph failure only for
the new publisher successor; v40 remains source-built and blocked. The r1 blind
technical review stopped at a concrete consent UI failure; IM-DEP-14's compiled
RED/GREEN correction passes root's repeat. New exact candidate review remains due.

The user has now explicitly selected normal uninstall cleanup: stop AutoClip and
its updater, verify owned files, preserve modified or unknown files. IM-UN-06/07
implement that bounded actor scope with existing ADS/path/integrity checks retained.
This resolves the earlier inferred requirement to atomically protect against
unrelated programs writing during deletion. No actual Setup/VM/application lifecycle,
generated-uninstaller acceptance or release has occurred. Preserve the required
order: working production installer, exact generated uninstaller tests, release.

Publisher CPU r2 (2026-10-02): exact 1154-member consumer graph and actual native
ZIP pass CPU installability; Inno compiles the new 3430296-byte candidate
`fafc1f92066325a68e59eb3acee05d0fc30921727aefc4c3b991308e75091e77`.
IM-UN-08 resolves Inno's exclusive DAT lifetime with verified prelaunch ownership
and a live handoff; root repeats of compiled hooks, actual exclusive-DAT cleanup
and positive Finalize CLI regressions pass. IM-DEP-13 records immutable new
artifact hashes, the fresh blind pre-VM review packet and current VM baseline.
Actual Setup/application/uninstall qualification and publication remain pending.

Publisher CPU r3 actual VM update (2026-10-02): fresh blind review passed the
exact candidate graph, 75 frozen hashes, 55 distinct Python tests, compiled
consent diagnostic and genuine short-TEMP FFmpeg regression. Actual retry reused
the existing exact Python and progressed beyond r2's FFmpeg failure into source
staging. It then failed at the shared downloader's `unexpected bytes or path`
guard; the exact attempt and live failure snapshot are recorded in IM-DEP-13.
IM-DEP-16 addresses this shared caller boundary. Complete installed application,
clean-baseline qualification, generated uninstaller and publication remain open.


Publisher CPU r7 progress (2026-10-02): actual r6 VM installed the official VC
runtime successfully, then exposed an incorrect DLL publisher check. IM-DEP-18
records actual-function RED/GREEN and retained strict vendor EXE verification.
New r7 Setup is 2ec0a2cb708e4b31f16fd4556bfea37f304fbc5d309cef176abe00575f1082e0;
CPU graph and focused VC regressions pass. The first frozen packet lost build
input timestamps and its blind review blocked source/binary correspondence.
A distinct packet preserves original timestamps; fresh blind review has rebuilt
the exact Setup byte for byte and is finishing its stated scope. Failed r6 VM
state and the blocked packet remain intact. New r7 clean clone is prepared;
post-fix installation, application, generated uninstall and release remain open.
