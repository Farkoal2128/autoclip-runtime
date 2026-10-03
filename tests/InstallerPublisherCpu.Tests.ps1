$ErrorActionPreference = 'Stop'
$repo = Split-Path -Parent $PSScriptRoot
$tokens=$null; $errors=$null
$ast=[Management.Automation.Language.Parser]::ParseFile((Join-Path $repo 'install.ps1'),[ref]$tokens,[ref]$errors)
if($errors){throw 'Bootstrap parse failed.'}
foreach($name in @('Assert-AutoClipSecurePath','Read-AutoClipSecureInput','Initialize-AutoClipPublisherCpu','Assert-AutoClipPublisherCpuRelease')) {
    $node=@($ast.FindAll({param($n) $n -is [Management.Automation.Language.FunctionDefinitionAst] -and $n.Name -eq $name},$false))
    if($node.Count -ne 1){throw "Missing publisher CPU behavioral function: $name"}
    Invoke-Expression $node[0].Extent.Text
}
$fixture=Join-Path $env:TEMP ('publisher-cpu-'+[guid]::NewGuid().ToString('N'))
[IO.Directory]::CreateDirectory($fixture)|Out-Null
$manifestPath=Join-Path $fixture 'manifest.json'
$descriptor=[ordered]@{identity='cpu-test-v1';filename='cpu-test-v1.zip';url='https://example.invalid/cpu-test-v1.zip';bytes=12;sha256=('a'*64);profile='cpu';delivery_classification='DIRECT_RECIPIENT_DOWNLOAD';qualification_receipt_path='evidence/cpu-qualified.json';qualification_receipt_sha256=('b'*64)}
function Select-Cpu($Row,$Path='C:\cpu-test-v1.zip',$NativePin=('c'*64),$PythonPin=('d'*64),$Gpu=$false,$Guard=$true) {
    $outer=@{schema_version=1;cpu_native_artifact=$Row}|ConvertTo-Json -Depth 6
    [IO.File]::WriteAllText($manifestPath,$outer)
    $script:SecureAcquisition=[pscustomobject]@{ManifestPath=$manifestPath;ManifestSha256=(Get-FileHash $manifestPath).Hash}
    Initialize-AutoClipPublisherCpu $Path $NativePin $PythonPin $Gpu $Guard
}
if(Select-Cpu $null '' '' ''){throw 'Legacy source route changed.'}
$selected=Select-Cpu $descriptor
if($selected.identity -cne 'cpu-test-v1'){throw 'Qualified exact CPU descriptor was not selected.'}
if(Select-Cpu $descriptor '' '' '' $true){throw 'Optional NVIDIA source route selected CPU binaries.'}
foreach($bad in @(
    @{path='';native=('c'*64);python=('d'*64);gpu=$false;guard=$true},
    @{path='C:\cpu.zip';native='';python=('d'*64);gpu=$false;guard=$true},
    @{path='C:\cpu.zip';native=('c'*64);python='';gpu=$false;guard=$true},
    @{path='C:\cpu.zip';native=('c'*64);python=('d'*64);gpu=$true;guard=$true},
    @{path='C:\cpu.zip';native=('c'*64);python=('d'*64);gpu=$false;guard=$false}
)) {
    $rejected=$false
    try{Select-Cpu $descriptor $bad.path $bad.native $bad.python $bad.gpu $bad.guard|Out-Null}catch{$rejected=$true}
    if(-not $rejected){throw 'Missing pair, GPU or unguarded CPU route accepted.'}
}
foreach($field in @('profile','delivery_classification','qualification_receipt_sha256','filename')) {
    $bad=@{};foreach($key in $descriptor.Keys){$bad[$key]=$descriptor[$key]};$bad[$field]=@{profile='nvidia';delivery_classification='BLOCKED';qualification_receipt_sha256='bad';filename='../cpu.zip'}[$field]
    $rejected=$false;try{Select-Cpu $bad|Out-Null}catch{$rejected=$true}
    if(-not $rejected){throw "Invalid descriptor accepted: $field"}
}
$release=[pscustomobject]@{runtime_id='cpu-test-v1';native_build=[pscustomobject]@{delivery='publisher_cpu_with_source_nvidia';cpu_artifact=[pscustomobject]$descriptor}}
Assert-AutoClipPublisherCpuRelease $selected $release
Assert-AutoClipPublisherCpuRelease $null $release $true
$release.native_build.cpu_artifact.sha256='e'*64
$rejected=$false;try{Assert-AutoClipPublisherCpuRelease $selected $release}catch{$rejected=$true}
if(-not $rejected){throw 'Release CPU identity substitution accepted.'}
'Publisher CPU selection and release binding PASS'
$publisherCpu=$selected
$nativeBlock=@($ast.FindAll({param($n) $n -is [Management.Automation.Language.IfStatementAst] -and $n.Extent.Text -eq 'if (-not $publisherCpu) { . $nativePrerequisiteAction }'},$true))
if($nativeBlock.Count -ne 1){throw 'Native prerequisite boundary is missing or ambiguous.'}
$nativeAction=$ast.FindAll({param($n) $n -is [Management.Automation.Language.AssignmentStatementAst] -and $n.Left.Extent.Text -eq '$nativePrerequisiteAction'},$true)[0]
Invoke-Expression $nativeAction.Extent.Text
function Get-Command {throw 'CPU probed a developer tool.'}
function Test-Path {throw 'CPU probed a developer tool path.'}
function Install-WingetPackage {throw 'CPU acquired a developer tool.'}
function Invoke-AutoClipMsysSource {throw 'CPU entered MSYS2.'}
Invoke-Expression $nativeBlock[0].Extent.Text
Remove-Item Function:Get-Command,Function:Test-Path,Function:Install-WingetPackage,Function:Invoke-AutoClipMsysSource
'Publisher CPU bypasses the complete original MSYS/Git/VS/SDK block PASS'
$workerTokens=$null;$workerErrors=$null
$workerAst=[Management.Automation.Language.Parser]::ParseFile((Join-Path $repo 'installer/run-source-build.ps1'),[ref]$workerTokens,[ref]$workerErrors)
if($workerErrors){throw 'Worker parse failed.'}
foreach($name in @('Assert-BuildPath','Read-BuildArguments')) {
    $node=$workerAst.FindAll({param($n) $n -is [Management.Automation.Language.FunctionDefinitionAst] -and $n.Name -eq $name},$false)[0]
    Invoke-Expression $node.Extent.Text
}
$parameters=@{NonInteractive=$true;NoPrerequisiteAcquisition=$true;SkipDesktopShortcut=$true;InstallRoot='C:\test-install';ArchivePath='C:\test-app.zip';CpuNativeArtifactPath='C:\cpu-test-v1.zip';CpuNativeHelperSha256=('c'*64);PythonPrerequisiteHelperSha256=('d'*64)}
$stream=[IO.MemoryStream]::new([Text.Encoding]::UTF8.GetBytes((@{schema_version=1;parameters=$parameters}|ConvertTo-Json)))
try{$arguments=Read-BuildArguments $stream}finally{$stream.Dispose()}
if($arguments.CpuNativeArtifactPath -ne $parameters.CpuNativeArtifactPath -or $arguments.PythonPrerequisiteHelperSha256 -ne $parameters.PythonPrerequisiteHelperSha256){throw 'Supervised worker lost publisher CPU inputs.'}
'Strict supervised worker publisher CPU arguments PASS'
# Compose the actual bootstrap branch with the helper's authentic ZIP/RECORD
# fixture. The unrelated publisher wheel must survive exact native staging.
foreach($name in @('Assert-AutoClipMsysProtectedPath','Invoke-AutoClipPinnedHelper','Publish-AutoClipCpuWheel')) {
    $node=$ast.FindAll({param($n) $n -is [Management.Automation.Language.FunctionDefinitionAst] -and $n.Name -eq $name},$false)[0]
    Invoke-Expression $node.Extent.Text
}
$acl=[Security.AccessControl.DirectorySecurity]::new();$sid=[Security.Principal.WindowsIdentity]::GetCurrent().User
$acl.SetOwner($sid);$acl.SetAccessRuleProtection($true,$false)
foreach($id in @($sid.Value,'S-1-5-18','S-1-5-32-544')){$acl.AddAccessRule([Security.AccessControl.FileSystemAccessRule]::new([Security.Principal.SecurityIdentifier]::new($id),'FullControl','ContainerInherit,ObjectInherit','None','Allow'))}
Set-Acl -LiteralPath $fixture -AclObject $acl
$generator=Join-Path $fixture 'fixture.py'
[IO.File]::WriteAllText($generator,@'
import importlib.util, json, shutil, sys
from pathlib import Path
spec=importlib.util.spec_from_file_location('fixture',Path(sys.argv[1])/'.github/tests/test_cpu_native_install.py')
module=importlib.util.module_from_spec(spec);spec.loader.exec_module(module)
case=module.CpuInstallTests();case.setUp()
try:
    target=Path(sys.argv[2])/'cpu.zip';shutil.copyfile(case.args.archive,target)
    print(json.dumps({'identity':case.args.runtime_id,'sha256':case.args.archive_sha256,'bytes':case.args.archive_bytes}))
finally:case.doCleanups()
'@)
$python=(Get-Command python.exe).Source
$publisherCpu=(& $python $generator $repo $fixture)|ConvertFrom-Json
if($LASTEXITCODE -ne 0){throw 'Authentic native fixture preparation failed.'}
$CpuNativeArtifactPath=Join-Path $fixture 'cpu.zip'
$externalWheels=Join-Path $fixture 'publisher-wheels/cpu'
[IO.Directory]::CreateDirectory($externalWheels)|Out-Null
$foreign=Join-Path $externalWheels 'existing-publisher.whl'
[IO.File]::WriteAllText($foreign,'retained unrelated publisher fixture')
$foreignPin=(Get-FileHash $foreign).Hash
$helper=Join-Path $fixture 'install-cpu-native-artifact.py'
[IO.File]::Copy((Join-Path $repo 'installer/install-cpu-native-artifact.py'),$helper)
$CpuNativeHelperSha256=(Get-FileHash $helper).Hash
$manifest=[pscustomobject]@{native_build=[pscustomobject]@{wheel_names=@('av-18.1.0-cp311-abi3-win_amd64.whl','ctranslate2-4.8.2-cp311-cp311-win_amd64.whl')}}
$nativeBranch=@($ast.FindAll({param($n) $n -is [Management.Automation.Language.IfStatementAst] -and $n.Clauses[0].Item1.Extent.Text -eq '$publisherCpu' -and $n.Extent.Text.Contains('$nativeHelper =')},$true))
if($nativeBranch.Count -ne 1){throw 'Actual native publisher branch missing.'}
$branch=$nativeBranch[0].Extent.Text.Replace("`$PSScriptRoot 'install-cpu-native-artifact.py'","'$fixture' 'install-cpu-native-artifact.py'")
Invoke-Expression $branch
if((Get-FileHash $foreign).Hash -ne $foreignPin -or @((Get-ChildItem $externalWheels -Filter '*.whl')).Count -ne 3){throw 'Publisher native composition changed unrelated wheels or omitted native wheels.'}
$producer=Join-Path $externalWheels 'native-artifact/build/native-build-receipt.json'
if(-not(Test-Path $producer) -or -not $publisherReceiptBytes){throw 'Original producer receipt or bound installed receipt missing.'}
Invoke-Expression $branch
[IO.File]::WriteAllText((Join-Path $externalWheels $manifest.native_build.wheel_names[0]),'corrupt')
$rejected=$false;try{Invoke-Expression $branch}catch{$rejected=$true}
if(-not $rejected -or (Get-FileHash $foreign).Hash -ne $foreignPin){throw 'Corrupt native cache accepted or unrelated wheel changed.'}
'Actual helper/bootstrap composition with existing publisher wheel, repeat and corruption PASS'
$pythonHelper=Join-Path $fixture 'install-python.ps1'
[IO.File]::WriteAllText($pythonHelper,("param([switch]`$CheckOnly)`r`nif(-not `$CheckOnly){throw 'Unexpected install'}`r`n'"+$python.Replace("'","''")+"'"))
$PythonPrerequisiteHelperSha256=(Get-FileHash $pythonHelper).Hash
function Capture-CpuVenv { $script:venvCall=@($args);$global:LASTEXITCODE=0 }
$uv=[pscustomobject]@{Source='Capture-CpuVenv'};$venvOptions=@();$venv=Join-Path $fixture '.venv'
$pythonBranch=@($ast.FindAll({param($n) $n -is [Management.Automation.Language.IfStatementAst] -and $n.Clauses[0].Item1.Extent.Text -eq '$publisherCpu' -and $n.Extent.Text.Contains('$pythonHelper =')},$true))
if($pythonBranch.Count -ne 1){throw 'Actual registered Python branch missing.'}
$pythonBranchText=$pythonBranch[0].Extent.Text.Replace("`$PSScriptRoot 'install-python.ps1'","'$fixture' 'install-python.ps1'")
Invoke-Expression $pythonBranchText
if(($script:venvCall -join '|') -ne (@('venv','--python',$python,'--no-managed-python','--no-python-downloads',$venv)-join '|')){throw 'CPU environment creation lost the exact verified absolute interpreter or disabled-download flags.'}
[IO.File]::AppendAllText($pythonHelper,'#changed')
$rejected=$false;try{Invoke-Expression $pythonBranchText}catch{$rejected=$true}
if(-not $rejected){throw 'Changed Python prerequisite helper executed.'}
'Actual pinned CheckOnly composition and absolute uv interpreter/download flags PASS'
