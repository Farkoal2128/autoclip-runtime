# CUDA build inputs for the pinned CTranslate2 4.8.2 Windows source build.
$script:CudaInstallerUrl = 'https://developer.download.nvidia.com/compute/cuda/12.8.0/local_installers/cuda_12.8.0_571.96_windows.exe'
$script:CudaInstallerName = 'cuda_12.8.0_571.96_windows.exe'
$script:CudaInstallerSize = 3383388152
$script:CudaInstallerSha256 = '540522788653606ace80869b65ac3acf8a13bea40545bd2f2af69393b5025a80'
$script:CudaComponents = @(
    'nvcc_12.8', 'cudart_12.8', 'cublas_12.8', 'cublas_dev_12.8',
    'nvrtc_12.8', 'nvrtc_dev_12.8', 'nvfatbin_12.8', 'nvjitlink_12.8',
    'curand_12.8', 'curand_dev_12.8'
)
$script:CudaRequiredFiles = @(
    'bin\nvcc.exe', 'include\cuda_runtime.h', 'include\cublas_v2.h',
    'include\curand_kernel.h', 'lib\x64\cudart_static.lib',
    'lib\x64\cudadevrt.lib', 'lib\x64\cublas.lib', 'lib\x64\curand.lib'
)

function Test-CudaBuildRoot([string]$Root, [scriptblock]$VersionScript) {
    if (-not $Root -or -not (Test-Path -LiteralPath $Root -PathType Container)) { return $false }
    foreach ($relative in $script:CudaRequiredFiles) {
        if (-not (Test-Path -LiteralPath (Join-Path $Root $relative) -PathType Leaf)) { return $false }
    }
    if ($VersionScript) { $version = & $VersionScript (Join-Path $Root 'bin\nvcc.exe') }
    else {
        $version = & (Join-Path $Root 'bin\nvcc.exe') --version | Out-String
        if ($LASTEXITCODE -ne 0) { return $false }
    }
    return ($version -match 'release 12\.8,')
}

function Ensure-CudaPrerequisites {
    param(
        [string]$CudaRoot,
        [Parameter(Mandatory)][string]$CacheRoot,
        [scriptblock]$DownloadScript,
        [scriptblock]$InstallScript,
        [scriptblock]$ProbeScript,
        [scriptblock]$BootIdScript,
        [string]$StandardRoot = (Join-Path $env:ProgramFiles 'NVIDIA GPU Computing Toolkit\CUDA\v12.8'),
        [long]$InstallerSize = $script:CudaInstallerSize,
        [string]$InstallerSha256 = $script:CudaInstallerSha256
    )
    if (-not $ProbeScript) { $ProbeScript = { param($path) Test-CudaBuildRoot $path } }
    if (-not $BootIdScript) {
        $BootIdScript = { (Get-CimInstance Win32_OperatingSystem).LastBootUpTime.ToUniversalTime().ToString('o') }
    }
    $standardRoot = $StandardRoot
    if (-not $CudaRoot) { $CudaRoot = $env:CUDA_PATH_V12_8 }
    if (-not $CudaRoot) { $CudaRoot = $standardRoot }
    $pending = Join-Path $CacheRoot 'cuda-12.8-install-pending.json'
    if (Test-Path -LiteralPath $pending) {
        $state = Get-Content -LiteralPath $pending -Raw | ConvertFrom-Json
        if ($state.state -eq 'reboot_required' -and $state.boot_id -eq (& $BootIdScript)) {
            throw 'CUDA 12.8 installation requires a reboot before AutoClip can continue. Reboot, then rerun the same installer command.'
        }
    }
    if (& $ProbeScript $CudaRoot) {
        if (Test-Path -LiteralPath $pending) { Remove-Item -LiteralPath $pending -Force }
        $env:CUDA_PATH = $CudaRoot
        $env:Path = "$(Join-Path $CudaRoot 'bin');$env:Path"
        return $CudaRoot
    }
    if ($CudaRoot -ne $standardRoot) {
        throw "Selected CUDA root is incomplete or not 12.8: $CudaRoot. Automatic provisioning uses $standardRoot."
    }
    if (-not $InstallScript) {
        $InstallScript = {
            param($file, $arguments)
            $process = Start-Process -FilePath $file -ArgumentList $arguments -Verb RunAs -WindowStyle Hidden -Wait -PassThru
            return $process.ExitCode
        }
    }
    if (-not (Get-Command Get-PinnedUpstreamAsset -ErrorAction SilentlyContinue)) {
        . (Join-Path $PSScriptRoot 'upstream-assets.ps1')
    }
    $destination = Join-Path (Join-Path (Join-Path $CacheRoot 'sha256') $InstallerSha256.ToLowerInvariant()) $script:CudaInstallerName
    $installer = Get-PinnedUpstreamAsset -Uri $script:CudaInstallerUrl -Sha256 $InstallerSha256 -Size $InstallerSize -Destination $destination -DownloadScript $DownloadScript
    New-Item -ItemType Directory -Path $CacheRoot -Force | Out-Null
    [IO.File]::WriteAllText($pending, '{"version":"12.8.0","state":"installing"}')
    $arguments = @('-s', '-n') + $script:CudaComponents
    $exitCode = & $InstallScript $installer $arguments
    if ($exitCode -eq 3010) {
        @{ version = '12.8.0'; state = 'reboot_required'; boot_id = (& $BootIdScript) } |
            ConvertTo-Json -Compress | Set-Content -LiteralPath $pending -Encoding UTF8
        throw 'CUDA 12.8 components installed but Windows requires a reboot. Reboot, then rerun the same AutoClip installer command.'
    }
    if ($exitCode -ne 0) {
        [IO.File]::WriteAllText($pending, ('{"version":"12.8.0","state":"failed","exit_code":' + $exitCode + '}'))
        throw "NVIDIA CUDA 12.8 component installer failed with exit code $exitCode."
    }
    $env:CUDA_PATH = $CudaRoot
    $env:Path = "$(Join-Path $CudaRoot 'bin');$env:Path"
    if (-not (& $ProbeScript $CudaRoot)) {
        throw 'CUDA 12.8 installation completed but required compiler, headers, or libraries are missing.'
    }
    Remove-Item -LiteralPath $pending -Force
    return $CudaRoot
}
