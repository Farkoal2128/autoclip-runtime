$ErrorActionPreference='Stop'
$repo=Split-Path -Parent $PSScriptRoot
$tokens=$null;$errors=$null
$ast=[Management.Automation.Language.Parser]::ParseFile((Join-Path $repo 'install.ps1'),[ref]$tokens,[ref]$errors)
$names=@('Assert-AutoClipSecurePath','Assert-AutoClipMsysProtectedPath','Read-AutoClipSecureInput','Assert-AutoClipBuildCancellation','Invoke-AutoClipAppHealth','Install-AutoClipLaunchers','Get-AutoClipLauncherPin','Test-AutoClipOwnedLauncher','Write-AutoClipCompletionFile')
$functions=@($ast.FindAll({param($n)$n -is [Management.Automation.Language.FunctionDefinitionAst] -and $n.Name -in $names},$true))
if($functions.Name -notcontains 'Invoke-AutoClipAppHealth'){throw 'RED: actual source has no verified app-health completion boundary.'}
$completion=$ast.FindAll({param($n)$n -is [Management.Automation.Language.AssignmentStatementAst] -and $n.Left.Extent.Text -eq '$completionAction'},$true)
$calls=@($ast.FindAll({param($n)$n -is [Management.Automation.Language.CommandAst] -and $n.GetCommandName() -eq 'Invoke-AutoClipAppHealth'},$true))
$reuseCalls=@($calls|Where-Object{$_.Extent.Text -eq 'Invoke-AutoClipAppHealth -PreserveSourceReceipt'})
$buildCalls=@($calls|Where-Object{$_.Extent.Text -eq 'Invoke-AutoClipAppHealth'})
$runtimeStart=$ast.FindAll({param($n)$n -is [Management.Automation.Language.AssignmentStatementAst] -and $n.Left.Extent.Text -eq '$ffmpegContext'},$true)[0]
if($calls.Count -ne 2 -or $reuseCalls.Count -ne 1 -or $buildCalls.Count -ne 1 -or
   $reuseCalls[0].Extent.StartOffset -gt $runtimeStart.Extent.StartOffset -or
   $buildCalls[0].Extent.StartOffset -gt $completion[0].Extent.StartOffset){throw 'Actual reuse health must precede runtime work; build health must precede completion action/commit.'}
