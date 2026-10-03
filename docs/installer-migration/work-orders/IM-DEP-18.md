# IM-DEP-18: distinguish VC executable and installed-DLL signers

Date: 2026-10-02. Parent objective: continue the authorized CPU installer and
subsequent generated-uninstaller qualification. Root owns implementation,
integration, VM and release decisions.

## Evidence and correction

Root reports that the official VC installer displayed `Setup Successful` in
actual VM snapshot `48dc5ca8-169c-4db1-8c4b-e3ec22ab7cd1`, named
`PublisherCPU-R6-VC-Dll-Signer-Refusal-20261002`, on VM
`7b5f6662-5e6f-459f-8aa0-2bcb01bb9146`. The AutoClip helper observed vendor
exit code 0, then failed its installed-DLL capability check. Guest Explorer
reported Signature OK for
`C:/Windows/System32/vcruntime140.dll`; its signer details showed CN
`Microsoft Windows Software Compatibility Publisher` and O
`Microsoft Corporation`. These are producer-reported guest observations, not
an independent snapshot inspection or post-fix VM result.

The cause was reusing the downloaded vendor executable's strict publisher-CN
rule for installed Microsoft system DLLs. The bounded code correction keeps
that EXE rule unchanged and allows the four required installed DLLs a valid
signature with exact subject CN `Microsoft Corporation` or `Microsoft Windows
Software Compatibility Publisher`, plus exact subject O `Microsoft
Corporation`. Path, ACL, version, x64 identity and native loader checks remain
required. Failure diagnostics remain private; no public result schema changed.

The actual-function AST focused test demonstrated RED against the old helper:
`Actual capability rejected valid Microsoft compatibility-signed system
DLLs.` Root reports GREEN after the correction and PASS for
`tests/InstallerVcCapability.Tests.ps1`,
`tests/InstallerVcRuntime.Tests.ps1` and
`tests/InstallerVcReboot.Tests.ps1`, each run in a fresh
`powershell.exe -NoProfile -NonInteractive -File` process. The focused
capability test reads the host's four installed DLLs, including bytes/PE,
version, ACL and Authenticode metadata; only the native loader boundary is
inert. It checks both accepted signer subjects, invalid/missing and foreign
signers, the unchanged strict vendor-EXE signer rule, and version/load/free
failures. These execution results are recorded from the producer report, not
rerun for this document update.

At 2026-10-02 16:28:37 -07:00, the inspected helper and test hashes were:

- `installer/install-vc-runtime.ps1` SHA-256
  `1afe73c791d3bc9d1f997bdc866ce76f7aa5248d94f33e442c0988913bf899fd`
- `tests/InstallerVcCapability.Tests.ps1` SHA-256
  `58ee8c3d136ae9c074a8e363244578574daae4c10fdf2439187740ffc2b19030`

These hashes timestamp the inspected files only; later root edits may change
them. No rerun against the changed signer policy in the actual VM is established
here. The exact user action at the native UAC prompt was not observed, and this
evidence does not qualify generated uninstallation, complete installation,
independent review, or release. Root retains those gates.
