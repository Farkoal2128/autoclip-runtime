param([string]$IsccPath='D:\AutoClip-Inno-Migration\InnoSetup7\ISCC.exe')
$ErrorActionPreference='Stop'
$repo=Split-Path -Parent $PSScriptRoot
$source=[IO.File]::ReadAllText((Join-Path $repo 'installer/AutoClip.iss'))
if((Get-FileHash $IsccPath).Hash -ne 'd06ebd38f38e3cee60a3c50cc45bd449d77e0bc6a5cabc607ea9886808e4de1a'){throw 'Compiler pin differs.'}
$root=Join-Path $env:TEMP ('autoclip-uninstall-wizard-'+[guid]::NewGuid().ToString('N'))
[IO.Directory]::CreateDirectory($root)|Out-Null
$blocks=@()
foreach($name in @('MsysPowerShellQuote','BuildJsonString','BuildUninstallCommand','ValidUninstallHandoff','RegisterManagedUninstall','RunManagedUninstall','RetireUninstallEvidence','PublishUninstallAnchor','PrepareNativeShortcutDirectory','FinalizeSetupReceipt')){
 $m=[regex]::Match($source,'(?ms)^(?:function|procedure) '+$name+'\b.*?(?=^(?:function|procedure) |\z)')
 if(-not $m.Success -and $name -eq 'BuildUninstallCommand'){$blocks+="function BuildUninstallCommand(NativeSilent:Boolean):String;begin Result:='';end;"}
 elseif(-not $m.Success -and $name -eq 'ValidUninstallHandoff'){$blocks+="function ValidUninstallHandoff(Path,Hash:String):Boolean;begin Result:=True;end;"}
 elseif($m.Success){$blocks+=$m.Value.Replace('function RunManagedUninstall(', 'function CapturedRunManagedUninstall(').Replace('function RetireUninstallEvidence:', 'function CapturedRetireUninstallEvidence:').Replace("ExpandConstant('{param:AUTOCLIP-HANDOFF|}')",'FixtureHandoffPath').Replace("ExpandConstant('{param:AUTOCLIP-HANDOFF-SHA256|}')",'FixtureHandoffHash').Replace('RegWriteStringValue(','FixtureRegWriteStringValue(').Replace('RegValueExists(','FixtureRegValueExists(').Replace('ExecWithNativeSysDir(','FixtureExec(').Replace("ExpandConstant('{uninstallexe}')","ExpandConstant('{tmp}\first-party-setup\unins999.exe')").Replace("ExpandConstant('{app}')","ExpandConstant('{tmp}\first-party-setup')").Replace("ExpandConstant('{group}')","ExpandConstant('{tmp}\first-party-menu')").Replace("'{group}\","'{tmp}\first-party-menu\")}
}
foreach($name in @('InitializeUninstall','CurUninstallStepChanged')){
 $m=[regex]::Match($source,'(?ms)^(?:function|procedure) '+$name+'\b.*?(?=^(?:function|procedure) |\z)')
 if($m.Success){$blocks+=$m.Value.Replace('MsgBox(','FixtureMsgBox(').Replace('Abort;','FixtureAbort;')}
 elseif($name -eq 'InitializeUninstall'){$blocks+='function InitializeUninstall:Boolean;begin Result:=True;end;'}
 else{$blocks+='procedure CurUninstallStepChanged(CurUninstallStep:TUninstallStep);begin end;'}
}
$header=@'
#define ReleaseId "fixture-runtime"
#define SetupReceiptHelperSha256 "aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa"
#define UninstallHelperSha256 "bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb"
#define RemovalHelperSha256 "cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc"
#define SourceBuildHelperSha256 "dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd"
#define UpdaterSha256 "eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee"
#define ReleaseSha256 "aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa"
#define ReleaseManifestSha256 "bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb"
#define DependencyManifestSha256 "cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc"
#define BootstrapSha256 "dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd"
#define AppHealthHelperSha256 "eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee"
#define SetupNoticeRows '[]'
#define SetupHelperRows '[{"path":"uninstall-owned-release.ps1","bytes":1,"sha256":"bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb"},{"path":"write-setup-receipt.ps1","bytes":1,"sha256":"aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa"},{"path":"remove-owned-file.ps1","bytes":1,"sha256":"cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc"},{"path":"run-source-build.ps1","bytes":1,"sha256":"dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd"},{"path":"update.ps1","bytes":1,"sha256":"eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee"}]'
[Setup]
AppId=AutoClipUninstallHookDiagnostic
AppName=AutoClip uninstall hook diagnostic
AppVersion=1
DefaultDirName={tmp}\never-installed
CreateAppDir=no
Uninstallable=no
PrivilegesRequired=lowest
OutputBaseFilename=uninstall-hook-diagnostic
[Code]
var Checks,Cleanups,Retirements:Integer;FixtureFail,FixturePreserved,Aborted,UninstallCleanRemoval,UninstallPreserved:Boolean;FixtureResult,FixtureCommand,FixtureHandoffPath,FixtureHandoffHash:String;
 ProfilePage:TInputOptionWizardPage;
 DownloadPage:TOutputMarqueeProgressWizardPage;
 BuildAttemptDirectory,SourceHandoffSha256:String;
 SetupReceiptComplete:Boolean;
function ReleaseRoot:String;begin Result:=ExpandConstant('{tmp}\first-party-release');end;
procedure VerifyHelper(Name,Pin:String);begin end;
function FixtureExec(Filename,Params,WorkingDir:String;ShowCmd:Integer;Wait:TExecWait;var Code:Integer):Boolean;
begin SaveStringToFile(FixtureResult+'.'+FixtureCommand,Params,False);Code:=0;Result:=True;end;
function FixtureRegValueExists(Root:Integer;Key,Name:String):Boolean;begin Result:=True;end;
function FixtureRegWriteStringValue(Root:Integer;Key,Name,Value:String):Boolean;begin SaveStringToFile(FixtureResult+'.registration-'+Name,Value,False);Result:=True;end;
function FixtureMsgBox(Text:String;Typ:TMsgBoxType;Buttons:Integer):Integer;begin Result:=IDOK;end;
procedure FixtureAbort;begin Aborted:=True;RaiseException('first-party fixture abort');end;
function RunManagedUninstall(CheckOnly:Boolean):Boolean;
begin
 if CheckOnly then Checks:=Checks+1 else begin Cleanups:=Cleanups+1;UninstallCleanRemoval:=not FixtureFail and not FixturePreserved;UninstallPreserved:=not FixtureFail and FixturePreserved;end;
 Result:=not FixtureFail;
end;
function RetireUninstallEvidence:Boolean;begin Retirements:=Retirements+1;Result:=True;end;
'@
$tail=@'
procedure InitializeWizard;
var I:Integer;Ok:Boolean;
begin
 for I:=1 to ParamCount do if Pos('/RESULT=',ParamStr(I))=1 then FixtureResult:=Copy(ParamStr(I),9,MaxInt);
 if not InitializeUninstall or (Checks<>1) or (Cleanups<>0) then RaiseException('Initialization omitted read-only preflight or performed cleanup');
 CurUninstallStepChanged(usAppMutexCheck);
 CurUninstallStepChanged(usPostUninstall);
 if Cleanups<>0 then RaiseException('Cleanup outside post-confirmation uninstall stage');
 FixtureFail:=True;if InitializeUninstall then RaiseException('Changed native ownership accepted');
 if Cleanups<>0 then RaiseException('Rejected preflight performed cleanup');
 FixtureFail:=False;CurUninstallStepChanged(usUninstall);
 if Cleanups<>1 then RaiseException('Confirmed uninstall omitted managed cleanup');
 CurUninstallStepChanged(usPostUninstall);
 if Retirements<>1 then RaiseException('Clean native completion omitted evidence retirement');
 FixturePreserved:=True;CurUninstallStepChanged(usUninstall);CurUninstallStepChanged(usPostUninstall);
 if Retirements<>1 then RaiseException('Preserved files lost their receipt evidence');
 FixtureFail:=True;Ok:=False;
 try CurUninstallStepChanged(usUninstall);except Ok:=True;end;
 if not Ok or not Aborted then RaiseException('Cleanup failure allowed native deletion');
 if ValidUninstallHandoff('',StringOfChar('f',64)) or ValidUninstallHandoff('fixture','wrong') or not ValidUninstallHandoff('fixture',StringOfChar('f',64)) then RaiseException('Direct invocation accepted missing/invalid handoff');
 FixtureCommand:='direct';if CapturedRunManagedUninstall(True) then RaiseException('Direct native callback accepted absent launch handoff');
 FixtureHandoffPath:='fixture-handoff.json';FixtureHandoffHash:=StringOfChar('f',64);
 SaveStringToFile(FixtureResult+'.loader',BuildUninstallCommand(False),False);
 if Pos('-LaunchNativeUninstall',BuildUninstallCommand(False))=0 then RaiseException('Registered command omitted verified pre-native launcher');
 FixtureCommand:='preflight';if not CapturedRunManagedUninstall(True) then RaiseException('Preflight boundary failed');
 FixtureCommand:='cleanup';if not CapturedRunManagedUninstall(False) then RaiseException('Cleanup boundary failed');
 FixtureCommand:='retire';if not CapturedRetireUninstallEvidence then RaiseException('Retirement boundary failed');
 FixtureCommand:='anchor';PublishUninstallAnchor(ExpandConstant('{tmp}\first-party-descriptor.json'));
 FixtureCommand:='shortcut';PrepareNativeShortcutDirectory;
 ProfilePage:=CreateInputOptionPage(wpWelcome,'fixture','','',True,False);ProfilePage.Add('cpu');ProfilePage.Add('gpu');ProfilePage.Values[0]:=True;
 DownloadPage:=CreateOutputMarqueeProgressPage('fixture','No application/native vendor actions');
 BuildAttemptDirectory:=ExpandConstant('{tmp}\first-party-build');ForceDirectories(BuildAttemptDirectory);
 ForceDirectories(ExpandConstant('{tmp}\first-party-menu'));
 SaveStringToFile(ExpandConstant('{tmp}\first-party-menu\AutoClip.lnk'),'inert fixture shortcut',False);
 SourceHandoffSha256:=StringOfChar('f',64);
 SaveStringToFile(ExpandConstant('{tmp}\write-setup-receipt.ps1'),
  'param([switch]$Finalize,[string]$RequestPath,[string]$RequestSha256)' + #13#10 +
  'if(-not $Finalize -or (Get-FileHash $RequestPath).Hash.ToLowerInvariant() -cne $RequestSha256){exit 23}' + #13#10 +
  '[IO.File]::WriteAllText(($RequestPath+''.receipt.json''),''{"status":"COMPLETE"}'')' + #13#10 +
  'exit 0',False);
 FixtureCommand:='finalized-anchor';FinalizeSetupReceipt;
 if not SetupReceiptComplete then RaiseException('Compiled finalization omitted completion');
 if not FileCopy(BuildAttemptDirectory+'\final-request.json',FixtureResult+'.request.json',False) then RaiseException('Final request evidence missing');
 SaveStringToFile(FixtureResult,'PASS',False);Abort;
end;
'@
[IO.File]::WriteAllText((Join-Path $root 'diagnostic.iss'),$header+"`n"+($blocks-join "`n")+"`n"+$tail)
$old=$ErrorActionPreference
try{$ErrorActionPreference='Continue';$compile=& $IsccPath ('--output-dir='+$root) (Join-Path $root 'diagnostic.iss') 2>&1|Out-String;$code=$LASTEXITCODE}finally{$ErrorActionPreference=$old}
[IO.File]::WriteAllText((Join-Path $root 'compile.log'),$compile)
if($code -ne 0){throw "Diagnostic compile failed: $compile"}
$result=Join-Path $root 'result.txt'
$process=Start-Process -FilePath (Join-Path $root 'uninstall-hook-diagnostic.exe') -ArgumentList @('/VERYSILENT','/SUPPRESSMSGBOXES','/NORESTART',('/LOG='+$result+'.log'),('/RESULT='+$result),'/AUTOCLIP-HANDOFF=fixture-handoff.json',('/AUTOCLIP-HANDOFF-SHA256='+('f'*64))) -WindowStyle Hidden -PassThru
if(-not $process.WaitForExit(30000)){$process.Kill();throw 'Diagnostic timeout.'}
if(-not(Test-Path $result)){throw "Uninstall hook diagnostic failed; evidence=$root"}
if([IO.File]::ReadAllText($result)-ne'PASS'){throw 'Wrong hook result.'}
$loader=[IO.File]::ReadAllText($result+'.loader')
if($loader -cnotmatch '^"?[A-Za-z]:\\.+powershell\.exe"? -NoProfile' -or $loader -notmatch 'File.*Open' -or $loader -notmatch 'Get-FileHash' -or $loader -notmatch '-LaunchNativeUninstall'){throw 'Compiled loader missing absolute native PowerShell or consumer pin.'}
foreach($name in @('UninstallString')){
 if([IO.File]::ReadAllText($result+'.registration-'+$name)-cne$loader){throw 'Compiled registration differs from receipt-bound launcher.'}
}
$quietLoader=[IO.File]::ReadAllText($result+'.registration-QuietUninstallString')
if($quietLoader -notmatch ' -NativeSilent' -or $loader -match ' -NativeSilent'){throw 'Quiet uninstall registration lost fixed native silent semantics.'}
# Execute the compiled loader with an inert first-party consumer. No native uninstall.
$launcherFixture=Join-Path $root 'inert-launcher'
[IO.Directory]::CreateDirectory((Join-Path $launcherFixture 'installation-receipts'))|Out-Null
$fixtureConsumer=Join-Path $launcherFixture 'uninstall-owned-release.ps1'
$fixtureMarker=Join-Path $launcherFixture 'invoked.json'
$fixtureText=@'
param([switch]$LaunchNativeUninstall,[switch]$NativeSilent,[string]$ReceiptPath,[string]$ReceiptSha256,[string]$ReleaseId,[string]$InstallRoot,[string]$ReceiptHelperSha256,[string]$RemovalHelperSha256,[string]$SourceBuildHelperSha256,[string]$UpdaterSha256)
if(-not $LaunchNativeUninstall -or $ReceiptSha256 -cne ('f'*64) -or $ReleaseId-cne'fixture-runtime'){exit 23}
$PSBoundParameters|ConvertTo-Json -Compress|Set-Content -LiteralPath (Join-Path $PSScriptRoot 'invoked.json')
exit 0
'@
[IO.File]::WriteAllText($fixtureConsumer,$fixtureText)
[IO.File]::WriteAllText((Join-Path $launcherFixture 'installation-receipts/fixture-runtime.sha256'),('f'*64))
$loaderCommand=[regex]::Match($loader,'(?s)-Command "(.*)"$').Groups[1].Value
if(-not $loaderCommand){throw 'Compiled launcher command missing.'}
$loaderCommand=[regex]::Replace($loaderCommand,'\$s=''[^'']*''',('$s='''+$launcherFixture.Replace("'","''")+"'"))
$loaderCommand=$loaderCommand.Replace(('b'*64),(Get-FileHash $fixtureConsumer).Hash.ToLowerInvariant())
$loaderScript=Join-Path $root 'actual-launcher-fixture.ps1'
[IO.File]::WriteAllText($loaderScript,$loaderCommand)
& powershell.exe -NoProfile -NonInteractive -File $loaderScript
if($LASTEXITCODE-ne0 -or !(Test-Path $fixtureMarker)){throw 'Pinned compiled loader did not invoke inert launch consumer.'}
$invocation=Get-Content $fixtureMarker -Raw|ConvertFrom-Json
if($invocation.ReceiptHelperSha256-cne('a'*64) -or $invocation.RemovalHelperSha256-cne('c'*64) -or $invocation.SourceBuildHelperSha256-cne('d'*64) -or $invocation.UpdaterSha256-cne('e'*64)){throw 'Launcher helper authority differs.'}
$quietCommand=[regex]::Match($quietLoader,'(?s)-Command "(.*)"$').Groups[1].Value
$quietCommand=[regex]::Replace($quietCommand,'\$s=''[^'']*''',('$s='''+$launcherFixture.Replace("'","''")+"'"))
$quietCommand=$quietCommand.Replace(('b'*64),(Get-FileHash $fixtureConsumer).Hash.ToLowerInvariant())
[IO.File]::WriteAllText($loaderScript,$quietCommand)
& powershell.exe -NoProfile -NonInteractive -File $loaderScript
if($LASTEXITCODE-ne0 -or -not(Get-Content $fixtureMarker -Raw|ConvertFrom-Json).NativeSilent){throw 'Quiet compiled loader omitted fixed NativeSilent switch.'}
$beforeMarker=[IO.File]::ReadAllBytes($fixtureMarker)
[IO.File]::AppendAllText($fixtureConsumer,"`n# changed helper")
$old=$ErrorActionPreference
try{$ErrorActionPreference='Continue';$output=& powershell.exe -NoProfile -NonInteractive -File $loaderScript 2>&1|Out-String;$code=$LASTEXITCODE}finally{$ErrorActionPreference=$old}
if($code-ne23 -or [Convert]::ToBase64String([IO.File]::ReadAllBytes($fixtureMarker))-cne[Convert]::ToBase64String($beforeMarker)){throw 'Changed consumer executed despite launcher pin.'}
$request=Get-Content ($result+'.request.json') -Raw|ConvertFrom-Json
$expectedHelpers=@('uninstall-owned-release.ps1','write-setup-receipt.ps1','remove-owned-file.ps1','run-source-build.ps1','update.ps1')
if($request.native_uninstaller -notmatch 'unins[0-9]+\.exe$' -or $request.uninstall_command-cne$loader -or $request.quiet_uninstall_command-cne$quietLoader -or $request.schema_version-ne1 -or $request.context.release_id-cne'fixture-runtime' -or $request.context.profile-cne'cpu' -or $request.handoff_sha256-cne('f'*64) -or
 @($request.helpers).Count-ne5 -or ((@($request.helpers.path|Sort-Object)-join'|')-cne(@($expectedHelpers|Sort-Object)-join'|')) -or
 !(Test-Path ($result+'.finalized-anchor'))){throw 'Actual compiled finalization request/helper/anchor sequence differs.'}
foreach($name in @('preflight','cleanup','retire','anchor','shortcut')){
 $params=[IO.File]::ReadAllText($result+'.'+$name)
 $command=[regex]::Match($params,'(?s)-Command "(.*)"$').Groups[1].Value
 if($name -in @('preflight','cleanup') -and ($command -notmatch '-HandoffPath' -or $command -notmatch '-HandoffSha256')){throw 'Callback omitted receipt-bound native handoff.'}
 if(-not $command){throw "Actual command missing: $name"}
 $tokens=$null;$errors=$null
 $null=[Management.Automation.Language.Parser]::ParseInput($command,[ref]$tokens,[ref]$errors)
 if($errors.Count){throw "Actual $name command does not parse: $($errors.Message -join '|')"}
 [IO.File]::WriteAllText((Join-Path $root ($name+'.ps1')),$command)
}
# Exercise final-receipt anchoring in a new private protected fixture directory.
$worker=[IO.File]::ReadAllText((Join-Path $repo 'installer/run-source-build.ps1'))
$tokens=$null;$errors=$null
$ast=[Management.Automation.Language.Parser]::ParseInput($worker,[ref]$tokens,[ref]$errors)
$nodes=@($ast.FindAll({param($n)$n -is [Management.Automation.Language.FunctionDefinitionAst] -and $n.Name -ceq 'New-BuildDirectoryAcl'},$true))
if($errors.Count -or $nodes.Count-ne1){throw 'Fixture directory ACL helper differs.'}
. ([scriptblock]::Create($nodes[0].Extent.Text))
$setup=Join-Path $root 'private-setup'
[IO.Directory]::CreateDirectory($setup,(New-BuildDirectoryAcl))|Out-Null
$receiptDirectory=Join-Path $setup 'installation-receipts'
[IO.Directory]::CreateDirectory($receiptDirectory,(New-BuildDirectoryAcl))|Out-Null
$receiptHelper=Join-Path $setup 'write-setup-receipt.ps1'
[IO.File]::Copy((Join-Path $repo 'installer/write-setup-receipt.ps1'),$receiptHelper,$false)
$helperHash=(Get-FileHash $receiptHelper).Hash.ToLowerInvariant()
$receipt=Join-Path $receiptDirectory 'fixture-runtime.json'
[IO.File]::WriteAllText($receipt,(@{schema_version=1;status='COMPLETE';context=@{release_id='fixture-runtime'};setup_root=$setup}|ConvertTo-Json -Compress))
$receiptOriginal=[IO.File]::ReadAllBytes($receipt)
$receiptHash=(Get-FileHash $receipt).Hash.ToLowerInvariant()
$descriptor=Join-Path $setup 'descriptor.json'
$descriptorData=@{path=$receipt;sha256=$receiptHash;bytes=(Get-Item $receipt).Length}|ConvertTo-Json -Compress
[IO.File]::WriteAllText($descriptor,$descriptorData)
$anchorCommand=[IO.File]::ReadAllText((Join-Path $root 'anchor.ps1'))
$anchorCommand=[regex]::Replace($anchorCommand,'\$s=''[^'']*''',('$s='''+$setup.Replace("'","''")+"'"))
$anchorCommand=[regex]::Replace($anchorCommand,"Get-SetupReceiptFile '[^']*first-party-descriptor.json'",("Get-SetupReceiptFile '"+$descriptor.Replace("'","''")+"'"))
$anchorCommand=$anchorCommand.Replace(('a'*64),$helperHash)
$anchorScript=Join-Path $root 'actual-anchor-fixture.ps1'
[IO.File]::WriteAllText($anchorScript,$anchorCommand)
foreach($attempt in 1,2){
 $old=$ErrorActionPreference
 try{$ErrorActionPreference='Continue';$output=& powershell.exe -NoProfile -NonInteractive -File $anchorScript 2>&1|Out-String;$code=$LASTEXITCODE}finally{$ErrorActionPreference=$old}
 if($code-ne0){throw "Exact anchor publication failed: $output"}
}
$anchor=Join-Path $receiptDirectory 'fixture-runtime.sha256'
if([IO.File]::ReadAllText($anchor)-cne$receiptHash){throw 'Final receipt anchor differs.'}
[IO.File]::AppendAllText($receipt,"`nchanged")
$old=$ErrorActionPreference
try{$ErrorActionPreference='Continue';$null=& powershell.exe -NoProfile -NonInteractive -File $anchorScript 2>&1;$code=$LASTEXITCODE}finally{$ErrorActionPreference=$old}
if($code-ne23 -or [IO.File]::ReadAllText($anchor)-cne$receiptHash){throw 'Changed receipt altered the anchor.'}
# Verify finite evidence retirement with simulated completed native cleanup.
$logs=Join-Path $setup 'logs'
[IO.Directory]::CreateDirectory($logs,(New-BuildDirectoryAcl))|Out-Null
$retirement=Join-Path $logs 'uninstall-fixture-runtime'
[IO.Directory]::CreateDirectory($retirement,(New-BuildDirectoryAcl))|Out-Null
[IO.File]::Copy($receiptHelper,(Join-Path $retirement 'write-setup-receipt.ps1'),$false)
$removal=Join-Path $retirement 'remove-owned-file.ps1'
[IO.File]::Copy((Join-Path $repo 'installer/remove-owned-file.ps1'),$removal,$false)
$removalHash=(Get-FileHash $removal).Hash.ToLowerInvariant()
$record=@{schema_version=1;release_id='fixture-runtime';setup_root=$setup;
 rows=@(@{path='installation-receipts/fixture-runtime.json';bytes=$receiptOriginal.Length;sha256=$receiptHash},
        @{path='installation-receipts/fixture-runtime.sha256';bytes=(Get-Item $anchor).Length;sha256=(Get-FileHash $anchor).Hash.ToLowerInvariant()});
 native=@('unins999.exe','unins999.dat')}
[IO.File]::WriteAllText((Join-Path $retirement 'retirement.json'),($record|ConvertTo-Json -Depth 6 -Compress))
$retireCommand=[IO.File]::ReadAllText((Join-Path $root 'retire.ps1'))
$retireCommand=[regex]::Replace($retireCommand,'\$s=''[^'']*''',('$s='''+$setup.Replace("'","''")+"'"))
$retireCommand=$retireCommand.Replace(('a'*64),$helperHash).Replace(('c'*64),$removalHash)
# Fixed first-party absent registration fixture; no registry mutation.
$retireCommand=$retireCommand.Replace('Software\Microsoft\Windows\CurrentVersion\Uninstall\{D7451842-48F4-487B-80E0-5C7E9E326342}_is1',('Software\AutoClip\InertUninstallFixture\'+[guid]::NewGuid().ToString('N')))
$retireScript=Join-Path $root 'actual-retirement-fixture.ps1'
[IO.File]::WriteAllText($retireScript,$retireCommand)
$old=$ErrorActionPreference
try{$ErrorActionPreference='Continue';$output=& powershell.exe -NoProfile -NonInteractive -File $retireScript 2>&1|Out-String;$code=$LASTEXITCODE}finally{$ErrorActionPreference=$old}
if($code-ne23 -or !(Test-Path $receipt) -or !(Test-Path $anchor)){throw "Changed evidence not preserved: $output"}
[IO.File]::WriteAllBytes($receipt,$receiptOriginal)
$old=$ErrorActionPreference
try{$ErrorActionPreference='Continue';$output=& powershell.exe -NoProfile -NonInteractive -File $retireScript 2>&1|Out-String;$code=$LASTEXITCODE}finally{$ErrorActionPreference=$old}
if($code-ne0 -or (Test-Path $receipt) -or (Test-Path $anchor)){throw "Finite evidence retirement failed: $output"}
"PASS actual compiled uninstall callbacks; inert cleanup boundary; evidence=$root"
