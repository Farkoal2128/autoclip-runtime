# IM-CPU-23 — validate completed CPU stage without rebuilding

Status: new read-only validation probe and tests frozen; root-only guest
execution pending. No source/installer, old probe/test, server, stage, receipt,
archive, vendor asset or VM state was changed by this work order.

## Failure reconciliation and scope

The preserved original CPU21 terminal primary is 8,001 bytes, SHA-256
`e04b342cd15c52d612676dc1b2d6cbae257372761624bd0de9d01f976d067347`.
The agent independently rehashed/inspected this transported primary. It
records actual source child PID 1548, terminal exit 0, followed by a diagnostic
`FAILED_PRESERVED` in installed-result validation. The diagnostic looked for
the generated PyAV wheel under `ExternalCache/publisher-wheels/cpu`.

The actual source caller assigns its wheelhouse under
`InstallRoot/publisher-wheels/cpu`. The frozen r3 diagnostic, its failure,
and completed stage `C:\Users\autocliplab\AppData\Local\Temp\cpb-a7390ec86449`
remain unchanged. No complete installer/build retry is justified by that
observation. This new probe validates the existing outputs at their actual
producer location and collects complete logs. It does not qualify final Inno,
health, normal desktop/media/model inference, uninstall or release.

## Fixed operation and held input pins

Default invocation returns `READ_ONLY_PLAN`; it performs no stage access,
imports, network calls or build. Explicit `-ValidateCompletedStage` requires
ordinary unelevated native64 `autocliplab`, the fixed completed stage and its
recipient-owned protected DACL. It accepts only a local path to the original
terminal primary, whose complete 8,001-byte hash is fixed in the probe.

The original primary must bind the exact root, SID, PID 1548, integer exit 0
and `live:false`. A current CIM observation rejects a matching original
process still live; PID reuse is recorded separately. The original primary's
eleven pinned controls/archives are independently size/hash checked and
read-locked, with no reparse or foreign-write path. These include exact v40
ZIP, frozen CPU20 bootstrap, latest downloader, extraction/runtime/Python
helpers, canonical/final diagnostic manifests, and uv/MinGit/FFmpeg archives.

The probe then independently requires:

- Existing 64-byte completion marker equal to exact v40 archive SHA.
- Exact installed release manifest, publisher manifest and immutable recipe
  pins; the final CPU diagnostic manifest remains `92fcd18...`.
- CPU-only native receipt with pinned FFmpeg/PyAV source hashes and oneDNN/
  CTranslate2 commits, exactly eight unique allowed installed DLL paths and
  exactly one wheel for each PyAV 18.1.0/CTranslate2 4.8.2 family.
- All eight actual DLL hashes/lengths and both actual wheel hashes/lengths
  from `installed/publisher-wheels/cpu`; no old-root fallback or cache substitution.
- Actual `native/ffmpeg-config.mak` hash equal to the produced native receipt.
- Valid PSF-signed fixed installed `.venv/Scripts/python.exe`, followed by a
  fixed isolated `-I -B` native import checking actual CPython 3.11.9/x64,
  PyAV 18.1.0, CTranslate2 4.8.2, expected installed module/interpreter paths
  and available CPU `int8`. No model or GPU inference is requested.

All input/output/log readlocks deny write/delete sharing and remain open
through receipt/transport. The probe has no explicit file-write, extraction,
source/build, cleanup, retry, installed-helper mutation or environment-change
operation. The native import is an explicit root-owned guest test; it was not
executed by this agent. Existing source-build wheel RECORD/dependency checks
are preserved at their original producer scope; this probe does not relabel
them as newly executed independent checks.

## Complete log transport

The completed stdout and stderr lengths must remain exactly 965,847 and
14,498 bytes. Each source file is opened read-only, full SHA-256 computed,
then split as binary bytes into 131,072-byte chunks (eight stdout chunks and
one stderr chunk). Base64 preserves arbitrary byte/line boundaries. No text
decoder or bounded tail substitutes for full data.

The existing server endpoints overwrite one file per POST and therefore
cannot preserve a multi-chunk stream. The root separately authorized/owns
new `/cpu-log-chunk` handling; this agent did not edit or execute the server.
With `-PostLogs`, each JSON POST includes exactly these fields:

```text
schema_version: 1
run: cpu21-cpb-a7390ec86449
name: production-stdout.log OR production-stderr.log
offset, length, total_bytes
source_sha256, chunk_sha256, data_base64
```

