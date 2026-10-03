# IM-CPU-25 — prepare the fixed installed CPU media probe

Status: **prepared and frozen for parent review; installed media/model execution unperformed**.

## Authorization and ownership

Parent authorized one external fixed diagnostic following IM-CPU-24. Owned only `D:/AutoClip-Inno-Migration/vm-transfer/cpu-installed-media-probe.ps1`, its focused `.Tests.ps1`, and this report. No application/runtime/installer source, contract, prior packet, server, VM, installed files or uninstall state changed. The user requires uninstall testing after production-ready installer qualification; this work does not perform uninstall.

Expected behavior: obtain exact model inputs directly on the ordinary recipient, generate owned speech/video, and exercise the actual installed CPU/int8 transcription, captions, render and decode APIs. Outputs stay in a fresh protected external TEMP stage. Default invocation performs no application execution or acquisition. This diagnostic does not add a production interface or change a public contract.

## Frozen handoff

| File | Bytes | SHA-256 |
|---|---:|---|
| `D:/AutoClip-Inno-Migration/vm-transfer/cpu-installed-media-probe.ps1` | 21791 | `c5940264397fc1ea3cea4cd8dfcf55d23148d0db42f6ea1b8d82081ef4e63ada` |
| `D:/AutoClip-Inno-Migration/vm-transfer/cpu-installed-media-probe.Tests.ps1` | 4118 | `86833b7506dfcc8d2cf9cb83aacf9b2fdc97d6c66477b17bd07ed0e233851904` |

Root must transfer/hash-verify the frozen first-party probe and explicitly review before execution. No server addition is needed: root can transport the complete fresh-stage files using its existing evidence workflow. The test script is host preparation evidence and is not required in the guest.

Readonly inspection:

```powershell
& .\cpu-installed-media-probe.ps1
```

Later **parent-only** operational invocation, under native64 Windows PowerShell as unelevated `autocliplab`:

```powershell
& .\cpu-installed-media-probe.ps1 -RunSmoke
```

There are no configurable application paths, executable paths, model URLs, provider inputs, arbitrary code or retry modes. The fixed existing basis is `C:\Users\autocliplab\AppData\Local\Temp\cpb-a7390ec86449`; the installation is its `installed` child. Each run creates a new protected `C:\Users\autocliplab\AppData\Local\Temp\acm-<guid>` stage. No existing output may be overwritten.

## Existing-stage bindings

IM-CPU-23 primary `fd74bfe29b4cc6eca9bc17cbb3c60e9a811f782da0ac56ffc3186f050c95e69e` proves the original full CPU output; separate installed health primary `a3c3693a9fcfd87d8fc52111c5b4df838408c901525b967f03800bb8cb02883d` proves isolated health/home. These are prior component evidence, not this media run.

Before acquisition/children, the probe checks current recipient ownership, allowed write authorities, protected basis, regular/nonreparse paths and held readlocks on:

- v40 archive `f2b3be779294bc55d6f5f56c2a780a2d6b863486f3af9bd7d19f30051961fc9f`, 173196134 bytes;
- release manifest `7fbf72038be30522bc176002082fddd92fd4e057159765726e77806a296658e2`, 277085 bytes;
- CPU native receipt `0c52317be6492339a697eea36d8df26b0ad4ea7e9e3bad3a87208dd2ae4c4599`, 6446 bytes, exact two wheels/eight DLLs and no NVIDIA;
- actual `installed/publisher-wheels/cpu` files and all installed `.pyd` entries compared to those locked exact wheels;
- actual `.install-complete` marker, exact 64-byte v40 archive hash;
- installed PSF-signed Python executable `21bb438c0d4a6f1f164b9a646f6ee000340185e5871180aec06db8d3f07c0082` and exact isolated `pyvenv.cfg` `b495c478f3dbc4eb4915823205475b12a02c976e389984105f592c9649ff2a4e`;
- seven archived app modules recorded in IM-CPU-24, plus `pipeline/transcript.py` `1bbd67acddd52eb676ab0d7b4bfbf7e239c6679565626a05ddaaeb9b4742b9fc` (8117 bytes), read from the actual archived wheel in memory during this preparation;
- managed Gyan FFmpeg/ffprobe pins already established in IM-CPU-24 and the exact production-generated `autoclip_ffmpeg_path.pth` bytes for this fixed root;
- original basis downloader `75ac92e4108a6fd3165617b2c94be02b44ca86c61a5397672d898eaa38635ad6`, 19545 bytes.

