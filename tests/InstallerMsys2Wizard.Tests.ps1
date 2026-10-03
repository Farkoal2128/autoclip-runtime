param([string]$IsccPath='D:\AutoClip-Inno-Migration\InnoSetup7\ISCC.exe', [switch]$CompileOnly)
$ErrorActionPreference='Stop'
$repo=Split-Path -Parent $PSScriptRoot
$source=[IO.File]::ReadAllText((Join-Path $repo 'installer/AutoClip.iss'))
$blocks=@()
foreach($name in @('UsePublisherCpu','MsysPowerShellQuote','MsysCommand','MsysResultPaths','PrepareMsys','MsysBuildArguments','PrepareToInstall')) {
    $m=[regex]::Match($source,'(?ms)^function '+$name+'\b.*?(?=^(?:function|procedure) |\z)')
    if(-not $m.Success){throw "Actual MSYS wizard behavioral entry point missing: $name"}
    # Keep actual decisions verbatim; RunSourceBuild is the final first-party fixture boundary.
    $blocks+=$m.Value
}
if((Get-FileHash $IsccPath).Hash -ne 'd06ebd38f38e3cee60a3c50cc45bd449d77e0bc6a5cabc607ea9886808e4de1a'){throw 'Compiler pin differs.'}
$root=Join-Path $env:TEMP ('autoclip-msys-wizard-'+[guid]::NewGuid().ToString('N'))
[IO.Directory]::CreateDirectory($root)|Out-Null
$header=@'
#define NativeCpuEnabled 0
#define MsysArchiveSha256 "a2d047e8ee213c3c6a49a8de427eb1069df12207c0422ff1b3cbb5c905c34221"
#define DependencyManifestSha256 "aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa"
#define MsysBaseHelperSha256 "aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa"
#define MsysExtractorSha256 "aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa"
#define MsysPackagesHelperSha256 "aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa"
#define PythonHelperSha256 "aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa"
#define PreflightSha256 "aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa"
#define ReleaseId "first-party-fixture"
#define ReleaseSha256 "e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855"
#define ReleaseManifestSha256 "e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855"
#define FfmpegSha256 "e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855"
#define MinGitSha256 "aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa"
#define UvSha256 "aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa"
#define BootstrapSha256 "aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa"
#define ToolArchiveHelperSha256 "aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa"
#define RuntimeToolPathHelperSha256 "aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa"
#define SecureDownloaderSha256 "aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa"
[Setup]
AppId=AutoClipMsysDecisionDiagnostic
AppName=AutoClip MSYS decision diagnostic
AppVersion=1
DefaultDirName={tmp}\never-installed
CreateAppDir=no
Uninstallable=no
PrivilegesRequired=lowest
OutputBaseFilename=msys-decision-diagnostic
[Code]
var
 MsysConsentPage:TInputOptionWizardPage;
 ProfilePage:TInputOptionWizardPage;
 DownloadPage:TOutputMarqueeProgressWizardPage;
 MsysPrepared, DownloadCancelled:Boolean;
 PreflightReady, GitPrepared, UvPrepared:Boolean;
 MsysRoot, MsysBaseReceiptPath, MsysPackageReceiptPath, MsysPackageReceiptSha256:String;
 BuildAttemptDirectory, SourceHandoffSha256:String;
 FixtureCase, FixtureResult:String;
 Downloads, Calls, Builds:Integer;
