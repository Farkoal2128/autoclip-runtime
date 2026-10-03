$ErrorActionPreference = 'Stop'
$helper = Join-Path $PSScriptRoot '../installer/run-source-build.ps1'
if (-not (Test-Path -LiteralPath $helper)) { throw 'RED: source-build process boundary is missing.' }
$fixture = Join-Path $env:TEMP ('autoclip-build-test-' + [guid]::NewGuid().ToString('N'))
[IO.Directory]::CreateDirectory($fixture) | Out-Null
$acl = [Security.AccessControl.DirectorySecurity]::new()
$sid = [Security.Principal.WindowsIdentity]::GetCurrent().User
$acl.SetOwner($sid); $acl.SetAccessRuleProtection($true,$false)
foreach ($id in @($sid.Value,'S-1-5-18','S-1-5-32-544')) {
    $acl.AddAccessRule([Security.AccessControl.FileSystemAccessRule]::new([Security.Principal.SecurityIdentifier]::new($id),'FullControl','ContainerInherit,ObjectInherit','None','Allow'))
}
Set-Acl -LiteralPath $fixture -AclObject $acl
Copy-Item -LiteralPath $helper -Destination (Join-Path $fixture 'run-source-build.ps1')
$helper=Join-Path $fixture 'run-source-build.ps1'
function Pin($path) { (Get-FileHash -LiteralPath $path).Hash.ToLowerInvariant() }
function Assert($condition,$message) { if (-not $condition) { throw $message } }
function Reject($action,$message) { $bad=$false; try { & $action } catch { $bad=$true }; Assert $bad $message }
$bootstrap=Join-Path $fixture 'install fixture.ps1'
$manifest=Join-Path $fixture 'manifest.json'; [IO.File]::WriteAllText($manifest,(@{target_release=@{sha256=('0'*64);manifest_sha256=('1'*64)}}|ConvertTo-Json -Depth 3))
$downloader=Join-Path $fixture 'download-artifact.ps1'; [IO.File]::WriteAllText($downloader,'# first party fixture')
$argfile=Join-Path $fixture 'arguments.json'
$parameters=@{InstallRoot=(Join-Path $fixture ('release with space '+[char]0x00E9)); ArchivePath=(Join-Path $fixture 'archive.zip'); NonInteractive=$true; NoPrerequisiteAcquisition=$true; SkipDesktopShortcut=$true}
function Save-Args { [IO.File]::WriteAllText($argfile,(@{schema_version=1;parameters=$parameters}|ConvertTo-Json -Depth 5)) }
Save-Args
$code=@'
param($InstallRoot,$ArchivePath,[switch]$NonInteractive,[switch]$NoPrerequisiteAcquisition,[switch]$SkipDesktopShortcut,$CancelPath,$SecureAcquisitionManifestPath,$SecureAcquisitionManifestSha256,$SecureDownloaderSha256)
for($i=0;$i -lt 16000;$i++) { 'chatty-'+$i+('-'*70) }
Write-Host ('ROOT='+$InstallRoot)
Write-Error 'stderr fixture' -ErrorAction Continue
Start-Sleep -Milliseconds 400
if(Test-Path -LiteralPath $CancelPath){exit 1223}
exit 0
'@
[IO.File]::WriteAllText($bootstrap,$code)
function Invocation($attempt) { @{BootstrapPath=$bootstrap;BootstrapSha256=(Pin $bootstrap);ManifestPath=$manifest;ManifestSha256=(Pin $manifest);DownloaderPath=$downloader;DownloaderSha256=(Pin $downloader);ArgumentsPath=$argfile;ArgumentsSha256=(Pin $argfile);HelperSha256=(Pin $helper);AttemptDirectory=(Join-Path $fixture $attempt)} }
$invoke=Invocation 'chatty'; & $helper @invoke
$status=Get-Content (Join-Path $invoke.AttemptDirectory 'status.json') -Raw|ConvertFrom-Json
Assert ($status.status -eq 'TERMINAL' -and $status.exit_code -eq 0 -and $status.worker_pid -gt 0) 'Chatty worker did not finish.'
Assert ((Get-Item (Join-Path $invoke.AttemptDirectory 'stdout.log')).Length -gt 1000000) 'Large output lost.'
Assert ((Get-Item (Join-Path $invoke.AttemptDirectory 'tail.txt')).Length -le 8192) 'Tail was unbounded.'
Assert (([IO.File]::ReadAllText((Join-Path $invoke.AttemptDirectory 'stdout.log'))).Contains('ROOT='+$parameters.InstallRoot)) 'Space/Unicode argument lost.'
'PASS chatty worker completes with full disk log and bounded tail'
$invoke=Invocation 'wrong-pin'; $invoke.BootstrapSha256='0'*64
Reject { & $helper @invoke } 'Wrong hash accepted.'
$parameters.ReleaseInfo=$true; Save-Args; $invoke=Invocation 'diagnostic'
Reject { & $helper @invoke } 'Diagnostic parameter accepted.'
$parameters.Remove('ReleaseInfo'); Save-Args
$parameters.NonInteractive='true'; Save-Args; $invoke=Invocation 'bad-type'
Reject { & $helper @invoke } 'String accepted as Boolean switch.'
$parameters.NonInteractive=$true; Save-Args
[IO.File]::WriteAllText($bootstrap,$code.Replace('exit 0','exit 7'))
$invoke=Invocation 'exit7'; & $helper @invoke
$status=Get-Content (Join-Path $invoke.AttemptDirectory 'status.json') -Raw|ConvertFrom-Json
Assert ($status.exit_code -eq 7 -and (Test-Path (Join-Path $invoke.AttemptDirectory 'stdout.log'))) 'Exit7/log retention failed.'
'PASS nonzero worker exit retained'
[IO.File]::WriteAllText($bootstrap,$code.Replace('Start-Sleep -Milliseconds 400','Start-Sleep -Seconds 3'))
$invoke=Invocation 'cancel-live'
$native=Join-Path $env:WINDIR 'System32/WindowsPowerShell/v1.0/powershell.exe'
$cli=@('-NoProfile','-ExecutionPolicy','Bypass','-File',('"'+$helper+'"'))
foreach($key in $invoke.Keys){$cli += '-'+$key; $cli += '"'+$invoke[$key]+'"'}
$supervisor=Start-Process -FilePath $native -ArgumentList ($cli -join ' ') -PassThru -WindowStyle Hidden
$handle=$supervisor.Handle
$watch=[Diagnostics.Stopwatch]::StartNew()
$statuspath=Join-Path $invoke.AttemptDirectory 'status.json'
while(-not(Test-Path -LiteralPath $statuspath) -and -not $supervisor.HasExited -and $watch.Elapsed.TotalSeconds -lt 30){Start-Sleep -Milliseconds 100}
Assert (Test-Path -LiteralPath $statuspath) 'Live supervisor status missing.'
$live=Get-Content $statuspath -Raw|ConvertFrom-Json
Assert ($live.status -eq 'RUNNING' -and $live.worker_pid -gt 0) 'Worker was not observed live.'
Reject { [IO.File]::WriteAllText($bootstrap,'changed') } 'Bootstrap was writable during worker.'
& $helper @invoke -RequestCancellation
Assert ($LASTEXITCODE -eq 0) 'Live-worker cancellation broker refused the request.'
$watch.Restart()
while(-not $supervisor.WaitForExit(100) -and $watch.Elapsed.TotalSeconds -lt 60){}
Assert $supervisor.HasExited 'Cancelled worker remains pending; fixture retained.'
$supervisor.WaitForExit()
$terminal=Get-Content $statuspath -Raw|ConvertFrom-Json
Assert ($terminal.status -eq 'TERMINAL' -and $terminal.exit_code -eq 1223 -and $terminal.cancel_requested -and $supervisor.ExitCode -eq 1223) 'Cancellation exit/status not propagated.'
Assert (-not(Get-Process -Id $live.worker_pid -ErrorAction SilentlyContinue)) 'Cancelled worker remains alive.'
$supervisor.Dispose()
'PASS observed live worker has locked inputs, cooperative cancellation waits for terminal exit1223'
$aclOriginal=Get-Acl -LiteralPath $downloader
$foreign=Get-Acl -LiteralPath $downloader
$foreign.AddAccessRule([Security.AccessControl.FileSystemAccessRule]::new([Security.Principal.SecurityIdentifier]::new('S-1-1-0'),'Write','Allow'))
Set-Acl -LiteralPath $downloader -AclObject $foreign
$invoke=Invocation 'foreign-writer'
Reject { & $helper @invoke } 'Foreign writable input accepted.'
Set-Acl -LiteralPath $downloader -AclObject $aclOriginal
$junction=Join-Path $fixture 'junction'
New-Item -ItemType Junction -Path $junction -Target $fixture|Out-Null
$invoke=Invocation 'reparse'; $invoke.AttemptDirectory=Join-Path $junction 'attempt'
Reject { & $helper @invoke } 'Reparse attempt accepted.'
'PASS foreign writable input and reparse attempt reject before worker execution'
$requestInvoke=Invocation 'request-before-commit'
[IO.Directory]::CreateDirectory($requestInvoke.AttemptDirectory)|Out-Null
Set-Acl -LiteralPath $requestInvoke.AttemptDirectory -AclObject $acl
[IO.File]::WriteAllText((Join-Path $requestInvoke.AttemptDirectory 'decision.lock'),'')
& $helper @requestInvoke -RequestCancellation
Assert ($LASTEXITCODE -eq 0 -and [IO.File]::Exists((Join-Path $requestInvoke.AttemptDirectory 'cancel.txt')) -and -not [IO.File]::Exists((Join-Path $requestInvoke.AttemptDirectory 'status.json'))) 'RED: protected cancellation request was not accepted before commit or launched a worker.'
'PASS request before commit serializes accepted cancellation'
$install=Join-Path $PSScriptRoot '../install.ps1'
$tokens=$null; $errors=$null
$ast=[Management.Automation.Language.Parser]::ParseFile($install,[ref]$tokens,[ref]$errors)
foreach($node in $ast.FindAll({param($n)$n -is [Management.Automation.Language.FunctionDefinitionAst] -and $n.Name -in @('Assert-AutoClipSecurePath','Assert-AutoClipMsysProtectedPath','Assert-AutoClipBuildCancellation','Invoke-AutoClipBuildCommit','Install-AutoClipLaunchers','Get-AutoClipLauncherPin','Test-AutoClipOwnedLauncher','Write-AutoClipCompletionFile')},$true)) { . ([scriptblock]::Create($node.Extent.Text)) }
$actualLauncher=(Get-Item Function:Install-AutoClipLaunchers).ScriptBlock
[IO.File]::WriteAllText((Join-Path $fixture 'native-build-receipt.json'),'{"profile":"cpu"}')
$CancelPath=Join-Path $fixture 'cancel.txt'; [IO.File]::WriteAllText($CancelPath,'cancel')
$source=[IO.File]::ReadAllText($install)
$recipeCall=@($ast.FindAll({param($n) $n -is [Management.Automation.Language.CommandAst] -and $n.GetCommandName() -eq 'Invoke-AutoClipMsysSource' -and $n.CommandElements[1].Extent.Text -eq '$msysBuildAction'},$true))
Assert ($recipeCall.Count -eq 1) 'Actual immutable recipe invocation selection differs.'
$recipeBoundary=$recipeCall[0].Parent
while($recipeBoundary -isnot [Management.Automation.Language.IfStatementAst]){$recipeBoundary=$recipeBoundary.Parent}
$nativeBranch=$recipeBoundary.Parent
$producerBoundary=$nativeBranch.Parent
$postRecipeEnd=$source.IndexOf('    $sitePackages = Join-Path $venv', $producerBoundary.Extent.EndOffset)
Assert ($postRecipeEnd -gt $producerBoundary.Extent.EndOffset) 'Actual post-recipe boundary missing.'
$postRecipeStatements=@($nativeBranch.Statements|Where-Object{$_.Extent.StartOffset -ge $recipeBoundary.Extent.StartOffset})+
    @($producerBoundary.Parent.Statements|Where-Object{$_.Extent.StartOffset -ge $producerBoundary.Extent.EndOffset -and $_.Extent.StartOffset -lt $postRecipeEnd})
