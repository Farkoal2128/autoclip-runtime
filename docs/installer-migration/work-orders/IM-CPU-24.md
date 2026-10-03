# IM-CPU-24 — prepare an installed ordinary-user CPU media smoke

Status: discovery/preparation complete; **media/transcription/render execution unperformed**. Ownership was this report only. No script/framework, production source, tests, VM/server state or application installation/execution was created/changed. Uninstall remains after production-ready installer qualification, as the user requested.

## Existing installed evidence and exact app basis

Read/rehashed primary `vm-cpu23-completed-primary-fd74bfe29b4c.json`: SHA `fd74bfe29b4cc6eca9bc17cbb3c60e9a811f782da0ac56ffc3186f050c95e69e`, status `VERIFIED_EXISTING_FULL_CPU_OUTPUT`. Actual installed Python/PyAV/CTranslate2 paths are under `C:\Users\autocliplab\AppData\Local\Temp\cpb-a7390ec86449\installed`; CPU types include int8. Media/inference/wizard/uninstall flags are false. Read/rehashed separate installed health primary SHA `a3c3693a9fcfd87d8fc52111c5b4df838408c901525b967f03800bb8cb02883d`: installed Python3.11.9 PID2988 exit0, actual installed app path, health/home200, manifest `7fbf72038be30522bc176002082fddd92fd4e057159765726e77806a296658e2`. These do not establish media/model inference or final Setup qualification.

Read the **actual archived v40 wheel**, in memory without extraction or execution, from `D:\AutoClip-Inno-Migration\autoclip-source-build-v40-provenance-continuity.zip`:

- Archive SHA `f2b3be779294bc55d6f5f56c2a780a2d6b863486f3af9bd7d19f30051961fc9f`, equal to CPU23's archive binding.
- Entry `wheelhouse/autoclip-0.1.0.dev0-py3-none-any.whl`, 1718713 bytes, SHA `ac8deb834a19a27374e63d1ba70b062450b95cd560ba01829fa1766f52618298`.

Actual v40 APIs:

| Installed API | Arguments/behavior to reuse |
|---|---|
| `prepare.extract_audio(source, destination, duration_s=...)` | Real FFmpeg, mono16kHz PCM WAV |
| `WhisperSettings(model=local_directory, compute_type="int8", language="en", diarization=False)` | Local model path is explicitly supported; no provider/key/diarization |
| `transcribe.resolve_compute(settings)` | Require actual result `(cpu, int8)` before decoding; no mocked GPU report |
| `transcribe.transcribe(audio, settings, duration_s=...)` | Real Whisper/CTranslate2 VAD + word timestamps; consume complete transcript |
| `centre_crop(width, height, duration)` | Actual fixed center crop, clip-relative time |
| `export.ExportRequest(source, destination, start_s=0, end_s=8, crop_path=..., words=real_words, style=captions.PRESETS["bold_pop"], ratio="9:16", burn_captions=True)` | Use real transcript words inside the selected span |
| `export.export_clip(request, work_dir=...)` | Actual native H264/AAC/libass render |
| `ffmpeg.probe(path)` | Actual ffprobe dimensions/codecs/duration/audio stream |

Exact archived module SHA-256 values for future installed-file comparisons:

| Module under `autoclip/` | SHA-256 |
|---|---|
| `config.py` | `fa6cde2b7b43fb42cf866265906431179c0276316ab4035a99324b261b5a86df` |
| `pipeline/prepare.py` | `7b91e8a90ebf2039c8dadefd24e63893f8e06b22547db250e1161b4c7adff598` |
| `pipeline/transcribe.py` | `417d7691596255088810ba9da01db26b01d551a5c4420970efbca96560efd198` |
| `pipeline/export.py` | `fd40cfe973a317019c591688e2af4f9dd83851062721cc43c86274c292b38702` |
| `pipeline/ffmpeg.py` | `1b6e3c1adbb548b6bd992ff8164a7198904159d7517164702c30966c661dcedf` |
| `pipeline/reframe/croppath.py` | `9e4a01b12d9320395f95027ae892e28de754cb5f85817ad4d2f687b4de1b2c24` |
| `pipeline/captions.py` | `5275111069e6a176783ad804271e772cb99467a6db4d26f3845bf111d42c5334` |

## Reuse decision

`D:\Projects\myAutoclip\tests\test_pipeline_e2e.py` is the existing real FFmpeg/Whisper/libass test pattern. Its provider answer is scripted; media/transcription/render are real. It hardcodes model `tiny`, expects >50 words and needs pytest. `tests/conftest.py` prepends checkout `src/backend`, so running it unchanged does not prove installed-package origin. No guest pytest availability is established. `autoclip clip` uses the actual configured LLM provider and adds provider/model/key readiness outside this bounded CPU smoke.

