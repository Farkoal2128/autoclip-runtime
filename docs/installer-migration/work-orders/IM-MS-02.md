# IM-MS-02: exact base keyring provenance audit

Status: read-only archive/keyring provenance established; GUI-to-TAR equality and
recipient trusted-signature installation remain pending the clean guest.

## Authorization and scope

Parent assignment IM-MS-02 authorizes official same-release artifact downloads
and read-only inspection in `D:/AutoClip-Inno-Migration/msys-base-audit`.
The only repository file owned/changed is this work order. The helper, tests,
manifest and VM remain owned by the parent or other writers. No base installation,
host key import, pacman-key initialization, key refresh, package update or VM
control was performed.

This is provenance evidence for [IM-MS-01](IM-MS-01.md) and the
[installer contract](../contract-v1.md), not a new implementation, legal
disposition or publication approval. TDD is not applicable to this read-only audit.

## Exact official release and downloaded artifacts

Official [2026-06-11 release](https://github.com/msys2/msys2-installer/releases/tag/2026-06-11),
release ID 337740828, published 2026-06-11T07:23:06Z. All four selected API assets
had state=uploaded; local sizes/hashes match their GitHub release digests.
The downloaded .sha256 also names the exact archive hash.

Download URL prefix:
`https://github.com/msys2/msys2-installer/releases/download/2026-06-11/`.

| Artifact filename | Bytes | SHA-256 |
| --- | ---: | --- |
| msys2-base-x86_64-20260611.tar.xz | 53,555,380 | a2d047e8ee213c3c6a49a8de427eb1069df12207c0422ff1b3cbb5c905c34221 |
| msys2-base-x86_64-20260611.tar.xz.sha256 | 100 | b098a55e4e0d6119775de3b38120c0503607f537c7f34552758a1f95ebd347ea |
| msys2-base-x86_64-20260611.tar.xz.sig | 566 | 076f5623b702d5016cf0253e1d14a6bd4870a90243243e96409b227f0d5bf70f |
| msys2-base-x86_64-20260611.packages.txt | 1,508 | 45fb386d514128291832c9cf78474d6104a8f6058197f6de370141e13f9a79bb |

Saved `release-metadata.json`: 47,309 bytes,
SHA-256 `459332f6da4e83d6a112dd80d293e7430434cb2fead0b005445dad13ebcf7652`.
This is a local serialization of the official HTTPS API response, not a signed
release document.

## Archive signature and independent fingerprint anchor

The [official MSYS2 installer guide](https://www.msys2.org/docs/installer/)
publishes installer primary fingerprint
`0EBF782C5D53F7E5FB02A66746BD761F7A49B0EC`. Its linked Ubuntu keyserver supplied
the public key as `installer-signer.asc`; the full primary fingerprint was
checked against that independently published value before accepting the result.

- Public-key URL:
  `https://keyserver.ubuntu.com/pks/lookup?op=get&search=0x0EBF782C5D53F7E5FB02A66746BD761F7A49B0EC`.
- ASCII public-key SHA-256:
  `a247a92716ab322770e800793c10136dd22a6ea4691fdd2b9c72d4cfc5221082`.
- Dearmored public-key SHA-256:
  `f22f08205e8886385f4530403a4175c1dba7690fc53b3b9a3193dbb77cc3f10b`.
- gpgv exit 0, GOODSIG and VALIDSIG with signing subkey
  `E0AA0F031DBD80FFBA57B06D5A62D0CAB6264964`,
  primary `0EBF782C5D53F7E5FB02A66746BD761F7A49B0EC`,
  signature timestamp 1781162388 (2026-06-11).
- `base-signature-check.txt` SHA-256:
  `97f382b50bd08d0e51262580d21a51460fe02839b36a4ed2289f65b061febeca`.

The installer signing key is separate from the package-signing keyring. The
initial attempt to use the delivered armored package keyring with gpgv failed
and was not accepted. Verification above uses only the separately fingerprint-
anchored installer key. Key dearmor/show/check commands do not import keys.
GPG inspection created an empty 32-byte keybox and 1,200-byte trust metadata
only in scratch `gpg-readonly`; no keys were generated/imported, no ownertrust
was assigned, and no host keyring or trust database was used or changed.

The host GnuPG tools performed cryptographic inspection only:
`C:/msys64/usr/bin/gpg.exe` and `gpgv.exe`, gpgv 2.4.9. No binary from the
downloaded base was executed.

## Delivered keyring and code snapshot

The official package list and archived local package database both identify
`msys2-keyring 1~20260214-1`. The base includes `pacman 6.1.0-25` and
`gnupg 2.4.9-1`. Three regular keyring files were delivered:

| Path relative to installed MSYS2 root | Bytes | SHA-256 |
| --- | ---: | --- |
| usr/share/pacman/keyrings/msys2.gpg | 54,878 | 79cc43bd8b8a4e8c952340adc0ae93d3ff8e50c40f244321cf58fa014282f4ea |
| usr/share/pacman/keyrings/msys2-trusted | 220 | a8d39040a7b6cc14bf4394b5d9c838443925c32b00a7d34e8729c972392dca04 |
| usr/share/pacman/keyrings/msys2-revoked | 164 | 62b67ba0217745c7df189092a70d6b7a5781577f6428a5391dccd897edb5756a |
| usr/bin/pacman-key | 23,497 | 5d2e5e67ca59e49e84d5f0b2f7e4166e3783f707cd2292c09ce61a79c7cc149f |
| etc/post-install/07-pacman-key.post | 300 | 19badd8d5d7e0052028c466fc1eb7fcf8f7e1fb50cb832be389922047897ef3e |
| etc/profile | 5,475 | 3368d6f88af0daf8f3df1eb563e6c351bf9e336f40b826bd94486c18183602ff |
| var/lib/pacman/local/msys2-keyring-1~20260214-1/desc | 342 | a72e90c5db7abb1280f295f51cc6c6d35c837d10f39d72d0379122bd9518014e |
| var/lib/pacman/local/msys2-keyring-1~20260214-1/files | 186 | 51f2379c86afbfe12a31792189f83db308425a44e664c6b1a7307713c1a90c43 |
| var/lib/pacman/local/msys2-keyring-1~20260214-1/install | 276 | 58e2bc988c433c445bbf56bd712c33b4ffc6f24742eccdf66e80438a4c61fa18 |
| var/lib/pacman/local/msys2-keyring-1~20260214-1/mtree | 476 | ffc2d1d7f32623aa673f7e37386416b0afa5cc3c8daaf8e83a96114d113af8a3 |

These selected regular members were individually read with Python tarfile,
checked for path containment and written under scratch `extracted/msys64`.
No whole archive extraction or symlink was followed. Inventory:
`selected-files.json`, SHA-256
`390e97bc8b5b68f7a8e929858f546f607660401f532718232a0c9ed6e0588d82`.

Additional archived executable hashes were computed directly from member bytes,
without extracting/executing those binaries, for the parent guest comparison:

| Path | Bytes | SHA-256 |
| --- | ---: | --- |
| usr/bin/bash.exe | 2,452,446 | 41b09f0a9c1c68fd65253a7e8087b3775f0af245b729ade74ca4425d14392c2d |
| usr/bin/pacman.exe | 10,765,942 | 209b2d527f359608cdb092515d3d99f46ac9d2209d130adced81a8cdd79057d8 |
| usr/bin/gpg.exe | 1,130,330 | a5140c85353e8399da8d6bd7e3741524cd76a4e69be88af12042b1c9ef022984 |
| usr/bin/gpgv.exe | 514,306 | f4d13204d77fdf63c02b0e6742230f83a833128c28f7b715709c2c63a96c427b |
| usr/bin/pacman-conf.exe | 10,713,395 | 12f4d59306fc83366a950923c9a70fa3c045fc0a6aa706e622ea30acff918726 |

## Exact trust data and package certification

The delivered `msys2-trusted` contains these five full master fingerprints,
each with ownertrust value `:4:`. Preserve these values; do not replace them
with ultimate trust:

| Master | Fingerprint |
| --- | --- |
| Alexey Pavlov | D55E7A6D7CE9BA1587C0ACACF40D263ECA25678A |
| Ignacio Casal Quinteiro | B91BCF3303284BF90CC043CA9F418C233E652008 |
| Martell Malone | 9DD0D4217D75A33B896159E6DA7EF2ABAEEA755C |
| David Macek | 6E8FEAFF9644F54EED90EEA0790AE56A1D3CFDDC |
| Christoph Reiter | 69985C5EB351011C78DF7F6D755B8182ACD22879 |

The delivered active developer identities are:

- Alexey Pavlov: `AD351C50AE085775EB59333B5F92EFC1A47D45A1`.
- David Macek: `87771331B3F1FF5263856A6D974C8BE49078F532`; the delivered key
  reports expiration at Unix 1786642926 and is expired at this audit date.
- Christoph Reiter: `5F944B027F7FE2091985AA2EFA11531AA0AA7F57`; no expiration
  field in this delivered key. All five selected packages use this key.

The exact revoked/disabled list is:
`123D4D51A1793859C2BE916BBBE514E53E0D0813`,
`B19514FB53EB3668471B296E794DCF97F93FC717`,
`909F9599D1A2046B21FAEB3C4DF3B7664CA56930`,
`C65EC8966983541D52B97A16D595C9AB2C51581E`.

The [official MSYS2 keyring reference](https://www.msys2.org/dev/keyring/) matches
the five master and three developer fingerprints. More directly, read-only
`gpg --check-sigs` against the dearmored archive keyring returned exit 0 and
valid `sig:!:` certifications of the selected Christoph developer key from
masters D55E..., 69985... and 6E8.... These certifications are delivered bytes;
no keyserver or host trust was used to validate them. The delivered
pacman-key populate code locally signs the exact master list, imports the
provided ownertrust values and disables the exact revoked list.
Its delivered import command includes the upstream
`--allow-weak-key-signatures` workaround for MSYS2-keyring issue 45. This was
inspected, not executed. It concerns key certification import; the production
package policy must still remain Required TrustedOnly. Review this exact pinned
upstream behavior rather than adding caller trust or signature exceptions.

All five package signatures returned gpgv exit 0 / GOODSIG / VALIDSIG using ONLY
the archive-delivered package keyring after dearmor. Signer for every package:
`5F944B027F7FE2091985AA2EFA11531AA0AA7F57`.

| Exact package | Signature date |
| --- | --- |
| diffutils-3.12-1-x86_64.pkg.tar.zst | 2025-04-18 |
| make-4.4.1-3-x86_64.pkg.tar.zst | 2026-06-01 |
| mingw-w64-ucrt-x86_64-nasm-3.02-1-any.pkg.tar.zst | 2026-07-04 |
| mingw-w64-ucrt-x86_64-zlib-1.3.2-2-any.pkg.tar.zst | 2026-03-06 |
| pkgconf-3.0.7-1-x86_64.pkg.tar.zst | 2026-09-09 |

`developer-certification-check.txt` SHA-256:
`fea41a73e5dc0a98442017998740a50e19402596f15306fdffecf1eec9f3b087`.
`package-signature-checks.json` SHA-256:
`73576985647a9528f15de414e6f32891fefacf8d7c841c9e0410b625b4af4cbf`.
These are cryptographic audit checks. gpgv does not establish recipient pacman
trust; Required TrustedOnly checks in the clean initialized guest remain required.

## Supported offline initialization and first-login risk

Inspected delivered `usr/bin/pacman-key` exposes `--init`, `--populate msys2`,
`--gpgdir` and `--populate-from`. Its init/populate functions perform local
key generation, local file import, local certification/ownertrust and trustdb
update; the explicit receive/refresh operations are separate. This supports a
no-network route using only the delivered bytes:

1. Install the hash-checked, validly signed GUI base into a new protected guest
   root with the guest network disabled.
2. Compare all three delivered keyring files to this snapshot, and compare
   relevant scripts/native executables and keyring version.
3. Invoke the installed bash without login/profile loading and with controlled
   PATH/environment, then run the pinned local `pacman-key --init` and
   `pacman-key --populate msys2` separately, requiring success.
   Supported argument shape:
   `bash.exe --noprofile --norc -c "/usr/bin/pacman-key --init && /usr/bin/pacman-key --populate msys2"`.
   Explicit `--gpgdir /etc/pacman.d/gnupg` and
   `--populate-from /usr/share/pacman/keyrings` can fix the recipient paths.
4. Verify keyring state, disabled keys and required trusted signatures with
   pacman using the repository-free configuration in IM-MS-01. Require all
   five selected packages to pass and altered/missing/untrusted signatures to
   fail. Do not use ownertrust assignments beyond the delivered file or any
   signature-policy bypass.

**Critical risk:** `etc/profile` sources the post-install scripts.
`07-pacman-key.post` runs init, populate and then `--refresh-keys || true`
when the gnupg directory is missing; populate errors are also ignored there.
The GUI guide says the installer starts a login shell for initialization.
Therefore default first login can attempt online refresh. Disable guest network
before GUI installation/first shell, record any such failed refresh, and rerun
only local init/populate with explicit checks. Production acquisition must
prevent unpinned refresh itself, not rely on swallowed refresh errors.
Do not claim the supported route is tested merely from source inspection.

## Evidence boundary and remaining gate

The archive is authenticated and its exact keyring/signature chain is inspected.
The [installer guide](https://www.msys2.org/docs/installer/) describes the GUI
and archive as functionally equivalent after first-login initialization. This
is not byte-equivalence proof for these exact release variants. The parent must
compare the clean installed signed GUI base's delivered files to the TAR
snapshot before using it as package trust provenance. Any mismatch requires
investigation; do not update expected pins to fit a different installation.

The parent must separately demonstrate trusted Required TrustedOnly package
acceptance/rejection, repository-free dependency closure, exact transaction set,
unchanged unrelated packages, all installed versions/capabilities and the full
clean AutoClip workflow. No GUI install, recipient trust initialization, package
transaction, helper production changes or clean-machine success are claimed here.

## Exact commands and outcomes

Official metadata, saved in scratch:

```powershell
$release = Invoke-RestMethod 'https://api.github.com/repos/msys2/msys2-installer/releases/tags/2026-06-11'
$release | ConvertTo-Json -Depth 20 | Set-Content -LiteralPath 'D:/AutoClip-Inno-Migration/msys-base-audit/release-metadata.json' -Encoding UTF8
```

Each selected asset was downloaded with this exact pattern, substituting its
literal filename from the table (all four downloads exit 0):

```powershell
curl.exe --fail --location --proto "=https" --proto-redir "=https" --output D:/AutoClip-Inno-Migration/msys-base-audit/msys2-base-x86_64-20260611.tar.xz https://github.com/msys2/msys2-installer/releases/download/2026-06-11/msys2-base-x86_64-20260611.tar.xz
tar.exe -tf D:/AutoClip-Inno-Migration/msys-base-audit/msys2-base-x86_64-20260611.tar.xz
curl.exe --fail --location --proto '=https' --proto-redir '=https' --output D:/AutoClip-Inno-Migration/msys-base-audit/installer-signer.asc 'https://keyserver.ubuntu.com/pks/lookup?op=get&search=0x0EBF782C5D53F7E5FB02A66746BD761F7A49B0EC'
```

Cryptographic inspection, exact executable and paths:

```powershell
$msysAudit='/d/AutoClip-Inno-Migration/msys-base-audit'
& C:/msys64/usr/bin/gpg.exe --no-options --homedir "$msysAudit/gpg-readonly" --batch --yes --output "$msysAudit/installer-signer.gpg" --dearmor "$msysAudit/installer-signer.asc"
& C:/msys64/usr/bin/gpg.exe --no-options --homedir "$msysAudit/gpg-readonly" --batch --no-auto-check-trustdb --with-colons --with-fingerprint --with-subkey-fingerprint --show-keys "$msysAudit/installer-signer.gpg"
& C:/msys64/usr/bin/gpgv.exe --homedir "$msysAudit/gpg-readonly" --keyring "$msysAudit/installer-signer.gpg" --status-fd 1 "$msysAudit/msys2-base-x86_64-20260611.tar.xz.sig" "$msysAudit/msys2-base-x86_64-20260611.tar.xz"
& C:/msys64/usr/bin/gpg.exe --no-options --homedir "$msysAudit/gpg-readonly" --batch --yes --output "$msysAudit/package-keyring.gpg" --dearmor "$msysAudit/extracted/msys64/usr/share/pacman/keyrings/msys2.gpg"
& C:/msys64/usr/bin/gpg.exe --no-options --homedir "$msysAudit/gpg-readonly" --batch --no-auto-check-trustdb --no-default-keyring --keyring "$msysAudit/package-keyring.gpg" --with-colons --with-fingerprint --check-sigs 5F944B027F7FE2091985AA2EFA11531AA0AA7F57
& C:/msys64/usr/bin/gpgv.exe --homedir "$msysAudit/gpg-readonly" --keyring "$msysAudit/package-keyring.gpg" --status-fd 1 /d/AutoClip-Inno-Migration/msys-pkgs/make-4.4.1-3-x86_64.pkg.tar.zst.sig /d/AutoClip-Inno-Migration/msys-pkgs/make-4.4.1-3-x86_64.pkg.tar.zst
```

The final gpgv command was repeated for each literal package filename from the
package table. All final signature and certification checks exit 0. Initial
Windows-style MSYS GPG paths failed and were corrected to /d/...; no failed check
was accepted. Hash/size/state comparisons with the saved official metadata
passed for all four assets. Extraction was selective Python tarfile regular-member
reading, as described above; no tar extraction command or base binary ran.

Document whitespace verification:

```powershell
git diff --no-index --check -- /dev/null docs/installer-migration/work-orders/IM-MS-02.md
```

No-index diff exit 1 indicates the new file differs from /dev/null; no whitespace
diagnostics remain. No production tests were run or changed for this audit.