$postRecipe=[scriptblock]::Create(($postRecipeStatements.Extent.Text -join "`r`n"))
foreach($gpu in @($false,$true)) {
foreach($cancelAt in (-1..$(if($gpu){8}else{6}))) {
& {
    $CancelPath=Join-Path $fixture ('cancel-after-recipe-'+$gpu+'-'+$cancelAt+'.txt')
    if($cancelAt -eq -1){$CancelPath=$null}
    $NoPrerequisiteAcquisition=$false; $SecureAcquisitionManifestPath=$null
    $publisherCpu=$null; $retainedLauncherPin=$null
    $InstallNvidiaGpu=$gpu; $NativeBuildRoot=$fixture; $InstallRoot=$fixture; $venv=$fixture
    $wheelhouse=Join-Path $fixture 'empty-wheelhouse'; [IO.Directory]::CreateDirectory($wheelhouse)|Out-Null
    $externalWheels=$fixture; $manifest=[pscustomobject]@{publisher_wheels=@();native_build=[pscustomobject]@{wheel_names=@()};external_assets=@()}
    $openblasArchive='first-party fixture'; $openblasAsset=[pscustomobject]@{member_path='fixture';member_sha256='0'*64}
    $python='Invoke-PostRecipeFixturePython'; $uv=[pscustomobject]@{Source='Invoke-PostRecipeFixtureUv'}
    $script:recipeCalls=0; $script:postRecipeSideEffects=0
    function Record-PostRecipeFixtureStage {
        $script:postRecipeSideEffects++
        if($script:postRecipeSideEffects -eq $cancelAt){[IO.File]::WriteAllText($CancelPath,'cancel during fixture bootstrap command')}
        $global:LASTEXITCODE=0
    }
    function Copy-Item { Record-PostRecipeFixtureStage }
    function Write-AutoClipCompletionFile { Record-PostRecipeFixtureStage }
    function Install-PinnedZipMember { Record-PostRecipeFixtureStage }
    function Invoke-PostRecipeFixturePython { Record-PostRecipeFixtureStage }
    function Invoke-PostRecipeFixtureUv { Record-PostRecipeFixtureStage }
    function Invoke-PostRecipeFixtureNvidia { Record-PostRecipeFixtureStage }
    function Get-Command { [pscustomobject]@{Source='Invoke-PostRecipeFixtureNvidia'} }
    $msysBuildAction={ $script:recipeCalls++; if($cancelAt -eq 0){[IO.File]::WriteAllText($CancelPath,'cancel while recipe runs')} }
    $blocked=$false; try { & $postRecipe } catch { $blocked=$true }
    if($cancelAt -eq -1) {
        Assert (-not $blocked -and $script:recipeCalls -eq 1 -and $script:postRecipeSideEffects -eq $(if($gpu){8}else{6})) 'Uncancelled actual bootstrap control flow changed.'
    } else {
        Assert ($blocked -and $script:recipeCalls -eq 1 -and $script:postRecipeSideEffects -eq $cancelAt) ('RED: cancellation after recipe/bootstrap stage '+$cancelAt+' allowed subsequent side effects: '+$script:postRecipeSideEffects)
    }
}
}
}
'PASS actual post-recipe AST boundaries stop at each CPU/NVIDIA fixture command, with unchanged uncancelled control flow'
$completionAssignment=$ast.FindAll({param($n)$n -is [Management.Automation.Language.AssignmentStatementAst] -and $n.Left.Extent.Text -eq '$completionAction'},$true)
$commitCalls=@($ast.FindAll({param($n)$n -is [Management.Automation.Language.CommandAst] -and $n.GetCommandName() -eq 'Invoke-AutoClipBuildCommit'},$true))
$completionCall=@($commitCalls|Where-Object{$_.CommandElements.Count -eq 2 -and $_.CommandElements[1].Extent.Text -eq '$completionAction'})
$reuseCall=@($commitCalls|Where-Object{$_.CommandElements.Count -eq 2 -and $_.CommandElements[1] -is [Management.Automation.Language.ScriptBlockExpressionAst] -and
    @($_.CommandElements[1].FindAll({param($n)$n -is [Management.Automation.Language.CommandAst] -and $n.GetCommandName() -eq 'Assert-SetupStartingProvenance'},$true)).Count -eq 1})
