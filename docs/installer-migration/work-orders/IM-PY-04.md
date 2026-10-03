# IM-PY-04: Python reboot receipt handoff

- Parent: production Inno installer, then exact generated-uninstaller tests,
  then authorized release. NVIDIA hardware tests deferred.
- Authorization: contract-first TDD implementation of the existing reboot rule.
- Role: implementer; configured GPT-6.1 Sol/medium, actual routing not exposed.
- Own only `installer/AutoClip.iss`, `tests/InstallerPythonWizard.Tests.ps1`,
  new `tests/InstallerPythonRebootReceipt.Tests.ps1`, and a new external report.
- Not alone: root owns contract, plan and all other files. Preserve all edits.
- Read objective, AGENTS/updater policy, contract, actual Python helper,
  actual reboot command/caller, and current wizard diagnostic generator.

## Required correction

The contract already puts Python receipts under
`%LOCALAPPDATA%/AutoClip/PythonSetupLogs`. `PreparePython` passes that directory
to `install-python.ps1`; its real producer writes `python-<GUID>.json` there.
`PythonRebootStatus` instead scans `Setup/logs/python` when the durable marker
is absent. Existing native diagnostic writes fake receipts to the obsolete
folder and ignores the passed LogDirectory, concealing the producer/consumer
disagreement. The contract and actual producer take precedence.

Demonstrate behavioral RED before production edits: use the actual generated
PowerShell reboot-check body with a genuine current Python helper receipt in
the actual directory selected by the wizard. Only inert process/signature/native
clock/path boundaries may be substituted; do not mock pending-state logic or
rewrite a receipt to match the obsolete consumer. Then minimum shared path
correction; prefer one existing path provider reused by producer and consumer.
Same-boot pending3010 must prevent acquisition/capability reuse; post-reboot
must still invoke normal capability verification. Invalid/reparse state fails
closed and remains preserved. Do not implement a generic reboot framework.

Fix the existing diagnostic's receipt producer to respect passed LogDirectory.
Redirect that path only in temporary diagnostic native/path boundaries; never
write a fake vendor receipt to the recipient's real AutoClip directories. Keep
all existing scenario assertions. Explain the fixture/requirement conflict before
changing it. Do not add a production test switch or weaken assertions.

## Permitted verification and limits

Run PS5 inert host checks with real first-party temporary receipt/file behavior,
and compile/export-only the affected native diagnostic with exact approved ISCC.
Do not execute any setup executable on the host or VM: root decides subsequent
native component testing. No actual vendor installer, download/acquisition,
agreement acceptance, existing installation/user-data mutation, VM, uninstaller,
trust/policy/clock change, packaging promotion, commit/push or release. Inert
process outcomes and substituted clocks are test-only, clearly recorded.

Return RED/GREEN commands/output, exact files/hashes, source boundary extraction
methods, producer receipt evidence, unchanged assertions, parser and compile
results. Mark native Pascal execution and full setup/reboot lifecycle unverified.
The earlier automatically rejected fresh prerequisite-acquisition preparation
must not be retried or bypassed. Keep production installer qualification and
then actual generated-uninstaller acceptance as separate remaining gates.

## Returned evidence and root integration

Frozen report:
`D:/AutoClip-Inno-Migration/python-wizard-diag-IM-PY-04-20261002/IM-PY-04-report.md`,
SHA256 `6d849976b12c9c5783c922503dc3c4d593864a669ef13424b919f4390d40ea57`.
Root inspected the complete report and producer/consumer test/source, verified
its hash, and independently ran
`powershell.exe -NoProfile -NonInteractive -File tests/InstallerPythonRebootReceipt.Tests.ps1`:
exit0, eight actual generated-command behaviors passed. The real helper producer
wrote the pending receipt; only native/process/signature/clock/path boundaries
were substituted. Pascal caller ordering was inspected, not executed.

Exact frozen source:

- `AutoClip.iss`: `5397ac000b46bfed90a1761ff2091a1eb6c0816a3b7cfdaa45c0e0c6324ddde1`
- existing wizard test: `5d8e7117daf1b9806265282fa38a1b0614449cd7107af41b6f016ebc343ff1c7`
- new receipt test: `223fc6dc3b9d508322dc46aa48365385de9f0a60e2006e0f4bec3d034d529be6`

Agent ran PythonInstall/PythonPin regressions and exact diagnostic compile/export
only; the twelve-scenario runner remained byte-identical at
`345222e68f07563526c4639c39295db88ff45ab91f8926566e69251cc07dd61a`.
No setup executable or real vendor was executed. Root accepts the bounded path
correction evidence; full native reboot/resume and production qualification
remain open. Historical exact-source61c2 reviews retain their original scope.
