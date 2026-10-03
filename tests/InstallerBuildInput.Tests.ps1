$ErrorActionPreference='Stop'
function Assert($condition,$message){if(-not $condition){throw $message}}
function Pin($path){(Get-FileHash -LiteralPath $path).Hash.ToLowerInvariant()}
$root=Join-Path $env:TEMP ('autoclip-build-input-'+[guid]::NewGuid().ToString('N'))
$sid=[Security.Principal.WindowsIdentity]::GetCurrent().User
$acl=[Security.AccessControl.DirectorySecurity]::new()
$acl.SetOwner($sid);$acl.SetAccessRuleProtection($true,$false)
foreach($identity in @($sid.Value,'S-1-5-18','S-1-5-32-544')){
    $acl.AddAccessRule([Security.AccessControl.FileSystemAccessRule]::new([Security.Principal.SecurityIdentifier]::new($identity),'FullControl','ContainerInherit,ObjectInherit','None','Allow'))
}
[IO.Directory]::CreateDirectory($root,$acl)|Out-Null
$helper=Join-Path $root 'run-source-build.ps1'
Copy-Item -LiteralPath (Join-Path $PSScriptRoot '../installer/run-source-build.ps1') -Destination $helper
$bootstrap=Join-Path $root 'install fixture.ps1'
[IO.File]::WriteAllText($bootstrap,@'
param($InstallRoot,$ArchivePath,[switch]$NonInteractive,[switch]$NoPrerequisiteAcquisition,[switch]$SkipDesktopShortcut,$CancelPath,$SecureAcquisitionManifestPath,$SecureAcquisitionManifestSha256,$SecureDownloaderSha256)
[IO.File]::WriteAllText($InstallRoot+'.entry.json',(@{pid=$PID;native64=[Environment]::Is64BitProcess}|ConvertTo-Json))
$watch=[Diagnostics.Stopwatch]::StartNew()
while(-not [IO.File]::Exists($InstallRoot+'.release')){
    if($watch.Elapsed.TotalSeconds -ge 60){throw 'Held fixture release was not supplied; no vendor execution.'}
    Start-Sleep -Milliseconds 50
}
[IO.File]::WriteAllText($InstallRoot+'.finished','first-party producer terminal')
exit 7
'@)
$manifest=Join-Path $root 'manifest.json'
[IO.File]::WriteAllText($manifest,(@{target_release=@{sha256=('0'*64);manifest_sha256=('1'*64)}}|ConvertTo-Json -Depth 4))
$downloader=Join-Path $root 'download-artifact.ps1';[IO.File]::WriteAllText($downloader,'# first-party fixture; never download')
$arguments=Join-Path $root 'arguments.json'
$installRoot=Join-Path $root 'held release'
[IO.File]::WriteAllText($arguments,(@{schema_version=1;parameters=@{InstallRoot=$installRoot;ArchivePath=(Join-Path $root 'archive.zip');NonInteractive=$true;NoPrerequisiteAcquisition=$true;SkipDesktopShortcut=$true}}|ConvertTo-Json -Depth 5))
$attempt=Join-Path $root 'attempt'
$invocation=[ordered]@{BootstrapPath=$bootstrap;BootstrapSha256=(Pin $bootstrap);ManifestPath=$manifest;ManifestSha256=(Pin $manifest);DownloaderPath=$downloader;DownloaderSha256=(Pin $downloader);ArgumentsPath=$arguments;ArgumentsSha256=(Pin $arguments);HelperSha256=(Pin $helper);AttemptDirectory=$attempt}
$cli=@('-NoProfile','-NonInteractive','-ExecutionPolicy','Bypass','-File',('"'+$helper+'"'))
foreach($key in $invocation.Keys){$cli+='-'+$key;$cli+='"'+$invocation[$key]+'"'}
$info=[Diagnostics.ProcessStartInfo]::new()
$info.FileName=Join-Path $env:WINDIR 'System32/WindowsPowerShell/v1.0/powershell.exe'
$info.Arguments=$cli -join ' ';$info.UseShellExecute=$false;$info.CreateNoWindow=$true
$info.RedirectStandardInput=$true
$process=[Diagnostics.Process]::new();$process.StartInfo=$info
$null=$process.Start();$handle=$process.Handle;$originalPid=$process.Id;$start=$process.StartTime.ToUniversalTime().ToString('o')
$receipt=[ordered]@{schema_version=1;fixture_root=$root;helper_sha256=(Pin $helper);supervisor_pid=$originalPid;supervisor_handle=[long]$handle;supervisor_start_utc=$start;stdin_left_open=$true;vendor_executed=$false;vm_executed=$false}
$terminalWithOpenInput=$false
$enteredWithOpenInput=$false
try {
    $watch=[Diagnostics.Stopwatch]::StartNew()
    while(-not [IO.File]::Exists($installRoot+'.entry.json') -and -not $process.HasExited -and $watch.Elapsed.TotalSeconds -lt 8){Start-Sleep -Milliseconds 50}
    $enteredWithOpenInput=[IO.File]::Exists($installRoot+'.entry.json')
    $receipt.producer_entered_with_open_stdin=$enteredWithOpenInput
    if(-not $enteredWithOpenInput){
        $receipt.stdin_closed_for_readiness=$true
        $process.StandardInput.Close()
        $watch.Restart()
        while(-not [IO.File]::Exists($installRoot+'.entry.json') -and -not $process.HasExited -and $watch.Elapsed.TotalSeconds -lt 30){Start-Sleep -Milliseconds 50}
    }
    Assert ([IO.File]::Exists($installRoot+'.entry.json')) 'Actual worker did not enter the held first-party producer.'
    $entry=[IO.File]::ReadAllText($installRoot+'.entry.json')|ConvertFrom-Json
    $live=[IO.File]::ReadAllText((Join-Path $attempt 'status.json'))|ConvertFrom-Json
    Assert ($live.status -eq 'RUNNING' -and $live.worker_pid -eq $entry.pid -and $entry.native64) 'Held producer does not bind to live actual worker.'
    $receipt.worker_pid=$entry.pid
    [IO.File]::WriteAllText($installRoot+'.release','release same original first-party producer')
    $observedTerminal=$process.WaitForExit(8000)
    $terminalWithOpenInput=$enteredWithOpenInput -and $observedTerminal
    $receipt.terminal_with_open_stdin=$terminalWithOpenInput
    $receipt.producer_finished=[IO.File]::Exists($installRoot+'.finished')
} finally {
    # Close only the existing original input; preserve any pending process on timeout.
    $process.StandardInput.Close()
    $receipt.stdin_closed_after_observation=$true
    $receipt.terminal_after_close=$process.WaitForExit(30000)
    if($receipt.terminal_after_close){
        $process.WaitForExit();$receipt.supervisor_exit=$process.ExitCode
        $receipt.observed_original_pid=$process.Id
        $receipt.observed_original_start_utc=$process.StartTime.ToUniversalTime().ToString('o')
        if([IO.File]::Exists((Join-Path $attempt 'status.json'))){$receipt.terminal_status=[IO.File]::ReadAllText((Join-Path $attempt 'status.json'))|ConvertFrom-Json}
    }
    [IO.File]::WriteAllText((Join-Path $root 'observation.json'),($receipt|ConvertTo-Json -Depth 6))
    Write-Host ('PRESERVED '+$root)
}
Assert $receipt.terminal_after_close 'Original supervisor remains pending; fixture retained, no kill or restart.'
Assert ($receipt.observed_original_pid -eq $originalPid -and $receipt.observed_original_start_utc -eq $start) 'Original process identity changed.'
Assert ($receipt.producer_finished -and $receipt.supervisor_exit -eq 7 -and $receipt.terminal_status.status -eq 'TERMINAL' -and $receipt.terminal_status.exit_code -eq 7 -and $receipt.terminal_status.worker_pid -eq $receipt.worker_pid) 'Actual worker completion or nonzero exit propagation changed.'
$process.Dispose()
Assert ($enteredWithOpenInput -and $terminalWithOpenInput) 'RED: actual noninteractive supervisor waits for redirected stdin EOF before first-party producer entry or terminal observation.'
'PASS actual noninteractive supervisor observes held first-party producer terminal with stdin left open and propagates exit7'