procedure VerifyHelper(Name, ExpectedHash:String);
begin { fixed first-party native boundary fixture; never execute extracted production helpers } end;
function ToolAvailable(Identity:String):Boolean;
begin Result:=True; end;
function PreparePython(var NeedsRestart:Boolean):String;
begin Result:=''; end;
function ReleaseRoot:String;
begin Result:=ExpandConstant('{tmp}\firstparty-release'); end;
function InstallToolArchive(Identity, ArchiveName, Destination:String):Boolean;
begin Result:=True; end;
function RunSourceBuild(Archive, GitPath, UvPath:String):Boolean;
var ExpectedRoot, ExpectedLogs:String;
begin
 ExpectedRoot:=ExpandConstant('{commonappdata}\acm-1234abcd\msys64');
 ExpectedLogs:=ExpandConstant('{localappdata}\acm-log-1234abcd');
 if not MsysPrepared or DownloadCancelled or
    (MsysRoot<>ExpectedRoot) or
    (MsysBaseReceiptPath<>ExpectedLogs+'\base-receipt.json') or
    (MsysPackageReceiptPath<>ExpectedLogs+'\package-receipt.json') or
    (MsysPackageReceiptSha256<>StringOfChar('a',64)) or
    (Archive<>ExpandConstant('{tmp}\autoclip-source-build.zip')) or
    not FileExists(Archive) or
    (GitPath<>'') or (UvPath<>'') then
   RaiseException('Source build without exact authenticated MSYS, archive and tool inputs');
 BuildAttemptDirectory:=ExpandConstant('{tmp}\firstparty-build-attempt');
 Builds:=Builds+1;
 ForceDirectories(ReleaseRoot);
 SaveStringToFile(ReleaseRoot+'\.install-complete','',False);
 SaveStringToFile(ReleaseRoot+'\release-manifest.json','',False);
 SaveStringToFile(ReleaseRoot+'\AutoClip.lnk','',False);
 SaveStringToFile(ReleaseRoot+'\.setup-source-ownership.json','',False);
 Result:=True;
