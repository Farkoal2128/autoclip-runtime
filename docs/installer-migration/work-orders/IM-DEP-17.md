# IM-DEP-17: inspect actual VC elevation cancellation

Date: 2026-10-02. Parent objective: complete the authorized CPU installer and
subsequent generated-uninstaller qualification. Root owns VM and integration.

Read-only assignment to `consumer_successor_packager` (implementer): inspect
`installer/install-vc-runtime.ps1` and its existing focused tests to determine
whether the real `Start-Process -Verb RunAs` exception wraps Win32 error 1223,
preventing the typed cancellation catch from recording terminal cancellation.
Report the smallest meaningful failing test and correction before editing.
No vendor, security-prompt, VM or release actions. No unrelated edits. Actual
per-run model telemetry is not exposed. This investigation can run independently
of root's preserved VM evidence and user handoff.

Actual clean r4 stopped with a 665-byte stderr, read in guest Notepad:
`Protected VC preparation failed: unresolved; This command cannot be run due to
the error: The operation was canceled by the user.` Generated bootstrap line495.
No successful VC installation or complete Setup is established. Root preserved
live snapshot `c0e7ac9a-1efc-493f-a660-a6d736374b89`, named
`PublisherCPU-R4-VC-Elevation-Canceled-20261002`, before further changes.
Copied primary bytes and their hashes remain pending; this is UI observation.

The Computer Use skill prohibits approving security permission prompts. Root
requested that the user handle any native UAC prompt during a retry. That is
separate from the user's already-recorded vendor-terms consent for VM tests.

## Paused checkpoint

User requested pause at the next available point. Root stopped at the preserved
failed-install checkpoint. The implementer reports no command running. Its
authorized follow-up changed only the VC launcher and its focused test:
`ProcessStartInfo` / `Process.Start`, retaining shell execution, native `runas`,
normal vendor UI and exact reviewed arguments. A real missing-file launch
demonstrated expected RED with the old launcher, which discarded native codes.
GREEN is incomplete: the new test's generic catch observes PowerShell's
`MethodInvocationException`; it needs the same typed Win32 catch as production.
No test correction or additional verification was performed after pause.

Resume with that test correction and focused VC/runtime/reboot/publisher/CPU
wizard regressions, then freeze/build/review the next immutable candidate.
Actual user-handled native UAC, complete clean Setup, application checks and
subsequent generated-uninstaller tests remain pending. The user is willing to
handle the VM UAC prompt, but no prompt was approved by automation. Candidate r4
and its reviews remain unchanged. No release, commit or push was performed.

Disk checkpoint: D: had about362MB free after retained VM snapshots; C: had
about57.9GB. Root inspected an unattached historical r2 VHD as a possible
relocation candidate but performed no move or deletion. Resolve space before
another build/snapshot/VM retry. Current r4 VM remains open at the failed attempt.

## Resumed bounded implementation and focused verification

Root cleared disk space and authorized continuation. The launcher now uses
standard-library `ProcessStartInfo` and `Process.Start`, retaining
`UseShellExecute=true`, `Verb=runas`, normal vendor UI and the reviewed
`/install /norestart` arguments. PowerShell's Start-Process replaces a native
Win32Exception with an InvalidOperationException without its native code;
[the official shell-launch implementation](https://raw.githubusercontent.com/PowerShell/PowerShell/master/src/Microsoft.PowerShell.Commands.Management/commands/management/Process.cs)
supports the finding. No localized message parsing or retry was introduced.

Before production changes, the actual launcher against a guaranteed nonexistent
inert executable produced expected RED:
`Real launcher discarded native Win32 launch error: System.InvalidOperationException`.
After the change, the test uses the same typed Win32 catch as production and
retains its exact `NativeErrorCode=2` assertion. This distinguishes PowerShell's
method invocation wrapper from the native exception caught by the typed clause.
The existing injected error1223 test remains enabled and now also checks both
durable records are terminal `cancelled` with no vendor exit code. A separate
error2 launch fixture proves unknown launch failure remains `unresolved`, keeps
`in_progress` state, and refuses a same-boot automatic retry. Existing owned-child
observation failure, lock and publication checks remain enabled.

Executed from `D:/Projects/autoclip-runtime`, all GREEN:

```powershell
powershell.exe -NoProfile -NonInteractive -File tests/InstallerVcRuntime.Tests.ps1
powershell.exe -NoProfile -NonInteractive -File tests/InstallerVcReboot.Tests.ps1
powershell.exe -NoProfile -NonInteractive -File tests/InstallerPublisherVc.Tests.ps1
powershell.exe -NoProfile -NonInteractive -File tests/InstallerPublisherCpuConsent.Tests.ps1
powershell.exe -NoProfile -NonInteractive -File tests/InstallerPublisherCpuWizard.Tests.ps1
git diff --check -- installer/install-vc-runtime.ps1 tests/InstallerVcRuntime.Tests.ps1
```

The real missing-file launch invoked no executable. Cancellation, vendor results
and DLL capability remain inert first-party boundaries. No actual UAC cancellation,
vendor installation, VM, production artifact, security prompt or release action
was performed by this assignment. Root owns fresh candidate integration, review
and actual clean-machine lifecycle verification. The preserved r4 candidate and
its observations are not rebound to these new bytes.

Frozen source SHA-256:
`installer/install-vc-runtime.ps1` =
`418ebdf1d431cd92fe895ba27f2f5003cd46deda8035b4c5f38e448fdf747fe1`;
`tests/InstallerVcRuntime.Tests.ps1` =
`136c4b1a41d90c4e5c1f2d77f03f3bacb7d780dfe98829e2788dc070f77b2984`.
These files are currently untracked, so `git diff` cannot provide their baseline
comparison; the production change was limited to the existing launcher function,
and before/after helper identities were recorded in this workstream.
