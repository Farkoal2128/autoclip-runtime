# IM-WIZ-25 - host COM stdin lifetime observation

Status: bounded ordinary collaborator investigation complete. This report and
`D:/AutoClip-Inno-Migration/wiz25-host-com-stdin-check.ps1` are the only owned
outputs. No production, VM, vendor, compiled Setup or security configuration was
changed. This observation does not close the guest startup gate.

## Method and commands

The external checker creates a fresh protected ordinary-user staging directory
and launches a tiny pinned first-party script using WScript.Shell.Exec and native
Windows PowerShell 5.1.26100.9444 with `-NoProfile -NonInteractive -WindowStyle
Hidden -ExecutionPolicy Bypass -File`. It compares leaving redirected stdin open
with closing it immediately. It captures the original native process handle,
PID, start time, image and command. After eight seconds, a pending baseline gets
its **existing** COM StdIn closed; it is never killed or restarted. Receipts are
bounded and validated against the original process identity. Only terminal tiny
fixed outputs are read through COM. Both checks exited 0 with all children terminal:

```powershell
powershell -NoProfile -File D:\AutoClip-Inno-Migration\wiz25-host-com-stdin-check.ps1
powershell -NoProfile -File D:\AutoClip-Inno-Migration\wiz25-host-com-stdin-check.ps1 -InputVariable
```

Checker SHA-256:
`eaad313574dffd95e7bf422e73174e305848eeee84824339f1f7c67702a0f982`.

## Native observations

The plain script completed with stdin open: PID38212, handle2716, start
`2026-10-02T06:13:06.3383300Z`, 248ms, native and COM exit17. Immediate-close
control PID52376, handle2692, start `2026-10-02T06:13:06.6893697Z` completed in
244ms, exit17. Both wrote their entry receipt. Thus ordinary `-File` alone does
not universally wait for EOF.

The second fixture adds the supervisor's ordinary `foreach($input in ...)`
idiom. Its open-input baseline PID51280, handle2668, start
`2026-10-02T06:10:45.3093241Z` remained live after 8008ms. Its entry receipt
already existed. Closing that same process's stdin allowed terminal exit17 in
60ms. The immediate-close control PID44976, handle2832, start
`2026-10-02T06:10:53.5346615Z` completed in238ms with exit17. Original PID/start
bindings were preserved. This proves a host completion dependency on stdin EOF
for that actual first-party pattern; it does not prove that the guest R5 script
never entered or identify the cause of missing worker readiness.

Primary observations (protected staging preserved):

- Plain: `C:/Users/beilo/AppData/Local/Temp/autoclip-wiz25-com-stdin-549289b11128452d9699019bde67606e/observation.json`, SHA `4b465690dcec450f855aa7d1b4dc0b0236881de8a0b99d2f1e17aa92a5718b12`.
- Input-variable: `C:/Users/beilo/AppData/Local/Temp/autoclip-wiz25-com-stdin-43026515db6a4e9e93c5c7a30adfdccd/observation.json`, SHA `32378060335f4397e7d51587381d9a513ae8a445cbcb00f13ee8187c1d26b764`.

## Primary source reconciliation and limits

[Microsoft's WSH article](https://learn.microsoft.com/en-us/archive/msdn-magazine/2002/may/scripting-windows-script-host-5-6-boasts-windows-xp-integration-security-new-object-model)
describes the Exec process object's redirected stdin/stdout/stderr streams and
status. [Windows PowerShell command documentation](https://learn.microsoft.com/en-us/powershell/module/microsoft.powershell.core/about/about_powershell_exe?view=powershell-5.1)
describes NonInteractive as suppressing interactive prompts; it does not promise
closure of redirected stdin.

Official modern [ConsoleHost source](https://github.com/PowerShell/PowerShell/blob/master/src/Microsoft.PowerShell.ConsoleHost/host/msh/ConsoleHost.cs)
parses file/command ASTs for dollar-input use and selects ReadInputObjects.
[Executor source](https://github.com/PowerShell/PowerShell/blob/master/src/Microsoft.PowerShell.ConsoleHost/host/msh/Executor.cs)
starts the pipeline asynchronously, then reads redirected console input until
the deserializer reaches EOF before closing pipeline input and waiting. That
explains why script entry can precede the completion wait. These are explanatory
modern sources, not a claim to have inspected the exact Windows PowerShell5.1
binary source; the host observations establish native5.1 behavior here.

Inspection found one reserved `$input` loop in run-source-build.ps1 and four
Inno Shell.Exec launch sites (cancellation, download, MSYS command, source build)
that do not close unused stdin. Parent may qualify an input-close variant or
the smaller reserved-local rename using actual production helper tests. Neither
has been implemented by this work order. Guest observations and guest
remediation qualification remain the parent's responsibility.
