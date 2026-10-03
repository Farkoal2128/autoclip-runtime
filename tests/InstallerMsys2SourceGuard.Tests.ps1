$ErrorActionPreference = 'Stop'
$repo = Split-Path -Parent $PSScriptRoot
$installer = Join-Path $repo 'install.ps1'
$tokens=$null; $errors=$null
$ast=[Management.Automation.Language.Parser]::ParseFile($installer,[ref]$tokens,[ref]$errors)
if($errors.Count){throw 'Installer parser failed.'}
foreach($node in $ast.FindAll({param($n)$n -is [Management.Automation.Language.FunctionDefinitionAst] -and ($n.Name -like '*AutoClipMsys*' -or $n.Name -in @('Assert-AutoClipSecurePath','Read-AutoClipSecureInput','Assert-AutoClipBuildCancellation'))},$true)) {
    . ([scriptblock]::Create($node.Extent.Text.Replace('$PSScriptRoot', ('''' + $repo.Replace('''','''''') + ''''))))
}
$source=[IO.File]::ReadAllText($installer)
$start=$source.IndexOf('$msysRoot = Split-Path')
$end=$source.IndexOf('$git = Get-Command git.exe',$start)
if($start -lt 0 -or $end -lt 0){throw 'MSYS native prerequisite boundary missing.'}
# Replace only the native executable invocation; execute the actual prerequisite section.
$prerequisite=[scriptblock]::Create($source.Substring($start,$end-$start).Replace('& $MsysBash','Invoke-MsysSourceFixture'))
$fixture=Join-Path $env:TEMP ('autoclip-msys-source-'+[guid]::NewGuid().ToString('N'))
[IO.Directory]::CreateDirectory((Join-Path $fixture 'owned/msys64/usr/bin'))|Out-Null
[IO.Directory]::CreateDirectory((Join-Path $fixture 'owned/msys64/ucrt64/bin'))|Out-Null
[IO.File]::WriteAllText((Join-Path $fixture 'owned/msys64/usr/bin/bash.exe'),'fixture')
[IO.File]::WriteAllText((Join-Path $fixture 'owned/msys64/ucrt64/bin/nasm.exe'),'fixture')
$MsysBash=Join-Path $fixture 'owned/msys64/usr/bin/bash.exe'
$NoPrerequisiteAcquisition=$true
$SecureAcquisitionManifestPath=Join-Path $fixture 'manifest.json'
$MsysPackageReceiptPath=$null
$MsysPackageReceiptSha256=$null
$MsysBaseArchivePath=$null
$script:nativeCalls=0
function Invoke-MsysSourceFixture { $script:nativeCalls++; $global:LASTEXITCODE=0 }
$originalPath=$env:PATH; $originalMsystem=$env:MSYSTEM; $originalPathType=$env:MSYS2_PATH_TYPE
try {
    $rejected=$false
    try { & $prerequisite } catch { $rejected=$true }
    if(!$rejected -or $script:nativeCalls){throw "RED: secure source path invoked $script:nativeCalls MSYS calls without bound startup inputs."}
    'PASS missing bound MSYS startup inputs reject before native prerequisite queries'
    $owned=Join-Path $fixture 'owned'
    $acl=New-Object Security.AccessControl.DirectorySecurity
    $sid=[Security.Principal.WindowsIdentity]::GetCurrent().User
    $acl.SetOwner($sid); $acl.SetAccessRuleProtection($true,$false)
    foreach($identity in @($sid.Value,'S-1-5-18','S-1-5-32-544')) {
        $rule=New-Object Security.AccessControl.FileSystemAccessRule([Security.Principal.SecurityIdentifier]::new($identity),'FullControl','ContainerInherit,ObjectInherit','None','Allow')
        $acl.AddAccessRule($rule)
    }
    Set-Acl -LiteralPath $owned -AclObject $acl
    $msysRoot=Join-Path $owned 'msys64'
    $rootAcl=Get-Acl -LiteralPath $msysRoot
    $rootRules=@($rootAcl.GetAccessRules($true,$true,[Security.Principal.SecurityIdentifier]))
    if($rootAcl.AreAccessRulesProtected -or $rootRules.Count -ne 3 -or @($rootRules|Where-Object {-not $_.IsInherited}).Count){throw 'Fixture must match protected extraction parent with exactly three inherited root rules.'}
    foreach($directory in @('etc/profile.d','etc/post-install','etc/msystem.d','home/autoclip-base')) { [IO.Directory]::CreateDirectory((Join-Path $msysRoot $directory))|Out-Null }
    foreach($name in @('etc/profile','etc/msystem','etc/bash.bashrc','msys2_shell.cmd','etc/profile.d/start.sh','ucrt64/bin/dependency.dll')) { [IO.File]::WriteAllText((Join-Path $msysRoot $name),'trusted fixture') }
    $msysPrivateHome=Join-Path $msysRoot 'home/autoclip-base'
    foreach($name in @('.bash_profile','.bashrc','.profile')) { [IO.File]::WriteAllText((Join-Path $msysPrivateHome $name),'trusted HOME') }
    function Get-FixturePin($path,$relative) { [pscustomobject]@{path=$relative;bytes=(Get-Item -LiteralPath $path).Length;sha256=(Get-FileHash -LiteralPath $path).Hash.ToLowerInvariant()} }
    $script:homePins=@('.bash_profile','.bashrc','.profile'|ForEach-Object { Get-FixturePin (Join-Path $msysPrivateHome $_) $_ })
    # Only native platform/Python execution boundaries are replaced. All paths, ACLs, pins,
    # receipt parsing, enumeration, file locks and environment handling execute production code.
    function Get-AutoClipMsysElevation { $script:elevated }
    function Invoke-AutoClipMsysPython($Executable,$Arguments) {
        $script:pythonCalls++
        if($Arguments -contains '-CheckOnly'){return (Join-Path $env:SystemRoot 'System32/python.exe')}
        $script:homePins | ConvertTo-Json -Compress
    }
    $script:elevated=$false
    $script:pythonCalls=0
    $MsysBaseArchivePath=Join-Path $owned 'msys2-base-x86_64-20260611.tar.xz'
    [IO.File]::WriteAllText($MsysBaseArchivePath,'authenticated TAR fixture')
    $basePin=Get-FixturePin $MsysBaseArchivePath ''
    $base=[ordered]@{identity='MSYS2';version='20260611';filename=[IO.Path]::GetFileName($MsysBaseArchivePath);artifact_kind='archive';archive_format='tar.xz';delivery_classification='DIRECT_RECIPIENT_DOWNLOAD';bytes=$basePin.bytes;sha256=$basePin.sha256;packages=@()}
    foreach($name in @('diffutils','make','mingw-w64-ucrt-x86_64-nasm','mingw-w64-ucrt-x86_64-zlib','pkgconf')) { $base.packages+=@{identity=$name;version='fixture-1'} }
    $SecureAcquisitionManifestPath=Join-Path $owned 'manifest.json'
    [IO.File]::WriteAllText($SecureAcquisitionManifestPath,(@{schema_version=1;build_prerequisites=@($base)}|ConvertTo-Json -Depth 10))
    $SecureAcquisitionManifestSha256=(Get-FileHash $SecureAcquisitionManifestPath).Hash.ToLowerInvariant()
    $code=@(Get-AutoClipMsysCodePaths $msysRoot | ForEach-Object { Get-FixturePin (Join-Path $msysRoot $_) $_ })
    $receipt=[ordered]@{schema_version=1;status='VERIFIED_PINNED_PACKAGES';root=$msysRoot;private_home=$msysPrivateHome;manifest_sha256=$SecureAcquisitionManifestSha256;base_receipt_sha256=('a'*64);packages=@($base.packages|ForEach-Object {$_.identity+' '+$_.version});post_install_code_files=$code}
    # Keep receipt protection independent of extraction-parent protection, as in the guest.
    $receiptDirectory=Join-Path $owned 'receipts'
    [IO.Directory]::CreateDirectory($receiptDirectory)|Out-Null
    $receiptAcl=Get-Acl -LiteralPath $owned
    $receiptAcl.SetAccessRuleProtection($true,$false)
    (Get-Item -LiteralPath $receiptDirectory).SetAccessControl($receiptAcl)
    $MsysPackageReceiptPath=Join-Path $receiptDirectory 'packages.json'
    function Write-FixtureReceipt { [IO.File]::WriteAllText($MsysPackageReceiptPath,($receipt|ConvertTo-Json -Depth 10)); $script:MsysPackageReceiptSha256=(Get-FileHash $MsysPackageReceiptPath).Hash.ToLowerInvariant() }
    Write-FixtureReceipt
    function Assert-GuardRejected($Label) {
        $script:nativeCalls=0; $rejected=$false
        try { Invoke-AutoClipMsysSource { $script:nativeCalls++ } @() } catch { $rejected=$true }
        if(!$rejected -or $script:nativeCalls){throw "$Label did not reject before MSYS execution."}
        "PASS $Label"
    }
    $script:nativeCalls=0
    & $prerequisite
    if($script:nativeCalls -ne 12){throw 'Verified prerequisite section did not run its actual twelve queries.'}
    'PASS qualified actual prerequisite queries'
    $buildStart=$source.IndexOf('$msysBuildAction = {')
$buildEnd=$source.IndexOf('    $nativeReceiptBytes =',$buildStart)
    if($buildStart -lt 0 -or $buildEnd -lt 0){throw 'Actual source build boundary missing.'}
    $build=[scriptblock]::Create($source.Substring($buildStart,$buildEnd-$buildStart).Replace('& (Join-Path $InstallRoot ''build-native-from-source.ps1'')','Invoke-MsysBuildFixture'))
    $script:buildCalls=0
    function Invoke-MsysBuildFixture { $script:buildCalls++ }
    $InstallRoot=$owned; $NativeBuildRoot=$owned; $externalWheels=$owned; $openblasArchive=$MsysBaseArchivePath; $CudaRoot=$null; $InstallNvidiaGpu=$false; $python=$null; $git=$null; $uv=$null
    $boundReceiptHash=$MsysPackageReceiptSha256; $MsysPackageReceiptSha256=$null
    $rejected=$false
    try { & $build } catch { $rejected=$true }
    if(!$rejected -or $script:buildCalls){throw 'Actual build entrypoint bypassed missing receipt binding.'}
    $MsysPackageReceiptSha256=$boundReceiptHash
    & $build
    if($script:buildCalls -ne 1){throw 'Actual qualified build entrypoint did not run once.'}
    'PASS actual build entrypoint independently rechecks bound inputs'
    $parentAcl=Get-Acl -LiteralPath $owned
    $unprotectedParent=Get-Acl -LiteralPath $owned
    $unprotectedParent.SetAccessRuleProtection($false,$true)
    (Get-Item -LiteralPath $owned).SetAccessControl($unprotectedParent)
    if(!(Get-Acl -LiteralPath $receiptDirectory).AreAccessRulesProtected){throw 'Receipt anchor must remain protected for the extraction-parent failure control.'}
    Assert-GuardRejected 'unprotected extraction parent'
    $parentAcl.SetAccessRuleProtection($true,$false)
    (Get-Item -LiteralPath $owned).SetAccessControl($parentAcl)
    $qualifiedRootAcl=Get-Acl -LiteralPath $msysRoot
    $foreignRootAcl=Get-Acl -LiteralPath $msysRoot
    $foreignRootAcl.AddAccessRule([Security.AccessControl.FileSystemAccessRule]::new([Security.Principal.SecurityIdentifier]::new('S-1-1-0'),'Write','Allow'))
    (Get-Item -LiteralPath $msysRoot).SetAccessControl($foreignRootAcl)
    Assert-GuardRejected 'foreign writer on inherited root'
    $qualifiedRootAcl.SetAccessRuleProtection($false,$true)
    (Get-Item -LiteralPath $msysRoot).SetAccessControl($qualifiedRootAcl)
    [IO.File]::WriteAllText((Join-Path $msysPrivateHome '.bashrc'),'tampered HOME')
    Assert-GuardRejected 'tampered private HOME'
    [IO.File]::WriteAllText((Join-Path $msysPrivateHome '.bashrc'),'trusted HOME')
    [IO.File]::WriteAllText((Join-Path $msysRoot 'ucrt64/bin/dependency.dll'),'changed dependency')
    Assert-GuardRejected 'changed UCRT64 startup dependency'
    [IO.File]::WriteAllText((Join-Path $msysRoot 'ucrt64/bin/dependency.dll'),'trusted fixture')
    $receipt.post_install_code_files=@($code)+@($code[0]); Write-FixtureReceipt
    Assert-GuardRejected 'duplicate receipt code rows'
    $receipt.post_install_code_files=$code; Write-FixtureReceipt
    [IO.File]::WriteAllText((Join-Path $msysRoot 'usr/bin/extra.dll'),'unreceipted')
    Assert-GuardRejected 'extra independently enumerated code'
    Remove-Item -LiteralPath (Join-Path $msysRoot 'usr/bin/extra.dll')
    $script:elevated=$true; $script:pythonCalls=0
    Assert-GuardRejected 'elevated token'
    if($script:pythonCalls){throw 'Elevated guard ran Python.'}; $script:elevated=$false
    $receipt.packages[0]='diffutils wrong'; Write-FixtureReceipt
    Assert-GuardRejected 'wrong installed package version'
    $receipt.packages=@($base.packages|ForEach-Object {$_.identity+' '+$_.version}); Write-FixtureReceipt
    $receipt.schema_version='1'; Write-FixtureReceipt
    Assert-GuardRejected 'malformed receipt schema'
    $receipt.schema_version=1; Write-FixtureReceipt
    $boundManifestHash=$SecureAcquisitionManifestSha256
    $SecureAcquisitionManifestSha256='b'*64
    Assert-GuardRejected 'changed manifest binding'
    $SecureAcquisitionManifestSha256=$boundManifestHash
    [IO.File]::WriteAllText($MsysBaseArchivePath,'corrupt authenticated TAR')
    Assert-GuardRejected 'changed archive bytes'
    [IO.File]::WriteAllText($MsysBaseArchivePath,'authenticated TAR fixture')
    [IO.File]::WriteAllText((Join-Path $msysPrivateHome '.other-startup'),'extra')
    Assert-GuardRejected 'extra private HOME file'
    Remove-Item -LiteralPath (Join-Path $msysPrivateHome '.other-startup')
    $env:BASH_ENV='injected'; $env:HOME='injected'; $env:BASH_FUNC_fixture='injected'
    $env:GIT_CONFIG_COUNT='7'; $env:GIT_CONFIG_KEY_0='injected'; $env:GIT_CONFIG_VALUE_0='injected'
    $callerPath=$env:PATH
    foreach($throwAction in @($false,$true)) {
        $failed=$false
        try {
            Invoke-AutoClipMsysSource {
                if($env:BASH_ENV -or $env:BASH_FUNC_fixture -or $env:HOME -eq 'injected' -or $env:PATH -eq $callerPath){throw 'Injected environment survived.'}
                if($env:GIT_CONFIG_COUNT -ne '1' -or $env:GIT_CONFIG_KEY_0 -ne 'core.longpaths' -or $env:GIT_CONFIG_VALUE_0 -ne 'true'){throw 'Fixed Git longpaths process configuration missing.'}
                $blocked=$false
                try {[IO.File]::WriteAllText((Join-Path $msysRoot 'etc/profile'),'write race')}catch{$blocked=$true}
                if(!$blocked){throw 'Code lock allowed mutation.'}
                $blocked=$false
                try {[IO.File]::WriteAllText($MsysPackageReceiptPath,'write race')}catch{$blocked=$true}
                if(!$blocked){throw 'Receipt lock allowed mutation.'}
                $env:BASH_FUNC_added='added'
                if($throwAction){throw 'expected action failure'}
            } @()
        } catch { if(!$throwAction -or $_.Exception.Message -ne 'expected action failure'){throw}; $failed=$true }
        if($failed -ne $throwAction -or $env:PATH -ne $callerPath -or $env:BASH_ENV -ne 'injected' -or $env:HOME -ne 'injected' -or $env:BASH_FUNC_fixture -ne 'injected' -or $env:BASH_FUNC_added -or $env:GIT_CONFIG_COUNT -ne '7' -or $env:GIT_CONFIG_KEY_0 -ne 'injected' -or $env:GIT_CONFIG_VALUE_0 -ne 'injected'){throw 'Caller environment was not restored.'}
    }
    'PASS injected environment cleared, file writes blocked and environment restored after success/failure'
    Remove-Item Env:BASH_ENV,Env:HOME,Env:BASH_FUNC_fixture
} finally {
    $env:PATH=$originalPath; $env:MSYSTEM=$originalMsystem; $env:MSYS2_PATH_TYPE=$originalPathType
    if(!$fixture.StartsWith([IO.Path]::GetFullPath($env:TEMP).TrimEnd('\')+'\',[StringComparison]::OrdinalIgnoreCase)){throw 'Unsafe fixture cleanup.'}
    Remove-Item -LiteralPath $fixture -Recurse -Force
}
