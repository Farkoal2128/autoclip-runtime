param([switch]$DurableOnly)
$ErrorActionPreference='Stop'
$repo=Split-Path -Parent $PSScriptRoot
$fixture=Join-Path $env:TEMP ('autoclip-build-storage-'+[guid]::NewGuid().ToString('N'))
$acl=[Security.AccessControl.DirectorySecurity]::new();$sid=[Security.Principal.WindowsIdentity]::GetCurrent().User
$acl.SetOwner($sid);$acl.SetAccessRuleProtection($true,$false)
foreach($id in @($sid.Value,'S-1-5-18','S-1-5-32-544')){$acl.AddAccessRule([Security.AccessControl.FileSystemAccessRule]::new([Security.Principal.SecurityIdentifier]::new($id),'FullControl','ContainerInherit,ObjectInherit','None','Allow'))}
[IO.Directory]::CreateDirectory($fixture,$acl)|Out-Null
$helper=Join-Path $fixture 'run-source-build.ps1';[IO.File]::Copy((Join-Path $repo 'installer/run-source-build.ps1'),$helper)
$bootstrap=Join-Path $fixture 'bootstrap.ps1'
[IO.File]::WriteAllText($bootstrap,@'
param($InstallRoot,$ArchivePath,[switch]$NonInteractive,[switch]$NoPrerequisiteAcquisition,[switch]$SkipDesktopShortcut,$CancelPath,$SecureAcquisitionManifestPath,$SecureAcquisitionManifestSha256,$SecureDownloaderSha256)
[IO.File]::AppendAllText((Join-Path $InstallRoot 'entered.log'),"entered`r`n")
'first-party worker entered'
[Console]::Error.WriteLine('first-party retained stderr')
$watch=[Diagnostics.Stopwatch]::StartNew()
while(!(Test-Path (Join-Path $InstallRoot 'release.signal'))){if($watch.Elapsed.TotalSeconds -gt 30){exit 23};Start-Sleep -Milliseconds 50}
[IO.File]::WriteAllText((Join-Path (Split-Path -Parent $CancelPath) 'health-result.json'),'first-party storage fixture; no health claim')
if(Test-Path (Join-Path $InstallRoot 'exit7.signal')){exit 7}
exit 0
'@)
$manifest=Join-Path $fixture 'manifest.json';[IO.File]::WriteAllText($manifest,'{"target_release":{"sha256":"aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa","manifest_sha256":"bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb"}}')
$downloader=Join-Path $fixture 'download-artifact.ps1';[IO.File]::WriteAllText($downloader,'# first-party fixture')
$native=Join-Path $env:SystemRoot 'System32/WindowsPowerShell/v1.0/powershell.exe'
function Assert($value,$message){if(!$value){throw $message}}
function Pin($path){(Get-FileHash -LiteralPath $path).Hash.ToLowerInvariant()}
function Invoke-Args($root,$attempt){
    $argsPath=Join-Path $fixture ([guid]::NewGuid().ToString('N')+'.json')
    [IO.File]::WriteAllText($argsPath,(@{schema_version=1;parameters=@{InstallRoot=$root;ArchivePath=(Join-Path $fixture 'archive.zip');NonInteractive=$true;NoPrerequisiteAcquisition=$true;SkipDesktopShortcut=$true}}|ConvertTo-Json -Depth 4))
    return @{BootstrapPath=$bootstrap;BootstrapSha256=(Pin $bootstrap);ManifestPath=$manifest;ManifestSha256=(Pin $manifest);DownloaderPath=$downloader;DownloaderSha256=(Pin $downloader);ArgumentsPath=$argsPath;ArgumentsSha256=(Pin $argsPath);HelperSha256=(Pin $helper);AttemptDirectory=$attempt}
}
function Start-Boundary($invocation,[switch]$Worker,[switch]$RequestCancellation){
    $cli=@('-NoProfile','-NonInteractive','-File',('"'+$helper+'"'))
    if($Worker){$cli+='-Worker'};if($RequestCancellation){$cli+='-RequestCancellation'}
    foreach($key in $invocation.Keys){$cli+='-'+$key;$cli+='"'+$invocation[$key]+'"'}
    $id=[guid]::NewGuid().ToString('N')
    $p=Start-Process $native -ArgumentList ($cli -join ' ') -WindowStyle Hidden -PassThru -RedirectStandardOutput (Join-Path $fixture ($id+'.out')) -RedirectStandardError (Join-Path $fixture ($id+'.err'))
    $handle=$p.Handle;return $p
}
function Wait-File($path,$process){$watch=[Diagnostics.Stopwatch]::StartNew();while(!(Test-Path $path) -and !$process.HasExited -and $watch.Elapsed.TotalSeconds -lt 15){Start-Sleep -Milliseconds 50};Assert (Test-Path $path) "Child did not reach $path"}
function Wait-Terminal($process){Assert ($process.WaitForExit(40000)) 'Fixture child remains pending; no kill performed.';$process.WaitForExit();$code=[int]$process.ExitCode;$process.Dispose();return $code}
function New-Attempt($name){$path=Join-Path $fixture $name;[IO.Directory]::CreateDirectory($path,$acl)|Out-Null;[IO.File]::WriteAllText((Join-Path $path 'decision.lock'),'');return $path}
$root=Join-Path $fixture 'target';[IO.Directory]::CreateDirectory($root)|Out-Null
if(!$DurableOnly){
$first=Start-Boundary (Invoke-Args $root (New-Attempt 'worker-one')) -Worker
$second=$null;$other=$null
try{
    Wait-File (Join-Path $root 'entered.log') $first
    $second=Start-Boundary (Invoke-Args ($root.ToUpperInvariant()+'\') (New-Attempt 'worker-two')) -Worker
    $rejected=$second.WaitForExit(3000)
    Assert (!$first.HasExited) 'Existing worker was disturbed.'
    Assert ([IO.File]::ReadAllLines((Join-Path $root 'entered.log')).Count -eq 1) 'RED: second same-target worker entered bootstrap concurrently.'
    Assert $rejected 'Second same-target worker did not fail immediately.'
    Assert ((Wait-Terminal $second) -ne 0) 'Busy target returned success.';$second=$null
    $otherRoot=Join-Path $fixture 'independent-target';[IO.Directory]::CreateDirectory($otherRoot)|Out-Null
    $other=Start-Boundary (Invoke-Args $otherRoot (New-Attempt 'worker-other')) -Worker
    Wait-File (Join-Path $otherRoot 'entered.log') $other
    Assert (!$first.HasExited -and !$other.HasExited) 'Different-root worker did not proceed independently.'
    $writeFailed=$false;try{[IO.File]::WriteAllText($bootstrap,'changed')}catch{$writeFailed=$true}
    Assert $writeFailed 'Existing worker input lock was lost.'
}finally{
    [IO.File]::WriteAllText((Join-Path $root 'release.signal'),'release fixture')
    if($otherRoot){[IO.File]::WriteAllText((Join-Path $otherRoot 'release.signal'),'release fixture')}
    $firstExit=Wait-Terminal $first
    if($second){Wait-Terminal $second|Out-Null}
    if($other){$otherExit=Wait-Terminal $other}
}
Assert ($firstExit -eq 0 -and $otherExit -eq 0) 'Existing/different-root workers failed.'
$retry=Start-Boundary (Invoke-Args $root (New-Attempt 'worker-retry')) -Worker
Assert ((Wait-Terminal $retry) -eq 0 -and [IO.File]::ReadAllLines((Join-Path $root 'entered.log')).Count -eq 2) 'Terminal worker did not release target lock for retry.'
$sha=[Security.Cryptography.SHA256]::Create()
try{$key=[BitConverter]::ToString($sha.ComputeHash([Text.Encoding]::UTF8.GetBytes($root.ToUpperInvariant()))).Replace('-','').ToLowerInvariant()}finally{$sha.Dispose()}
$targetLock=Join-Path ([Environment]::GetFolderPath('LocalApplicationData')) ('AutoClip/Setup/locks/'+$key+'.lock')
Assert ((Get-Item $targetLock).Length -eq 0) 'Terminal target lock was removed or changed.'
$probe=[IO.File]::Open($targetLock,'Open','ReadWrite','None');$probe.Dispose()
'PASS same-target exclusion, case/slash normalization, different-root independence, input locks and terminal retry'
}
$logs=Join-Path ([Environment]::GetFolderPath('LocalApplicationData')) 'AutoClip/Setup/logs'
$attempt=Join-Path $logs ('source-build-wiz17-'+[guid]::NewGuid().ToString('N')+'-1')
$invocation=Invoke-Args $root $attempt
$request=Start-Boundary $invocation -RequestCancellation
$supervisor=$null
try{
    Start-Sleep -Milliseconds 600
    Assert (!$request.HasExited) 'RED: cancellation requester did not wait for protected durable startup.'
    Assert (!(Test-Path $attempt)) 'Cancellation request created staging before supervisor.'
    $supervisor=Start-Boundary $invocation
    $requestExit=Wait-Terminal $request;$request=$null
    Assert ($requestExit -eq 0) 'RED: startup cancellation not accepted under actual decision lock.'
}finally{
    [IO.File]::WriteAllText((Join-Path $root 'release.signal'),'release fixture')
    if($request){Wait-Terminal $request|Out-Null}
    if($supervisor){$supervisorExit=Wait-Terminal $supervisor}
}
Assert ($supervisorExit -eq 1223 -and (Test-Path (Join-Path $attempt 'cancel.txt'))) 'Actual durable supervisor did not report accepted cancellation.'
Assert ((Get-Acl $logs).AreAccessRulesProtected -and (Get-Acl $attempt).AreAccessRulesProtected) 'Durable directories were not protected.'
'PASS fixed durable startup waits for actual decision lock and retains accepted cancellation logs'
foreach($failure in @($false,$true)){
    $durableRoot=Join-Path $fixture ('durable-target-'+$failure);[IO.Directory]::CreateDirectory($durableRoot)|Out-Null
    [IO.File]::WriteAllText((Join-Path $durableRoot 'release.signal'),'release fixture')
    if($failure){[IO.File]::WriteAllText((Join-Path $durableRoot 'exit7.signal'),'fixture nonzero')}
    $attempt=Join-Path $logs ('source-build-wiz17-'+[guid]::NewGuid().ToString('N')+'-2')
    $child=Start-Boundary (Invoke-Args $durableRoot $attempt)
    $exit=Wait-Terminal $child
    Assert ($exit -eq $(if($failure){7}else{0})) 'Durable child exit changed.'
    foreach($file in @('stdout.log','stderr.log','health-result.json','decision.lock','tail.txt','status.json')){Assert (Test-Path (Join-Path $attempt $file)) "Durable $file not retained after terminal process."}
    Assert ([IO.File]::ReadAllText((Join-Path $attempt 'stdout.log')).Contains('first-party worker entered')) 'Durable stdout content lost.'
    Assert ([IO.File]::ReadAllText((Join-Path $attempt 'stderr.log')).Contains('first-party retained stderr')) 'Durable stderr content lost.'
}
'PASS durable success/failure logs and fixture health result survive terminal process'
$absent=Join-Path $logs ('source-build-wiz17-'+[guid]::NewGuid().ToString('N')+'-3')
$request=Start-Boundary (Invoke-Args $root $absent) -RequestCancellation
Assert ((Wait-Terminal $request) -eq 2 -and !(Test-Path $absent)) 'Missing startup was accepted or created staging.'
'PASS bounded missing startup returns2 without claiming accepted cancellation'
foreach($bad in @('arbitrary-missing-parent','invalid-fixed-name','existing-file','foreign-writer','reparse')){
    $attempt=Join-Path $logs ('source-build-wiz17-'+[guid]::NewGuid().ToString('N')+'-4')
    if($bad -eq 'arbitrary-missing-parent'){$attempt=Join-Path $fixture 'missing-parent/attempt'}
    if($bad -eq 'invalid-fixed-name'){$attempt=Join-Path $logs ('unrecognized-'+[guid]::NewGuid().ToString('N'))}
    if($bad -eq 'existing-file'){[IO.File]::WriteAllText($attempt,'preserve existing file')}
    if($bad -eq 'foreign-writer'){
        [IO.Directory]::CreateDirectory($attempt,$acl)|Out-Null
        $badAcl=[IO.Directory]::GetAccessControl($attempt,[Security.AccessControl.AccessControlSections]::Access);$badAcl.AddAccessRule([Security.AccessControl.FileSystemAccessRule]::new([Security.Principal.SecurityIdentifier]::new('S-1-1-0'),'Write','Allow'));[IO.Directory]::SetAccessControl($attempt,$badAcl)
    }
    if($bad -eq 'reparse'){New-Item -ItemType Junction -Path $attempt -Target $fixture|Out-Null}
    $child=Start-Boundary (Invoke-Args $root $attempt)
    Assert ((Wait-Terminal $child) -ne 0) "Unsafe durable attempt accepted: $bad"
    if($bad -eq 'existing-file'){Assert ([IO.File]::ReadAllText($attempt) -eq 'preserve existing file') 'Existing file was modified.'}
    if($bad -eq 'foreign-writer'){[IO.Directory]::SetAccessControl($attempt,$acl)}
}
'PASS missing arbitrary parent, invalid fixed basename, existing file, foreign write and reparse refusal'
foreach($bad in @('nonzero','directory','foreign-writer','reparse')){
    $lockRoot=Join-Path $fixture ('bad-lock-'+$bad);[IO.Directory]::CreateDirectory($lockRoot)|Out-Null
    [IO.File]::WriteAllText((Join-Path $lockRoot 'release.signal'),'release fixture')
    $sha=[Security.Cryptography.SHA256]::Create()
    try{$key=[BitConverter]::ToString($sha.ComputeHash([Text.Encoding]::UTF8.GetBytes($lockRoot.ToUpperInvariant()))).Replace('-','').ToLowerInvariant()}finally{$sha.Dispose()}
    $path=Join-Path ([Environment]::GetFolderPath('LocalApplicationData')) ('AutoClip/Setup/locks/'+$key+'.lock')
    if($bad -eq 'directory'){[IO.Directory]::CreateDirectory($path,$acl)|Out-Null}
    elseif($bad -eq 'reparse'){New-Item -ItemType Junction -Path $path -Target $fixture|Out-Null}
    else{[IO.File]::WriteAllText($path,$(if($bad -eq 'nonzero'){'preserve unexpected lock bytes'}else{''}))}
    if($bad -eq 'foreign-writer'){$original=[IO.File]::GetAccessControl($path,[Security.AccessControl.AccessControlSections]::Access);$foreign=[IO.File]::GetAccessControl($path,[Security.AccessControl.AccessControlSections]::Access);$foreign.AddAccessRule([Security.AccessControl.FileSystemAccessRule]::new([Security.Principal.SecurityIdentifier]::new('S-1-1-0'),'Write','Allow'));[IO.File]::SetAccessControl($path,$foreign)}
    $child=Start-Boundary (Invoke-Args $lockRoot (New-Attempt ('bad-lock-attempt-'+$bad))) -Worker
    Assert ((Wait-Terminal $child) -ne 0 -and !(Test-Path (Join-Path $lockRoot 'entered.log'))) "Unsafe target lock allowed bootstrap: $bad"
    if($bad -eq 'nonzero'){Assert ([IO.File]::ReadAllText($path) -eq 'preserve unexpected lock bytes') 'Nonzero lock was modified.'}
    if($bad -eq 'foreign-writer'){[IO.File]::SetAccessControl($path,$original)}
}
'PASS target lock rejects nonzero, directory, foreign writer and reparse before bootstrap'
'FIXTURE='+$fixture
