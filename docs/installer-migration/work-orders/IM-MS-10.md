# IM-MS-10: ordinary-user pinned MSYS2 base provisioning

Status: helper implemented; focused plan and isolated guard tests PASS. Full
ordinary-user extraction, OpenPGP verification, initialization and first-login
qualification remain with the parent guest. Canonical delivery routes remain
BLOCKED. No complete base qualification, installer approval, vendor agreement,
publication or commit is claimed.

## Authorization and contract

Parent authorized only `installer/install-msys2-base.ps1`,
`tests/InstallerMsys2Base.Tests.ps1` and this report. Other writers own manifest,
downloader, contracts, package consumer, Inno and VM. The
[base receipt contract](../contract-v1.md#per-user-base-receipt-and-execution-authority),
[runtime architecture](../../runtime-update-architecture.md),
[IM-MS-07](IM-MS-07.md) and frozen [extractor](IM-MS-08.md) govern this helper.
No frozen Python/extractor/Inno helper was changed.

The helper accepts the work-order input paths and pins, fresh DestinationParent,
fresh LogDirectory outside that parent, optional CancelPath, and explicit
InstallBase. Default is read-only `PLANNED_PINNED_BASE`: no managed file writes,
extraction or native child invocation. Elevated tokens are rejected. Inputs
require schema 1, exactly one case-unambiguous MSYS2 identity, the exact official
20260611 TAR, detached signature and installer key, explicit DIRECT parent and
child classifications, and setup-bound manifest SHA256. Duplicate manifest
properties, unsafe/reparse paths, substituted/nonfixed/non-NTFS volumes, long or
non-ASCII extraction parents, existing foreign/partial targets and nested receipt
directories are rejected.

InstallBase locks manifest/archive/signature/key/extractor/Python-helper/Python
inputs against writes/deletion and rechecks pins. It invokes the fixed sibling
Python helper CheckOnly, requiring its exact returned full-interpreter path to
match PythonPath. It creates protected current-recipient/SYSTEM/Administrators
DACLs with current-recipient ownership, writes durable pending ownership outside
the extraction parent, then uses the frozen stdlib extractor. The complete
extraction receipt is captured outside the parent and requires 15,529 files,
1,052 directories, matching identity and actual file inventory. Failure preserves
partial roots; no recursive root removal or automatic reuse is implemented.

Before direct native GPG, the full extracted inventory and code/DLL closure are
verified. Native executables are absolute, CWD is verified usr/bin and PATH is
restricted to it plus Windows System32. OpenPGP arguments use `/c/...` conversion;
Windows drive paths are not passed to MSYS-native GPG. Exact installer primary
fingerprint and exact detached-signature signing subkey/primary are required
before any bash. The signature homedir is fresh/protected outside the root.

Local default pacman-key init and populate run separately with non-login bash.
All signed delivered master fingerprints must have full/ultimate validity;
primary fingerprint is bound to its pub key ID, subkey/status aliases are not
accepted. Delivered revoked keys must be revoked or disabled. Agents are scoped
to this fresh root and stopped. Exactly one upstream login follows only after
default gnupg exists and passes trust validation, causing the signed upstream
07-pacman-key branch to skip refresh. No repository or keyserver command is added.

Fresh private HOME is `/home/autoclip-base`. Verify native device directories,
the documented mtab target `/proc/mounts`, executable capabilities, exact Windows
etc copies and every signed skeleton copy with no extra HOME entries. Recheck
original archive inventory after initialization and reject new paths outside
the documented default-keyring/device/HOME/Windows-copy effects. Only mtab is
excluded from the no-reparse tree walk after native link-target verification.
Code closure includes usr/bin, profile.d, post-install, msystem.d, etc/profile,
etc/msystem, etc/bash.bashrc and msys2_shell.cmd; it is rechecked before native
execution and final receipt. This aligns with the revised package consumer.

Clear BASH_ENV, ENV, GNUPGHOME, ambient PS1/XDG configuration, ORIGINAL_PATH,
CYG_SYS_BASHRC, conversion overrides and exported BASH_FUNC_* functions; constrain
HOME/MSYSTEM/MSYS2_PATH_TYPE/CHERE_INVOKING/PATH. Restore caller process environment
and CWD in finally. Native output/exit records are durable. Cancellation or a
600-second native step timeout stops that exact process/descendants and preserves
state. Finally stops detached gpg-agent processes only by the exact fresh-owned
executable path. A cancellation flag is checked before publishing a verified
receipt, including immediately before the atomic move.

Accepted receipt contains all canonical schema-1 VERIFIED_PINNED_BASE fields,
Boolean verification flags, exact signer, full extraction receipt SHA/counts and
actual code_files path/bytes/hash records. Extras private_home (absolute Windows)
and private_home_msys bind the private startup context. Stdout returns status,
root, receipt_path, receipt_sha256 and private_home. Early guard failures mutate
nothing; owned-stage failures retain failure.json and native/extraction evidence.

## TDD and focused commands

Initial RED, before source creation:

```powershell
& .\tests\InstallerMsys2Base.Tests.ps1
```

The public default invocation failed because the helper did not exist. Subsequent
meaningful REDs demonstrated empty-DACL acceptance, missing actual msystem/bash
startup closure, cancellation publishing a verified fixture receipt, and swapped
primary fingerprints being accepted. Each was fixed and the same assertions
passed. An initial isolated trust test also failed before its parser function
existed; the final test uses two first-party master IDs, rejects a missing second
master and swapped pub/fpr identities, and rejects invalid revoked state.

Final verification:

```powershell
& .\tests\InstallerMsys2Base.Tests.ps1
git diff --check -- installer/install-msys2-base.ps1 tests/InstallerMsys2Base.Tests.ps1 docs/installer-migration/work-orders/IM-MS-10.md
```

Results: PASS. Default plan reads exact local archive/signature/key using a
separate explicit DIRECT fixture manifest; canonical classification is unchanged.
Actual path/hash/atomic receipt/ACL/closure/cancel/parser guards are exercised
with first-party component fixtures. Token elevation is mocked only at its
isolated read-only query. Process environment restoration is exercised under a
simulated failure. No manufactured 15,529-file successful installation fixture is
accepted. Final host tests contain no InstallBase invocation, native invoker,
Start-Process or vendor executable call. First-party unit scratch is preserved.

Frozen helper SHA256:
`309ee54200c2e2b07fb8b7137ae092ee46dd204901edc55eab40b410e8da7be7`.

Frozen test SHA256:
`b6dbdbe38f6528fea3512d555d2a39c1e423d007df7385de0a43269fa067c024`.

Frozen dependencies remain:

- extractor: `23307cdbcafd03fb0d03b209cb2dceb35a4e2eed99c2ecfccda9571374fc1596`;
- sibling Python helper: `081b312795cc8b038de2ce511d2a8baabd23ffec55f7ef2f7269dbbb105f02e3`.

## Host test-boundary incident: preserved partial extraction

A draft elevated-token test overrode a proposed query function before that
function existed and invoked the operational body. This bypassed the intended
test interception: existing verified Python CheckOnly ran, then real Python
stdlib extraction began on the host. This violated the work order's intended
host boundary. The exact extractor PID **37180** was stopped before it returned
and before the helper reached OpenPGP or bash phases. No archive-delivered
GPG/bash or package command was launched by that helper. No complete base
installation, vendor agreement or qualification occurred.

`C:\acmb-492cbb00` remains preserved, with **14,546 files and 1,052 directories**.
The root is owned by BLI2002\beilo with protected DACL. The original draft test's
finally cleanup removed its separate temporary fixture/log directory; this is
recorded as lost staging evidence, not represented as a durable base receipt.
All further unit scratch cleanup was disabled. No root or additional incident
output was deleted after parent instructed preservation.

Read-only durable evidence:
`D:\AutoClip-Inno-Migration\im-ms-10-host-extraction-incident-b66b07cb99a14f88915c06ba9ecbc8f8\incident.json`.
SHA256:
`b7a2f15bf59c099247b28193d5cc47676727bc94d608ddda6c47e3b78f733737`.
It records every remaining file path/size/hash, directory path, root SDDL/owner,
historical source/test/extractor/Python-helper hashes, terminated PID and an empty
targeted live-child result. A later targeted process check was also empty.
These read-only hashes are evidence of the preserved partial tree, not authority
to execute it, delete it, or treat it as a qualified receipt.

The harness was corrected before resuming: public host invocations are default
planning only; remaining guards are called as isolated actual functions. No
operational provisioning body is invoked by final host tests, so absent guards
in future RED cases cannot initiate extraction through those function checks.

## Remaining qualification and limits

Parent must run full InstallBase on a fresh ordinary-user guest, verify complete
archive/DLL inventory and native execute modes, direct GPG/path/fingerprint/
signature handling, all five master trust states, skipped refresh while online,
exactly one upstream login effects, protected descendants, default-agent cleanup,
failure/cancel/timeout preservation and consumer receipt acceptance. Frozen
extractor's chmod on Windows does not itself prove POSIX permission bits; this
helper's native executable checks still require guest evidence.

Full operation and full installed receipt were not qualified by the final unit
suite. Complete five-package transaction, source build, wizard/lifecycle/media
validation and release gates remain separate. No endpoint setting or protection
exclusion was changed, no detection-evasion candidate was created, and frozen
Python wizard diagnostics remain untouched.
