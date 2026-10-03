# IM-DEP-12: package a distinct publisher CPU consumer successor

Date: 2026-10-02. User Stage A–D direction authorizes a fresh publisher CPU
artifact and its consumer integration. This work owns only the new stdlib
producer, its focused tests, and this record. Root owns actual production,
Inno integration, VM verification and release decisions.

## Requirement and contract

Preserve the latest indexed r18 application, its 75 publisher-wheel routes,
external vendor routes, source and historical evidence. Assign a distinct
release identity and the exact new CPU runtime identity; retain the nine
source inputs and compiler/SDK/Git/MSYS2 requirements for optional NVIDIA.
Visual Studio and SDK remain blocked for that profile. CPU uses the separate
qualified native ZIP, which is never nested in the consumer release archive.

The producer follows `cpu-native-artifact-v1.md` and the actual
`verify-installer-manifest.py` descriptor/receipt contract. It retains the
original component disposition and report byte for byte. A separately named,
indexed consuming receipt supplies the schema 1 `decision` and exact
runtime/filename/size/hash fields, with references to those originals and
their component-only limits. It does not reinterpret historical source-build
evidence or upgrade immutable native candidate metadata.

`notices-and-source/publisher-cpu/README.md` identifies the installed notice,
corresponding source and FFmpeg replacement instructions, and the pinned
native source ZIP download. New controlled producer/helper snapshots live
under a distinct prefix; original historical snapshots remain intact.

## Implementation and integrity

`scripts/build-publisher-cpu-release.py` accepts an indexed schema 3 base,
the dependency policy, native artifact, original disposition/report and
current standalone bootstrap. Its CLI requires SHA-256 pins for the base,
policy, bootstrap and both original review inputs. Native bytes are checked
against the original exact qualified component identity, then validated by
the existing ZIP/RECORD/source/config consumer helper.

The producer rejects reparse paths, unsafe/duplicate archive members,
changed or unindexed base files, substituted review inputs, colliding
evidence paths, wrong asset filenames and existing/aliased output files.
It preserves the base inventory rather than calling the older utility that
assumes 74 publisher wheels. It changes only the release/native metadata,
inventory native metadata, new indexed evidence and corresponding pins.
Current canonical bootstrap public pins remain unchanged; only a separate
standalone output receives successor pins. The complete staged candidate
must pass the actual CPU installability verifier before exclusive output
creation. Outputs remain `UNPUBLISHABLE_REVIEW_PENDING`.

## RED and GREEN

Working directory: `D:/Projects/autoclip-runtime`.

```powershell
python -m unittest discover -s .github/tests -p test_publisher_cpu_release.py
python -m py_compile scripts/build-publisher-cpu-release.py
git diff --check -- .github/tests/test_publisher_cpu_release.py scripts/build-publisher-cpu-release.py
```

RED: the three inherited successor behavioral tests raised
`FileNotFoundError` for the absent producer; the 22 imported existing manifest
tests passed. GREEN: all 27 tests pass, comprising five successor tests and
those 22 existing manifest regressions. Checks exercise byte preservation,
75-wheel inventory, preserved original review bytes, distinct consuming
receipt, actual synthetic CPU gate, retained NVIDIA block, changed base,
review substitution, native corruption, explicit input pins and immutable
output aliases/retry rejection. Compilation and scoped whitespace checks
pass.

Tests use first-party synthetic native fixtures and synthetic component
review records. This work did not produce the real successor, execute native
libraries, acquire prerequisites, install in a VM, run uninstall or publish.
Root must freeze and supply exact production input pins, produce the actual
successor and retain its original source/native/evidence identities. Public
source availability, installed notices, complete Setup/application/lifecycle
and generated uninstall evidence, exact review and release approval remain
separate requirements.

## Root integration addendum: durable updater provenance

IM-UN-06/07 add the current updater selection mutex to the finite durable cleanup
helper set. Root found that the consumer producer snapshot covered installer
helpers but omitted this root-level updater input. Before producing the next
candidate, the actual successor test now requires its exact bytes and SHA-256
in the separately indexed producer provenance. Meaningful RED was a missing
`notices-and-source/publisher-cpu/producer-inputs/update.ps1` archive member.
The minimum producer change adds `ROOT / 'update.ps1'` to the controlled input
list. The same 27-test command is GREEN. Historical r1 and base updater bytes
remain intact; no existing archive was rewritten or approval rebound.
