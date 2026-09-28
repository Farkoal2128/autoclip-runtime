$ErrorActionPreference = 'Stop'
. (Join-Path $PSScriptRoot '..\cuda-prerequisites.ps1')
# Provisioning behavior fixture: consent is tested independently; no real vendor acceptance.
function Confirm-PrerequisiteTerms { }

function Assert([bool]$Condition, [string]$Message) {
    if (-not $Condition) { throw $Message }
}

$root = Join-Path $env:TEMP ('autoclip-cuda-test-' + [guid]::NewGuid().ToString('N'))
try {
    New-Item -ItemType Directory -Path $root | Out-Null
    foreach ($relative in $CudaRequiredFiles) {
        $path = Join-Path $root $relative
        New-Item -ItemType Directory -Path (Split-Path -Parent $path) -Force | Out-Null
        [IO.File]::WriteAllText($path, 'fixture')
    }
    Assert (Test-CudaBuildRoot $root { 'Cuda compilation tools, release 12.8, V12.8.61' }) 'Complete CUDA 12.8 build root must validate.'
    Assert (-not (Test-CudaBuildRoot $root { 'Cuda compilation tools, release 12.7, V12.7.1' })) 'Wrong CUDA minor must be rejected.'
    Remove-Item -LiteralPath (Join-Path $root 'include\curand_kernel.h')
    Assert (-not (Test-CudaBuildRoot $root { 'Cuda compilation tools, release 12.8, V12.8.61' })) 'Missing cuRAND development header must be rejected.'
    [IO.File]::WriteAllText((Join-Path $root 'include\curand_kernel.h'), 'fixture')
    Remove-Item -LiteralPath (Join-Path $root 'bin\nvcc.exe')
    Assert (-not (Test-CudaBuildRoot $root { 'Cuda compilation tools, release 12.8, V12.8.61' })) 'Missing nvcc must be rejected.'
    $calls = [Collections.Generic.List[string]]::new()
    $sentinel = Join-Path $root 'ready'
    $download = { param($url, $path) $calls.Add('download') | Out-Null; [IO.File]::WriteAllBytes($path, [byte[]](1,2,3)) }
    $launch = { param($file, $arguments) $calls.Add('install') | Out-Null; Assert ($arguments -contains 'curand_dev_12.8' -and $arguments -notcontains 'Display.Driver') 'Selected CUDA components must include cuRAND development and exclude driver.'; [IO.File]::WriteAllText($sentinel, 'yes'); return 0 }
    $probe = { param($path) return (Test-Path -LiteralPath $sentinel) }
    $result = Ensure-CudaPrerequisites -CudaRoot $root -StandardRoot $root -CacheRoot $root -DownloadScript $download -InstallScript $launch -ProbeScript $probe -InstallerSize 3 -InstallerSha256 '039058c6f2c0cb492c533b0a4d14ef77cc0f78abccced5287d84a1a2011cfb81'
    Assert ($calls.Contains('download') -and $calls.Contains('install')) 'Missing CUDA must invoke pinned acquisition and installation.'
    Assert ($result -eq $root) 'CUDA root must be returned only after validation.'
    Assert ($env:CUDA_PATH -eq $root -and $env:Path.StartsWith((Join-Path $root 'bin') + ';')) 'CUDA environment must refresh before build.'
    $calls.Clear()
    $result = Ensure-CudaPrerequisites -CudaRoot $root -StandardRoot $root -CacheRoot $root -DownloadScript $download -InstallScript $launch -ProbeScript $probe
    Assert ($result -eq $root -and $calls.Count -eq 0) 'Valid CUDA must not reinstall.'
    Remove-Item -LiteralPath $sentinel
    $failedInstall = { param($file, $arguments) return 7 }
    try {
        Ensure-CudaPrerequisites -CudaRoot $root -StandardRoot $root -CacheRoot $root -DownloadScript $download -InstallScript $failedInstall -ProbeScript $probe -InstallerSize 3 -InstallerSha256 '039058c6f2c0cb492c533b0a4d14ef77cc0f78abccced5287d84a1a2011cfb81' | Out-Null
        throw 'Expected installer failure.'
    } catch {
        Assert ($_.Exception.Message -match 'exit code 7') 'NVIDIA installer failure must surface its exit code.'
    }
    $rebootInstall = { param($file, $arguments) return 3010 }
    try {
        Ensure-CudaPrerequisites -CudaRoot $root -StandardRoot $root -CacheRoot $root -DownloadScript $download -InstallScript $rebootInstall -ProbeScript $probe -BootIdScript { 'boot-one' } -InstallerSize 3 -InstallerSha256 '039058c6f2c0cb492c533b0a4d14ef77cc0f78abccced5287d84a1a2011cfb81' | Out-Null
        throw 'Expected reboot requirement.'
    } catch {
        Assert ($_.Exception.Message -match 'requires a reboot') 'Reboot-required must stop before build.'
        $pending = Get-Content -LiteralPath (Join-Path $root 'cuda-12.8-install-pending.json') -Raw | ConvertFrom-Json
        Assert ($pending.state -eq 'reboot_required') 'Reboot state must persist.'
    }
    [IO.File]::WriteAllText($sentinel, 'yes')
    try {
        Ensure-CudaPrerequisites -CudaRoot $root -StandardRoot $root -CacheRoot $root -ProbeScript $probe -BootIdScript { 'boot-one' } | Out-Null
        throw 'Expected reboot guard.'
    } catch {
        Assert ($_.Exception.Message -match 'requires a reboot') 'Same-boot retry must not continue.'
    }
    $result = Ensure-CudaPrerequisites -CudaRoot $root -StandardRoot $root -CacheRoot $root -ProbeScript $probe -BootIdScript { 'boot-two' }
    Assert ($result -eq $root -and -not (Test-Path (Join-Path $root 'cuda-12.8-install-pending.json'))) 'Post-reboot valid CUDA must clear pending state.'
    Remove-Item -LiteralPath $sentinel
    $other = Join-Path $root 'custom'
    New-Item -ItemType Directory -Path $other | Out-Null
    try {
        Ensure-CudaPrerequisites -CudaRoot $other -StandardRoot $root -CacheRoot $root -ProbeScript $probe | Out-Null
        throw 'Expected custom root validation failure.'
    } catch {
        Assert ($_.Exception.Message -match 'incomplete or not 12.8') 'Invalid custom CUDA root must be rejected.'
    }
} finally {
    if (Test-Path $root) { Remove-Item -LiteralPath $root -Recurse -Force }
}
