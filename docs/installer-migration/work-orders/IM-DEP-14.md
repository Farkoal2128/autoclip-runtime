# IM-DEP-14: align wizard consent with the selected CPU prerequisites

Date: 2026-10-02. Root assignment follows the blind r1 review's concrete
consent finding. The user authorized the publisher CPU successor and Inno
integration. Ownership is limited to `installer/AutoClip.iss`, a new focused
consent regression, existing wizard fixture declarations when required, and
this record. Existing r1 frozen source and Setup bytes remain intact.

## Requirement and boundary

The runtime architecture requires CPU to avoid NVIDIA terms and requires
already valid Microsoft inputs to avoid provisioning consent. The former
wizard placed Microsoft/CUDA/cuBLAS controls on one page, always required
the Microsoft checkbox and unconditionally declared Microsoft acceptance
in the worker JSON.

The wizard now has a Microsoft page with one checkbox and a separate NVIDIA
page with two checkboxes and links. CPU skips the NVIDIA page. Publisher CPU
checks the pinned `install-vc-runtime.ps1 -CheckOnly` before leaving the
prerequisite summary. The helper retains its four-DLL signature/version/x64
capability check; the wizard does not substitute its own capability test.
CheckOnly uses the same default state directory as the bootstrap:
`{localappdata}/AutoClip/publisher-cache/vc-runtime`.

The native PowerShell boundary locks and checks the exact helper and outer
manifest pins, invokes bare `-CheckOnly`, and requires one JSON result with
integer schema/exit code consistent with the child exit. Only exact ready/0
skips Microsoft consent; exact missing/2 leads to its checkbox. Consistent
pending-reboot/3010 blocks advancement with a restart message. Busy, unknown,
contradictory, malformed, multiple-result or failed-launch outcomes block
advancement. No acquisition or vendor installer is invoked by this check.

Worker declarations now come from the actual applicable checkbox values.
Skipped Microsoft consent emits no acceptance declaration, including a stale
checked value when capability becomes ready. NVIDIA declarations require the
NVIDIA profile and both of its actual checks. Profile selection resets the
declarations. The bootstrap's existing authoritative capability recheck and
missing-prerequisite consent guard remain unchanged; a later state change
can fail before acquisition rather than infer agreement.

## RED and GREEN

Working directory: `D:/Projects/autoclip-runtime`.

```powershell
powershell.exe -NoProfile -NonInteractive -File tests/InstallerPublisherCpuConsent.Tests.ps1
powershell.exe -NoProfile -NonInteractive -File tests/InstallerPublisherCpuWizard.Tests.ps1
powershell.exe -NoProfile -NonInteractive -File tests/InstallerMsys2Wizard.Tests.ps1
git diff --check -- installer/AutoClip.iss tests/InstallerPublisherCpuWizard.Tests.ps1 tests/InstallerPublisherCpuConsent.Tests.ps1
```

Meaningful compiled Pascal RED: the actual former `ShouldSkipPage` allowed
the CPU NVIDIA page. The diagnostic Setup log records
`CPU presents NVIDIA terms` under
`C:/Users/beilo/AppData/Local/Temp/autoclip-cpu-consent-37520289cdb24f309b79474bfb81add9/result.txt.log`.

GREEN: the new diagnostic compiles and executes the actual page-skip,
Next-button and vendor-argument functions. It covers CPU/GPU separation,
ready/missing Microsoft state, explicit declarations, stale skipped values,
reboot/busy/unknown states and failed helper launch. The captured actual
PowerShell command is also executed with an inert first-party helper and
fixture paths/pins. Ready, missing, reboot, busy, unknown, contradictory,
string-schema, multiple and malformed results have their required outcomes;
a changed helper is rejected before execution. Production native helper
internals and vendor execution are not mocked into an acceptance claim.

Existing publisher CPU success/retry/native-failure/cancel/pinned-uv cases
pass. Its fixture only gained the actual new page variables and page objects;
original assertions remain. All 13 existing compiled MSYS source decisions
pass without modifying that test. Scoped whitespace validation passes.

The diagnostic's message-box boundary is first-party and inert so negative
Next-button cases can run unattended. An initial diagnostic timed out on a
real custom message box; its owned diagnostic process was stopped and the
test boundary corrected. No security rejection was retried or overridden.

## Remaining verification

No new production Setup was built or installed here. No VM, vendor consent,
prerequisite acquisition, uninstall or publication occurred. Root owns the
new immutable r2 archive/Setup, full compile, exact blind review and clean
recipient wizard/application/lifecycle/uninstaller verification. GPU hardware
testing remains deferred under the user's instruction.
