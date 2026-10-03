$ErrorActionPreference='Stop'
$repo=Split-Path -Parent $PSScriptRoot
function Assert($value,$message){if(!$value){throw $message}}
function Pin($path){(Get-FileHash -LiteralPath $path).Hash.ToLowerInvariant()}
function Snapshot($root){@((Get-ChildItem -LiteralPath $root -Recurse -Force -File|Sort-Object FullName|ForEach-Object{[ordered]@{path=$_.FullName.Substring($root.Length);bytes=$_.Length;sha256=(Pin $_.FullName)}}))|ConvertTo-Json -Compress}
$source=[IO.File]::ReadAllText((Join-Path $repo 'install.ps1'))
$tokens=$null;$errors=$null;$ast=[Management.Automation.Language.Parser]::ParseInput($source,[ref]$tokens,[ref]$errors)
Assert (!$errors.Count) 'Installer parser failed.'
$names=@('Assert-AutoClipSecurePath','Assert-AutoClipMsysProtectedPath','Read-AutoClipSecureInput','Assert-AutoClipBuildCancellation','Invoke-AutoClipAppHealth','Invoke-AutoClipBuildCommit')
$functions=@($ast.FindAll({param($n)$n -is [Management.Automation.Language.FunctionDefinitionAst] -and $n.Name -in $names},$true))
$start=$source.IndexOf('$resumeIncomplete = $false');$end=$source.IndexOf('$ffmpegContext = $null',$start)
Assert ($start -gt 0 -and $end -gt $start) 'Actual source guard selection failed.'
$early=$source.Substring($start,$end-$start)
$fixture=Join-Path $env:TEMP ('autoclip-completed-reuse-'+[guid]::NewGuid().ToString('N'))
$acl=[Security.AccessControl.DirectorySecurity]::new();$sid=[Security.Principal.WindowsIdentity]::GetCurrent().User
$acl.SetOwner($sid);$acl.SetAccessRuleProtection($true,$false)
foreach($id in @($sid.Value,'S-1-5-18','S-1-5-32-544')){$acl.AddAccessRule([Security.AccessControl.FileSystemAccessRule]::new([Security.Principal.SecurityIdentifier]::new($id),'FullControl','ContainerInherit,ObjectInherit','None','Allow'))}
[IO.Directory]::CreateDirectory($fixture,$acl)|Out-Null
. (Join-Path $repo 'installer/write-setup-receipt.ps1')
$fixtureHelper=@'
param($InstallRoot,$ManifestSha256,$ResultPath)
$ErrorActionPreference='Stop'
$attempt=Split-Path -Parent $ResultPath
$mode=[IO.File]::ReadAllText((Join-Path $attempt 'mode.txt'))
if($mode -eq 'health-throw'){throw 'inert first-party health failure'}
$result=@{schema_version=1;status='VERIFIED_HEALTH_HOME';install_root=$InstallRoot;manifest_sha256=$ManifestSha256;isolated_health_only=$true;desktop_tested=$false;media_tested=$false;model_inference_tested=$false;child=@{exit_code=0;receipt=@{health_status=200;home_status=200}}}
if($mode -eq 'health-foreign'){$result.install_root='C:\foreign'}
if($mode -eq 'health-failed'){$result.child.exit_code=7}
if($mode -eq 'health-string-bool'){$result.isolated_health_only='True'}
[IO.File]::WriteAllText($ResultPath,($result|ConvertTo-Json -Depth 8))
if($mode -eq 'cancel'){[IO.File]::WriteAllText((Join-Path $attempt 'cancel.txt'),'accepted fixture signal')}
if($mode -eq 'changed-during-health'){[IO.File]::WriteAllText((Join-Path $InstallRoot '.venv/Scripts/pythonw.exe'),'deliberate first-party mutation')}
if($mode -eq 'marker-removed-during-health'){[IO.File]::Delete((Join-Path $InstallRoot '.install-complete'))}
[pscustomobject]@{status='VERIFIED_HEALTH_HOME';result_path=$ResultPath}
'@
$harness=@'
param($InstallRoot,$ContextPath,$CancelPath,$AppHealthHelperSha256,[switch]$Standalone,[switch]$HealthOnly)
$ErrorActionPreference='Stop'
$setupReceiptContext=@{};$record=Get-Content -LiteralPath $ContextPath -Raw|ConvertFrom-Json
foreach($property in $record.PSObject.Properties){$setupReceiptContext[$property.Name]=$property.Value}
$expectedArchiveSha256=$setupReceiptContext.archive_sha256;$expectedManifestSha256=$setupReceiptContext.release_manifest_sha256
$SecureAcquisitionManifestSha256=$setupReceiptContext.dependency_manifest_sha256;$PrerequisitesOnly=$false
if($Standalone){$setupReceiptContext=$null;$AppHealthHelperSha256=$null;$CancelPath=$null}
'@
$harness+="`r`n"+(($functions|ForEach-Object{$_.Extent.Text}) -join "`r`n")+"`r`n"
$harness+=". '"+(Join-Path $repo 'installer/write-setup-receipt.ps1')+"'`r`ntry {`r`n"
$harness+='if($HealthOnly){$health=Invoke-AutoClipAppHealth -PreserveSourceReceipt;[IO.File]::WriteAllText((Join-Path (Split-Path -Parent $ContextPath) ''descriptor.json''),($health|ConvertTo-Json));exit 0}'
$harness+="`r`n& {`r`n"+$early+"`r`nthrow 'Unexpected runtime acquisition/build boundary reached.'`r`n};exit 0`r`n} catch {[Console]::Error.WriteLine(`$_.Exception.Message);exit 7}"
$nativePs=Join-Path $env:SystemRoot 'System32/WindowsPowerShell/v1.0/powershell.exe'
foreach($mode in @('changed-during-commit-wait','ok','health-only','standalone','missing-handoff','changed-handoff','missing-file','changed-file','unknown-file','unknown-directory','foreign-marker','marker-directory','changed-manifest','wrong-profile','wrong-archive','wrong-dependency','wrong-bootstrap','wrong-source-helper','wrong-helper-identity','wrong-recipient','changed-history','foreign-launcher','health-throw','health-foreign','health-failed','health-string-bool','wrong-pin','cancel-before','cancel','changed-during-health','marker-removed-during-health','attempt-inside-source')){
    $case=Join-Path $fixture $mode;[IO.Directory]::CreateDirectory($case,$acl)|Out-Null
    $root=Join-Path $case 'installed';[IO.Directory]::CreateDirectory($root,$acl)|Out-Null
    [IO.File]::WriteAllText((Join-Path $root 'Start-AutoClip.ps1'),'# pinned inert first-party payload')
    $payload=Join-Path $root 'Start-AutoClip.ps1';$manifest=Join-Path $root 'release-manifest.json'
    [IO.File]::WriteAllText($manifest,(@{schema_version=3;files=@(@{path='Start-AutoClip.ps1';bytes=(Get-Item $payload).Length;sha256=(Pin $payload)})}|ConvertTo-Json -Depth 6))
    $helper=Join-Path $case 'verify-installed-app.ps1';[IO.File]::WriteAllText($helper,$fixtureHelper)
    $context=@{install_root=$root;release_id='first-party-completed-source';profile='cpu';archive_sha256=('a'*64);release_manifest_sha256=(Pin $manifest);dependency_manifest_sha256=('b'*64);bootstrap_sha256=('c'*64);source_helper_sha256=(Pin (Join-Path $repo 'installer/write-setup-receipt.ps1'));health_helper_sha256=(Pin $helper)}
    $proof=Assert-SetupStartingProvenance -Context $context -ManifestPath $manifest
    [IO.Directory]::CreateDirectory((Join-Path $root '.venv/Scripts'))|Out-Null
    [IO.File]::WriteAllText((Join-Path $root '.venv/Scripts/pythonw.exe'),'inert first-party interpreter; never execute')
    $history=Join-Path $case 'historical-health.json'
    [IO.File]::WriteAllText($history,(@{schema_version=1;status='VERIFIED_HEALTH_HOME';install_root=$root;manifest_sha256=$context.release_manifest_sha256;isolated_health_only=$true;desktop_tested=$false;media_tested=$false;model_inference_tested=$false;child=@{exit_code=0;receipt=@{health_status=200;home_status=200}}}|ConvertTo-Json -Depth 6))
    $health=@{result_path=$history;bytes=(Get-Item $history).Length;sha256=(Pin $history);install_root=$root;manifest_sha256=$context.release_manifest_sha256;status='VERIFIED_HEALTH_HOME'}
    $launcher=Join-Path $root 'AutoClip.lnk';$shell=New-Object -ComObject WScript.Shell;$link=$shell.CreateShortcut($launcher)
    $link.TargetPath=Join-Path $root '.venv/Scripts/pythonw.exe';$link.Arguments='-m autoclip.desktop';$link.WorkingDirectory=$root;$link.Description='Start AutoClip';$link.Save()
    $launcherPin=@{bytes=(Get-Item $launcher).Length;sha256=(Pin $launcher);archive_sha256=$context.archive_sha256;release_manifest_sha256=$context.release_manifest_sha256}
    [IO.File]::WriteAllText((Join-Path $root 'native-build-receipt.json'),(@{profile='cpu';setup_app_health=$health;setup_owned_launcher=$launcherPin}|ConvertTo-Json -Depth 8))
    Write-SetupSourceReceipt -Context $context -StartingProof $proof|Out-Null
    $marker=Join-Path $root '.install-complete';[IO.File]::WriteAllText($marker,$context.archive_sha256)
    $handoff=Join-Path $root '.setup-source-ownership.json'
    if($mode -eq 'missing-handoff'){[IO.File]::Delete($handoff)}
    if($mode -eq 'changed-handoff'){[IO.File]::WriteAllText($handoff,'{"schema_version":2,"status":"UNKNOWN"}')}
    if($mode -eq 'missing-file'){[IO.File]::Delete((Join-Path $root '.venv/Scripts/pythonw.exe'))}
    if($mode -eq 'changed-file'){[IO.File]::AppendAllText($payload,'modified')}
    if($mode -eq 'unknown-file'){[IO.File]::WriteAllText((Join-Path $root '.venv/unknown.txt'),'preserve unrelated bytes')}
    if($mode -eq 'unknown-directory'){[IO.Directory]::CreateDirectory((Join-Path $root '.venv/unknown'))|Out-Null}
    if($mode -eq 'foreign-marker'){[IO.File]::WriteAllText($marker,'f'*64)}
    if($mode -eq 'marker-directory'){[IO.File]::Delete($marker);[IO.Directory]::CreateDirectory($marker)|Out-Null}
    if($mode -eq 'changed-manifest'){[IO.File]::AppendAllText($manifest,' ')}
    if($mode -eq 'wrong-profile'){$context.profile='nvidia'}
    if($mode -eq 'wrong-archive'){$context.archive_sha256='f'*64}
    if($mode -eq 'wrong-dependency'){$context.dependency_manifest_sha256='f'*64}
    if($mode -eq 'wrong-bootstrap'){$context.bootstrap_sha256='f'*64}
    if($mode -eq 'wrong-source-helper'){$context.source_helper_sha256='f'*64}
    if($mode -eq 'wrong-helper-identity'){$context.health_helper_sha256='f'*64}
    if($mode -eq 'wrong-recipient'){$record=Get-Content $handoff -Raw|ConvertFrom-Json;$record.context.recipient_sid='S-1-5-18';[IO.File]::WriteAllText($handoff,($record|ConvertTo-Json -Depth 12))}
    if($mode -eq 'changed-history'){[IO.File]::AppendAllText($history,' ')}
    if($mode -eq 'foreign-launcher'){$link.Arguments='-m foreign';$link.Save()}
    $attempt=Join-Path $case 'attempt';if($mode -eq 'attempt-inside-source'){$attempt=Join-Path $root '.venv/attempt'}
    [IO.Directory]::CreateDirectory($attempt,$acl)|Out-Null
    [IO.File]::WriteAllText((Join-Path $attempt 'decision.lock'),'');[IO.File]::WriteAllText((Join-Path $attempt 'mode.txt'),$mode)
    $cancel=Join-Path $attempt 'cancel.txt';if($mode -eq 'cancel-before'){[IO.File]::WriteAllText($cancel,'accepted fixture signal')}
    $contextPath=Join-Path $case 'context.json';[IO.File]::WriteAllText($contextPath,($context|ConvertTo-Json))
    $script=Join-Path $case 'actual-boundary.ps1';[IO.File]::WriteAllText($script,$harness)
    $pin=Pin $helper;if($mode -eq 'wrong-pin'){$pin='0'*64}
    $before=Snapshot $root;$historyBefore=Pin $history
    $arguments=@('-NoProfile','-NonInteractive','-File',$script,'-InstallRoot',$root,'-ContextPath',$contextPath,'-CancelPath',$cancel,'-AppHealthHelperSha256',$pin)
    if($mode -eq 'standalone'){$arguments+='-Standalone'}
    if($mode -in @('health-only','attempt-inside-source')){$arguments+='-HealthOnly'}
    if($mode -eq 'changed-during-commit-wait'){
        $decision=[IO.File]::Open((Join-Path $attempt 'decision.lock'),'Open','ReadWrite','None')
        $child=[Diagnostics.Process]::new();$child.StartInfo.FileName=$nativePs
        $child.StartInfo.Arguments=($arguments|ForEach-Object{'"'+$_+'"'}) -join ' '
        $child.StartInfo.UseShellExecute=$false;$child.StartInfo.CreateNoWindow=$true
        $child.StartInfo.RedirectStandardOutput=$true;$child.StartInfo.RedirectStandardError=$true
        try{
            Assert ($child.Start()) 'Actual completed-source child did not start.'
            $watch=[Diagnostics.Stopwatch]::StartNew()
            while(![IO.File]::Exists((Join-Path $attempt 'health-result.json')) -and !$child.HasExited -and $watch.Elapsed.TotalSeconds -lt 10){Start-Sleep -Milliseconds 50}
            Assert ([IO.File]::Exists((Join-Path $attempt 'health-result.json')) -and !$child.HasExited) 'Actual health did not reach locked completion decision.'
            Start-Sleep -Milliseconds 500
            Assert (!$child.HasExited -and ![IO.File]::Exists((Join-Path $attempt 'commit.json'))) 'Child bypassed held decision lock.'
            [IO.File]::WriteAllText((Join-Path $root '.venv/Scripts/pythonw.exe'),'deliberate first-party mutation')
        }finally{$decision.Dispose()}
        Assert ($child.WaitForExit(15000)) 'Completed-source child did not terminate after decision lock release.'
        $output=@($child.StandardOutput.ReadToEnd(),$child.StandardError.ReadToEnd());$exit=$child.ExitCode;$child.Dispose()
    }else{
        $ErrorActionPreference='Continue';$output=& $nativePs @arguments 2>&1;$exit=$LASTEXITCODE;$ErrorActionPreference='Stop'
    }
    $output|ForEach-Object{Write-Host $_}
    $success=$mode -in @('ok','health-only')
    Assert (($exit -eq 0) -eq $success) "RED: actual completed-source boundary result for $mode differs: exit=$exit"
    if($mode -notin @('changed-during-health','marker-removed-during-health','changed-during-commit-wait')){Assert ((Snapshot $root) -ceq $before) "Source bytes changed for $mode"}
    else{
        if($mode -ne 'changed-during-commit-wait'){Assert (-not [IO.File]::Exists((Join-Path $attempt 'commit.json'))) 'Changed source must fail provenance before commit.'}
        $changedPath=if($mode -in @('changed-during-health','changed-during-commit-wait')){'\.venv\Scripts\pythonw.exe'}else{'\.install-complete'}
        $beforeRows=$before|ConvertFrom-Json;$afterRows=(Snapshot $root)|ConvertFrom-Json
        $unchangedBefore=@($beforeRows|Where-Object{$_.path -cne $changedPath})|ConvertTo-Json -Compress
        $unchangedAfter=@($afterRows|Where-Object{$_.path -cne $changedPath})|ConvertTo-Json -Compress
        Assert ($unchangedBefore -ceq $unchangedAfter) 'Recheck refusal modified source beyond deliberate fixture mutation.'
    }
    Assert ((Pin $history) -ceq $historyBefore) 'Historical health was rewritten.'
    Assert ([IO.File]::Exists((Join-Path $attempt 'commit.json')) -eq ($mode -in @('ok','changed-during-commit-wait'))) "Wrong cooperative decision for $mode"
    if($success){
        $result=Join-Path $attempt 'health-result.json';Assert ([IO.File]::Exists($result)) 'Fresh external health was not executed.'
        if($mode -eq 'health-only'){$descriptor=Get-Content (Join-Path $case 'descriptor.json') -Raw|ConvertFrom-Json;Assert ($descriptor.sha256 -ceq (Pin $result) -and $descriptor.bytes -eq (Get-Item $result).Length -and $descriptor.install_root -ieq $root) 'Read-only health descriptor differs.'}
    }
    "PASS $mode exit=$exit source_before=$before source_after=$(Snapshot $root)"
}
'PASS inert first-party completed-source fixtures; no actual application health success claimed.'
'PRESERVED '+$fixture