$runtimeStart=$source.IndexOf('$ffmpegContext = $null')
Assert ($completionAssignment.Count -eq 1 -and $commitCalls.Count -eq 2 -and $completionCall.Count -eq 1 -and $reuseCall.Count -eq 1 -and
        $reuseCall[0].Extent.StartOffset -lt $runtimeStart -and $completionCall[0].Extent.StartOffset -gt $completionAssignment[0].Extent.StartOffset) 'Actual serialized completion/reuse boundaries absent or reordered.'
. ([scriptblock]::Create($completionAssignment[0].Extent.Text))
$complete=[scriptblock]::Create($completionCall[0].Extent.Text)
$InstallRoot=$parameters.InstallRoot; [IO.Directory]::CreateDirectory($InstallRoot)|Out-Null
[IO.Directory]::CreateDirectory((Join-Path $InstallRoot '.venv/Scripts'))|Out-Null
[IO.File]::WriteAllText((Join-Path $InstallRoot '.venv/Scripts/pythonw.exe'),'first-party fixture, never execute')
[IO.File]::WriteAllText((Join-Path $InstallRoot 'Start-AutoClip.ps1'),'# first-party fixture')
[IO.File]::WriteAllText((Join-Path $InstallRoot 'native-build-receipt.json'),'{"profile":"cpu"}')
$expectedArchiveSha256='0'*64; $expectedManifestSha256='1'*64; $SecureAcquisitionManifestSha256=Pin $manifest
$SkipDesktopShortcut=$true; $script:launches=0
function Install-AutoClipLaunchers { param($InstallRoot,[switch]$SkipDesktopShortcut); $script:launches++; & $actualLauncher -InstallRoot $InstallRoot -SkipDesktopShortcut:$SkipDesktopShortcut }
$CancelPath=Join-Path $requestInvoke.AttemptDirectory 'cancel.txt'
Reject { & $complete } 'Accepted cancellation allowed commit.'
Assert (-not(Test-Path (Join-Path $InstallRoot '.install-complete')) -and $script:launches -eq 0) 'Cancelled build wrote marker or launcher.'
'PASS accepted cancellation wins before actual serialized marker/launcher commit'
$lateInvoke=Invocation 'request-during-commit'
[IO.Directory]::CreateDirectory($lateInvoke.AttemptDirectory)|Out-Null
Set-Acl -LiteralPath $lateInvoke.AttemptDirectory -AclObject $acl
[IO.File]::WriteAllText((Join-Path $lateInvoke.AttemptDirectory 'decision.lock'),'')
$CancelPath=Join-Path $lateInvoke.AttemptDirectory 'cancel.txt'
function Start-RequestFixture($inputArgs) {
    $cli=@('-NoProfile','-ExecutionPolicy','Bypass','-File',('"'+$helper+'"'),'-RequestCancellation')
    foreach($key in $inputArgs.Keys){$cli += '-'+$key; $cli += '"'+$inputArgs[$key]+'"'}
    $p=Start-Process -FilePath $native -ArgumentList ($cli -join ' ') -PassThru -WindowStyle Hidden
    $handle=$p.Handle; return $p
}
function Install-AutoClipLaunchers {
    param($InstallRoot,[switch]$SkipDesktopShortcut)
    $script:launches++
    & $actualLauncher -InstallRoot $InstallRoot -SkipDesktopShortcut:$SkipDesktopShortcut
    $script:lateRequest=Start-RequestFixture $lateInvoke
    Start-Sleep -Milliseconds 500
}
& $complete
Assert ($script:lateRequest.WaitForExit(30000)) 'Late request remains pending; fixture retained.'
$script:lateRequest.WaitForExit()
Assert ($script:lateRequest.ExitCode -eq 170 -and -not [IO.File]::Exists($CancelPath) -and $script:launches -eq 1 -and [IO.File]::Exists((Join-Path $InstallRoot '.install-complete'))) 'Late cancellation overwrote committed completion.'
$script:lateRequest.Dispose()
'PASS cancellation during actual launcher commit returns170 and leaves committed success intact'
$startupInvoke=Invocation 'request-before-startup'
$startup=Start-RequestFixture $startupInvoke
Start-Sleep -Milliseconds 500
& $helper @startupInvoke
$startupSupervisorExit=$LASTEXITCODE
Assert ($startup.WaitForExit(30000)) 'Startup cancellation request remains pending.'
$startup.WaitForExit()
Assert ($startup.ExitCode -eq 0 -and $startupSupervisorExit -eq 1223 -and [IO.File]::Exists((Join-Path $startupInvoke.AttemptDirectory 'cancel.txt'))) 'Startup request failed or supervisor ignored cancellation.'
$startup.Dispose()
'PASS request before actual supervisor startup waits for protected decision lock and cancels worker'
foreach($kind in @('malformed','foreign','reparse','wrong-binding')) {
    $invalidInvoke=Invocation ('invalid-commit-'+$kind)
    [IO.Directory]::CreateDirectory($invalidInvoke.AttemptDirectory)|Out-Null
    Set-Acl -LiteralPath $invalidInvoke.AttemptDirectory -AclObject $acl
    [IO.File]::WriteAllText((Join-Path $invalidInvoke.AttemptDirectory 'decision.lock'),'')
    $commitPath=Join-Path $invalidInvoke.AttemptDirectory 'commit.json'
    if($kind -eq 'reparse'){New-Item -ItemType Junction -Path $commitPath -Target $lateInvoke.AttemptDirectory|Out-Null}
    else {
        $text=[IO.File]::ReadAllText((Join-Path $lateInvoke.AttemptDirectory 'commit.json'))
        if($kind -eq 'malformed'){$text='{broken'}
        if($kind -eq 'wrong-binding'){$text=$text.Replace(('0'*64),('f'*64))}
        [IO.File]::WriteAllText($commitPath,$text)
        if($kind -eq 'foreign'){
            $badAcl=Get-Acl -LiteralPath $commitPath
            $badAcl.AddAccessRule([Security.AccessControl.FileSystemAccessRule]::new([Security.Principal.SecurityIdentifier]::new('S-1-1-0'),'Write','Allow'))
            Set-Acl -LiteralPath $commitPath -AclObject $badAcl
        }
    }
    Reject { & $helper @invalidInvoke -RequestCancellation } ('Invalid '+$kind+' commit accepted.')
    Assert (-not [IO.File]::Exists((Join-Path $invalidInvoke.AttemptDirectory 'cancel.txt'))) 'Invalid commit caused signal write.'
}
'PASS malformed, foreign-writable, reparse and wrong-bound commit states fail closed without signals'
