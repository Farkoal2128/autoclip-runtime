param(
    [string]$InstallRoot,
    [string]$ArchivePath,
    [string]$ExternalCache,
    [string]$NativeBuildRoot,
    [string]$MsysBash,
    [string]$CudaRoot,
    [switch]$InstallNvidiaGpu,
    [switch]$AcceptNvidiaTerms,
    [switch]$AcceptMicrosoftTerms,
    [switch]$NonInteractive,
    [switch]$OfflinePublisherCache,
    [switch]$InstallOllama,
    [switch]$PrerequisitesOnly,
    [switch]$ReleaseInfo
)

$ErrorActionPreference = 'Stop'
$releaseUrl = '' # Candidate is local until its exact asset is published and verified.
$expectedArchiveSha256 = 'de757f19171bbc57b6c26e31f7431a62240e2a4ee081167f649963bf61f29500'
$expectedManifestSha256 = 'f28fcc93e9f7d46c2f947c0d199d20b2e415de4d328eeeed961173bb5373772d'
$releaseId = 'v11-20260926-source-build-candidate-v14'

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
$publisherCache = Join-Path (Join-Path $env:LOCALAPPDATA 'AutoClip') 'cache\artifacts'
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

. (Join-Path $PSScriptRoot 'prerequisite-terms.ps1')
function Update-ProcessPath {
    $machine = [Environment]::GetEnvironmentVariable('Path', 'Machine')
    $user = [Environment]::GetEnvironmentVariable('Path', 'User')
    $env:Path = @($env:Path, $machine, $user, (Join-Path $env:USERPROFILE '.local\bin')) -join ';'
}
Update-ProcessPath

function Install-WingetPackage([string]$Package, [string]$Version, [string]$Override = '') {
    if ($Package -eq 'Microsoft.VisualStudio.2022.BuildTools') {
        Confirm-PrerequisiteTerms -Id build-tools -ReceiptRoot $publisherCache -Accepted:$AcceptMicrosoftTerms -NonInteractive:$NonInteractive
        # Let Microsoft's installer present and collect its own exact agreement.
        $Override = '--wait --add Microsoft.VisualStudio.Workload.VCTools --includeRecommended --add Microsoft.VisualStudio.Component.Windows10SDK.20348'
    }
    $winget = Get-Command winget -ErrorAction SilentlyContinue
    if (-not $winget) { throw "Windows Package Manager is required to provision $Package." }
    $arguments = @('install', '--exact', '--id', $Package, '--version', $Version, '--architecture', 'x64', '--source', 'winget', '--accept-source-agreements', '--accept-package-agreements')
    if ($Package -eq 'Microsoft.VisualStudio.2022.BuildTools') {
        $arguments = @('install', '--exact', '--id', $Package, '--version', $Version, '--architecture', 'x64', '--source', 'winget', '--accept-source-agreements', '--interactive')
    }
    if ($Override) { $arguments += @('--override', $Override) }
    & $winget.Source @arguments
    if ($LASTEXITCODE -ne 0) { throw "winget installation failed: $Package $Version (exit $LASTEXITCODE)." }
    Update-ProcessPath
}

function Require-Tool([string]$Name, [string]$Package, [string]$Version) {
    $command = Get-Command $Name -ErrorAction SilentlyContinue
    if ($command) { return $command }
    Write-Host "Installing $Package $Version with winget..."
    Install-WingetPackage $Package $Version
    $command = Get-Command $Name -ErrorAction SilentlyContinue
    if (-not $command) { throw "$Name was installed but is unavailable in this PowerShell session." }
    return $command
}

