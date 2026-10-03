param([string]$ArtifactDirectory = 'D:\AutoClip-Inno-Migration\msys-base-audit')
$ErrorActionPreference = 'Stop'
$repo = Split-Path -Parent $PSScriptRoot
$helper = Join-Path $repo 'installer/install-msys2-base.ps1'
$fixture = Join-Path $env:TEMP ('ac-msbase-tests-' + [guid]::NewGuid().ToString('N'))
[IO.Directory]::CreateDirectory($fixture) | Out-Null
try {
    $manifest = Get-Content (Join-Path $repo 'release/manifests/installer-dependencies-v1.json') -Raw | ConvertFrom-Json
    $base = @($manifest.build_prerequisites | Where-Object identity -eq 'MSYS2')[0]
    $base.url = 'https://github.com/msys2/msys2-installer/releases/download/2026-06-11/msys2-base-x86_64-20260611.tar.xz'
    $base.filename = 'msys2-base-x86_64-20260611.tar.xz'; $base.bytes = 53555380
    $base.sha256 = 'a2d047e8ee213c3c6a49a8de427eb1069df12207c0422ff1b3cbb5c905c34221'
    $base.delivery_classification = 'DIRECT_RECIPIENT_DOWNLOAD'
    $base | Add-Member artifact_kind archive -Force; $base | Add-Member archive_format tar.xz -Force
    $base | Add-Member signature ([pscustomobject]@{filename=$base.filename+'.sig';bytes=566;sha256='076f5623b702d5016cf0253e1d14a6bd4870a90243243e96409b227f0d5bf70f';delivery_classification='DIRECT_RECIPIENT_DOWNLOAD'}) -Force
    $base | Add-Member installer_key ([pscustomobject]@{filename='installer-signer.asc';bytes=52107;sha256='a247a92716ab322770e800793c10136dd22a6ea4691fdd2b9c72d4cfc5221082';delivery_classification='DIRECT_RECIPIENT_DOWNLOAD';fingerprint='0EBF782C5D53F7E5FB02A66746BD761F7A49B0EC'}) -Force
    $manifestPath = Join-Path $fixture 'manifest.json'
    $manifest | ConvertTo-Json -Depth 30 | Set-Content $manifestPath -Encoding UTF8
    $arguments = @{
        BaseArchivePath=Join-Path $ArtifactDirectory $base.filename
        BaseSignaturePath=Join-Path $ArtifactDirectory ($base.filename+'.sig')
        InstallerKeyPath=Join-Path $ArtifactDirectory 'installer-signer.asc'
        ManifestPath=$manifestPath; ManifestSha256=(Get-FileHash $manifestPath).Hash.ToLowerInvariant()
        PythonPath=Join-Path $env:LOCALAPPDATA 'Programs/Python/Python311/python.exe'
        ExtractionHelperPath=Join-Path $repo 'installer/extract-msys2-base.py'
        ExtractionHelperSha256='23307cdbcafd03fb0d03b209cb2dceb35a4e2eed99c2ecfccda9571374fc1596'
        DestinationParent=Join-Path ([IO.Path]::GetPathRoot($fixture)) ('acmb-' + [guid]::NewGuid().ToString('N').Substring(0,8))
        LogDirectory=Join-Path $fixture 'logs'
    }
    # Default is a genuine public helper invocation. No extraction or vendor execution.
    $before = @(Get-ChildItem -LiteralPath $fixture -Recurse -Force | ForEach-Object FullName)
    $plan = & $helper @arguments
    if ($plan.status -cne 'PLANNED_PINNED_BASE' -or $plan.execution_performed -ne $false) { throw 'Default invocation did not produce read-only base plan.' }
    if (Test-Path $arguments.DestinationParent) { throw 'Planning created the extraction parent.' }
    if (@(Compare-Object $before @(Get-ChildItem -LiteralPath $fixture -Recurse -Force | ForEach-Object FullName)).Count) { throw 'Planning changed files.' }
    'MSYS2 base: authenticated default plan does not mutate or execute PASS'
    function Assert-Rejected([scriptblock]$Action,[string]$Pattern) {
        try { & $Action | Out-Null } catch { if ($_.Exception.Message -notmatch $Pattern) { throw }; return }
        throw ('Expected guarded rejection did not occur: ' + $Pattern)
    }
    $savedHash=$arguments.ManifestSha256; $arguments.ManifestSha256='0'*64
    Assert-Rejected { & $helper @arguments } 'manifest hash'; $arguments.ManifestSha256=$savedHash
    $savedArchive=$arguments.BaseArchivePath
    $badArchive=Join-Path $fixture $base.filename; [IO.File]::WriteAllText($badArchive,'first-party malformed archive fixture')
    $arguments.BaseArchivePath=$badArchive; Assert-Rejected { & $helper @arguments } 'file pin'; $arguments.BaseArchivePath=$savedArchive
    $savedParent=$arguments.DestinationParent; $arguments.DestinationParent=Join-Path $fixture 'foreign'
    [IO.Directory]::CreateDirectory($arguments.DestinationParent) | Out-Null
    $foreign=Join-Path $arguments.DestinationParent 'preserve.txt'; [IO.File]::WriteAllText($foreign,'foreign untouched')
    Assert-Rejected { & $helper @arguments } 'ASCII|already exists'
    if ([IO.File]::ReadAllText($foreign) -cne 'foreign untouched') { throw 'Foreign contents changed.' }; $arguments.DestinationParent=$savedParent
    $cancel=Join-Path $fixture 'cancel'; [IO.File]::WriteAllText($cancel,'cancel fixture'); $arguments.CancelPath=$cancel
    Assert-Rejected { & $helper @arguments } 'cancelled'; $arguments.Remove('CancelPath')
    if (Test-Path $arguments.LogDirectory) { throw 'Guard failure created logs.' }

    # Load actual functions without executing the provisioning body; all filesystem/hash/ACL guards remain real.
    $tokens=$null; $errors=$null
    $ast=[Management.Automation.Language.Parser]::ParseFile($helper,[ref]$tokens,[ref]$errors)
    if ($errors.Count) { throw 'Helper parse errors.' }
    foreach ($node in $ast.FindAll({param($n) $n -is [Management.Automation.Language.FunctionDefinitionAst]},$false)) { . ([scriptblock]::Create($node.Extent.Text)) }
    $platform=Get-BasePlatform
    $component=Join-Path $fixture 'component'; New-ProtectedBaseDirectory $component
    $emptyFile=Join-Path $component 'archive-empty-placeholder.pem'
    [IO.File]::WriteAllBytes($emptyFile,[byte[]]@())
    $emptyPin=@{bytes=0;sha256='e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855'}
    Assert-BasePin $emptyFile $emptyPin -AllowEmpty
    Assert-Rejected { Assert-BasePin $emptyFile $emptyPin } 'pin differs'
    [IO.File]::WriteAllText($emptyFile,'changed archive placeholder')
    Assert-Rejected { Assert-BasePin $emptyFile $emptyPin -AllowEmpty } 'pin differs'
    $jsonPath=Join-Path $component 'receipt.json'; Write-BaseJson $jsonPath @{status='FIRST_PARTY_UNIT_FIXTURE'}
    $jsonHash=(Get-FileHash $jsonPath).Hash
    Assert-Rejected { Write-BaseJson $jsonPath @{status='OVERWRITE'} } 'preserved'
    if ((Get-FileHash $jsonPath).Hash -ne $jsonHash -or @(Get-ChildItem $component -Filter '*.tmp' -Force).Count) { throw 'Atomic write changed existing receipt or left temporary output.' }
    $root=Join-Path $component 'code-fixture'; New-ProtectedBaseDirectory $root
    foreach($path in @('usr/bin','etc/profile.d','etc/post-install','etc/msystem.d','etc')) { [IO.Directory]::CreateDirectory((Join-Path $root $path)) | Out-Null }
    foreach($path in @('usr/bin/fixture.dll','etc/profile.d/fixture.sh','etc/post-install/fixture.post','etc/msystem.d/MSYS','etc/bash.bashrc','etc/msystem','etc/profile','msys2_shell.cmd')) { [IO.File]::WriteAllText((Join-Path $root $path),'first-party source fixture') }
    $code=@(Get-BaseCodeFiles); if ($code.Count -ne 8) { throw 'Code closure missing actual sourced msystem/bash files.' }; Assert-BaseCodeFiles $code
    [IO.File]::AppendAllText((Join-Path $root 'usr/bin/fixture.dll'),'changed'); Assert-Rejected { Assert-BaseCodeFiles $code } 'closure changed'
    $emptyAcl=Join-Path $component 'empty-acl'; New-ProtectedBaseDirectory $emptyAcl
    $security=[IO.Directory]::GetAccessControl($emptyAcl,[Security.AccessControl.AccessControlSections]::Access)
    foreach($rule in @($security.GetAccessRules($true,$false,[Security.Principal.SecurityIdentifier]))) { $security.RemoveAccessRuleSpecific($rule) }
    try { [IO.Directory]::SetAccessControl($emptyAcl,$security); Assert-Rejected { Assert-BaseAcl $emptyAcl -RequireProtected } 'DACL|ACL|denied' }
    finally { $sid=[Security.Principal.SecurityIdentifier]::new($platform.sid); $security.AddAccessRule([Security.AccessControl.FileSystemAccessRule]::new($sid,'FullControl','ContainerInherit,ObjectInherit','None','Allow')); [IO.Directory]::SetAccessControl($emptyAcl,$security) }
    'MSYS2 base: pins, foreign-root preservation, cancellation, actual atomic receipt/hash/code/ACL guards PASS'
    # Test only the actual elevation guard function: no provisioning body or native invoker is reachable.
    function Get-BaseElevation { $true }
    Assert-Rejected { Get-BasePlatform } 'Elevated'
    if (Test-Path $arguments.DestinationParent) { throw 'Elevated invocation created a root.' }
    # Exercise process environment restoration without a provisioning body or a native child.
    $originalEnvironment=Save-BaseEnvironment
    try {
        foreach($name in @('BASH_ENV','ENV','GNUPGHOME','PS1','XDG_CONFIG_HOME','ORIGINAL_PATH','CYG_SYS_BASHRC','BASH_FUNC_fixture%%')) { [Environment]::SetEnvironmentVariable($name,'foreign startup fixture','Process') }
        $savedEnvironment=Save-BaseEnvironment
        try {
            Set-BaseEnvironment
            foreach($name in @('BASH_ENV','ENV','GNUPGHOME','PS1','XDG_CONFIG_HOME','ORIGINAL_PATH','CYG_SYS_BASHRC','BASH_FUNC_fixture%%')) { if ([Environment]::GetEnvironmentVariable($name,'Process')) { throw 'Ambient startup state survived.' } }
            if ($env:HOME -cne '/home/autoclip-base' -or $env:MSYS2_PATH_TYPE -cne 'strict' -or $env:MSYSTEM -cne 'MSYS') { throw 'Fixed startup environment missing.' }
            throw 'FIRST_PARTY_SIMULATED_FAILURE'
        } catch { if ($_.Exception.Message -cne 'FIRST_PARTY_SIMULATED_FAILURE') { throw } }
        finally { Restore-BaseEnvironment }
        foreach($name in $savedEnvironment.Keys) { if ([Environment]::GetEnvironmentVariable($name,'Process') -cne $savedEnvironment[$name]) { throw 'Caller environment not restored after failure.' } }
    } finally { $savedEnvironment=$originalEnvironment; Restore-BaseEnvironment; [Environment]::SetEnvironmentVariable('BASH_FUNC_fixture%%',$null,'Process') }
    # Foreign inheritable-only grants must also be rejected before they can affect new children.
    $security=[IO.Directory]::GetAccessControl($component,[Security.AccessControl.AccessControlSections]::Access)
    $foreignRule=[Security.AccessControl.FileSystemAccessRule]::new([Security.Principal.SecurityIdentifier]::new('S-1-1-0'),'Write','ContainerInherit,ObjectInherit','InheritOnly','Allow')
    $security.AddAccessRule($foreignRule)
    try { [IO.Directory]::SetAccessControl($component,$security); Assert-Rejected { Assert-BaseAcl $component -RequireProtected } 'Foreign base writer' }
    finally { $security.RemoveAccessRuleSpecific($foreignRule); [IO.Directory]::SetAccessControl($component,$security) }
    'MSYS2 base: isolated elevated-token rejection, inherited-only foreign writes, fixed startup environment and failure restoration PASS'
    $CancelPath=$cancel
    Assert-Rejected { Write-BaseJson (Join-Path $component 'cancelled-base.json') @{status='VERIFIED_PINNED_BASE'} } 'cancelled'
    if (Test-Path (Join-Path $component 'cancelled-base.json')) { throw 'Cancelled state produced a verified receipt.' }
    Write-BaseJson (Join-Path $component 'failure.json') @{status='FAILED_BASE_PRESERVED';root='first-party fixture only'}
    if ((Get-Content (Join-Path $component 'failure.json') -Raw|ConvertFrom-Json).status -cne 'FAILED_BASE_PRESERVED') { throw 'Cancellation prevented durable failure state.' }
    $CancelPath=$null
    Assert-Rejected { Assert-BaseInventory @{schema_version=1;status='VERIFIED_ARCHIVE_EXTRACTION';inventory=@();file_count=15529;directory_count=1052} } 'receipt differs'
    'MSYS2 base: cancellation cannot publish verified receipt; failure receipt retained; count-only extraction claims rejected PASS'
    $keyringDirectory=Join-Path $root 'usr/share/pacman/keyrings'; [IO.Directory]::CreateDirectory($keyringDirectory)|Out-Null
    $trustedId='1111111111111111111111111111111111111111'; $revokedId='2222222222222222222222222222222222222222'; $secondMaster='3333333333333333333333333333333333333333'
    [IO.File]::WriteAllText((Join-Path $keyringDirectory 'msys2-trusted'),($trustedId+":4:`n"+$secondMaster+':4:'))
    [IO.File]::WriteAllText((Join-Path $keyringDirectory 'msys2-revoked'),$revokedId)
    $fingerprintLine='fpr:::::::::'
    function Pub-Line([string]$Id,[string]$Trust='f') { (@('pub',$Trust,'4096','1',$Id.Substring(24),'0','','','','','','scSC') -join ':')+':' }
    $completeTrust=@((Pub-Line $trustedId),($fingerprintLine+$trustedId+':'),(Pub-Line $secondMaster),($fingerprintLine+$secondMaster+':'),(Pub-Line $revokedId r),($fingerprintLine+$revokedId+':'))
    Assert-BaseKeyringTrust $completeTrust
    Assert-Rejected { Assert-BaseKeyringTrust @((Pub-Line $trustedId),($fingerprintLine+$trustedId+':'),(Pub-Line $revokedId r),($fingerprintLine+$revokedId+':')) } 'trusted master'
    Assert-Rejected { Assert-BaseKeyringTrust @((Pub-Line $revokedId),($fingerprintLine+$revokedId+':')) } 'trusted|revoked'
    Assert-Rejected { Assert-BaseKeyringTrust @((Pub-Line $trustedId),($fingerprintLine+$secondMaster+':'),(Pub-Line $secondMaster),($fingerprintLine+$trustedId+':'),(Pub-Line $revokedId r),($fingerprintLine+$revokedId+':')) } 'fingerprint|identity'
} finally {
    Write-Output ('First-party unit fixtures preserved: ' + $fixture)
}
