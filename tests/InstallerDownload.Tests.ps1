param([switch]$RealDownloads)
$ErrorActionPreference = 'Stop'
$repo = Split-Path -Parent $PSScriptRoot
$helper = Join-Path $repo 'installer/download-artifact.ps1'
if (-not (Test-Path -LiteralPath $helper)) { throw 'RED: recipient download helper is missing.' }
. $helper
Add-Type -AssemblyName System.Net.Http
Add-Type -TypeDefinition @'
using System;
using System.IO;
using System.Threading;
using System.Threading.Tasks;
public sealed class StalledDownloadStream : Stream {
    public static bool Cancelled;
    public static Task ScheduleCancel(string path) {
        return Task.Delay(200).ContinueWith(t => File.WriteAllText(path, "cancel"));
    }
    public override bool CanRead { get { return true; } }
    public override bool CanSeek { get { return false; } }
    public override bool CanWrite { get { return false; } }
    public override long Length { get { throw new NotSupportedException(); } }
    public override long Position { get { throw new NotSupportedException(); } set { throw new NotSupportedException(); } }
    public override int Read(byte[] b, int o, int n) { throw new InvalidOperationException("Stalled stream cannot use synchronous Read."); }
    public override Task<int> ReadAsync(byte[] b, int o, int n, CancellationToken token) {
        var pending = new TaskCompletionSource<int>();
        token.Register(() => { Cancelled = true; pending.TrySetCanceled(); });
        return pending.Task;
    }
    public override void Flush() { }
    public override long Seek(long o, SeekOrigin s) { throw new NotSupportedException(); }
    public override void SetLength(long n) { throw new NotSupportedException(); }
    public override void Write(byte[] b, int o, int n) { throw new NotSupportedException(); }
}
'@
$root = Join-Path $env:TEMP ('autoclip-download-test-' + [guid]::NewGuid().ToString('N'))
New-Item -ItemType Directory -Path $root | Out-Null
try {
    $fixture = Join-Path $root 'fixture.bin'
    [IO.File]::WriteAllText($fixture, 'pinned')
    $fixtureManifestPath = Join-Path $root 'manifest.json'
    $pin = [pscustomobject]@{ identity = 'fixture'; version = '1'; delivery_classification = 'DIRECT_RECIPIENT_DOWNLOAD'; url = 'https://official.example/artifact'; redirect_hosts = @('official.example', 'cdn.example'); bytes = 6; sha256 = (Get-FileHash $fixture).Hash }
    function Save-Pin { [pscustomobject]@{schema_version = 1; build_prerequisites = @($pin)} | ConvertTo-Json -Depth 5 | Set-Content $fixtureManifestPath -Encoding UTF8 }
    $script:requests = @()
    $script:status = 200
    $script:location = 'https://cdn.example/artifact'
    $script:body = 'pinned'
    $script:redirectOnce = $false
    $script:stalled = $false
    $script:headerStalled = $false
    $script:batchFailureAt = 0
    $script:batchCancelAt = 0
    $script:batchMutation = $null
    $script:batchMutationBlocked = $false
    function Get-InstallerDownloadResponse {
        param($Client, $Uri, $CancelPath)
        $script:requests += $Uri.AbsoluteUri
        if ($script:batchMutation) {
            try { [IO.File]::WriteAllText($script:batchMutation, 'mutated'); throw 'Manifest mutation was allowed.' }
            catch [IO.IOException] { $script:batchMutationBlocked = $true }
        }
        if ($script:batchCancelAt -eq $script:requests.Count) { [IO.File]::WriteAllText($CancelPath, 'cancel') }
        if ($script:headerStalled) {
            $cancellation = New-Object Threading.CancellationTokenSource
            try {
                $pending = (New-Object StalledDownloadStream).ReadAsync((New-Object byte[] 1), 0, 1, $cancellation.Token)
                return Wait-InstallerDownloadTask $pending $CancelPath 300000 $cancellation
            } finally { $cancellation.Dispose() }
        }
        $nextStatus = $script:status
        if ($script:batchFailureAt -eq $script:requests.Count) { $nextStatus = 503 }
        if ($script:redirectOnce -and $script:requests.Count -gt 1) { $nextStatus = 200 }
        $response = New-Object Net.Http.HttpResponseMessage ([Net.HttpStatusCode]$nextStatus)
        if ($script:status -ge 300 -and $script:status -lt 400) { $response.Headers.Location = [uri]$script:location }
        $response.Content = New-Object Net.Http.StringContent $script:body
        if ($script:stalled) { $response.Content = New-Object Net.Http.StreamContent (New-Object StalledDownloadStream) }
        return $response
    }
    function Reject-Download {
        param($Destination, $Pattern)
        $rejected = $false
        try { Get-InstallerArtifact -ManifestPath $fixtureManifestPath -Identity fixture -DestinationPath $Destination | Out-Null }
        catch { if ($_.Exception.Message -notmatch $Pattern) { throw }; $rejected = $true }
        if (-not $rejected) { throw "Expected rejection: $Pattern" }
    }
    Save-Pin
    $batchManifest = Get-Content (Join-Path $repo 'release/manifests/installer-dependencies-v1.json') -Raw | ConvertFrom-Json
    $batchBase = @($batchManifest.build_prerequisites | Where-Object identity -eq MSYS2)[0]
    $batchArtifacts = @($batchBase, $batchBase.signature, $batchBase.installer_key)
    foreach ($p in $batchBase.packages) { $batchArtifacts += @($p, $p.signature) }
    foreach ($a in $batchArtifacts) { $a.bytes = 6; $a.sha256 = $pin.sha256; $a.delivery_classification = 'DIRECT_RECIPIENT_DOWNLOAD' }
    $batchManifest.build_prerequisites = @($batchBase)
    $batchManifestPath = Join-Path $root 'batch-manifest.json'
    function Save-Batch { $batchManifest | ConvertTo-Json -Depth 12 | Set-Content -LiteralPath $batchManifestPath -Encoding UTF8 }
    Save-Batch
    $batchDirectory = Join-Path $root 'batch'
    New-Item -ItemType Directory -Path $batchDirectory | Out-Null
    $batchDestination = Join-Path $batchDirectory $batchBase.filename
    $script:requests = @()
    $script:batchMutation = $batchManifestPath
    $verifiedBatch = Get-InstallerMsysInputs -ManifestPath $batchManifestPath -ManifestSha256 (Get-FileHash $batchManifestPath).Hash -Identity MSYS2 -DestinationPath $batchDestination
    $script:batchMutation = $null
    if (-not $script:batchMutationBlocked) { throw 'Manifest was not locked against writes during batch requests.' }
    if ($verifiedBatch -ne $batchDestination -or $script:requests.Count -ne 13 -or @(Get-ChildItem $batchDirectory -File).Count -ne 13) { throw 'MSYS2 batch did not acquire exactly thirteen verified inputs.' }
    $script:requests = @()
    Get-InstallerMsysInputs -ManifestPath $batchManifestPath -ManifestSha256 (Get-FileHash $batchManifestPath).Hash -Identity MSYS2 -DestinationPath $batchDestination | Out-Null
    if ($script:requests.Count) { throw 'Verified MSYS2 batch cache requested network.' }
    function Reject-Batch([string]$Pattern, [string]$Hash = (Get-FileHash $batchManifestPath).Hash, [string]$Destination = $batchDestination) {
        $script:requests = @(); $rejected = $false
        try { Get-InstallerMsysInputs -ManifestPath $batchManifestPath -ManifestSha256 $Hash -Identity MSYS2 -DestinationPath $Destination | Out-Null }
        catch { if ($_.Exception.Message -notmatch $Pattern) { throw }; $rejected = $true }
        if (-not $rejected -or $script:requests.Count) { throw "Batch must reject $Pattern before HTTP." }
    }
    $lastSignature = $batchBase.packages[4].signature
    $lastSignature.delivery_classification = 'BLOCKED'; Save-Batch
    Reject-Batch 'unavailable'
    $lastSignature.delivery_classification = 'DIRECT_RECIPIENT_DOWNLOAD'; Save-Batch
    Reject-Batch 'manifest SHA-256' ('0' * 64)
    $hashBeforeMutation = (Get-FileHash $batchManifestPath).Hash
    Add-Content $batchManifestPath ' '
    Reject-Batch 'manifest SHA-256' $hashBeforeMutation
    Save-Batch
    $keyFingerprint = $batchBase.installer_key.fingerprint
    $batchBase.installer_key.fingerprint = '0' * 40; Save-Batch
    Reject-Batch 'signature/key metadata'
    $batchBase.installer_key.fingerprint = $keyFingerprint; Save-Batch
    $signatureName = $lastSignature.filename
    $lastSignature.filename = '../escape.sig'; Save-Batch
    Reject-Batch 'unsafe.*filename|package metadata'
    $lastSignature.filename = $signatureName; Save-Batch
    $batchManifest | Add-Member external_assets @([pscustomobject]@{identity='other'; filename=$batchBase.packages[4].filename; delivery_classification='DIRECT_RECIPIENT_DOWNLOAD'; url=$pin.url; redirect_hosts=$pin.redirect_hosts; bytes=6; sha256=$pin.sha256}) -Force
    Save-Batch; Reject-Batch 'Ambiguous'
    $batchManifest.PSObject.Properties.Remove('external_assets'); Save-Batch
    $batchBase | Add-Member extra_payload $lastSignature
    Save-Batch; Reject-Batch 'extra.*child'
    $batchBase.PSObject.Properties.Remove('extra_payload'); Save-Batch
    $originalPackages = $batchBase.packages
    $batchBase.packages = @($originalPackages) + @($originalPackages[0]); Save-Batch
    Reject-Batch 'batch metadata'
    $batchBase.packages = @($originalPackages[0], $originalPackages[0], $originalPackages[2], $originalPackages[3], $originalPackages[4]); Save-Batch
    Reject-Batch 'Duplicate'
    $batchBase.packages = $originalPackages; Save-Batch
    $lastHosts = $lastSignature.redirect_hosts
    $lastSignature.redirect_hosts = @('unapproved.example'); Save-Batch
    Reject-Batch 'Unapproved.*host'
    $lastSignature.redirect_hosts = $lastHosts; Save-Batch
    $batchManifest | Add-Member external_assets @([pscustomobject]@{identity='other'; filename=$batchBase.filename; delivery_classification='DIRECT_RECIPIENT_DOWNLOAD'; url=$pin.url; redirect_hosts=$pin.redirect_hosts; bytes=6; sha256=$pin.sha256})
    Save-Batch; Reject-Batch 'Ambiguous'
    $batchManifest.PSObject.Properties.Remove('external_assets'); Save-Batch
    Reject-Batch 'absolute|destination|metadata' (Get-FileHash $batchManifestPath).Hash ('relative/' + $batchBase.filename)
    [IO.File]::WriteAllText($batchDestination, 'broken')
    Reject-Batch 'Existing artifact'
    [IO.File]::WriteAllText($batchDestination, 'pinned')
    foreach ($file in Get-ChildItem -LiteralPath $batchDirectory -File) { Remove-Item -LiteralPath $file.FullName }
    $script:batchFailureAt = 5; $script:requests = @(); $failed = $false
    try { Get-InstallerMsysInputs -ManifestPath $batchManifestPath -ManifestSha256 (Get-FileHash $batchManifestPath).Hash -Identity MSYS2 -DestinationPath $batchDestination | Out-Null }
    catch { if ($_.Exception.Message -notmatch 'HTTP 503') { throw }; $failed = $true }
    $script:batchFailureAt = 0
    if (-not $failed -or $script:requests.Count -ne 5 -or @(Get-ChildItem $batchDirectory -File).Count -ne 4) { throw 'Batch failed transfer did not preserve exactly four verified inputs.' }
    $script:requests = @()
    Get-InstallerMsysInputs -ManifestPath $batchManifestPath -ManifestSha256 (Get-FileHash $batchManifestPath).Hash -Identity MSYS2 -DestinationPath $batchDestination | Out-Null
    if ($script:requests.Count -ne 9) { throw 'Batch retry did not reuse exactly four verified inputs.' }
    foreach ($file in Get-ChildItem -LiteralPath $batchDirectory -File) { Remove-Item -LiteralPath $file.FullName }
    $batchSignal = Join-Path $root 'batch-cancel.txt'
    $script:batchCancelAt = 5; $script:requests = @(); $cancelledBatch = $false
    try { Get-InstallerMsysInputs -ManifestPath $batchManifestPath -ManifestSha256 (Get-FileHash $batchManifestPath).Hash -Identity MSYS2 -DestinationPath $batchDestination -CancelPath $batchSignal | Out-Null }
    catch { if ($_.Exception.Message -notmatch 'cancelled') { throw }; $cancelledBatch = $true }
    $script:batchCancelAt = 0
    if (-not $cancelledBatch -or $script:requests.Count -ne 5 -or @(Get-ChildItem $batchDirectory -File).Count -ne 4) { throw 'Batch cancellation did not preserve verified inputs.' }
    Remove-Item -LiteralPath $batchSignal
    $script:requests = @()
    Get-InstallerMsysInputs -ManifestPath $batchManifestPath -ManifestSha256 (Get-FileHash $batchManifestPath).Hash -Identity MSYS2 -DestinationPath $batchDestination | Out-Null
    if ($script:requests.Count -ne 9) { throw 'Cancelled batch retry cache failed.' }
    $cliBatch = @(& "$env:SystemRoot\System32\WindowsPowerShell\v1.0\powershell.exe" -NoProfile -File $helper -ManifestPath $batchManifestPath -ManifestSha256 (Get-FileHash $batchManifestPath).Hash -Identity MSYS2 -DestinationPath $batchDestination -MsysInputs)
    if ($LASTEXITCODE -ne 0 -or $cliBatch.Count -ne 1 -or $cliBatch[0] -ne $batchDestination) { throw 'Actual MSYS2 batch CLI failed verified cache entrypoint.' }
    $extensionFailures = @()
    $pin | Add-Member filename 'fixture.zip'
    [pscustomobject]@{schema_version = 1; external_assets = @($pin)} | ConvertTo-Json -Depth 5 | Set-Content $fixtureManifestPath -Encoding UTF8
    foreach ($externalIdentity in @('fixture', 'fixture.zip')) {
        try { Get-InstallerArtifact -ManifestPath $fixtureManifestPath -Identity $externalIdentity -DestinationPath (Join-Path $root ($externalIdentity + '-external.bin')) | Out-Null }
        catch { $extensionFailures += "External $externalIdentity resolution: $($_.Exception.Message)" }
    }
    $fixturePublisherPath = Join-Path $root 'publisher-wheel-manifest.json'
    $wheel = [pscustomobject]@{filename = 'fixture.whl'; package = 'fixture'; version = '1'; url = 'https://files.pythonhosted.org/packages/fixture.whl'; bytes = $pin.bytes; sha256 = $pin.sha256}
    [pscustomobject]@{schema_version = 1; wheels = @($wheel)} | ConvertTo-Json -Depth 5 | Set-Content $fixturePublisherPath -Encoding UTF8
    $publisherRoute = [pscustomobject]@{sha256 = (Get-FileHash $fixturePublisherPath).Hash; delivery_classification = 'DIRECT_RECIPIENT_DOWNLOAD'; redirect_hosts = @('files.pythonhosted.org')}
    $extendedManifest = [pscustomobject]@{schema_version = 1; external_assets = @($pin); publisher_wheels = $publisherRoute}
    function Save-ExtendedManifest { $extendedManifest | ConvertTo-Json -Depth 6 | Set-Content $fixtureManifestPath -Encoding UTF8 }
    Save-ExtendedManifest
    try { Get-InstallerArtifact -ManifestPath $fixtureManifestPath -Identity 'fixture.whl' -PublisherManifestPath $fixturePublisherPath -DestinationPath (Join-Path $root 'wheel.bin') | Out-Null }
    catch { $extensionFailures += "Publisher wheel resolution: $($_.Exception.Message)" }
    if ($extensionFailures.Count) { throw ($extensionFailures -join "`n") }
    function Reject-ExtendedArtifact {
        param([string]$RequestedIdentity, [string]$Pattern)
        $script:requests = @()
        $rejected = $false
        try { Get-InstallerArtifact -ManifestPath $fixtureManifestPath -Identity $RequestedIdentity -PublisherManifestPath $fixturePublisherPath -DestinationPath (Join-Path $root 'rejected-extension.bin') | Out-Null }
        catch { if ($_.Exception.Message -notmatch $Pattern) { throw }; $rejected = $true }
        if (-not $rejected -or $script:requests.Count) { throw 'Invalid extended artifact policy requested network or was accepted.' }
    }
    Add-Content $fixturePublisherPath ' '
    Reject-ExtendedArtifact 'fixture.whl' 'publisher manifest SHA-256'
    [pscustomobject]@{schema_version = 2; wheels = @($wheel)} | ConvertTo-Json -Depth 5 | Set-Content $fixturePublisherPath -Encoding UTF8
    $publisherRoute.sha256 = (Get-FileHash $fixturePublisherPath).Hash; Save-ExtendedManifest
    Reject-ExtendedArtifact 'fixture.whl' 'publisher manifest schema'
    [pscustomobject]@{schema_version = 1; wheels = @($wheel)} | ConvertTo-Json -Depth 5 | Set-Content $fixturePublisherPath -Encoding UTF8
    $publisherRoute.sha256 = (Get-FileHash $fixturePublisherPath).Hash; Save-ExtendedManifest
    $publisherRoute.delivery_classification = 'BLOCKED'; Save-ExtendedManifest
    Reject-ExtendedArtifact 'fixture.whl' 'route is unavailable'
    $publisherRoute.delivery_classification = 'DIRECT_RECIPIENT_DOWNLOAD'; Save-ExtendedManifest
    Reject-ExtendedArtifact 'unknown.whl' 'route is unavailable'
    $extendedManifest | Add-Member build_prerequisites @($pin)
    Save-ExtendedManifest
    Reject-ExtendedArtifact 'fixture' 'Ambiguous'
    $extendedManifest.PSObject.Properties.Remove('build_prerequisites')
    $pin.delivery_classification = 'BLOCKED'; Save-ExtendedManifest
    Reject-ExtendedArtifact 'fixture.zip' 'route is unavailable'
    $pin.delivery_classification = 'DIRECT_RECIPIENT_DOWNLOAD'; Save-ExtendedManifest
    $wheelDuplicate = [pscustomobject]@{schema_version = 1; wheels = @($wheel, $wheel)}
    $wheelDuplicate | ConvertTo-Json -Depth 5 | Set-Content $fixturePublisherPath -Encoding UTF8
    $publisherRoute.sha256 = (Get-FileHash $fixturePublisherPath).Hash; Save-ExtendedManifest
    Reject-ExtendedArtifact 'fixture.whl' 'Ambiguous'
    $package = [pscustomobject]@{identity = 'fixture-package'; version = '1-1'; architecture = 'x86_64'; filename = 'fixture-package-1-1-x86_64.pkg.tar.zst'; url = 'https://repo.msys2.org/msys/x86_64/fixture-package-1-1-x86_64.pkg.tar.zst'; bytes = 6; sha256 = $pin.sha256; delivery_classification = 'DIRECT_RECIPIENT_DOWNLOAD'; redirect_hosts = @('repo.msys2.org')}
    $signature = [pscustomobject]@{filename = $package.filename + '.sig'; url = $package.url + '.sig'; bytes = 6; sha256 = $pin.sha256; delivery_classification = 'DIRECT_RECIPIENT_DOWNLOAD'; redirect_hosts = @('repo.msys2.org')}
    $package | Add-Member signature $signature
    $msysParent = [pscustomobject]@{identity = 'MSYS2'; delivery_classification = 'DIRECT_RECIPIENT_DOWNLOAD'; packages = @($package)}
    $msysManifest = [pscustomobject]@{schema_version = 1; build_prerequisites = @($msysParent)}
    function Save-MsysManifest { $msysManifest | ConvertTo-Json -Depth 8 | Set-Content $fixtureManifestPath -Encoding UTF8 }
    Save-MsysManifest
    $nestedFailures = @()
    foreach ($nestedIdentity in @($package.identity, $package.filename, $signature.filename)) {
        try { Get-InstallerArtifact -ManifestPath $fixtureManifestPath -Identity $nestedIdentity -DestinationPath (Join-Path $root ($nestedIdentity + '-nested.bin')) | Out-Null }
        catch { $nestedFailures += "Nested $nestedIdentity resolution: $($_.Exception.Message)" }
    }
    if ($nestedFailures.Count) { throw ($nestedFailures -join "`n") }
    function Reject-NestedArtifact {
        param([string]$RequestedIdentity, [string]$Pattern)
        $script:requests = @(); $rejected = $false
        try { Get-InstallerArtifact -ManifestPath $fixtureManifestPath -Identity $RequestedIdentity -DestinationPath (Join-Path $root 'rejected-nested.bin') | Out-Null }
        catch { if ($_.Exception.Message -notmatch $Pattern) { throw }; $rejected = $true }
        if (-not $rejected -or $script:requests.Count) { throw 'Invalid nested acquisition made a request or succeeded.' }
    }
    $msysParent.delivery_classification = 'BLOCKED'; Save-MsysManifest
    Reject-NestedArtifact $package.filename 'route is unavailable'
    Reject-NestedArtifact $signature.filename 'route is unavailable'
    $msysParent.delivery_classification = 'DIRECT_RECIPIENT_DOWNLOAD'
    $package.delivery_classification = 'BLOCKED'; Save-MsysManifest
    Reject-NestedArtifact $signature.filename 'route is unavailable'
    $package.delivery_classification = 'DIRECT_RECIPIENT_DOWNLOAD'
    $signature.delivery_classification = 'BLOCKED'; Save-MsysManifest
    Reject-NestedArtifact $signature.filename 'route is unavailable'
    $signature.delivery_classification = 'DIRECT_RECIPIENT_DOWNLOAD'
    $signature.sha256 = 'bad'; Save-MsysManifest
    Reject-NestedArtifact $signature.filename 'Invalid pinned'
    $signature.sha256 = $pin.sha256
    $package.filename = '../unsafe.pkg.tar.zst'; Save-MsysManifest
    Reject-NestedArtifact $package.identity 'Invalid MSYS2 package metadata'
    $package.filename = 'fixture-package-1-1-x86_64.pkg.tar.zst'
    $package.redirect_hosts = @(); Save-MsysManifest
    Reject-NestedArtifact $package.identity 'redirect host policy'
    $package.redirect_hosts = @('repo.msys2.org')
    $msysManifest | Add-Member external_assets @($package); Save-MsysManifest
    Reject-NestedArtifact $package.filename 'Ambiguous'
    $msysManifest.PSObject.Properties.Remove('external_assets')
    $msysParent.packages = @($package, $package); Save-MsysManifest
    Reject-NestedArtifact $signature.filename 'Ambiguous'
    $msysParent.packages = @($package)
    $msysParent | Add-Member filename 'msys2-base-x86_64-20260611.tar.xz'
    $msysParent | Add-Member version '20260611'
    $msysParent | Add-Member artifact_kind 'archive'
    $msysParent | Add-Member archive_format 'tar.xz'
    $baseSignature = [pscustomobject]@{filename = $msysParent.filename + '.sig'; url = 'https://github.com/msys2/base.tar.xz.sig'; bytes = 6; sha256 = $pin.sha256; delivery_classification = 'DIRECT_RECIPIENT_DOWNLOAD'; redirect_hosts = @('github.com')}
    $installerKey = [pscustomobject]@{filename = 'installer-signer.asc'; fingerprint = '0EBF782C5D53F7E5FB02A66746BD761F7A49B0EC'; url = 'https://keyserver.ubuntu.com/pks/lookup?op=get'; bytes = 6; sha256 = $pin.sha256; delivery_classification = 'DIRECT_RECIPIENT_DOWNLOAD'; redirect_hosts = @('keyserver.ubuntu.com')}
    $msysParent | Add-Member signature $baseSignature
    $msysParent | Add-Member installer_key $installerKey
    Save-MsysManifest
    foreach ($child in @($baseSignature, $installerKey)) {
        Get-InstallerArtifact -ManifestPath $fixtureManifestPath -Identity $child.filename -DestinationPath (Join-Path $root ($child.filename + '-child.bin')) | Out-Null
    }
    $msysParent.delivery_classification = 'BLOCKED'; Save-MsysManifest
    Reject-NestedArtifact $baseSignature.filename 'route is unavailable'
    Reject-NestedArtifact $installerKey.filename 'route is unavailable'
    $msysParent.delivery_classification = 'DIRECT_RECIPIENT_DOWNLOAD'
    $installerKey.delivery_classification = 'BLOCKED'; Save-MsysManifest
    Reject-NestedArtifact $installerKey.filename 'route is unavailable'
    $installerKey.delivery_classification = 'DIRECT_RECIPIENT_DOWNLOAD'
    $installerKey.fingerprint = 'BAD'; Save-MsysManifest
    Reject-NestedArtifact $installerKey.filename 'Invalid MSYS2 base'
    $installerKey.fingerprint = '0EBF782C5D53F7E5FB02A66746BD761F7A49B0EC'
    $baseSignature.filename = '../unsafe.sig'; Save-MsysManifest
    Reject-NestedArtifact $baseSignature.filename 'Invalid MSYS2 base'
    $baseSignature.filename = $msysParent.filename + '.sig'
    $baseSignature.redirect_hosts = @(); Save-MsysManifest
    Reject-NestedArtifact $baseSignature.filename 'redirect host policy'
    $baseSignature.redirect_hosts = @('github.com'); Save-MsysManifest
    $nativeManifest = [pscustomobject]@{schema_version = 1; native_build_assets = @($pin)}
    function Save-NativeManifest { $nativeManifest | ConvertTo-Json -Depth 6 | Set-Content $fixtureManifestPath -Encoding UTF8 }
    Save-NativeManifest
    $nativeFailures = @()
    foreach ($nativeIdentity in @($pin.identity, $pin.filename)) {
        try { Get-InstallerArtifact -ManifestPath $fixtureManifestPath -Identity $nativeIdentity -DestinationPath (Join-Path $root ($nativeIdentity + '-native.bin')) | Out-Null }
        catch { $nativeFailures += "Native $nativeIdentity resolution: $($_.Exception.Message)" }
    }
    if ($nativeFailures.Count) { throw ($nativeFailures -join "`n") }
    $pin.delivery_classification = 'BLOCKED'; Save-NativeManifest
    Reject-NestedArtifact $pin.filename 'route is unavailable'
    $pin.delivery_classification = 'DIRECT_RECIPIENT_DOWNLOAD'
    $nativeManifest | Add-Member external_assets @($pin); Save-NativeManifest
    Reject-NestedArtifact $pin.filename 'Ambiguous'
    Save-Pin
    $destination = Join-Path $root 'download.bin'
    $script:status = 302
    foreach ($redirect in @('https://unapproved.example/payload', 'http://cdn.example/payload', 'https://user:password@cdn.example/payload', 'https://cdn.example:444/payload')) {
        $script:requests = @(); $script:location = $redirect
        Reject-Download $destination 'Unsafe|Unapproved'
        if ($script:requests.Count -ne 1 -or (Test-Path $destination)) { throw 'Unapproved redirect was requested or published.' }
    }
    $script:requests = @(); $script:location = 'https://cdn.example/artifact'
    Reject-Download $destination 'redirect limit'
    if ($script:requests.Count -ne 6) { throw 'Redirect limit must allow only five hops.' }
    $script:requests = @(); $script:redirectOnce = $true
    $redirected = Join-Path $root 'redirected.bin'
    Get-InstallerArtifact -ManifestPath $fixtureManifestPath -Identity fixture -DestinationPath $redirected | Out-Null
    if ($script:requests.Count -ne 2 -or $script:requests[1] -ne 'https://cdn.example/artifact') { throw 'Approved redirect did not download.' }
    $commandResult = & powershell -NoProfile -ExecutionPolicy Bypass -File $helper -ManifestPath $fixtureManifestPath -Identity fixture -DestinationPath $redirected
    if ($LASTEXITCODE -ne 0 -or $commandResult -ne $redirected) { throw 'Command entrypoint did not return the verified cached artifact.' }
    $script:redirectOnce = $false
    $script:status = 200
    $pin.delivery_classification = 'BLOCKED'; Save-Pin; $script:requests = @()
    Reject-Download $destination 'route is unavailable'
    if ($script:requests.Count) { throw 'Blocked route made a request.' }
    $pin.delivery_classification = 'DIRECT_RECIPIENT_DOWNLOAD'; Save-Pin
    $script:body = 'wrong!'; Reject-Download $destination 'size or SHA-256'
    $script:body = 'short'; Reject-Download $destination 'size or SHA-256'
    if (Test-Path $destination) { throw 'Invalid bytes published.' }
    $script:body = 'pinned'; $script:status = 503
    Reject-Download $destination '503'
    $script:status = 200
    Get-InstallerArtifact -ManifestPath $fixtureManifestPath -Identity fixture -DestinationPath $destination | Out-Null
    if ((Get-FileHash $destination).Hash -ne $pin.sha256) { throw 'Retry failed to publish verified bytes.' }
    $script:requests = @()
    Get-InstallerArtifact -ManifestPath $fixtureManifestPath -Identity fixture -DestinationPath $destination | Out-Null
    if ($script:requests.Count) { throw 'Verified cache requested network.' }
    [IO.File]::WriteAllText($destination, 'corrupt')
    Reject-Download $destination 'size or SHA-256'
    if ([IO.File]::ReadAllText($destination) -ne 'corrupt' -or $script:requests.Count) { throw 'Corrupt destination overwritten or requested network.' }
    $pin.redirect_hosts = @(); Save-Pin
    Reject-Download (Join-Path $root 'missing-policy.bin') 'redirect host policy'
    $pin.redirect_hosts = @('official.example', 'cdn.example'); Save-Pin
    $failures = @()
    $originalDirectory = [Environment]::CurrentDirectory
    $script:requests = @()
    try {
        [Environment]::CurrentDirectory = $root
        try { Reject-Download 'relative.bin' 'absolute' }
        catch { $failures += "Relative destination: $($_.Exception.Message)" }
        if ($script:requests.Count) { $failures += 'Relative destination requested network.' }
    } finally { [Environment]::CurrentDirectory = $originalDirectory }
    $script:stalled = $true
    $beforeStages = @(Get-ChildItem -LiteralPath $env:TEMP -Directory -Filter 'autoclip-download-*' | Select-Object -ExpandProperty FullName)
    $timer = [Diagnostics.Stopwatch]::StartNew()
    try {
        try { Reject-Download (Join-Path $root 'stalled.bin') 'body read timed out' }
        catch { $failures += "Stalled response: $($_.Exception.Message)" }
        if (-not [StalledDownloadStream]::Cancelled) { $failures += 'Stalled read was not cancelled.' }
        if ($timer.Elapsed.TotalSeconds -gt 45 -or (Test-Path (Join-Path $root 'stalled.bin'))) { $failures += 'Stalled response exceeded the time bound or published bytes.' }
        $remainingStages = @(Get-ChildItem -LiteralPath $env:TEMP -Directory -Filter 'autoclip-download-*' | Where-Object { $beforeStages -notcontains $_.FullName })
        if ($remainingStages.Count) { $failures += 'Stalled response staging was not cleaned.' }
    } finally { $script:stalled = $false; $timer.Stop() }
    if ($failures.Count) { throw ($failures -join "`n") }
    foreach ($phase in @('header', 'body')) {
        $script:headerStalled = $phase -eq 'header'
        $script:stalled = $phase -eq 'body'
        [StalledDownloadStream]::Cancelled = $false
        $signal = Join-Path $root ($phase + '-cancel.txt')
        $signalTask = [StalledDownloadStream]::ScheduleCancel($signal)
        $timer.Restart()
        $cancelled = $false
        try {
            Get-InstallerArtifact -ManifestPath $fixtureManifestPath -Identity fixture -DestinationPath (Join-Path $root ($phase + '-cancel.bin')) -CancelPath $signal | Out-Null
        } catch {
            if ($_.Exception.Message -notmatch 'cancelled') { throw }
            $cancelled = $true
        } finally { $script:headerStalled = $false; $script:stalled = $false; $timer.Stop(); $signalTask.Wait() }
        if (-not $cancelled -or -not [StalledDownloadStream]::Cancelled -or $timer.Elapsed.TotalSeconds -gt 5 -or (Test-Path (Join-Path $root ($phase + '-cancel.bin')))) { throw "$phase cooperative cancellation failed." }
    }
    Reject-Download (Join-Path $root '../escape.bin') 'Unsafe download destination'
    $junction = Join-Path $root 'junction'
    New-Item -ItemType Junction -Path $junction -Target $root | Out-Null
    Reject-Download (Join-Path $junction 'escaped.bin') 'reparse point'
    [IO.Directory]::Delete($junction)
    [pscustomobject]@{schema_version = 1; target_release = [pscustomobject]@{id = 'fixture'; delivery_classification = $pin.delivery_classification; url = $pin.url; redirect_hosts = $pin.redirect_hosts; bytes = $pin.bytes; sha256 = $pin.sha256}} |
        ConvertTo-Json -Depth 5 | Set-Content $fixtureManifestPath -Encoding UTF8
    $script:requests = @()
    Get-InstallerArtifact -ManifestPath $fixtureManifestPath -Identity fixture -DestinationPath (Join-Path $root 'release.bin') | Out-Null
    if ($script:requests.Count -ne 1) { throw 'Target release identity failed.' }
    'Installer download behavioral tests PASS: redirects, classification, size/hash, retry, verified/corrupt cache.'
    if ($RealDownloads) {
        # Restore the real transport; only this temporary fixture changes blocked classifications.
        . $helper
        $actual = Get-Content (Join-Path $repo 'release/manifests/installer-dependencies-v1.json') -Raw | ConvertFrom-Json
        foreach ($identity in @('uv', 'Git for Windows')) {
            $item = @($actual.build_prerequisites | Where-Object identity -eq $identity)[0]
            $item.delivery_classification = 'DIRECT_RECIPIENT_DOWNLOAD'
            $item | Add-Member redirect_hosts @('github.com', 'release-assets.githubusercontent.com') -Force
            [pscustomobject]@{schema_version = 1; build_prerequisites = @($item)} | ConvertTo-Json -Depth 6 | Set-Content $fixtureManifestPath -Encoding UTF8
            $local = Join-Path $root ($identity.Replace(' ', '-') + '.zip')
            Get-InstallerArtifact -ManifestPath $fixtureManifestPath -Identity $identity -DestinationPath $local | Out-Null
            "Official local download PASS: $identity bytes=$((Get-Item $local).Length) sha256=$((Get-FileHash $local).Hash)"
        }
    }
} finally {
    $resolved = [IO.Path]::GetFullPath($root)
    if (-not $resolved.StartsWith([IO.Path]::GetFullPath($env:TEMP).TrimEnd('\') + '\', [StringComparison]::OrdinalIgnoreCase)) { throw 'Unsafe fixture cleanup.' }
    Remove-Item -LiteralPath $resolved -Recurse -Force
}