The script reuses that downloader's actual `Get-InstallerArtifact`. Its response function is wrapped only to record the actual hop's path/status/Location host; URI signed queries are excluded. The original production response implementation and allowlist validation remain active. The separate held diagnostic `model-inputs.json` does not change an installed/canonical manifest. The downloader retains its existing internal failed-partial cleanup behavior; the probe itself deletes no evidence, model, app, output or user files.

## Model and source notice records

Direct-recipient model URLs are `https://huggingface.co/Systran/faster-whisper-tiny.en/resolve/0d3d19a32d3338f10357c0889762bd8d64bbdeba/<file>`.

| File | Bytes | SHA-256 |
|---|---:|---|
| `model.bin` | 75537502 | `1a5afae06a4db91c975c9a9d78be5cc110ee4ea022ad57d55492e4550e936b2a` |
| `config.json` | 2317 | `14b1b421a90349bc551b881461426b561a874049cb9e4c4864f2ca384f6a7cc5` |
| `tokenizer.json` | 2128466 | `929c5252409436dce1b38a75d1abbcb5e132d170d8e324e4e04ed915fa2d22df` |
| `vocabulary.txt` | 422309 | `ff77588746d3a2595d32ab5b69ffd7b95ce2441ac57533cb66fc3eb575a115cf` |
| `README.md` | 1323 | `1b7816626bf0548e4b71a467f4112b4592924bc818e3117f19aefcc50ce4b6aa` |

Only established official hosts `huggingface.co` and `us.aws.cdn.hf.co` are permitted for these records. IM-CPU-24 observed the pinned weight HEAD's first official redirect; the full recipient weight redirect chain remains unobserved. An additional host fails closed and requires parent review; no speculative host is preauthorized.

