$ErrorActionPreference = 'Stop'
$installerPath = if ($env:AUTOCLIP_INSTALL_SCRIPT) { $env:AUTOCLIP_INSTALL_SCRIPT } else { Join-Path $PSScriptRoot '..\install.ps1' }
$tokens = $null
$parseErrors = $null
$ast = [Management.Automation.Language.Parser]::ParseFile((Resolve-Path -LiteralPath $installerPath), [ref]$tokens, [ref]$parseErrors)
if ($parseErrors) { throw "Installer parse failed: $parseErrors" }

$installWinget = $ast.Find({ param($node) $node -is [Management.Automation.Language.FunctionDefinitionAst] -and $node.Name -eq 'Install-WingetPackage' }, $true)
$msysInstall = $ast.Find({ param($node) $node -is [Management.Automation.Language.IfStatementAst] -and $node.Extent.Text.Contains("pacman -Syu --noconfirm") }, $true)
$pythonFallback = @($ast.FindAll({ param($node) $node -is [Management.Automation.Language.IfStatementAst] -and $node.Extent.Text.Contains('Python.Python.3.11') }, $true) | Sort-Object { $_.Extent.Text.Length } -Descending | Select-Object -First 1)
$gpuBranch = $ast.Find({ param($node) $node -is [Management.Automation.Language.IfStatementAst] -and $node.Extent.Text.Contains('NVIDIA prerequisite acquisition is not yet qualified') }, $true)
$gpuRuntime = @($ast.FindAll({ param($node) $node -is [Management.Automation.Language.IfStatementAst] -and $node.Extent.Text.Contains('Locally built CTranslate2 CUDA capability check failed') }, $true) |
    Sort-Object { $_.Extent.Text.Length } -Descending | Select-Object -First 1)
if (-not $installWinget -or -not $msysInstall -or -not $pythonFallback.Count -or -not $gpuBranch -or -not $gpuRuntime.Count) {
    throw 'Could not locate all acquisition paths in install.ps1.'
}

$root = Join-Path ([IO.Path]::GetTempPath()) ('autoclip-no-acquisition-' + [guid]::NewGuid().ToString('N'))
New-Item -ItemType Directory -Path $root | Out-Null
$wingetMarker = Join-Path $root 'winget-called.txt'
$pacmanMarker = Join-Path $root 'pacman-install-called.txt'
try {
    [IO.File]::WriteAllText((Join-Path $root 'winget.cmd'), "@echo off`r`necho called>>`"$wingetMarker`"`r`nexit /b 0`r`n", [Text.Encoding]::ASCII)
    $oldPath = $env:Path
    $env:Path = "$root;$oldPath"
    Invoke-Expression $installWinget.Extent.Text
    function Update-ProcessPath { }
    function Test-MsysBash {
        param([string]$Mode, [string]$Command)
        if ($Command -match 'pacman -S(?:yu| --)') { [IO.File]::AppendAllText($pacmanMarker, "$Command`n") }
        $global:LASTEXITCODE = 0
    }

    $failures = @()
    $NoPrerequisiteAcquisition = $true
    try {
        Install-WingetPackage 'Git.Git' '2.55.0.3'
        $failures += 'Install-WingetPackage returned instead of rejecting acquisition.'
    } catch {
        if ($_.Exception.Message -notmatch 'Missing prerequisite') { $failures += "Unexpected winget guard error: $($_.Exception.Message)" }
    }
    if (Test-Path -LiteralPath $wingetMarker) { $failures += 'winget was called with -NoPrerequisiteAcquisition.' }

    $missingMsysPackages = @('make', 'diffutils')
    $MsysBash = 'Test-MsysBash'
    try {
        Invoke-Expression $msysInstall.Extent.Text
        $failures += 'MSYS2 package update returned instead of rejecting acquisition.'
    } catch {
        if ($_.Exception.Message -notmatch 'Missing MSYS2 packages') { $failures += "Unexpected MSYS2 guard error: $($_.Exception.Message)" }
    }
    if (Test-Path -LiteralPath $pacmanMarker) { $failures += 'pacman package acquisition ran with -NoPrerequisiteAcquisition.' }

    $LASTEXITCODE = 1
    try {
        Invoke-Expression $pythonFallback[0].Extent.Text
        $failures += 'Python fallback returned instead of rejecting acquisition.'
    } catch {
        if ($_.Exception.Message -notmatch 'Python 3.11 is unavailable without prerequisite acquisition') { $failures += "Unexpected Python fallback error: $($_.Exception.Message)" }
    }
    if (Test-Path -LiteralPath $wingetMarker) { $failures += 'Python winget fallback ran with -NoPrerequisiteAcquisition.' }

    $gpuMarker = Join-Path $root 'gpu-called.txt'
    function Ensure-CudaPrerequisites {
        param($CudaRoot, $CacheRoot, $AcceptNvidiaTerms, $NonInteractive)
        [IO.File]::WriteAllText($gpuMarker, 'called')
        return 'C:\verified-cuda'
    }
    $InstallNvidiaGpu = $true
    $AllowPinnedNvidiaAcquisition = $false
    $publisherCache = $root
    try {
        Invoke-Expression $gpuBranch.Extent.Text
        $failures += 'NVIDIA acquisition ran without explicit wizard opt-in.'
    } catch {
        if ($_.Exception.Message -notmatch 'NVIDIA prerequisite acquisition') { $failures += "Unexpected NVIDIA guard error: $($_.Exception.Message)" }
    }
    if (Test-Path -LiteralPath $gpuMarker) { $failures += 'NVIDIA acquisition ran without opt-in.' }
    $AllowPinnedNvidiaAcquisition = $true
    Invoke-Expression $gpuBranch.Extent.Text
    if (-not (Test-Path -LiteralPath $gpuMarker) -or $CudaRoot -ne 'C:\verified-cuda') {
        $failures += 'Explicit optional NVIDIA route did not invoke the pinned prerequisite helper.'
    }
    $nvidiaSmi = $null
    try {
        Invoke-Expression $gpuRuntime[0].Extent.Text
        $failures += 'NVIDIA installation would complete without GPU hardware.'
    } catch {
        if ($_.Exception.Message -notmatch 'NVIDIA GPU') { $failures += "Unexpected missing-GPU error: $($_.Exception.Message)" }
    }

    $env:Path = $oldPath
    if ($failures.Count) { throw ($failures -join [Environment]::NewLine) }
    Write-Output 'NoPrerequisiteAcquisition blocked winget, pacman, Python fallback, and ungated NVIDIA; explicit NVIDIA route invoked pinned helper.'
} finally {
    if ($oldPath) { $env:Path = $oldPath }
    if (Test-Path -LiteralPath $root) { Remove-Item -LiteralPath $root -Recurse -Force }
}