$guard=@($ast.FindAll({param($n)$n -is [Management.Automation.Language.IfStatementAst] -and $n.Extent.Text.StartsWith('if ($CancelPath -and $AppHealthHelperSha256 -notmatch')},$true))
$acquisition=@($ast.FindAll({param($n)$n -is [Management.Automation.Language.AssignmentStatementAst] -and $n.Left.Extent.Text -eq '$secureDownload'},$true))
if($guard.Count -ne 1 -or $guard[0].Extent.StartOffset -gt $acquisition[0].Extent.StartOffset){throw 'Managed health pin guard must precede acquisition/native work.'}
function Assert($value,$message){if(!$value){throw $message}}
$stage=Join-Path $env:TEMP ('autoclip-health-boundary-'+[guid]::NewGuid().ToString('N'))
[IO.Directory]::CreateDirectory($stage)|Out-Null
$acl=[Security.AccessControl.DirectorySecurity]::new();$sid=[Security.Principal.WindowsIdentity]::GetCurrent().User
$acl.SetOwner($sid);$acl.SetAccessRuleProtection($true,$false)
foreach($id in @($sid.Value,'S-1-5-18','S-1-5-32-544')){$acl.AddAccessRule([Security.AccessControl.FileSystemAccessRule]::new([Security.Principal.SecurityIdentifier]::new($id),'FullControl','ContainerInherit,ObjectInherit','None','Allow'))}
Set-Acl -LiteralPath $stage -AclObject $acl
$fixtureHelper=@'
param($InstallRoot,$ManifestSha256,$ResultPath)
$ErrorActionPreference='Stop'
$mode=[IO.File]::ReadAllText((Join-Path $InstallRoot 'fixture-mode.txt'))
if($mode -eq 'throw'){throw 'first-party fixture failure'}
if(!$ResultPath){$ResultPath=Join-Path $InstallRoot 'fixture-result.json'}
$result=@{schema_version=1;status='VERIFIED_HEALTH_HOME';install_root=$InstallRoot;manifest_sha256=$ManifestSha256;isolated_health_only=$true;desktop_tested=$false;media_tested=$false;model_inference_tested=$false;child=@{exit_code=0;receipt=@{health_status=200;home_status=200}}}
if($mode -eq 'foreign'){$result.install_root='C:\foreign'}
if($mode -eq 'wrong-manifest'){$result.manifest_sha256='f'*64}
if($mode -eq 'failed'){$result.status='FAILED_PRESERVED'}
if($mode -eq 'string-bool'){$result.isolated_health_only='True'}
if($mode -eq 'result-directory'){[IO.Directory]::CreateDirectory($ResultPath)|Out-Null}else{[IO.File]::WriteAllText($ResultPath,($result|ConvertTo-Json -Depth 8))}
if($mode -eq 'result-reparse'){[IO.File]::Delete($ResultPath);New-Item -ItemType Junction -Path $ResultPath -Target $InstallRoot|Out-Null}
if($mode -eq 'oversized'){[IO.File]::AppendAllText($ResultPath,(' '*70000))}
if($mode -eq 'cancel'){[IO.File]::WriteAllText((Join-Path (Split-Path -Parent $ResultPath) 'cancel.txt'),'accepted fixture signal')}
[pscustomobject]@{status=$result.status;result_path=$ResultPath;stage=(Split-Path -Parent $ResultPath)}
if($mode -eq 'duplicate'){[pscustomobject]@{status=$result.status;result_path=$ResultPath}}
'@
$harness=@'
param($InstallRoot,$CancelPath,$AppHealthHelperSha256,$expectedManifestSha256)
$ErrorActionPreference='Stop'
$expectedArchiveSha256='a'*64;$SkipDesktopShortcut=$true
'@
$harness+= "`r`n"+ (($functions|ForEach-Object {$_.Extent.Text}) -join "`r`n")+"`r`n"+$completion[0].Extent.Text+@'

