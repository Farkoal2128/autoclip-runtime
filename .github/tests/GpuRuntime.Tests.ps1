param(
    [Parameter(Mandatory)][string]$ReleaseArchive,
    [string]$InstalledRoot
)

$ErrorActionPreference = 'Stop'
$repoRoot = Split-Path -Parent (Split-Path -Parent $PSScriptRoot)
$release = & (Join-Path $repoRoot 'install.ps1') -ReleaseInfo
if ((Get-FileHash -LiteralPath $ReleaseArchive -Algorithm SHA256).Hash.ToLowerInvariant() -ne $release.ArchiveSha256) {
    throw 'Release archive disagrees with the installer pin.'
}
Add-Type -AssemblyName System.IO.Compression.FileSystem
$archive = [IO.Compression.ZipFile]::OpenRead($ReleaseArchive)
try {
    $names = @($archive.Entries | ForEach-Object FullName)
    foreach ($prefix in @('wheelhouse/nvidia_cublas_cu12-', 'wheelhouse/nvidia_cudnn_cu12-')) {
        if (@($names | Where-Object { $_.StartsWith($prefix) -and $_.EndsWith('-win_amd64.whl') }).Count -ne 1) {
            throw "Expected exactly one Windows CUDA wheel in the release: $prefix"
        }
    }
    if (-not $names.Contains('release-manifest.json')) { throw 'Release manifest is missing.' }
    $manifestEntry = $archive.GetEntry('release-manifest.json')
    $reader = [IO.StreamReader]::new($manifestEntry.Open())
    try { $manifestText = $reader.ReadToEnd() } finally { $reader.Dispose() }
    $sha = [Security.Cryptography.SHA256]::Create()
    try {
        $manifestHash = ([BitConverter]::ToString($sha.ComputeHash([Text.Encoding]::UTF8.GetBytes($manifestText)))).Replace('-', '').ToLowerInvariant()
    } finally { $sha.Dispose() }
    if ($manifestHash -ne $release.ManifestSha256) { throw 'Release manifest disagrees with the installer pin.' }
    $manifest = $manifestText | ConvertFrom-Json
    $listed = @($manifest.files | ForEach-Object path)
    foreach ($name in ($names | Where-Object { $_.StartsWith('wheelhouse/nvidia_') })) {
        if (-not $listed.Contains($name)) { throw "CUDA wheel is not hash-listed: $name" }
    }
} finally {
    $archive.Dispose()
}

if ($InstalledRoot) {
    $python = Join-Path $InstalledRoot '.venv\Scripts\python.exe'
    if (-not (Test-Path -LiteralPath $python -PathType Leaf)) { throw "Installed Python is missing: $python" }
    & $python -c "from importlib.metadata import version; from pathlib import Path; from autoclip.cuda import library_directories, ensure_cuda_libraries; assert version('nvidia-cublas-cu12'); assert version('nvidia-cudnn-cu12'); dirs=library_directories(); assert any((p/'cublas64_12.dll').is_file() for p in dirs), dirs; assert any((p/'cudnn64_9.dll').is_file() for p in dirs), dirs; assert set(dirs).issubset(set(ensure_cuda_libraries()))"
    if ($LASTEXITCODE -ne 0) { throw 'Installed CUDA packages or loader discovery failed.' }
}

Write-Output 'CUDA wheelhouse, manifest and installed loader checks passed.'
