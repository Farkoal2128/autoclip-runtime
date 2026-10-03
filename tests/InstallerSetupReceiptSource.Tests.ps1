param([ValidateSet('All','Early','Completion','Fresh','Worker','Import','Composition')][string]$Case='All')
$ErrorActionPreference='Stop'
$repo=Split-Path -Parent $PSScriptRoot
$source=[IO.File]::ReadAllText((Join-Path $repo 'install.ps1'))
$tokens=$null;$errors=$null;$ast=[Management.Automation.Language.Parser]::ParseInput($source,[ref]$tokens,[ref]$errors)
if($errors.Count){throw 'Source parser failed.'}
foreach($node in $ast.FindAll({param($n)$n -is [Management.Automation.Language.FunctionDefinitionAst] -and $n.Name -in @('Assert-AutoClipSecurePath','Assert-AutoClipMsysProtectedPath','Read-AutoClipSecureInput','Install-AutoClipLaunchers','Get-AutoClipLauncherPin','Test-AutoClipOwnedLauncher','Write-AutoClipCompletionFile','Get-AutoClipSetupDirectoryAcl','Initialize-AutoClipFreshSetupProvenance')},$true)){. ([scriptblock]::Create($node.Extent.Text))}
. (Join-Path $repo 'installer/write-setup-receipt.ps1')
function Assert($value,$message){if(-not $value){throw $message}}
function Pin($path){(Get-FileHash -LiteralPath $path).Hash.ToLowerInvariant()}
$fixture=Join-Path $env:TEMP ('autoclip-source-receipt-'+[guid]::NewGuid().ToString('N'))
$acl=[Security.AccessControl.DirectorySecurity]::new();$sid=[Security.Principal.WindowsIdentity]::GetCurrent().User
$acl.SetOwner($sid);$acl.SetAccessRuleProtection($true,$false)
foreach($id in @($sid.Value,'S-1-5-18','S-1-5-32-544')){$acl.AddAccessRule([Security.AccessControl.FileSystemAccessRule]::new([Security.Principal.SecurityIdentifier]::new($id),'FullControl','ContainerInherit,ObjectInherit','None','Allow'))}
[IO.Directory]::CreateDirectory($fixture,$acl)|Out-Null
$payloadPath=Join-Path $fixture 'payload.ps1';[IO.File]::WriteAllText($payloadPath,'# first-party static payload')
$manifestPath=Join-Path $fixture 'manifest.json'
[IO.File]::WriteAllText($manifestPath,(@{schema_version=3;files=@(@{path='Start-AutoClip.ps1';bytes=(Get-Item $payloadPath).Length;sha256=(Pin $payloadPath)})}|ConvertTo-Json -Depth 5))
$expectedManifestSha256=Pin $manifestPath;$expectedArchiveSha256='a'*64;$releaseId='first-party-source-receipt'
$SecureAcquisitionManifestSha256='b'*64;$BootstrapIdentitySha256='c'*64;$AppHealthHelperSha256='d'*64
$SetupReceiptHelperSha256=Pin (Join-Path $repo 'installer/write-setup-receipt.ps1');$SkipDesktopShortcut=$true;$PrerequisitesOnly=$false
function New-Root($name){
    $root=Join-Path $fixture $name;[IO.Directory]::CreateDirectory($root,$acl)|Out-Null
    Copy-Item -LiteralPath $manifestPath -Destination (Join-Path $root 'release-manifest.json')
    Copy-Item -LiteralPath $payloadPath -Destination (Join-Path $root 'Start-AutoClip.ps1')
    return $root
}
function Set-Context($root){$script:setupReceiptContext=@{install_root=$root;release_id=$releaseId;profile='cpu';archive_sha256=$expectedArchiveSha256;release_manifest_sha256=$expectedManifestSha256;dependency_manifest_sha256=$SecureAcquisitionManifestSha256;bootstrap_sha256=$BootstrapIdentitySha256;source_helper_sha256=$SetupReceiptHelperSha256;health_helper_sha256=$AppHealthHelperSha256}}
$earlyStart=$source.IndexOf('$resumeIncomplete = $false');$earlyEnd=$source.IndexOf('$ffmpegContext = $null',$earlyStart)
Assert ($earlyStart -gt 0 -and $earlyEnd -gt $earlyStart) 'Actual early source guard selection failed.'
$early=[scriptblock]::Create($source.Substring($earlyStart,$earlyEnd-$earlyStart))
if($Case -in @('All','Early')){
    foreach($relative in @('.venv/foreign.txt','publisher-wheels/foreign.txt')){
        $InstallRoot=New-Root ('foreign-'+[guid]::NewGuid().ToString('N'));Set-Context $InstallRoot
        $foreign=Join-Path $InstallRoot $relative;[IO.Directory]::CreateDirectory((Split-Path -Parent $foreign))|Out-Null;[IO.File]::WriteAllText($foreign,'preserve unrelated bytes')
        $script:nativeSideEffects=0;$failed=$false
        try{. $early;$script:nativeSideEffects++}catch{$failed=$true}
        Assert ($failed -and $script:nativeSideEffects -eq 0) 'RED: actual early source guard accepts unproven dynamic partial before next native side effect.'
        Assert ([IO.File]::ReadAllText($foreign) -ceq 'preserve unrelated bytes') 'Rejected partial was modified.'
    }
    $InstallRoot=New-Root 'static';Set-Context $InstallRoot;. $early
    Assert ($resumeIncomplete -and $setupReceiptStartingProof) 'Matching static-only source retry did not obtain actual proof.'
    $InstallRoot=Join-Path $fixture 'empty-protected';[IO.Directory]::CreateDirectory($InstallRoot,$acl)|Out-Null;Set-Context $InstallRoot
    $failed=$false;try{. $early}catch{$failed=$true}
    Assert (-not $failed -and -not $resumeIncomplete) 'RED: actual managed source guard refuses an empty protected release root.'
    $setupReceiptContext=$null;$InstallRoot=New-Root 'legacy';$foreign=Join-Path $InstallRoot '.venv/legacy.txt';[IO.Directory]::CreateDirectory((Split-Path -Parent $foreign))|Out-Null;[IO.File]::WriteAllText($foreign,'legacy retained workflow');. $early
    Assert $resumeIncomplete 'No-pin legacy retry behavior changed.'
    'PASS actual early guard refuses unproven dynamic bytes before native boundary, accepts static proof and preserves no-pin workflow'
}
if($Case -in @('All','Completion')){
    $InstallRoot=New-Root 'completion';Set-Context $InstallRoot
    $setupReceiptStartingProof=Assert-SetupStartingProvenance -Context $setupReceiptContext -ManifestPath (Join-Path $InstallRoot 'release-manifest.json')
    [IO.Directory]::CreateDirectory((Join-Path $InstallRoot '.venv/Scripts'))|Out-Null
    [IO.File]::WriteAllText((Join-Path $InstallRoot '.venv/Scripts/pythonw.exe'),'inert first-party interpreter; never execute')
    $healthPath=Join-Path $fixture 'health.json'
    [IO.File]::WriteAllText($healthPath,(@{schema_version=1;status='VERIFIED_HEALTH_HOME';install_root=$InstallRoot;manifest_sha256=$expectedManifestSha256;isolated_health_only=$true;desktop_tested=$false;media_tested=$false;model_inference_tested=$false;child=@{exit_code=0;receipt=@{health_status=200;home_status=200}}}|ConvertTo-Json -Depth 6))
    $healthPin=@{result_path=$healthPath;bytes=(Get-Item $healthPath).Length;sha256=(Pin $healthPath);install_root=$InstallRoot;manifest_sha256=$expectedManifestSha256;status='VERIFIED_HEALTH_HOME'}
    [IO.File]::WriteAllText((Join-Path $InstallRoot 'native-build-receipt.json'),(@{profile='cpu';setup_app_health=$healthPin}|ConvertTo-Json -Depth 6))
    $assignment=$ast.FindAll({param($n)$n -is [Management.Automation.Language.AssignmentStatementAst] -and $n.Left.Extent.Text -eq '$completionAction'},$true)
    Assert ($assignment.Count -eq 1) 'Actual completion action differs.'
    . ([scriptblock]::Create($assignment[0].Extent.Text))
    $realWriter=(Get-Item Function:Write-AutoClipCompletionFile).ScriptBlock
    & {
        function Write-AutoClipCompletionFile($Path,[byte[]]$Bytes,[switch]$ReplaceExisting){
            if([IO.Path]::GetFileName($Path) -eq '.install-complete'){
                Assert ([IO.File]::Exists((Join-Path $InstallRoot '.setup-source-ownership.json'))) 'RED: actual source completion reaches marker before producing ownership handoff.'
                $record=Get-Content (Join-Path $InstallRoot '.setup-source-ownership.json') -Raw|ConvertFrom-Json
                Assert ($record.status -eq 'VERIFIED_SOURCE_OUTPUTS' -and $record.files.Count -eq 5) 'Actual source handoff inventory differs.'
                throw 'First-party denied marker fixture'
            }
            & $realWriter $Path $Bytes -ReplaceExisting:$ReplaceExisting
        }
        $failed=$false;$message='';try{& $completionAction}catch{$failed=$true;$message=$_.Exception.Message}
        Assert ($failed -and $message -ceq 'First-party denied marker fixture') ('Actual completion handoff missing/invalid: '+$message)
    }
    Assert (-not [IO.File]::Exists((Join-Path $InstallRoot '.install-complete'))) 'Denied marker left completion.'
    . $early
    Assert ($resumeIncomplete -and $setupReceiptStartingProof) 'Actual receipt-backed source retry rejects retained handoff.'
    $scanStart=$source.IndexOf('    if ($resumeIncomplete) {');$scanEnd=$source.IndexOf("    . (Join-Path `$InstallRoot 'upstream-assets.ps1')",$scanStart)
    $rootFull=[IO.Path]::GetFullPath($InstallRoot).TrimEnd('\')+'\';$expectedFiles=[Collections.Generic.HashSet[string]]::new([StringComparer]::OrdinalIgnoreCase)
    foreach($path in @('release-manifest.json','Start-AutoClip.ps1')){$null=$expectedFiles.Add($path)};$ffmpegContext=$null
    . ([scriptblock]::Create($source.Substring($scanStart,$scanEnd-$scanStart)))
    & $completionAction
    Assert ([IO.File]::ReadAllText((Join-Path $InstallRoot '.install-complete')) -ceq $expectedArchiveSha256) 'Actual retry did not publish handoff then marker.'
    'PASS actual completion produces verified handoff before marker; denied marker remains proven retryable through actual scan/action'
}
if($Case -in @('All','Fresh')){
    $zipRoot=Join-Path $fixture 'zip-input';[IO.Directory]::CreateDirectory($zipRoot,$acl)|Out-Null
    Copy-Item -LiteralPath $manifestPath -Destination (Join-Path $zipRoot 'release-manifest.json')
    Copy-Item -LiteralPath $payloadPath -Destination (Join-Path $zipRoot 'Start-AutoClip.ps1')
    Add-Type -AssemblyName System.IO.Compression.FileSystem
    $ArchivePath=Join-Path $fixture 'first-party-source.zip';[IO.Compression.ZipFile]::CreateFromDirectory($zipRoot,$ArchivePath)
    $expectedArchiveSha256=Pin $ArchivePath;$InstallRoot=Join-Path $fixture 'fresh-extraction';Set-Context $InstallRoot;$setupReceiptStartingProof=$null;$CancelPath=$null
    $start=$source.IndexOf('    $actualArchiveSha256 =');$end=$source.IndexOf("    `$manifestPath = Join-Path `$InstallRoot 'release-manifest.json'",$start)
    Assert ($start -gt 0 -and $end -gt $start) 'Actual fresh source extraction boundary differs.'
    . ([scriptblock]::Create($source.Substring($start,$end-$start)))
    Assert ($setupReceiptStartingProof -and (Get-Acl -LiteralPath $InstallRoot).AreAccessRulesProtected) 'RED: actual fresh extraction occurs without registered provenance/protected recipient root.'
    Assert ((Pin (Join-Path $InstallRoot 'release-manifest.json')) -ceq $expectedManifestSha256) 'Fresh manifest bytes changed.'
    Assert ($setupReceiptStartingProof.manifest_path -ine (Join-Path $InstallRoot 'release-manifest.json')) 'Fresh proof used already-overwritten release manifest.'
    'PASS actual fresh source verifies archive and separate manifest, obtains proof before protected root extraction'
}
if($Case -in @('All','Worker')){
    $workerHelper=Join-Path $fixture 'run-source-build.ps1';Copy-Item -LiteralPath (Join-Path $repo 'installer/run-source-build.ps1') -Destination $workerHelper
    $bootstrap=Join-Path $fixture 'fake-install.ps1'
    [IO.File]::WriteAllText($bootstrap,@'
param($InstallRoot,$ArchivePath,[switch]$NonInteractive,[switch]$NoPrerequisiteAcquisition,[switch]$SkipDesktopShortcut,$CancelPath,$SecureAcquisitionManifestPath,$SecureAcquisitionManifestSha256,$SecureDownloaderSha256,$SetupReceiptHelperSha256,$BootstrapIdentitySha256)
[IO.File]::WriteAllText($InstallRoot+'.identity.json',(@{bootstrap=$BootstrapIdentitySha256;receipt_helper=$SetupReceiptHelperSha256}|ConvertTo-Json))
exit 7
'@)
    $workerManifest=Join-Path $fixture 'worker-manifest.json';[IO.File]::WriteAllText($workerManifest,(@{target_release=@{sha256=('a'*64);manifest_sha256=('b'*64)}}|ConvertTo-Json -Depth 4))
    $downloader=Join-Path $fixture 'download-artifact.ps1';[IO.File]::WriteAllText($downloader,'# inert first-party downloader')
    $workerRoot=Join-Path $fixture 'worker-root';$argumentFile=Join-Path $fixture 'worker-arguments.json'
    $parameters=@{InstallRoot=$workerRoot;ArchivePath=(Join-Path $fixture 'archive.zip');NonInteractive=$true;NoPrerequisiteAcquisition=$true;SkipDesktopShortcut=$true;SetupReceiptHelperSha256=$SetupReceiptHelperSha256}
    [IO.File]::WriteAllText($argumentFile,(@{schema_version=1;parameters=$parameters}|ConvertTo-Json -Depth 5))
    $invoke=@{BootstrapPath=$bootstrap;BootstrapSha256=(Pin $bootstrap);ManifestPath=$workerManifest;ManifestSha256=(Pin $workerManifest);DownloaderPath=$downloader;DownloaderSha256=(Pin $downloader);ArgumentsPath=$argumentFile;ArgumentsSha256=(Pin $argumentFile);HelperSha256=(Pin $workerHelper);AttemptDirectory=(Join-Path $fixture 'worker-attempt')}
    & $workerHelper @invoke
    $identity=Get-Content ($workerRoot+'.identity.json') -Raw|ConvertFrom-Json
    $status=Get-Content (Join-Path $invoke.AttemptDirectory 'status.json') -Raw|ConvertFrom-Json
    Assert ($status.exit_code -eq 7 -and $identity.bootstrap -ceq (Pin $bootstrap) -and $identity.receipt_helper -ceq $SetupReceiptHelperSha256) 'Actual worker did not inject held bootstrap identity.'
    $parameters.BootstrapIdentitySha256='0'*64
    [IO.File]::WriteAllText($argumentFile,(@{schema_version=1;parameters=$parameters}|ConvertTo-Json -Depth 5));$invoke.ArgumentsSha256=Pin $argumentFile;$invoke.AttemptDirectory=Join-Path $fixture 'bad-worker-attempt'
    $failed=$false;try{& $workerHelper @invoke}catch{$failed=$true}
    Assert ($failed -and -not [IO.Directory]::Exists($invoke.AttemptDirectory)) 'Remote JSON supplied bootstrap identity bypass was accepted.'
    'PASS actual worker injects held bootstrap identity and rejects JSON-supplied identity before worker launch'
}
if($Case -in @('All','Composition')){
    $local=Join-Path $fixture 'localappdata';[IO.Directory]::CreateDirectory($local,$acl)|Out-Null
    $pythonAst=[Management.Automation.Language.Parser]::ParseFile((Join-Path $repo 'installer/install-python.ps1'),[ref]$tokens,[ref]$errors)
    foreach($node in $pythonAst.FindAll({param($n)$n -is [Management.Automation.Language.FunctionDefinitionAst] -and $n.Name -in @('Assert-AutoClipPythonPath','Install-AutoClipPython')},$true)){. ([scriptblock]::Create($node.Extent.Text))}
    $inno=[IO.File]::ReadAllText((Join-Path $repo 'installer/AutoClip.iss'))
    $prepare=[regex]::Match($inno,'(?s)function PreparePython\b.*?(?=\r?\nfunction|\z)').Value
    Assert ([regex]::IsMatch($prepare,"' -LogDirectory '\s*\+\s*AddQuotes\(PythonLogDirectory\)")) 'Actual Python preparation must use its shared log-directory function.'
    $logFunction=[regex]::Match($inno,'(?s)function PythonLogDirectory\b.*?(?=\r?\nfunction|\z)').Value
    $match=[regex]::Match($logFunction,"Result\s*:=\s*ExpandConstant\('(?<path>[^']+)'\)")
    Assert $match.Success 'Actual Python log directory could not be resolved.'
    Assert ($match.Groups['path'].Value -ceq '{localappdata}\AutoClip\PythonSetupLogs') 'Actual Python logs must remain outside protected source supervisor storage.'
    $pythonLogs=Join-Path $local $match.Groups['path'].Value.Substring('{localappdata}\'.Length)
    $declined=Install-AutoClipPython -InstallerPath (Join-Path $local 'never-execute.exe') -ManifestPath (Join-Path $local 'absent-manifest.json') -LogDirectory $pythonLogs
    Assert ($declined.ExitCode -eq 20) 'Python fixture did not decline before vendor execution.'
    $receiptPin=Pin $declined.ReceiptPath;$autoClipParent=Join-Path $local 'AutoClip';$before=Get-Acl -LiteralPath $autoClipParent
    Assert (-not $before.AreAccessRulesProtected) 'Actual inherited Python parent fixture did not reproduce the composition.'
    $parentDacl=$before.GetSecurityDescriptorSddlForm([Security.AccessControl.AccessControlSections]::Access)
    $zipInput=Join-Path $fixture 'composition-zip';[IO.Directory]::CreateDirectory($zipInput,$acl)|Out-Null
    Copy-Item -LiteralPath $manifestPath -Destination (Join-Path $zipInput 'release-manifest.json');Copy-Item -LiteralPath $payloadPath -Destination (Join-Path $zipInput 'Start-AutoClip.ps1')
    Add-Type -AssemblyName System.IO.Compression.FileSystem
    $ArchivePath=Join-Path $fixture 'composition.zip';[IO.Compression.ZipFile]::CreateFromDirectory($zipInput,$ArchivePath)
    $expectedArchiveSha256=Pin $ArchivePath;$InstallRoot=Join-Path $autoClipParent 'fresh-release';Set-Context $InstallRoot;$setupReceiptStartingProof=$null;$CancelPath=$null
    $start=$source.IndexOf('    $actualArchiveSha256 =');$end=$source.IndexOf("    `$manifestPath = Join-Path `$InstallRoot 'release-manifest.json'",$start)
    . ([scriptblock]::Create($source.Substring($start,$end-$start)))
    Assert ($setupReceiptStartingProof -and (Get-Acl -LiteralPath $InstallRoot).AreAccessRulesProtected) 'Actual source did not create protected child after absent-root proof.'
    Assert ((Get-Acl -LiteralPath $autoClipParent).GetSecurityDescriptorSddlForm([Security.AccessControl.AccessControlSections]::Access) -ceq $parentDacl -and (Pin $declined.ReceiptPath) -ceq $receiptPin) 'Producer parent ACL or receipt was changed.'
    'PASS actual declined Python producer inherited parent -> absent-root source proof -> new protected release, parent/receipt unchanged'
}
if($Case -in @('All','Import')){
    $start=$source.IndexOf('$setupReceiptContext = $null');$end=$source.IndexOf('$resumeIncomplete = $false',$start)
    Assert ($start -gt 0 -and $end -gt $start) 'Actual verified helper import boundary missing.'
    $import=Join-Path $fixture 'actual-import-fixture.ps1';[IO.File]::WriteAllText($import,$source.Substring($start,$end-$start))
    Copy-Item -LiteralPath (Join-Path $repo 'installer/write-setup-receipt.ps1') -Destination (Join-Path $fixture 'write-setup-receipt.ps1')
    $InstallRoot=Join-Path $fixture 'import-root';$InstallNvidiaGpu=$false
    $BootstrapIdentitySha256='c'*64;$AppHealthHelperSha256='d'*64;$SecureAcquisitionManifestSha256='b'*64
    & {
        $SetupReceiptHelperSha256=$null;$failed=$false;try{. $import}catch{$failed=$true};Assert $failed 'Missing helper/bootstrap pair accepted.'
        $SetupReceiptHelperSha256='0'*64;$failed=$false;try{. $import}catch{$failed=$true};Assert $failed 'Changed helper pin accepted.'
        $SetupReceiptHelperSha256=Pin (Join-Path $repo 'installer/write-setup-receipt.ps1');. $import
        Assert ($setupReceiptContext.source_helper_sha256 -ceq $SetupReceiptHelperSha256 -and $setupReceiptContext.bootstrap_sha256 -ceq $BootstrapIdentitySha256) 'Verified actual import did not bind context.'
        $SetupReceiptHelperSha256=$null;$BootstrapIdentitySha256=$null;. $import;Assert ($null -eq $setupReceiptContext) 'No-pin standalone import behavior changed.'
    }
    'PASS actual fixed helper verified import requires paired pins and retains no-pin standalone route'
}
'PRESERVED '+$fixture
