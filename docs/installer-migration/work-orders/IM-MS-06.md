# IM-MS-06: bounded isolated GnuPG socket paths

Status: focused RED/GREEN and host fixture regression PASS. Fixed helper ready
for parent guest retry. No complete installer or runtime approval claimed.

## Requirement, authorization and ownership

Parent explicitly authorized diagnosis and a minimal TDD fix to the isolated
keyring route in [IM-MS-03](IM-MS-03.md), under the
[installer contract](../contract-v1.md). Preserve exact provenance, offline
initialization, Required TrustedOnly signatures, and the five-package closure.
An otherwise supported short MSYS2 root must permit all agent sockets; a root
whose isolated socket cannot fit must fail before creating that directory or
invoking native initialization. No public arguments or manifest schema change.

Owned repository files: `installer/install-msys2-packages.ps1`,
`tests/InstallerMsys2Packages.Tests.ps1`, new
`tests/InstallerMsys2SocketPath.Tests.ps1`, and this work order. No VM operations,
host MSYS2 installation/update, shared keyring imports, archive changes, or
edits to another writer's files.

## Diagnosis and evidence boundaries

Read parent failure receipt
`D:/AutoClip-Inno-Migration/vm-msys-tar-packages-20261001.json`, SHA256
`a730700537b3dc01c2c45fb59d239abbb69a36c88d10e61d37bf6f36dd99b219`.
It records bash failure at initialization but contains an empty native output
array; that receipt alone does not establish the underlying agent error.

Longest socket names including their terminating NUL:

| Guest root | Original prefix | New `ac-` prefix |
| --- | ---: | ---: |
| `C:\AutoClipMsys2Audit` | 104 bytes | 91 bytes |
| `C:\AutoClipMsysTar20261001\msys64` | 116 bytes | 103 bytes |

Bounded host A/B used `C:/msys64/usr/bin/gpg-agent.exe` (GnuPG 2.4.9), with
`--no-options --homedir <exact-owned-home> --daemon --no-detach --verbose
--log-file <exact-owned-home>/agent.log`. Only the home prefix differed:
`D:/AutoClip-Inno-Migration/mg-37a9e0-123456789/ac-<32 zeroes>` versus
`.../autoclip-pinned-<32 zeroes>`. Python 3.11 `subprocess.run`, with stdout
and stderr redirected to an owned regular file and timeout 10 seconds, captured
exit 0 at 103 bytes and exit 2 at 116 bytes. The short log shows all four
sockets listening. The long log says `socket name .../S.gpg-agent is too long`.
Evidence `.../diagnosis.json` SHA256
`a0fddc6addc0cc01429e201e08f7b6dd9f96ba6172130ef95f0aae776b96262b`.

Earlier exploratory PowerShell probes below the limit both succeeded. An
attempt to capture inherited daemon pipes timed out; redirecting to ordinary
owned files established the actual exit codes. Every resulting owned agent
was stopped using its exact homedir with `gpgconf --kill gpg-agent`, or after
matching its executable and complete owned homedir command-line prefix.
Final CIM check found no remaining agent whose command line contained the
owned `AutoClip-Inno-Migration/mg-` scratch prefix. No shared host keyring was
used. Scratch evidence logs remain for audit.

Primary references: [Cygwin UNIX_PATH_MAX 108](https://sourceware.org/pipermail/cygwin-patches/2021q1/011099.html),
[GnuPG agent socket length discussion](https://lists.gnupg.org/pipermail/gnupg-devel/2019-June/034367.html),
and [GnuPG agent standard socket options](https://www.gnupg.org/documentation/manuals/gnupg/Agent-Options.html).
The host A/B proves the path-length mechanism. It does not independently execute
the pinned guest base or establish a successful fixed package transaction.

## Minimal change and verification

Shorten only the keyring directory prefix to `ac-`, retain the entire random
32-hex GUID, and check the UTF-8 size of the longest browser socket plus NUL
against 108 before directory creation/native work. The repository-free config,
trust rules, provenance pins and transaction checks are unchanged.

The new test executes the actual production allocation statements extracted
from the parsed source, with no filesystem or native mocking. Before the fix,
the first command failed with `Supported guest root must fit all GnuPG socket
names.` After the fix it passes the reported guest root, full random isolation,
108-byte acceptance and 109-byte rejection. Exact artifact regression adds
test-only `-ShortFixtureParent`; it stages a unique `am-<6hex>` root directly
under that parent to keep its real keyring path within the same production
bound. Creation does not overwrite existing paths; cleanup validates the exact
owned name, absolute path and absence of a root reparse point.

Executed from `D:/Projects/autoclip-runtime`:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File tests/InstallerMsys2SocketPath.Tests.ps1
powershell -NoProfile -ExecutionPolicy Bypass -File tests/InstallerMsys2Packages.Tests.ps1
powershell -NoProfile -ExecutionPolicy Bypass -File tests/InstallerMsys2Packages.Tests.ps1 -RealBaseInstaller D:/AutoClip-Inno-Migration/msys2-x86_64-20260611.exe -RealPackageDirectory D:/AutoClip-Inno-Migration/msys-pkgs -RealBaseArchive D:/AutoClip-Inno-Migration/msys-base-audit/msys2-base-x86_64-20260611.tar.xz -ShortFixtureParent D:/AutoClip-Inno-Migration
git diff --check
```

All GREEN; diff check clean (existing LF/CRLF warnings elsewhere). Actual exact
artifact execution regression retains only the native-process boundary mock;
it does not initialize keys or install packages. Initial fixture roots exceeded
the new production bound and failed closed; using the short staging parent
and removing an unnecessary nested test root resolved that fixture limitation.
No production test bypass was introduced.

Frozen SHA256:

- Helper: `34e9d95adc8f9fbc07a29785fef1d8d741d442fb457c8e0c592f4306f80bb3d0`.
- Existing test: `6a6ad0a9aaaab808503f83b8fea54580a9bd58c5817c9e0d62764084be4e144d`.
- Focused test: `5b725261bf063f862a4e9820a476f62079e8134c1e56264116390a8ff2191ec5`.

Remaining required evidence belongs to parent: retry the frozen helper with
the authenticated delivered base in the disconnected guest, recording actual
trusted signatures, exact transaction and capabilities. No whole setup or
release qualification follows from these bounded host checks.
