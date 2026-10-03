param([string]$IsccPath='D:\AutoClip-Inno-Migration\InnoSetup7\ISCC.exe')
$ErrorActionPreference='Stop'
$repo=Split-Path -Parent $PSScriptRoot
$source=[IO.File]::ReadAllText((Join-Path $repo 'installer/AutoClip.iss'))
if((Get-FileHash $IsccPath).Hash -ne 'd06ebd38f38e3cee60a3c50cc45bd449d77e0bc6a5cabc607ea9886808e4de1a'){throw 'Compiler pin differs.'}
$blocks=@()
foreach($name in @('UsePublisherCpu','ShouldSkipPage','BuildJsonString','PublisherCpuBuildArguments','PrepareToInstall')) {
    $match=[regex]::Match($source,'(?ms)^function '+$name+'\b.*?(?=^(?:function|procedure) |\z)')
    if($match.Success){$blocks+=$match.Value}
    elseif($name -eq 'UsePublisherCpu'){$blocks+='function UsePublisherCpu: Boolean; begin Result := ProfilePage.Values[0]; end;'}
    else{throw 'Actual PrepareToInstall missing.'}
}
$root=Join-Path $env:TEMP ('autoclip-publisher-cpu-wizard-'+[guid]::NewGuid().ToString('N'))
[IO.Directory]::CreateDirectory($root)|Out-Null
$header=@'
#define NativeCpuEnabled 1
#define CpuNativeIdentity "cpu-fixture-v1"
#define CpuNativeRuntimeId "cpu-fixture-v1"
#define CpuNativeFilename "cpu-fixture-v1.zip"
#define CpuNativeSha256 "e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855"
#define CpuNativeBytes 0
#define CpuNativeHelperSha256 "aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa"
#define PythonPrerequisiteHelperSha256 "bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb"
#define VcRuntimeHelperSha256 "cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc"
#define ReleaseId "first-party-fixture"
#define ReleaseSha256 "e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855"
#define ReleaseManifestSha256 "e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855"
#define FfmpegSha256 "e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855"
#define MinGitSha256 "aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa"
#define UvSha256 "aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa"
[Setup]
AppId=AutoClipPublisherCpuDecisionDiagnostic
AppName=AutoClip CPU decision diagnostic
AppVersion=1
DefaultDirName={tmp}\never-installed
CreateAppDir=no
Uninstallable=no
PrivilegesRequired=lowest
OutputBaseFilename=cpu-decision-diagnostic
[Code]
var
 ProfilePage, PythonConsentPage, MsysConsentPage, ConsentPage, NvidiaConsentPage:TInputOptionWizardPage;
 VcConsentStatus:Integer;
 DownloadPage:TOutputMarqueeProgressWizardPage;
 PreflightReady, GitPrepared, UvPrepared, MsysPrepared, DownloadCancelled:Boolean;
 BuildAttemptDirectory, SourceHandoffSha256, FixtureCase, FixtureResult:String;
 NativeDownloads, Builds, ToolInstalls, HelperPins:Integer;
procedure VerifyHelper(Name, ExpectedHash:String);
begin
 if (Name='install-cpu-native-artifact.py') and (ExpectedHash=StringOfChar('a',64)) then HelperPins:=HelperPins+1
 else if (Name='install-python.ps1') and (ExpectedHash=StringOfChar('b',64)) then HelperPins:=HelperPins+1
 else if (Name='install-vc-runtime.ps1') and (ExpectedHash=StringOfChar('c',64)) then HelperPins:=HelperPins+1
 else RaiseException('Wrong CPU helper pin');
end;
function ToolAvailable(Identity:String):Boolean;
begin
 if Identity='Git for Windows' then RaiseException('CPU developer prerequisite invoked: Git');
 Result:=FixtureCase<>'needs-uv';
end;
function PreparePython(var NeedsRestart:Boolean):String;
begin Result:='';end;
function PrepareMsys:String;
begin RaiseException('CPU developer prerequisite invoked: MSYS2'); Result:='';end;
function ReleaseRoot:String;
begin Result:=ExpandConstant('{tmp}\firstparty-cpu-release');end;
function InstallToolArchive(Identity, ArchiveName, Destination:String):Boolean;
begin
 if Identity<>'uv' then RaiseException('CPU extracted developer tool');
 ToolInstalls:=ToolInstalls+1;Result:=True;
