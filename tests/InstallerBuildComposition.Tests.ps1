param([switch]$AliasOnly,[switch]$ProducerOnly)
$ErrorActionPreference='Stop'
$repo=Split-Path -Parent $PSScriptRoot
function Assert($value,$message){if(!$value){throw $message}}
function New-FixtureAcl {
    $acl=[Security.AccessControl.DirectorySecurity]::new();$sid=[Security.Principal.WindowsIdentity]::GetCurrent().User
    $acl.SetOwner($sid);$acl.SetAccessRuleProtection($true,$false)
    foreach($id in @($sid.Value,'S-1-5-18','S-1-5-32-544')){$acl.AddAccessRule([Security.AccessControl.FileSystemAccessRule]::new([Security.Principal.SecurityIdentifier]::new($id),'FullControl','ContainerInherit,ObjectInherit','None','Allow'))}
    return $acl
}
$acl=New-FixtureAcl
$tokens=$null;$errors=$null
if(!$AliasOnly){
    $fixtureLocalAppData=Join-Path $env:TEMP ('autoclip-localappdata-composition-'+[guid]::NewGuid().ToString('N'))
    [IO.Directory]::CreateDirectory($fixtureLocalAppData,$acl)|Out-Null
    $pythonAst=[Management.Automation.Language.Parser]::ParseFile((Join-Path $repo 'installer/install-python.ps1'),[ref]$tokens,[ref]$errors)
    foreach($node in $pythonAst.FindAll({param($n)$n -is [Management.Automation.Language.FunctionDefinitionAst] -and $n.Name -in @('Assert-AutoClipPythonPath','Install-AutoClipPython')},$true)){. ([scriptblock]::Create($node.Extent.Text))}
    $sourceAst=[Management.Automation.Language.Parser]::ParseFile((Join-Path $repo 'installer/run-source-build.ps1'),[ref]$tokens,[ref]$errors)
    # Substitute only the environment-owned LocalAppData location; execute all
    # producer directory/receipt and source storage security operations unchanged.
    foreach($node in $sourceAst.FindAll({param($n)$n -is [Management.Automation.Language.FunctionDefinitionAst] -and $n.Name -in @('Assert-BuildPath','New-BuildDirectoryAcl','Initialize-BuildStorage')},$true)){
        $text=$node.Extent.Text.Replace('([Environment]::GetFolderPath([Environment+SpecialFolder]::LocalApplicationData))','($fixtureLocalAppData)')
        . ([scriptblock]::Create($text))
    }
    $inno=[IO.File]::ReadAllText((Join-Path $repo 'installer/AutoClip.iss'))
    $prepare=[regex]::Match($inno,'(?s)function PreparePython\b.*?(?=\r?\nfunction|\z)').Value
    Assert ($prepare -match "' -LogDirectory '\s*\+\s*AddQuotes\(PythonLogDirectory\)") 'Actual PreparePython no longer selects PythonLogDirectory.'
    $logFunction=[regex]::Match($inno,'(?s)function PythonLogDirectory\b.*?(?=\r?\nfunction|\z)').Value
    $match=[regex]::Match($logFunction,"Result\s*:=\s*ExpandConstant\('(?<path>[^']+)'\)")
    Assert $match.Success 'Actual PreparePython LogDirectory argument could not be resolved.'
    $literal=$match.Groups['path'].Value
    Assert ($literal.StartsWith('{localappdata}\')) 'Python logs no longer use the expected native LocalAppData constant.'
    $pythonLogs=Join-Path $fixtureLocalAppData $literal.Substring('{localappdata}\'.Length)
    $result=Install-AutoClipPython -InstallerPath (Join-Path $fixtureLocalAppData 'never-execute.exe') -ManifestPath (Join-Path $fixtureLocalAppData 'absent-manifest.json') -LogDirectory $pythonLogs
    $receipt=Get-Content -LiteralPath $result.ReceiptPath -Raw|ConvertFrom-Json
    Assert ($result.ExitCode -eq 20 -and $receipt.status -eq 'declined' -and $null -eq $receipt.vendor_exit_code) 'Actual Python producer did not stop before vendor execution.'
    $receiptPin=(Get-FileHash -LiteralPath $result.ReceiptPath).Hash
    $storage=Initialize-BuildStorage 'logs'
    Assert ((Get-Acl -LiteralPath $storage).AreAccessRulesProtected) 'Source logs did not obtain protected storage after Python producer.'
    Assert ((Get-FileHash -LiteralPath $result.ReceiptPath).Hash -eq $receiptPin) 'Python producer receipt was changed.'
    "PASS actual Inno Python LogDirectory -> actual declined Python producer -> protected source storage: $literal"
}
if($ProducerOnly){exit 0}
Add-Type -TypeDefinition @'
using System; using System.Text; using System.Runtime.InteropServices;
public static class WIZ19Alias {
 [DllImport("kernel32.dll",CharSet=CharSet.Unicode,SetLastError=true)] public static extern uint GetShortPathName(string p,StringBuilder b,uint n);
}
'@
function Short-Path($path){$b=[Text.StringBuilder]::new(32768);$n=[WIZ19Alias]::GetShortPathName($path,$b,32768);if(!$n -or $n -ge 32768){return $null};return $b.ToString()}
$fixture=$null
foreach($parent in @($env:TEMP,(Split-Path -Parent $repo))|Select-Object -Unique){
    $candidate=Join-Path $parent ('autoclip-alias-lock-fixture-'+[guid]::NewGuid().ToString('N'))
    [IO.Directory]::CreateDirectory($candidate,$acl)|Out-Null
    $short=Short-Path $candidate
    if($short -and $short -ine $candidate){$fixture=$candidate;break}
}
if(!$fixture){Write-Warning 'UNSUPPORTED: no temporary eligible directory exposes a real 8.3 alias; alias workers unexecuted. No volume policy changed.';exit 3}
$helper=Join-Path $fixture 'run-source-build.ps1';[IO.File]::Copy((Join-Path $repo 'installer/run-source-build.ps1'),$helper)
$bootstrap=Join-Path $fixture 'bootstrap.ps1'
[IO.File]::WriteAllText($bootstrap,@'
param($InstallRoot,$ArchivePath,[switch]$NonInteractive,[switch]$NoPrerequisiteAcquisition,[switch]$SkipDesktopShortcut,$CancelPath,$SecureAcquisitionManifestPath,$SecureAcquisitionManifestSha256,$SecureDownloaderSha256)
$attempt=Split-Path -Parent $CancelPath
[IO.File]::WriteAllText((Join-Path $attempt 'bootstrap-entered.signal'),$InstallRoot)
$watch=[Diagnostics.Stopwatch]::StartNew()
while(!(Test-Path $InstallRoot) -and !(Test-Path (Join-Path $attempt 'create.signal'))){if($watch.Elapsed.TotalSeconds -gt 30){exit 23};Start-Sleep -Milliseconds 50}
[IO.Directory]::CreateDirectory($InstallRoot)|Out-Null
[IO.File]::AppendAllText((Join-Path $InstallRoot 'entered.log'),"entered`r`n")
$watch=[Diagnostics.Stopwatch]::StartNew()
while(!(Test-Path (Join-Path $InstallRoot 'release.signal'))){if($watch.Elapsed.TotalSeconds -gt 30){exit 23};Start-Sleep -Milliseconds 50}
exit 0
'@)
$manifest=Join-Path $fixture 'manifest.json';[IO.File]::WriteAllText($manifest,'{}')
$downloader=Join-Path $fixture 'download-artifact.ps1';[IO.File]::WriteAllText($downloader,'# fixture')
$native=Join-Path $env:SystemRoot 'System32/WindowsPowerShell/v1.0/powershell.exe'
function Pin($path){(Get-FileHash -LiteralPath $path).Hash.ToLowerInvariant()}
function Start-AliasWorker($root,$name){
    $attempt=Join-Path $fixture $name;[IO.Directory]::CreateDirectory($attempt,$acl)|Out-Null
    [IO.File]::WriteAllText((Join-Path $attempt 'decision.lock'),'')
    $argfile=Join-Path $attempt 'arguments.json'
    [IO.File]::WriteAllText($argfile,(@{schema_version=1;parameters=@{InstallRoot=$root;ArchivePath=(Join-Path $fixture 'archive.zip');NonInteractive=$true;NoPrerequisiteAcquisition=$true;SkipDesktopShortcut=$true}}|ConvertTo-Json -Depth 4))
    $invocation=@{BootstrapPath=$bootstrap;BootstrapSha256=(Pin $bootstrap);ManifestPath=$manifest;ManifestSha256=(Pin $manifest);DownloaderPath=$downloader;DownloaderSha256=(Pin $downloader);ArgumentsPath=$argfile;ArgumentsSha256=(Pin $argfile);HelperSha256=(Pin $helper);AttemptDirectory=$attempt}
    $cli=@('-NoProfile','-NonInteractive','-File',('"'+$helper+'"'),'-Worker')
    foreach($key in $invocation.Keys){$cli+='-'+$key;$cli+='"'+$invocation[$key]+'"'}
    $p=Start-Process $native -ArgumentList ($cli -join ' ') -WindowStyle Hidden -PassThru -RedirectStandardOutput (Join-Path $attempt 'out.log') -RedirectStandardError (Join-Path $attempt 'err.log')
    $handle=$p.Handle;return $p
}
function Wait-Terminal($process){Assert ($process.WaitForExit(40000)) 'Alias fixture worker remains pending; no kill performed.';$process.WaitForExit();$code=[int]$process.ExitCode;$process.Dispose();return $code}
$identityAst=[Management.Automation.Language.Parser]::ParseFile((Join-Path $repo 'installer/run-source-build.ps1'),[ref]$tokens,[ref]$errors)
foreach($node in $identityAst.FindAll({param($n)$n -is [Management.Automation.Language.FunctionDefinitionAst] -and $n.Name -in @('Assert-BuildPath','Get-BuildTargetIdentity')},$true)){. ([scriptblock]::Create($node.Extent.Text))}
foreach($absent in @($false,$true)){
    $parent=Join-Path $fixture ('long existing target ancestor '+$absent);[IO.Directory]::CreateDirectory($parent)|Out-Null
    $root=if($absent){Join-Path $parent 'new target/another absent leaf'}else{$parent}
    $aliasParent=Short-Path $parent
    Assert ($aliasParent -and $aliasParent -ine $parent) 'Eligible fixture unexpectedly lost real alias.'
    $alias=if($absent){Join-Path $aliasParent 'new target/another absent leaf'}else{$aliasParent}
    $first=Start-AliasWorker $root ('long-'+$absent);$second=$null
    try{
        $firstSignal=Join-Path $fixture ('long-'+$absent+'/bootstrap-entered.signal')
        $secondSignal=Join-Path $fixture ('short-'+$absent+'/bootstrap-entered.signal')
        $watch=[Diagnostics.Stopwatch]::StartNew();while(!(Test-Path $firstSignal) -and !$first.HasExited -and $watch.Elapsed.TotalSeconds -lt 15){Start-Sleep -Milliseconds 50}
        Assert (Test-Path $firstSignal) 'Long-path worker never entered.'
        if($absent){Assert (!(Test-Path $root) -and !(Test-Path $alias)) 'Absent target was created before alias lock observation.'}
        "OBSERVED long-input=$root; short-input=$alias; lexical-long=$([IO.Path]::GetFullPath($root)); lexical-short=$([IO.Path]::GetFullPath($alias))"
        $longIdentity=Get-BuildTargetIdentity $root;$shortIdentity=Get-BuildTargetIdentity $alias
        Assert ($longIdentity -ceq $shortIdentity) 'Actual canonical target identity differs between confirmed aliases.'
        "OBSERVED actual shared lock identity=$longIdentity"
        $second=Start-AliasWorker $alias ('short-'+$absent)
        $rejected=$second.WaitForExit(3000)
        Assert (!(Test-Path $secondSignal)) 'RED: real short/long aliases entered the same physical target concurrently.'
        Assert ($rejected -and !$first.HasExited) 'Alias contender did not reject while original stayed live.'
        $code=Wait-Terminal $second;$second=$null;Assert ($code -ne 0) 'Alias contender returned success.'
    }finally{
        [IO.Directory]::CreateDirectory($root)|Out-Null
        [IO.File]::WriteAllText((Join-Path $root 'release.signal'),'fixture release')
        $firstExit=Wait-Terminal $first
        if($second){Wait-Terminal $second|Out-Null}
    }
    Assert ($firstExit -eq 0) 'Original alias worker was disturbed.'
    $retry=Start-AliasWorker $alias ('retry-'+$absent)
    Assert ((Wait-Terminal $retry) -eq 0 -and [IO.File]::ReadAllLines((Join-Path $root 'entered.log')).Count -eq 2) 'Alias terminal release/retry failed.'
    "PASS real alias exclusion/release, initially absent target=$absent; long=$root; short=$alias"
}
foreach($unsafe in @('foreign-existing-ancestor','reparse-existing-ancestor','file-existing-ancestor')){
    $ancestor=Join-Path $fixture $unsafe
    if($unsafe -eq 'file-existing-ancestor'){[IO.File]::WriteAllText($ancestor,'preserve fixture file')}
    elseif($unsafe -eq 'reparse-existing-ancestor'){New-Item -ItemType Junction -Path $ancestor -Target $fixture|Out-Null}
    else{
        [IO.Directory]::CreateDirectory($ancestor,$acl)|Out-Null
        $original=[IO.Directory]::GetAccessControl($ancestor,[Security.AccessControl.AccessControlSections]::Access)
        $foreign=[IO.Directory]::GetAccessControl($ancestor,[Security.AccessControl.AccessControlSections]::Access)
        $foreign.AddAccessRule([Security.AccessControl.FileSystemAccessRule]::new([Security.Principal.SecurityIdentifier]::new('S-1-1-0'),'Write','Allow'));[IO.Directory]::SetAccessControl($ancestor,$foreign)
    }
    $failed=$false;try{Get-BuildTargetIdentity (Join-Path $ancestor 'absent target')|Out-Null}catch{$failed=$true}
    finally{if($unsafe -eq 'foreign-existing-ancestor'){[IO.Directory]::SetAccessControl($ancestor,$original)}}
    Assert $failed "Unsafe existing ancestor was accepted: $unsafe"
}
'PASS actual target normalizer rejects foreign-write/reparse/file ancestors'
