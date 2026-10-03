# IM-TOOL-01 — uv and MinGit direct recipient evidence

Reviewed 2026-10-01. Read-only tool acquisition/licensing investigation with
only this report written. This is same-session internal verification, not a
blinded final setup review, legal advice, actor-rights determination, or release
approval. No installer, manifest, test, application, host/guest installation,
Git history, or release was changed. The root coordinator owns classification.

## Bounded route recommendation

The inspected official licensing/source records support a proposed
`DIRECT_RECIPIENT_DOWNLOAD` route for the exact uv 0.12.19 and MinGit
2.55.0.3 x64 archives below, acquired into recipient-owned staging and executed
unmodified as separate tools. Keep the original archive identities and local
notices/source entry points, verify extracted executable identity, and retain
the project's explicit recipient download decision. This recommendation covers
the tool acquisition/use operation only.

It provides no AutoClip bundle, mirror, redistributed populated cache, complete
static/transitive SBOM, supplier compliance assurance, or publication clearance.
An Authenticode signer is evidence of executable identity; it does not replace
the published license or establish every incorporated component's rights.

uv's ZIP has no license text. The exact upstream texts below should be retained
with the installed recipient tool/index before reporting notice delivery
complete. For MinGit, retain the original whole extracted notice tree, root
license, and package-version file. Merely retaining `cmd/git.exe` would discard
both required supporting binaries and the inspected component evidence.

## Independently inspected archive/executable identities

