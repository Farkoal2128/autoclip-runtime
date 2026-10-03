# IM-MS-04: same-release MSYS2 base TAR initialization route

Status: read-only route investigation complete; a bounded guest experiment is
specified, but no TAR installation or production classification is qualified.
Only this report was added. No archive was extracted into an install root, no
binary, GUI, key operation, package transaction, VM, or system setting was run
or changed for this work order. This is internal engineering analysis, not
vendor consent, legal approval, or independent review.

## Sources and exact candidate

The [official MSYS2 installer guide](https://www.msys2.org/docs/installer/)
lists the GUI, self-extracting, `.tar.zst`, and `.tar.xz` base forms. It says
the TAR has the same base files as the self-extracting form and that unpacking
an archive **then running a login shell once** yields a functionally
equivalent MSYS2 installation. The [official reinstallation guide](https://www.msys2.org/wiki/MSYS2-reinstallation/)
similarly says to untar the base, run `msys2_shell.cmd`, then exit. The archive
does not supply the GUI's shortcuts, uninstaller, or mandatory component login.
Those integration features are unnecessary for a private, protected AutoClip
build-tool root if installation, lookup, and cleanup use its explicit path.

[IM-MS-02](IM-MS-02.md) independently recorded the official 2026-06-11
`msys2-base-x86_64-20260611.tar.xz` as **53,555,380 bytes**, SHA-256
`a2d047e8ee213c3c6a49a8de427eb1069df12207c0422ff1b3cbb5c905c34221`,
with an exact detached `.sig`, official guide fingerprint
`0EBF782C5D53F7E5FB02A66746BD761F7A49B0EC`, and successful `gpgv`
verification against that anchored public key. It also verified the selected
five package signatures against the delivered package keyring. The installer
signing key and package-signing keyring are distinct. A recipient route must
still download the exact TAR directly from the official release, enforce the
approved HTTPS redirects, verify size/hash and any required signature before
extraction, and preserve that trust chain. A TAR hash inherited from GUI-file
comparisons is not an independent recipient download check.

The present [dependency manifest](../../../release/manifests/installer-dependencies-v1.json)
(`MSYS2` row beginning at line 214) pins the **GUI EXE**, its arguments, and
`BLOCKED` classification. The TAR route therefore needs an intentional
manifest/installer contract revision and separately reviewed implementation;
this report does not silently treat the TAR as the GUI executable or change a
classification. The [installer contract](../contract-v1.md) requires exact
identity, size/hash, official source, terms decision, protected staging, and
post-install capabilities regardless of archive format.

## What extraction and first login actually do

Read-only enumeration of this exact signed TAR found **16,581 members**:
15,529 regular files and 1,052 directories under one `msys64` top directory.
There are **no archived symbolic links or hard links**. A case-insensitive
name scan found no collisions; a scan for `..`, absolute/UNC paths, backslash,
Windows-invalid or reserved path components, trailing dots/spaces and `:`
found no exception apart from the expected `msys64` root directory entry.
The longest member path is 79 characters. These are properties of this exact
archive, not permissions to omit extraction guards for later releases.

The archived `etc/profile` sources *all* `etc/post-install/*.post` files on
login. This 2026-06-11 archive has exactly five:

| Script | Effect of first login in this archive |
| --- | --- |
| `01-devices.post` | Creates `/dev/shm` and `/dev/mqueue` directories if absent. |
| `03-mtab.post` | Creates `/etc/mtab` as an MSYS symlink to `/proc/mounts` if absent. |
| `05-home-dir.post` | Resolves the user, creates its home directory, and copies skeleton files if absent. |
| `06-windows-files.post` | Copies Windows `hosts`, `protocols`, `services`, and `networks` into `/etc` when absent. |
| `07-pacman-key.post` | If `/etc/pacman.d/gnupg` is absent: runs `pacman-key --init`, `--populate msys2 || true`, `--refresh-keys || true`, then kills GPG agents. |

These effects were read directly from the authenticated TAR's `etc/profile`
and `.post` members. A non-login `pacman-key` sequence alone, including
[IM-MS-03](IM-MS-03.md)'s isolated package trust, **does not perform the other
four first-login tasks**. In particular, IM-MS-03 initializes a separate
`etc/pacman.d/autoclip-pinned-*` keyring; it does not create the default
`etc/pacman.d/gnupg` directory tested by `07-pacman-key.post`. The observed
GUI component login's `hkps://keyserver.ubuntu.com` refresh attempt is therefore
expected from the exact shipped script even if the GUI itself already copied
all files. Its `|| true` means a successful installer status cannot certify
that refresh or trust initialization succeeded.

No additional `autorebase.bat`, package sync, or full upgrade is identified as
a mandatory *initial* TAR step by the official installer/reinstallation
guides or these exact post-install scripts. The reinstallation guide mentions
autorebase for **32-bit** MSYS2 after core updates; this candidate is x64 and
is a fresh base. MSYS2's [updating guide](https://www.msys2.org/docs/updating/)
describes rolling-release maintenance separately. Running an unpinned
`pacman -Suy` would change the reviewed base and cannot be smuggled into this
exact pinned AutoClip transaction.

## Smallest source-supported, refresh-free TAR experiment

The shortest guest route that keeps upstream first-login behavior without
allowing its network refresh is:

1. On a new, short ASCII NTFS path with no spaces, symlinks, `subst`, or network
   share, make a protected empty parent/root as the [MSYS2 guide recommends](https://www.msys2.org/docs/installer/).
   Recheck path containment, all archive member types/names/collisions, the
   target/parent chain for existing Windows reparse points, and expected free
   space immediately before extracting the exact verified TAR. Extract the
   archive's single `msys64` tree into that protected parent with an XZ-capable
   native archive tool, rejecting errors and validating the complete resulting
   file inventory and local package database. Do not merge into a prior MSYS2
   root or follow a preexisting link. The recipient installer must own only
   its selected root for later cleanup.
2. Before *any* login shell, run the archive-delivered `pacman-key --init` and
   `pacman-key --populate msys2` **separately**, in a controlled non-login
   shell, against the *default* `/etc/pacman.d/gnupg` directory. Use the
   delivered keyring only, fixed PATH/environment, no inherited `BASH_ENV` or
   `ENV`, and require each exit status and trust result. `--init` and
   `--populate` are local actions in the inspected pinned `pacman-key` script;
   do not run `--refresh-keys`, receive keys, weaken SigLevel, or assign extra
   trust. Abort if default keyring state is incomplete. This preordering is a
   **source-derived composition of native commands**, not an explicitly
   documented MSYS2 install recipe; the guest must validate it.
3. With guest network disabled, launch one native **login** shell from this
   root, then exit it normally. Since the default gnupg directory now exists,
   this exact `07-pacman-key.post` should skip its refresh branch; the other
   four post-install scripts still run as upstream intended. Require evidence
   that `/dev` directories, `/etc/mtab`, home/skel and Windows `/etc` copies
   were handled, and that no keyserver request was made. Do not accept the
   `Initial setup complete` banner alone as proof because these scripts do not
   all fail the shell on error.
4. Run [IM-MS-03](IM-MS-03.md)'s **separate**, non-login, repository-free
   Required TrustedOnly transaction for the five exact pinned packages and
   their signatures. Verify the complete base and package closure, keyring
   state, unchanged unrelated package versions, expected native binaries and
   build capabilities. The 12 static GUI/TAR matching files established in
   IM-MS-02 are provenance evidence only; they do not prove the entire archive
   extracted, initialized, or works as an AutoClip build prerequisite.

The first-login `03-mtab.post` may create a link **after** extraction even
though the TAR contains none. Its on-disk representation may be an MSYS link
file or a Windows reparse point depending on runtime settings; the guest must
inspect it. Accept only this known `/etc/mtab` to `/proc/mounts` behavior in
the exact root. The `05-home-dir.post` script can act on the user's resolved
home; preflight its resolved target and ensure that it will not overwrite or
take ownership of an unrelated user directory. The `06-windows-files.post`
copies four machine-local data files, so their post-install hashes are
recipient-specific and must be recorded as such, not compared to TAR member
hashes. Protect the root's ACL because the [MSYS2 guide](https://www.msys2.org/docs/installer/)
says a default `C:\msys64` inherits broad write access from `C:\`.

## GUI comparison and recommendation

The GUI remains an official route. Its exact 2026-06-11
[component script](https://github.com/msys2/msys2-installer/blob/2026-06-11/qt-ifw/packages/com.msys2.root/meta/installscript.js)
adds an `Execute` operation for `bash.exe --login -c exit` after creating
shortcuts. This operation is part of component installation, before the
maintenance tool and finish page. The parent-provided primary vendor log
`D:\AutoClip-Inno-Migration\vm-msys-base2-20261001.json` (SHA-256
`c444e6f87cf93b6a84851479add056b26d011bb27714b1fc3d0e066f4eed2398`)
confirms `backup`/`perform com.msys2.root operation: Execute` at about
22,553 ms, then local keyring initialization, failed keyserver refresh,
maintenance-tool writing and `Components installed successfully` at about
39,048 ms. The log records **vendor component success**, not a completed
redirected wrapper exit or an accepted refresh result.

Separately, the pinned
[installer config](https://github.com/msys2/msys2-installer/blob/2026-06-11/qt-ifw/config/config.xml)
sets `RunProgram` to `@TargetDir@/ucrt64.exe`; [Qt Installer Framework](https://doc.qt.io/qtinstallerframework/ifw-globalconfig.html)
defines that as a finish-page choice. Deselecting that choice **cannot avoid
the earlier mandatory component login or its refresh attempt**. Running the
native GUI/CLI without stdout or stderr pipe redirection and reading its
native `InstallationLog.txt` is a bounded diagnostic for the wrapper hang: a
surviving child `gpg-agent` may retain redirected handles, but that cause is
unproven. A GUI vendor success or a wrapper exit would still require direct
keyring and package trust checks. Avoid changing the publisher installer or
inserting a Qt control script to suppress a mandatory operation without a
separately reviewed behavior contract.

**Recommended bounded next experiment:** the exact signed TAR in a fresh guest,
with safe extraction, local default-keyring initialization, one observed
network-isolated login, then IM-MS-03's isolated trusted package transaction.
It avoids QIFW startup and stdout lifetime ambiguity and exposes each required
post-install result separately. This is a candidate, not an approved installed
runtime. The official GUI without redirection can be tested independently to
diagnose the hang, but simply changing the wrapper or finish-page RunProgram
choice does not remove the component login's refresh. No rights, terms, or
publication decision is inferred from either technical route; the prior recipient terms
decision and blocked-classification gates remain in force.

Read-only checks performed: primary MSYS2/Qt docs, pinned installer config and
component script, and the parent-provided hashed vendor log;
exact TAR member/type/path scan; authenticated TAR `etc/profile`, five
post-install scripts and `pacman.conf` inspection; IM-MS-02/03 and manifest
cross-check. No guest execution, trusted package installation, end-to-end
AutoClip setup, RED/GREEN, or external approval is claimed.
