$ErrorActionPreference = 'Stop'
$repoRoot = Split-Path -Parent (Split-Path -Parent $PSScriptRoot)
. (Join-Path $repoRoot 'release/scripts/upstream-assets.ps1')
$fixture = Join-Path ([IO.Path]::GetTempPath()) ('autoclip-upstream-assets-' + [guid]::NewGuid().ToString('N'))
New-Item -ItemType Directory -Path $fixture | Out-Null
try {
    $source = Join-Path $fixture 'publisher.bin'
    [IO.File]::WriteAllText($source, 'publisher bytes')
    $hash = (Get-FileHash -LiteralPath $source -Algorithm SHA256).Hash.ToLowerInvariant()
    $destination = Join-Path $fixture 'cache\publisher.bin'
    $calls = [pscustomobject]@{ Count = 0 }
    $payload = [IO.File]::ReadAllBytes($source)
    $download = { param($uri, $path) $calls.Count++; [IO.File]::WriteAllBytes($path, $payload) }.GetNewClosure()
    $result = Get-PinnedUpstreamAsset -Uri 'https://example.test/publisher.bin' -Sha256 $hash -Size (Get-Item $source).Length -Destination $destination -DownloadScript $download
    if ($result -ne $destination -or $calls.Count -ne 1) { throw 'First verified download did not use the pinned destination.' }
    $result = Get-PinnedUpstreamAsset -Uri 'https://example.test/publisher.bin' -Sha256 $hash -Size (Get-Item $source).Length -Destination $destination -DownloadScript $download
    if ($result -ne $destination -or $calls.Count -ne 1) { throw 'Verified cache was downloaded again.' }
    $contentCache = Join-Path $fixture 'content-cache'
    $cached = Get-ContentAddressedAsset -Uri 'https://example.test/publisher.bin' -Sha256 $hash -Size (Get-Item $source).Length -Filename 'publisher.bin' -CacheRoot $contentCache -DownloadScript $download
    if ($cached -notlike "*$hash*" -or $calls.Count -ne 2) { throw 'Content-addressed cache did not pin the digest.' }
    [IO.File]::WriteAllText($cached, 'tampered')
    $cached = Get-ContentAddressedAsset -Uri 'https://example.test/publisher.bin' -Sha256 $hash -Size (Get-Item $source).Length -Filename 'publisher.bin' -CacheRoot $contentCache -DownloadScript $download
    if ($calls.Count -ne 3 -or (Get-FileHash $cached -Algorithm SHA256).Hash.ToLowerInvariant() -ne $hash) { throw 'Corrupt content cache was not repaired.' }
    [IO.File]::WriteAllText($destination, 'tampered')
    try {
        Get-PinnedUpstreamAsset -Uri 'https://example.test/publisher.bin' -Sha256 $hash -Size (Get-Item $source).Length -Destination $destination -DownloadScript $download | Out-Null
        throw 'Tampered cache was accepted.'
    } catch {
        if ($_.Exception.Message -notlike '*hash or size mismatch*') { throw }
    }
    Add-Type -AssemblyName System.IO.Compression.FileSystem
    $vendorZip = Join-Path $fixture 'vendor.zip'
    $zip = [IO.Compression.ZipFile]::Open($vendorZip, 'Create')
    try {
        $entry = $zip.CreateEntry('bin/libopenblas.dll')
        $writer = [IO.StreamWriter]::new($entry.Open())
        try { $writer.Write('openblas dll') } finally { $writer.Dispose() }
    } finally { $zip.Dispose() }
    $dllHash = [Security.Cryptography.SHA256]::Create()
    try { $expectedDllHash = ([BitConverter]::ToString($dllHash.ComputeHash([Text.Encoding]::UTF8.GetBytes('openblas dll')))).Replace('-', '').ToLowerInvariant() }
    finally { $dllHash.Dispose() }
    $dllDestination = Join-Path $fixture 'installed\libopenblas.dll'
    try {
        Install-PinnedZipMember -Archive $vendorZip -Member 'bin/libopenblas.dll' -Sha256 ('0' * 64) -Destination $dllDestination
        throw 'Wrong member hash was accepted.'
    } catch {
        if ($_.Exception.Message -notlike '*member SHA-256 mismatch*') { throw }
    }
    if (Test-Path -LiteralPath $dllDestination) { throw 'Rejected member was installed.' }
    Install-PinnedZipMember -Archive $vendorZip -Member 'bin/libopenblas.dll' -Sha256 $expectedDllHash -Destination $dllDestination
    if ((Get-FileHash -LiteralPath $dllDestination -Algorithm SHA256).Hash.ToLowerInvariant() -ne $expectedDllHash) { throw 'Verified member was not installed.' }
    Write-Output 'Pinned upstream download, cache, tamper and ZIP-member checks passed.'
} finally {
    Remove-Item -LiteralPath $fixture -Recurse -Force
}
