$ErrorActionPreference='Stop'
# Reuse the real source/final receipt producer fixture, including legacy schema1.
. (Join-Path $PSScriptRoot 'InstallerSetupReceipt.Tests.ps1')
[IO.Directory]::SetAccessControl((Join-Path $setup 'installation-receipts'),$acl)
$base=Split-Path -Parent $context.install_root
$baseRows=@()
foreach($name in @('Start-AutoClip.ps1','Start-AutoClip-Desktop.ps1')){
    $path=Join-Path $base $name;[IO.File]::WriteAllText($path,'inert stable launcher '+$name)
    $baseRows+=@{path=$name;bytes=(Get-Item $path).Length;sha256=(Pin $path)}
}
$maintenanceRows=@()
foreach($name in @('uninstall-owned-release.ps1','write-setup-receipt.ps1','remove-owned-file.ps1','run-source-build.ps1','update.ps1','update-app.ps1','initialize-selection.ps1','run-maintenance.ps1','AutoClip-Maintenance.exe','install.ps1','installer-dependencies-v1.json')){
    $path=Join-Path $setup $name;[IO.File]::WriteAllText($path,'inert maintenance file '+$name)
    $maintenanceRows+=@{path=$name;bytes=(Get-Item $path).Length;sha256=(Pin $path)}
}
$stableLink=Join-Path $fixture 'stable.lnk';$maintenanceLink=Join-Path $fixture 'maintenance.lnk'
$shell=New-Object -ComObject WScript.Shell;$link=$shell.CreateShortcut($stableLink)
$link.TargetPath=Join-Path $env:WINDIR 'System32/WindowsPowerShell/v1.0/powershell.exe';$link.Arguments='-NoProfile -WindowStyle Hidden -File "'+(Join-Path $base 'Start-AutoClip-Desktop.ps1')+'"';$link.WorkingDirectory=$base;$link.Save()
$link=$shell.CreateShortcut($maintenanceLink);$link.TargetPath=Join-Path $setup 'AutoClip-Maintenance.exe';$link.WorkingDirectory=$setup;$link.Save()
$v2Context=@{}+$context;$v2Context.release_id='maintenance-enabled'
$oldHandoff=[IO.File]::ReadAllText($descriptor.path)
$v2Handoff=$oldHandoff|ConvertFrom-Json;$v2Handoff.context.release_id=$v2Context.release_id
[IO.File]::WriteAllText($descriptor.path,($v2Handoff|ConvertTo-Json -Depth 16))
try{
    $args2=@{}+$finalArgs;$args2.Context=$v2Context;$args2.HandoffSha256=Pin $descriptor.path;$args2.BaseFiles=$baseRows
    $args2.NativeFiles=@($native)+$maintenanceRows;$args2.NativeShortcutPath=$stableLink;$args2.NativeShortcutSha256=Pin $stableLink
    $args2.MaintenanceShortcutPath=$maintenanceLink;$args2.MaintenanceShortcutSha256=Pin $maintenanceLink
    $result=Write-SetupInstallationReceipt @args2
    $record=Get-Content $result.path -Raw|ConvertFrom-Json
    Assert ($record.schema_version -eq 2 -and $record.base_files.Count -eq 2 -and $record.shortcuts.Count -eq 3) 'Managed base launcher or maintenance shortcut ownership missing.'
    $bad=@{}+$args2;$bad.BaseFiles=@($baseRows[0]);Reject {Write-SetupInstallationReceipt @bad} 'Incomplete stable pair accepted.'
    $bad=@{}+$args2;$bad.BaseFiles=@($baseRows)+@(@{path='unknown.txt';bytes=0;sha256=('a'*64)})
    Reject {Write-SetupInstallationReceipt @bad} 'Arbitrary base ownership accepted.'
    [IO.File]::WriteAllText((Join-Path $base $baseRows[0].path),'modified')
    Reject {Write-SetupInstallationReceipt @args2} 'Changed launcher bytes accepted.'
    . (Join-Path $PSScriptRoot '../installer/remove-owned-file.ps1')
    . (Join-Path $PSScriptRoot '../installer/uninstall-owned-release.ps1')
    [IO.File]::WriteAllText((Join-Path $base 'unknown-user-file.txt'),'preserve')
    $removed=Remove-ReceiptOwnedBaseFiles -BaseRoot $base -Rows $record.base_files
    Assert ($removed.status -eq 'PRESERVED' -and $removed.removed.Count -eq 1 -and $removed.preserved.Count -eq 1) 'Base cleanup failed to remove exact bytes while preserving modified bytes.'
    Assert ([IO.File]::ReadAllText((Join-Path $base $baseRows[0].path)) -ceq 'modified') 'Modified launcher was deleted.'
    Assert ([IO.File]::ReadAllText((Join-Path $base 'unknown-user-file.txt')) -ceq 'preserve') 'Unknown base file was deleted.'
}finally{[IO.File]::WriteAllText($descriptor.path,$oldHandoff)}
'PASS schema1 compatibility and schema2 finite exact base ownership'
