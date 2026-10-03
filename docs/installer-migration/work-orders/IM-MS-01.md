# IM-MS-01: pinned MSYS2 validation and transaction plan

Status: validation and transaction construction implemented; recipient execution
BLOCKED on exact installed-base/keyring provenance. No host MSYS2 or VM was
installed, updated or initialized.

## Authorization, ownership and behavior

Parent work order IM-MS-01 explicitly authorizes this bounded implementation for
the conventional Inno Windows source-build installer. Ownership is limited to
`installer/install-msys2-packages.ps1`,
`tests/InstallerMsys2Packages.Tests.ps1`, and this work order. Other writers own
the manifest, Inno source, acquisition helper, bootstrap and shared documentation.

The requirement is the exact, trusted, offline five-package transaction stated
in the parent work order and the [installer contract](../contract-v1.md), Inputs
and dependency policy / Wizard step 3. The [runtime architecture](../../runtime-update-architecture.md)
requires verified immutable dependencies before activation. The existing
[evidence](../evidence-2026-10-01.md), Later CPU dependency audit / Same-session
dependency route audits, identifies the unproved keyring route.

The authorized fallback applies: validate exact base/package/signature bytes
against a separately trusted manifest, require DIRECT_RECIPIENT_DOWNLOAD for
every input, require the fixed five identities/versions/filenames, and return
transaction/configuration/check plans with execution_allowed=false. This is
not an install entry point. It does not acquire, write configuration, initialize
keys, invoke pacman, or run capabilities. An unchanged production manifest with
BLOCKED MSYS2 cannot pass validation. Test manifests declare DIRECT solely to
exercise validation; this is not approval or promotion of the real manifest.

Contract impact: proposed additive MSYS2 filename/packages/signature metadata
within schema v1; no existing runtime identity or public bootstrap changes.
The parent must review and integrate metadata intentionally. Unknown schema,
missing/duplicate identities, wrong versions, malformed/mismatched hashes,
signature pins/classifications, and input reparse paths fail closed.

## Transaction construction

The returned config has only [options], explicit RootDir/DBPath/GPGDir,
Architecture=x86_64, SigLevel=Required TrustedOnly and
LocalFileSigLevel=Required TrustedOnly. It contains no repository, Include or
Server. Missing dependencies therefore cannot be acquired from sync repositories
when this plan is eventually executed; this remains unexecuted here.

Fixed future pacman arguments:

- Preview: `-U --config <root>/etc/autoclip-pinned-packages.conf --noconfirm <exact five local paths> --print --print-format "%n %v"`.
- Install: `-U --config <same config> --noconfirm <same five local paths>`.
- Versions: `-Q diffutils make mingw-w64-ucrt-x86_64-nasm mingw-w64-ucrt-x86_64-zlib pkgconf`.
- Capability plans: `usr/bin/make.exe --version` = GNU Make 4.4.1,
  `usr/bin/diff.exe --version` = GNU diffutils 3.12,
  `usr/bin/pkg-config.exe --version` = 3.0.7,
  `ucrt64/bin/nasm.exe -v` = NASM 3.02.

The pure Assert-Msys2Transaction validator rejects any missing, extra, duplicate
or changed name/version. A future executing route must call it on the preview,
revalidate input bytes immediately before execution, verify signatures with the
proven pinned keyring, require exit code 0, verify installed package versions and
execute all capability checks. It must also prove unchanged pre-existing
package state outside these five, preserve the active AutoClip release, protect
staging from modification, and reject unrelated/existing/reparse target roots.
This work order does not implement or claim any of those execution checks.

## Base identity and keyring limit

Locally rechecked base: 94,016,640 bytes, SHA-256
`3150d7d9aa5dedd900a7f52300d4d918271e3a8fc47de94848818fd5a430e6b0`.
Get-AuthenticodeSignature returned Valid, subject
`CN=Christoph Reiter, O=Christoph Reiter, L=Graz, C=AT`, certificate thumbprint
`47F81859AE612659DD2248E76A58347A073B2933`.

This establishes signed base-file identity; it does not bind an already installed
recipient root or initialized trust database to those base bytes. The audit
directory has no detached base signature or extracted pinned keyring snapshot;
`gpg-verify-home` contains only trustdb.gpg. Existing evidence records package
cryptographic verification using the host keyring; it explicitly does not
establish base-keyring provenance or clean-machine initialization. I did not
repeat that host-keyring verification or substitute it for recipient trust.

Before enabling execution, inspect/extract the exact signed base in an isolated
authorized staging route, record its msys2-keyring version and delivered
keyring/ownership files by hash, establish expected master/developer fingerprints
and trust chain from those bytes, prove the installed recipient base files
against that snapshot, and test required trusted local signatures with the
five exact packages and altered/missing/untrusted signature rejection. Do not
import a host keyring, fetch current keys implicitly, assign arbitrary owner
trust, use TrustAll/Optional/Never, or refresh/update mutable repositories.

