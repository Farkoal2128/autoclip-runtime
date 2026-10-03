# IM-WIZ-10 — root Inno source-build integration

Status: source integration and first-party build checks; exact wizard execution
and cancellation qualification remain open. Installer/updater change under
contract-v1, IM-WIZ-07/08 and the user objective. Root owns the Inno source,
builder, compiler-input tests and integration records. Other workers' changes
and immutable laboratory controls are preserved.

The Inno page now invokes the pinned hidden source-build supervisor with typed
UTF-8 JSON, shows its bounded recent log tail, and animates the existing page.
The worker's full logs remain separate from WScript pipes. The builder includes
the helper as its twentieth locked input, supplies its SHA to the actual
compiler invocation, and records it in the candidate receipt. Relative helper
source paths follow the existing Inno [Files] pattern; no extra path define is
needed. The embedded audit list and its expected helper/notice inventory were
aligned, but that compiled audit was not executed.

Meaningful build RED: `python -B -m unittest discover -s .github/tests -p
test_inno_build.py` failed for the missing helper compiler define, missing
receipt field, and an actual successful write/rename to the unprotected new
helper while the verifier/compiler fixture ran. After adding the helper to
the existing locked input set/defines/receipt, all 11 tests passed. These
tests execute a first-party fake compiler; they do not run a setup executable.

Exact ISCC syntax compile initially failed because StringJoin's arguments
were reversed. Corrected to the native separator-first signature documented
by [Inno Setup](https://jrsoftware.org/ishelp/topic_isxfunc_stringjoin.htm).
The current recorded successful syntax snapshot is:

- Source SHA: `79840d80b2b4e689bd66aa1b8a0a0c9e36390a7811738d91942f7ee34c332116`.
- Bootstrap SHA: `0a82cd0bf441b93a0074e43548f25c0d784fc8cd96c1fc3ba73b8f0cb20cf4d2`.
- Supervisor SHA: `c69cace7ce9f5988918e0208118b4838316d39c3e6e4d3aa0ff1a8d3267c1ead`.
- Compiler SHA: `d06ebd38f38e3cee60a3c50cc45bd449d77e0bc6a5cabc607ea9886808e4de1a`.
- Output: `D:/AutoClip-Inno-Migration/im-wiz-08-compile-l1v4_e5u/AutoClip-Setup-v1.exe`.
- Output SHA: `a44112aa8296dd7e1cba66d6a7f2897c8f41cc28f2bcee09ab7bf83143934d9a`.
- Exact defines/command and exit 0: adjacent `compile-inputs.json`; full output
  in `compile.log`. Root invoked `python -B
  D:/AutoClip-Inno-Migration/compile-current-inno.py`.

This private direct compile uses canonical BLOCKED metadata for syntax
inspection only. It is not the guarded production build, current final source,
installer qualification or publication evidence. It was not executed. Later
source changes need new hashes and a new candidate. The earlier automatic
policy rejection of compiled `/AUDIT` execution remains unresolved; it was
not retried via another route.

Root also ran `powershell.exe -NoProfile -File
tests/InstallerPreflight.Tests.ps1` without SetupExe, exit 0, and
`git diff --check`, exit 0. Thus only preflight fixtures were exercised.
IM-WIZ-09 separately preserves compile-only MSYS decision-fixture adaptation.

IM-WIZ-11 found post-recipe cancellation, startup signaling and finalization
races. IM-WIZ-12 adds meaningful post-recipe native-boundary checks. The
contract now explicitly discloses waiting for the whole immutable recipe and
requires serialized accepted cancellation versus completion commit. IM-WIZ-13
implements that protected boundary; its Inno request-mode integration and
exact guest tests remain pending. No passing cancellation claim is inferred
from compilation or from these producer summaries.

The subsequent integration routes build cancellation through that request mode
before the page becomes interactive, accepts only requester exit 0, latches
exit 170 as too late, and observes both the requester and original supervisor.
Native Cancel is disabled after either decision and restored after observation.
Root reran all 11 builder checks and the real first-party supervisor/process
fixture, both exit 0. IM-WIZ-14 records internal read-only collaborator findings;
its launcher/marker retry finding is separately being fixed under IM-WIZ-15.

Newer syntax-only snapshot:
`D:/AutoClip-Inno-Migration/im-wiz-08-compile-64nelbmj/AutoClip-Setup-v1.exe`,
SHA256 `f6936c02cad5d260d4f8a6bb4e22583862d1e89f6066cb9ad5554e61aef01a58`.
Source SHA256 `6e8596ff00a8a3683b4b536b6e41185bff73038f39e6e934399fd809fed367a5`;
bootstrap `edf3fda3081257fc2919630c104e534e0bc5ccd65ce15f760bd5875d3f59359b`;
supervisor `daa1b1ac6094938770845b287e729993317c58d428b4601123a5a29ed2cad9e8`.
Adjacent compile-input receipt SHA256
`6583526b593356a8991ad2a78d94a9d4c72c4a8ee7c283c417c262947934f1f1`
binds exact definitions and exit 0. Same compiler and direct command as above.
This diagnostic was not executed; exact callbacks/UI remain unverified.

Uninstaller execution remains scheduled after the installer is working and
production ready, before release. It has not been executed here.
