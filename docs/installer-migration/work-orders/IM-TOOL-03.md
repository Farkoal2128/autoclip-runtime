# IM-TOOL-03 - Persistent setup tool notices and guarded build receipt

Completed bounded implementation 2026-10-01. Parent authorization explicitly
covers `installer/AutoClip.iss`, `scripts/build-inno.py`,
`.github/tests/test_inno_build.py`, `release/notices/setup-tool-sources.md`, and
this work order. No other repository files were edited by this work order.
The exact Inno/uv texts delivered previously are reused without modification.

## Requirement and contract

The parent-owned `docs/installer-migration/contract-v1.md`, section
**Setup-owned tool notices**, requires the exact Inno Setup 7.1.0 and uv 0.12.19
MIT/Apache texts plus a source index in the persistent setup-owned `notices`
directory. Missing or changed versioned texts must prevent compiler execution;
the receipt binds every delivered notice/index by size and SHA-256.
The affected producers are the guarded Python builder and Inno `[Files]` table;
consumers are the recipient and parent packaging reviewer. The receipt adds
`notices`, an array of installed-relative path/bytes/sha256 records, while
retaining schema version 1 and the existing Inno-only `notice_sha256` field.
No parent contract or manifest was edited here.

## RED before production changes

The test copies the actual builder/verifier and repository inputs into isolated
temporary snapshots, corrupts or omits uv texts, and runs the builder CLI with a
first-party fake compiler. It does not mock the notice validation under test.
After isolating each subcase's output to avoid stale fixture interference:

```powershell
python -I -B .github/tests/test_inno_build.py InnoBuildTests.test_missing_or_changed_uv_license_refuses_before_compiler
```

Exit 1, four expected failures: missing MIT, same-size changed MIT, missing
Apache, and same-size changed Apache all returned success and invoked the fake
compiler. Production edits had not begun. The first broader RED command was:

```powershell
python -I -B .github/tests/test_inno_build.py InnoBuildTests.test_missing_or_changed_uv_license_refuses_before_compiler InnoBuildTests.test_setup_installs_all_notices_as_normal_persistent_files InnoBuildTests.test_verified_unblocked_graph_invokes_compiler_and_writes_hashed_receipt
```

It also showed the existing Inno notice used `dontcopy` and `{app}`, the uv/index
entries were absent, and the receipt lacked `notices`. Its later uv subcases
initially encountered the first subcase's output; the isolated rerun above is
the clean behavioral RED evidence. The final license test was renamed
`test_missing_or_changed_license_refuses_before_compiler` and extended to cover
the Inno text as well.

## Minimum implementation and GREEN

- Four normal `ignoreversion` file entries install to `{app}\notices`; no notice
  entry uses `dontcopy`.
- Builder pins all three versioned texts by exact expected length and SHA-256
  before compiler execution. It requires a nonempty source index and records
  its exact bytes in the additive receipt inventory.
- The index attributes Inno and uv, provides uv commit/tag/archive/terms URLs,
  and states the private recipient acquisition scope and embedded-component/
  redistribution limits. MinGit's complete package notice tree remains required.
- Existing build guards, helper pins, and receipt assertions remain in place.
- The existing `/AUDIT` branch now also extracts and logs SHA-256 for both uv
  texts and the source index using three literal calls of each kind. This
  diagnostic addition introduces no new branch, parser, or fixture.

```powershell
python -I -B .github/tests/test_inno_build.py
python -I -B .github/tests/test_installer_manifest.py
git diff --check -- installer/AutoClip.iss scripts/build-inno.py .github/tests/test_inno_build.py
```

Results: nine builder tests PASS (including six missing/changed license subcases),
16 manifest tests PASS, and scoped diff check PASS. Python source syntax was
also parsed without writing bytecode using this exact command:

```powershell
@'
import ast, hashlib, pathlib
paths = ['installer/AutoClip.iss', 'scripts/build-inno.py', '.github/tests/test_inno_build.py', 'release/notices/setup-tool-sources.md']
for name in paths:
    path = pathlib.Path(name)
    data = path.read_bytes()
    if path.suffix == '.py':
        ast.parse(data, filename=name)
    print(f'{name} | {len(data)} | {hashlib.sha256(data).hexdigest()}')
'@ | python -I -B -
```

