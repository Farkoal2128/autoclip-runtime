# IM-CPU-21 — accept pinned uv venv metadata

Status: root cause fixed and successor driver frozen; actual r3 guest build
pending. Parent owns VM action and publication gates. No `install.ps1`, old
server file, driver, receipt, failure root or canonical manifest was changed.

## Requirement, evidence and callers

The parent authorized a minimal correction under the runtime setup contract:
accept exact unambiguous Python 3.11.9 from standard-library `version` or
pinned uv `version_info`, while rejecting missing, duplicate, conflicting or
incompatible identity/isolation fields. Paths, executable hashes, manifest
route, atomic startup file ownership and global PATH protections stay intact.

The agent independently rehashed and inspected these parent-transported
primary files; this is not an independent guest execution:

- `vm-cpu20-failure-primary-99d78e465e75.json`:
  `99d78e465e75c86c5d4b84d4ed4c33dbd458065a1064d1a64815ee830efa6550`.
- `vm-cpu20-failure-logs-9dc0e8f9f626.json`:
  `9dc0e8f9f6265828b5bc602ce780a6ef27b057c8730b8031c01f8fefe12e8923`.
- `vm-cpu20-venv-config-e6066a991386.json`:
  `e6066a991386259bcf4c18a00a4577db4ef015ae28a55acbf00324ed284d5e18`.

Actual source-install child PID 11524 exited 1 after selecting installed
CPython 3.11.9 and creating the venv. The runtime PATH helper rejected its
configuration before compilation. The captured exact configuration is
165 bytes, SHA `b495c478f3dbc4eb4915823205475b12a02c976e389984105f592c9649ff2a4e`:

```text
home = C:\Users\autocliplab\AppData\Local\Programs\Python\Python311
implementation = CPython
uv = 0.12.19
version_info = 3.11.9
include-system-site-packages = false
```

The helper matched only standard-library `version`. Its shared producer is
`installer/install-runtime-toolpath.ps1`; `install.ps1` reads it from the
adjacent canonical filename during persistent FFmpeg registration. Inno
extracts/binds that same helper. Correcting the shared guard fixes these
callers without adding another registration route or rewriting the archived
native recipe. The immutable CPU20 bootstrap remains unchanged.

## Minimum production correction

The existing configuration guard now reads only known identity/isolation
key/value lines, recognizes `version` and `version_info`, and requires every
present version to equal `3.11.9`. Both representations may coexist only when
consistent; duplicate occurrences of any recognized key, including case
variants, fail. Exactly one explicit `include-system-site-packages = false`
is required. If `implementation` is present it must occur once and equal
`CPython`; ordinary standard-library metadata may omit it. A missing version,
wrong version, conflicting second version, enabled/missing/duplicated system
site packages, non-CPython implementation or duplicate identity fails closed.

Unrelated `home`/uv/executable/command metadata is not executed or converted
to paths by this guard. Actual installed Python identity remains independently
checked by the existing prerequisite helper and CPU driver. No relaxed
FFmpeg executable pin, path, notice or ownership check was introduced.

## RED and GREEN

The existing test retains its explicit real-archive integration route and
adds `-ConfigurationOnly`, which executes the actual helper's configuration
guard AST region against first-party text fixtures. It does not create or
execute Python, extract vendor files or acquire network data.

```powershell
powershell -NoProfile -File tests/InstallerRuntimeToolPath.Tests.ps1 -ConfigurationOnly
powershell -NoProfile -File D:/AutoClip-Inno-Migration/vm-transfer/cpu-real-build-probe-r3.tests.ps1
git diff --check -- installer/install-runtime-toolpath.ps1 tests/InstallerRuntimeToolPath.Tests.ps1
```

RED exit 1 before production edit rejected the exact observed uv text with
`Runtime tool startup requires the expected isolated Python 3.11.9 venv.`
GREEN exit 0 after the correction accepted actual uv, standard-library CRLF
and consistent dual-version forms. Eleven negative fixtures reject duplicated
version/version_info, conflicting versions, wrong version, missing version,
missing/true/duplicate isolation, PyPy/duplicate implementation and a case
variant duplicate identity. AST parser and scoped diff check passed.

R3 driver fixtures exited 0 and preserve CPU context, full diagnostic clone
equality, CPU-only arguments, child/marker failures, readlocks/pins, immutable
live observations and nonoperational default. Additional tests evaluate the
actual metadata spec and actual URI expression without executing network
calls: the new served runtime helper maps to its required adjacent local
canonical basename; the CPU20 bootstrap remains the same distinct served file.

The opt-in real Python/FFmpeg startup/pythonw/app-layer integration test was
not run by this agent. It requires vendor execution forbidden in this work
order. Actual r3 guest execution and broader acceptance remain parent-owned.

## Frozen files and server interface

| Artifact | Bytes | SHA-256 |
| --- | ---: | --- |
| `installer/install-runtime-toolpath.ps1` | 6696 | `c959d360a99155179262058ecc311edd9f36f14926b7edcdf239273e619e4f68` |
| `tests/InstallerRuntimeToolPath.Tests.ps1` | 11233 | `06163aace8f632ab45a6b6b9e3bba635d659a7d4fef8974c93224a964a6dcf89` |
| `D:/AutoClip-Inno-Migration/vm-transfer/cpu-real-build-probe-r3.ps1` | 19019 | `fea467e38742fdd5d97bdc5e852b2761e296db9f88f59b570ddbfcdab9ea02e5` |
| `D:/AutoClip-Inno-Migration/vm-transfer/cpu-real-build-probe-r3.tests.ps1` | 6004 | `1ad66789ed98c426df7d19fbb017522179758f27c95f92dab3024f2c4d63588b` |

The parent must copy exact new helper bytes to distinct server filename
`install-runtime-toolpath-cpu21-c959d360a991.ps1`; old canonical server helper
`699977...` must remain immutable. R3 fetches this distinct filename but writes
it as stage-local `install-runtime-toolpath.ps1`, holds its readlock and passes
full new `RuntimeToolPathHelperSha256` to frozen source
`install-cpu20-0a82cd0bf441.ps1`. That old bootstrap is still full hash
`0a82cd0bf441b93a0074e43548f25c0d784fc8cd96c1fc3ba73b8f0cb20cf4d2`.

The only r3 driver changes from r2 are the two runtime helper hash occurrences,
that helper's distinct `server_name`, and optional server-name selection in
the existing first-party control fetch. All remaining source/build behavior,
fresh-root/context guards, final CPU manifest `92fcd18...`, package receipt
`429f0aef...`, root `C:\ProgramData\acm-ee01cf00\msys64`, protected staging,
PID/log observation and result checks remain unchanged. Parent invocation is
the IM-CPU-19 concrete CPU18 command with the verified r3 driver path.

No automatic retry, VM action, vendor execution, host acquisition or source
classification promotion was performed here. Successful component checks do
not establish final wizard, application/media/model inference or release.
Uninstaller execution remains after production-ready installer qualification,
as explicitly requested by the user.
