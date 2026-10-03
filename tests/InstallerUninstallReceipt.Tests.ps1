$ErrorActionPreference='Stop'
function Assert($ok,$message){if(!$ok){throw $message}}
$helper=Join-Path $PSScriptRoot '../installer/uninstall-owned-release.ps1'
if(![IO.File]::Exists($helper)){throw 'RED: receipt-owned uninstall consumer missing.'}
. $helper
. (Join-Path $PSScriptRoot '../installer/write-setup-receipt.ps1')
. (Join-Path $PSScriptRoot '../installer/remove-owned-file.ps1')
$fixture=Join-Path $env:TEMP ('autoclip-uninstall-receipt-'+[guid]::NewGuid().ToString('N'))
$sid=[Security.Principal.WindowsIdentity]::GetCurrent().User
$acl=[Security.AccessControl.DirectorySecurity]::new();$acl.SetOwner($sid);$acl.SetAccessRuleProtection($true,$false)
foreach($id in @($sid.Value,'S-1-5-18','S-1-5-32-544')){$acl.AddAccessRule([Security.AccessControl.FileSystemAccessRule]::new([Security.Principal.SecurityIdentifier]::new($id),'FullControl','ContainerInherit,ObjectInherit','None','Allow'))}
[IO.Directory]::CreateDirectory($fixture,$acl)|Out-Null
function Row($name,$content){$path=Join-Path $fixture $name;[IO.File]::WriteAllText($path,$content);[pscustomobject]@{path=$name;bytes=(Get-Item $path).Length;sha256=(Get-FileHash $path).Hash.ToLowerInvariant()}}
$unchanged=Row 'owned.txt' 'first-party';$changed=Row 'changed.txt' 'original';$ads=Row 'ads.txt' 'original'
[IO.File]::WriteAllText((Join-Path $fixture 'changed.txt'),'modified')
Set-Content -LiteralPath (Join-Path $fixture 'ads.txt') -Stream personal -Value 'preserve'
[IO.File]::WriteAllText((Join-Path $fixture 'unknown.txt'),'personal')
[IO.Directory]::CreateDirectory((Join-Path $fixture 'empty'))|Out-Null
$result=Remove-ReceiptOwnedReleaseFiles -Root $fixture -Rows @($unchanged,$changed,$ads) -Directories @('empty')
Assert (![IO.File]::Exists((Join-Path $fixture 'owned.txt'))) 'Exact owned bytes were retained.'
Assert ([IO.File]::ReadAllText((Join-Path $fixture 'changed.txt')) -ceq 'modified') 'Modified file was lost.'
Assert ((Get-Content -LiteralPath (Join-Path $fixture 'ads.txt') -Stream personal -Raw).Trim() -ceq 'preserve') 'Observed ADS was lost.'
Assert ([IO.File]::ReadAllText((Join-Path $fixture 'unknown.txt')) -ceq 'personal') 'Unknown file was lost.'
Assert (![IO.Directory]::Exists((Join-Path $fixture 'empty'))) 'Owned empty directory was retained.'
Assert ($result.status -ceq 'PRESERVED' -and @($result.preserved).Count -eq 2) 'Preservation result is ambiguous.'
$later=Row 'later.txt' 'original'
$failed=$false;try{Remove-ReceiptOwnedReleaseFiles -Root $fixture -Rows @($later,@{path='../escape';bytes=0;sha256=('a'*64)}) -Directories @()|Out-Null}catch{$failed=$true}
Assert ($failed -and [IO.File]::Exists((Join-Path $fixture 'later.txt'))) 'Malformed row caused partial removal.'
$failed=$false;try{Remove-ReceiptOwnedReleaseFiles -Root $fixture -Rows @($later,$later) -Directories @()|Out-Null}catch{$failed=$true}
Assert ($failed -and [IO.File]::Exists((Join-Path $fixture 'later.txt'))) 'Duplicate inventory accepted.'
Write-Output ('PASS receipt-owned cleanup fixture '+$fixture)
$inherited=Join-Path $fixture 'inherited';[IO.Directory]::CreateDirectory($inherited)|Out-Null
$inheritedPath=Join-Path $inherited 'active.json';[IO.File]::WriteAllText($inheritedPath,'exact owned current selection')
$inheritedRow=@{path='active.json';bytes=(Get-Item $inheritedPath).Length;sha256=(Get-FileHash $inheritedPath).Hash.ToLowerInvariant()}
Assert (!(Get-Acl $inherited).AreAccessRulesProtected) 'Inherited root fixture was protected.'
Assert ((Remove-SetupOwnedFile -Root $inherited -Row $inheritedRow).status -ceq 'UNSAFE') 'Default protected-root rule was weakened.'
Assert ((Remove-SetupOwnedFile -Root $inherited -Row $inheritedRow -AllowInheritedRoot).status -ceq 'REMOVED') 'Exact validated state in trusted inherited base could not be removed.'
[IO.File]::WriteAllText($inheritedPath,'exact owned current selection')
$foreignAcl=Get-Acl $inheritedPath;$foreignAcl.AddAccessRule([Security.AccessControl.FileSystemAccessRule]::new([Security.Principal.SecurityIdentifier]::new('S-1-1-0'),'Write','Allow'));Set-Acl -LiteralPath $inheritedPath -AclObject $foreignAcl
Assert ((Remove-SetupOwnedFile -Root $inherited -Row $inheritedRow -AllowInheritedRoot).status -ceq 'UNSAFE') 'Inherited-root exception accepted foreign file writes.'

