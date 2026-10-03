# IM-PF-03: read-only MSYS2 preflight with exact versions

Authorization: parent explicitly assigned this implementation slice under the
installer goal. Owned files: `installer/preflight.ps1`,
`tests/InstallerPreflight.Tests.ps1`, and this report. Other writers own all
manifest, installer, Inno, package installation and guest work. Existing Python
CheckOnly behavior and the expected embedded `install-python.ps1` audit entry
were preserved.

Requirement/contract: `contract-v1.md` pre-install inspection, exact dependency
identity and capability checks, with no machine changes during preflight.
Classification: installer/updater. A login bash can execute first-login
post-install/key refresh scripts; inspecting packages must not load startup
profiles or initialize keys/packages. This slice changes the internal probe's
expected behavior; no command-line or HTTP contract changed.

## Change

The manifest iteration passes its exact prerequisite row to the capability
probe. For MSYS2, the probe validates a nonempty selected package map with
distinct shell-safe identities, versions, architecture and consistent artifact
filenames. It verifies every supplied `installed_files` hash/size, rejects
duplicate/escaping/reparse paths, and requires bash and pacman provenance.

It executes one native query via:

```text
C:\msys64\usr\bin\bash.exe --noprofile --norc -c "/usr/bin/pacman -Q -- <exact manifest package names>"
```

The absolute MSYS pacman path avoids depending on login PATH initialization.
The probe also clears child-inherited `BASH_ENV` for this invocation and restores
the caller's value in `finally`, because noninteractive Bash can otherwise load
that startup file despite the non-login flags. No persistent environment change
is made.
Returned row count, unique package identities and exact case-sensitive version
map must match the manifest. Missing, extra, duplicate, wrong-name/wrong-version
rows and native query failure remain missing capability. There is no package
installation, key initialization, sync/refresh or login activation.

Legacy rows without package or native provenance metadata explicitly remain
missing capability, before native execution; there is no presence-only fallback.
The current canonical manifest supplies the five selected package rows and
native provenance. The detection root stays `C:\msys64`; explicit selected-root
integration was excluded by the parent.

## RED and GREEN

Exact command from `D:\Projects\autoclip-runtime`:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File tests/InstallerPreflight.Tests.ps1
```

RED: before production edits, exit 1. The AST fixture retained the production
probe body, replaced only its fixture root and native invocation boundary, and
recorded the arguments passed by the running function. It captured four calls
with `bash.exe|-lc|pacman -Q ...`, including the original redirected
presence-only commands. The failure was `MSYS2 probe loaded profiles or used
wrong query arguments`. This was actual invocation behavior, not a source
presence assertion, and no real MSYS command ran.

Final GREEN: the same command exited 0. It recorded one exact fixture-root
native argument vector: bash path, `--noprofile`, `--norc`, `-c`, then
`/usr/bin/pacman -Q -- make diffutils pkgconf mingw-w64-ucrt-x86_64-nasm mingw-w64-ucrt-x86_64-zlib`.
Tests exercise correct versions and reject missing, extra, duplicate, uppercase
name and wrong-version output, native failure, absent legacy metadata, duplicate
manifest identity, shell syntax in an identity, missing pacman provenance,
duplicate provenance, wrong hash and escaping path. Invalid metadata/provenance
cases assert zero native calls. Existing Python CheckOnly, CPU/GPU policy,
reporting, read-only and unsigned uv fixture checks also passed.

An additional behavioral RED after consulting GNU's startup-file rules exposed
inherited `BASH_ENV` at the same native boundary: exit 1 with `MSYS2 preflight
inherited BASH_ENV startup script.` After the temporary clear/restore guard,
the same focused command returned GREEN again and verified that the native
boundary receives no `BASH_ENV` while the caller retains its original value.

Additional exact commands:

```powershell
rg -n -- '-lc' install.ps1
git diff --check -- installer/preflight.ps1 tests/InstallerPreflight.Tests.ps1 docs/installer-migration/work-orders/IM-PF-03.md
Get-FileHash installer/preflight.ps1,tests/InstallerPreflight.Tests.ps1 -Algorithm SHA256
```

Scoped whitespace validation exited 0. Final handoff hashes:

- Preflight SHA-256:
  `c469d5c0e6de8b098d1cb0f2a0d92f9bbf466965181087396d09d1035749d1fa`.
- Tests SHA-256:
  `1b68eb8217fac39bf905ac1493f0ae7149a0229159cb048a1a285ce833a4e150`.

## Related caller and limits

The inspected concurrent parent version of `install.ps1` already selects
`--noprofile --norc -c` at line 666 for `NoPrerequisiteAcquisition`. Its legacy
branch still selects `-lc`, with login acquisition commands at lines 673 and
675. These were reported to the parent and remain outside this slice's
ownership; no changes were made there.

Evidence is PowerShell 5.1 fixture-boundary behavior plus existing focused
preflight tests. Inert bash/pacman files were hashed; their native boundary was
mocked solely in tests. No host or VM MSYS executable, vendor installer,
pacman/key transaction, real canonical MSYS detection, Inno build/audit,
installed media workflow, human/legal or publication gate was run by this
work order. Package version detection and provenance checks do not establish
installed media/build capability or package signature trust.

Primary behavior reference:
[GNU Bash startup files](https://www.gnu.org/software/bash/manual/html_node/Bash-Startup-Files.html),
which documents profile loading and its suppression by `--noprofile` and
`--norc`.
