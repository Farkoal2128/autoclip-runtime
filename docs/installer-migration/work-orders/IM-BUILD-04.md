# IM-BUILD-04 — hold exact build inputs through candidate receipt

## Authorization and requirement

Parent explicitly authorized a bounded safety fix in `scripts/build-inno.py`, `.github/tests/test_inno_build.py` and this report. The existing setup provenance requirement binds source, payload archive, manifest, notices and compiler identity to the candidate. Parent owns canonical contract integration. Concurrent edits were preserved; no Inno source, installer helper, manifest, VM or release change was made by this worker.

The prior builder validated/digested files at different times and rehashed source/helper/compiler/builder/verifier inputs after compilation. A concurrent writer could therefore change bytes used by the compiler and get a receipt describing later bytes. Existing source/notice pins and refusal to overwrite candidates remain required.

## Implementation

Before any build input read or validation, the Windows-only build entry acquires `CreateFileW` handles with `GENERIC_READ`, `FILE_SHARE_READ`, `OPEN_EXISTING`; no write/delete sharing. Explicit ctypes argument/result declarations use pointer-sized HANDLEs and Win32 DWORDs. Null security attributes make the handles non-inheritable. `CloseHandle` cleanup runs through context-manager `finally` and stdlib `ExitStack`, including partial acquisition or later failures. Unsupported platforms refuse the build rather than claiming equivalent Unix locking.

The 19 inputs are manifest, payload archive, ISCC executable, Inno source, bootstrap, eight helpers, four notices, verifier and builder. All are locked before pin capture or verifier invocation and stay locked until receipt creation completes. Captured SHA-256 values feed compiler definitions and final receipt. Hashing uses Python 3.11 stdlib streaming `hashlib.file_digest`, avoiding an extra whole-archive allocation. Notice bytes and existing exact license pins are checked while locked. Existing candidate/receipt overwrite refusal is preserved.

The change uses only stdlib and the native Windows API. It adds no bypass flags, test URLs, framework or dependency.

## Meaningful RED → GREEN

Environment: Windows, Python 3.11.9, 64-bit process (independently queried with `python -c "import struct,sys; print(sys.version.split()[0], struct.calcsize('P')*8)"`).

Exact initial RED command from `D:\Projects\autoclip-runtime`:

```powershell
python -m unittest discover -s .github/tests -p test_inno_build.py -k inputs_block_mutation -v
```

Before production edits, the actual builder ran from an authorized disposable first-party snapshot and invoked a real `.cmd` fixture compiler. Its Python child attempted real writes and renames of build inputs. RED exit 1: copied `install.ps1` had both operations succeed (`write: None`, `rename: None`) while compilation was in progress. No canonical file was mutated.

Final race GREEN: the real fixture verifier boundary and fixture compiler boundary both attempt writes/renames of every one of the 19 inputs. Write opens are denied with Python `PermissionError`/errno 13; renames are denied with Win32 sharing violation 32. Every input remains byte-identical, the candidate receipt matches captured fixture source/manifest/builder pins, and write/rename operations succeed afterward. An intermediate test-recording assumption expected `winerror=32` for Python file opens; Python's CRT path maps that denial to errno 13 without a Win32 number, so the test now records and asserts the actual error fields. The initial RED still represents successful mutation rather than an error-reporting artifact.

A separate harness imports and calls the actual copied builder in one live Python process, then immediately writes/renames every input before that process exits. It proves handles release after success, compiler exit 7, missing helper during partial acquisition, and a changed exact license. The missing-helper/changed-license cases refuse before the compiler; compiler-failure evidence includes the actual fixture invocation marker. Existing tests cover changed archive, blocked/unpinned graph, exact notice identity, supplied runtime pins and hashed receipt behavior.

Exact final commands:

```powershell
python -m unittest discover -s .github/tests -p test_inno_build.py -v
python -m unittest discover -s .github/tests -p test_installer_manifest.py -v
git diff --check -- scripts/build-inno.py .github/tests/test_inno_build.py
```

Results: **11 builder tests PASS**, **16 manifest tests PASS**, diff check clean. New tests execute native Windows sharing boundaries, actual first-party verifier logic and actual builder source; only the compiler executable/output is a disposable first-party fixture. No real vendor compiler or payload was executed or acquired. Authorized read-only copies contain only first-party source and exact license texts; mutation targets are entirely within disposable fixtures.

## Frozen SHA-256

- `scripts/build-inno.py`: `15c3e1a455eb3c9e7c2852947da36385a0f63ec09e63a3d48d0bd361d2d05275`.
- `.github/tests/test_inno_build.py`: `47f345b5af3b38509f8c58540b04a22e6c3175b4b753b2b5855851c7d8ba51f0`.

## Limits and source evidence

This qualifies existing-file mutation/rename protection for the enumerated build inputs and correct cleanup. It does not claim a real ISCC compile, signed setup, whole-wizard completion, VM behavior, publication authorization or production route promotion. Compiler support files outside the existing pinned input set and path-ancestor directory replacement are not newly qualified by this work order. Receipt/output ownership and later provenance checks retain their existing contract.

The native sharing and rename semantics follow [Microsoft CreateFileW documentation](https://learn.microsoft.com/en-us/windows/win32/api/fileapi/nf-fileapi-createfilew); explicit pointer/result and last-error handling follow [Python ctypes documentation](https://docs.python.org/3/library/ctypes.html). Actual Windows fixture results above establish the performed sharing behavior.
