$ErrorActionPreference='Stop'
$repo=Split-Path -Parent $PSScriptRoot
$helper=Join-Path $repo 'installer/write-setup-receipt.ps1'
$native=Join-Path $env:WINDIR 'System32/WindowsPowerShell/v1.0/powershell.exe'
$fixture=Join-Path $env:TEMP ('autoclip-finalize-cli-'+[guid]::NewGuid().ToString('N'))
$acl=[Security.AccessControl.DirectorySecurity]::new();$sid=[Security.Principal.WindowsIdentity]::GetCurrent().User
$acl.SetOwner($sid);$acl.SetAccessRuleProtection($true,$false)
foreach($id in @($sid.Value,'S-1-5-18','S-1-5-32-544')){$acl.AddAccessRule([Security.AccessControl.FileSystemAccessRule]::new([Security.Principal.SecurityIdentifier]::new($id),'FullControl','ContainerInherit,ObjectInherit','None','Allow'))}
[IO.Directory]::CreateDirectory($fixture,$acl)|Out-Null
function Run-Finalize([string[]]$Arguments,[string]$Name,[string]$ExpectedError){
    $output=Join-Path $fixture ($Name+'.out');$error=Join-Path $fixture ($Name+'.err')
    $cli=@('-NoProfile','-NonInteractive','-File',('"'+$helper+'"'))+$Arguments
    $p=Start-Process -FilePath $native -ArgumentList ($cli -join ' ') -WindowStyle Hidden -PassThru -RedirectStandardOutput $output -RedirectStandardError $error
    $handle=$p.Handle;$started=$p.StartTime.ToUniversalTime().ToString('o')
    $p.WaitForExit();$code=[int]$p.ExitCode;$p.Dispose()
    if($code -eq 0){throw ('RED: invalid finalization returned success: '+$Name)}
    if(![IO.File]::ReadAllText($error).Contains($ExpectedError)){throw ('Wrong failure boundary: '+$Name+'; '+[IO.File]::ReadAllText($error))}
    'PASS rejected '+$Name+'; exit='+$code+'; original_handle='+$handle+'; start='+$started
}
Run-Finalize @('-Finalize','-RequestPath',('"'+(Join-Path $fixture 'missing.json')+'"'),'-RequestSha256',('a'*64)) 'missing-request' 'Receipt regular file is missing.'
$request=Join-Path $fixture 'invalid.json';[IO.File]::WriteAllText($request,'{"schema_version":999}')
$pin=(Get-FileHash -LiteralPath $request).Hash.ToLowerInvariant()
Run-Finalize @('-Finalize','-RequestPath',('"'+$request+'"'),'-RequestSha256',$pin) 'unsupported-schema' 'Unsupported finalization request schema.'
Run-Finalize @('-Finalize','-RequestPath',('"'+$request+'"'),'-RequestSha256',('b'*64)) 'changed-pin' 'Receipt file SHA256 differs.'
if([IO.File]::ReadAllText($request) -cne '{"schema_version":999}' -or @(Get-ChildItem -LiteralPath $fixture -Recurse -Filter '*.receipt.json').Count){throw 'Rejected request mutated data or published completion.'}
'PASS actual CLI fails closed without native installation, registry mutation or receipt publication'