Live official [uv release metadata](https://api.github.com/repos/astral-sh/uv/releases/tags/0.12.19)
and [Git for Windows release metadata](https://api.github.com/repos/git-for-windows/git/releases/tags/v2.55.0.windows.3)
both list the selected assets as `uploaded`. Published digests and sizes agree
with independently recomputed local archive hashes.

| Object | Bytes | SHA-256 |
| --- | ---: | --- |
| uv Windows x64 ZIP | 17,955,780 | `6dbb02d79e419522f1c500f0adb1cddcff0cda7d59b0d66ea7f5e3b4a1b2f5f0` |
| uv ZIP `uv.exe` | 42,417,456 | `f94eddb81f3addca6ef8f2361a70c3edde31adcbd1000a55fc6674306ae0b1e7` |
| uv ZIP `uvw.exe` | 348,976 | `ff6a3488a4d71b035f7368cfc65273fbdaafffa300717c7886b621cfea4cf140` |
| uv ZIP `uvx.exe` | 348,976 | `177e4eb197b040c356a96970e97f12e1da39f727e5e3a4fc3086baa20fc3a052` |
| MinGit Windows x64 ZIP | 38,791,206 | `f48e2d2dc74a24454adc6d8fd0ac25bf9c2386f19cfb06202b9465aaad4f9f05` |
| MinGit `cmd/git.exe` | 46,920 | `7b7971dd13f0c3a284e538601f2f9770b3a87dfaccb5fb52d68141c67ed22364` |
| MinGit `mingw64/bin/git.exe` | 4,383,048 | `1a0043555d254618f2d56c936c3d9a1fbfb878bc878416a133c346bc7835eda9` |
| MinGit root `LICENSE.txt` | 19,125 | `454649ddc02b5cc098513cea28db6592b45ac0a906386287c4d48cf8dbde651c` |
| MinGit `etc/package-versions.txt` | 1,690 | `104ca60c3e0db5c282f92357fb99235e054d9c4105a0b8db1bd3d023cfbf6cbd` |

Exact binary URLs:

- `https://github.com/astral-sh/uv/releases/download/0.12.19/uv-x86_64-pc-windows-msvc.zip`
- `https://github.com/git-for-windows/git/releases/download/v2.55.0.windows.3/MinGit-2.55.0.3-64-bit.zip`

Local ZIPs are under `D:\AutoClip-Inno-Migration`, named
`uv-0.12.19-x64.zip` and `MinGit-2.55.0.3-64-bit.zip`. Both passed
`ZipFile.testzip()`: uv has exactly three EXE members; MinGit has 368 members,
365 regular files and three directories. MinGit includes 96 DLL files and 89
EXE files. A file count is not an incorporated-component count.

The existing scratch extracted uv executables and both Git executables were
independently compared with their ZIP member hashes. Actual local commands:

- `uv.exe --version`: `uv 0.12.19 (bea138450 2026-09-24 x86_64-pc-windows-msvc)`.
- `cmd/git.exe --version`: `git version 2.55.0.windows.3`.
- `Get-AuthenticodeSignature`: all three uv executables `Valid`, signer
  `OpenAI OpCo, LLC`; MinGit `cmd/git.exe` `Valid`, signer
  `Johannes Schindelin`.

These are independent checks of these local bytes, not a clean setup
installation, acquisition failure test, or proof of every native import.

## uv exact licensing/source evidence

The official 0.12.19 tag resolves to
`bea138450f0e620a4ce5765b0e38cff7b9f0799f`, consistent with the executable's
revision string. The exact tag's [Cargo.toml](https://raw.githubusercontent.com/astral-sh/uv/0.12.19/Cargo.toml)
and [README licensing section](https://raw.githubusercontent.com/astral-sh/uv/0.12.19/README.md)
declare a choice of MIT or Apache-2.0. The source MIT text names Astral Software
Inc.; the Windows signing subject does not change that declaration.

| Exact upstream material | Bytes | SHA-256 |
| --- | ---: | --- |
| [LICENSE-MIT at 0.12.19](https://raw.githubusercontent.com/astral-sh/uv/0.12.19/LICENSE-MIT) | 1,077 | `860e3d7a86b84e6a7012c7a635fc64df475cebc6cce34dfeb73a5982ec58176c` |
| [LICENSE-APACHE at 0.12.19](https://raw.githubusercontent.com/astral-sh/uv/0.12.19/LICENSE-APACHE) | 11,357 | `c71d239df91726fc519c6eb72d318ec65820627232b2f796219e87dcf35d0ab4` |
| [Published source.tar.gz](https://github.com/astral-sh/uv/releases/download/0.12.19/source.tar.gz) | 8,720,078 | `26a42b3580e990db68120838c2512a678aedd473c777b34aa802dc100ef7c76a` |
| Source member `uv-0.12.19/Cargo.lock` | 190,188 | `f7c745d23b637e3458f50fdad8a7f193348fbc11043e687bf4034fb2b391b59e` |

Both license texts were fetched from the official exact tag. The release source
archive was fetched into memory, rehashed against its live publisher digest,
and inspected without extracting/installing its code. Its root license members
exactly match the two text hashes above.

The MIT text permits use while retaining its copyright/permission text in
copies. Apache-2.0 supplies permissions and redistribution/notice conditions;
these texts are not evidence of an additional paid or proprietary recipient
EULA. Retaining both texts records the offered alternatives without inventing a
license change. Link the exact source tag/archive from the recipient index.

The ZIP's lack of texts is a concrete notice-delivery gap for a route that claims
to leave an installed notice index. Supplying those exact upstream texts fixes
the top-level uv gap; it does not establish every Rust/native dependency's
notice fulfillment. Cargo.lock is a source dependency record, not an exact
Windows linked-object SBOM. No dependency license scanner, build reproduction,
attestation validation, or complete embedded-third-party notice reconstruction
was performed. That supplier evidence limit must remain explicit.

## MinGit exact licensing/source evidence

The exact tag resolves to `52ca1113d651127f89477a8763f86ab20f645e1d`.
Official [COPYING at the tag](https://raw.githubusercontent.com/git-for-windows/git/v2.55.0.windows.3/COPYING)
is 18,765 bytes, SHA-256
`5b2198d1645f767585e8a88ac0499b04472164c0d2da22e75ecf97ef443ab32e`.
It matches the ZIP's root `LICENSE.txt` after removing carriage-return bytes.
The project preamble specifies GPLv2 unless a file explicitly states otherwise;
the whole MinGit package must not be described as uniformly GPLv2-only.

The same official release publishes
[mingw-w64-git-2.55.0.3-1.src.tar.gz](https://github.com/git-for-windows/git/releases/download/v2.55.0.windows.3/mingw-w64-git-2.55.0.3-1.src.tar.gz),
12,483,901 bytes, SHA-256
`83fe0426914069810fe3b4b5b4c662f52757b553d05272933ca0ea370cf1d905`.
It was independently fetched into memory and rehashed against publisher
metadata. Its 19 entries include `PKGBUILD`, `.SRCINFO`, wrapper sources, build
helpers, and `git-v2.55.0.windows.3.tar.gz`. PKGBUILD identifies the matching tag
and GPL2. This is concrete core/package build-source evidence, not complete
corresponding source for every additional DLL or bundled tool.

The archive provides 17 `mingw64/share/licenses` component roots: brotli, curl,
expat, gcc-libs, gettext-runtime, libffi, libiconv, libpsl, libssh2, libtasn1,
libunistring, libwinpthread, nghttp2, openssl, pcre2, zlib, zstd. Six additional
`usr/share/licenses` roots cover gcc-libs, libopenssl, libsqlite, ncurses,
openssh, zlib. Git Credential Manager has separate `LICENSE` and `NOTICE`
under `mingw64/doc/git-credential-manager`.

| Delivered component evidence inspected | Recorded content and scope |
| --- | --- |
| Git root LICENSE | GPLv2 text and project preamble; running is outside the restricted activities in section 0, while distribution/source duties are separately described. |
| GCC libraries README, COPYING3, COPYING.RUNTIME and COPYING.LIB | Package README distinguishes GPL-3.0-or-later with GCC-exception-3.1 for libgcc/libstdc++/libgomp/libatomic, and LGPL-2.1-or-later for libquadmath. It does not prove all these libraries are used by this MinGit operation. |
| gettext-runtime COPYING and library texts | Explicitly distinguishes LGPL libraries from GPL programs/documentation. Preserve that distinction and the delivered texts. |
| Git Credential Manager LICENSE and NOTICE | MIT license and additional attribution material; LICENSE SHA `b47f1a8a744ecdc7a3da35804f88552805d33f51a726b87a2105acdfae406b07`, NOTICE SHA `f573f5d21d5d8a054aad1ffcbe0165391a4d93a5aa3e23c3db0752759adfd50c`. No auth-provider account operation was tested. |
| OpenSSL LICENSE files | Apache-2.0 text; SHA `7d5450cb2d142651b8afa315b5f238efc805dad827d91ba367d8516bc9d49e7a`. |
| PCRE2 LICENCE.md | Declares BSD-3-Clause WITH PCRE2-exception and separately describes its JIT material. SHA `197d8a73ffee0d6b09adba2f9c677b5f5aede24edf89258a68e48248d010d811`. |
| Brotli, curl, libwinpthread and SQLite texts | Inspected permissive notice/grant texts or SQLite dedication. This does not replace inspection of every source object's applicable terms. |

All named legal-file members were read and hashed. The complete MinGit member
inventory digest is
`c32f1206d3640fdb5ead32d77e84d15c0e24f63cd2efd9337b3b4d905deb1c17`:
sort member rows by path, with keys `path`, `bytes`, `sha256`; serialize JSON with
sorted keys, comma/colon separators, then one LF, UTF-8.

`etc/package-versions.txt` records package identities, including Git
2.55.0.3-1, GCM 2.9.0-1, GCC libraries 16.1.0-5/15.3.0-1, OpenSSL
3.5.7-1, curl 8.21.0-2, PCRE2 10.47-1, MSYS2 runtime 3.6.9-2,
and OpenSSH 10.3p1-1. It also has duplicate entries and packages for the
publisher's broader build environment. Treat it as delivered package evidence,
not a precise final incorporation SBOM. Publisher
[MinGW package recipes](https://github.com/git-for-windows/MINGW-packages) and
[MSYS2 package recipes](https://github.com/git-for-windows/MSYS2-packages)
are useful source lookup routes; this investigation did not pin every recipe
commit/source archive to every extracted binary.

## Producer guest evidence inspected separately

The parent reports successful real host and clean guest guarded downloader,
signature, and version checks. Independently inspected producer receipt
`D:\AutoClip-Inno-Migration\vm-tools-20261001.json` has SHA-256
`340b29f5664e9192b408922d107c2a9f86f8a30805d4f338df5c854f38534440`.
It records matching archive/EXE hashes, matching versions, signatures `Valid`,
computer `AUTOCLIP-CR09-W`, and status `passed`. It is marked
`test_fixture_only: true`; its embedded UTC string is
`2026-09-27T08:08:02.4815825Z`. This report preserves that timestamp and does
not independently establish the guest clock or re-execute that guest test.

Adjacent `vm-transfer/tool-test-manifest.json`, SHA-256
`7222c6c951db29fcec8401ad54f9e4ebbca903c88bf292b27308d979edbd3ff1`,
is also expressly a test fixture. Those receipts support their recorded tool
probe scope. They are not final production-manifest or whole-wizard evidence.

## Policy interpretation and finite remaining route work

The setup contract requires exact approved official acquisition, the recipient's
explicit decision, applicable licensing evidence, installed capability checks,
and safe staging. It forbids acquisition of `BLOCKED` inputs. Its definition of
direct recipient download does not waive licenses; the requirement's source
provision applies where source is required for the actual operation.

For the inspected GPLv2 core text, private unmodified execution is distinguished
from copying/distribution obligations. uv's declared MIT/Apache alternatives
permit use under their conditions. No inspected upstream term establishes a
separate vendor-agreement purchase or a requirement that AutoClip first host
all supplier source before recipients run these publisher-acquired tools.
This is a bounded reading of inspected primary text, not a conclusion about
every actor, patent, nested source license, or planned distribution operation.

Before promoting the route, the root should bind the exact artifacts and
official HTTPS delivery hosts to the final manifest; deliver the two pinned uv
license texts and exact source links through the recipient notice index; preserve
MinGit's entire notices/package-version material; and bind the downloader,
signature/version and notice-delivery checks to the final production snapshot.
Recorded fixture/tool checks cannot be relabeled as complete setup, lifecycle,
or ordinary-user acceptance.

Onward distribution of either tool archive, any populated cache, or extracted
publisher binary needs a new operation-specific review of corresponding source,
nested notice coverage, and applicable rights. Complete static/transitive
component licensing remains unproved here and is not claimed merely because
the recipient execution route is supported. Preserve all earlier approvals,
holds, and technical reviews at their stated scope.

Contract snapshot inspected: `docs/installer-migration/contract-v1.md`, SHA-256
`b49df2081c88e02d2d4d1c4a98fa165ddb76f66175aeb7d1e0e4ada30ff5dbfb`.
Concurrent work is occurring in the repository; this report identifies an
evidence scope and does not approve a mutable final installer candidate.