$uv = Require-Tool 'uv' 'astral-sh.uv' '0.12.19'
$ffmpeg = Require-Tool 'ffmpeg' 'Gyan.FFmpeg' '9.0.1'
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
    $ollama = Require-Tool 'ollama' 'Ollama.Ollama' '0.34.4'
    Write-Host 'Ollama installed. Pull a model of your choice with: ollama pull <model>'
}
if (-not $MsysBash) { $MsysBash = 'C:\msys64\usr\bin\bash.exe' }
if (-not (Test-Path -LiteralPath $MsysBash -PathType Leaf)) {
    if ($MsysBash -ne 'C:\msys64\usr\bin\bash.exe') { throw "Custom MSYS2 bash path is missing: $MsysBash" }
    Install-WingetPackage 'MSYS2.MSYS2' '20260611' 'in --confirm-command --accept-messages --root C:/msys64'
}
if (-not (Test-Path -LiteralPath $MsysBash -PathType Leaf)) { throw 'MSYS2 installation did not provide bash.exe.' }
$msysRoot = Split-Path -Parent (Split-Path -Parent (Split-Path -Parent $MsysBash))
$msysUcrt = Join-Path $msysRoot 'ucrt64\bin'
$env:MSYSTEM = 'UCRT64'
$env:MSYS2_PATH_TYPE = 'inherit'
$env:Path = "$msysUcrt;$(Split-Path -Parent $MsysBash);$env:Path"
$requiredMsysPackages = @('make', 'diffutils', 'pkgconf', 'mingw-w64-ucrt-x86_64-nasm')
$missingMsysPackages = @($requiredMsysPackages | Where-Object {
    & $MsysBash -lc "pacman -Q $_ >/dev/null 2>&1"
    $LASTEXITCODE -ne 0
})
if ($missingMsysPackages.Count) {
    & $MsysBash -lc 'pacman -Syu --noconfirm'
    if ($LASTEXITCODE -ne 0) { throw 'MSYS2 base package update failed.' }
    & $MsysBash -lc ('pacman -S --noconfirm --needed ' + ($requiredMsysPackages -join ' '))
    if ($LASTEXITCODE -ne 0) { throw 'Required MSYS2 build package installation failed.' }
}
foreach ($package in $requiredMsysPackages) {
    & $MsysBash -lc "pacman -Q $package >/dev/null 2>&1"
    if ($LASTEXITCODE -ne 0) { throw "MSYS2 build package is missing: $package" }
}
foreach ($probe in @('make --version', 'diff --version', 'pkg-config --version', 'nasm -v')) {
    & $MsysBash -lc $probe | Out-Null
    if ($LASTEXITCODE -ne 0) { throw "MSYS2 build tool check failed: $probe" }
}
if (-not (Test-Path -LiteralPath (Join-Path $msysUcrt 'nasm.exe'))) { throw 'MSYS2 UCRT64 NASM executable is missing.' }
$git = Get-Command git.exe -ErrorAction SilentlyContinue
if (-not $git) {
    Install-WingetPackage 'Git.Git' '2.55.0.3'
    $gitPath = Join-Path $env:ProgramFiles 'Git\cmd\git.exe'
    if (Test-Path -LiteralPath $gitPath) { $env:Path = "$(Split-Path -Parent $gitPath);$env:Path" }
    $git = Get-Command git.exe -ErrorAction SilentlyContinue
}
if (-not $git) { throw 'Git for Windows installation did not provide git.exe.' }
$gitVersion = & $git.Source --version | Out-String
if ($LASTEXITCODE -ne 0 -or $gitVersion -notmatch 'git version 2\.(4[5-9]|5[0-9])\.') { throw "Unsupported Git version: $gitVersion" }
$vswhere = Join-Path ${env:ProgramFiles(x86)} 'Microsoft Visual Studio\Installer\vswhere.exe'
$vsRoot = if (Test-Path -LiteralPath $vswhere) { & $vswhere -latest -products '*' -version '[17.0,18.0)' -requires Microsoft.VisualStudio.Component.VC.Tools.x86.x64 -property installationPath | Select-Object -First 1 }
if (-not $vsRoot) {
    Install-WingetPackage 'Microsoft.VisualStudio.2022.BuildTools' '17.14.41' '--wait --passive --add Microsoft.VisualStudio.Workload.VCTools --includeRecommended --add Microsoft.VisualStudio.Component.Windows10SDK.20348'
    if (-not (Test-Path -LiteralPath $vswhere)) { throw 'Visual Studio installer did not provide vswhere.exe.' }
    $vsRoot = & $vswhere -latest -products '*' -version '[17.0,18.0)' -requires Microsoft.VisualStudio.Component.VC.Tools.x86.x64 -property installationPath | Select-Object -First 1
}
if (-not $vsRoot) { throw 'Visual Studio 2022 C++ Build Tools and Windows SDK are unavailable after provisioning.' }
$vcvars = Join-Path $vsRoot 'VC\Auxiliary\Build\vcvars64.bat'
if (-not (Test-Path -LiteralPath $vcvars)) { throw 'Visual Studio 2022 vcvars64.bat is missing.' }
& cmd.exe /c "call `"$vcvars`" >nul && where cl.exe >nul"
if ($LASTEXITCODE -ne 0) { throw 'Visual Studio x64 compiler validation failed.' }
$sdkIncludeRoot = Join-Path ${env:ProgramFiles(x86)} 'Windows Kits\10\Include'
$sdkHeaders = @(Get-ChildItem -LiteralPath $sdkIncludeRoot -Directory -ErrorAction SilentlyContinue | Where-Object { Test-Path -LiteralPath (Join-Path $_.FullName 'um\Windows.h') -PathType Leaf })
if (-not $sdkHeaders.Count) { throw 'Windows SDK headers are unavailable after provisioning.' }
if ($InstallNvidiaGpu) {
    . (Join-Path $PSScriptRoot 'cuda-prerequisites.ps1')
    $CudaRoot = Ensure-CudaPrerequisites -CudaRoot $CudaRoot -CacheRoot $publisherCache -AcceptNvidiaTerms:$AcceptNvidiaTerms -NonInteractive:$NonInteractive
}
if ($PrerequisitesOnly) { Write-Host 'Prerequisites are ready.'; return }

$downloaded = $false
try {
    if (-not $ArchivePath) {
        if (-not $releaseUrl) {
            throw 'This source-build candidate is not published. Supply its exact local -ArchivePath; the active installer pin is unchanged.'
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
    if ($manifest.schema_version -ne 3 -or @($manifest.external_assets).Count -ne 3 -or
        @($manifest.external_assets | Where-Object { $_.kind -eq 'python_wheel' -and $_.filename -eq 'nvidia_cublas_cu12-12.4.5.8-py3-none-win_amd64.whl' }).Count -ne 1 -or
        @($manifest.external_assets | Where-Object { $_.kind -eq 'python_wheel' -and $_.filename -ne 'nvidia_cublas_cu12-12.4.5.8-py3-none-win_amd64.whl' }).Count -ne 0 -or
        -not $manifest.native_build -or @($manifest.native_build.wheel_names).Count -ne 2) {
        throw 'Unsupported or incomplete source-build manifest.'
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
                -not $relative.StartsWith('.venv/', [StringComparison]::OrdinalIgnoreCase) -and
                -not $relative.StartsWith('publisher-wheels/', [StringComparison]::OrdinalIgnoreCase) -and
                $relative -ne 'native-build-receipt.json') {
                throw "Unexpected file in incomplete install: $relative. Choose a new -InstallRoot."
            }
        }
    }

    . (Join-Path $InstallRoot 'upstream-assets.ps1')
    $wheelProfile = if ($InstallNvidiaGpu) { 'nvidia' } else { 'cpu' }
    $externalWheels = Join-Path $InstallRoot "publisher-wheels\$wheelProfile"
    & (Join-Path $InstallRoot 'Prepare-AutoClipOfflineCache.ps1') -ManifestPath $manifestPath -CacheRoot $publisherCache -StageWheelhouse $externalWheels -Offline:$OfflinePublisherCache -InstallNvidiaGpu:$InstallNvidiaGpu -AcceptNvidiaTerms:$AcceptNvidiaTerms -NonInteractive:$NonInteractive
    if (-not $?) { throw 'Publisher wheel acquisition failed.' }
    $microsoft = $null
    $openblasArchive = $null
    $openblasAsset = $null
    foreach ($asset in $manifest.external_assets) {
        if ($asset.kind -eq 'python_wheel' -and -not $InstallNvidiaGpu) { continue }
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
            Confirm-PrerequisiteTerms -Id vc-runtime -ReceiptRoot $publisherCache -Accepted:$AcceptMicrosoftTerms -NonInteractive:$NonInteractive
        }
        if ($asset.kind -eq 'openblas_archive') {
            $openblasArchive = $destination
            $openblasAsset = $asset
        }
        Get-PinnedUpstreamAsset -Uri ([string]$asset.url) -Sha256 ([string]$asset.sha256) -Size ([long]$asset.bytes) -Destination $destination | Out-Null
    }
    if ($microsoft) {
        $process = Start-Process -FilePath $microsoft -ArgumentList '/install','/norestart' -Wait -PassThru -Verb RunAs -WindowStyle Hidden
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
        & $winget.Source install --exact --id Python.Python.3.11 --version 3.11.9 --architecture x64 --source winget --accept-source-agreements --accept-package-agreements
        if ($LASTEXITCODE -ne 0) { throw 'Python 3.11 installation with winget failed.' }
        Update-ProcessPath
        & $uv.Source venv @venvOptions --python 3.11 --no-managed-python --no-python-downloads $venv
        if ($LASTEXITCODE -ne 0) { throw 'Python 3.11 is still unavailable after winget installation. Open a new PowerShell window and retry.' }
    }
    $python = Join-Path $venv 'Scripts\python.exe'
    $wheelhouse = Join-Path $InstallRoot 'wheelhouse'
    if (-not $NativeBuildRoot) {
        $buildProfile = if ($InstallNvidiaGpu) { 'nvidia' } else { 'cpu' }
        $NativeBuildRoot = Join-Path $ExternalCache "native-build-v11-20260926-$buildProfile"
    }
    & (Join-Path $InstallRoot 'build-native-from-source.ps1') -BuildRoot $NativeBuildRoot -Wheelhouse $externalWheels -OpenBlasArchive $openblasArchive -MsysBash $MsysBash -CudaRoot $CudaRoot -InstallNvidiaGpu:$InstallNvidiaGpu -Python $python -Uv $uv.Source
    if (-not $?) { throw 'Pinned PyAV/CTranslate2 source build failed.' }
    Copy-Item -LiteralPath (Join-Path $NativeBuildRoot 'native-build-receipt.json') -Destination (Join-Path $InstallRoot 'native-build-receipt.json') -Force
    $nvidiaWheelCount = if ($InstallNvidiaGpu) { @($manifest.external_assets | Where-Object { $_.kind -eq 'python_wheel' }).Count } else { 0 }
    $expectedWheelCount = @($manifest.publisher_wheels).Count + @($manifest.native_build.wheel_names).Count + $nvidiaWheelCount + @(Get-ChildItem -LiteralPath $wheelhouse -Filter '*.whl' -File).Count
    & $python (Join-Path $InstallRoot 'verify-install-wheels.py') $wheelhouse $externalWheels --count $expectedWheelCount
    if ($LASTEXITCODE -ne 0) { throw 'Wheel ZIP or RECORD integrity check failed.' }
    $autoclipPackage = if ($InstallNvidiaGpu) { 'autoclip[gpu-source]==0.1.0.dev0' } else { 'autoclip==0.1.0.dev0' }
    & $uv.Source pip install --python $python --no-cache --offline --no-index --find-links $wheelhouse --find-links $externalWheels $autoclipPackage
    if ($LASTEXITCODE -ne 0) { throw 'Offline AutoClip installation failed.' }
    if (-not $openblasArchive -or -not $openblasAsset) { throw 'Pinned OpenBLAS publisher archive is missing.' }
    $openblasDestination = Join-Path $venv 'Lib\site-packages\ctranslate2\libopenblas.dll'
    Install-PinnedZipMember -Archive $openblasArchive -Member ([string]$openblasAsset.member_path) -Sha256 ([string]$openblasAsset.member_sha256) -Destination $openblasDestination
    & $uv.Source pip check --python $python
    if ($LASTEXITCODE -ne 0) { throw 'Installed dependency check failed.' }
    & $python -c "import av, ctranslate2; assert 'int8' in ctranslate2.get_supported_compute_types('cpu')"
    if ($LASTEXITCODE -ne 0) { throw 'Locally built PyAV/CTranslate2 CPU import and capability check failed.' }
    if ($InstallNvidiaGpu) {
        $nvidiaSmi = Get-Command nvidia-smi.exe -ErrorAction SilentlyContinue
    }
    if ($InstallNvidiaGpu -and $nvidiaSmi) {
        & $nvidiaSmi.Source -L | Out-Null
        if ($LASTEXITCODE -eq 0) {
            & $python -c "from autoclip.cuda import ensure_cuda_libraries; ensure_cuda_libraries(); import ctranslate2; assert 'float16' in ctranslate2.get_supported_compute_types('cuda')"
            if ($LASTEXITCODE -ne 0) { throw 'Locally built CTranslate2 CUDA capability check failed.' }
        }
    }

    $sitePackages = Join-Path $venv 'Lib\site-packages'
    $builtNativeFiles = @(
        Get-ChildItem -LiteralPath (Join-Path $sitePackages 'av.libs') -Filter '*.dll' -File
        Get-Item -LiteralPath (Join-Path $sitePackages 'ctranslate2\ctranslate2.dll')
    )
    if ($builtNativeFiles.Count -ne 8) { throw 'Expected seven built FFmpeg DLLs and one built CTranslate2 DLL.' }
    $receiptPath = Join-Path $InstallRoot 'native-build-receipt.json'
    $receipt = Get-Content -LiteralPath $receiptPath -Raw | ConvertFrom-Json
    $receipt | Add-Member -NotePropertyName installed_files -NotePropertyValue @($builtNativeFiles | ForEach-Object {
        [ordered]@{
            path = $_.FullName.Substring(([IO.Path]::GetFullPath($InstallRoot).TrimEnd('\') + '\').Length).Replace('\', '/')
            bytes = $_.Length
            sha256 = (Get-FileHash -LiteralPath $_.FullName -Algorithm SHA256).Hash.ToLowerInvariant()
        }
    }) -Force
    $receipt | ConvertTo-Json -Depth 6 | Set-Content -LiteralPath $receiptPath -Encoding UTF8

    [IO.File]::WriteAllText((Join-Path $InstallRoot '.install-complete'), $expectedArchiveSha256)

    Write-Host "AutoClip installed at $InstallRoot"
    Write-Host "Run: & '$(Join-Path $InstallRoot 'Start-AutoClip.ps1')'"
    Write-Host 'FFmpeg and ffprobe are ready. Configure a hosted AI provider in Settings, or install Ollama and pull a local model.'
} finally {
    if ($downloaded -and (Test-Path -LiteralPath $ArchivePath)) {
        Remove-Item -LiteralPath $ArchivePath
    }
}
