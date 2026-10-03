$ErrorActionPreference='Stop'
function Assert($ok,$message){if(!$ok){throw $message}}
$fixture=Join-Path $env:TEMP ('autoclip-owned-removal-'+[guid]::NewGuid().ToString('N'))
$sid=[Security.Principal.WindowsIdentity]::GetCurrent().User
Assert (!([Security.Principal.WindowsPrincipal]::new([Security.Principal.WindowsIdentity]::GetCurrent())).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) 'Run ordinary-user only.'
$acl=[Security.AccessControl.DirectorySecurity]::new();$acl.SetOwner($sid);$acl.SetAccessRuleProtection($true,$false)
foreach($id in @($sid.Value,'S-1-5-18','S-1-5-32-544')){$acl.AddAccessRule([Security.AccessControl.FileSystemAccessRule]::new([Security.Principal.SecurityIdentifier]::new($id),'FullControl','ContainerInherit,ObjectInherit','None','Allow'))}
[IO.Directory]::CreateDirectory($fixture,$acl)|Out-Null
Write-Output ('FIXTURE '+$fixture)
$helper=Join-Path $PSScriptRoot '../installer/remove-owned-file.ps1'
if(![IO.File]::Exists($helper)){throw 'RED: owned-file removal implementation missing.'}
. $helper
Add-Type -TypeDefinition @'
using System;
using System.Runtime.InteropServices;
using Microsoft.Win32.SafeHandles;
public static class OwnedRemovalDirectoryProbe {
    [DllImport("kernel32.dll",CharSet=CharSet.Unicode,SetLastError=true)]
    static extern SafeFileHandle CreateFileW(string path,uint access,uint share,IntPtr security,uint creation,uint flags,IntPtr template);
    public static int WriteOpen(string path) {
        using(var handle=CreateFileW(path,0x40000000,7,IntPtr.Zero,3,0x02200000,IntPtr.Zero)) {
            return handle.IsInvalid ? Marshal.GetLastWin32Error() : 0;
        }
    }
    public static int WriteAds(string path) {
        using(var handle=CreateFileW(path,0x40000000,7,IntPtr.Zero,4,0,IntPtr.Zero)) {
            if(handle.IsInvalid)return Marshal.GetLastWin32Error();
            using(var stream=new System.IO.FileStream(handle,System.IO.FileAccess.Write)) {
                byte[] data=System.Text.Encoding.UTF8.GetBytes("inert-secret");stream.Write(data,0,data.Length);
            }
            return 0;
        }
    }
}
'@
function Row($name,$text){$path=Join-Path $fixture $name;[IO.Directory]::CreateDirectory([IO.Path]::GetDirectoryName($path))|Out-Null;[IO.File]::WriteAllText($path,$text);@{path=$name;bytes=(Get-Item -LiteralPath $path).Length;sha256=(Get-FileHash -LiteralPath $path).Hash.ToLowerInvariant()}}
function Outcome($row,$expected){$result=Remove-SetupOwnedFile -Root $fixture -Row $row;Assert ($result.status -ceq $expected) ('Expected '+$expected+', got '+($result|ConvertTo-Json -Compress));Write-Output ($row.path+' '+$result.status)}
$row=Row 'nested/unchanged.txt' 'inert first-party bytes';Outcome $row 'REMOVED';Assert (![IO.File]::Exists((Join-Path $fixture $row.path))) 'Unchanged file retained.'
$row=Row 'zero.txt' '';Outcome $row 'REMOVED';Outcome $row 'MISSING'
$row=Row 'changed.txt' 'original';[IO.File]::WriteAllText((Join-Path $fixture $row.path),'changed');Outcome $row 'CHANGED';Assert ([IO.File]::ReadAllText((Join-Path $fixture $row.path)) -ceq 'changed') 'Changed file lost.'
$row=Row 'same-size.txt' 'original';[IO.File]::WriteAllText((Join-Path $fixture $row.path),'modified');Outcome $row 'CHANGED'
# Preserve an ADS actually created during default-stream hashing with compatible sharing.
$row=Row 'during-hash.bin' ''; $path=Join-Path $fixture $row.path
$stream=[IO.File]::Open($path,'Open','Write','None');try{$stream.SetLength(536870912)}finally{$stream.Dispose()}
$row.bytes=(Get-Item -LiteralPath $path).Length;$row.sha256=(Get-FileHash -LiteralPath $path).Hash.ToLowerInvariant()
$worker=[PowerShell]::Create();$null=$worker.AddScript('param($root,$path,$bytes,$sha) [AutoClip.OwnedFileRemoval]::Remove($root,$path,$bytes,$sha)').AddArgument($fixture).AddArgument($row.path).AddArgument($row.bytes).AddArgument($row.sha256)
$operation=$worker.BeginInvoke()
try{
    Start-Sleep -Milliseconds 250
    Assert (!$operation.IsCompleted) 'No observed during-hash ADS overlap.'
    $blocked=$false;try{$probe=[IO.File]::Open($path,'Open','Write','ReadWrite');$probe.Dispose()}catch [IO.IOException]{$blocked=($_.Exception.HResult -band 65535) -eq 32}
    Assert $blocked 'Default stream was not locked during ADS probe.'
    $adsResult=[OwnedRemovalDirectoryProbe]::WriteAds($path+':secret');Write-Output ('During-hash ADS native write Win32 '+$adsResult)
    Assert ($adsResult -eq 0) 'Compatible ADS writer did not actually write.'
    Assert (!$operation.IsCompleted) 'ADS write did not overlap hashing.'
    $result=$worker.EndInvoke($operation);Write-Output ('During-hash ADS removal result '+($result -join ','))
    Assert ($result.Count -eq 1 -and $result[0] -ceq 'UNSAFE') 'During-hash ADS file must be preserved.'
    Assert ([IO.File]::Exists($path) -and (Get-Content -LiteralPath $path -Stream secret -Raw) -ceq 'inert-secret') 'During-hash ADS contents lost.'
}finally{$worker.Dispose()}
$row=Row 'alternate-stream.txt' 'unchanged default bytes'
Set-Content -LiteralPath (Join-Path $fixture $row.path) -Stream secret -Value 'inert-secret'
Outcome $row 'UNSAFE'
Assert ((Get-Content -LiteralPath (Join-Path $fixture $row.path) -Stream secret -Raw).Trim() -ceq 'inert-secret') 'Unknown alternate stream lost.'
$row=Row 'locked.txt' 'locked';$lock=[IO.File]::Open((Join-Path $fixture $row.path),'Open','ReadWrite','None');try{Outcome $row 'LOCKED'}finally{$lock.Dispose()};Outcome $row 'REMOVED'
foreach($name in @('../escape','nested/../escape','/absolute','C:/escape','nested\escape','NUL.txt','bad.','bad ','a//b','a:stream')){Outcome @{path=$name;bytes=0;sha256=('a'*64)} 'INVALID'}
foreach($bytes in @(-1,1.0,'1',$true,$null)){Outcome @{path='changed.txt';bytes=$bytes;sha256=('a'*64)} 'INVALID'}
Outcome @{path='changed.txt';bytes=7;sha256=('A'*64)} 'INVALID'
Outcome @{path='changed.txt';bytes=7;sha256=('a'*64);extra=1} 'INVALID'
foreach($root in @('relative','C:\','\\server\share','C:\safe\..\escape')){Assert ((Remove-SetupOwnedFile -Root $root -Row @{path='x';bytes=0;sha256=('a'*64)}).status -ceq 'INVALID') 'Unsafe root accepted.'}
$row=Row 'directory/child.txt' 'preserve';Outcome @{path='directory';bytes=0;sha256=('a'*64)} 'UNSAFE'
$junction=Join-Path $fixture 'junction';New-Item -ItemType Junction -Path $junction -Target (Join-Path $fixture 'directory')|Out-Null
Outcome @{path='junction/child.txt';bytes=$row.bytes;sha256=$row.sha256} 'UNSAFE';Assert ([IO.File]::Exists((Join-Path $fixture 'directory/child.txt'))) 'Junction target lost.'
Assert ((Remove-SetupOwnedFile -Root $junction -Row @{path='child.txt';bytes=$row.bytes;sha256=$row.sha256}).status -ceq 'UNSAFE') 'Reparse root accepted.'
$unprotected=Join-Path $fixture 'inherited-root';[IO.Directory]::CreateDirectory($unprotected)|Out-Null
Assert ((Remove-SetupOwnedFile -Root $unprotected -Row @{path='missing.txt';bytes=0;sha256=('a'*64)}).status -ceq 'UNSAFE') 'Unprotected existing root accepted.'
$row=Row 'hardlink.txt' 'preserve';New-Item -ItemType HardLink -Path (Join-Path $fixture 'hardlink-alias.txt') -Target (Join-Path $fixture $row.path)|Out-Null;Outcome $row 'UNSAFE'
$row=Row 'foreign-write.txt' 'preserve';$foreign=Get-Acl -LiteralPath (Join-Path $fixture $row.path);$foreign.AddAccessRule([Security.AccessControl.FileSystemAccessRule]::new([Security.Principal.SecurityIdentifier]::new('S-1-1-0'),'Write','Allow'));Set-Acl -LiteralPath (Join-Path $fixture $row.path) -AclObject $foreign;Outcome $row 'UNSAFE'
$row=Row 'foreign-directory/child.txt' 'preserve';$directory=Join-Path $fixture 'foreign-directory';$foreign=Get-Acl -LiteralPath $directory;$foreign.AddAccessRule([Security.AccessControl.FileSystemAccessRule]::new([Security.Principal.SecurityIdentifier]::new('S-1-1-0'),'Write','Allow'));Set-Acl -LiteralPath $directory -AclObject $foreign;Outcome $row 'UNSAFE'
# A refusal must release both file and ancestor handles.
[IO.File]::WriteAllText((Join-Path $fixture 'changed.txt'),'post-refusal write')
[IO.Directory]::Move((Join-Path $fixture 'directory'),(Join-Path $fixture 'directory-renamed'))
# Exercise real overlapping operations while the production helper hashes.
# An inert 512 MiB zero-filled file gives the observer time; no production test hook.
$replacement=Row 'replacement.txt' 'inert replacement attempt'
$row=Row 'race/large.bin' '';$path=Join-Path $fixture $row.path
$stream=[IO.File]::Open($path,'Open','Write','None');try{$stream.SetLength(536870912)}finally{$stream.Dispose()}
$row.bytes=(Get-Item -LiteralPath $path).Length;$row.sha256=(Get-FileHash -LiteralPath $path).Hash.ToLowerInvariant()
Assert ([OwnedRemovalDirectoryProbe]::WriteOpen((Join-Path $fixture 'race')) -eq 0) 'Baseline directory write open failed.'
$worker=[PowerShell]::Create();$null=$worker.AddScript('param($root,$path,$bytes,$sha) [AutoClip.OwnedFileRemoval]::Remove($root,$path,$bytes,$sha)').AddArgument($fixture).AddArgument($row.path).AddArgument($row.bytes).AddArgument($row.sha256)
$operation=$worker.BeginInvoke();$observed=$false
try{
    # Do not transiently hold a writer during the remover's initial open.
    Start-Sleep -Milliseconds 250
    try{$probe=[IO.File]::Open($path,'Open','Write','ReadWrite');$probe.Dispose()}catch [IO.IOException]{$observed=($_.Exception.HResult -band 65535) -eq 32}
    Assert $observed 'Did not observe actual same-handle write exclusion.'
    Assert (!$operation.IsCompleted) 'Hash completed before directory write probe.'
    $directoryWrite=[OwnedRemovalDirectoryProbe]::WriteOpen((Join-Path $fixture 'race'));Write-Output ('Directory GENERIC_WRITE probe Win32 '+$directoryWrite)
    Assert ($directoryWrite -eq 32) 'Directory write/reparse-capable handle was not excluded.'
    Write-Output 'Directory GENERIC_WRITE refusal Win32 32'
    foreach($action in @({[IO.File]::Move($path,$path+'.renamed')},{[IO.File]::Replace((Join-Path $fixture 'replacement.txt'),$path,[NullString]::Value)},{[IO.Directory]::Move((Join-Path $fixture 'race'),(Join-Path $fixture 'race-renamed'))},{[IO.Directory]::Move($fixture,$fixture+'-renamed')})){
        Assert (!$operation.IsCompleted) 'Hash completed before concurrency probes.'
        $blocked=$false;try{& $action}catch{$code=$_.Exception.GetBaseException().HResult -band 65535;Write-Output ('Rename refusal Win32 '+$code);$blocked=$code -in @(5,32)};Assert $blocked 'File/ancestor rename was not excluded while hashing.'
    }
    $result=$worker.EndInvoke($operation);Assert ($result.Count -eq 1 -and $result[0] -ceq 'REMOVED') 'Concurrent remover did not remove unchanged file.'
    Assert (![IO.File]::Exists($path)) 'Concurrent deletion did not complete.'
    Assert ([IO.File]::ReadAllText((Join-Path $fixture 'replacement.txt')) -ceq 'inert replacement attempt') 'Blocked replacement source lost.'
}finally{$worker.Dispose()}
[IO.File]::WriteAllText($path,'new post-delete file');[IO.Directory]::Move((Join-Path $fixture 'race'),(Join-Path $fixture 'race-after'))
Assert ([OwnedRemovalDirectoryProbe]::WriteOpen((Join-Path $fixture 'race-after')) -eq 0) 'Directory handle retained after disposition.'
Write-Output 'PASS actual write/file rename/ancestor rename exclusion and handle release.'
Write-Output 'PASS owned-file removal; fixtures preserved.'