end;
function DownloadArtifact(Identity, FileName, ExpectedHash:String):Boolean;
begin
 if Identity<>'MSYS2' then begin
   if (Identity<>'first-party-fixture') and (Identity<>'Gyan FFmpeg') then RaiseException('Unexpected download');
   SaveStringToFile(ExpandConstant('{tmp}\')+FileName,'',False);Result:=True;Exit;
 end;
 Downloads:=Downloads+1;
 if (Identity<>'MSYS2') or (FileName<>'msys2-base-x86_64-20260611.tar.xz') or (ExpectedHash<>'{#MsysArchiveSha256}') then RaiseException('Wrong acquisition identity');
 Result:=FixtureCase<>'download-failure';
end;
function RunMsysProcess(Recheck:Boolean; var Output:String):Boolean;
var Root, Logs:String;
begin
 Calls:=Calls+1;
 Root:=ExpandConstant('{commonappdata}\acm-1234abcd\msys64');
 Logs:=ExpandConstant('{localappdata}\acm-log-1234abcd');
 Output:=Root+#13#10+Logs+'\base-receipt.json'+#13#10+Logs+'\package-receipt.json'+#13#10+StringOfChar('a',64)+#13#10;
 if FixtureCase='extra-output' then Output:=Output+'extra'+#13#10;
 if FixtureCase='foreign-root' then StringChangeEx(Output,'acm-1234abcd','foreign',True);
 if FixtureCase='foreign-log' then StringChangeEx(Output,'acm-log-1234abcd','acm-log-99999999',True);
 if FixtureCase='upper-hash' then StringChangeEx(Output,StringOfChar('a',64),StringOfChar('A',64),True);
 if FixtureCase='cancel' then DownloadCancelled:=True;
 Result:=(FixtureCase<>'base-failure') and (FixtureCase<>'package-failure') and (FixtureCase<>'postcheck-failure') and not (Recheck and (FixtureCase='tampered-retry'));
end;
'@
$tail=@'
procedure InitializeWizard;
var Outcome, First:String; I:Integer; Restart:Boolean;
begin
 for I:=1 to ParamCount do begin
  if Pos('/CASE=',ParamStr(I))=1 then FixtureCase:=Copy(ParamStr(I),7,MaxInt);
  if Pos('/RESULT=',ParamStr(I))=1 then FixtureResult:=Copy(ParamStr(I),9,MaxInt);
 end;
 MsysConsentPage:=CreateInputOptionPage(wpWelcome,'Diagnostic','Diagnostic','No installation',False,False);
 MsysConsentPage.Add('Fixture consent'); MsysConsentPage.Values[0]:=FixtureCase<>'decline';
 ProfilePage:=CreateInputOptionPage(wpWelcome,'Fixture','Fixture','CPU default',True,False);
 ProfilePage.Add('CPU');ProfilePage.Add('GPU');ProfilePage.Values[0]:=True;
 PreflightReady:=True;Restart:=False;
 DownloadPage:=CreateOutputMarqueeProgressPage('Diagnostic','No native processes');
 Outcome:=PrepareToInstall(Restart); First:=Outcome;
 if (FixtureCase='reuse') or (FixtureCase='tampered-retry') then Outcome:=PrepareToInstall(Restart);
 SaveStringToFile(FixtureResult+'.command',MsysCommand(False),False);
 if MsysPrepared then SaveStringToFile(FixtureResult+'.buildargs',MsysBuildArguments,False);
 SaveStringToFile(FixtureResult,IntToStr(Downloads)+#13#10+IntToStr(Calls)+#13#10+IntToStr(Ord(MsysPrepared))+#13#10+First+#13#10+Outcome+#13#10+IntToStr(Builds),False);
 Abort;
end;
'@
[IO.File]::WriteAllText((Join-Path $root 'diagnostic.iss'),$header+"`n"+($blocks-join "`n")+"`n"+$tail)
$oldError=$ErrorActionPreference
try{$ErrorActionPreference='Continue';$log=& $IsccPath ('--output-dir='+$root) (Join-Path $root 'diagnostic.iss') 2>&1|Out-String;$compileExit=$LASTEXITCODE}finally{$ErrorActionPreference=$oldError}
[IO.File]::WriteAllText((Join-Path $root 'compile.log'),$log)
if($compileExit -ne 0){throw "Compile failed: $log"}
if($CompileOnly){"Compiled only: $root";return}
foreach($case in @('decline','success','reuse','tampered-retry','download-failure','base-failure','package-failure','postcheck-failure','cancel','extra-output','foreign-root','foreign-log','upper-hash')){
 $result=Join-Path $root ($case+'.txt')
 $p=Start-Process -FilePath (Join-Path $root 'msys-decision-diagnostic.exe') -ArgumentList @('/VERYSILENT','/SUPPRESSMSGBOXES','/NORESTART',('/CASE='+$case),('/RESULT='+$result)) -WindowStyle Hidden -PassThru
 if(-not $p.WaitForExit(30000)){throw "Diagnostic timeout: $case PID=$($p.Id)"}
 if(-not (Test-Path -LiteralPath $result)){throw "Diagnostic no result: $case exit=$($p.ExitCode) evidence=$root"}
 $lines=[IO.File]::ReadAllText($result).Split(@("`r`n"),[StringSplitOptions]::None)
 $success=$case -in @('success','reuse')
 if(($lines[4] -eq '') -ne $success -or ($lines[2] -eq '1') -ne $success){throw "Wrong result $case $($lines-join '|')"}
 if($case -eq 'decline' -and ($lines[0] -ne '0' -or $lines[1] -ne '0')){throw 'Acquisition occurred before consent.'}
 if($case -in @('reuse','tampered-retry') -and ($lines[0] -ne '1' -or $lines[1] -ne '2')){throw 'Retry did not recheck or reacquired.'}
 $expectedBuilds=if($case -eq 'reuse'){2}elseif($case -in @('success','tampered-retry')){1}else{0}
 if([int]$lines[5] -ne $expectedBuilds){throw 'Actual PrepareToInstall reached source build after MSYS failure.'}
 $tokens=$null;$errors=$null
 $command=[IO.File]::ReadAllText($result+'.command')
 $ast=[Management.Automation.Language.Parser]::ParseInput($command,[ref]$tokens,[ref]$errors)
 if($errors.Count){throw "Actual generated PowerShell syntax invalid: $errors"}
 if($success){
  $argsText=[IO.File]::ReadAllText($result+'.buildargs')
  foreach($arg in @('-MsysBash','-MsysPackageReceiptPath','-MsysPackageReceiptSha256','-MsysBaseArchivePath')){if($argsText -notmatch [regex]::Escape($arg+' ')){throw "Missing actual bootstrap argument: $arg"}}
 } elseif(Test-Path ($result+'.buildargs')){throw 'Unprepared MSYS produced bootstrap arguments.'}
}
# Invoke only the actual isolated path/hash guards. The full command is never executed.
$safeFunctions=@($ast.FindAll({param($n) $n -is [Management.Automation.Language.FunctionDefinitionAst] -and $n.Name -in @('SafePath','Pin','Protected')},$true))
if($safeFunctions.Count -ne 3){throw 'Isolated guard selection differs; native boundary must remain unexecuted.'}
foreach($fn in $safeFunctions){Invoke-Expression $fn.Extent.Text}
$locks=@()
$guardFile=Join-Path $root 'firstparty.txt';[IO.File]::WriteAllText($guardFile,'first party fixture')
$valid=(Get-FileHash $guardFile).Hash.ToLowerInvariant()
$rejected=$false;try{Pin $guardFile ('b'*64)}catch{$rejected=$true};if(-not $rejected){throw 'Changed pin accepted.'}
foreach($bad in @('relative.txt',($root+'\..\escape.txt'))){$rejected=$false;try{SafePath $bad}catch{$rejected=$true};if(-not $rejected){throw 'Unsafe path accepted.'}}
try{
 Pin $guardFile $valid
 $blocked=$false;try{[IO.File]::WriteAllText($guardFile,'replace locked bytes')}catch{$blocked=$true};if(-not $blocked){throw 'Pinned helper was writable during use.'}
}finally{foreach($f in $locks){$f.Dispose()}}
$sid=[Security.Principal.WindowsIdentity]::GetCurrent().User.Value
$allowed=@($sid,'S-1-5-18','S-1-5-32-544')
$aclDirectory=Join-Path $root 'owned-acl-fixture'
$acl=New-Object Security.AccessControl.DirectorySecurity
$acl.SetAccessRuleProtection($true,$false);$acl.SetOwner([Security.Principal.SecurityIdentifier]::new($sid))
foreach($s in $allowed){$acl.AddAccessRule([Security.AccessControl.FileSystemAccessRule]::new([Security.Principal.SecurityIdentifier]::new($s),'FullControl','ContainerInherit,ObjectInherit','None','Allow'))}
[IO.Directory]::CreateDirectory($aclDirectory,$acl)|Out-Null
Protected $aclDirectory
$foreign=[Security.AccessControl.FileSystemAccessRule]::new([Security.Principal.SecurityIdentifier]::new('S-1-5-32-545'),'Write','ContainerInherit,ObjectInherit','InheritOnly','Allow')
$acl.AddAccessRule($foreign);[IO.Directory]::SetAccessControl($aclDirectory,$acl)
$rejected=$false;try{Protected $aclDirectory}catch{$rejected=$true};if(-not $rejected){throw 'Inheritable-only foreign write ACL accepted.'}
$acl.RemoveAccessRuleSpecific($foreign);[IO.Directory]::SetAccessControl($aclDirectory,$acl)
Protected $aclDirectory
$flags=$ast.FindAll({param($n) $n -is [Management.Automation.Language.ForEachStatementAst] -and $n.Variable.VariablePath.UserPath -eq 'flag'},$true)
if($flags.Count -ne 1){throw 'Actual Boolean receipt guard selection differs.'}
$b=[pscustomobject]@{signature_verified=$true;init_verified=$true;first_login_verified=$true;protected_root_verified=$true}
Invoke-Expression $flags[0].Extent.Text
$b.init_verified='True';$rejected=$false
try{Invoke-Expression $flags[0].Extent.Text}catch{$rejected=$true}
if(-not $rejected){throw 'String Boolean receipt claim accepted.'}
"GREEN: 13 actual Pascal MSYS decisions; native and acquisition boundaries entirely first-party Pascal fixtures. Evidence retained: $root"
