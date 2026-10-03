$ErrorActionPreference='Stop'
$repo=Split-Path -Parent $PSScriptRoot
$fixture=Join-Path $env:TEMP ('autoclip-build-tail-'+[guid]::NewGuid().ToString('N'))
$acl=[Security.AccessControl.DirectorySecurity]::new();$sid=[Security.Principal.WindowsIdentity]::GetCurrent().User
$acl.SetOwner($sid);$acl.SetAccessRuleProtection($true,$false)
foreach($id in @($sid.Value,'S-1-5-18','S-1-5-32-544')){$acl.AddAccessRule([Security.AccessControl.FileSystemAccessRule]::new([Security.Principal.SecurityIdentifier]::new($id),'FullControl','ContainerInherit,ObjectInherit','None','Allow'))}
[IO.Directory]::CreateDirectory($fixture,$acl)|Out-Null
$helper=Join-Path $fixture 'run-source-build.ps1';[IO.File]::Copy((Join-Path $repo 'installer/run-source-build.ps1'),$helper)
$bootstrap=Join-Path $fixture 'bootstrap.ps1'
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
function Open-TailReader($path,$supervisor,[int]$timeoutMilliseconds=2000){
    $watch=[Diagnostics.Stopwatch]::StartNew()
    while(!$supervisor.HasExited -and $watch.ElapsedMilliseconds -lt $timeoutMilliseconds){
        try{return [IO.File]::Open($path,'Open','Read','Read')}
        catch [IO.IOException]{if(($_.Exception.HResult -band 65535) -notin @(32,33)){throw}}
        Start-Sleep -Milliseconds 20
    }
    throw 'Tail reader could not be established while the actual supervisor was live.'
}
[IO.File]::WriteAllText($bootstrap,@'
param($InstallRoot,$ArchivePath,[switch]$NonInteractive,[switch]$NoPrerequisiteAcquisition,[switch]$SkipDesktopShortcut,$CancelPath,$SecureAcquisitionManifestPath,$SecureAcquisitionManifestSha256,$SecureDownloaderSha256)
[IO.File]::WriteAllText((Join-Path $InstallRoot 'entered.log'),'ready')
'before tail reader'
$watch=[Diagnostics.Stopwatch]::StartNew()
while(!(Test-Path (Join-Path $InstallRoot 'release.signal'))){if($watch.Elapsed.TotalSeconds -gt 20){exit 23};Start-Sleep -Milliseconds 50}
if(Test-Path -LiteralPath $CancelPath){exit 1223}
$commit=@{schema_version=1;decision='COMMIT_STARTED';install_root=$InstallRoot;dependency_manifest_sha256=$SecureAcquisitionManifestSha256;archive_sha256=('a'*64);release_manifest_sha256=('b'*64)}
if(Test-Path (Join-Path $InstallRoot 'invalid.signal')){$commit.archive_sha256='c'*64}
[IO.File]::WriteAllText((Join-Path (Split-Path -Parent $CancelPath) 'commit.json'),($commit|ConvertTo-Json))
'after tail reader'
if(Test-Path (Join-Path $InstallRoot 'exit7.signal')){exit 7}
exit 0
'@)
foreach($case in @('success','exit7','cancel','invalid-commit')){
    $root=Join-Path $fixture $case;[IO.Directory]::CreateDirectory($root)|Out-Null
    if($case -eq 'exit7'){[IO.File]::WriteAllText((Join-Path $root 'exit7.signal'),'fixture')}
    if($case -eq 'invalid-commit'){[IO.File]::WriteAllText((Join-Path $root 'invalid.signal'),'fixture')}
    $invocation=Invoke-Args $root (Join-Path $fixture ('attempt-'+$case))
    $observedSupervisor=Start-Boundary $invocation
    $reader=$null
    try{
        Wait-File (Join-Path $root 'entered.log') $observedSupervisor
        $tail=Join-Path $invocation.AttemptDirectory 'tail.txt';Wait-File $tail $observedSupervisor
        if($case -eq 'success'){
            $unavailable=Join-Path $root 'reader-unavailable.txt';[IO.File]::WriteAllText($unavailable,'fixture')
            $exclusive=[IO.File]::Open($unavailable,'Open','ReadWrite','None')
            $rejected=$false;$watch=[Diagnostics.Stopwatch]::StartNew()
            try{Open-TailReader $unavailable $observedSupervisor 100|Out-Null}catch{$rejected=$_.Exception.Message -eq 'Tail reader could not be established while the actual supervisor was live.'}finally{$exclusive.Dispose()}
            Assert ($rejected -and $watch.ElapsedMilliseconds -lt 2000 -and !$observedSupervisor.HasExited) 'Unavailable reader was accepted, unbounded, or lost the live supervisor.'
        }
        # Model a wizard reader denying write sharing while actual supervisor polls.
        $reader=Open-TailReader $tail $observedSupervisor
        Start-Sleep -Milliseconds 900
        $blocked=$false;try{[IO.File]::WriteAllText($bootstrap,'changed')}catch{$blocked=$true}
        Assert $blocked 'Input lock was lost during live tail observation.'
        if($case -eq 'cancel'){
            & $helper @invocation -RequestCancellation
            Assert ($LASTEXITCODE -eq 0) 'Actual cancellation broker rejected precommit cancellation.'
        }
        [IO.File]::WriteAllText((Join-Path $root 'release.signal'),'release actual worker')
        Assert ($observedSupervisor.WaitForExit(30000)) 'Supervisor remains pending; fixture retained.'
        $observedSupervisor.WaitForExit();$exit=[int]$observedSupervisor.ExitCode
        $status=Get-Content (Join-Path $invocation.AttemptDirectory 'status.json') -Raw|ConvertFrom-Json
        if($case -eq 'invalid-commit'){
            Assert ($exit -ne 0) 'Invalid commit returned success.'
            Assert ([IO.File]::ReadAllText((Join-Path $invocation.AttemptDirectory 'stderr.log')).Contains('Build commit binding is invalid')) 'Commit validation error was lost.'
        }else{
            $expected=if($case -eq 'exit7'){7}elseif($case -eq 'cancel'){1223}else{0}
            Assert ($exit -eq $expected -and $status.status -eq 'TERMINAL' -and $status.exit_code -eq $expected) ('RED: tail reader prevented real terminal exit/status for '+$case+'; supervisor exit='+$exit+' status='+$status.status)
        }
        if($case -ne 'cancel'){Assert ([IO.File]::ReadAllText((Join-Path $invocation.AttemptDirectory 'stdout.log')).Contains('after tail reader')) 'Full stdout was lost.'}
    }finally{
        if($reader){$reader.Dispose()}
        [IO.File]::WriteAllText((Join-Path $root 'release.signal'),'release actual worker')
        Wait-Terminal $observedSupervisor|Out-Null
    }
    'PASS held wizard tail reader preserves actual worker result: '+$case
}
# Run the actual shared function for non-sharing failures; no worker or API mock.
$tokens=$null;$errors=$null
$ast=[Management.Automation.Language.Parser]::ParseFile($helper,[ref]$tokens,[ref]$errors)
Assert (!$errors.Count) 'Supervisor parse failed.'
foreach($node in $ast.FindAll({param($n)$n -is [Management.Automation.Language.FunctionDefinitionAst] -and $n.Name -in @('Assert-BuildPath','Save-BuildTail')},$true)){. ([scriptblock]::Create($node.Extent.Text))}
$AttemptDirectory=Join-Path $fixture 'non-sharing-failures';[IO.Directory]::CreateDirectory($AttemptDirectory,$acl)|Out-Null
foreach($name in @('stdout.log','stderr.log')){[IO.File]::WriteAllText((Join-Path $AttemptDirectory $name),'fixture')}
$tail=Join-Path $AttemptDirectory 'tail.txt';[IO.File]::WriteAllText($tail,'previous display frame')
$heldReader=[IO.File]::Open($tail,'Open','Read','Read')
try{Save-BuildTail;Assert ([IO.File]::ReadAllText($tail) -eq 'previous display frame') 'Held reader display frame changed.'}finally{$heldReader.Dispose()}
Save-BuildTail
Assert ([IO.File]::ReadAllText($tail).Contains("fixture`r`nfixture")) 'Display tail did not resume after reader release.'
[IO.File]::Delete($tail)
$tail=Join-Path $AttemptDirectory 'tail.txt';[IO.Directory]::CreateDirectory($tail)|Out-Null
$rejected=$false;try{Save-BuildTail}catch{$rejected=$true}
Assert $rejected 'Non-sharing tail directory failure was swallowed.'
[IO.Directory]::Delete($tail);[IO.File]::WriteAllText($tail,'preserve foreign-writable fixture')
$foreign=Get-Acl -LiteralPath $tail
$foreign.AddAccessRule([Security.AccessControl.FileSystemAccessRule]::new([Security.Principal.SecurityIdentifier]::new('S-1-1-0'),'Write','Allow'))
Set-Acl -LiteralPath $tail -AclObject $foreign
$rejected=$false;try{Save-BuildTail}catch{$rejected=$true}
Assert ($rejected -and [IO.File]::ReadAllText($tail) -eq 'preserve foreign-writable fixture') 'Tail path security failure was swallowed or mutated.'
'PASS non-sharing I/O and foreign-writable tail fail closed'
