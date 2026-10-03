# IM-MS-09: TAR-qualified package-helper handoff

Status: TAR receipt-qualified package route implemented; host exact-artifact
fixture verification PASS with native and platform-query boundaries mocked.
Parent owns actual unelevated guest provisioning/transaction qualification.

## Authorization and bounded ownership

Parent authorizes only `installer/install-msys2-packages.ps1`,
`tests/InstallerMsys2Packages.Tests.ps1`, the socket test if required, and this
work order. Another writer will own base provisioning; root owns manifest,
contracts, downloader, bootstrap/Inno and guest operations.

Requirement from the [archive boundary](../contract-v1.md#msys2-archive-provisioning-boundary)
and [IM-MS-07](IM-MS-07.md)/[IM-MS-08](IM-MS-08.md): use the exact official TAR
instead of GUI EXE identity/Authenticode assumptions, require the bound qualified
base receipt before package execution, preserve trusted isolated local
signature verification, exact five packages, repository-free pacman, socket
bounds, code integrity, unrelated versions and capability checks.

## Executed RED

Tests now specify `-BaseArchivePath`, official TAR filename, archive kind/format,
and default planning without file mutation. Existing trusted-signature,
transaction, package/signature corruption and unrelated-package assertions
are retained. GUI filename and incorrect archive discriminators are explicit
rejection cases. Test-only `-RealBaseInstaller` is removed.

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File tests/InstallerMsys2Packages.Tests.ps1 -RealBaseArchive D:/AutoClip-Inno-Migration/msys-base-audit/msys2-base-x86_64-20260611.tar.xz -RealPackageDirectory D:/AutoClip-Inno-Migration/msys-pkgs -ShortFixtureParent D:/AutoClip-Inno-Migration
```

RED: `NamedParameterNotFound` for `BaseArchivePath`. No native MSYS2 or GUI
installer invocation was performed.

## Contract coordination and implementation

The proposed receipt fields and code-closure selector were sent to parent
before production work. Its proposed SYSTEM/Administrators-only write/owner
policy was **not accepted** because it conflicts with the unelevated per-user
route. Parent held changes, then accepted and appended the exact receipt
fields and the per-user policy in the canonical contract section
`Per-user base receipt and execution authority`.

A tentative production draft crossed that coordination boundary immediately
before the parent's hold message arrived. It was fully reverted, including
line endings; actual helper SHA256 is again exactly
`34e9d95adc8f9fbc07a29785fef1d8d741d442fb457c8e0c592f4306f80bb3d0`.
The socket test is untouched. No native execution or integration occurred in
that tentative draft.

Final implementation follows the accepted policy: explicit execution rejects
an elevated token before filesystem mutation/native commands. Owner and write
SIDs are current recipient, SYSTEM and Administrators. The extraction parent
and receipt directory require protected DACLs. Root/code descendants and the
receipt reject reparse ancestors, foreign writer ACEs (including generic and
inherit-only grants) and empty/null-rule DACLs. No ACL is modified by this helper.
Per-user evidence can never authorize elevated execution of recipient code.

`-BaseArchivePath` replaces `-BaseInstallerPath`; no GUI fallback or
Authenticode assumption remains. The default remains validation and readonly
planning. Explicit execution also requires `-BaseReceiptPath` and
`-BaseReceiptSha256` from trusted ordinary-user setup orchestration. It verifies
the exact official 53,555,380-byte TAR SHA256
`a2d047e8ee213c3c6a49a8de427eb1069df12207c0422ff1b3cbb5c905c34221`.

Required receipt fields are exactly the accepted schema: `schema_version: 1`,
`status: VERIFIED_PINNED_BASE`, `manifest_sha256`, `archive_sha256`,
`archive_bytes`, exact absolute `root`, Boolean true `signature_verified`,
`init_verified`, `first_login_verified`, `protected_root_verified`, and
`signer_fingerprint: 0EBF782C5D53F7E5FB02A66746BD761F7A49B0EC`.
`extraction_inventory` binds `receipt_sha256`, `file_count: 15529` and
`directory_count: 1052`. The protected base receipt carries this extraction
binding; parent/base writer retain the corresponding complete extraction
receipt outside the extracted root. `code_files` supplies relative `path`,
`bytes`, `sha256` for every regular file in `usr/bin/**`, `etc/profile.d/**`,
`etc/post-install/**`, `etc/msystem.d/**`, plus `etc/profile`, `etc/msystem`,
`etc/bash.bashrc` and `msys2_shell.cmd` after qualified
initialization.

The package helper independently enumerates that closure, compares exact
names/count/uniqueness, checks all bytes/hashes and ACLs, and retains all twelve
hardcoded base/keyring pins. Manifest hash, bound receipt/hash and complete
closure are checked before native execution and immediately before `pacman -U`.
The exact inspected TAR has 532 expanded closure files; the post-initialization receipt
defines the current verified set, which is independently enumerated rather
than assumed from that audit count. Setup supplies the trusted receipt hash;
arbitrary ambient receipt Booleans alone do not authorize this route.

The prior non-login isolated keyring, 108-byte socket bound, five trusted
signatures, Required TrustedOnly, no repositories/Include, exact preview set,
package/signature/config rehash, unrelated-package preservation and independent
capability assertions remain. A package receipt now includes
`base_receipt_sha256` for the chain. No elevated source-build authority,
rollback/activation or complete runtime success follows from this receipt.

## Additional RED and GREEN

The real TAR fixture independently caught two DACL mistakes before their
minimal fixes: foreign inherit-only write rules and empty/null-rule DACLs were
initially accepted. Each run failed with `Expected rejection: DACL|untrusted
write`; then the guard was fixed to reject those cases. The earlier exact TAR
`BaseArchivePath` RED remains the intentional public interface revision.

Executed from `D:/Projects/autoclip-runtime` under PowerShell 5.1:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File tests/InstallerMsys2Packages.Tests.ps1
powershell -NoProfile -ExecutionPolicy Bypass -File tests/InstallerMsys2SocketPath.Tests.ps1
powershell -NoProfile -ExecutionPolicy Bypass -File tests/InstallerMsys2Packages.Tests.ps1 -RealBaseArchive D:/AutoClip-Inno-Migration/msys-base-audit/msys2-base-x86_64-20260611.tar.xz -RealPackageDirectory D:/AutoClip-Inno-Migration/msys-pkgs -ShortFixtureParent D:/AutoClip-Inno-Migration
git diff --check
```

All GREEN. Exact-artifact tests manually copy the twelve pinned files and
complete expanded 532-file code closure from the locally authenticated official TAR.
Only native processes, the elevation query and `Get-Acl` platform query are
mocked; production guard decisions, actual filesystem/reparse enumeration,
package/base/code/receipt hashes and all trust/transaction assertions execute.
ACL queries return real .NET security objects with current-recipient ownership
and deliberately safe/unsafe ACEs. Test receipts simulate the base writer's
qualification; they are not actual native initialization/signature evidence.

Cases prove missing canonical pins; wrong or altered receipt hash; wrong
status/root/manifest/archive/signer; failed or string-valued verification flags;
missing/duplicate/injected code records/files; modified native DLL; directory
junction; elevated token with no native/mutation; unprotected/foreign-owner/
foreign/generic/inherit-only writer/empty DACL; and altered receipt/DLL after
preview before transaction. Existing package trust, exact-five, mutation,
version/capability and unrelated-package assertions remain enabled.

Primary ACL references:
[Microsoft FileSystemRights](https://learn.microsoft.com/en-us/dotnet/api/system.security.accesscontrol.filesystemrights?view=netframework-4.8.1),
[protected DACL property](https://learn.microsoft.com/en-us/dotnet/api/system.security.accesscontrol.objectsecurity.areaccessrulesprotected?view=netframework-4.8.1).

Original pre-follow-up frozen SHA256 (superseded below):

- Helper: `05ad6e985879d7e0eee39dd4734ae4266549984ad52410e3016e1a3129f97e48`.
- Package test: `263f13bd55042492cd509facd6e847e120a9d5b85fa6c3544f97f1e7abf86f44`.
- Socket test unchanged: `5b725261bf063f862a4e9820a476f62079e8134c1e56264116390a8ff2191ec5`.

Remaining: base writer's protected ordinary-user receipt production, qualified
initialization/first login and real trusted transaction in the guest. Parent
owns canonical manifest/downloader/integration and VM; production MSYS2
classification stays BLOCKED until qualified. No host MSYS2 installation,
default keyring modification, VM control, complete provisioning, technical
independent review, vendor-rights/legal approval or publication occurred here.

## Authorized startup, snapshot and environment follow-up

Root identified additional sourced startup files in the actual archive:
`etc/profile` loads `etc/msystem`, which loads `etc/msystem.d/MSYS`, and
`etc/bash.bashrc`. The original 524-file selector omitted these. Root
intentionally expanded the canonical selector with both literal files and all
six regular `etc/msystem.d/**` variants (532 files in this exact TAR), and
authorized this bounded consumer correction. The base writer and package
consumer now use that same selection.

Meaningful RED: the exact artifact fixture wrote all expanded files but passed
the old 524-file receipt set. The old helper accepted it and the test failed
`Expected rejection: code closure`. The two-line selector change makes that
receipt fail before any native invocation. Tests also modify `etc/msystem`,
`etc/bash.bashrc` and `etc/msystem.d/MSYS` individually; unchanged complete
expanded selection passes and each alteration rejects before native execution.

Root appended `Package receipt and source-build startup` to the canonical
contract and authorized the additive returned package receipt interface:
`schema_version: 1`, lowercase 64-character `manifest_sha256` and
`base_receipt_sha256`, `private_home` copied from the authenticated base
receipt, and `post_install_code_files` with the complete expanded selection's
actual relative paths, sizes and hashes after successful trusted transaction,
version/unrelated-package and capability checks. Its fields are an intentional
receipt contract change for the future source-build consumer. The helper does
not write a durable package receipt; trusted parent orchestration captures it
in a protected directory and binds that file's hash.

Meaningful receipt RED: after correcting the startup selector, the real fixture
failed `Qualified package receipt must bind schema, lowercase hashes, private
HOME and the complete post-install code snapshot.` The minimal change now
requires the base receipt's private HOME to equal the owned root's
`home/autoclip-base`, checks that directory and its parent ACL/reparse state,
retains the validated receipt for copying the field, checks unchanged
manifest/base receipt hashes after transaction, independently enumerates the
post-install selection, and checks every file's ACL and actual bytes/hash.
Original base hashes are checked before `-U`; they are not compared to the new
post-install selection because trusted packages may legitimately add/replace
code. A native-boundary transaction fixture adds a new DLL and proves the
returned selection records its bytes/hash. An unsafe post-install ACL fails
before returning a trusted package receipt. The query fixture also records and
asserts an ACL check for every returned code file.

Root separately authorized the canonical environment correction. RED:
seeded ambient HOME, strict-path controls, hooks, PS1/XDG config and exported
Bash function reached the mocked native boundary, which failed
`Ambient startup environment reached native execution.` The helper now uses
the same 21-name allowlisted clearing/saving/restoring block as the base
producer, plus every process environment name matching `BASH_FUNC_*`. It sets
PATH to the verified root's `usr/bin`, `ucrt64/bin`, and System32; HOME to the
validated base HOME's MSYS drive path; isolated GNUPGHOME; `MSYSTEM=MSYS`,
`MSYS2_PATH_TYPE=strict`, and `CHERE_INVOKING=1`. It restores every saved value
in `finally`, including failure paths. Tests assert that all ambient hooks
are absent at bash entry and caller values are restored after success and
each native failure case. No helper abstraction or global PATH write added.

The same three PowerShell commands above were rerun: default validation,
socket allocation, and complete real TAR/five-package fixture all PASS.
`git diff --check` PASS (existing unrelated LF/CRLF warnings). Actual file
hashes and reparse enumeration execute; native execution, elevation and ACL
queries remain mocked. No native MSYS2 initialization, package installation,
or VM operation was performed here. Private HOME contents are still the
future source-build guard's separate archive-derived verification boundary;
the package helper does not source HOME during its non-login transaction.

Updated frozen SHA256:

- Helper: `a467f4b665f8d296e5db33d0c463a12d7b146ebb642d2aa1c155afba2f8cad79`.
- Package test: `768e0a953a58e762d0c9e70d4fb15f10f249cc25329fcc465d0d9bd1f64335e8`.
- Socket test unchanged: `5b725261bf063f862a4e9820a476f62079e8134c1e56264116390a8ff2191ec5`.

Parent owns the actual ordinary-user guest chain, durable receipts and guarded
source-build qualification. This follow-up does not qualify whole setup,
release/publication, independent review or vendor/legal decisions.

## IM-MS-11: include UCRT64 code in the package snapshot

Parent authorized this concrete follow-up after source-build inspection found
that the controlled build PATH executes `ucrt64/bin/nasm.exe` and uses its zlib
DLL. Root extended the canonical `post_install_code_files` selection to the
expanded base/startup selection **plus every regular `ucrt64/bin/**` file**.
The base receipt selector remains 532 files from the pinned TAR. Ownership
remains only this helper/test/report; no other writer's files were changed.

Meaningful RED used the same exact TAR/package fixture command above. Its
mocked trusted transaction creates known NASM/zlib fixture bytes under the
actual disposable `ucrt64/bin`. The old helper returned no matching snapshot
records and failed `Post-install snapshot must include UCRT64 NASM and zlib
DLL code.` Production then changed only three lines: reuse
`Get-Msys2CodePaths` with an internal `-PostInstall` switch that adds the UCRT64
directory to its traversal only for the post-install snapshot. Calls that
validate the original base receipt do not select UCRT64.

GREEN verifies both exact NASM/DLL relative names, actual sizes/lowercase hashes,
and an ACL query for every returned code file. A foreign writer ACE injected
only on the zlib DLL fails the actual guard and prevents a trusted receipt;
the containing directory retains its safe test ACL. A later transaction can
add another code file and the snapshot includes it without comparing the new
state to the old base hashes. All prior signature/transaction/capability,
startup, ambient environment/restore, per-user/elevation, receipt, mutation,
unrelated-package and reparse checks remain enabled.

Default, socket and full exact-artifact commands above all PASS; diff check
PASS (existing unrelated line-ending warnings). Native processes, elevation
and ACL platform queries remain mocked; actual files, inventory enumeration,
hashes and guard decisions execute. NASM/zlib additions are explicit test bytes,
not installed or redistributed vendor binaries. No native MSYS2 invocation,
host installation or VM operation was performed by this follow-up.

Evidence boundary agreed with parent: the producer records trusted transaction
bytes and verifies their ACLs. It does not gain a separate signed-package
installed-file inventory or claim that a safely writable file modified before
snapshot capture would be rejected against an independent NASM/DLL byte pin.
Missing/changed code **after** snapshot capture must be rejected by the future
source-build consumer against the protected bound package receipt; root's
source-guard writer owns those actual tamper tests. No separate package archive
extraction or extra pin interface was introduced.

Final IM-MS-11 frozen SHA256 (supersedes prior candidate hashes):

- Helper: `889dc7106dcc5c076dbe08aca8d45726dfe22edb7d199839755d60bd26a2a48b`.
- Package test: `1cbb58b616598de008011830c80d2dd1957f5da718a59625f30363937dc938fe`.
- Socket test unchanged: `5b725261bf063f862a4e9820a476f62079e8134c1e56264116390a8ff2191ec5`.

Real guest chain, durable protected receipt, complete source build/setup,
review, rights/legal and publication qualification remain with parent.
