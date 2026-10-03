# IM-DEP-05: controlled CPU native artifact packager

Date: 2026-10-02. Parent assignment authorizes implementation under the user's
new controlled publisher CPU artifact request. Requirement:
`docs/installer-migration/cpu-native-artifact-v1.md`; related disposition:
`work-orders/IM-DEP-02.md`. This work is runtime packaging, not qualification.

## Ownership and behavior

Owned files only:

- `scripts/package-cpu-native-artifact.py`
- `.github/tests/test_cpu_native_artifact.py`
- `docs/installer-migration/work-orders/IM-DEP-05.md`

Root owns actual builds, source/provenance/legal preparation, contracts and
consumer integration. No concurrent edits to those files, compiler execution,
dependency acquisition, Setup/VM execution, publication or acceptance occurred
in this assignment.

The CLI accepts `--wheelhouse`, `--build-root`, `--source-directory`, `--output`,
and `--runtime-id`. Windows input-sharing locks are reused from `build-inno.py`.
Exactly `av-18.1.0-cp311-abi3-win_amd64.whl` and
`ctranslate2-4.8.2-cp311-cp311-win_amd64.whl` are selected. Existing source pins,
strict CPU receipt/profile/flags, actual wheel size/hash and FFmpeg configuration
hash must match. Actual FFmpeg header exclusions and configure flags are checked.
The existing native wheel verifier runs in the current Python process, requiring
its existing `pefile` dependency; its ZIP/RECORD/DLL/import checks are reused.

The complete supplied source directory is included under `sources/`. Supply:

- `provenance.json`: nonempty JSON object containing actual producer, toolchain,
  recipe/source/submodule identities, modifications and build evidence.
- `source-associations.json`: schema version 1, `components` array with at least
  `ffmpeg`, `pyav`, `ctranslate2`, `onednn`; each row has `component`, nonempty
  `source_paths` and `notice_paths`, relative to the supplied directory. Additional
  embedded component rows are accepted. Sources may reference a complete tree or
  archive; notices reference nonempty files.

Build-root inputs are the original `native-build-receipt.json`,
`ffmpeg-config.mak`, `ffmpeg-config.log`, and `ffmpeg-config.h`. Their original
bytes/hashes are retained. Traversal, Windows unsafe paths, case collisions,
reparse points, binary/tool/cache payloads and archive links are rejected.
ZIP/TAR archives, including renamed recognizable archives, are recursively
inspected to three levels. Tracked `.bin` data is not rejected solely by suffix;
native executable/object/library formats remain excluded.

The schema1 `native-artifact-manifest.json` contains `runtime_id`, `profile=cpu`,
`platform=win_x64`, `python=cp311`, `qualification=UNQUALIFIED_CANDIDATE`, exact
file rows, producer receipt/provenance paths and source associations. It binds
every payload byte, without claiming legal/source completeness approval.
All selected inputs remain locked through publication. A temporary complete ZIP
is published with an exclusive same-volume hard link; prior/racing outputs are
preserved, and an interrupted temporary output is cleaned.

## Verification evidence

Exact focused command, from `D:\Projects\autoclip-runtime`:

```powershell
python -m unittest discover -s .github/tests -p test_cpu_native_artifact.py -v
python -m py_compile scripts/package-cpu-native-artifact.py .github/tests/test_cpu_native_artifact.py
git diff --check
```

RED: before production creation, packaging capability assertion failed in four
tests. A subsequent meaningful behavioral RED rejected an enabled GPL header
with `AssertionError: ValueError not raised`; the minimal header/log checks made
it GREEN. Parent evidence corrected PyAV's real ABI3 filename: the successful
inventory test first failed at the wheel-selection guard, then passed after its
exact expected filename was corrected. Final GREEN: six tests pass; compilation
and diff whitespace checks pass.

Tests cover exact byte inventory and candidate state, receipt/profile/flags/pin
substitution, changed wheel bytes, FFmpeg header inconsistency, nested/hidden
archive binaries, traversal/case collisions, real Windows directory junctions,
native verifier rejection, interrupted output writes and concurrent output
creation. Native PE inspection alone is replaced at the external inspection
boundary with synthetic wheel data; packaging, locks, inventory, binding,
exclusions and publication execute normally.

Limits: tests do not establish actual native wheel compatibility, source/legal
completeness, clean-machine installation, GPU capability or release permission.
Root must run this CLI with actual build outputs and supplied source evidence,
then carry the resulting exact bytes into the remaining review gates. Packaging
holds payload bytes in memory; the controlled source packet must fit host RAM.
No broad application or installed-release smoke checks were performed here.

Suggested commit: `feat: package unqualified controlled CPU native artifacts`.
