$ErrorActionPreference = 'Stop'
$repo = Split-Path -Parent $PSScriptRoot
$install = Join-Path $repo 'install.ps1'
$tokens = $null; $errors = $null
$ast = [Management.Automation.Language.Parser]::ParseFile($install, [ref]$tokens, [ref]$errors)
if ($errors) { throw 'Installer parse failed.' }
$root = Join-Path $env:TEMP ('autoclip-secure-acquisition-' + [guid]::NewGuid().ToString('N'))
[IO.Directory]::CreateDirectory($root) | Out-Null
$originalTemp = $env:TEMP
try {
    $msysProbeSetup = $ast.Find({ param($n) $n -is [Management.Automation.Language.AssignmentStatementAst] -and $n.Left.Extent.Text -eq '$msysProbeArguments' }, $true)
    $msysMissing = $ast.Find({ param($n) $n -is [Management.Automation.Language.AssignmentStatementAst] -and $n.Left.Extent.Text -eq '$missingMsysPackages' }, $true)
    $msysChecks = @($ast.FindAll({ param($n) $n -is [Management.Automation.Language.ForEachStatementAst] -and $n.Extent.Text.Contains('& $MsysBash') -and $n.Extent.Text.Contains('MSYS2 build') }, $true))
    if (-not $msysMissing -or $msysChecks.Count -ne 2) { throw 'MSYS2 prerequisite probe boundaries are missing.' }
    function Invoke-MsysProbeFixture {
        if ($NoPrerequisiteAcquisition) {
            if ($args -contains '-lc' -or $args -notcontains '--noprofile' -or $args -notcontains '--norc' -or $args -notcontains '-c') {
                throw 'Guarded MSYS2 detection must not load login profiles or trigger post-install key refresh.'
            }
        } elseif ($args -notcontains '-lc') { throw "Legacy MSYS2 detection arguments changed: $($args -join '|')" }
        $global:LASTEXITCODE = 0
    }
    $MsysBash = 'Invoke-MsysProbeFixture'
    $requiredMsysPackages = @('make', 'diffutils', 'pkgconf', 'mingw-w64-ucrt-x86_64-nasm')
    foreach ($guarded in @($true, $false)) {
        $NoPrerequisiteAcquisition = $guarded
        if ($msysProbeSetup) { Invoke-Expression $msysProbeSetup.Extent.Text }
        Invoke-Expression $msysMissing.Extent.Text
        foreach ($check in $msysChecks) { Invoke-Expression $check.Extent.Text }
    }
    foreach ($name in @('Assert-AutoClipSecurePath', 'Read-AutoClipSecureInput', 'Initialize-AutoClipSecureAcquisition', 'Invoke-AutoClipSecureDownload', 'Get-AutoClipSecureDownloadDefaults')) {
        $node = $ast.Find({ param($n) $n -is [Management.Automation.Language.FunctionDefinitionAst] -and $n.Name -eq $name }, $false)
        if (-not $node) { throw "RED: missing guarded acquisition function $name; unapproved URI cannot be rejected before download." }
        Invoke-Expression ($node.Extent.Text.Replace('$PSScriptRoot', ("'" + $root.Replace("'", "''") + "'")))
    }
    # Tests use the actual protected downloader with only its HTTP response boundary mocked.
    $helper = Join-Path $root 'download-artifact.ps1'
    $networkMarker = Join-Path $root 'network.txt'
    $httpFixture = @'
function Get-InstallerDownloadResponse {
    param($Client, [uri]$Uri, [string]$CancelPath)
    $transfer = [IO.Path]::GetFullPath($parameters.DestinationPath)
    if (-not $transfer.StartsWith([IO.Path]::GetFullPath($env:TEMP).TrimEnd('\') + '\autoclip-secure-', [StringComparison]::OrdinalIgnoreCase) -or
        -not (Test-Path -LiteralPath (Join-Path (Split-Path -Parent $transfer) 'manifest.json') -PathType Leaf)) {
        throw 'Protected acquisition must use private TEMP staging and a verified manifest snapshot.'
    }
    [IO.File]::AppendAllText('MARKER', $Uri.AbsoluteUri + "`n")
    $response = New-Object Net.Http.HttpResponseMessage ([Net.HttpStatusCode]::OK)
    $response.Content = New-Object Net.Http.ByteArrayContent (,[Text.Encoding]::UTF8.GetBytes('fixture'))
    return $response
}
'@
    [IO.File]::WriteAllText($helper, (Get-Content (Join-Path $repo 'installer/download-artifact.ps1') -Raw) + "`r`n" + $httpFixture.Replace('MARKER', $networkMarker.Replace("'", "''")))
    $helperHash = (Get-FileHash $helper).Hash
    $fixtureHash = 'f16d05ec6b29248d2c61adb1e9263f78e4f7bace1b955014a2d17872cfe4064d'
    $wheel = [ordered]@{ filename = 'fixture-1-py3-none-any.whl'; url = 'https://files.pythonhosted.org/fixture.whl'; bytes = 7; sha256 = $fixtureHash; delivery_policy = 'publisher'; package = 'fixture'; version = '1'; publisher_identity = 'fixture' }
    $publisherPath = Join-Path $root 'publisher-wheel-manifest.json'
    @{ schema_version = 1; wheels = @($wheel) } | ConvertTo-Json -Depth 5 | Set-Content $publisherPath -Encoding UTF8
    $sourcePin = [ordered]@{ identity = 'source fixture'; filename = 'source.tar.gz'; url = 'https://ffmpeg.org/source.tar.gz'; bytes = 7; sha256 = $fixtureHash; delivery_classification = 'DIRECT_RECIPIENT_DOWNLOAD'; redirect_hosts = @('ffmpeg.org') }
    $outer = [ordered]@{ schema_version = 1; external_assets = @(); build_prerequisites = @(); native_build_assets = @($sourcePin); publisher_wheels = @{ manifest_path = 'publisher-wheel-manifest.json'; count = 1; sha256 = (Get-FileHash $publisherPath).Hash; delivery_classification = 'DIRECT_RECIPIENT_DOWNLOAD'; redirect_hosts = @('files.pythonhosted.org') } }
    $outerPath = Join-Path $root 'installer-dependencies-v1.json'
    function Save-Outer { $outer | ConvertTo-Json -Depth 7 | Set-Content $outerPath -Encoding UTF8; $script:outerHash = (Get-FileHash $outerPath).Hash }
    function Initialize-Fixture { Initialize-AutoClipSecureAcquisition -ManifestPath $outerPath -ManifestSha256 $script:outerHash -DownloaderSha256 $helperHash -NoPrerequisiteAcquisition }
    Save-Outer
    $secureDownload = Initialize-Fixture
    $script:SecurePublisherManifestPath = $publisherPath
    function Assert-Rejected([scriptblock]$Action, [string]$Message) {
        $calls = if (Test-Path $networkMarker) { (Get-Content $networkMarker).Count } else { 0 }
        $rejected = $false
        try { & $Action | Out-Null } catch { $rejected = $true }
        if (-not $rejected) { throw "Guard failed: $Message" }
        $after = if (Test-Path $networkMarker) { (Get-Content $networkMarker).Count } else { 0 }
        if ($calls -ne $after) { throw "Rejected request reached network: $Message" }
    }
    Assert-Rejected { Invoke-AutoClipSecureDownload -Uri 'https://evil.example/fixture.whl' -Sha256 $fixtureHash -Size 7 -Destination (Join-Path $root 'bad') } 'unknown URI'
    Assert-Rejected { Invoke-AutoClipSecureDownload -Uri $wheel.url -Sha256 ('a' * 64) -Size 7 -Destination (Join-Path $root 'bad') } 'wrong hash'
    Assert-Rejected { Invoke-AutoClipSecureDownload -Uri $wheel.url -Sha256 $fixtureHash -Size 8 -Destination (Join-Path $root 'bad') } 'wrong size'
    Assert-Rejected { Initialize-AutoClipSecureAcquisition -ManifestPath $outerPath } 'partial input set'
    Assert-Rejected { Initialize-AutoClipSecureAcquisition -ManifestPath $outerPath -ManifestSha256 $script:outerHash -DownloaderSha256 $helperHash } 'guard absent'
    if (Initialize-AutoClipSecureAcquisition) { throw 'Legacy route unexpectedly selected a secure callback.' }
    Assert-Rejected { & $secureDownload $wheel.url (Join-Path $root 'bad') } 'missing caller size/hash'

    # Load the immutable archive's actual callback producers, without running installation.
    $fileSystem = New-Object -ComObject Scripting.FileSystemObject
    $shortTemp = $fileSystem.GetFolder($root).ShortPath
    if ($shortTemp -eq [IO.Path]::GetFullPath($shortTemp)) { throw 'Short TEMP fixture must use a genuine Windows 8.3 alias.' }
    $env:TEMP = $shortTemp
    Add-Type -AssemblyName System.IO.Compression.FileSystem
    $archivePath = 'D:\AutoClip-Inno-Migration\autoclip-source-build-v40-provenance-continuity.zip'
    if ((Get-FileHash $archivePath).Hash -ne 'f2b3be779294bc55d6f5f56c2a780a2d6b863486f3af9bd7d19f30051961fc9f') { throw 'Exact v40 archive fixture SHA-256 differs.' }
    $archive = [IO.Compression.ZipFile]::OpenRead($archivePath)
    try {
        foreach ($name in @('upstream-assets.ps1', 'Prepare-AutoClipOfflineCache.ps1', 'build-native-from-source.ps1')) {
            $entry = $archive.GetEntry($name)
            if (-not $entry) { throw "Immutable archive lacks $name" }
            [IO.Compression.ZipFileExtensions]::ExtractToFile($entry, (Join-Path $root $name))
        }
    } finally { $archive.Dispose() }
    $savedDownloadDefaults = $PSDefaultParameterValues
    try {
        $PSDefaultParameterValues = Get-AutoClipSecureDownloadDefaults -Existing $PSDefaultParameterValues -DownloadScript $secureDownload
        . (Join-Path $root 'upstream-assets.ps1')
        $releasePath = Join-Path $root 'release-manifest.json'
        @{ schema_version = 3; publisher_wheels = @($wheel) } | ConvertTo-Json -Depth 6 | Set-Content $releasePath -Encoding UTF8
        $InstallRoot = $root; $manifestPath = $releasePath
        $publisherCache = Join-Path $root 'cache'; $externalWheels = Join-Path $root 'wheels'
        $OfflinePublisherCache = $false; $InstallNvidiaGpu = $false; $cublasTermsAccepted = $false; $NonInteractive = $true
        $prepareCall = $ast.Find({ param($n) $n -is [Management.Automation.Language.CommandAst] -and $n.Extent.Text.StartsWith("& (Join-Path `$InstallRoot 'Prepare-AutoClipOfflineCache.ps1')") }, $true)
        if (-not $prepareCall) { throw 'Installer Prepare callback invocation is missing.' }
        Invoke-Expression $prepareCall.Extent.Text
        if ((Get-FileHash (Join-Path $root ('wheels\' + $wheel.filename))).Hash -ne $fixtureHash) { throw 'Actual Prepare callback did not acquire the verified wheel.' }
        # Redefining Get-PinnedUpstreamAsset, as native build does, must keep the guarded default.
        . (Join-Path $root 'upstream-assets.ps1')
        $buildAst = [Management.Automation.Language.Parser]::ParseFile((Join-Path $root 'build-native-from-source.ps1'), [ref]$tokens, [ref]$errors)
        $sourceFunction = $buildAst.Find({ param($n) $n -is [Management.Automation.Language.FunctionDefinitionAst] -and $n.Name -eq 'Get-VerifiedSource' }, $false)
        Invoke-Expression $sourceFunction.Extent.Text
        $BuildRoot = Join-Path $root 'sources'
        $source = Get-VerifiedSource 'source.tar.gz' $sourcePin.url 7 $fixtureHash
        if ((Get-FileHash $source).Hash -ne $fixtureHash) { throw 'Actual native source callback was not guarded.' }
        $directWheel = Get-ContentAddressedAsset -Uri $wheel.url -Sha256 $fixtureHash -Size 7 -Filename $wheel.filename -CacheRoot (Join-Path $root 'other-cache')
        if ((Get-FileHash $directWheel).Hash -ne $fixtureHash) { throw 'Content-addressed default callback was not guarded.' }
        $asset = $sourcePin; $destination = Join-Path $root 'external-source.tar.gz'
        $externalCall = $ast.Find({ param($n) $n -is [Management.Automation.Language.CommandAst] -and $n.Extent.Text.StartsWith('Get-PinnedUpstreamAsset -Uri ([string]$asset.url)') }, $true)
        if (-not $externalCall) { throw 'Installer external callback invocation is missing.' }
        Invoke-Expression $externalCall.Extent.Text | Out-Null
        if ((Get-FileHash $destination).Hash -ne $fixtureHash) { throw 'Actual installer external asset invocation was not guarded.' }
        Assert-Rejected { Get-PinnedUpstreamAsset -Uri $sourcePin.url -Sha256 ('b' * 64) -Size 7 -Destination (Join-Path $root 'mismatch') } 'caller pin mismatch after redefinition'
    } finally {
        $restore = $ast.Find({ param($n) $n -is [Management.Automation.Language.IfStatementAst] -and $n.Extent.Text -eq 'if ($secureDownload) { $PSDefaultParameterValues = $savedDownloadDefaults }' }, $true)
        if (-not $restore) { throw 'Guarded route must restore download defaults in installation finally.' }
        Invoke-Expression $restore.Extent.Text
    }
    if (-not [Object]::ReferenceEquals($savedDownloadDefaults, $PSDefaultParameterValues)) { throw 'Previous callback defaults were not restored.' }
    if ((Get-Content $networkMarker).Count -ne 4) { throw 'Unexpected guarded acquisition network count.' }
    Assert-Rejected { Invoke-AutoClipSecureDownload -Uri $wheel.url -Sha256 $fixtureHash -Size 7 -Destination ((Join-Path $root 'bad') + ':stream') } 'alternate stream destination'
    $junction = Join-Path $root 'linked-cache'
    New-Item -ItemType Junction -Path $junction -Target (Join-Path $root 'cache') | Out-Null
    try {
        Assert-Rejected { Invoke-AutoClipSecureDownload -Uri $wheel.url -Sha256 $fixtureHash -Size 7 -Destination (Join-Path $junction 'escape.whl') } 'reparse destination ancestor'
    } finally { [IO.Directory]::Delete($junction) }
    $publisherOriginal = [IO.File]::ReadAllBytes($publisherPath)
    [IO.File]::AppendAllText($publisherPath, ' ')
    Assert-Rejected { Invoke-AutoClipSecureDownload -Uri $wheel.url -Sha256 $fixtureHash -Size 7 -Destination (Join-Path $root 'changed-publisher') } 'publisher manifest changed after binding'
    [IO.File]::WriteAllBytes($publisherPath, $publisherOriginal)
    $sourcePin.delivery_classification = 'BLOCKED'
    Save-Outer; $secureDownload = Initialize-Fixture; $script:SecurePublisherManifestPath = $publisherPath
    Assert-Rejected { Invoke-AutoClipSecureDownload -Uri $sourcePin.url -Sha256 $fixtureHash -Size 7 -Destination (Join-Path $root 'blocked') } 'blocked route'
    $sourcePin.delivery_classification = 'DIRECT_RECIPIENT_DOWNLOAD'
    $outer.external_assets = @($sourcePin)
    Save-Outer; $secureDownload = Initialize-Fixture; $script:SecurePublisherManifestPath = $publisherPath
    Assert-Rejected { Invoke-AutoClipSecureDownload -Uri $sourcePin.url -Sha256 $fixtureHash -Size 7 -Destination (Join-Path $root 'duplicate') } 'duplicate routes'
    $outer.external_assets = @(); Save-Outer; $secureDownload = Initialize-Fixture; $script:SecurePublisherManifestPath = $publisherPath
    [IO.File]::AppendAllText($helper, '# changed')
    Assert-Rejected { Invoke-AutoClipSecureDownload -Uri $wheel.url -Sha256 $fixtureHash -Size 7 -Destination (Join-Path $root 'changed') } 'helper changed after binding'
    [IO.File]::AppendAllText($outerPath, ' ')
    Assert-Rejected { Invoke-AutoClipSecureDownload -Uri $wheel.url -Sha256 $fixtureHash -Size 7 -Destination (Join-Path $root 'changed') } 'outer manifest changed after binding'
    'Secure acquisition: actual immutable Prepare/source callbacks, strict pins, private TEMP transfer, default restoration, route ambiguity and tamper rejection PASS'
} finally {
    $env:TEMP = $originalTemp
    if (Test-Path -LiteralPath $root) { Remove-Item -LiteralPath $root -Recurse -Force }
}
