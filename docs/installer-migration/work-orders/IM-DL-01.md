# IM-DL-01: recipient artifact downloader

Authorization: parent work order IM-DL-01 explicitly authorizes implementation
of the bounded downloader for the Inno migration. Owned files:
`installer/download-artifact.ps1`, `tests/InstallerDownload.Tests.ps1`, and this
report. No manifest, Inno, installation, publication, or commit authorization
was used.

Requirement: `contract-v1.md`, Inputs and dependency policy and installation
state-machine steps 3 and 6. Classification: installer/updater. The manifest
remains the exact identity/policy source. No historical runtime identity or
active-installation boundary changes.

Interface: execute the absolute `installer/download-artifact.ps1` script with
`-ManifestPath`, `-Identity`, and `-DestinationPath`, or dot source it and call
`Get-InstallerArtifact -ManifestPath <path> -Identity <identity> -DestinationPath
<absolute TEMP file>`. Identity resolves exactly one `target_release.id` or
`build_prerequisites.identity`. Only `DIRECT_RECIPIENT_DOWNLOAD` is allowed.
The manifest entry must provide a nonempty `redirect_hosts` array of exact DNS
hosts including the origin; there is no wildcard or implicit origin exception.
Missing host policy fails before networking. Parent owns adding reviewed host
policies to the repository manifest.

Implementation uses .NET HttpClient on Windows PowerShell 5.1, manual redirect
validation with a five-hop limit, HTTPS port 443 only, no URL credentials or
fragments, default certificate validation, no cookies/default credentials,
new randomly named TEMP staging, path traversal/reparse-point rejection,
streamed exact size bounds, SHA-256 verification, and a file move that cannot
overwrite a destination. A matching existing regular file can be reused;
corrupt existing bytes fail intact and require an explicit fresh destination.
Failure removes this invocation's partial file and empty staging directory.

## Evidence

- RED, before production helper existed:
  `powershell -NoProfile -ExecutionPolicy Bypass -File tests/InstallerDownload.Tests.ps1`
  exited 1 with `RED: recipient download helper is missing.` This is the
  missing-feature RED baseline; it is not evidence of a behavior regression
  in a pre-existing implementation.
- GREEN:
  `powershell -NoProfile -ExecutionPolicy Bypass -File tests/InstallerDownload.Tests.ps1`
  exited 0. Behavioral tests invoke the production helper with test-scope
  response mocks and verify rejected redirects cause no destination request,
  allowed redirects, redirect cap, BLOCKED policy, size/hash mismatch, failed
  HTTP request followed by retry, valid cache reuse, corrupt cache preserved,
  absent redirect policy, traversal/reparse rejection, and target-release lookup.
  A separate PowerShell process also verifies the script entrypoint against a
  pinned cached artifact without any transport mock or production bypass.
- GREEN, official network route:
  `powershell -NoProfile -ExecutionPolicy Bypass -File tests/InstallerDownload.Tests.ps1 -RealDownloads`
  exited 0. The real production transport downloaded uv 0.12.19 and MinGit
  2.55.0.3 directly from their pinned official GitHub URLs through
  `release-assets.githubusercontent.com`.
  uv: 17955780 bytes,
  SHA-256 `6dbb02d79e419522f1c500f0adb1cddcff0cda7d59b0d66ea7f5e3b4a1b2f5f0`.
  MinGit: 38791206 bytes,
  SHA-256 `f48e2d2dc74a24454adc6d8fd0ac25bf9c2386f19cfb06202b9465aaad4f9f05`.
  These runs temporarily changed classification and host policy only in a
  test-owned TEMP manifest. Repository manifest entries remain BLOCKED.
- `git diff --check` produced no whitespace errors; its CRLF warnings were
  for other writers' existing files. The owned files are newly added files.

Primary API references inspected:
[HttpClientHandler.AllowAutoRedirect](https://learn.microsoft.com/dotnet/api/system.net.http.httpclienthandler.allowautoredirect),
[HttpClient.SendAsync](https://learn.microsoft.com/dotnet/api/system.net.http.httpclient.sendasync),
[HttpCompletionOption](https://learn.microsoft.com/dotnet/api/system.net.http.httpcompletionoption).

Limits: local developer-machine download evidence only. No clean-machine,
Inno integration, certificate-negative endpoint, vendor execution, GPU,
installed-release, human/legal review, or publication verification performed.
This helper verifies downloaded archive bytes; signature/publisher and extracted
capability checks remain the integration's responsibility before execution.
Header requests time out after five minutes. Body reads use .NET `ReadAsync`
and a finite 30-second `Task.Wait` for every read, cancelling the pending read
and disposing the stream on timeout even when `CanTimeout` is false. The
30-second bound is an inactivity bound, not a total-transfer deadline.

## Parent-requested follow-up

Parent explicitly requested an absolute destination requirement and bounded
body reads. Behavioral RED used the same focused test command and exited 1:
the relative TEMP destination was acquired instead of rejected before a
request, and a test-only non-timeout stream reached synchronous `Read` instead
of a bounded asynchronous wait/cancellation. The regression fixture returns
a never-completing real `Task<int>` from `ReadAsync`, observes cancellation,
and requires timeout within 45 seconds, no destination publication, and no
new staging directory left behind. It does not shorten the production timeout
or add a production bypass.

Follow-up GREEN:
`powershell -NoProfile -ExecutionPolicy Bypass -File tests/InstallerDownload.Tests.ps1 -RealDownloads`
exited 0 after the fixes. The new regressions and all prior behavioral cases
passed, and actual official uv/MinGit downloads again matched the exact sizes
and SHA-256 values recorded above. Scoped `git diff --check` also exited 0.

Additional primary API references inspected:
[Stream.ReadAsync](https://learn.microsoft.com/dotnet/api/system.io.stream.readasync)
and [Task.Wait](https://learn.microsoft.com/dotnet/api/system.threading.tasks.task.wait).

## IM-INNO-DL-02 cooperative cancellation extension

The parent explicitly expanded ownership to allow a validated optional
`-CancelPath` for Inno integration. This is an absolute regular signal-file
path under TEMP with traversal, alternate-stream, collision and reparse
rejection. It is a recipient cancellation channel, not a transport bypass.
Header and body waits poll the signal every 100 milliseconds; on signal they
cancel the pending .NET task, dispose the transport and remove owned staging.
The five-minute header and 30-second body inactivity limits remain in effect.

RED: the focused test command exited 1 because the pre-extension helper did
not accept `CancelPath`. Tests use actual pending `Task<int>` fixtures and a
separate .NET timed signal writer. GREEN: the full focused test command with
`-RealDownloads` exited 0, including header/body cancellation within five
seconds, existing timeout/path/cache/redirect cases, and the exact official
uv/MinGit size/hash downloads. No production timeout was shortened by tests.
Inno integration and exact executable evidence are recorded in IM-INNO-DL-02.
