# IM-MS-03: explicit pinned MSYS2 package execution

Status: explicit branch implemented and host fixture checks pass; live guest
trusted-signature installation and complete setup qualification remain pending.
Production dependency classification remains BLOCKED.

## Authorization and ownership

Parent work order IM-MS-03 explicitly authorizes this bounded behavior revision.
Owned files: `installer/install-msys2-packages.ps1`,
`tests/InstallerMsys2Packages.Tests.ps1`, and this work order. Other writers own
the manifest, Inno source, bootstrap, shared documentation and guest operations.
No host MSYS2 installation/update/key initialization or VM operation was performed.

Requirement: implement the exact offline, trusted five-package transaction from
[IM-MS-01](IM-MS-01.md), using the authenticated delivered base/keyring snapshot
from [IM-MS-02](IM-MS-02.md), under the [installer contract](../contract-v1.md).
Public/domain change: additive explicit `-InstallPinnedPackages` switch and
MSYS2 `installed_files` records. The default remains input validation and
non-executable transaction planning. The optional executing route returns a
package verification receipt only; it does not activate AutoClip or qualify setup.

## Implemented execution boundaries

Execution fails before native commands unless every ordinary input is DIRECT,
the original signed GUI installer has its exact version/hash/size and valid
Christoph Reiter Authenticode, and all twelve delivered-file records AND local
bytes match the hardcoded authenticated IM-MS-02 snapshot. Installed records
inherit the base's classification. Missing, duplicate, extra or changed
installed-file records fail closed.

A new GUID directory under the supplied root's `etc/pacman.d/autoclip-pinned-*`
holds AutoClip's isolated keyring. The helper never reuses the shared gnupg
directory or imports host trust. It creates a unique repository-free config
with Required TrustedOnly for both ordinary and local signatures. Input and
keyring parent reparse points are rejected. The caller still owns full clean
signed-GUI provisioning, protected staging/ACLs and the complete base DLL
closure; twelve individual file checks do not establish those broader facts.

Fixed non-login bash arguments run shipped `pacman-key --init` and
`--populate msys2` separately with explicit `--gpgdir` and
`--populate-from`. No login shell, refresh, receive, manual ownertrust,
TrustAll, relaxed SigLevel or caller signature exception is added. PATH and
GNUPGHOME are fixed for the operation; BASH_ENV and ENV are cleared. Changed
environment values are restored in finally.

Each exact detached package signature is then checked directly with delivered
GPG: native exit 0, VALIDSIG for
`5F944B027F7FE2091985AA2EFA11531AA0AA7F57`, TRUST_FULLY or TRUST_ULTIMATE, and
no bad/expired/revoked/error signature status. No automatic key retrieval is
allowed. This avoids relying solely on the shipped pacman-key verification
pipeline or exit status.

The pacman config has no repository, Include or Server. The helper snapshots
installed versions, requires the exact keyring package, previews the fixed local
-U operation and rejects anything outside the exact five-name/version set.
Immediately before -U it rechecks installed provenance, base bytes, every
package/signature, the manifest and config. All native calls require exit 0.
Afterward it verifies unchanged pinned base files, all five installed versions,
unchanged unrelated package-version rows, GNU Make 4.4.1, GNU diffutils 3.12,
pkg-config 3.0.7 and NASM 3.02. Version prefixes such as NASM 3.02.1 fail.

On any failure there is no successful package receipt. Partial changes in this
recipient prerequisite root are possible once -U starts; the helper does not
claim rollback of vendor prerequisites. AutoClip activation is the parent's
separate verified-state gate. Fresh keyring/config files remain available for
diagnosis and the receipt on success identifies their paths and manifest hash.

## Upstream certification-import allowance

The hash-pinned upstream populate script uses
`--allow-weak-key-signatures` for MSYS2-keyring issue 45. The caller does not
add that flag or an ownertrust override. IM-MS-02 independently checked valid
certifications of the selected developer from three delivered masters:
D55E... using digest algorithm 8 (SHA-256), 69985... using 8 and 6E8... using
10 (SHA-512). Those selected certifications therefore do not require acceptance
of SHA-1 certification signatures. The pinned populate script still imports the
whole upstream ring with its existing allowance; this boundary is retained for
technical review, not described as eliminated or legal approval.

## Additive manifest records

The parent may insert this array as the MSYS2 entry's `installed_files` after
review. It does not authorize changing the production BLOCKED classification.

