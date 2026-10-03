param([string]$RealPackageDirectory, [string]$RealBaseArchive, [string]$ShortFixtureParent)
$ErrorActionPreference = 'Stop'
$helper = Join-Path (Split-Path -Parent $PSScriptRoot) 'installer/install-msys2-packages.ps1'
if (-not (Test-Path -LiteralPath $helper)) { throw 'Pinned MSYS2 input validation and offline transaction planning are missing.' }
$fixtureParent = if ($ShortFixtureParent) { [IO.Path]::GetFullPath($ShortFixtureParent).TrimEnd('\') } else { $env:TEMP }
$root = Join-Path $fixtureParent ('am-' + [guid]::NewGuid().ToString('N').Substring(0,6))
New-Item -ItemType Directory -Path $root | Out-Null
function Assert-Rejected([scriptblock]$Action, [string]$Reason) {
    try { & $Action | Out-Null } catch {
        if ($_.Exception.Message -notmatch $Reason) { throw }
        return
    }
    throw "Expected rejection: $Reason"
}
try {
    $base = Join-Path $root 'msys2-base-x86_64-20260611.tar.xz'
    $packages = Join-Path $root 'packages'
    New-Item -ItemType Directory -Path $packages | Out-Null
    [IO.File]::WriteAllText($base, 'base fixture')
    $rows = @(
        @('diffutils', '3.12-1', 'x86_64'), @('make', '4.4.1-3', 'x86_64'),
        @('mingw-w64-ucrt-x86_64-nasm', '3.02-1', 'any'),
        @('mingw-w64-ucrt-x86_64-zlib', '1.3.2-2', 'any'), @('pkgconf', '3.0.7-1', 'x86_64')
    )
    if ($RealBaseArchive) { $base = $RealBaseArchive }
    if ($RealPackageDirectory) { $packages = $RealPackageDirectory }
    function File-Pin([string]$Path) {
        @{ filename = [IO.Path]::GetFileName($Path); bytes = (Get-Item -LiteralPath $Path).Length;
           sha256 = (Get-FileHash -LiteralPath $Path).Hash.ToLowerInvariant(); delivery_classification = 'DIRECT_RECIPIENT_DOWNLOAD' }
    }
    $entries = @($rows | ForEach-Object {
        $name, $version, $arch = $_
        $filename = "$name-$version-$arch.pkg.tar.zst"
        $path = Join-Path $packages $filename
        if (-not $RealPackageDirectory) {
            [IO.File]::WriteAllText($path, $filename)
            [IO.File]::WriteAllText($path + '.sig', 'signature fixture')
        }
        $entry = File-Pin $path
        $entry.identity = $name; $entry.version = $version
        $entry.signature = File-Pin ($path + '.sig')
        $entry
    })
    $msys = File-Pin $base
    $msys.identity = 'MSYS2'; $msys.version = '20260611'; $msys.packages = $entries
    $msys.artifact_kind = 'archive'; $msys.archive_format = 'tar.xz'
    $manifest = Join-Path $root 'manifest.json'
    function Save-Manifest { @{schema_version = 1; build_prerequisites = @($msys)} | ConvertTo-Json -Depth 8 | Set-Content -LiteralPath $manifest -Encoding UTF8 }
    function Plan { & $helper -BaseArchivePath $base -PackageDirectory $packages -ManifestPath $manifest -MsysRoot 'C:\AutoClipMSYS2' }
    Save-Manifest
    $beforePlan = @(Get-ChildItem -LiteralPath $root -File -Recurse | ForEach-Object { $_.FullName + ':' + (Get-FileHash -LiteralPath $_.FullName).Hash })
    $plan = Plan
    $afterPlan = @(Get-ChildItem -LiteralPath $root -File -Recurse | ForEach-Object { $_.FullName + ':' + (Get-FileHash -LiteralPath $_.FullName).Hash })
    if (@(Compare-Object $beforePlan $afterPlan).Count) { throw 'Default TAR planning must not mutate any file.' }
    if ($plan.execution_allowed -ne $false -or $plan.blocker -notmatch 'keyring provenance') { throw 'Unproved keyring must block execution.' }
    if ($plan.config -notmatch 'LocalFileSigLevel = Required TrustedOnly' -or $plan.config -match '(?m)^\[(?!options\])|Include|Server|TrustAll|Optional|Never') { throw 'Plan must require trusted signatures and have no sync repositories.' }
    if ($plan.install_arguments[0] -ne '-U' -or $plan.install_arguments -contains '--nodeps' -or $plan.install_arguments -contains '--dbonly' -or $plan.install_arguments.Count -ne 9) { throw 'Only fixed local package arguments allowed.' }
    if ($plan.expected_transaction.Count -ne 5 -or $plan.capability_checks.Count -ne 4) { throw 'Exact package and capability closure missing.' }
    $msys.filename = 'msys2-x86_64-20260611.exe'; Save-Manifest
    Assert-Rejected { Plan } 'identity'
    $msys.filename = 'msys2-base-x86_64-20260611.tar.xz'
    $msys.artifact_kind = 'installer'; Save-Manifest
    Assert-Rejected { Plan } 'identity'
    $msys.artifact_kind = 'archive'
    $msys.archive_format = 'zip'; Save-Manifest
    Assert-Rejected { Plan } 'identity'
    $msys.archive_format = 'tar.xz'
    $msys.delivery_classification = 'BLOCKED'; Save-Manifest
    Assert-Rejected { Plan } 'DIRECT_RECIPIENT_DOWNLOAD'
    $msys.delivery_classification = 'DIRECT_RECIPIENT_DOWNLOAD'
    $baseBytes = $msys.bytes; $msys.bytes = $baseBytes + 1; Save-Manifest
    Assert-Rejected { Plan } 'size or SHA-256'
    $msys.bytes = $baseBytes
    $entries[0].delivery_classification = 'BLOCKED'; Save-Manifest
    Assert-Rejected { Plan } 'DIRECT_RECIPIENT_DOWNLOAD'
    $entries[0].delivery_classification = 'DIRECT_RECIPIENT_DOWNLOAD'
    $entries[0].signature.delivery_classification = 'BLOCKED'; Save-Manifest
    Assert-Rejected { Plan } 'DIRECT_RECIPIENT_DOWNLOAD'
    $entries[0].signature.delivery_classification = 'DIRECT_RECIPIENT_DOWNLOAD'
    $entries[0].signature.sha256 = '0' * 64; Save-Manifest
    Assert-Rejected { Plan } 'SHA-256'
    $entries[0].signature = File-Pin (Join-Path $packages ($entries[0].filename + '.sig'))
    $entries[0].sha256 = '0' * 64; Save-Manifest
    Assert-Rejected { Plan } 'SHA-256'
    $entries[0].sha256 = (Get-FileHash (Join-Path $packages $entries[0].filename)).Hash
    $entries[0].version = '3.12-2'; Save-Manifest
    Assert-Rejected { Plan } 'identity'
    $entries[0].version = '3.12-1'
    $msys.packages = @($entries) + @($entries[0]); Save-Manifest
    Assert-Rejected { Plan } 'exact five'
    $msys.packages = $entries; $entries[0].filename = '../escape.pkg.tar.zst'; Save-Manifest
    Assert-Rejected { Plan } 'identity'
    $entries[0].filename = 'diffutils-3.12-1-x86_64.pkg.tar.zst'; Save-Manifest
    # Exercise the real transaction-set validator without invoking pacman.
    $tokens = $null; $errors = $null
    $ast = [Management.Automation.Language.Parser]::ParseFile($helper, [ref]$tokens, [ref]$errors)
    if ($errors.Count) { throw $errors[0] }
    $functionAst = $ast.Find({param($node) $node -is [Management.Automation.Language.FunctionDefinitionAst] -and $node.Name -eq 'Assert-Msys2Transaction'}, $true)
    if (-not $functionAst) { throw 'Transaction validator missing.' }
    . ([scriptblock]::Create($functionAst.Extent.Text))
    Assert-Msys2Transaction -Actual $plan.expected_transaction -Expected $plan.expected_transaction
    Assert-Rejected { Assert-Msys2Transaction -Actual (@($plan.expected_transaction) + 'unapproved 1-1') -Expected $plan.expected_transaction } 'outside'
    Assert-Rejected { Assert-Msys2Transaction -Actual $plan.expected_transaction[0..3] -Expected $plan.expected_transaction } 'outside'
    Assert-Rejected { Assert-Msys2Transaction -Actual @($plan.expected_transaction[0], $plan.expected_transaction[0], $plan.expected_transaction[2], $plan.expected_transaction[3], $plan.expected_transaction[4]) -Expected $plan.expected_transaction } 'outside'
    Assert-Rejected { & $helper -BaseArchivePath $base -PackageDirectory $packages -ManifestPath $manifest -MsysRoot 'C:\unsafe path' } 'ASCII'
    if ($RealBaseArchive) {
        if (-not $RealBaseArchive -or -not $RealPackageDirectory) { throw 'Execution fixtures require both real archive/package paths.' }
        $fixtureRoot = $root
        $fixturePackages = Join-Path $root 'execute-packages'
        New-Item -ItemType Directory -Path $fixturePackages | Out-Null
        foreach ($entry in $entries) {
            Copy-Item -LiteralPath (Join-Path $packages $entry.filename) -Destination $fixturePackages
            Copy-Item -LiteralPath (Join-Path $packages $entry.signature.filename) -Destination $fixturePackages
        }
        $packages = $fixturePackages
        $env:AUTOCLIP_MSYS_TEST_ARCHIVE = $RealBaseArchive
        $env:AUTOCLIP_MSYS_TEST_ROOT = $fixtureRoot
        $extractCode = @'
import os, pathlib, tarfile, json, hashlib
root=pathlib.Path(os.environ['AUTOCLIP_MSYS_TEST_ROOT'])
paths=['usr/share/pacman/keyrings/msys2.gpg','usr/share/pacman/keyrings/msys2-trusted','usr/share/pacman/keyrings/msys2-revoked','usr/bin/bash.exe','usr/bin/pacman.exe','usr/bin/gpg.exe','usr/bin/gpgv.exe','usr/bin/pacman-conf.exe','usr/bin/pacman-key','etc/profile','etc/post-install/07-pacman-key.post','var/lib/pacman/local/msys2-keyring-1~20260214-1/desc']
rows=[]; code=[]
with tarfile.open(os.environ['AUTOCLIP_MSYS_TEST_ARCHIVE']) as tf:
 for member in tf:
  path=member.name.removeprefix('msys64/')
  is_code=member.isfile() and (path.startswith(('usr/bin/','etc/profile.d/','etc/post-install/','etc/msystem.d/')) or path in ('etc/profile','etc/msystem','etc/bash.bashrc','msys2_shell.cmd'))
  if path not in paths and not is_code: continue
  if not member.isfile(): raise ValueError(path)
  data=tf.extractfile(member).read()
  target=root/path
  target.parent.mkdir(parents=True,exist_ok=True)
  target.write_bytes(data)
  record=dict(path=path,bytes=len(data),sha256=hashlib.sha256(data).hexdigest())
  if path in paths: rows.append(record)
  if is_code: code.append(record)
print(json.dumps(dict(installed_files=rows,code_files=code)))
'@
        $fixture = $extractCode | python - | Out-String | ConvertFrom-Json
        if ($LASTEXITCODE -ne 0) { throw 'Exact base fixture extraction failed.' }
        $msys.installed_files = @($fixture.installed_files | ForEach-Object { $_ })
        Save-Manifest
        $diskPin = Get-Content -LiteralPath $manifest -Raw | ConvertFrom-Json
        if (@($diskPin.build_prerequisites[0].installed_files).Count -ne 12) { throw "Exact fixture provenance missing: $(@($msys.installed_files).Count) records." }
        # Mock only native execution and platform ACL/elevation queries; guard decisions stay real.
        $source = Get-Content -LiteralPath $helper -Raw
        $nativeAst = $ast.Find({param($node) $node -is [Management.Automation.Language.FunctionDefinitionAst] -and $node.Name -eq 'Invoke-PinnedMsys2'}, $true)
        if ($nativeAst) {
            . ([scriptblock]::Create($nativeAst.Extent.Text))
            Assert-Rejected { Invoke-PinnedMsys2 $env:COMSPEC @('/d','/c','exit','13') } 'native exit 13'
        }
        $queryAst = $ast.Find({param($node) $node -is [Management.Automation.Language.FunctionDefinitionAst] -and $node.Name -eq 'Get-Msys2Elevation'}, $true)
        foreach ($boundary in @($nativeAst, $queryAst) | Sort-Object { $_.Extent.StartOffset } -Descending) {
            $source = $source.Remove($boundary.Extent.StartOffset, $boundary.Extent.EndOffset - $boundary.Extent.StartOffset)
        }
        $execution = [scriptblock]::Create($source)
        $state = @{ calls = @(); installed = $false; fault = ''; queries = 0; elevated = $false; aclFault = ''; postAclQueries = @(); ucrtAclFault = $false }
        function Get-Msys2Elevation { $state.elevated }
        $safeAcl = New-Object Security.AccessControl.DirectorySecurity
        $recipientSid = [Security.Principal.WindowsIdentity]::GetCurrent().User
        $safeAcl.SetOwner($recipientSid)
        $safeAcl.SetAccessRuleProtection($true, $false)
        $safeAcl.AddAccessRule((New-Object Security.AccessControl.FileSystemAccessRule($recipientSid, 'FullControl', 'Allow')))
        function Get-Acl([string]$LiteralPath) {
            if ($state.installed) { $state.postAclQueries += $LiteralPath }
            $aclFault = $state.aclFault
            if ($state.ucrtAclFault -and $LiteralPath.EndsWith('\ucrt64\bin\zlib1.dll')) { $aclFault = 'writer' }
            if (-not $aclFault) { return $safeAcl }
            $acl = New-Object Security.AccessControl.DirectorySecurity
            $acl.SetOwner($recipientSid)
            $acl.SetAccessRuleProtection(($aclFault -ne 'unprotected'), $false)
            if ($aclFault -eq 'owner') { $acl.SetOwner((New-Object Security.Principal.SecurityIdentifier('S-1-1-0'))) }
            if ($aclFault -eq 'writer') {
                $acl.AddAccessRule((New-Object Security.AccessControl.FileSystemAccessRule((New-Object Security.Principal.SecurityIdentifier('S-1-1-0')), 'Modify', 'Allow')))
            }
            if ($aclFault -eq 'generic-writer') {
                $acl.SetSecurityDescriptorSddlForm('O:' + $recipientSid.Value + 'D:P(A;;GW;;;WD)')
            }
            if ($aclFault -eq 'inherit-writer') {
                $acl.SetSecurityDescriptorSddlForm('O:' + $recipientSid.Value + 'D:P(A;OICIIO;GW;;;WD)')
            }
            $acl
        }
        $receiptPath = Join-Path $root 'base-receipt.json'
        $privateHome = Join-Path $fixtureRoot 'home/autoclip-base'
        New-Item -ItemType Directory -Path $privateHome -Force | Out-Null
        $receipt = @{ schema_version = 1; status = 'VERIFIED_PINNED_BASE'; root = $fixtureRoot;
            archive_sha256 = $msys.sha256; archive_bytes = $msys.bytes; signature_verified = $true;
            signer_fingerprint = '0EBF782C5D53F7E5FB02A66746BD761F7A49B0EC'; init_verified = $true;
            first_login_verified = $true; protected_root_verified = $true;
            extraction_inventory = @{ receipt_sha256 = 'a' * 64; file_count = 15529; directory_count = 1052 };
            code_files = @($fixture.code_files | ForEach-Object { $_ }); private_home = $privateHome }
        function Save-Receipt {
            param([switch]$PreserveManifestHash)
            if (-not $PreserveManifestHash) { $receipt.manifest_sha256 = (Get-FileHash -LiteralPath $manifest).Hash.ToLowerInvariant() }
            $receipt | ConvertTo-Json -Depth 8 | Set-Content -LiteralPath $receiptPath -Encoding UTF8
            $script:receiptHash = (Get-FileHash -LiteralPath $receiptPath).Hash.ToLowerInvariant()
        }
        $ambientNames = @('PATH','BASH_ENV','ENV','GNUPGHOME','HOME','MSYSTEM','MSYS2_PATH_TYPE','SYSCONFDIR','CHERE_INVOKING','SHELLOPTS','BASHOPTS','CDPATH','GLOBIGNORE','PS1','XDG_CONFIG_HOME','ORIGINAL_PATH','CYG_SYS_BASHRC','MSYS2_PS1','MSYS2_ARG_CONV_EXCL','MSYS2_ENV_CONV_EXCL','MSYS_NO_PATHCONV','BASH_FUNC_autoclip_attack%%')
        $ambientSaved = @{}; $ambientValues = @{}
        foreach ($name in $ambientNames) {
            $ambientSaved[$name] = [Environment]::GetEnvironmentVariable($name, 'Process')
            $ambientValues[$name] = 'ambient-' + $name
            [Environment]::SetEnvironmentVariable($name, $ambientValues[$name], 'Process')
        }
        function Assert-AmbientRestored {
            foreach ($name in $ambientNames) {
                if ([Environment]::GetEnvironmentVariable($name, 'Process') -cne $ambientValues[$name]) { throw "Caller environment not restored: $name" }
            }
        }
        function Invoke-PinnedMsys2([string]$Executable, [string[]]$Arguments) {
            $state.calls += @{ executable = $Executable; arguments = @($Arguments) }
            if ($Arguments -contains '--refresh-keys' -or $Arguments -contains '-l' -or $Arguments -contains '--login') { throw 'Network or login shell forbidden.' }
            if ($Executable.EndsWith('bash.exe')) {
                $expectedHome = '/' + $privateHome.Substring(0,1).ToLowerInvariant() + $privateHome.Substring(2).Replace('\','/')
                if ($env:HOME -cne $expectedHome -or $env:MSYS2_PATH_TYPE -cne 'strict' -or $env:CHERE_INVOKING -cne '1' -or
                    $env:MSYSTEM -cne 'MSYS' -or $env:PATH -cne "$fixtureRoot\usr\bin;$fixtureRoot\ucrt64\bin;$env:SystemRoot\System32" -or
                    $env:GNUPGHOME -notmatch '/etc/pacman.d/ac-[0-9a-f]{32}$') { throw 'Ambient startup environment reached native execution.' }
                foreach ($name in $ambientNames | Where-Object { $_ -notin @('PATH','HOME','GNUPGHOME','MSYSTEM','MSYS2_PATH_TYPE','CHERE_INVOKING') }) {
                    if ([Environment]::GetEnvironmentVariable($name, 'Process')) { throw "Ambient startup hook reached native execution: $name" }
                }
                if (($Arguments -join ' ') -match 'refresh|recv-keys|import-ownertrust|TrustAll') { throw 'Unpinned trust operation.' }
                if ($Arguments[0] -ne '--noprofile' -or $Arguments[1] -ne '--norc' -or ($Arguments -join ' ') -notmatch '--gpgdir') { throw 'Isolated non-login initialization required.' }
                if ($state.fault -eq 'init') { throw 'Native exit 7' }
                return
            }
            if ($Executable.EndsWith('gpg.exe')) {
                if ($state.fault -eq 'untrusted') { return '[GNUPG:] VALIDSIG 5F944B027F7FE2091985AA2EFA11531AA0AA7F57' }
                if ($state.fault -eq 'wrongkey') { return @('[GNUPG:] VALIDSIG 0000000000000000000000000000000000000000', '[GNUPG:] TRUST_FULLY 0 pgp') }
                return @('[GNUPG:] VALIDSIG 5F944B027F7FE2091985AA2EFA11531AA0AA7F57', '[GNUPG:] TRUST_FULLY 0 pgp')
            }
            if ($Executable.EndsWith('pacman.exe')) {
                if ($Arguments -contains '--print') {
                    if ($state.fault -eq 'extra') { return @($plan.expected_transaction) + 'unapproved 1-1' }
                    if ($state.fault -eq 'mutate') { [IO.File]::AppendAllText((Join-Path $fixtureRoot 'usr/share/pacman/keyrings/msys2-trusted'), 'changed') }
                    if ($state.fault -eq 'signature-mutate') { [IO.File]::AppendAllText((Join-Path $packages $entries[0].signature.filename), 'changed') }
                    if ($state.fault -eq 'receipt-mutate') { [IO.File]::AppendAllText($receiptPath, 'changed') }
                    if ($state.fault -eq 'dll-mutate') { [IO.File]::AppendAllText($dllPath, 'changed') }
                    return $plan.expected_transaction
                }
                if ($Arguments -contains '-U') {
                    $state.installed = $true
                    $ucrtBin = Join-Path $fixtureRoot 'ucrt64/bin'
                    New-Item -ItemType Directory -Path $ucrtBin -Force | Out-Null
                    [IO.File]::WriteAllText((Join-Path $ucrtBin 'nasm.exe'), 'trusted NASM transaction fixture bytes')
                    [IO.File]::WriteAllText((Join-Path $ucrtBin 'zlib1.dll'), 'trusted zlib transaction fixture bytes')
                    if ($state.fault -eq 'post-add') { [IO.File]::WriteAllText((Join-Path $fixtureRoot 'usr/bin/package-added.dll'), 'trusted transaction fixture bytes') }
                    if ($state.fault -eq 'post-acl') { $state.aclFault = 'writer' }
                    if ($state.fault -eq 'ucrt-acl') { $state.ucrtAclFault = $true }
                    return
                }
                if ($Arguments -contains '-Q') {
                    $state.queries++
                    if ($Arguments -contains 'diffutils') {
                        if ($state.fault -eq 'version') { return @($plan.expected_transaction[0..3]) + 'pkgconf 0-1' }
                        return $plan.expected_transaction
                    }
                    if ($state.installed -and $state.fault -eq 'unrelated') { return @($plan.expected_transaction) + 'msys2-keyring 1~20260214-1' + 'bash changed-1' }
                    return @($plan.expected_transaction) + 'msys2-keyring 1~20260214-1' + 'bash 5.3.9-1'
                }
            }
            if ($state.fault -eq 'capability') { return 'wrong capability' }
            if ($state.fault -eq 'nasm' -and $Executable.EndsWith('nasm.exe')) { return 'NASM version 3.02.1' }
            switch ([IO.Path]::GetFileName($Executable)) {
                'make.exe' { 'GNU Make 4.4.1' }
                'diff.exe' { 'diff (GNU diffutils) 3.12' }
                'pkg-config.exe' { '3.0.7' }
                'nasm.exe' { 'NASM version 3.02' }
                default { throw "Unexpected native call: $Executable" }
            }
        }
        function Execute-Fixture { & $execution -BaseArchivePath $base -PackageDirectory $packages -ManifestPath $manifest -MsysRoot $fixtureRoot -BaseReceiptPath $receiptPath -BaseReceiptSha256 $script:receiptHash -InstallPinnedPackages }
        $pins = $msys.installed_files
        $msys.installed_files = @($pins[0..10]); Save-Manifest
        Assert-Rejected { Execute-Fixture } 'provenance'
        if ($state.calls.Count) { throw 'Missing provenance must prevent every native call.' }
        $msys.installed_files = $pins
        $firstHash = $pins[0].sha256; $pins[0].sha256 = '0' * 64; Save-Manifest
        Assert-Rejected { Execute-Fixture } 'provenance'
        if ($state.calls.Count) { throw 'Altered provenance must prevent every native call.' }
        $pins[0].sha256 = $firstHash; Save-Manifest
        Save-Receipt
        $expandedClosure = $receipt.code_files
        $receipt.code_files = @($expandedClosure | Where-Object { $_.path -notin @('etc/msystem','etc/bash.bashrc') -and $_.path -notlike 'etc/msystem.d/*' })
        Save-Receipt
        Assert-Rejected { Execute-Fixture } 'code closure'
        if ($state.calls.Count) { throw 'Omitted sourced startup files must prevent every native call.' }
        $receipt.code_files = $expandedClosure; Save-Receipt
        $state.elevated = $true
        $ownedBefore = @(Get-ChildItem -LiteralPath (Join-Path $root 'etc') -Recurse -Force).Count
        Assert-Rejected { Execute-Fixture } 'elevated'
        if ($state.calls.Count -or @(Get-ChildItem -LiteralPath (Join-Path $root 'etc') -Recurse -Force).Count -ne $ownedBefore) { throw 'Elevated execution must prevent mutation/native calls.' }
        $state.elevated = $false
        foreach ($fault in @('unprotected','owner','writer','generic-writer','inherit-writer','empty')) {
            $state.aclFault = $fault
            Assert-Rejected { Execute-Fixture } 'DACL|untrusted write'
            if ($state.calls.Count) { throw 'Unsafe ACL must prevent native calls.' }
        }
        $state.aclFault = ''
        foreach ($field in @('status','root','manifest_sha256','archive_sha256','signer_fingerprint','signature_verified','init_verified','first_login_verified','protected_root_verified','private_home')) {
            $old = $receipt[$field]
            $receipt[$field] = if ($old -is [bool]) { $false } else { 'wrong' }
            Save-Receipt -PreserveManifestHash
            Assert-Rejected { Execute-Fixture } 'receipt'
            if ($state.calls.Count) { throw 'Unqualified base receipt must prevent native calls.' }
            $receipt[$field] = $old
        }
        Save-Receipt
        $receipt.signature_verified = 'true'; Save-Receipt
        Assert-Rejected { Execute-Fixture } 'qualification'
        $receipt.signature_verified = $true; Save-Receipt
        $validReceiptHash = $script:receiptHash; $script:receiptHash = '0' * 64
        Assert-Rejected { Execute-Fixture } 'receipt SHA-256'
        $script:receiptHash = $validReceiptHash
        [IO.File]::AppendAllText($receiptPath, 'changed')
        Assert-Rejected { Execute-Fixture } 'receipt SHA-256'
        Save-Receipt
        $closure = $receipt.code_files
        $receipt.code_files = @($closure | Select-Object -Skip 1); Save-Receipt
        Assert-Rejected { Execute-Fixture } 'code closure'
        $receipt.code_files = $closure; Save-Receipt
        foreach ($startup in @('etc/msystem','etc/bash.bashrc','etc/msystem.d/MSYS')) {
            $startupPath = Join-Path $fixtureRoot $startup
            $startupBytes = [IO.File]::ReadAllBytes($startupPath)
            [IO.File]::AppendAllText($startupPath, 'changed')
            Assert-Rejected { Execute-Fixture } 'SHA-256'
            if ($state.calls.Count) { throw 'Changed sourced startup file must prevent every native call.' }
            [IO.File]::WriteAllBytes($startupPath, $startupBytes)
        }
        $receipt.code_files = @($closure) + @($closure[0]); Save-Receipt
        Assert-Rejected { Execute-Fixture } 'code closure'
        $receipt.code_files = $closure; Save-Receipt
        $dll = @($closure | Where-Object path -Like '*.dll')[0]
        $dllPath = Join-Path $fixtureRoot $dll.path
        $dllBytes = [IO.File]::ReadAllBytes($dllPath)
        [IO.File]::AppendAllText($dllPath, 'changed')
        Assert-Rejected { Execute-Fixture } 'SHA-256'
        [IO.File]::WriteAllBytes($dllPath, $dllBytes)
        $injected = Join-Path $fixtureRoot 'usr/bin/injected.dll'
        [IO.File]::WriteAllText($injected, 'unexpected')
        Assert-Rejected { Execute-Fixture } 'code closure'
        Remove-Item -LiteralPath $injected
        $junction = Join-Path $fixtureRoot 'usr/bin/foreign-link'
        & $env:COMSPEC /d /c mklink /J $junction $packages | Out-Null
        if ($LASTEXITCODE) { throw 'Fixture junction creation failed.' }
        try { Assert-Rejected { Execute-Fixture } 'reparse' } finally { [IO.Directory]::Delete($junction) }
        if ($state.calls.Count) { throw 'Invalid receipt/code must prevent every native call.' }
        $result = Execute-Fixture
        Assert-AmbientRestored
        if (-not $state.installed -or $result.status -ne 'VERIFIED_PINNED_PACKAGES' -or $state.calls.Count -lt 15) { throw 'Explicit install must verify trusted packages, exact transaction, versions and capabilities.' }
        foreach ($relative in @('ucrt64/bin/nasm.exe','ucrt64/bin/zlib1.dll')) {
            if (@($result.post_install_code_files | Where-Object path -CEQ $relative).Count -ne 1) { throw 'Post-install snapshot must include UCRT64 NASM and zlib DLL code.' }
        }
        if ($result.schema_version -ne 1 -or $result.manifest_sha256 -cne (Get-FileHash -LiteralPath $manifest).Hash.ToLowerInvariant() -or
            $result.base_receipt_sha256 -cne $script:receiptHash -or $result.private_home -cne $privateHome -or
            @($result.post_install_code_files).Count -ne $expandedClosure.Count + 2) { throw 'Qualified package receipt must bind schema, lowercase hashes, private HOME and the complete post-install code snapshot.' }
        foreach ($record in $result.post_install_code_files) {
            $path = Join-Path $fixtureRoot $record.path
            if ($record.bytes -ne (Get-Item -LiteralPath $path).Length -or $record.sha256 -cne (Get-FileHash -LiteralPath $path).Hash.ToLowerInvariant()) { throw 'Package snapshot must record actual post-transaction bytes.' }
            if ($state.postAclQueries -cnotcontains $path) { throw 'Every post-install code file must have its ACL checked.' }
        }
        $state.fault = 'post-add'; $state.installed = $false
        $addedResult = Execute-Fixture
        Assert-AmbientRestored
        $added = @($addedResult.post_install_code_files | Where-Object path -CEQ 'usr/bin/package-added.dll')
        if ($added.Count -ne 1 -or $added[0].sha256 -cne (Get-FileHash -LiteralPath (Join-Path $fixtureRoot $added[0].path)).Hash.ToLowerInvariant() -or
            @($addedResult.post_install_code_files).Count -ne $expandedClosure.Count + 3) { throw 'Package snapshot must include new trusted-transaction code instead of comparing it to the old base closure.' }
        Remove-Item -LiteralPath (Join-Path $fixtureRoot 'usr/bin/package-added.dll')
        $state.fault = 'post-acl'; $state.installed = $false
        Assert-Rejected { Execute-Fixture } 'untrusted write'
        Assert-AmbientRestored
        $state.aclFault = ''
        $state.fault = 'ucrt-acl'; $state.installed = $false
        Assert-Rejected { Execute-Fixture } 'untrusted write'
        Assert-AmbientRestored
        $state.ucrtAclFault = $false
        foreach ($fault in @('init','untrusted','wrongkey','extra','version','unrelated','capability','nasm')) {
            $state.fault = $fault; $state.installed = $false
            Assert-Rejected { Execute-Fixture } 'Native exit|trusted|outside|unrelated|capability'
            Assert-AmbientRestored
            if ($fault -in @('init','untrusted','wrongkey','extra') -and $state.installed) { throw 'Failure before verified transaction must prevent installation.' }
        }
        foreach ($fault in @('receipt-mutate','dll-mutate')) {
            $state.fault = $fault; $state.installed = $false
            Assert-Rejected { Execute-Fixture } 'receipt SHA-256|SHA-256'
            if ($state.installed) { throw 'Changed receipt/code after preview must prevent transaction.' }
            Save-Receipt
            [IO.File]::WriteAllBytes($dllPath, $dllBytes)
        }
        $sig = Join-Path $packages $entries[0].signature.filename
        $signatureBytes = [IO.File]::ReadAllBytes($sig)
        $state.fault = 'signature-mutate'; $state.installed = $false
        Assert-Rejected { Execute-Fixture } 'SHA-256'
        if ($state.installed) { throw 'Changed signature after preview must prevent installation.' }
        [IO.File]::WriteAllBytes($sig, $signatureBytes)
        $state.fault = 'mutate'; $state.installed = $false
        Assert-Rejected { Execute-Fixture } 'SHA-256'
        if ($state.installed) { throw 'Changed provenance after preview must prevent installation.' }
        'MSYS2 explicit execution branch PASS with mocked native processes and actual exact base/package files; no host installation or key initialization'
    }
    'MSYS2 pinned inputs, corruption/classification/set rejection, offline plan and keyring execution block PASS; no package installation performed'
} finally {
    if ($ambientSaved) { foreach ($name in $ambientSaved.Keys) { [Environment]::SetEnvironmentVariable($name, $ambientSaved[$name], 'Process') } }
    $resolved = [IO.Path]::GetFullPath($root)
    if ($resolved -cne [IO.Path]::GetFullPath((Join-Path $fixtureParent (Split-Path -Leaf $root))) -or
        (Split-Path -Leaf $resolved) -notmatch '^am-[0-9a-f]{6}$' -or
        ((Get-Item -LiteralPath $resolved).Attributes -band [IO.FileAttributes]::ReparsePoint)) { throw 'Unsafe fixture cleanup.' }
    Remove-Item -LiteralPath $resolved -Recurse -Force
}
