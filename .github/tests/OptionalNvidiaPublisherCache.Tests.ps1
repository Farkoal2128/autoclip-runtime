$ErrorActionPreference = 'Stop'
# This cache fixture does not accept real terms; consent refusal has its own behavioral test.
function Confirm-PrerequisiteTerms { }
$repoRoot = Split-Path -Parent (Split-Path -Parent $PSScriptRoot)
$prepare = Join-Path $repoRoot 'release\scripts\Prepare-AutoClipOfflineCache.ps1'
$fixture = Join-Path ([IO.Path]::GetTempPath()) ('autoclip-nvidia-cache-' + [guid]::NewGuid().ToString('N'))
New-Item -ItemType Directory -Path $fixture | Out-Null
try {
    $source = Join-Path $fixture 'publisher.whl'
    [IO.File]::WriteAllText($source, 'optional GPU publisher bytes')
    $hash = (Get-FileHash $source -Algorithm SHA256).Hash.ToLowerInvariant()
    $filename = 'nvidia_cublas_cu12-12.4.5.8-py3-none-win_amd64.whl'
    $manifest = Join-Path $fixture 'manifest.json'
    @{ schema_version=3; publisher_wheels=@(); external_assets=@(@{kind='python_wheel';filename=$filename;url='https://files.pythonhosted.org/fixture.whl';sha256=$hash;bytes=(Get-Item $source).Length}) } | ConvertTo-Json -Depth 5 | Set-Content $manifest -Encoding UTF8
    $calls = [pscustomobject]@{ Count=0 }
    $download = { param($url,$destination) $calls.Count++; Copy-Item $source $destination }.GetNewClosure()
    $cache = Join-Path $fixture 'cache'
    & $prepare -ManifestPath $manifest -CacheRoot $cache -DownloadScript $download
    if ($calls.Count -ne 0) { throw 'CPU cache preparation acquired an NVIDIA wheel.' }
    & $prepare -ManifestPath $manifest -CacheRoot $cache -InstallNvidiaGpu -DownloadScript $download
    $cached = Join-Path (Join-Path (Join-Path $cache 'sha256') $hash) $filename
    if ($calls.Count -ne 1 -or -not (Test-Path $cached)) { throw 'NVIDIA wheel was not acquired into the verified cache.' }
    $stage = Join-Path $fixture 'stage'
    & $prepare -ManifestPath $manifest -CacheRoot $cache -InstallNvidiaGpu -Offline -StageWheelhouse $stage -DownloadScript $download
    if ($calls.Count -ne 1 -or (Get-FileHash (Join-Path $stage $filename)).Hash.ToLowerInvariant() -ne $hash) { throw 'Offline NVIDIA staging downloaded or changed bytes.' }
    [IO.File]::WriteAllText($cached, 'tampered')
    $rejected = $false
    try { & $prepare -ManifestPath $manifest -CacheRoot $cache -InstallNvidiaGpu -Offline -DownloadScript $download }
    catch { if ($_.Exception.Message -notlike 'Offline cache is missing a verified publisher wheel:*') { throw }; $rejected=$true }
    if (-not $rejected -or $calls.Count -ne 1) { throw 'Offline corrupt NVIDIA cache was accepted or downloaded.' }
    # A publisher row cannot evade its metadata contract by declaring an
    # external-asset kind; only rows from external_assets use that schema.
    $spoofed = Get-Content $manifest -Raw | ConvertFrom-Json
    $spoofed.publisher_wheels = @($spoofed.external_assets[0])
    $spoofed.external_assets = @()
    $spoofed | ConvertTo-Json -Depth 5 | Set-Content $manifest -Encoding UTF8
    $rejected = $false
    try { & $prepare -ManifestPath $manifest -CacheRoot $cache -DownloadScript $download }
    catch { if ($_.Exception.Message -notlike 'Invalid publisher wheel identity:*') { throw }; $rejected=$true }
    if (-not $rejected) { throw 'Ordinary publisher row bypassed metadata validation.' }
    Write-Output 'CPU exclusion, NVIDIA verified-cache acquisition, offline reuse and tamper rejection passed.'
} finally {
    $resolved=[IO.Path]::GetFullPath($fixture)
    $temp=[IO.Path]::GetFullPath([IO.Path]::GetTempPath()).TrimEnd('\') + '\'
    if (-not $resolved.StartsWith($temp,[StringComparison]::OrdinalIgnoreCase)) { throw 'Unsafe fixture cleanup.' }
    Remove-Item -LiteralPath $resolved -Recurse -Force
}