try { Invoke-AutoClipAppHealth; & $completionAction; exit 0 } catch { [Console]::Error.WriteLine($_.Exception.Message);exit 7 }
'@
$nativePs=Join-Path $env:SystemRoot 'System32/WindowsPowerShell/v1.0/powershell.exe'
foreach($mode in @('ok','throw','foreign','wrong-manifest','failed','duplicate','cancel','wrong-pin','changed-helper','missing-helper','missing-pin','existing-result','result-directory','result-reparse','oversized','string-bool','legacy','real-helper')){
    $case=Join-Path $stage $mode;[IO.Directory]::CreateDirectory($case)|Out-Null;Set-Acl -LiteralPath $case -AclObject $acl
    $root=Join-Path $case 'installed';[IO.Directory]::CreateDirectory((Join-Path $root '.venv/Scripts'))|Out-Null
    [IO.File]::WriteAllText((Join-Path $root '.venv/Scripts/pythonw.exe'),'first-party fixture; never execute')
    [IO.File]::WriteAllText((Join-Path $root 'Start-AutoClip.ps1'),'# fixture')
    [IO.File]::WriteAllText((Join-Path $root 'release-manifest.json'),'{"schema_version":3,"files":[]}')
    [IO.File]::WriteAllText((Join-Path $root 'native-build-receipt.json'),'{"installed_files":[]}')
    [IO.File]::WriteAllText((Join-Path $root 'fixture-mode.txt'),$mode)
    $helper=Join-Path $case 'verify-installed-app.ps1'
    if($mode -eq 'real-helper'){[IO.File]::Copy((Join-Path $repo 'installer/verify-installed-app.ps1'),$helper)}else{[IO.File]::WriteAllText($helper,$fixtureHelper)}
    $pin=(Get-FileHash $helper).Hash.ToLowerInvariant()
    if($mode -eq 'wrong-pin'){$pin='0'*64}
    if($mode -eq 'changed-helper'){[IO.File]::AppendAllText($helper,"`r`n# changed after pin")}
    if($mode -eq 'missing-helper'){[IO.File]::Delete($helper)}
    if($mode -in @('missing-pin','legacy')){$pin=''}
    $cancel=Join-Path $case 'cancel.txt';if($mode -eq 'legacy'){$cancel=''}
    if($mode -eq 'existing-result'){[IO.File]::WriteAllText((Join-Path $case 'health-result.json'),'unrelated preexisting result')}
    $script=Join-Path $case 'source-boundary.ps1';[IO.File]::WriteAllText($script,$harness)
    $arguments=@('-NoProfile','-NonInteractive','-File',$script,'-InstallRoot',$root,'-expectedManifestSha256',((Get-FileHash (Join-Path $root 'release-manifest.json')).Hash.ToLowerInvariant()))
    if($cancel){$arguments+=@('-CancelPath',$cancel)}
    if($pin){$arguments+=@('-AppHealthHelperSha256',$pin)}
    $ErrorActionPreference='Continue'
    & $nativePs @arguments 2>&1 | ForEach-Object {Write-Host $_}
    $ErrorActionPreference='Stop'
    $exit=$LASTEXITCODE;$success=$mode -in @('ok','legacy')
    Assert (($exit -eq 0) -eq $success) "Wrong boundary exit for $mode : $exit"
    Assert ((Test-Path (Join-Path $root '.install-complete')) -eq $success) "Wrong marker state for $mode"
    Assert ((Test-Path (Join-Path $root 'AutoClip.lnk')) -eq $success) "Wrong launcher state for $mode"
    if($mode -eq 'existing-result'){Assert ([IO.File]::ReadAllText((Join-Path $case 'health-result.json')) -eq 'unrelated preexisting result') 'Existing result was modified.'}
    if($mode -eq 'ok'){
        $receipt=Get-Content (Join-Path $root 'native-build-receipt.json') -Raw|ConvertFrom-Json
        $result=Join-Path $case 'health-result.json'
        Assert ($receipt.setup_app_health.sha256 -eq (Get-FileHash $result).Hash.ToLowerInvariant()) 'Actual health result bytes were not pinned in native receipt.'
        Assert ($receipt.setup_app_health.install_root -eq $root -and $receipt.setup_app_health.manifest_sha256 -eq (Get-FileHash (Join-Path $root 'release-manifest.json')).Hash.ToLowerInvariant()) 'Health receipt binding differs.'
    }
    "PASS $mode"
}
'PASS actual source boundary fixtures; real helper failure only, no actual app health success claimed.'
$wrapper=[Management.Automation.Language.Parser]::ParseFile((Join-Path $repo 'installer/run-source-build.ps1'),[ref]$tokens,[ref]$errors)
foreach($node in $wrapper.FindAll({param($n)$n -is [Management.Automation.Language.FunctionDefinitionAst] -and $n.Name -in @('Assert-BuildPath','Read-BuildArguments')},$true)){. ([scriptblock]::Create($node.Extent.Text))}
foreach($pin in @(('a'*64),17,'wrong')){
    $json=@{schema_version=1;parameters=@{InstallRoot=$stage;ArchivePath=(Join-Path $stage 'archive.zip');NonInteractive=$true;NoPrerequisiteAcquisition=$true;SkipDesktopShortcut=$true;AppHealthHelperSha256=$pin}}|ConvertTo-Json
    $stream=[IO.MemoryStream]::new([Text.Encoding]::UTF8.GetBytes($json));$failed=$false
    try{$parsed=Read-BuildArguments $stream}catch{$failed=$true}finally{$stream.Dispose()}
    Assert ($failed -eq ($pin -ne ('a'*64))) 'Actual wrapper health pin allowlist/type check differs.'
}
'PASS actual wrapper typed health pin acceptance/rejection'
