# IM-WIZ-15 — launcher success before completion marker, safe partial retry

Status: focused host behavioral and adjacent regression checks passed; frozen
for parent integration. Parent authorized `install.ps1`, new completion test,
this report, and bounded existing fixture adaptations. Root owns contracts,
Inno and builder. No VM, vendor executable, network, compiled setup, immutable
recipe/archive, frozen diagnostic bootstrap or uninstaller was touched/executed.

## Requirement / contract impact

The intentionally revised completion contract requires the install-folder
launcher to succeed **before** recording completion. Launcher and marker failure
must propagate, leave a matching partial installation retryable, and preserve
unknown/modified recipient files. IM-WIZ-14 identified the opposite behavior:
marker first, swallowed launcher failure, marker-based retry refusal, and
unrecognized retained shortcut after marker failure.

## Minimum production remedy

- Required launcher failure now propagates. Completion reuses only an exact
  authenticated retained folder shortcut or creates one successfully, records
  its ownership pin, and commits the marker last. IM-WIZ-13 exclusive decision
  lock still surrounds this entire action.
- `setup_owned_launcher` is an optional installed-only field in the existing
  `native-build-receipt.json`: exact `path`, `bytes`, `sha256`, `target`,
  `arguments`, `working_directory`, `description`, `archive_sha256` and
  `release_manifest_sha256`. It does not change native recipe/cache schema
  meaning or claim application health. Missing/wrong pins, changed bytes,
  unexpected target/arguments/description, unsafe ACLs and reparse paths reject.
  Hash/size are checked before reading shortcut semantics through Windows COM.
- Actual partial-root scan admits only `AutoClip.lnk` matching that pin. All
  other existing matching-manifest and unexpected-file rules remain in place.
  Its validated pin is retained when the native receipt is refreshed, so an
  intervening native bootstrap failure does not erase launcher ownership.
- Native receipt and marker use the existing repository's atomic temporary-file
  pattern, with same-volume temporary **siblings outside the managed root**.
  Partial writes therefore do not introduce unexpected files inside that root.
  Required marker is moved only after complete flushed bytes exist. Native
  receipt replacement retains the previous receipt when a locked-file failure
  prevents replacement.
- Shortcut creation likewise saves a temporary sibling and moves/replaces only
  after Windows has written it. On ownership-record failure, only a newly created
  shortcut whose current size/hash still exactly match this attempt is removed;
  preexisting/modified files are preserved. Temporary siblings are removed only
  when their exact authored bytes remain unchanged; interrupted/unverified or
  modified siblings may remain for review outside the managed root.
- Desktop behavior remains optional; an existing Desktop shortcut is preserved.

Consumer inspection: `update.ps1:171+` reads `installed_files` and validates its
eight native records; profile selection reads named existing fields. The exact
immutable recipe's cached-receipt checks read named source/profile/wheel fields.
No inspected consumer rejects additive installed fields. The build-cache
receipt itself is not modified; only the installed copy gets this optional
ownership field. No application/API/runtime dependency contract was changed.

## RED / GREEN

Before production edits, exact command:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File tests/InstallerCompletion.Tests.ps1
```

RED exit 1: executing the actual AST completion action and actual launcher helper
against missing real launcher inputs swallowed their failure as a warning and
left `.install-complete`. Assertion: `RED: required launcher failure was
swallowed or left a completion marker.`

Final GREEN, same command exit 0, using real first-party filesystem/Windows COM:

1. Missing required launcher inputs propagate with no marker.
2. A real ACL denial of destination marker creation causes the actual atomic
   write to fail; no marker exists and the actual generated shortcut remains
   correctly pinned.
3. Actual matching-release early retry decision and unexpected-file scan accept
   that partial root. Actual native-receipt refresh retains its pin; actual
   completion retry commits the marker after validating the same shortcut.
4. A real unrecorded shortcut is rejected without overwriting its bytes.
5. A byte-modified shortcut is rejected and preserved.
6. Actual retry scan rejects an unexpected recipient export and preserves it.
7. A real held read handle blocks native-receipt replacement. Failure propagates,
   previous receipt hash remains unchanged, only the newly created exact shortcut
   is removed, and a subsequent retry succeeds after the handle is released.

Adjacent exact commands, each exit 0:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File tests/InstallerBuildProcess.Tests.ps1
powershell -NoProfile -ExecutionPolicy Bypass -File tests/InstallerMsys2SourceGuard.Tests.ps1
powershell -NoProfile -ExecutionPolicy Bypass -File tests/InstallLaunchers.Tests.ps1
powershell -NoProfile -ExecutionPolicy Bypass -File tests/InstallerSecureAcquisition.Tests.ps1
powershell -NoProfile -ExecutionPolicy Bypass -File tests/InstallerNoAcquisition.Tests.ps1
git diff --check
```

Final BuildProcess run (session 51248) observed terminal exit 0 against the frozen
bootstrap below: eighteen actual post-recipe CPU/NVIDIA fixture cases and all
accepted/late/startup cancellation orderings remained green. Its completion
fixture now supplies existing native receipt, first-party launcher inputs and
the actual COM shortcut helper. No fixture executable or vendor binary ran.
Diff check emitted existing CRLF warnings only.

### Deliberately resolved test/source conflict

`InstallLaunchers.Tests.ps1` formerly asserted call-after-marker. That conflicts
with the explicitly revised requirement. Parent authorized correcting it to
call-before-marker and loading its new safe-path helper dependency. All actual
launcher target/arguments/Desktop preservation assertions remain intact; the new
completion suite proves failure/order behavior rather than relying on that
source check alone.

MSYS source-guard fixture used the removed `Copy-Item` token as its pre-receipt
endpoint. Parent authorized replacing only that locator with equivalent
`$nativeReceiptBytes =`; all actual source-entry and negative scenario assertions
were retained and rerun. This is not a waiver of the MSYS guard.

## Frozen files

| File | SHA256 |
| --- | --- |
| `install.ps1` | `fdb9fb9e9f2ffa0405ff35898b4362d54f3c87b56923483c8341e5b88fa18989` |
| `tests/InstallerCompletion.Tests.ps1` | `2643abc03db31c6d081793f897071df4f40da8c7082a359962bb9282501e1eeb` |
| `tests/InstallerBuildProcess.Tests.ps1` | `36c8d4ca03d84f1ff42010ee4e1322244924e1ad049d633d998dd55ca4de902b` |
| `tests/InstallLaunchers.Tests.ps1` | `9fbfadb70c5ba98611e2f91130e9320b5d43ab10c4c06c94e5ced76795f7084f` |
| `tests/InstallerMsys2SourceGuard.Tests.ps1` | `0f62f5c45233852e1d89ac794e1cbbb26a5fafa5333e492e363a9439654d1ceb` |

## Limits

These are host first-party boundary tests, not exact generated setup, native
source compilation, ordinary installed app health, media workflow or lifecycle
acceptance. Optional metadata compatibility was inspected, not a full installed
updater exercise. Recipient-owned pins are local integrity evidence and never
grant elevated execution authority. Unknown/modified outputs remain blocked
and preserved, rather than receiving automatic cleanup or overwritten ownership.
Final health and setup-owned installation receipt remain separate parent gates.
Uninstaller tests still wait until the installer works and is production ready,
then run before release.
