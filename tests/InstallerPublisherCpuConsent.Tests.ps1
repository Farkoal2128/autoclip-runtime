param([string]$IsccPath='D:\AutoClip-Inno-Migration\InnoSetup7\ISCC.exe')
$ErrorActionPreference='Stop'
$repo=Split-Path -Parent $PSScriptRoot
$source=[IO.File]::ReadAllText((Join-Path $repo 'installer/AutoClip.iss'))
if((Get-FileHash $IsccPath).Hash -ne 'd06ebd38f38e3cee60a3c50cc45bd449d77e0bc6a5cabc607ea9886808e4de1a'){throw 'Compiler pin differs.'}
$root=Join-Path $env:TEMP ('autoclip-cpu-consent-'+[guid]::NewGuid().ToString('N'))
[IO.Directory]::CreateDirectory($root)|Out-Null
$blocks=@()
foreach($name in @('UsePublisherCpu','MsysPowerShellQuote','PublisherVcConsentStatus','ShouldSkipPage','NextButtonClick','VendorConsentBuildArguments')){
 $m=[regex]::Match($source,'(?ms)^function '+$name+'\b.*?(?=^(?:function|procedure) |\z)')
 if($m.Success){$blocks+=$m.Value.Replace('ExecWithNativeSysDir(','FixtureExec(').Replace('MsgBox(','FixtureMsgBox(')}
 elseif($name -eq 'PublisherVcConsentStatus'){$blocks+='function PublisherVcConsentStatus:Integer;begin Result:=23;end;'}
 elseif($name -eq 'VendorConsentBuildArguments'){$blocks+='function VendorConsentBuildArguments:String;begin Result:='','' + ''"AcceptMicrosoftTerms":true'';end;'}
 else{throw "Missing actual decision: $name"}
}
$header=@'
#define NativeCpuEnabled 1
#define DependencyManifestSha256 "aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa"
#define VcRuntimeHelperSha256 "bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb"
#define ReleaseId "fixture"
#define ReleaseUrl "https://github.com/example/runtime/releases/download/test/fixture.zip"
[Setup]
AppId=AutoClipConsentDiagnostic
AppName=AutoClip consent diagnostic
AppVersion=1
DefaultDirName={tmp}\never-installed
CreateAppDir=no
Uninstallable=no
PrivilegesRequired=lowest
OutputBaseFilename=consent-diagnostic
[Code]
var
 ProfilePage,ConsentPage,NvidiaConsentPage,PythonConsentPage,MsysConsentPage:TInputOptionWizardPage;
 SummaryPage:TWizardPage;
 SummaryText:TMemo;
 PreflightReady:Boolean;
 VcConsentStatus,FixtureCode:Integer;
 FixtureResult:String;
function ToolAvailable(Identity:String):Boolean;begin Result:=True;end;
procedure RunPreflight;begin PreflightReady:=True;end;
function MsysSummary:String;begin Result:='fixture';end;
function FixtureMsgBox(Text:String;Typ:TMsgBoxType;Buttons:Integer):Integer;begin Result:=IDOK;end;
procedure VerifyHelper(Name,Pin:String);
begin
 if (Name<>'install-vc-runtime.ps1') or (Pin<>'{#VcRuntimeHelperSha256}') then RaiseException('Wrong capability helper pin');
end;
function FixtureExec(Filename,Params,WorkingDir:String;ShowCmd:Integer;Wait:TExecWait;var Code:Integer):Boolean;
begin
 if Pos('-CheckOnly',Params)=0 then RaiseException('VC check would provision');
 if Pos('publisher-cache\vc-runtime',Params)=0 then RaiseException('Wrong shared VC state');
 SaveStringToFile(FixtureResult+'.command',Params,False);
 Code:=FixtureCode;Result:=FixtureCode>=0;
