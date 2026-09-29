param(
    [string]$InstallRoot,
    [string]$ArchivePath,
    [string]$ExternalCache,
    [switch]$InstallOllama,
    [switch]$PrerequisitesOnly,
    [switch]$ReleaseInfo
)

$ErrorActionPreference = 'Stop'
$releaseUrl = '' # Candidate is local until its exact asset is published and verified.
$expectedArchiveSha256 = '27e07a123c157e25fa0b935b2c573c78226beba792ae1d48bddf17012eb559ae'
$expectedManifestSha256 = 'da7062b2cbe7195030d5a54e46b9a1f52d442a1f5a2dc7f57ea1aff7bb1f7833'
$releaseId = 'v11-20260926-source-routed-candidate'

if ($ReleaseInfo) {
    [pscustomobject]@{
        ReleaseId = $releaseId
        ArchiveSha256 = $expectedArchiveSha256
        ManifestSha256 = $expectedManifestSha256
        ArchiveUrl = $releaseUrl
    }
    return
}

if (-not $IsWindows -and $PSVersionTable.PSEdition -eq 'Core') {
    throw 'This release contains Windows x64 Python wheels. Linux, macOS and Docker are not supported by this installer.'
}
if (-not [Environment]::Is64BitOperatingSystem) {
    throw 'This release requires 64-bit Windows.'
}
if (-not $InstallRoot) {
    $InstallRoot = Join-Path (Join-Path $env:LOCALAPPDATA 'AutoClip') $releaseId
}
if (-not $ExternalCache) {
    $ExternalCache = Join-Path (Join-Path $env:LOCALAPPDATA 'AutoClip') 'publisher-cache'
}
$resumeIncomplete = $false
if (Test-Path -LiteralPath $InstallRoot) {
    if (-not $PrerequisitesOnly) {
        $existingManifest = Join-Path $InstallRoot 'release-manifest.json'
        $existingVenv = Join-Path $InstallRoot '.venv'
        if (Test-Path -LiteralPath (Join-Path $InstallRoot '.install-complete')) {
            throw "Install path already exists: $InstallRoot. Choose another -InstallRoot to preserve existing data."
        }
        if ((Test-Path -LiteralPath $existingManifest -PathType Leaf) -and
            (Get-FileHash -LiteralPath $existingManifest -Algorithm SHA256).Hash.ToLowerInvariant() -eq $expectedManifestSha256) {
            $resumeIncomplete = $true
        } else {
            throw "Install path already exists: $InstallRoot. Choose another -InstallRoot to preserve existing data."
        }
    }
}

function Update-ProcessPath {
    $machine = [Environment]::GetEnvironmentVariable('Path', 'Machine')
    $user = [Environment]::GetEnvironmentVariable('Path', 'User')
    $env:Path = @($env:Path, $machine, $user, (Join-Path $env:USERPROFILE '.local\bin')) -join ';'
}

function Require-Tool([string]$Name, [string]$Package) {
    $command = Get-Command $Name -ErrorAction SilentlyContinue
    if ($command) { return $command }
    $winget = Get-Command winget -ErrorAction SilentlyContinue
    if (-not $winget) {
        throw "Missing $Name and Windows Package Manager (winget). Install App Installer from Microsoft, then retry."
    }
    Write-Host "Installing $Package with winget..."
    & $winget.Source install --exact --id $Package --source winget --accept-source-agreements --accept-package-agreements
    if ($LASTEXITCODE -ne 0) { throw "winget installation failed: $Package" }
    Update-ProcessPath
    $command = Get-Command $Name -ErrorAction SilentlyContinue
    if (-not $command) { throw "$Name was installed but is unavailable in this PowerShell session. Open a new PowerShell window and retry." }
    return $command
}

$uv = Require-Tool 'uv' 'astral-sh.uv'
$ffmpeg = Require-Tool 'ffmpeg' 'Gyan.FFmpeg'
$ffprobe = Get-Command ffprobe -ErrorAction SilentlyContinue
if (-not $ffprobe) { throw 'FFmpeg was found, but ffprobe is missing. Install the complete Gyan.FFmpeg package.' }
$filters = & $ffmpeg.Source -hide_banner -filters 2>&1 | Out-String
if ($LASTEXITCODE -ne 0 -or $filters -notmatch '(?m)^\s*\.\.\s+ass\s') {
    throw 'FFmpeg needs the ass subtitle filter (libass). Install a full FFmpeg build.'
}
$encoders = & $ffmpeg.Source -hide_banner -encoders 2>&1 | Out-String
if ($LASTEXITCODE -ne 0 -or $encoders -notmatch '\blibx264\b') {
    throw 'FFmpeg needs the libx264 encoder. Install a full FFmpeg build.'
}
if ($InstallOllama) {
    $ollama = Require-Tool 'ollama' 'Ollama.Ollama'
    Write-Host 'Ollama installed. Pull a model of your choice with: ollama pull <model>'
}
if ($PrerequisitesOnly) { Write-Host 'Prerequisites are ready.'; return }