end;
function DownloadArtifact(Identity, FileName, ExpectedHash:String):Boolean;
begin
 if Identity='cpu-fixture-v1' then begin
  NativeDownloads:=NativeDownloads+1;
  if (FileName<>'cpu-fixture-v1.zip') or (ExpectedHash<>'{#CpuNativeSha256}') then RaiseException('Wrong CPU download pin');
  if FixtureCase='native-failure' then begin Result:=False;Exit;end;
  if FixtureCase='cancel' then begin DownloadCancelled:=True;Result:=False;Exit;end;
 end else if (Identity<>'first-party-fixture') and (Identity<>'Gyan FFmpeg') and (Identity<>'uv') then RaiseException('CPU downloaded developer tool');
 SaveStringToFile(ExpandConstant('{tmp}\')+FileName,'',False);Result:=True;
end;
function RunSourceBuild(Archive, GitPath, UvPath:String):Boolean;
begin
 if (NativeDownloads=0) or not FileExists(ExpandConstant('{tmp}\cpu-fixture-v1.zip')) or (GitPath<>'') or MsysPrepared then RaiseException('Invalid CPU worker handoff');
 if (FixtureCase='needs-uv') and (UvPath<>ExpandConstant('{tmp}\uv\uv.exe')) then RaiseException('Pinned uv handoff missing');
 Builds:=Builds+1;BuildAttemptDirectory:=ExpandConstant('{tmp}\firstparty-cpu-attempt');
 ForceDirectories(ReleaseRoot);
 SaveStringToFile(ReleaseRoot+'\.install-complete','',False);
 SaveStringToFile(ReleaseRoot+'\release-manifest.json','',False);
 SaveStringToFile(ReleaseRoot+'\AutoClip.lnk','',False);
 SaveStringToFile(ReleaseRoot+'\.setup-source-ownership.json','',False);
 Result:=True;
end;
'@
$tail=@'
procedure InitializeWizard;
var Outcome, Json:String;I:Integer;Restart:Boolean;
begin
 for I:=1 to ParamCount do begin
  if Pos('/CASE=',ParamStr(I))=1 then FixtureCase:=Copy(ParamStr(I),7,MaxInt);
  if Pos('/RESULT=',ParamStr(I))=1 then FixtureResult:=Copy(ParamStr(I),9,MaxInt);
 end;
 ProfilePage:=CreateInputOptionPage(wpWelcome,'Fixture','Fixture','CPU',True,False);
 ProfilePage.Add('CPU');ProfilePage.Add('GPU');ProfilePage.Values[0]:=True;
 PythonConsentPage:=CreateInputOptionPage(wpWelcome,'Python','Python','Fixture',False,False);
 MsysConsentPage:=CreateInputOptionPage(wpWelcome,'MSYS','MSYS','Fixture',False,False);
 ConsentPage:=CreateInputOptionPage(wpWelcome,'Microsoft','Microsoft','Fixture',False,False);
 NvidiaConsentPage:=CreateInputOptionPage(wpWelcome,'NVIDIA','NVIDIA','Fixture',False,False);
 if not ShouldSkipPage(MsysConsentPage.ID) then RaiseException('CPU displayed MSYS consent');
 DownloadPage:=CreateOutputMarqueeProgressPage('Diagnostic','No native processes');
 PreflightReady:=True;Restart:=False;
 try
  Outcome:=PrepareToInstall(Restart);
  if FixtureCase='retry' then Outcome:=PrepareToInstall(Restart);
 except Outcome:=GetExceptionMessage;end;
 SaveStringToFile(FixtureResult,Outcome+#13#10+IntToStr(NativeDownloads)+#13#10+IntToStr(Builds)+#13#10+IntToStr(ToolInstalls)+#13#10+SourceHandoffSha256,False);
 Json:=PublisherCpuBuildArguments;
 if HelperPins<>3 then RaiseException('Missing CPU helper verification');
 SaveStringToFile(FixtureResult+'.args','{'+Copy(Json,2,MaxInt)+'}',False);
 ProfilePage.Values[0]:=False;ProfilePage.Values[1]:=True;
 if UsePublisherCpu then RaiseException('GPU selected CPU artifact');
 if ShouldSkipPage(MsysConsentPage.ID) then RaiseException('GPU skipped source prerequisite consent');
 if PublisherCpuBuildArguments<>'' then RaiseException('GPU received CPU worker arguments');
 Abort;
end;
'@
[IO.File]::WriteAllText((Join-Path $root 'diagnostic.iss'),$header+"`n"+($blocks-join "`n")+"`n"+$tail)
$old=$ErrorActionPreference
try{$ErrorActionPreference='Continue';$compile=& $IsccPath ('--output-dir='+$root) (Join-Path $root 'diagnostic.iss') 2>&1|Out-String;$code=$LASTEXITCODE}finally{$ErrorActionPreference=$old}
[IO.File]::WriteAllText((Join-Path $root 'compile.log'),$compile)
if($code -ne 0){throw "Diagnostic compile failed: $compile"}
foreach($case in @('success','retry','native-failure','cancel','needs-uv')) {
 $result=Join-Path $root ($case+'.txt')
 $process=Start-Process -FilePath (Join-Path $root 'cpu-decision-diagnostic.exe') -ArgumentList @('/VERYSILENT','/SUPPRESSMSGBOXES','/NORESTART',('/CASE='+$case),('/RESULT='+$result)) -WindowStyle Hidden -PassThru
 if(-not $process.WaitForExit(30000)){throw "Diagnostic timeout: $case"}
 if(-not(Test-Path $result)){throw "No CPU diagnostic result: $case evidence=$root"}
 $lines=[IO.File]::ReadAllText($result).Split(@("`r`n"),[StringSplitOptions]::None)
 $success=$case -in @('success','retry','needs-uv')
 if(($lines[0] -eq '') -ne $success){throw "Wrong CPU outcome $case $($lines-join '|') evidence=$root"}
 $expected=if($case -eq 'retry'){2}else{1}
 if([int]$lines[1] -ne $expected -or [int]$lines[2] -ne $(if($success){$expected}else{0})){throw "Wrong native acquisition/build count: $case"}
 if([int]$lines[3] -ne $(if($case -eq 'needs-uv'){1}else{0})){throw 'Unexpected CPU tool extraction.'}
 if($success -and $lines[4] -ne 'e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855'){throw 'Exact source handoff was not retained.'}
 $arguments=Get-Content ($result+'.args') -Raw|ConvertFrom-Json
 if(@($arguments.PSObject.Properties).Count -ne 4 -or $arguments.CpuNativeArtifactPath -notlike '*\cpu-fixture-v1.zip' -or
    $arguments.CpuNativeHelperSha256 -ne ('a'*64) -or $arguments.PythonPrerequisiteHelperSha256 -ne ('b'*64) -or $arguments.VcRuntimeHelperSha256 -ne ('c'*64)){throw 'Actual CPU worker JSON/pins differ.'}
}
"PASS actual compiled publisher CPU PrepareToInstall success/retry/native failure/cancel/pinned uv; GPU excludes CPU. Evidence: $root"
