$ErrorActionPreference = 'Stop'
$repoRoot = Split-Path -Parent (Split-Path -Parent $PSScriptRoot)
$fixture = Join-Path ([IO.Path]::GetTempPath()) ('autoclip-publisher-wheels-' + [guid]::NewGuid().ToString('N'))
New-Item -ItemType Directory -Path $fixture | Out-Null
try {
    $source = Join-Path $fixture 'example-1-py3-none-any.whl'
    [IO.File]::WriteAllText($source, 'wheel bytes')
    $hash = (Get-FileHash $source -Algorithm SHA256).Hash.ToLowerInvariant()
    $manifest = Join-Path $fixture 'release-manifest.json'
    @{ schema_version = 3; publisher_wheels = @(@{ package = 'example'; version = '1'; filename = 'example-1-py3-none-any.whl'; tags = @('py3-none-any'); bytes = (Get-Item $source).Length; sha256 = $hash; url = 'https://files.pythonhosted.org/example.whl'; publisher_identity = 'PyPI project example'; delivery_policy = 'publisher' }) } | ConvertTo-Json -Depth 5 | Set-Content $manifest
    $cache = Join-Path $fixture 'cache'
    $stage = Join-Path $fixture 'stage'
    $calls = [pscustomobject]@{ Count = 0 }
    $download = { param($url, $path) $calls.Count++; Copy-Item -LiteralPath $source -Destination $path }.GetNewClosure()
    & (Join-Path $repoRoot 'Prepare-AutoClipOfflineCache.ps1') -ManifestPath $manifest -CacheRoot $cache -StageWheelhouse $stage -DownloadScript $download
    if ($calls.Count -ne 1 -or (Get-FileHash (Join-Path $stage 'example-1-py3-none-any.whl') -Algorithm SHA256).Hash.ToLowerInvariant() -ne $hash) { throw 'First publisher fetch failed.' }
    & (Join-Path $repoRoot 'Prepare-AutoClipOfflineCache.ps1') -ManifestPath $manifest -CacheRoot $cache -StageWheelhouse $stage -Offline -DownloadScript $download
    if ($calls.Count -ne 1) { throw 'Offline reuse downloaded a wheel.' }
    $cached = Join-Path (Join-Path (Join-Path $cache 'sha256') $hash) 'example-1-py3-none-any.whl'
    [IO.File]::WriteAllText($cached, 'corrupt')
    try {
        & (Join-Path $repoRoot 'Prepare-AutoClipOfflineCache.ps1') -ManifestPath $manifest -CacheRoot $cache -Offline -DownloadScript $download
        throw 'Offline mode accepted a corrupt cached wheel.'
    } catch {
        if ($_.Exception.Message -notlike '*Offline cache is missing*') { throw }
    }
    & (Join-Path $repoRoot 'Prepare-AutoClipOfflineCache.ps1') -ManifestPath $manifest -CacheRoot $cache -StageWheelhouse $stage -DownloadScript $download
    if ($calls.Count -ne 2) { throw 'Corrupt cached wheel was not redownloaded.' }
    Remove-Item -LiteralPath $cached -Force
    $interrupted = { param($url, $path) [IO.File]::WriteAllText($path, 'partial'); throw 'interrupted transfer' }
    try {
        & (Join-Path $repoRoot 'Prepare-AutoClipOfflineCache.ps1') -ManifestPath $manifest -CacheRoot $cache -DownloadScript $interrupted
        throw 'Interrupted publisher transfer was accepted.'
    } catch {
        if ($_.Exception.Message -notlike '*interrupted transfer*') { throw }
    }
    if ((Test-Path -LiteralPath $cached) -or @(Get-ChildItem -LiteralPath (Split-Path -Parent $cached) -File).Count -ne 0) {
        throw 'Interrupted publisher transfer left an accepted cache file.'
    }
    $unsafe = Join-Path $fixture 'unsafe-manifest.json'
    @{ schema_version = 3; publisher_wheels = @(@{ package = 'example'; version = '1'; filename = '../escape.whl'; bytes = (Get-Item $source).Length; sha256 = $hash; url = 'https://files.pythonhosted.org/example.whl'; publisher_identity = 'PyPI project example'; delivery_policy = 'publisher' }) } | ConvertTo-Json -Depth 5 | Set-Content $unsafe
    try {
        & (Join-Path $repoRoot 'Prepare-AutoClipOfflineCache.ps1') -ManifestPath $unsafe -CacheRoot $cache -DownloadScript $download
        throw 'Unsafe publisher manifest path was accepted.'
    } catch {
        if ($_.Exception.Message -notlike '*Invalid publisher wheel identity*') { throw }
    }
    Write-Output 'Publisher wheel cache download, reuse, offline missing, corruption and interrupted transfer checks passed.'
} finally {
    Remove-Item -LiteralPath $fixture -Recurse -Force
}
