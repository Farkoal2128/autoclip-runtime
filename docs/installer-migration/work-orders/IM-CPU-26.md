# IM-CPU-26 — bind the generated fixture duration to owned speech

Status: **additive r2 prepared/frozen; actual r2 media execution unperformed**.

## Authorization and scope

Parent authorized the smallest external fixture fix after the actual IM-CPU-25 VM failure. Owned only new `cpu-installed-media-probe-r2.ps1`, `cpu-installed-media-probe-r2.Tests.ps1` under `D:/AutoClip-Inno-Migration/vm-transfer`, and this report. Original c594 CPU25 probe/tests, all actual failed stage/logs/handles, application/installer sources and other agents' files were preserved. No VM, server, vendor, media/model or uninstall execution was performed here.

Requirement: the generated fixture video must be bounded by its measured owned speech duration, and still satisfy the existing strict audio/duration check. This changes diagnostic input construction only; no production/public contract revision is justified by this failure.

## Actual runtime RED and source mapping

Original native outer PID4712/start `2026-10-02T04:46:16.1128024Z`, original handle3896, terminal exit1. Guest saved-state clock lagged the host; these are observed guest timestamps, with no clock setting or backdating.

Preserved outer full stdout `vm-cpu25-native-probe-stdout.log-eb2a37340c22.log`, 24524 bytes, SHA `eb2a37340c2248ee14a0d63dfd071241c3463681346b60a5f5315f166f2330c9`, contains `FAILED_PRESERVED` for `acm-72c56379d52b4007aefbc8e11e1cc374`. Native speech PID11820 exit0; installed media PID3968 exit1.

Inner envelope 24882 bytes/SHA `d32f7ed2cab2e2a9006652130a48e13689868a4bc0987bc5f5c4c07174950669` was read and selected raw log records independently checked against their declared byte count/SHA and outer primary. `media-stderr.log`, 366 bytes, SHA `aab528c151bd54b9217b5a82cdf3a90f5b5e1d391e8b4414b3b535280f12cb61`, fails at actual smoke.py line28:

```python
info=ffmpeg.probe(source);assert info.has_audio and abs(info.duration_s-speech_duration)<0.6
```

Generation exited0. Full generation stderr4448 bytes/SHA `20049aa27c176a15ceeaa74d3a7b1d1c150b4c7774f087587331fe8045a04525` reports WAV27.01s and video282 frames/28.20s. This is incompatible with the fixture's strict0.6s duration requirement. The fixture used infinite lavfi video plus `-t 60 -shortest`. Actual archived v40 `ffmpeg.probe` was reread in memory: it invokes managed ffprobe, uses `format.duration`, and identifies audio through actual `codec_type == audio`. The failed conjunction's exact values were not logged; root is collecting preserved source ffprobe/WAV metadata before runtime r2. No inference or render had begun; no app/installer defect is established.

## Exact minimum change

The only changed probe line replaces generation arguments:

```python
'-t','60'
```

with:

```python
'-t',format(speech_duration,'.6f')
```

Existing real WAV frame/rate calculation and `15 <= speech_duration <= 60` bound are reused. All other bytes, pins, paths, acquisition, process observation, CPU/int8 APIs, offline environment, native rendering steps and strict `has_audio`/0.6s assertion remain unchanged. No tolerance was weakened. Parent can run the same `-RunSmoke` interface only after its review and exact preserved metadata check.

## Focused construction RED/GREEN

Command:

```powershell
& D:/AutoClip-Inno-Migration/vm-transfer/cpu-installed-media-probe-r2.Tests.ps1
```

Final exit0. The test AST-selects the single actual embedded generation `run` expression and evaluates that expression with a real float speech duration27.01. A recorder captures the constructed arguments; it does not simulate FFmpeg, duration, application, inference or render results. A fixed ffmpeg path stub supplies only the executable-name input.

- Original frozen expression: real first-party child exit1, assertion `(60.0, 27.01)` — expected construction RED.
- Additive r2 expression: requested `-t`27.01, first-party child exit0 — construction GREEN.
- Require the original strict audio/duration assertion unchanged.
- Reused focused boundaries also pass: unsafe path/hash rejection, CreateNew collision, held readlock, immutable source records, readonly default, PowerShell/Python parsing, actual first-party child offline environment/restoration and rejection of its terminal exit7.

