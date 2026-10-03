$ErrorActionPreference='Stop'
$repo=Split-Path -Parent $PSScriptRoot
$tokens=$null; $errors=$null
$ast=[Management.Automation.Language.Parser]::ParseFile((Join-Path $repo 'install.ps1'),[ref]$tokens,[ref]$errors)
if($errors.Count){throw 'Installer parser failed.'}
foreach($node in $ast.FindAll({param($n)$n -is [Management.Automation.Language.FunctionDefinitionAst] -and $n.Name -in @('Install-AutoClipLaunchers','Assert-AutoClipSecurePath','Assert-AutoClipMsysProtectedPath','Read-AutoClipSecureInput','Test-AutoClipOwnedLauncher','Get-AutoClipLauncherPin','Write-AutoClipCompletionFile')},$true)){. ([scriptblock]::Create($node.Extent.Text))}
$completion=$ast.FindAll({param($n)$n -is [Management.Automation.Language.AssignmentStatementAst] -and $n.Left.Extent.Text -eq '$completionAction'},$true)
if($completion.Count -ne 1){throw 'Actual completion action missing.'}
. ([scriptblock]::Create($completion[0].Extent.Text))
function Assert($value,$message){if(-not $value){throw $message}}
$fixture=Join-Path $env:TEMP ('autoclip-completion-'+[guid]::NewGuid().ToString('N'))
[IO.Directory]::CreateDirectory($fixture)|Out-Null
$acl=[Security.AccessControl.DirectorySecurity]::new();$sid=[Security.Principal.WindowsIdentity]::GetCurrent().User
$acl.SetOwner($sid);$acl.SetAccessRuleProtection($true,$false)
foreach($id in @($sid.Value,'S-1-5-18','S-1-5-32-544')){$acl.AddAccessRule([Security.AccessControl.FileSystemAccessRule]::new([Security.Principal.SecurityIdentifier]::new($id),'FullControl','ContainerInherit,ObjectInherit','None','Allow'))}
Set-Acl -LiteralPath $fixture -AclObject $acl
$InstallRoot=Join-Path $fixture 'missing-launcher-inputs';[IO.Directory]::CreateDirectory($InstallRoot)|Out-Null
$expectedArchiveSha256='a'*64; $expectedManifestSha256='b'*64; $SkipDesktopShortcut=$true
$failed=$false;try{& $completionAction}catch{$failed=$true}
Assert ($failed -and -not [IO.File]::Exists((Join-Path $InstallRoot '.install-complete'))) 'RED: required launcher failure was swallowed or left a completion marker.'
'PASS required launcher failure propagates without marker'
function New-CompletionRoot($name) {
    $root=Join-Path $fixture $name
    [IO.Directory]::CreateDirectory((Join-Path $root '.venv/Scripts'))|Out-Null
    [IO.File]::WriteAllText((Join-Path $root '.venv/Scripts/pythonw.exe'),'first-party fixture; never execute')
    [IO.File]::WriteAllText((Join-Path $root 'Start-AutoClip.ps1'),'# first party fixture')
    [IO.File]::WriteAllText((Join-Path $root 'release-manifest.json'),'{}')
    [IO.File]::WriteAllText((Join-Path $root 'native-build-receipt.json'),'{"profile":"cpu","installed_files":[]}')
    return $root
}
$source=[IO.File]::ReadAllText((Join-Path $repo 'install.ps1'))
$scanStart=$source.IndexOf('    if ($resumeIncomplete) {')
$scanEnd=$source.IndexOf("    . (Join-Path `$InstallRoot 'upstream-assets.ps1')",$scanStart)
$scan=[scriptblock]::Create($source.Substring($scanStart,$scanEnd-$scanStart))
$earlyStart=$source.IndexOf('$resumeIncomplete = $false')
$earlyEnd=$source.IndexOf('$ffmpegContext = $null',$earlyStart)
$early=[scriptblock]::Create($source.Substring($earlyStart,$earlyEnd-$earlyStart))
$InstallRoot=New-CompletionRoot 'marker-failure'
$expectedManifestSha256=(Get-FileHash (Join-Path $InstallRoot 'release-manifest.json')).Hash.ToLowerInvariant()
$realWriter=(Get-Item Function:Write-AutoClipCompletionFile).ScriptBlock
& {
    function Write-AutoClipCompletionFile($Path,[byte[]]$Bytes,[switch]$ReplaceExisting) {
        if([IO.Path]::GetFileName($Path) -ne '.install-complete'){ & $realWriter $Path $Bytes -ReplaceExisting:$ReplaceExisting;return }
        $original=Get-Acl -LiteralPath $InstallRoot
        $denied=Get-Acl -LiteralPath $InstallRoot
        $denied.AddAccessRule([Security.AccessControl.FileSystemAccessRule]::new($sid,'WriteData','Deny'))
        Set-Acl -LiteralPath $InstallRoot -AclObject $denied
        try{& $realWriter $Path $Bytes}finally{Set-Acl -LiteralPath $InstallRoot -AclObject $original}
    }
    $failed=$false;try{& $completionAction}catch{$failed=$true}
    Assert ($failed -and -not [IO.File]::Exists((Join-Path $InstallRoot '.install-complete'))) 'Marker failure left a marker or did not propagate.'
}
Assert (Test-AutoClipOwnedLauncher $InstallRoot) 'Marker failure did not retain exact authenticated owned launcher.'
$PrerequisitesOnly=$false
. $early
Assert $resumeIncomplete 'Matching partial root did not remain retryable.'
$rootFull=[IO.Path]::GetFullPath($InstallRoot).TrimEnd('\')+'\'
$expectedFiles=[Collections.Generic.HashSet[string]]::new([StringComparer]::OrdinalIgnoreCase)
[void]$expectedFiles.Add('release-manifest.json');[void]$expectedFiles.Add('Start-AutoClip.ps1')
$ffmpegContext=$null
. $scan
Assert ($retainedLauncherPin.sha256 -eq (Get-FileHash (Join-Path $InstallRoot 'AutoClip.lnk')).Hash.ToLowerInvariant()) 'Actual retry scan did not retain owned output pin.'
$NativeBuildRoot=Join-Path $fixture 'fresh-native-receipt';[IO.Directory]::CreateDirectory($NativeBuildRoot)|Out-Null
[IO.File]::WriteAllText((Join-Path $NativeBuildRoot 'native-build-receipt.json'),'{"profile":"cpu","installed_files":[]}')
$copyStart=$source.IndexOf('    $nativeReceiptBytes =')
$copyEnd=$source.IndexOf('    $nvidiaWheelCount =',$copyStart)
& ([scriptblock]::Create($source.Substring($copyStart,$copyEnd-$copyStart)))
Assert (Test-AutoClipOwnedLauncher $InstallRoot) 'Refreshing native receipt lost authenticated retained launcher ownership.'
& $completionAction
Assert ([IO.File]::ReadAllText((Join-Path $InstallRoot '.install-complete')) -eq $expectedArchiveSha256) 'Retry did not commit marker after validated launcher.'
'PASS real denied marker write propagates; exact pinned shortcut passes actual matching-root retry'
$InstallRoot=New-CompletionRoot 'foreign-output'
$expectedManifestSha256=(Get-FileHash (Join-Path $InstallRoot 'release-manifest.json')).Hash.ToLowerInvariant()
Install-AutoClipLaunchers -InstallRoot $InstallRoot -SkipDesktopShortcut
Assert (-not (Test-AutoClipOwnedLauncher $InstallRoot)) 'Unrecorded launcher was treated as owned.'
$foreignBytes=[IO.File]::ReadAllBytes((Join-Path $InstallRoot 'AutoClip.lnk'))
$failed=$false;try{& $completionAction}catch{$failed=$true}
Assert ($failed -and [Convert]::ToBase64String($foreignBytes) -eq [Convert]::ToBase64String([IO.File]::ReadAllBytes((Join-Path $InstallRoot 'AutoClip.lnk')))) 'Foreign launcher was overwritten.'
'PASS unrecorded real shortcut is preserved and blocks completion'
$InstallRoot=New-CompletionRoot 'modified-output'
& $completionAction
[IO.File]::WriteAllText((Join-Path $InstallRoot 'AutoClip.lnk'),'modified recipient data')
$failed=$false;try{Test-AutoClipOwnedLauncher $InstallRoot|Out-Null}catch{$failed=$true}
Assert ($failed -or -not(Test-AutoClipOwnedLauncher $InstallRoot)) 'Modified output was accepted.'
Assert ([IO.File]::ReadAllText((Join-Path $InstallRoot 'AutoClip.lnk')) -eq 'modified recipient data') 'Modified output was removed.'
'PASS modified shortcut is rejected and preserved'
$InstallRoot=New-CompletionRoot 'unknown-data'
$resumeIncomplete=$true;$rootFull=[IO.Path]::GetFullPath($InstallRoot).TrimEnd('\')+'\'
[IO.File]::WriteAllText((Join-Path $InstallRoot 'my-export.mp4'),'recipient export')
$failed=$false;try{& $scan}catch{$failed=$true}
Assert ($failed -and [IO.File]::ReadAllText((Join-Path $InstallRoot 'my-export.mp4')) -eq 'recipient export') 'Unknown data was accepted or altered.'
'PASS actual retry scan preserves unexpected export and rejects retry'
$InstallRoot=New-CompletionRoot 'receipt-write-failure'
$receiptPath=Join-Path $InstallRoot 'native-build-receipt.json'
$before=(Get-FileHash -LiteralPath $receiptPath).Hash
$locked=[IO.File]::Open($receiptPath,'Open','Read','Read')
try{$failed=$false;try{& $completionAction}catch{$failed=$true}}finally{$locked.Dispose()}
Assert ($failed -and -not [IO.File]::Exists((Join-Path $InstallRoot 'AutoClip.lnk')) -and -not [IO.File]::Exists((Join-Path $InstallRoot '.install-complete')) -and (Get-FileHash -LiteralPath $receiptPath).Hash -eq $before) 'Receipt write failure stranded unowned launcher or changed receipt.'
& $completionAction
Assert ([IO.File]::Exists((Join-Path $InstallRoot '.install-complete'))) 'Receipt failure retry did not complete.'
'PASS real locked receipt replacement removes only its new exact launcher and permits retry'