Primary research: [MSYS2 installer](https://www.msys2.org/docs/installer/)
documents base composition, supported CLI syntax, checksum/signature validation
and its installer PGP primary fingerprint
`0EBF782C5D53F7E5FB02A66746BD761F7A49B0EC`.
[MSYS2 keyring](https://www.msys2.org/dev/keyring/) documents the master/developer
trust model. Neither identifies the exact delivered 20260611 keyring.
[Official pacman manual](https://man.archlinux.org/man/pacman.8.en) states that -U
can resolve dependencies from sync repositories and documents --print /
--print-format. [Official pacman.conf manual](https://man.archlinux.org/man/pacman.conf.5.en)
defines Required / TrustedOnly / LocalFileSigLevel. The exact MSYS2-shipped
pacman behavior is still subject to recipient-route verification.

## Proposed manifest record (not promoted)

All eleven input sizes/hashes below were computed from the exact local files.
BLOCKED is deliberate; future DIRECT classification requires the parent gate.
The parent should merge required purpose, profile, detection, license, execution
and reboot evidence from its contract inventory. Do not use this pin excerpt
as a completed installable dependency disposition.

```json
{
  "identity": "MSYS2",
  "version": "20260611",
  "architecture": "x64",
  "filename": "msys2-x86_64-20260611.exe",
  "url": "https://github.com/msys2/msys2-installer/releases/download/2026-06-11/msys2-x86_64-20260611.exe",
  "bytes": 94016640,
  "sha256": "3150d7d9aa5dedd900a7f52300d4d918271e3a8fc47de94848818fd5a430e6b0",
  "delivery_classification": "BLOCKED",
  "packages": [
    {
      "identity": "diffutils",
      "version": "3.12-1",
      "architecture": "x86_64",
      "filename": "diffutils-3.12-1-x86_64.pkg.tar.zst",
      "url": "https://repo.msys2.org/msys/x86_64/diffutils-3.12-1-x86_64.pkg.tar.zst",
      "bytes": 394515,
      "sha256": "7902c8ce3d4dd69a0f5e98dc9d5c83c17b23314ba486169db57ef6e2835ce3b6",
      "delivery_classification": "BLOCKED",
      "signature": {
        "filename": "diffutils-3.12-1-x86_64.pkg.tar.zst.sig",
        "url": "https://repo.msys2.org/msys/x86_64/diffutils-3.12-1-x86_64.pkg.tar.zst.sig",
        "bytes": 566,
        "sha256": "f25457caac4b77e5341e8fd02a53e696a023024ed398992eec199a43fd26c811",
        "delivery_classification": "BLOCKED"
      }
    },
    {
      "identity": "make",
      "version": "4.4.1-3",
      "architecture": "x86_64",
      "filename": "make-4.4.1-3-x86_64.pkg.tar.zst",
      "url": "https://repo.msys2.org/msys/x86_64/make-4.4.1-3-x86_64.pkg.tar.zst",
      "bytes": 514683,
      "sha256": "af0bdba17f06fe037f0194069adaa31a8fe45f1a11381501896aea1fae37bd5d",
      "delivery_classification": "BLOCKED",
      "signature": {
        "filename": "make-4.4.1-3-x86_64.pkg.tar.zst.sig",
        "url": "https://repo.msys2.org/msys/x86_64/make-4.4.1-3-x86_64.pkg.tar.zst.sig",
        "bytes": 566,
        "sha256": "7f53c96aeb1a29d9917e2b00e9f709fbdc5b0458e6535e88b1fed69365191265",
        "delivery_classification": "BLOCKED"
      }
    },
    {
      "identity": "mingw-w64-ucrt-x86_64-nasm",
      "version": "3.02-1",
      "architecture": "any",
      "filename": "mingw-w64-ucrt-x86_64-nasm-3.02-1-any.pkg.tar.zst",
      "url": "https://repo.msys2.org/mingw/ucrt64/mingw-w64-ucrt-x86_64-nasm-3.02-1-any.pkg.tar.zst",
      "bytes": 452146,
      "sha256": "e60cf678bedee3d6c9a9264f8dec5897520e5ff7e3ae80c2b90b2628c5f51d58",
      "delivery_classification": "BLOCKED",
      "signature": {
        "filename": "mingw-w64-ucrt-x86_64-nasm-3.02-1-any.pkg.tar.zst.sig",
        "url": "https://repo.msys2.org/mingw/ucrt64/mingw-w64-ucrt-x86_64-nasm-3.02-1-any.pkg.tar.zst.sig",
        "bytes": 566,
        "sha256": "8939ebb3d4a4c5b56aad2c1af14b9a438a8ee79c9f2b66277d6260a6a08d8120",
        "delivery_classification": "BLOCKED"
      }
    },
    {
      "identity": "mingw-w64-ucrt-x86_64-zlib",
      "version": "1.3.2-2",
      "architecture": "any",
      "filename": "mingw-w64-ucrt-x86_64-zlib-1.3.2-2-any.pkg.tar.zst",
      "url": "https://repo.msys2.org/mingw/ucrt64/mingw-w64-ucrt-x86_64-zlib-1.3.2-2-any.pkg.tar.zst",
      "bytes": 111475,
      "sha256": "841401182976d2f9e17e5c0ebaac51f2a8014140ea53d67625e91c8fb3c85ea0",
      "delivery_classification": "BLOCKED",
      "signature": {
        "filename": "mingw-w64-ucrt-x86_64-zlib-1.3.2-2-any.pkg.tar.zst.sig",
        "url": "https://repo.msys2.org/mingw/ucrt64/mingw-w64-ucrt-x86_64-zlib-1.3.2-2-any.pkg.tar.zst.sig",
        "bytes": 566,
        "sha256": "3c21e4ca62ae9544f37ad41b0910f64d60f4f0c4c4113bc5c9287ce2b6396acb",
        "delivery_classification": "BLOCKED"
      }
    },
    {
      "identity": "pkgconf",
      "version": "3.0.7-1",
      "architecture": "x86_64",
      "filename": "pkgconf-3.0.7-1-x86_64.pkg.tar.zst",
      "url": "https://repo.msys2.org/msys/x86_64/pkgconf-3.0.7-1-x86_64.pkg.tar.zst",
      "bytes": 120051,
      "sha256": "5e051b9623f7e539515f8c42430bf4bd1e377a459e810faea4358f48c3115199",
      "delivery_classification": "BLOCKED",
      "signature": {
        "filename": "pkgconf-3.0.7-1-x86_64.pkg.tar.zst.sig",
        "url": "https://repo.msys2.org/msys/x86_64/pkgconf-3.0.7-1-x86_64.pkg.tar.zst.sig",
        "bytes": 566,
        "sha256": "ab5b69850cd0d755bf62e89463ab840bafe8da9256be3d35e2d6df664176b5eb",
        "delivery_classification": "BLOCKED"
      }
    }
  ]
}
```

## RED, GREEN and verification

RED before production helper creation:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File tests/InstallerMsys2Packages.Tests.ps1
```

Exit 1: "Pinned MSYS2 input validation and offline transaction planning are missing."
The initial test failed on the absent bounded behavior; no existing implementation
was modified before RED.

GREEN, same command: exit 0. Synthetic fixtures exercise the real validator,
including base size mismatch, blocked base/package/signature classification,
changed package/signature hashes, wrong versions, extra/duplicate package records,
unsafe filename/root and incorrect transaction sets. The transaction validator
is loaded from its production AST; no native package behavior is mocked or bypassed.

Exact-artifact GREEN:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File tests/InstallerMsys2Packages.Tests.ps1 -RealBaseInstaller D:/AutoClip-Inno-Migration/msys2-x86_64-20260611.exe -RealPackageDirectory D:/AutoClip-Inno-Migration/msys-pkgs
```

Exit 0: all eleven real size/hash pins passed; negative cases passed.
PowerShell 5.1 parser validation passed for both scripts. Scoped whitespace checks
passed for all three owned files using the following commands:

```powershell
$paths = @('installer/install-msys2-packages.ps1','tests/InstallerMsys2Packages.Tests.ps1')
foreach ($path in $paths) {
    $tokens=$null; $errors=$null
    [void][Management.Automation.Language.Parser]::ParseFile((Join-Path (Get-Location) $path),[ref]$tokens,[ref]$errors)
    if ($errors.Count) { throw ($errors | Out-String) }
}
git diff --no-index --check -- /dev/null installer/install-msys2-packages.ps1
git diff --no-index --check -- /dev/null tests/InstallerMsys2Packages.Tests.ps1
git diff --no-index --check -- /dev/null docs/installer-migration/work-orders/IM-MS-01.md
```

These no-index diffs return 1 because the files differ from /dev/null; final
output contained only LF/CRLF working-copy notices and no whitespace diagnostics.

No trust initialization, package install,
post-install command, clean VM, Inno compile, GPU, publication, or installed-release
smoke was performed; these require the unblocked executing route and parent gates.

Suggested commit message: `installer: validate pinned MSYS2 inputs and block unproved keyring execution`.