# Build genuine source/health/launcher provenance with the existing real
# producer fixture, then exercise Finalize itself in an isolated native child.
. (Join-Path $PSScriptRoot 'InstallerSetupReceipt.Tests.ps1')
$entryLocal=Join-Path $fixture 'entry-local';$entryPrograms=Join-Path $fixture 'entry-programs';$entrySetup=Join-Path $entryLocal 'AutoClip/Setup';$entryLogs=Join-Path $entrySetup 'logs/attempt'
foreach($path in @($entryLocal,$entryPrograms,$entrySetup,$entryLogs,(Join-Path $entryPrograms 'AutoClip'),(Join-Path $entrySetup 'notices'))){[IO.Directory]::CreateDirectory($path,$acl)|Out-Null}
$entryKey='Software\AutoClipFinalizeFixture\'+[guid]::NewGuid().ToString('N')
$originalKey='Software\Microsoft\Windows\CurrentVersion\Uninstall\{D7451842-48F4-487B-80E0-5C7E9E326342}_is1'
$helperRows=@()
foreach($name in @('uninstall-owned-release.ps1','write-setup-receipt.ps1','remove-owned-file.ps1','run-source-build.ps1','update.ps1')){
    $path=if($name -eq 'update.ps1'){Join-Path $repo $name}else{Join-Path $repo ('installer/'+$name)}
    $text=[IO.File]::ReadAllText($path)
    if($name -in @('write-setup-receipt.ps1','run-source-build.ps1')){$text=$text.Replace('[Environment]::GetFolderPath([Environment+SpecialFolder]::LocalApplicationData)',("'"+$entryLocal.Replace("'","''")+"'"))}
    if($name -eq 'write-setup-receipt.ps1'){$text=$text.Replace('[Environment]::GetFolderPath([Environment+SpecialFolder]::Programs)',("'"+$entryPrograms.Replace("'","''")+"'"));$text=$text.Replace($originalKey,$entryKey)}
    $target=Join-Path $entrySetup $name;[IO.File]::WriteAllText($target,$text);$helperRows+=@{path=$name;bytes=(Get-Item $target).Length;sha256=(Pin $target)}
}
$entryHelper=Join-Path $entrySetup 'write-setup-receipt.ps1'
$context.source_helper_sha256=Pin $entryHelper
$handoffPath=Join-Path $context.install_root '.setup-source-ownership.json'
$handoff=Get-Content $handoffPath -Raw|ConvertFrom-Json;$handoff.context.source_helper_sha256=$context.source_helper_sha256
[IO.File]::WriteAllText($handoffPath,($handoff|ConvertTo-Json -Depth 16))
$noticeRows=@()
foreach($name in @('notices/inno-setup-7.1.0-LICENSE.txt','notices/uv-0.12.19-LICENSE-MIT.txt','notices/uv-0.12.19-LICENSE-APACHE.txt','notices/setup-tool-sources.md')){$path=Join-Path $entrySetup $name;[IO.File]::WriteAllText($path,'inert notice '+$name);$noticeRows+=@{path=$name;bytes=(Get-Item $path).Length;sha256=(Pin $path)}}
foreach($name in @('unins000.exe','unins000.dat')){[IO.File]::WriteAllText((Join-Path $entrySetup $name),'inert native '+$name)}
$entryLink=Join-Path $entryPrograms 'AutoClip/AutoClip.lnk';Copy-Item -LiteralPath (Join-Path $context.install_root 'AutoClip.lnk') -Destination $entryLink
$uninstallCommand='inert compiled setup loader fixture; never execute';$quietCommand=$uninstallCommand+' quiet'
$registry=[Microsoft.Win32.RegistryKey]::OpenBaseKey([Microsoft.Win32.RegistryHive]::CurrentUser,[Microsoft.Win32.RegistryView]::Registry64)
$key=$registry.CreateSubKey($entryKey);$key.SetValue('InstallLocation',$entrySetup+'\');$key.SetValue('UninstallString',$uninstallCommand);$key.SetValue('QuietUninstallString',$quietCommand);$key.SetValue('DisplayName','Inert AutoClip finalization fixture');$key.Dispose()
$request=Join-Path $entryLogs 'final-request.json'
$requestRecord=@{schema_version=1;context=$context;handoff_sha256=(Pin $handoffPath);setup_path=$setupExe;setup_sha256=(Pin $setupExe);source_build_helper_sha256=(Pin (Join-Path $entrySetup 'run-source-build.ps1'));notices=$noticeRows;helpers=$helperRows;native_shortcut_path=$entryLink;native_shortcut_sha256=(Pin $entryLink);native_uninstaller=(Join-Path $entrySetup 'unins000.exe');uninstall_command=$uninstallCommand;quiet_uninstall_command=$quietCommand}
[IO.File]::WriteAllText($request,($requestRecord|ConvertTo-Json -Depth 12))
try{
    $out=Join-Path $fixture 'entry.out';$err=Join-Path $fixture 'entry.err'
    $cli='-NoProfile -NonInteractive -File "'+$entryHelper+'" -Finalize -RequestPath "'+$request+'" -RequestSha256 '+(Pin $request)
    $entryPowerShell=Join-Path $env:WINDIR 'System32/WindowsPowerShell/v1.0/powershell.exe'
    $child=Start-Process -FilePath $entryPowerShell -ArgumentList $cli -WindowStyle Hidden -PassThru -RedirectStandardOutput $out -RedirectStandardError $err
    $null=$child.Handle;$child.WaitForExit();$code=$child.ExitCode;$child.Dispose()
    if($code -ne 0){throw ('Actual Finalize entry failed: '+[IO.File]::ReadAllText($err))}
    $result=Get-Content $out -Raw|ConvertFrom-Json
    $record=Get-Content $result.path -Raw|ConvertFrom-Json
    if($result.status -cne 'COMPLETE' -or $result.sha256 -cne (Pin $result.path) -or $record.setup_files.Count -ne 11 -or $record.registration.values.Count -ne 4 -or $record.registration.native_uninstaller -ine $requestRecord.native_uninstaller -or $record.registration.quiet_uninstall_string -cne $quietCommand){throw 'Actual Finalize receipt/helpers/registration bindings differ.'}
    if(!(Test-Path -LiteralPath ($request+'.receipt.json'))){throw 'Actual Finalize result handoff missing.'}
    'PASS actual positive Finalize CLI: real protected request/source provenance, five helpers, native pair, both loader commands, complete Registry64 values, final receipt/hash/result handoff'
}finally{$registry.DeleteSubKey($entryKey);$registry.Dispose()}