Source notice: [OpenAI Whisper versioned MIT license](https://raw.githubusercontent.com/openai/whisper/6e3be77e1a105e59086e3e21ff5f609fd6fa89a5/LICENSE), 1063 bytes, SHA `b5d65a59060e68c4ff940e1eddfa6f94b2d68fdf58ed7f4dd57721c997e35e9d`. Parent-authorized small source metadata GET was byte-hashed in memory during preparation; no weights or native binaries were acquired on the host. The recipient saves this as `model/WHISPER-MIT-LICENSE.txt`, allowed host only `raw.githubusercontent.com`. This retains copyright/model source evidence; it neither accepts vendor agreements nor establishes native model qualification.

## Actual runtime sequence prepared

1. Native hidden Windows PowerShell uses existing `System.Speech` English voice only, records voice identity, and speaks the first-party text from IM-CPU-24 to fresh `speech.wav`. No voice installation or network is provided; no English voice fails with preserved logs.
2. Installed Python runs fixed source with `-I -B`. Actual CPython3.11.9/native64/venv/module origins and exact managed tools must match. Child-only `AUTOCLIP_HOME`, storage and HF cache point to this fresh stage; HF/Transformers offline flags are 1, Python path/home injection cleared, user site disabled. Caller environment is restored immediately after spawn.
3. Pinned FFmpeg generates bounded test-pattern H264/AAC video from owned speech. Actual app `prepare.extract_audio`, `WhisperSettings` local model, `resolve_compute == (cpu,int8)` and `transcribe.transcribe` decode real timed speech. Require >20 finite chronological words and at least three fixture anchors.
4. Actual `ExportRequest`, `centre_crop`, `bold_pop`, `export_clip` burn real transcript captions into an eight-second 9:16 H264/AAC MP4. Require actual ASS captions, regular nonempty MP4, dimensions/duration/audio, full native AV decode, non-silent volume, and a retained caption frame. Source hash must remain unchanged.

Original native process handle/start/PID, arguments and full stdout/stderr are retained per speech/media phase. Even an observation/evidence error waits for that same child to terminate before releasing held inputs; no kill, retry or timeout is provided. Parent can poll `*-process.json` and growing logs. Exact exit0 and successful app-result binding are necessary before `VERIFIED_CPU_MEDIA_COMPONENT`. Failed outputs/logs survive. Final `result.json` lists all fresh files' byte counts/SHA values.

This does not claim selected-provider/highlight selection, desktop/browser workflow, visual caption acceptance, listening acceptance, NVIDIA, final installer wizard or uninstall. Successful component output still flags caption visual review pending and audio listening unperformed.

## Verification performed

Requirement/contract basis and existing actual app APIs were inspected before the external implementation. The first focused test run, before creating the probe, failed exit1: `RED: installed-media input boundary is absent.` This is preparation/input-boundary RED, not inference RED.

Focused command, final exit0:

```powershell
& D:/AutoClip-Inno-Migration/vm-transfer/cpu-installed-media-probe.Tests.ps1
```

GREEN proves real unsafe path rejection, CreateNew collision refusal, exact hash/size refusal, held readlock preventing overwrite, fixed immutable model records, actual PowerShell parsing, readonly default, embedded Python AST parsing, and a real normal-host first-party Python child receiving the offline environment. That child exits7; the probe rejects it, records the original terminal exit, and restores the caller's sentinel environment. No behavior under test is replaced by a mock. An initial parser-command quoting mistake was corrected in the test invocation; the fixed embedded Python AST itself parsed successfully.

**Unperformed:** production downloader execution, model weight acquisition, installed app import/inference/media/TTS/FFmpeg execution, VM actions, server mutation, Setup, uninstall, publication. The focused script retains its fresh first-party TEMP fixtures; no cleanup was performed. Parent runtime review/execution is the next step.

## Root actual recipient execution and failure

Root resumed saved warm CPU VM3408a555-dd0f-458c-aa4e-e22589ed9869 after saving
cold engine VM with VS42 pending native state intact. Ordinary native64 console
6852 launched original4712/handle3896, guest start2026-10-02T04:46:16.1128024Z,
terminal1. Guest clock on resume lagged host UTC about7h; no clock backdating,
trust setting change or bypass occurred. Capture times are the guest's observed
values, not claimed host-current UTC. No exact Setup/uninstaller execution.

Original terminal primary `D:/AutoClip-Inno-Migration/vm-cpu25-native-terminal-4063d3934dac.json`,
SHA256 `4063d3934dacf84db5e9c7afef87b177de48770256e0985fd27a70577e90bc9b`,
binds stdout24524/SHA256 `eb2a37340c2248ee14a0d63dfd071241c3463681346b60a5f5315f166f2330c9`
and stderr523/SHA256 `c2f11b98131394c81e610e94553c565d1313cc55db7d5eb78316b77d49f1426e`.
Full retained log envelope33723/SHA256
`895c1ea69b4209d8ffeb90fea67578f6986ed5e2fc44687a31675ee35c3a1d21`
was independently decoded/rehashed against original terminal metadata. Initial
observer deep-serialized Get-Content strings and produced2249732 characters,
exceeding transfer bound; request400, no lost guest logs. Small native-read-based
records succeeded. Avoid Get-Content values in deep JSON metadata transport.

Actual model acquisition/input checks and speech11820 exit0 succeeded. Media
3968 exit1 failed before prepare/transcribe at generated source duration check.
Inner10 log files were individually decoded/rehashed against actual outer
receipt.files. Envelope24882/SHA256
`d32f7ed2cab2e2a9006652130a48e13689868a4bc0987bc5f5c4c07174950669`.
Exact media stderr366/SHA256
`aab528c151bd54b9217b5a82cdf3a90f5b5e1d391e8b4414b3b535280f12cb61`
records unchanged audio/0.6s duration assertion at smoke.py28. Generation exit0
log4448/20049aa27c176a15ceeaa74d3a7b1d1c150b4c7774f087587331fe8045a04525
shows WAV27.01s and video282frames/28.2s from infinite lavfi with -t60/-shortest.

Root independently pinned/probed preserved source using native FFprobe1104,
originalhandle1876, guest04:58:03.1749473Z/exit0. Exact source3275413/SHA256
`7eb7f60690a8ee20b2e3fd569c7f6feed100cc4ceeef81f6c0517936466f10ab`;
actual AAC audio27.005079s and H264/container28.2s confirm audio exists and
fixture duration is the failing conjunct. Primary
`vm-cpu25-source-probe-primary-d531ee1c3dea.json`, SHA256
`d531ee1c3dea7db32df428f7b07b101d55f1469165c0e60121fb8cbc6088c478`.
No inference/render/installation pass is established by this failure. Separate
IM-CPU-26 minimum fixture correction retains old source and strict assertions.