Each encoded payload is below 1,000,000 bytes. The root receiver must validate
known run/name/total, aligned offsets and expected final length, Base64 bytes
and chunk digest; persist immutable chunks and reject conflicting repetitions.
An identical already-stored chunk may be acknowledged. The probe has no
automatic retry. A failed POST fails this validation attempt and preserves
all original guest files. Root reassembly must independently verify no gaps,
total byte count and full source SHA against the resulting primary receipt.

The final primary records full source log bytes/hash and every chunk offset,
length/hash/transport state, without repeating Base64 data. `-PostResult`
sends that bounded first-party primary to existing `/python-wizard`, including
failure where context was verified. Preserve its previous host file first.
Failed ordinary-context checks cannot trigger a POST. Parent staging uses
raw bytes/OutFile; no HTTP Content-to-string conversion is used in this probe.

## Exact parent interface

The root serves the preserved first-party terminal bytes as
`cpu21-terminal-primary-e04b342cd15c.json`; after downloading it byte-exact and
staging the hash-verified new probe, the root alone may invoke:

```powershell
powershell -NoProfile -File <verified-cpu-completed-stage-probe.ps1> -ValidateCompletedStage -PostLogs -PostResult -TerminalReceiptPath <verified-local-8001-byte-original-primary.json>
```

Success status is `VERIFIED_EXISTING_FULL_CPU_OUTPUT`, distinct from the
unchanged original diagnostic failure. It records original exit 0 and current
observations, exact files/recipe/source/native receipt/configuration/wheels/DLLs,
actual isolated CPU import and complete log transport. No source installer is
called again. Actual installed health is intentionally a separate root-owned
IM-CPU-22 invocation. Uninstall remains after production-ready installer
qualification, as requested by the user.

## RED/GREEN and frozen artifacts

```powershell
powershell -NoProfile -File D:/AutoClip-Inno-Migration/vm-transfer/cpu-completed-stage-probe.tests.ps1
```

Meaningful RED evaluates the actual frozen r3 `$nativeWheelhouse` assignment
AST with first-party install/cache roots: it selects ExternalCache and exits
1 with `RED: frozen diagnostic selected ExternalCache; production wheel root
is InstallRoot`. After implementing the new probe, GREEN exits 0 against an
actual first-party fixture file in the correct installed wheelhouse. It checks
correct root, wrong-root absence, size/hash tampering and real write-denying
readlocks. A 965,847-byte binary fixture is encoded into eight bounded chunks,
each independently hashed, ordered and decoded; reconstructed total/full SHA
must exactly match the original. Default invocation is nonoperational and the
AST parser passes. No vendor/VM/network/build operation produced these results.

| Artifact | Bytes | SHA-256 |
| --- | ---: | --- |
| `D:/AutoClip-Inno-Migration/vm-transfer/cpu-completed-stage-probe.ps1` | 13932 | `1f6b496f705501c98e6a9be3d6c64a7334af176eb5da43a2558740c8ec7f6cfa` |
| `D:/AutoClip-Inno-Migration/vm-transfer/cpu-completed-stage-probe.tests.ps1` | 3987 | `614dfd7e1e39adf28381bb838dfed6042d55126c9ff1bbee4c1a9817b60769cf` |

Probe and tests are frozen for parent review/execution. The agent edited only
these two new files and this new work-order report. Guest execution, full
returned primary/chunk verification and all broader acceptance gates remain
pending at this report snapshot.

## Separate installed health evidence received before handoff

The parent subsequently completed the actual IM-CPU-22 public helper on this
same existing installed root. This agent independently rehashed/inspected the
transported 2,967-byte primary
`vm-cpu21-installed-health-primary-a3c3693a9fcf.json`, full SHA-256
`a3c3693a9fcfd87d8fc52111c5b4df838408c901525b967f03800bb8cb02883d`.
Its wrapper records `VERIFIED_INSTALLED_HEALTH_HOME`, exact helper `9f5656...`,
release manifest `7fbf7203...`, actual signed installed Python 3.11.9 child
PID 2988 exit 0, installed `autoclip/app.py`, health/home HTTP 200 and an
isolated fresh health home. This is primary evidence inspection, not this
agent's independent guest execution.

The health result remains a separate operation: this new CPU23 probe still
records `health_tested:false` because it does not perform that test. No
desktop/media/model/uninstall/wizard or release gate is implied. The root
reported starting the hash-verified CPU23 probe; its returned primary/log
chunks were still pending when this report was finalized.