end;
'@
$tail=@'
procedure InitializeWizard;
var I:Integer;J:String;
begin
 for I:=1 to ParamCount do if Pos('/RESULT=',ParamStr(I))=1 then FixtureResult:=Copy(ParamStr(I),9,MaxInt);
 ProfilePage:=CreateInputOptionPage(wpWelcome,'profile','','',True,False);ProfilePage.Add('cpu');ProfilePage.Add('gpu');ProfilePage.Values[0]:=True;
 ConsentPage:=CreateInputOptionPage(ProfilePage.ID,'Microsoft','','',False,False);ConsentPage.Add('Microsoft');
 NvidiaConsentPage:=CreateInputOptionPage(ConsentPage.ID,'NVIDIA','','',False,False);NvidiaConsentPage.Add('CUDA');NvidiaConsentPage.Add('cuBLAS');
 PythonConsentPage:=CreateInputOptionPage(NvidiaConsentPage.ID,'Python','','',False,False);PythonConsentPage.Add('Python');
 MsysConsentPage:=CreateInputOptionPage(PythonConsentPage.ID,'MSYS','','',False,False);MsysConsentPage.Add('MSYS');
 SummaryPage:=CreateCustomPage(MsysConsentPage.ID,'summary','');SummaryText:=TMemo.Create(SummaryPage);SummaryText.Parent:=SummaryPage.Surface;PreflightReady:=True;
 VcConsentStatus:=0;
 if not ShouldSkipPage(NvidiaConsentPage.ID) then RaiseException('CPU presents NVIDIA terms');
 if not ShouldSkipPage(ConsentPage.ID) then RaiseException('Valid Microsoft capability requires provisioning consent');
 J:=VendorConsentBuildArguments;
 if Pos('AcceptMicrosoftTerms',J)>0 then RaiseException('Implicit Microsoft declaration');
 ConsentPage.Values[0]:=True;
 if Pos('AcceptMicrosoftTerms',VendorConsentBuildArguments)>0 then RaiseException('Skipped page declared Microsoft terms');
 ConsentPage.Values[0]:=False;
 if Pos('AcceptNvidia',J)>0 then RaiseException('CPU declares NVIDIA terms');
 VcConsentStatus:=2;
 if ShouldSkipPage(ConsentPage.ID) then RaiseException('Missing Microsoft skipped consent');
 if NextButtonClick(ConsentPage.ID) then RaiseException('Missing Microsoft advanced without checkbox');
 ConsentPage.Values[0]:=True;
 if Pos('"AcceptMicrosoftTerms":true',VendorConsentBuildArguments)=0 then RaiseException('Explicit Microsoft declaration omitted');
 ProfilePage.Values[0]:=False;ProfilePage.Values[1]:=True;
 if ShouldSkipPage(NvidiaConsentPage.ID) then RaiseException('GPU skips NVIDIA page');
 if NextButtonClick(NvidiaConsentPage.ID) then RaiseException('GPU advanced without NVIDIA consent');
 if Pos('AcceptNvidia',VendorConsentBuildArguments)>0 then RaiseException('Implicit NVIDIA declaration');
 NvidiaConsentPage.Values[0]:=True;NvidiaConsentPage.Values[1]:=True;
 J:=VendorConsentBuildArguments;
 if (Pos('"AcceptNvidiaTerms":true',J)=0) or (Pos('"AcceptCublasTerms":true',J)=0) then RaiseException('GPU explicit declaration omitted');
 ProfilePage.Values[0]:=True;ProfilePage.Values[1]:=False;
 FixtureCode:=0;if PublisherVcConsentStatus<>0 then RaiseException('Valid VC rejected');
 FixtureCode:=2;if PublisherVcConsentStatus<>2 then RaiseException('Missing VC rejected');
 FixtureCode:=3010;if PublisherVcConsentStatus<>3010 then RaiseException('Reboot state ignored');
 FixtureCode:=1618;if PublisherVcConsentStatus=0 then RaiseException('Busy VC accepted');
 FixtureCode:=23;if PublisherVcConsentStatus=0 then RaiseException('Unknown VC accepted');
 FixtureCode:=0;if not NextButtonClick(SummaryPage.ID) then RaiseException('Ready VC blocked summary');
 FixtureCode:=2;if not NextButtonClick(SummaryPage.ID) then RaiseException('Missing VC blocked before consent');
 FixtureCode:=3010;if NextButtonClick(SummaryPage.ID) then RaiseException('Pending reboot advanced summary');
 FixtureCode:=1618;if NextButtonClick(SummaryPage.ID) then RaiseException('Busy VC advanced summary');
 FixtureCode:=23;if NextButtonClick(SummaryPage.ID) then RaiseException('Unknown VC advanced summary');
 if NextButtonClick(ConsentPage.ID) then RaiseException('Unknown VC advanced consent');
 FixtureCode:=-1;if PublisherVcConsentStatus<>23 then RaiseException('Failed helper launch accepted');
 SaveStringToFile(FixtureResult,'PASS',False);Abort;