# Run the actual CLI in a native child. Only Windows folder discovery and the
# registry key location are redirected to isolated first-party fixture scopes.
# Receipt parsing, pins, ACLs, mutex, target lock, selection and removal are real.
$local=Join-Path $fixture 'local';$programs=Join-Path $fixture 'programs'
$base=Join-Path $local 'AutoClip';$setup=Join-Path $base 'Setup';$release='fixture-cpu';$root=Join-Path $base $release
foreach($directory in @($local,$programs,$base,$setup,(Join-Path $setup 'locks'),(Join-Path $setup 'installation-receipts'),$root,(Join-Path $programs 'AutoClip'))){[IO.Directory]::CreateDirectory($directory,$acl)|Out-Null}
# Preserve the architecture's ordinary trusted inherited parent authorities.
foreach($directory in @($base,(Join-Path $programs 'AutoClip'))){$inheritedAcl=[IO.Directory]::GetAccessControl($directory,[Security.AccessControl.AccessControlSections]::Access);$inheritedAcl.SetAccessRuleProtection($false,$true);[IO.Directory]::SetAccessControl($directory,$inheritedAcl);Assert (!(Get-Acl $directory).AreAccessRulesProtected) 'CLI parent did not inherit its trusted fixture authority.'}
$key='Software\AutoClipUninstallFixture\'+[guid]::NewGuid().ToString('N')
$originalKey='Software\Microsoft\Windows\CurrentVersion\Uninstall\{D7451842-48F4-487B-80E0-5C7E9E326342}_is1'
$registry=[Microsoft.Win32.RegistryKey]::OpenBaseKey([Microsoft.Win32.RegistryHive]::CurrentUser,[Microsoft.Win32.RegistryView]::Registry64)
$nativeKey=$registry.CreateSubKey($key)
$nativeKey.SetValue('InstallLocation',$setup+'\');$nativeKey.SetValue('UninstallString','"'+(Join-Path $setup 'unins000.exe')+'"');$nativeKey.SetValue('DisplayName','Inert first-party fixture')
$values=@($nativeKey.GetValueNames()|Sort-Object|ForEach-Object{[ordered]@{name=$_;kind=$nativeKey.GetValueKind($_).ToString();value=$nativeKey.GetValue($_)}})
$nativeKey.Dispose()
function FixtureRow($scope,$name,$content){$path=Join-Path $scope $name;[IO.Directory]::CreateDirectory([IO.Path]::GetDirectoryName($path))|Out-Null;[IO.File]::WriteAllText($path,$content);[ordered]@{path=$name;bytes=(Get-Item $path).Length;sha256=(Get-FileHash $path).Hash.ToLowerInvariant()}}
$releaseRows=@((FixtureRow $root 'owned.txt' 'first-party release'),(FixtureRow $root 'AutoClip.lnk' 'inert folder link'))
$setupRows=@()
foreach($name in @('unins000.exe','unins000.dat','notices/inno-setup-7.1.0-LICENSE.txt','notices/uv-0.12.19-LICENSE-MIT.txt','notices/uv-0.12.19-LICENSE-APACHE.txt','notices/setup-tool-sources.md')){$setupRows+=,(FixtureRow $setup $name ('inert '+$name))}
foreach($name in @('uninstall-owned-release.ps1','write-setup-receipt.ps1','remove-owned-file.ps1','run-source-build.ps1','update.ps1')){
    $source=if($name -eq 'update.ps1'){Join-Path $PSScriptRoot '../update.ps1'}else{Join-Path $PSScriptRoot ('../installer/'+$name)}
    $text=[IO.File]::ReadAllText($source)
    if($name -in @('uninstall-owned-release.ps1','run-source-build.ps1')){
        $text=$text.Replace('[Environment]::GetFolderPath([Environment+SpecialFolder]::LocalApplicationData)',("'"+$local.Replace("'","''")+"'"))
    }
    if($name -eq 'uninstall-owned-release.ps1'){
        $text=$text.Replace('[Environment]::GetFolderPath([Environment+SpecialFolder]::Programs)',("'"+$programs.Replace("'","''")+"'"))
        $text=$text.Replace($originalKey,$key)
    }
    $setupRows+=,(FixtureRow $setup $name $text)
}
$nativeExe=Join-Path $setup 'unins000.exe';[IO.File]::Delete($nativeExe)
Add-Type -TypeDefinition @'
using System;using System.IO;using System.Diagnostics;using System.Runtime.InteropServices;using Microsoft.Win32.SafeHandles;
public class InertNativeUninstall {
 [DllImport("kernel32.dll",SetLastError=true)] static extern bool SetFileTime(SafeFileHandle h,IntPtr creation,IntPtr access,ref long write);
 static string Quote(string s){return "\""+s.Replace("\"","\\\"")+"\"";}
 public static void Main(string[] args){
  string root=AppDomain.CurrentDomain.BaseDirectory, handoff=null,sha=null;
  foreach(string a in args){if(a.StartsWith("/AUTOCLIP-HANDOFF="))handoff=a.Substring(18).Trim('"');if(a.StartsWith("/AUTOCLIP-HANDOFF-SHA256="))sha=a.Substring(25);}
  File.WriteAllLines(Path.Combine(root,"last-native-arguments.txt"),args);
  // This is the actual Inno lifetime conflict: a different native process
  // owns a read/write, FileShare.None DAT handle throughout callbacks.
  using(var dat=File.Open(Path.Combine(root,"unins000.dat"),FileMode.Open,FileAccess.ReadWrite,FileShare.None)){
   string mode=File.ReadAllText(Path.Combine(root,"fixture-mode.txt"));
   if(mode=="metadata"){long time=DateTime.UtcNow.AddMinutes(1).ToFileTimeUtc();if(!SetFileTime(dat.SafeFileHandle,IntPtr.Zero,IntPtr.Zero,ref time))throw new System.ComponentModel.Win32Exception(Marshal.GetLastWin32Error());}
   string cli="-NoProfile -NonInteractive -File "+Quote(Path.Combine(root,"uninstall-owned-release.ps1"));
   foreach(string a in File.ReadAllLines(Path.Combine(root,"callback-arguments.txt")))cli+=" "+Quote(a);
   cli+=" -HandoffPath "+Quote(handoff)+" -HandoffSha256 "+sha;
   if(mode!="cleanup")cli+=" -Preflight";
   var info=new ProcessStartInfo(Path.Combine(Environment.GetFolderPath(Environment.SpecialFolder.System),"WindowsPowerShell\\v1.0\\powershell.exe"),cli);
   info.UseShellExecute=false;info.CreateNoWindow=true;info.RedirectStandardOutput=true;info.RedirectStandardError=true;
   using(var p=Process.Start(info)){string output=p.StandardOutput.ReadToEnd(),error=p.StandardError.ReadToEnd();p.WaitForExit();File.WriteAllText(Path.Combine(root,"callback.out"),output);File.WriteAllText(Path.Combine(root,"callback.err"),error);Environment.ExitCode=p.ExitCode;}
  }
 }
}
'@ -OutputAssembly $nativeExe -OutputType ConsoleApplication
$nativeRow=@($setupRows|Where-Object path -EQ 'unins000.exe')[0];$nativeRow.bytes=(Get-Item $nativeExe).Length;$nativeRow.sha256=(Get-FileHash $nativeExe).Hash.ToLowerInvariant()
[IO.File]::WriteAllText((Join-Path $setup 'fixture-mode.txt'),'preflight')
$shortcut=FixtureRow (Join-Path $programs 'AutoClip') 'AutoClip.lnk' 'inert start menu link'
$record=[ordered]@{schema_version=1;status='COMPLETE';context=@{release_id=$release;install_root=$root;recipient_sid=$sid.Value;profile='cpu';archive_sha256=('a'*64);release_manifest_sha256=('b'*64)};setup_root=$setup;release_files=$releaseRows;release_directories=@();setup_files=$setupRows;shortcuts=@(@{path=(Join-Path $root 'AutoClip.lnk');bytes=$releaseRows[1].bytes;sha256=$releaseRows[1].sha256},@{path=(Join-Path $programs 'AutoClip/AutoClip.lnk');bytes=$shortcut.bytes;sha256=$shortcut.sha256});registration=@{key=$key;view='Registry64';install_location=$setup+'\';uninstall_string='"'+(Join-Path $setup 'unins000.exe')+'"';native_uninstaller=(Join-Path $setup 'unins000.exe');values=$values;subkeys=@()}}
foreach($name in @('dependency_manifest_sha256','bootstrap_sha256','source_helper_sha256','health_helper_sha256')){$record.context[$name]='c'*64}
$record.setup_sha256='d'*64
$record.source_handoff=@{path=(Join-Path $root '.setup-source-ownership.json');bytes=0;sha256=('e'*64)}
$record.app_health=@{status='VERIFIED_HEALTH_HOME';install_root=$root;manifest_sha256=('b'*64);result_path=(Join-Path $fixture 'historical-health.json');bytes=0;sha256=('f'*64)}
$receipt=Join-Path $setup ('installation-receipts/'+$release+'.json')
$script:SetupReceiptLocks=[Collections.Generic.List[IO.FileStream]]::new()
$null=Write-SetupReceiptRecord $receipt $record
foreach($held in $script:SetupReceiptLocks){$held.Dispose()}
function Pin($path){(Get-FileHash -LiteralPath $path).Hash.ToLowerInvariant()}
$arguments=@{ReceiptPath=$receipt;ReceiptSha256=(Pin $receipt);ReleaseId=$release;InstallRoot=$root;ReceiptHelperSha256=(Pin (Join-Path $setup 'write-setup-receipt.ps1'));RemovalHelperSha256=(Pin (Join-Path $setup 'remove-owned-file.ps1'));SourceBuildHelperSha256=(Pin (Join-Path $setup 'run-source-build.ps1'));UpdaterSha256=(Pin (Join-Path $setup 'update.ps1'))}
function NativeCall($argsMap,[switch]$Failure){
    if($argsMap.LaunchNativeUninstall -and !$argsMap.Preflight){$callbackArgs=@();foreach($name in $argsMap.Keys){if($name -notin @('LaunchNativeUninstall','Preflight','NativeSilent')){$callbackArgs+=('-'+$name);$callbackArgs+=[string]$argsMap[$name]}};[IO.File]::WriteAllLines((Join-Path $setup 'callback-arguments.txt'),[string[]]$callbackArgs)}
    $cli=@('-NoProfile','-NonInteractive','-File',(Join-Path $setup 'uninstall-owned-release.ps1'))
    foreach($name in $argsMap.Keys){if($argsMap[$name] -is [bool]){if($argsMap[$name]){$cli+=('-'+$name)}}else{$cli+=('-'+$name);$cli+=[string]$argsMap[$name]}}
    $ErrorActionPreference='Continue';$output=@(& powershell.exe @cli 2>&1);$exit=$LASTEXITCODE;$ErrorActionPreference='Stop'
    Assert ($(if($Failure){$exit -ne 0}else{$exit -eq 0})) ('Native CLI exit '+$exit+': '+($output -join ' '))
    if(!$Failure){$result=($output -join "`n")|ConvertFrom-Json;if($result.status -ceq 'NATIVE_ORIGINAL_PROCESS_EXITED'){Assert (!$result.native_post_uninstall_observed) 'Original native process exit claimed final teardown evidence.';Get-Content (Join-Path $setup 'callback.out') -Raw|ConvertFrom-Json}else{$result}}
}
try{
    $fixturePreflight=@{}+$arguments;$fixturePreflight.Preflight=$true;$fixturePreflight.LaunchNativeUninstall=$true
    $fixtureResult=NativeCall $fixturePreflight
    Assert ($fixtureResult.status -ceq 'VERIFIED_UNINSTALL_PREFLIGHT') ('Actual preflight did not verify: '+($fixtureResult|ConvertTo-Json -Depth 8 -Compress))
    Assert ([IO.File]::Exists((Join-Path $root 'owned.txt'))) 'Preflight deleted release bytes.'
    $launch=@{}+$arguments;$launch.LaunchNativeUninstall=$true
    Assert ((NativeCall $launch).status -ceq 'VERIFIED_UNINSTALL_PREFLIGHT') 'Native exclusive DAT callback observation failed.'
    $nativeArgs=Get-Content (Join-Path $setup 'last-native-arguments.txt')
    $proofPath=($nativeArgs|Where-Object{$_ -like '/AUTOCLIP-HANDOFF=*'}).Substring(18).Trim('"')
    $replay=@{}+$arguments;$replay.Preflight=$true;$replay.HandoffPath=$proofPath;$replay.HandoffSha256=Pin $proofPath
    NativeCall $replay -Failure
    $proofRecord=Get-Content $proofPath -Raw|ConvertFrom-Json;$testParent=Get-Process -Id $PID
    $proofRecord.launcher_pid=$PID;$proofRecord.launcher_start=$testParent.StartTime.ToUniversalTime().ToString('o');$proofRecord.launcher_path=$testParent.Path
    [IO.File]::WriteAllText($proofPath,($proofRecord|ConvertTo-Json -Depth 12));$replay.HandoffSha256=Pin $proofPath;NativeCall $replay -Failure
    $datTime=(Get-Item (Join-Path $setup 'unins000.dat')).LastWriteTimeUtc
    [IO.File]::WriteAllText((Join-Path $setup 'fixture-mode.txt'),'metadata');NativeCall $launch -Failure
    Assert ([IO.File]::ReadAllText((Join-Path $setup 'callback.err')).Contains('Native file metadata changed after prelaunch verification.')) 'Metadata fixture failed outside the callback lifetime boundary.'
    [IO.File]::SetLastWriteTimeUtc((Join-Path $setup 'unins000.dat'),$datTime)
    [IO.File]::WriteAllText((Join-Path $setup 'fixture-mode.txt'),'preflight')
    $quiet=@{}+$launch;$quiet.NativeSilent=$true;Assert ((NativeCall $quiet).status -ceq 'VERIFIED_UNINSTALL_PREFLIGHT') 'Quiet native callback failed.'
    $quietArgs=Get-Content (Join-Path $setup 'last-native-arguments.txt');Assert ($quietArgs -contains '/VERYSILENT' -and $quietArgs -contains '/NORESTART') 'Quiet mode omitted fixed native arguments.'
    $wrong=@{}+$fixturePreflight;$wrong.ReceiptSha256='0'*64;NativeCall $wrong -Failure
    $wrong=@{}+$fixturePreflight;$wrong.RemovalHelperSha256='0'*64;NativeCall $wrong -Failure
    $before=[IO.File]::ReadAllText($receipt)
    $bad=$before|ConvertFrom-Json;$bad.context.recipient_sid='S-1-5-18';[IO.File]::WriteAllText($receipt,($bad|ConvertTo-Json -Depth 12));$wrong=@{}+$fixturePreflight;$wrong.ReceiptSha256=Pin $receipt;NativeCall $wrong -Failure
    [IO.File]::WriteAllText($receipt,$before)
    $bad=$before|ConvertFrom-Json;$bad.schema_version='1';[IO.File]::WriteAllText($receipt,($bad|ConvertTo-Json -Depth 12));$wrong=@{}+$fixturePreflight;$wrong.ReceiptSha256=Pin $receipt;NativeCall $wrong -Failure
    [IO.File]::WriteAllText($receipt,$before)
    $bad=$before|ConvertFrom-Json;$bad.context.PSObject.Properties.Remove('bootstrap_sha256');[IO.File]::WriteAllText($receipt,($bad|ConvertTo-Json -Depth 12));$wrong=@{}+$fixturePreflight;$wrong.ReceiptSha256=Pin $receipt;NativeCall $wrong -Failure
    [IO.File]::WriteAllText($receipt,$before)
    $nativePath=Join-Path $setup 'unins000.dat';$nativeBefore=[IO.File]::ReadAllText($nativePath);[IO.File]::WriteAllText($nativePath,'modified native output');NativeCall $fixturePreflight -Failure;[IO.File]::WriteAllText($nativePath,$nativeBefore)
    $updaterPath=Join-Path $setup 'update.ps1';$updaterBefore=[IO.File]::ReadAllText($updaterPath);[IO.File]::WriteAllText($updaterPath,'corrupt helper');NativeCall $fixturePreflight -Failure;[IO.File]::WriteAllText($updaterPath,$updaterBefore)
    $statePath=Join-Path $base 'active.json'
    [IO.File]::WriteAllText($statePath,(@{schema_version=1;current=@{release_id=$release;archive_sha256=('a'*64);manifest_sha256=('b'*64)};previous=@{release_id='keep-rollback'}}|ConvertTo-Json -Depth 5))
    NativeCall $fixturePreflight -Failure
    Assert ([IO.File]::Exists((Join-Path $root 'owned.txt'))) 'Rollback reference did not preserve release.'
    [IO.File]::WriteAllText($statePath,(@{schema_version=1;current=@{release_id='other-current'};previous=@{release_id=$release}}|ConvertTo-Json -Depth 5));NativeCall $fixturePreflight -Failure
    [IO.File]::WriteAllText($statePath,(@{schema_version=1;current=@{release_id='other-current'};previous=$null}|ConvertTo-Json -Depth 5))
    $appPath=Join-Path $base 'app-active.json';[IO.File]::WriteAllText($appPath,(@{schema_version=1;current=@{required_runtime=$release};previous=$null}|ConvertTo-Json -Depth 5));NativeCall $fixturePreflight -Failure;[IO.File]::Delete($appPath)
    [IO.File]::WriteAllText($statePath,(@{schema_version=1;current=@{release_id=$release;archive_sha256=('a'*64);manifest_sha256=('b'*64)};previous=$null}|ConvertTo-Json -Depth 5))
    $nativeKey=$registry.OpenSubKey($key,$true);$nativeKey.SetValue('UnknownUserValue','preserve');$nativeKey.Dispose();NativeCall $fixturePreflight -Failure
    $nativeKey=$registry.OpenSubKey($key,$true);$nativeKey.DeleteValue('UnknownUserValue');$nativeKey.Dispose()
    $nativeKey=$registry.OpenSubKey($key,$true);$child=$nativeKey.CreateSubKey('unknown');$child.Dispose();$nativeKey.Dispose();NativeCall $fixturePreflight -Failure
    $nativeKey=$registry.OpenSubKey($key,$true);$nativeKey.DeleteSubKey('unknown');$nativeKey.Dispose()
    # Actual inert first-party process, with the real root/command/owner/time
    # discovery boundary. It has no AutoClip application or vendor behavior.
    $scripts=Join-Path $root '.venv/Scripts';[IO.Directory]::CreateDirectory($scripts)|Out-Null
    $ownedProcessPath=Join-Path $scripts 'python.exe'
    Add-Type -TypeDefinition 'public class InertUninstallProcess { public static void Main(string[] args) { System.Threading.Thread.Sleep(60000); } }' -OutputAssembly $ownedProcessPath -OutputType ConsoleApplication
    $processRow=@{path='.venv/Scripts/python.exe';bytes=(Get-Item $ownedProcessPath).Length;sha256=(Pin $ownedProcessPath)}
    $record.release_files+=,$processRow;$record.release_directories=@('.venv','.venv/Scripts')
    [IO.File]::WriteAllText($receipt,($record|ConvertTo-Json -Depth 12));$arguments.ReceiptSha256=Pin $receipt
    $unknownProcess=Start-Process -FilePath $ownedProcessPath -ArgumentList '-m unrelated' -WindowStyle Hidden -PassThru
    [IO.File]::WriteAllText((Join-Path $setup 'fixture-mode.txt'),'cleanup');$arguments.LaunchNativeUninstall=$true
    try{NativeCall $arguments -Failure;Assert (!$unknownProcess.HasExited -and [IO.File]::Exists($statePath) -and [IO.File]::Exists((Join-Path $root 'owned.txt'))) 'Unknown release process or selected files were changed.'}finally{if(!$unknownProcess.HasExited){$unknownProcess.Kill();$unknownProcess.WaitForExit()}}
    $ownedProcess=Start-Process -FilePath $ownedProcessPath -ArgumentList '-m autoclip.desktop' -WindowStyle Hidden -PassThru
    # A real foreign read handle denies DELETE while preserving exact selected
    # bytes and trusted authority. The actual native callback must explain its
    # finite refusal outcome, without mutating selection or release files.
    $stateReadHandle=[IO.File]::Open($statePath,'Open','Read','Read')
    try{
        NativeCall $arguments -Failure
        $lockedDiagnostic=[IO.File]::ReadAllText((Join-Path $setup 'callback.err'))
        [IO.File]::WriteAllText((Join-Path $setup 'locked-selection-refusal.err'),$lockedDiagnostic)
        Assert ($lockedDiagnostic.Contains('outcome=LOCKED')) 'Locked selection refusal discarded the native primitive outcome.'
        Assert ([IO.File]::Exists($statePath) -and [IO.File]::Exists((Join-Path $root 'owned.txt'))) 'Locked selection refusal changed selected files.'
    }finally{$stateReadHandle.Dispose()}
    [IO.File]::Delete((Join-Path $root 'owned.txt'))
    $unknownRootFile=Join-Path $root 'personal.txt';[IO.File]::WriteAllText($unknownRootFile,'unknown root bytes')
    $result=NativeCall $arguments
    Assert ($result.status -ceq 'PRESERVED' -and $result.selection -ceq 'RESET' -and ![IO.File]::Exists($statePath) -and [IO.File]::ReadAllText($unknownRootFile) -ceq 'unknown root bytes') 'Actual cleanup/selection reset or root-only unknown preservation failed.'
    Assert ($ownedProcess.HasExited) 'Owned process remained running after cleanup.'
    [IO.File]::Delete($unknownRootFile)
    $retry=NativeCall $arguments
    Assert ($retry.status -ceq 'REMOVED') 'Missing release retry falsely failed or preserved.'
    Write-Output ('PASS actual native CLI authority, exact helpers/receipt/registry, rollback refusal, current-only reset, missing-file retry '+$fixture)
}finally{$registry.DeleteSubKey($key);$registry.Dispose()}