$downloaded = $false
try {
    if (-not $ArchivePath) {
        if (-not $releaseUrl) {
            throw 'This source-routed candidate is not published. Supply its exact local -ArchivePath; the active installer pin is unchanged.'
        }
        $ArchivePath = Join-Path ([IO.Path]::GetTempPath()) "autoclip-v11-20260926-notice-correction-$PID.zip"
        $downloaded = $true
        try {
            Invoke-WebRequest -Uri $releaseUrl -OutFile $ArchivePath
        } catch {
            $status = $null
            if ($_.Exception.Response) { $status = [int]$_.Exception.Response.StatusCode }
            if ($status -eq 404 -or $_.Exception.Message -match '(?i)\b404\b|\bNot Found\b') {
                throw "AutoClip release asset for $releaseId is not published or could not be found at $releaseUrl. Your existing installation has not been replaced. Download error: $($_.Exception.Message)"
            }
            throw "AutoClip release asset download failed for $releaseId at $releaseUrl. Your existing installation has not been replaced. Network error: $($_.Exception.Message)"
        }
    }
    if (-not (Test-Path -LiteralPath $ArchivePath -PathType Leaf)) {
        throw "Release archive not found: $ArchivePath"
    }

    $actualArchiveSha256 = (Get-FileHash -LiteralPath $ArchivePath -Algorithm SHA256).Hash.ToLowerInvariant()
    if ($actualArchiveSha256 -ne $expectedArchiveSha256) {
        throw "Release archive SHA-256 mismatch: $actualArchiveSha256"
    }

    New-Item -ItemType Directory -Path $InstallRoot -Force | Out-Null
    Expand-Archive -LiteralPath $ArchivePath -DestinationPath $InstallRoot -Force
    $manifestPath = Join-Path $InstallRoot 'release-manifest.json'
    if ((Get-FileHash -LiteralPath $manifestPath -Algorithm SHA256).Hash.ToLowerInvariant() -ne $expectedManifestSha256) {
        throw 'Release manifest SHA-256 mismatch.'
    }
    $manifest = Get-Content -LiteralPath $manifestPath -Raw | ConvertFrom-Json
    if ($manifest.schema_version -ne 2 -or @($manifest.external_assets).Count -ne 4) {
        throw 'Unsupported or incomplete source-routed manifest.'
    }
    $expectedFiles = New-Object 'System.Collections.Generic.HashSet[string]' ([StringComparer]::OrdinalIgnoreCase)
    [void]$expectedFiles.Add('release-manifest.json')
    $rootFull = [IO.Path]::GetFullPath($InstallRoot).TrimEnd('\') + '\'
    foreach ($entry in $manifest.files) {
        $relative = [string]$entry.path
        [void]$expectedFiles.Add($relative.Replace('\', '/'))
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
    if ($resumeIncomplete) {
        foreach ($file in (Get-ChildItem -LiteralPath $InstallRoot -File -Recurse -Force)) {
            $relative = $file.FullName.Substring($rootFull.Length).Replace('\', '/')
            if (-not $expectedFiles.Contains($relative) -and
                -not $relative.StartsWith('.venv/', [StringComparison]::OrdinalIgnoreCase)) {
                throw "Unexpected file in incomplete install: $relative. Choose a new -InstallRoot."
            }
        }
    }

    . (Join-Path $InstallRoot 'upstream-assets.ps1')
    $externalWheels = Join-Path $ExternalCache 'wheels'
    $microsoft = $null
    $openblasArchive = $null
    $openblasAsset = $null
    foreach ($asset in $manifest.external_assets) {
        if ([string]$asset.filename -notmatch '^[A-Za-z0-9][A-Za-z0-9._+-]*$') {
            throw "Invalid publisher asset filename: $($asset.filename)"
        }
        $destination = if ($asset.kind -eq 'python_wheel') {
            Join-Path $externalWheels ([string]$asset.filename)
        } elseif ($asset.kind -eq 'microsoft_vc_redist_x64') {
            Join-Path $ExternalCache ([string]$asset.filename)
        } elseif ($asset.kind -eq 'openblas_archive') {
            Join-Path $ExternalCache ([string]$asset.filename)
        } else {
            throw "Unsupported publisher asset kind: $($asset.kind)"
        }
        if ($asset.kind -eq 'microsoft_vc_redist_x64') {
            $installedOpenMp = Join-Path $env:WINDIR 'System32\vcomp140.dll'
            if ((Test-Path -LiteralPath $installedOpenMp -PathType Leaf) -and
                ([version](Get-Item -LiteralPath $installedOpenMp).VersionInfo.FileVersion) -ge [version]'14.44.35211.0') {
                Write-Host 'Compatible Microsoft OpenMP runtime is already installed.'
                continue
            }
            $microsoft = $destination
        }
        if ($asset.kind -eq 'openblas_archive') {
            $openblasArchive = $destination
            $openblasAsset = $asset
        }
        Get-PinnedUpstreamAsset -Uri ([string]$asset.url) -Sha256 ([string]$asset.sha256) -Size ([long]$asset.bytes) -Destination $destination | Out-Null
    }
    if ($microsoft) {
        $process = Start-Process -FilePath $microsoft -ArgumentList '/install','/quiet','/norestart' -Wait -PassThru -Verb RunAs
        if ($process.ExitCode -ne 0 -and $process.ExitCode -ne 3010) {
            throw "Microsoft Visual C++ Redistributable installation failed: $($process.ExitCode)"
        }
    }
    $installedOpenMp = Join-Path $env:WINDIR 'System32\vcomp140.dll'
    if (-not (Test-Path -LiteralPath $installedOpenMp -PathType Leaf) -or
        ([version](Get-Item -LiteralPath $installedOpenMp).VersionInfo.FileVersion) -lt [version]'14.44.35211.0') {
        throw 'Microsoft OpenMP runtime is missing or too old after the Microsoft installer.'
    }

    $venv = Join-Path $InstallRoot '.venv'
    $venvOptions = @()
    if ($resumeIncomplete -and (Test-Path -LiteralPath $venv)) {
        $venvOptions += '--clear'
    }
    & $uv.Source venv @venvOptions --python 3.11 $venv
    if ($LASTEXITCODE -ne 0) {
        $winget = Get-Command winget -ErrorAction SilentlyContinue
        if (-not $winget) {
            throw 'Python 3.11 was unavailable to uv, and winget is missing. Install Python 3.11 from python.org, then retry.'
        }
        Write-Host 'uv could not obtain Python 3.11. Installing the official Python 3.11 package with winget...'
        & $winget.Source install --exact --id Python.Python.3.11 --source winget --accept-source-agreements --accept-package-agreements
        if ($LASTEXITCODE -ne 0) { throw 'Python 3.11 installation with winget failed.' }
        Update-ProcessPath
        & $uv.Source venv @venvOptions --python 3.11 --no-managed-python --no-python-downloads $venv
        if ($LASTEXITCODE -ne 0) { throw 'Python 3.11 is still unavailable after winget installation. Open a new PowerShell window and retry.' }
    }
    $python = Join-Path $venv 'Scripts\python.exe'
    $wheelhouse = Join-Path $InstallRoot 'wheelhouse'
    & $uv.Source pip install --python $python --no-cache --offline --no-index --find-links $wheelhouse --find-links $externalWheels 'autoclip[gpu]==0.1.0.dev0'
    if ($LASTEXITCODE -ne 0) { throw 'Offline AutoClip installation failed.' }
    if (-not $openblasArchive -or -not $openblasAsset) { throw 'Pinned OpenBLAS publisher archive is missing.' }
    $openblasDestination = Join-Path $venv 'Lib\site-packages\ctranslate2\libopenblas.dll'
    Install-PinnedZipMember -Archive $openblasArchive -Member ([string]$openblasAsset.member_path) -Sha256 ([string]$openblasAsset.member_sha256) -Destination $openblasDestination
    & $uv.Source pip check --python $python
    if ($LASTEXITCODE -ne 0) { throw 'Installed dependency check failed.' }

    [IO.File]::WriteAllText((Join-Path $InstallRoot '.install-complete'), $expectedArchiveSha256)

    Write-Host "AutoClip installed at $InstallRoot"
    Write-Host "Run: & '$(Join-Path $InstallRoot 'Start-AutoClip.ps1')'"
    Write-Host 'FFmpeg and ffprobe are ready. Configure a hosted AI provider in Settings, or install Ollama and pull a local model.'
} finally {
    if ($downloaded -and (Test-Path -LiteralPath $ArchivePath)) {
        Remove-Item -LiteralPath $ArchivePath
    }
}
