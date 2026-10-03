$ErrorActionPreference='Stop'
function Assert($ok,$message){if(!$ok){throw $message}}
$helper=Join-Path $PSScriptRoot '../installer/initialize-selection.ps1'
if(![IO.File]::Exists($helper)){throw 'RED: initial runtime selection helper is missing.'}
. $helper
. (Join-Path $PSScriptRoot '../installer/write-setup-receipt.ps1')
$tokens=$null;$errors=$null;$ast=[Management.Automation.Language.Parser]::ParseFile((Join-Path $PSScriptRoot '../update-app.ps1'),[ref]$tokens,[ref]$errors)
foreach($node in $ast.FindAll({param($n)$n -is [Management.Automation.Language.FunctionDefinitionAst]},$false)){. ([scriptblock]::Create($node.Extent.Text))}
$fixture=Join-Path $env:TEMP ('autoclip-initial-selection-'+[guid]::NewGuid().ToString('N'))
$sid=[Security.Principal.WindowsIdentity]::GetCurrent().User
$acl=[Security.AccessControl.DirectorySecurity]::new();$acl.SetOwner($sid);$acl.SetAccessRuleProtection($true,$false)
foreach($id in @($sid.Value,'S-1-5-18','S-1-5-32-544')){$acl.AddAccessRule([Security.AccessControl.FileSystemAccessRule]::new([Security.Principal.SecurityIdentifier]::new($id),'FullControl','ContainerInherit,ObjectInherit','None','Allow'))}
[IO.Directory]::CreateDirectory($fixture,$acl)|Out-Null
$baseFull=$fixture;$runtimeStatePath=Join-Path $fixture 'active.json';$appStatePath=Join-Path $fixture 'app-active.json'
$identity=[pscustomobject]@{release_id='fixture-cpu';archive_sha256=('a'*64);release_manifest_sha256=('b'*64)}
Commit-InitialSelection $identity
$first=[IO.File]::ReadAllText($runtimeStatePath);$state=$first|ConvertFrom-Json
Assert ($state.schema_version -eq 1 -and $state.current.release_id -ceq 'fixture-cpu' -and !$state.previous) 'Fresh installation was not selected.'
Commit-InitialSelection $identity
Assert ([IO.File]::ReadAllText($runtimeStatePath) -ceq $first) 'Repeat initialization changed selection bytes.'
$conflict=[pscustomobject]@{release_id='other';archive_sha256=('c'*64);release_manifest_sha256=('d'*64)}
$failed=$false;try{Commit-InitialSelection $conflict}catch{$failed=$true}
Assert ($failed -and [IO.File]::ReadAllText($runtimeStatePath) -ceq $first) 'Conflicting runtime replaced the active selection.'
$prior=$first|ConvertFrom-Json;$prior.previous=@{release_id='old';archive_sha256=('c'*64);manifest_sha256=('d'*64)}
[IO.File]::WriteAllText($runtimeStatePath,($prior|ConvertTo-Json -Depth 5));$rollbackBefore=[IO.File]::ReadAllText($runtimeStatePath)
$failed=$false;try{Commit-InitialSelection $identity}catch{$failed=$true}
Assert ($failed -and [IO.File]::ReadAllText($runtimeStatePath) -ceq $rollbackBefore) 'Prior rollback reference was replaced by bootstrap activation.'
[IO.File]::WriteAllText($runtimeStatePath,$first)
[IO.File]::WriteAllText($appStatePath,'{"schema_version":1,"current":{"required_runtime":"fixture-cpu"}}')
$failed=$false;try{Commit-InitialSelection $identity}catch{$failed=$true}
Assert ($failed -and [IO.File]::ReadAllText($runtimeStatePath) -ceq $first) 'App selection was ignored during bootstrap initialization.'
[IO.File]::Delete($appStatePath)
$launcherPath=Join-Path $fixture 'Start-AutoClip.ps1';$desktopLauncherPath=Join-Path $fixture 'Start-AutoClip-Desktop.ps1'
Prepare-InitialLaunchers
$launcher=[IO.File]::ReadAllText($desktopLauncherPath)
Assert ($launcher.Contains("app-active.json") -and $launcher.Contains('-m autoclip.desktop')) 'Normal desktop launch does not resolve selected app/runtime.'
Prepare-InitialLaunchers
[IO.File]::WriteAllText($desktopLauncherPath,'personal modified launcher')
$failed=$false;try{Prepare-InitialLaunchers}catch{$failed=$true}
Assert ($failed -and [IO.File]::ReadAllText($desktopLauncherPath) -ceq 'personal modified launcher') 'Modified stable launcher overwritten.'
Write-Output ('PASS initial state conflicts and stable launcher preservation '+$fixture)
# Actual helper entry checks use copied pinned first-party bytes, not mocked parsers.
$setup=Join-Path $fixture 'Setup';[IO.Directory]::CreateDirectory($setup,$acl)|Out-Null
foreach($name in @('initialize-selection.ps1','write-setup-receipt.ps1')){Copy-Item (Join-Path $PSScriptRoot ('../installer/'+$name)) (Join-Path $setup $name)}
Copy-Item (Join-Path $PSScriptRoot '../update-app.ps1') (Join-Path $setup 'update-app.ps1')
$receiptDir=Join-Path $setup 'installation-receipts';[IO.Directory]::CreateDirectory($receiptDir,$acl)|Out-Null
$receiptPath=Join-Path $receiptDir 'fixture-cpu.json';$anchorPath=Join-Path $receiptDir 'fixture-cpu.sha256'
[IO.File]::WriteAllText($receiptPath,'{"schema_version":1,"status":"COMPLETE"}')
$receiptPin=(Get-FileHash $receiptPath).Hash.ToLowerInvariant()
[IO.File]::WriteAllText($anchorPath,$receiptPin)
$args=@{Activate=$true;BaseRoot=$fixture;ReleaseId='fixture-cpu';ReceiptPath=$receiptPath;ReceiptSha256=$receiptPin;ReceiptHelperSha256=(Get-FileHash (Join-Path $setup 'write-setup-receipt.ps1')).Hash.ToLowerInvariant();UpdaterSha256=(Get-FileHash (Join-Path $setup 'update-app.ps1')).Hash.ToLowerInvariant()}
$failed=$false;try{& (Join-Path $setup 'initialize-selection.ps1') @args}catch{$failed=$_.Exception.Message -like '*Anchored COMPLETE ownership receipt required*'}
Assert ($failed -and [IO.File]::ReadAllText($runtimeStatePath) -ceq $first) 'Unsupported COMPLETE receipt was accepted or prior selection changed.'
[IO.File]::WriteAllText($anchorPath,('f'*64))
$failed=$false;try{& (Join-Path $setup 'initialize-selection.ps1') @args}catch{$failed=$_.Exception.Message -like '*Receipt anchor differs*'}
Assert ($failed -and [IO.File]::ReadAllText($runtimeStatePath) -ceq $first) 'Receipt anchor mismatch was accepted or prior selection changed.'
Write-Output 'PASS actual initializer rejects unsupported COMPLETE receipt and anchor mismatch before activation'
# A retained health receipt is insufficient: the actual installed child must pass again.
$root=Join-Path $fixture 'health-fails';$releaseId='health-fails'
$manifest=Join-Path $fixture 'source-manifest.json'
[IO.File]::WriteAllText($manifest,'{"schema_version":3,"files":[]}')
$context=@{install_root=$root;release_id=$releaseId;profile='cpu';archive_sha256=('a'*64);release_manifest_sha256=(Get-FileHash $manifest).Hash.ToLowerInvariant();dependency_manifest_sha256=('b'*64);bootstrap_sha256=('c'*64);source_helper_sha256=$args.ReceiptHelperSha256;health_helper_sha256=('e'*64)}
$proof=Assert-SetupStartingProvenance -Context $context -ManifestPath $manifest
[IO.Directory]::CreateDirectory($root,$acl)|Out-Null
Copy-Item $manifest (Join-Path $root 'release-manifest.json')
[IO.Directory]::CreateDirectory((Join-Path $root '.venv/Scripts'))|Out-Null
[IO.Directory]::CreateDirectory((Join-Path $root '.venv/Lib/site-packages'))|Out-Null
$python=Join-Path $root '.venv/Scripts/python.exe'
Add-Type -TypeDefinition 'public class InitialSelectionFailedPython { public static void Main(string[] args) { System.Environment.ExitCode=1; } }' -OutputAssembly $python -OutputType ConsoleApplication
[IO.File]::WriteAllText((Join-Path $root '.venv/Scripts/pythonw.exe'),'inert launcher target, not executed')
$healthPath=Join-Path $fixture 'prior-health.json'
$health=@{schema_version=1;status='VERIFIED_HEALTH_HOME';install_root=$root;manifest_sha256=$context.release_manifest_sha256;isolated_health_only=$true;desktop_tested=$false;media_tested=$false;model_inference_tested=$false;child=@{exit_code=0;receipt=@{health_status=200;home_status=200}}}
[IO.File]::WriteAllText($healthPath,($health|ConvertTo-Json -Depth 6))
$healthPin=@{result_path=$healthPath;bytes=(Get-Item $healthPath).Length;sha256=(Get-FileHash $healthPath).Hash.ToLowerInvariant();install_root=$root;manifest_sha256=$context.release_manifest_sha256;status='VERIFIED_HEALTH_HOME'}
$shell=New-Object -ComObject WScript.Shell;$link=$shell.CreateShortcut((Join-Path $root 'AutoClip.lnk'))
$link.TargetPath=Join-Path $root '.venv/Scripts/pythonw.exe';$link.Arguments='-m autoclip.desktop';$link.WorkingDirectory=$root;$link.Description='Start AutoClip';$link.Save()
$linkPath=Join-Path $root 'AutoClip.lnk'
$launcher=@{path='AutoClip.lnk';bytes=(Get-Item $linkPath).Length;sha256=(Get-FileHash $linkPath).Hash.ToLowerInvariant();archive_sha256=$context.archive_sha256;release_manifest_sha256=$context.release_manifest_sha256}
[IO.File]::WriteAllText((Join-Path $root 'native-build-receipt.json'),(@{profile='cpu';setup_app_health=$healthPin;setup_owned_launcher=$launcher}|ConvertTo-Json -Depth 8))
$handoff=Write-SetupSourceReceipt -Context $context -StartingProof $proof
[IO.File]::WriteAllText((Join-Path $root '.install-complete'),$context.archive_sha256)
$logs=Join-Path $setup 'logs';[IO.Directory]::CreateDirectory($logs,$acl)|Out-Null
$requestPath=Join-Path $logs 'final-request.json'
[IO.File]::WriteAllText($requestPath,(@{schema_version=1;context=$context;handoff_sha256=$handoff.sha256}|ConvertTo-Json -Depth 8))
$prepare=@{PrepareLaunchers=$true;BaseRoot=$fixture;ReleaseId=$releaseId;RequestPath=$requestPath;RequestSha256=(Get-FileHash $requestPath).Hash.ToLowerInvariant();ReceiptHelperSha256=$args.ReceiptHelperSha256;UpdaterSha256=$args.UpdaterSha256}
$failed=$false;try{& (Join-Path $setup 'initialize-selection.ps1') @prepare}catch{$failed=$_.Exception.Message -like '*staged app has a missing runtime dependency*';if(!$failed){throw}}
Assert ($failed -and [IO.File]::ReadAllText($runtimeStatePath) -ceq $first -and [IO.File]::ReadAllText($desktopLauncherPath) -ceq 'personal modified launcher') 'Live child failure changed selection or stable launcher.'
Write-Output 'PASS actual source handoff and retained health receipt cannot bypass failing installed health child'
