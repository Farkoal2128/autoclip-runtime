# IM-VS-12: exact installed display identity

The first IM-VS-10 capability probe ran in the ordinary-user VM and stopped at
its instance check. Native `vswhere` returned exit 0, the required Build Tools
component selection, complete/launchable true, installation version
`17.14.37710.0` and display version `17.14.41 (September 2026)`. The probe had
incorrectly required the display text to equal `17.14.41`.
The local pinned Catalog's `info.productDisplayVersion` contains the same
longer display text; this correction retains exact version identity.

Primary failure summary:
`D:/AutoClip-Inno-Migration/vm-vs-capability-failure-5ad2c3374488.json`,
SHA256 `5ad2c3374488c520265fa80f7a2ad76c7d3c177763d5ac316315f1bd6d651439`.
Full failed guest receipt SHA256:
`db146a799c78a20a16e31dc3478e6d5c332bd3e60d602cecd4e6430abc0cf032`.
Independent read-only receipt observation including native stdout:
`D:/AutoClip-Inno-Migration/vm-vs-capability-observation-21c43210a985.json`,
SHA256 `21c43210a98530bc7fd6bd70e20ce5ccb83240811f1336d8c5d4234c6ce91ed3`.

## Focused RED and GREEN

Executed the actual instance guard AST against that primary `vswhere` output.
RED rejected the valid observed display identity before the change. Changed
only the expected display string to the exact pinned Catalog value.
GREEN accepts the observed record and rejects changed installation version,
display version, product, incomplete and unlaunchable states.

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File D:/AutoClip-Inno-Migration/vm-transfer/vs-capability-probe.tests.ps1
```

The host tests execute only the isolated guard; they cannot install or execute
vendor files. Historical probe is preserved as `vs-capability-probe-1d21903d.ps1`
under `D:/AutoClip-Inno-Migration`, original full SHA256
`1d21903d4dde93e5b5094d5ed8a8a13f48f47f069bbedf3b5944e8abd443ca35`.
Corrected probe SHA256:
`42fe601ba6b2e05f46d1b3ffd7e6c63bfac8f4983a9a6e9abacad2cc9e85fe32`.

The corrected native compiler/SDK check is a separate guest operation. This
metadata correction establishes neither compile/link/run capability nor the
production Microsoft acquisition, full wizard or publication gates.

## Corrected real guest result

The corrected probe was hash-checked after first-party transfer and executed
as the ordinary guest user with `-VerifyInstalled -PostResult`. It returned
`VERIFIED_X64_COMPILE_LINK_RUN`. The full primary guest receipt was then
transported byte for byte and independently matched its reported SHA256:
`D:/AutoClip-Inno-Migration/vm-vs-capability-primary-27e076cc8d77.json`,
SHA256 `27e076cc8d77547c3641428755db553ad417c4bc680deb5b7db4a21ce4cd7f8e`.
The compact summary remains separately preserved at
`vm-vs-capability-success-db764ecca5a9.json`, SHA256
`db764ecca5a9cbfe9f50db7da99f95f934d0461ced1164b392cc29a165290d44`.

- `vswhere`: exit 0; both required component IDs, complete and launchable true,
  installation `17.14.37710.0`, no reboot required.
- MSVC default toolset `14.44.35207`; signed `cl.exe` version `19.44.35229.0`,
  SHA256 `fe251ef50a1545b1b0835ee17b1e785459712b38d79e45b5c1d3d28970a36619`.
- SDK `10.0.26100.0` headers and x64 libraries were read and hashed.
- `cl /Bv` returned expected exit 2 for missing source while reporting compiler
  identity; the separate first-party compile/link returned 0.
- Compiled output is PE machine `0x8664`; running that exact x64 executable
  returned 0. Its SHA256 is
  `6b718a5cc38133b1294212d4551d5be7309fdbc4e0671556746ff354782f3617`.
- Installed setup engine candidates have valid Microsoft signatures and
  version `4.10.30.62513`.
- `vcomp140.dll` is signed, version `14.44.35211.0`, SHA256
  `55aba23cdcd6484fbb06f4155b8ca75adfce7a881f10afd0c49457165e677164`;
  its OpenMP capability was not executed by this probe.

This qualifies the prepared guest's first-party compiler/linker/SDK capability.
It does not qualify the complete source build, connected recipient Microsoft
acquisition, installer consent/lifecycle handling, or whole Inno setup.