end;
'@
[IO.File]::WriteAllText((Join-Path $root 'diagnostic.iss'),$header+"`n"+($blocks-join "`n")+"`n"+$tail)
$old=$ErrorActionPreference
try{$ErrorActionPreference='Continue';$compile=& $IsccPath ('--output-dir='+$root) (Join-Path $root 'diagnostic.iss') 2>&1|Out-String;$code=$LASTEXITCODE}finally{$ErrorActionPreference=$old}
[IO.File]::WriteAllText((Join-Path $root 'compile.log'),$compile)
if($code -ne 0){throw "Diagnostic compile failed: $compile"}
$result=Join-Path $root 'result.txt'
$process=Start-Process -FilePath (Join-Path $root 'consent-diagnostic.exe') -ArgumentList @('/VERYSILENT','/SUPPRESSMSGBOXES','/NORESTART',('/LOG='+$result+'.log'),('/RESULT='+$result)) -WindowStyle Hidden -PassThru
if(-not $process.WaitForExit(30000)){$process.Kill();throw 'Consent diagnostic timeout.'}
if(-not(Test-Path $result)){throw "Consent diagnostic failed; evidence=$root"}
if([IO.File]::ReadAllText($result)-ne'PASS'){throw 'Wrong consent outcome.'}
# Run the exact compiled PowerShell command against an inert first-party helper.
# Replace only the fixture input paths/pins; the production framing stays intact.
$params=[IO.File]::ReadAllText($result+'.command')
$command=[regex]::Match($params,'(?s)-Command "(.*)"$').Groups[1].Value
if(-not $command){throw 'Actual CheckOnly command missing.'}
$fixtureHelper=Join-Path $root 'first-party-vc-fixture.ps1'
$fixtureManifest=Join-Path $root 'manifest.json'
[IO.File]::WriteAllText($fixtureManifest,'{"schema_version":1}')
$fixture=@'
param([switch]$CheckOnly,[string]$ManifestPath,[string]$ManifestSha256,[string]$StateDirectory)
if(-not $CheckOnly -or $StateDirectory -ne (Join-Path $env:LOCALAPPDATA 'AutoClip\publisher-cache\vc-runtime') -or
 (Get-FileHash $ManifestPath).Hash.ToLowerInvariant() -ne $ManifestSha256){exit 23}
[IO.File]::AppendAllText((Join-Path $PSScriptRoot 'calls.txt'),"check`n")
$code=0;$status='ready';$schema=1
switch($env:AUTOCLIP_CONSENT_FIXTURE_CASE){
 'missing'{$code=2;$status='missing'}
 'reboot'{$code=3010;$status='pending_reboot'}
 'busy'{$code=1618;$status='busy'}
 'unknown'{$code=23;$status='unresolved'}
 'contradictory'{$status='missing'}
 'schema-string'{$schema='1'}
 'multiple'{[Console]::Out.WriteLine('{}')}
 'malformed'{[Console]::Out.WriteLine('broken');exit 0}
}
@{schema_version=$schema;status=$status;exit_code=$code}|ConvertTo-Json -Compress
exit $code
'@
[IO.File]::WriteAllText($fixtureHelper,$fixture)
$manifestHash=(Get-FileHash $fixtureManifest).Hash.ToLowerInvariant()
$helperHash=(Get-FileHash $fixtureHelper).Hash.ToLowerInvariant()
$command=[regex]::Replace($command,'\$m=''[^'']*''',('$m='''+$fixtureManifest.Replace("'","''")+"'"))
$command=[regex]::Replace($command,'\$h=''[^'']*''',('$h='''+$fixtureHelper.Replace("'","''")+"'"))
$command=$command.Replace(('a'*64),$manifestHash).Replace(('b'*64),$helperHash)
$wrapper=Join-Path $root 'actual-vc-check-command.ps1'
[IO.File]::WriteAllText($wrapper,$command)
$priorCase=$env:AUTOCLIP_CONSENT_FIXTURE_CASE
try{
 foreach($case in @('ready','missing','reboot','busy','unknown','contradictory','schema-string','multiple','malformed')){
  $env:AUTOCLIP_CONSENT_FIXTURE_CASE=$case
  $old=$ErrorActionPreference
  try{$ErrorActionPreference='Continue';$output=& powershell.exe -NoProfile -NonInteractive -File $wrapper 2>&1|Out-String;$actual=$LASTEXITCODE}finally{$ErrorActionPreference=$old}
  $expected=switch($case){'ready'{0};'missing'{2};'reboot'{3010};default{23}}
  if($actual -ne $expected){throw "Actual CheckOnly framing failed: $case actual=$actual expected=$expected output=$output"}
 }
 $calls=[IO.File]::ReadAllText((Join-Path $root 'calls.txt'))
 [IO.File]::AppendAllText($fixtureHelper,"`n# substituted fixture")
 $old=$ErrorActionPreference
 try{$ErrorActionPreference='Continue';$null=& powershell.exe -NoProfile -NonInteractive -File $wrapper 2>&1;$actual=$LASTEXITCODE}finally{$ErrorActionPreference=$old}
 if($actual -ne 23 -or [IO.File]::ReadAllText((Join-Path $root 'calls.txt')) -ne $calls){throw 'Changed capability helper executed.'}
}finally{$env:AUTOCLIP_CONSENT_FIXTURE_CASE=$priorCase}
"PASS actual compiled CPU/GPU consent decisions and CheckOnly boundary; evidence=$root"