```json
[
  {
    "path": "etc/post-install/07-pacman-key.post",
    "sha256": "19badd8d5d7e0052028c466fc1eb7fcf8f7e1fb50cb832be389922047897ef3e",
    "bytes": 300
  },
  {
    "path": "etc/profile",
    "sha256": "3368d6f88af0daf8f3df1eb563e6c351bf9e336f40b826bd94486c18183602ff",
    "bytes": 5475
  },
  {
    "path": "usr/bin/pacman-key",
    "sha256": "5d2e5e67ca59e49e84d5f0b2f7e4166e3783f707cd2292c09ce61a79c7cc149f",
    "bytes": 23497
  },
  {
    "path": "usr/share/pacman/keyrings/msys2-revoked",
    "sha256": "62b67ba0217745c7df189092a70d6b7a5781577f6428a5391dccd897edb5756a",
    "bytes": 164
  },
  {
    "path": "usr/share/pacman/keyrings/msys2-trusted",
    "sha256": "a8d39040a7b6cc14bf4394b5d9c838443925c32b00a7d34e8729c972392dca04",
    "bytes": 220
  },
  {
    "path": "usr/share/pacman/keyrings/msys2.gpg",
    "sha256": "79cc43bd8b8a4e8c952340adc0ae93d3ff8e50c40f244321cf58fa014282f4ea",
    "bytes": 54878
  },
  {
    "path": "var/lib/pacman/local/msys2-keyring-1~20260214-1/desc",
    "sha256": "a72e90c5db7abb1280f295f51cc6c6d35c837d10f39d72d0379122bd9518014e",
    "bytes": 342
  },
  {
    "path": "usr/bin/bash.exe",
    "sha256": "41b09f0a9c1c68fd65253a7e8087b3775f0af245b729ade74ca4425d14392c2d",
    "bytes": 2452446
  },
  {
    "path": "usr/bin/pacman.exe",
    "sha256": "209b2d527f359608cdb092515d3d99f46ac9d2209d130adced81a8cdd79057d8",
    "bytes": 10765942
  },
  {
    "path": "usr/bin/gpg.exe",
    "sha256": "a5140c85353e8399da8d6bd7e3741524cd76a4e69be88af12042b1c9ef022984",
    "bytes": 1130330
  },
  {
    "path": "usr/bin/gpgv.exe",
    "sha256": "f4d13204d77fdf63c02b0e6742230f83a833128c28f7b715709c2c63a96c427b",
    "bytes": 514306
  },
  {
    "path": "usr/bin/pacman-conf.exe",
    "sha256": "12f4d59306fc83366a950923c9a70fa3c045fc0a6aa706e622ea30acff918726",
    "bytes": 10713395
  }
]
```

## RED and focused GREEN

Before production edits, the exact execution fixture command failed with
`A parameter cannot be found that matches parameter name 'InstallPinnedPackages'.`
This is the expected absent explicit-install behavior.

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File tests/InstallerMsys2Packages.Tests.ps1 -RealBaseInstaller D:/AutoClip-Inno-Migration/msys2-x86_64-20260611.exe -RealPackageDirectory D:/AutoClip-Inno-Migration/msys-pkgs -RealBaseArchive D:/AutoClip-Inno-Migration/msys-base-audit/msys2-base-x86_64-20260611.tar.xz
```

GREEN: exit 0. The test extracts only twelve exact regular TAR members into a
TEMP fixture, copies only the selected package/signature inputs, and replaces
only Invoke-PinnedMsys2 in the production AST. File hashes, Authenticode,
manifest/config construction and all sequencing/verification logic are real.
Actual host package/key native commands are never invoked. The process wrapper
is separately exercised with Windows cmd `/d /c exit 13` and rejects that exit.

Covered failures: incomplete/altered provenance before any native call, init
failure, missing trust, wrong signer, extra transaction package, wrong selected
versions, unrelated-package change, wrong capabilities, near-matching NASM
version, and signature/provenance changes after preview. Every early failure
asserts that installation was not called. These supplement existing real-byte
hash/classification/identity/set/path checks.

The first fixture run after implementation exposed Windows PowerShell 5.1
ConvertFrom-Json array metadata being serialized as a value/Count wrapper.
The test now materializes plain arrays and checks all twelve records before
execution; this setup correction did not alter production requirements or pins.

Default validation regression also passed:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File tests/InstallerMsys2Packages.Tests.ps1
```

## Parser and whitespace verification

PowerShell 5.1 parser checks passed for both scripts:

```powershell
$paths=@('installer/install-msys2-packages.ps1','tests/InstallerMsys2Packages.Tests.ps1')
foreach ($path in $paths) {
    $tokens=$null; $errors=$null
    [void][Management.Automation.Language.Parser]::ParseFile((Join-Path (Get-Location) $path),[ref]$tokens,[ref]$errors)
    if ($errors.Count) { throw ($errors | Out-String) }
}
git diff --no-index --check -- /dev/null installer/install-msys2-packages.ps1
git diff --no-index --check -- /dev/null tests/InstallerMsys2Packages.Tests.ps1
git diff --no-index --check -- /dev/null docs/installer-migration/work-orders/IM-MS-03.md
```

No-index diffs return 1 for new files differing from /dev/null. No whitespace
diagnostics remain; working-copy LF/CRLF notices are not check failures.

## Parent guest evidence and remaining gates

The parent reports it executed an independent TAR-to-installed-GUI comparison
of all twelve files, with exact size/hash equality, recorded in
`D:/AutoClip-Inno-Migration/vm-msys-state-20261001.json`.
I independently rechecked that evidence file's SHA-256:
`774a59fd3c5cc067fb534424279876d73d220c09114d7e3c71545ce604d06ea8`.
I did not perform guest operations or independently repeat the guest comparison.

The parent also reports non-login pacman -Q works in the guest, while an
exploratory base provision process remains hung after its vendor log's success.
No completed provisioning receipt is inferred. The default-login key-refresh
investigation, live isolated-keyring trust, actual package acceptance/rejection,
dependency closure, native post-install capabilities, final installer integration
and clean AutoClip workflow remain parent gates. Host mocks cannot close them.

Primary contracts and research remain linked in IM-MS-01/02:
[official installer guide](https://www.msys2.org/docs/installer/),
[official keyring trust model](https://www.msys2.org/dev/keyring/),
[pacman manual](https://man.archlinux.org/man/pacman.8.en), and
[pacman.conf signature policy](https://man.archlinux.org/man/pacman.conf.5.en).

Suggested commit message:
`installer: add explicit offline trusted MSYS2 package verification`.
