$ErrorActionPreference='Stop'
. (Join-Path $PSScriptRoot 'InstallerSetupReceipt.Tests.ps1')
[IO.Directory]::SetAccessControl((Join-Path $setup 'installation-receipts'),$acl)
$repo=Split-Path -Parent $PSScriptRoot
$worker=Join-Path $repo 'installer/run-maintenance.ps1'
$runtime=$context.install_root;$base=Split-Path -Parent $runtime;$releaseId=Split-Path -Leaf $runtime
$bootstrap=Join-Path $setup 'install.ps1';[IO.File]::WriteAllText($bootstrap,'throw "The bootstrap must never execute during app maintenance."')
$dependency=Join-Path $setup 'installer-dependencies-v1.json';[IO.File]::WriteAllText($dependency,'{"schema_version":1}')
$inertUpdater=Join-Path $setup 'update-app.ps1'
$inert=@'
param($BaseRoot,$ManifestPath,$WheelPath,[switch]$Rollback,[switch]$NoShortcut,[scriptblock]$StopOwnedApp)
& $StopOwnedApp
$observed=@()
foreach($name in @('install.ps1','installer-dependencies-v1.json','update-app.ps1','write-setup-receipt.ps1','uninstall-owned-release.ps1')) {
    $path=Join-Path $PSScriptRoot $name;$denied=$false
    try{$h=[IO.File]::Open($path,'Open','Write','ReadWrite');$h.Dispose()}catch [IO.IOException]{$denied=(($_.Exception.HResult -band 65535) -eq 32)}
    if(!$denied){throw 'Maintenance input was mutable: '+$name};$observed+=,$name
}
[IO.File]::WriteAllText((Join-Path $BaseRoot 'observed.json'),(@{locked=$observed;rollback=[bool]$Rollback;manifest=$ManifestPath;wheel=$WheelPath}|ConvertTo-Json))
if($Rollback){exit 7};'inert app-only update; zero runtime assets';exit 0
'@
[IO.File]::WriteAllText($inertUpdater,$inert)
foreach($name in @('write-setup-receipt.ps1','uninstall-owned-release.ps1')){Copy-Item -LiteralPath (Join-Path $repo ('installer/'+$name)) -Destination (Join-Path $setup $name) -Force}
$updated=@{}+$context;$updated.release_id=$releaseId;$updated.bootstrap_sha256=Pin $bootstrap;$updated.dependency_manifest_sha256=Pin $dependency;$updated.source_helper_sha256=Pin (Join-Path $setup 'write-setup-receipt.ps1')
$old=[IO.File]::ReadAllText($descriptor.path);$h=$old|ConvertFrom-Json
foreach($name in $updated.Keys){$h.context.$name=$updated[$name]}
[IO.File]::WriteAllText($descriptor.path,($h|ConvertTo-Json -Depth 16))
$positive=@{}+$finalArgs;$positive.Context=$updated;$positive.HandoffSha256=Pin $descriptor.path
$result=Write-SetupInstallationReceipt @positive
[IO.File]::WriteAllText(($result.path -replace '\.json$','.sha256'),$result.sha256)
$native=Join-Path $env:WINDIR 'System32/WindowsPowerShell/v1.0/powershell.exe'
function Run([switch]$Rollback,[string]$BootstrapPin=(Pin $bootstrap)){
    $argv=@('-NoProfile','-NonInteractive','-ExecutionPolicy','Bypass','-File',('"'+$worker+'"'),'-BaseRoot',('"'+$base+'"'),'-ReleaseId',$releaseId,
        '-ReceiptPath',('"'+$result.path+'"'),'-ReceiptSha256',$result.sha256,'-ReceiptHelperSha256',(Pin (Join-Path $setup 'write-setup-receipt.ps1')),
        '-OwnershipHelperSha256',(Pin (Join-Path $setup 'uninstall-owned-release.ps1')),'-UpdaterSha256',(Pin $inertUpdater),'-BootstrapSha256',$BootstrapPin,'-DependencyManifestSha256',(Pin $dependency),'-NoShortcut')
    if($Rollback){$argv+='-Rollback'}
    $out=Join-Path $fixture ('maintenance-'+[guid]::NewGuid().ToString('N')+'.out');$err=$out+'.err'
    $p=Start-Process $native -ArgumentList ($argv -join ' ') -WindowStyle Hidden -PassThru -RedirectStandardOutput $out -RedirectStandardError $err
    $null=$p.Handle;$p.WaitForExit();$code=$p.ExitCode;$p.Dispose()
    @{code=$code;stdout=[IO.File]::ReadAllText($out);stderr=[IO.File]::ReadAllText($err)}
}
$first=Run
Assert ($first.code -eq 0) ('Native maintenance worker failed: '+$first.stderr)
$observed=Get-Content (Join-Path $base 'observed.json') -Raw|ConvertFrom-Json
Assert ($observed.locked.Count -eq 5 -and !$observed.rollback) 'Inputs were not held through the real updater invocation.'
$rollback=Run -Rollback
Assert ($rollback.code -eq 7) 'Actual nonzero updater exit was hidden.'
$bad=Run -BootstrapPin ('0'*64)
Assert ($bad.code -ne 0 -and $bad.stderr -match 'SHA256 differs|provenance differs') 'Changed pinned bootstrap was accepted.'
Assert ([IO.File]::ReadAllText($bootstrap).Contains('must never execute')) 'Pinned bootstrap was executed or changed.'
'PASS actual hidden worker: owned-stop callback, exact input locks, no bootstrap execution, real exit propagation and pin rejection'