These checks prove construction and preparation boundaries. Actual r2 generated media, model inference, render/audio, visual/listening, Setup and uninstall qualification remain unperformed by this agent. No production test was disabled or weakened.

## Frozen handoff

| File | Bytes | SHA-256 |
|---|---:|---|
| `D:/AutoClip-Inno-Migration/vm-transfer/cpu-installed-media-probe-r2.ps1` | 21816 | `8321ac7eab70733b63263c50e2436e4bd2007ba728fd45f33103bca3169ba272` |
| `D:/AutoClip-Inno-Migration/vm-transfer/cpu-installed-media-probe-r2.Tests.ps1` | 5915 | `2b91ce2704148c0f08fafd5309f7ed90b72fa4fc03ed7125894b3b5edaa7e97b` |

The original CPU25 launcher pins the original helper and must not be repointed/overwritten. Root must stage the distinct r2 filename and pin in its separately authorized actual run. Outputs remain a fresh protected external GUID stage. The user's uninstall-after-production-readiness order is preserved.

## Root actual CPU component GREEN

Root re-read focused tests/report and verified exact one-literal source diff,
reran focused checks exit0 (actual original-expression child expectedRED1).
Distinct reviewed launch source3939 bytes/SHA256
`1aacff29b33f39597415e293a5edbf8aa2c09d4de21890270eddf33dbacc3475`
started original8024/handle3640, guest2026-10-02T04:59:52.9797946Z, terminal0.
Ordinary native64 parent6852 retains the original object/input lock. Warm VM
clock still lagged host UTC after saved-state resume; these are guest capture
times. Exact original terminal primary SHA256
`66ce88fbf8273e9d6df0895ffb6269f8e84bff2357407b720e4a389234c9c07e`.
Full stdout27818/SHA256
`c7057795fc587307928e605b758dee3d39aae20ba4f40255a3e4e4722ca05297`,
stderr0/e3b0c4 were independently rehashed; exact log envelope37413/SHA256
`fc2b145359cc439ca000bbb011dc0965fd9165ad4b2c547637b75f88120ef52d`.

Actual fresh stage `C:\Users\autocliplab\AppData\Local\Temp\acm-7e91cabf71f14dfd91c420034a6fd68d`
contains VERIFIED_CPU_MEDIA_COMPONENT: real app prepare, CPU/int8 Whisper
transcription62 words and captioned 8.0-second1080x1920 H264/AAC render. Original
source hash remains unchanged; actual full AV decode exit0/stderr empty and
volume mean-17.8dB/max-1.5dB verify expected non-silent audio in the output.
Actual rendered1475472 bytes/SHA256
`22b3c99f28e758704a89d40adb1c2cb7c133a46c74b197f8df9976f849644443`.
No model, vendor binary/cache or rendered video was mirrored to the host.

Root transported only bounded firstparty evidence/caption PNG. All10 non-self
files independently matched outer result file bytes/hashes. The exact43273-byte
result.json/0651d92433f73285662039101b1ad8f58fb12b1de4c9c664aeec7a494b4d6d4a
structurally equals the recorded outer receipt; app-result443 bytes/SHA256
`46f27b9dbc350a9e82cd92a9283e2a619fd15fef9c170b59c1fb26db9f91f8ed`
equals its app record. Exact component evidence envelope311601 bytes/SHA256
`57b7aeed795ea79f6cc509a8b3644c3101124c2fe2dddb0ea55f4a2c9e6fd97e`.
Caption PNG178411 bytes/SHA256
`4d842cb76b40301228fccc76b28fe73ba08772c087c41091cbd1fdbbd90815dd`
was viewed directly by root: readable INSTALLATION TEST. white/yellow caption
with black outline, inside the portrait frame, no missing glyphs or clipping at
that sampled frame. This is bounded internal visual inspection, not creator
acceptance or review of every frame. Original receipt pending flags are retained;
audio listening, desktop/browser flow, exact wizard, clean-install and uninstall
qualification remain unperformed. This prepared-machine component GREEN is not
approval for an exact setup candidate or an NVIDIA claim.