No additional refactor was needed. Canonical qualification was checked with:

```powershell
python -I -B scripts/verify-installer-manifest.py --manifest release/manifests/installer-dependencies-v1.json --archive D:/AutoClip-Inno-Migration/autoclip-source-build-v40-provenance-continuity.zip --profile cpu --require-installable
```

Expected exit 1: `required native build asset is blocked: ffmpeg-8.1.2.tar.xz`.
This is retained gate evidence, not a passing installability result.

## Frozen implementation identities

| File | Bytes | SHA-256 |
| --- | ---: | --- |
| `installer/AutoClip.iss` | 48,596 | `3b5aab1ea6a2d0f7d1b31547e175e7603dc9d4984b9a1ad6adfe1ad51754bfba` |
| `scripts/build-inno.py` | 7,861 | `d258f515ad8e8c65508eab0b0b44a6006d8ce33ab8b901a38266b992fc5d5d84` |
| `.github/tests/test_inno_build.py` | 15,375 | `5241927506d9402c57a24a07530f237c175d80fc2191f8d7e7e21910c93f46f9` |
| `release/notices/setup-tool-sources.md` | 2,579 | `f6135e7d73d46520ada9ad24fd158d559737680313da4a764ba3f434467e7995` |

Pinned Inno text: 1,521 bytes,
`2e5346868c2a18434489824e11d65c3031620f792fefc415d05f19cd441abf5c`.
Pinned MIT text: 1,077 bytes,
`860e3d7a86b84e6a7012c7a635fc64df475cebc6cce34dfeb73a5982ec58176c`.
Pinned Apache text: 11,357 bytes,
`c71d239df91726fc519c6eb72d318ec65820627232b2f796219e87dcf35d0ab4`.

## Compile-only evidence and limits

The existing pinned ISCC was verified at 2,135,968 bytes, SHA-256
`d06ebd38f38e3cee60a3c50cc45bd449d77e0bc6a5cabc607ea9886808e4de1a`.
Direct source compilation exited 0, and every source/helper/manifest/notice
input hash was compared before and after compilation. The arguments were
constructed from current manifest fields and current helper hashes, including
base helper `70293061a4a5c41e7064e7c7f22e4f6132d08161e0a448196602d018240e61be`.
The installable builder gate was not bypassed to install or promote a candidate.

Evidence directory:
`C:\Users\beilo\AppData\Local\Temp\im-tool-03-audit-compile-x3heibgl`.
It retains `compile-arguments.json`, `compile.log`, `compile-receipt.json`, and
the unexecuted `AutoClip-Setup-v1.exe`: 2,594,827 bytes, SHA-256
`7a221b60ace775938ac317c2ab587cd7aeddb4db4ae62290b35a83576343624a`.
The receipt labels it `COMPILE_ONLY_UNEXECUTED`, not an installable build receipt.
Exact replay command, using a new output directory in the argument file:

```powershell
[string[]]$compileArgs = Get-Content 'C:\Users\beilo\AppData\Local\Temp\im-tool-03-audit-compile-x3heibgl\compile-arguments.json' -Raw | ConvertFrom-Json
& 'D:\AutoClip-Inno-Migration\InnoSetup7\ISCC.exe' @compileArgs
```

The compiler log records compression of all four notice/index files. Prior to
adding the three literal audit calls, the parent reported automatic tool policy
rejected both VM `/AUDIT` attempts (first silent, then ordinary). Neither
executed; the policy returned no reason beyond blocked by policy. No VM RED is
claimed. The parent explicitly authorized the diagnostic additions under the
already demonstrated notice-delivery RED/GREEN and retained the actual audit
gate. After adding them, source compilation and all nine builder tests passed
again. The final compile also required every non-source input to match the prior
compile receipt before execution, then checked all inputs again afterward.

No setup EXE, host vendor program, or VM was executed by this work order.
Actual candidate notice hash/audit verification remains **UNVERIFIED** and
tool-blocked, not closed by the source test or compiler compression log. Final compiled
payload inspection, installed notice contents, ordinary-user wizard acceptance,
acquisition/cancellation qualification, runtime source build, and all legal/
publication decisions remain parent-owned. No application recipe, acquisition
helper, dependency manifest, publisher cache, or release pin was changed.

Suggested commit subject: `fix(installer): retain and pin setup tool notices`.
