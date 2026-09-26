param(
    [string]$InstallRoot = (Join-Path $env:LOCALAPPDATA 'AutoClip\v11'),
    [string]$ArchivePath
)

$ErrorActionPreference = 'Stop'
$releaseUrl = 'https://github.com/Farkoal2128/autoclip-runtime/releases/download/v0.1.0-dev0-windows-v11/autoclip-windows-py311-v11.zip'
$expectedArchiveSha256 = '3ca8d5725228a28be12389adcd58fc9828e125ed54e08a12aa57aae52aa6d75c'

if (-not $IsWindows -and $PSVersionTable.PSEdition -eq 'Core') {
    throw 'This release contains Windows x64 Python wheels. Linux, macOS and Docker are not supported by this installer.'
}
if (-not [Environment]::Is64BitOperatingSystem) {
    throw 'This release requires 64-bit Windows.'
}
if (Test-Path -LiteralPath $InstallRoot) {
    throw "Install path already exists: $InstallRoot. Choose another -InstallRoot to preserve existing data."
}
$uv = Get-Command uv -ErrorAction SilentlyContinue
if (-not $uv) {
    throw 'uv is required. Install it from https://docs.astral.sh/uv/getting-started/installation/ and retry.'
}

$downloaded = $false
if (-not $ArchivePath) {
    $ArchivePath = Join-Path ([IO.Path]::GetTempPath()) "autoclip-v11-$PID.zip"
    Invoke-WebRequest -Uri $releaseUrl -OutFile $ArchivePath
    $downloaded = $true
}

try {
    $actualArchiveSha256 = (Get-FileHash -LiteralPath $ArchivePath -Algorithm SHA256).Hash.ToLowerInvariant()
    if ($actualArchiveSha256 -ne $expectedArchiveSha256) {
        throw "Release archive SHA-256 mismatch: $actualArchiveSha256"
    }

    New-Item -ItemType Directory -Path $InstallRoot -Force | Out-Null
    Expand-Archive -LiteralPath $ArchivePath -DestinationPath $InstallRoot
    $manifestPath = Join-Path $InstallRoot 'release-manifest.json'
    $manifest = Get-Content -LiteralPath $manifestPath -Raw | ConvertFrom-Json
    $rootFull = [IO.Path]::GetFullPath($InstallRoot).TrimEnd('\') + '\'
    foreach ($entry in $manifest.files) {
        $relative = [string]$entry.path
        $file = [IO.Path]::GetFullPath((Join-Path $InstallRoot $relative))
        if (-not $file.StartsWith($rootFull, [StringComparison]::OrdinalIgnoreCase)) {
            throw "Invalid release path: $relative"
        }
        $info = Get-Item -LiteralPath $file
        if ($info.Length -ne [long]$entry.bytes) {
            throw "Release file length mismatch: $relative"
        }
        $hash = (Get-FileHash -LiteralPath $file -Algorithm SHA256).Hash.ToLowerInvariant()
        if ($hash -ne [string]$entry.sha256) {
            throw "Release file SHA-256 mismatch: $relative"
        }
    }

    $venv = Join-Path $InstallRoot '.venv'
    & $uv.Source python install 3.11.16
    if ($LASTEXITCODE -ne 0) { throw 'Python 3.11.16 installation failed.' }
    & $uv.Source venv --python 3.11.16 $venv
    if ($LASTEXITCODE -ne 0) { throw 'Virtual environment creation failed.' }
    $python = Join-Path $venv 'Scripts\python.exe'
    $wheelhouse = Join-Path $InstallRoot 'wheelhouse'
    & $uv.Source pip install --python $python --no-cache --offline --no-index --find-links $wheelhouse autoclip==0.1.0.dev0
    if ($LASTEXITCODE -ne 0) { throw 'Offline AutoClip installation failed.' }
    & $uv.Source pip check --python $python
    if ($LASTEXITCODE -ne 0) { throw 'Installed dependency check failed.' }

    Write-Host "AutoClip installed at $InstallRoot"
    Write-Host "Run: & '$(Join-Path $InstallRoot 'Start-AutoClip.ps1')'"
    Write-Host 'FFmpeg/FFprobe, Ollama and model weights are external prerequisites.'
} finally {
    if ($downloaded -and (Test-Path -LiteralPath $ArchivePath)) {
        Remove-Item -LiteralPath $ArchivePath
    }
}
