$ErrorActionPreference = 'Stop'
$repoRoot = Split-Path -Parent (Split-Path -Parent $PSScriptRoot)
$fixture = Join-Path ([IO.Path]::GetTempPath()) ('autoclip-optional-nvidia-' + [guid]::NewGuid().ToString('N'))
$oldPath = $env:Path
try {
    New-Item -ItemType Directory -Path $fixture | Out-Null
    foreach ($tool in @('uv', 'ffprobe', 'git')) {
        [IO.File]::WriteAllText((Join-Path $fixture "$tool.cmd"), "@echo off`r`nexit /b 0`r`n")
    }
    [IO.File]::WriteAllText((Join-Path $fixture 'ffmpeg.cmd'), "@echo off`r`necho .. ass`r`necho libx264`r`nexit /b 0`r`n")
    $bash = Join-Path $fixture 'bash.exe'
    [IO.File]::WriteAllBytes($bash, [byte[]]@())
    $env:Path = "$fixture;$oldPath"

    & (Join-Path $repoRoot 'install-source-build.ps1') -PrerequisitesOnly -MsysBash $bash -CudaRoot (Join-Path $fixture 'missing-cuda')
    try {
        & (Join-Path $repoRoot 'install-source-build.ps1') -PrerequisitesOnly -MsysBash $bash -InstallNvidiaGpu -CudaRoot (Join-Path $fixture 'missing-cuda')
        throw 'NVIDIA prerequisite check unexpectedly succeeded without CUDA.'
    } catch {
        if ($_.Exception.Message -notlike 'NVIDIA GPU install requires CUDA 12.8 toolkit*') { throw }
    }
    Write-Output 'CPU prerequisites passed without CUDA; NVIDIA mode required CUDA.'
} finally {
    $env:Path = $oldPath
    if (Test-Path -LiteralPath $fixture) { Remove-Item -LiteralPath $fixture -Recurse -Force }
}