Shortest route: a later parent-authorized **single fixed installed-Python diagnostic sequence** invoking the existing APIs above, reusing assertions from `test_pipeline_e2e.py` and `test_export_render.py`. No new framework, pytest installation, provider mock or product feature is needed. This report does not create that sequence. Normal CLI help/doctor can be recorded separately, but cannot replace actual decode/render results.

## Exact model candidate, sources and pins

No model weights, fixed model revision, or approved Hugging Face model acquisition record was found in the migration manifest/work orders. The licensed Hugging Face client wheel is not a model rights/pin record. The following is **new diagnostic candidate evidence**, not a previously qualified model or production acquisition promotion.

Candidate: `Systran/faster-whisper-tiny.en`, immutable commit `0d3d19a32d3338f10357c0889762bd8d64bbdeba`. Its official [model card](https://huggingface.co/Systran/faster-whisper-tiny.en) identifies the English CTranslate2 conversion and MIT license; the [commit page](https://huggingface.co/Systran/faster-whisper-tiny.en/commit/0d3d19a32d3338f10357c0889762bd8d64bbdeba) supplies the immutable revision. Retain pinned README plus applicable upstream [OpenAI MIT notice](https://github.com/openai/whisper/blob/main/LICENSE); the MIT notice text still needs a frozen capture/pin for any recipient notice record. No extra voice/model terms were accepted by the agent.

Recipient URL prefix (append only each fixed filename):

`https://huggingface.co/Systran/faster-whisper-tiny.en/resolve/0d3d19a32d3338f10357c0889762bd8d64bbdeba/`

| File | Exact bytes | SHA-256 | Evidence |
|---|---:|---|---|
| `model.bin` | 75537502 | `1a5afae06a4db91c975c9a9d78be5cc110ee4ea022ad57d55492e4550e936b2a` | Pinned URL HEAD X-Linked-Size/X-Linked-ETag; no weight body fetched |
| `config.json` | 2317 | `14b1b421a90349bc551b881461426b561a874049cb9e4c4864f2ca384f6a7cc5` | Exact raw response bytes hashed in memory |
| `tokenizer.json` | 2128466 | `929c5252409436dce1b38a75d1abbcb5e132d170d8e324e4e04ed915fa2d22df` | Exact raw response bytes hashed in memory |
| `vocabulary.txt` | 422309 | `ff77588746d3a2595d32ab5b69ffd7b95ce2441ac57533cb66fc3eb575a115cf` | Exact raw response bytes hashed in memory |
| `README.md` | 1323 | `1b7816626bf0548e4b71a467f4112b4592924bc818e3117f19aefcc50ce4b6aa` | Pinned licensing/source card, raw bytes hashed |

The four runtime files total78090594 bytes. Parent explicitly permitted small source metadata retrieval after initial discovery; only those four small text files were GET-read in host memory, with no disk artifact written. No host weights/native binary/app acquisition occurred. The weight HEAD had redirects disabled, status302, and next host `us.aws.cdn.hf.co`; **the full weight redirect chain and actual recipient transfer remain unobserved**. Small-file final response URIs were Hugging Face `/api/resolve-cache/models/.../<commit>/<filename>` with Git ETags; file SHA-256 values above were computed independently from raw byte streams, not inferred from those Git ETags.

Use a new separate diagnostic acquisition record/receipt through the existing approved acquisition discipline. Do not change the installed manifest, MSYS receipt basis or completed stage to add this model. Exact model files must be downloaded directly by the ordinary recipient, size/hash-verified before use, and retained outside managed application cleanup in this fresh diagnostic stage. Avoid model aliases/default `main`; set offline flags for inference with the complete local directory so missing tokenizer/model files fail instead of fetching another artifact.

## First-party media creation and planned native commands

All output belongs in one fresh protected diagnostic TEMP root; preserve original installed files and user homes. First check availability of an already installed English native `System.Speech`/SAPI voice. Record its exact name/culture and ordinary-user identity. Do not install a voice or use a hosted TTS service. If unavailable, the exact missing input is a short first-party/right-cleared English speech WAV/video plus creator/source record.

First-party fixture text, for ordinary diagnostic use only:

> This is an AutoClip installation test. We are checking clear speech, accurate timing, visible captions, and working audio. The blue bicycle stands beside an orange garden gate. A small river flows beyond the trees. This short video should render on the computer using the CPU. The final clip should keep the spoken words and show readable captions without changing the original recording.

Use the native voice synchronously to produce `speech.wav` with recorded voice/rate/volume and no overwrite. Verify speech duration is between15 and60 seconds before building video. Synthetic FFmpeg test frames need no third-party footage or music. The app's external FFmpeg must be the managed Gyan9.0.1 binary, not the codec-free native build DLL or a random host executable:

- Bin: `<InstallRoot>\tools\ffmpeg\ffmpeg-9.0.1-essentials_build\bin`.
- `ffmpeg.exe` SHA `72a489eccd008c2ec2c0a5856c5c75bc3d8bbfa90166c4566865c246445e6aa3`.
- `ffprobe.exe` SHA `19202b23c0043f15ad1b7bce2344f406fd52bd6efd8f995ce02e7392a1cec52f`.
- Their existing ZIP pin is `fec81ae03971d9dd4be3ebe02e263bd2ec1d789483f931bdba5f5715e65da2e9`.

Planned FFmpeg argument arrays, executed only after parent assignment, with fixed verified executable paths and stage-local paths:

```text
-nostdin -n -f lavfi -i testsrc2=size=640x360:rate=10 -i <stage>/speech.wav -map 0:v:0 -map 1:a:0 -c:v libx264 -preset ultrafast -pix_fmt yuv420p -c:a aac -t 60 -shortest <stage>/source.mp4
-v error -i <stage>/rendered.mp4 -map 0:v:0 -map 0:a:0 -f null -
-hide_banner -nostdin -i <stage>/rendered.mp4 -vn -af volumedetect -f null -
```

Use exact installed `<InstallRoot>\.venv\Scripts\python.exe -I -B` for the fixed API sequence. Set child-only `AUTOCLIP_HOME` and `AUTOCLIP_STORAGE_HOME` to separate fresh stage paths, clear PYTHONPATH/PYTHONHOME and user-site influence, set HF_HUB_OFFLINE/TRANSFORMERS_OFFLINE for local inference, and restore caller environment. Record actual `ffmpeg.ffmpeg_path()` / `ffprobe_path()` and installed module paths/hashes. Reuse current .pth registration; do not mutate global PATH, existing config, registry or normal user data.

## Evidence required for the eventual smoke

1. Revalidate/readlock exact installed marker/manifest/native receipt plus module/tool/model inputs; actual unelevated native64 recipient identity and Python3.11.9. Existing CPU stage proof does not substitute for current paths/pins.
2. Generated speech/source SHA/length/voice/text provenance and input hashes unchanged after render. Source has real video/audio, finite duration and decodable PCM.
3. Actual app compute resolves cpu/int8; local pinned model loaded; complete lazy decode consumed. Transcript has >20 nonempty timed words, nondecreasing finite starts, ends>=starts, times within source tolerance and recognizable expected fixture content. Preserve actual transcript/status logs. Do not mock any decoder.
4. Render actual first8 seconds using the transcript words in that span, real center crop and bold_pop burned captions. Require caption ASS nonempty plus a readable rendered-frame inspection; file/stream metadata alone does not prove visible captions.
5. Nonempty regular MP4, full native decode exit0, expected9:16 dimensions, H264 video/audio stream, duration approximately8 seconds (existing E2E tolerance0.6s). Preserve ffprobe JSON, decode and volumedetect logs; finite audio levels rather than silent `-inf`. Stream presence alone is insufficient audio evidence. Playback/listening or retranscribing the rendered audio can further establish intelligibility; do not claim that from RMS alone.
6. Exact child PID/start/exit, all stdout/stderr, elapsed time, output SHA/length and a small primary receipt. Observation timeout preserves live processes and logs; no unattended retries, killing or cleanup. This is an installed CPU media component smoke, not full desktop/LLM/media-judgment/wizard acceptance. A final wizard-installed root needs its own acceptance after integration.

## Remaining concrete inputs

- Parent-authorized one minimal fixed installed-runtime smoke sequence and recipient acquisition record; neither exists yet in this assignment.
- Recipient-side complete weight redirect/HTTPS route and downloaded-file receipts; first redirect only is observed. No model file is proven present in the VM.
- Frozen upstream MIT notice capture/pin for the diagnostic record; official license/model card metadata is identified, not a preexisting release-rights record.
- Actual installed English voice availability (or first-party licensed speech media) and fresh recipient stage identity.
- Full ordinary desktop/provider workflow and final installer qualification remain separate. **Do not run uninstall until the installer is production-ready**, following the user's sequencing.

No runtime tests, model inference, application/media execution, VM/server mutation, uninstall or code edits were performed for this report. Small approved metadata reads and archived first-party source inspection are discovery evidence only.
