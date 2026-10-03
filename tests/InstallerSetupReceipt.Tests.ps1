$ErrorActionPreference='Stop'
function Assert($value,$message){if(-not $value){throw $message}}
function Reject($action,$message){$failed=$false;try{& $action|Out-Null}catch{$failed=$true};Assert $failed $message}
function Pin($path){(Get-FileHash -LiteralPath $path).Hash.ToLowerInvariant()}
$fixture=Join-Path $env:TEMP ('autoclip-setup-receipt-'+[guid]::NewGuid().ToString('N'))
$acl=[Security.AccessControl.DirectorySecurity]::new();$sid=[Security.Principal.WindowsIdentity]::GetCurrent().User
$acl.SetOwner($sid);$acl.SetAccessRuleProtection($true,$false)
foreach($id in @($sid.Value,'S-1-5-18','S-1-5-32-544')){$acl.AddAccessRule([Security.AccessControl.FileSystemAccessRule]::new([Security.Principal.SecurityIdentifier]::new($id),'FullControl','ContainerInherit,ObjectInherit','None','Allow'))}
[IO.Directory]::CreateDirectory($fixture,$acl)|Out-Null
$manifest=Join-Path $fixture 'release-manifest.json'
$payload=[Text.Encoding]::UTF8.GetBytes('pinned first-party payload')
$sha=[Security.Cryptography.SHA256]::Create();$payloadPin=[BitConverter]::ToString($sha.ComputeHash($payload)).Replace('-','').ToLowerInvariant();$sha.Dispose()
[IO.File]::WriteAllText($manifest,(@{schema_version=3;files=@(@{path='Start-AutoClip.ps1';bytes=$payload.Length;sha256=$payloadPin})}|ConvertTo-Json -Depth 6))
function Context($name){@{install_root=(Join-Path $fixture $name);release_id='first-party-release';profile='cpu';archive_sha256=('a'*64);release_manifest_sha256=(Pin $manifest);dependency_manifest_sha256=('b'*64);bootstrap_sha256=('c'*64);source_helper_sha256=('d'*64);health_helper_sha256=('e'*64)}}
function New-Root($context){[IO.Directory]::CreateDirectory($context.install_root,$acl)|Out-Null;[IO.File]::WriteAllBytes((Join-Path $context.install_root 'Start-AutoClip.ps1'),$payload);Copy-Item -LiteralPath $manifest -Destination (Join-Path $context.install_root 'release-manifest.json')}
$helper=Join-Path $PSScriptRoot '../installer/write-setup-receipt.ps1'
if(-not [IO.File]::Exists($helper)){throw 'RED: actual setup receipt producer is missing.'}
. $helper
$context=Context 'fresh'
$proof=Assert-SetupStartingProvenance -Context $context -ManifestPath $manifest
New-Root $context
function Add-Generated($context){
    $root=$context.install_root
    [IO.Directory]::CreateDirectory((Join-Path $root '.venv/Scripts'))|Out-Null
    [IO.File]::WriteAllText((Join-Path $root '.venv/Scripts/pythonw.exe'),'inert first-party interpreter; never execute')
    [IO.Directory]::CreateDirectory((Join-Path $root 'publisher-wheels/cpu'))|Out-Null
    [IO.File]::WriteAllText((Join-Path $root 'publisher-wheels/cpu/owned.whl'),'first-party generated wheel')
    $healthPath=Join-Path $fixture ($([IO.Path]::GetFileName($root))+'-health.json')
    $health=@{schema_version=1;status='VERIFIED_HEALTH_HOME';install_root=$root;manifest_sha256=$context.release_manifest_sha256;isolated_health_only=$true;desktop_tested=$false;media_tested=$false;model_inference_tested=$false;child=@{exit_code=0;receipt=@{health_status=200;home_status=200}}}
    [IO.File]::WriteAllText($healthPath,($health|ConvertTo-Json -Depth 6))
    $healthPin=@{result_path=$healthPath;bytes=(Get-Item $healthPath).Length;sha256=(Pin $healthPath);install_root=$root;manifest_sha256=$context.release_manifest_sha256;status='VERIFIED_HEALTH_HOME'}
    $shell=New-Object -ComObject WScript.Shell;$link=$shell.CreateShortcut((Join-Path $root 'AutoClip.lnk'))
    $link.TargetPath=Join-Path $root '.venv/Scripts/pythonw.exe';$link.Arguments='-m autoclip.desktop';$link.WorkingDirectory=$root;$link.Description='Start AutoClip';$link.Save()
    $launcher=@{path='AutoClip.lnk';bytes=(Get-Item (Join-Path $root 'AutoClip.lnk')).Length;sha256=(Pin (Join-Path $root 'AutoClip.lnk'));archive_sha256=$context.archive_sha256;release_manifest_sha256=$context.release_manifest_sha256}
    [IO.File]::WriteAllText((Join-Path $root 'native-build-receipt.json'),(@{profile='cpu';setup_app_health=$healthPin;setup_owned_launcher=$launcher}|ConvertTo-Json -Depth 8))
}
Add-Generated $context
$descriptor=Write-SetupSourceReceipt -Context $context -StartingProof $proof
Assert ($descriptor.status -eq 'VERIFIED_SOURCE_OUTPUTS' -and -not [IO.File]::Exists((Join-Path $context.install_root '.install-complete'))) 'Source handoff must precede marker.'
$handoff=Get-Content $descriptor.path -Raw|ConvertFrom-Json
Assert (@($handoff.files).Count -eq 6 -and @($handoff.files|Where-Object path -eq '.setup-source-ownership.json').Count -eq 0) 'Exact source inventory or no-self-hash failed.'
Assert ((Assert-SetupStartingProvenance -Context $context -ManifestPath $manifest).context.install_root -eq $context.install_root) 'Exact receipt-backed retry refused.'
[IO.File]::WriteAllText((Join-Path $context.install_root '.install-complete'),$context.archive_sha256)
$proofAfterMarker=Assert-SetupStartingProvenance -Context $context -ManifestPath $manifest
Assert $proofAfterMarker 'Retained source completion cannot be validated for caller repair.'
foreach($relative in @('.venv/unrelated.txt','publisher-wheels/unrelated.txt')){
    $path=Join-Path $context.install_root $relative;[IO.File]::WriteAllText($path,'must preserve unknown existing data')
    Reject {Assert-SetupStartingProvenance -Context $context -ManifestPath $manifest} 'Unknown dynamic file was adopted during retry.'
    Assert ([IO.File]::ReadAllText($path) -eq 'must preserve unknown existing data') 'Rejected provenance mutated unrelated data.'
    [IO.File]::Delete($path)
}
$static=Context 'static';New-Root $static
$staticProof=Assert-SetupStartingProvenance -Context $static -ManifestPath $manifest
Add-Generated $static
Reject {Write-SetupSourceReceipt -Context $static -StartingProof $proof} 'Foreign starting proof accepted.'
$healthPath=Join-Path $fixture 'static-health.json';$healthBefore=[IO.File]::ReadAllText($healthPath)
[IO.File]::WriteAllText($healthPath,'{"status":"FAILED_PRESERVED"}')
Reject {Write-SetupSourceReceipt -Context $static -StartingProof $staticProof} 'Changed health result accepted.'
Assert (-not [IO.File]::Exists((Join-Path $static.install_root '.setup-source-ownership.json'))) 'Failed health wrote source handoff.'
[IO.File]::WriteAllText($healthPath,$healthBefore)
Write-SetupSourceReceipt -Context $static -StartingProof $staticProof|Out-Null
$unproven=Context 'unproven';New-Root $unproven
[IO.Directory]::CreateDirectory((Join-Path $unproven.install_root '.venv'))|Out-Null
[IO.File]::WriteAllText((Join-Path $unproven.install_root '.venv/unrelated.txt'),'unproven')
Reject {Assert-SetupStartingProvenance -Context $unproven -ManifestPath $manifest} 'Unproven partial prefix became ownership.'
[IO.File]::WriteAllText((Join-Path $unproven.install_root 'Start-AutoClip.ps1'),'modified')
Reject {Assert-SetupStartingProvenance -Context $unproven -ManifestPath $manifest} 'Modified static payload accepted.'
$setup=Join-Path $fixture 'setup';[IO.Directory]::CreateDirectory((Join-Path $setup 'notices'),$acl)|Out-Null
$native=@()
foreach($name in @('notices/inno-setup-7.1.0-LICENSE.txt','notices/uv-0.12.19-LICENSE-MIT.txt','notices/uv-0.12.19-LICENSE-APACHE.txt','notices/setup-tool-sources.md','unins000.exe','unins000.dat')){
    $path=Join-Path $setup $name;[IO.File]::WriteAllText($path,'inert native output '+$name)
    $native+=@{path=$name;bytes=(Get-Item $path).Length;sha256=(Pin $path)}
}
$setupExe=Join-Path $fixture 'Setup.exe';[IO.File]::WriteAllText($setupExe,'inert original setup; never execute')
$shortcut=Join-Path $fixture 'native-AutoClip.lnk';Copy-Item -LiteralPath (Join-Path $context.install_root 'AutoClip.lnk') -Destination $shortcut
$registration=@{key='Software\Microsoft\Windows\CurrentVersion\Uninstall\{D7451842-48F4-487B-80E0-5C7E9E326342}_is1';view='Registry64';install_location=($setup+'\');uninstall_string=('"'+(Join-Path $setup 'unins000.exe')+'"')}
$finalArgs=@{Context=$context;HandoffSha256=(Pin $descriptor.path);SetupRoot=$setup;SetupExePath=$setupExe;SetupSha256=(Pin $setupExe);NativeFiles=$native;NativeShortcutPath=$shortcut;NativeShortcutSha256=(Pin $shortcut);Registration=$registration}
$final=Write-SetupInstallationReceipt @finalArgs
Assert ($final.status -eq 'COMPLETE' -and [IO.File]::Exists($final.path)) 'Actual final producer did not publish COMPLETE.'
$finalRecord=Get-Content $final.path -Raw|ConvertFrom-Json
Assert ($finalRecord.registration.install_location -ceq ($setup+'\')) 'Native InstallLocation snapshot was not preserved exactly.'
$wrongRegistration=@{}+$registration;$wrongRegistration.install_location=$setup
$wrongArgs=@{}+$finalArgs;$wrongArgs.Registration=$wrongRegistration
Reject {Write-SetupInstallationReceipt @wrongArgs} 'Non-native InstallLocation spelling accepted.'
Assert ($finalRecord.release_files.Count -eq 8 -and $finalRecord.setup_files.Count -eq 6 -and $finalRecord.setup_sha256 -eq (Pin $setupExe)) 'Final exact inventories/setup binding differ.'
# An additive cleanup-enabled final receipt owns exactly the five pinned helpers.
$cleanup=@()
foreach($name in @('uninstall-owned-release.ps1','write-setup-receipt.ps1','remove-owned-file.ps1','run-source-build.ps1','update.ps1')){
    $path=Join-Path $setup $name;[IO.File]::WriteAllText($path,'inert helper '+$name)
    $cleanup+=@{path=$name;bytes=(Get-Item $path).Length;sha256=(Pin $path)}
}
$cleanupContext=@{}+$context;$cleanupContext.release_id='cleanup-enabled'
$handoffBytes=[IO.File]::ReadAllText($descriptor.path);$cleanupHandoff=$handoffBytes|ConvertFrom-Json;$cleanupHandoff.context.release_id=$cleanupContext.release_id
[IO.File]::WriteAllText($descriptor.path,($cleanupHandoff|ConvertTo-Json -Depth 16))
try{
    $cleanupArgs=@{}+$finalArgs;$cleanupArgs.Context=$cleanupContext;$cleanupArgs.HandoffSha256=Pin $descriptor.path;$cleanupArgs.NativeFiles=@($native)+@($cleanup)
    $cleanupFinal=Write-SetupInstallationReceipt @cleanupArgs
    Assert ((Get-Content $cleanupFinal.path -Raw|ConvertFrom-Json).setup_files.Count -eq 11) 'Finite cleanup helper inventory rejected.'
}finally{[IO.File]::WriteAllText($descriptor.path,$handoffBytes)}
Write-SetupInstallationReceipt @finalArgs|Out-Null
$finalBefore=[IO.File]::ReadAllText($final.path)
$nativePath=Join-Path $setup 'notices/setup-tool-sources.md';$nativeBefore=[IO.File]::ReadAllText($nativePath)
[IO.File]::WriteAllText($nativePath,'changed native notice')
Reject {Write-SetupInstallationReceipt @finalArgs} 'Changed actual native output accepted.'
Assert ([IO.File]::ReadAllText($nativePath) -ceq 'changed native notice') 'Changed native output was overwritten.'
[IO.File]::WriteAllText($nativePath,$nativeBefore)
[IO.File]::WriteAllText((Join-Path $static.install_root '.install-complete'),$static.archive_sha256)
$otherShortcut=Join-Path $fixture 'other-native-AutoClip.lnk';Copy-Item -LiteralPath (Join-Path $static.install_root 'AutoClip.lnk') -Destination $otherShortcut
$conflict=@{}+$finalArgs;$conflict.Context=$static;$conflict.HandoffSha256=Pin (Join-Path $static.install_root '.setup-source-ownership.json');$conflict.NativeShortcutPath=$otherShortcut;$conflict.NativeShortcutSha256=Pin $otherShortcut
Reject {Write-SetupInstallationReceipt @conflict} 'Same release ID receipt adopted another valid install root.'
Assert ([IO.File]::ReadAllText($final.path) -ceq $finalBefore) 'Conflicting final publication changed prior record.'
foreach($field in @('profile','install_root')){
    $wrong=@{}+$context;$wrong[$field]=if($field -eq 'profile'){'nvidia'}else{$static.install_root}
    $bad=@{}+$finalArgs;$bad.Context=$wrong
    Reject {Write-SetupInstallationReceipt @bad} 'Wrong root/profile accepted.'
}
$bad=@{}+$finalArgs;$bad.HandoffSha256='0'*64;Reject {Write-SetupInstallationReceipt @bad} 'Wrong handoff pin accepted.'
$bad=@{}+$finalArgs;$bad.ReceiptPath=Join-Path $fixture 'foreign-receipt.json';Reject {Write-SetupInstallationReceipt @bad} 'Final receipt redirected outside canonical location.'
Assert (-not [IO.File]::Exists($bad.ReceiptPath)) 'Rejected final location was mutated.'
$original=[IO.File]::ReadAllText($descriptor.path)
foreach($fault in @('duplicate','traversal','changed')){
    $record=$original|ConvertFrom-Json
    if($fault -eq 'duplicate'){$record.files+=@($record.files[0])}
    elseif($fault -eq 'traversal'){$record.files[0].path='../foreign.txt'}
    else{$record.files[0].sha256='0'*64}
    [IO.File]::WriteAllText($descriptor.path,($record|ConvertTo-Json -Depth 12))
    $bad=@{}+$finalArgs;$bad.HandoffSha256=Pin $descriptor.path
    Reject {Write-SetupInstallationReceipt @bad} 'Invalid handoff inventory accepted.'
}
[IO.File]::WriteAllText($descriptor.path,$original)
$reparse=Join-Path $context.install_root 'publisher-wheels/junction'
New-Item -ItemType Junction -Path $reparse -Target $fixture|Out-Null
Reject {Assert-SetupStartingProvenance -Context $context -ManifestPath $manifest} 'Reparse tree accepted.'
[IO.Directory]::Delete($reparse)
$foreignPath=Join-Path $static.install_root '.setup-source-ownership.json'
$fileAcl=[IO.File]::GetAccessControl($foreignPath,[Security.AccessControl.AccessControlSections]::Access)
$foreign=[IO.File]::GetAccessControl($foreignPath,[Security.AccessControl.AccessControlSections]::Access)
$foreign.AddAccessRule([Security.AccessControl.FileSystemAccessRule]::new([Security.Principal.SecurityIdentifier]::new('S-1-1-0'),'Write','Allow'))
[IO.File]::SetAccessControl($foreignPath,$foreign)
Reject {Assert-SetupStartingProvenance -Context $static -ManifestPath $manifest} 'Foreign writable receipt accepted.'
[IO.File]::SetAccessControl($foreignPath,$fileAcl)
$deniedDirectory=Join-Path $setup 'installation-receipts'
$originalAcl=[IO.Directory]::GetAccessControl($deniedDirectory,[Security.AccessControl.AccessControlSections]::Access)
$deny=[IO.Directory]::GetAccessControl($deniedDirectory,[Security.AccessControl.AccessControlSections]::Access)
$deny.AddAccessRule([Security.AccessControl.FileSystemAccessRule]::new($sid,'WriteData','Deny'))
$newContext=@{}+$context;$newContext.release_id='other-release'
# Publication failure requires a valid handoff for the new identity, not a mocked writer.
$handoffOriginal=[IO.File]::ReadAllText($descriptor.path)
$newHandoff=$handoffOriginal|ConvertFrom-Json;$newHandoff.context.release_id=$newContext.release_id
[IO.File]::WriteAllText($descriptor.path,($newHandoff|ConvertTo-Json -Depth 16))
$deniedArgs=@{}+$finalArgs;$deniedArgs.Context=$newContext;$deniedArgs.HandoffSha256=Pin $descriptor.path
[IO.Directory]::SetAccessControl($deniedDirectory,$deny)
try{Reject {Write-SetupInstallationReceipt @deniedArgs} 'Denied actual atomic receipt write was swallowed.'}finally{[IO.Directory]::SetAccessControl($deniedDirectory,$originalAcl);[IO.File]::WriteAllText($descriptor.path,$handoffOriginal)}
Assert (-not [IO.File]::Exists((Join-Path $deniedDirectory 'other-release.json'))) 'Failed publication left COMPLETE record.'
Assert ([IO.File]::ReadAllText($final.path) -ceq $finalBefore) 'Failed publication changed prior record.'
'PASS actual source/final publication, exact fresh/static/receipt-backed provenance, foreign prefix preservation, identity/pin/inventory/reparse/ACL rejection; no app/native Setup/vendor execution'
'PRESERVED '+$fixture
