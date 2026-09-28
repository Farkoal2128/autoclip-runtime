$ErrorActionPreference = 'Stop'
$repoRoot = Split-Path -Parent (Split-Path -Parent $PSScriptRoot)
$installer = Get-Content -LiteralPath (Join-Path $repoRoot 'install-source-build.ps1') -Raw
$tokens = $null
$errors = $null
$ast = [System.Management.Automation.Language.Parser]::ParseInput($installer, [ref]$tokens, [ref]$errors)
if ($errors) { throw $errors[0] }
if ($installer -notmatch '(?s)function Update-ProcessPath\s*\{.*?\}\s*Update-ProcessPath\s*function Install-WingetPackage') {
    throw 'Installer must refresh machine and user PATH before probing existing tools.'
}

# Exercise package selection without mutating the test machine.
$helper = $ast.Find({ param($node) $node -is [System.Management.Automation.Language.FunctionDefinitionAst] -and $node.Name -eq 'Install-WingetPackage' }, $true)
if (-not $helper) { throw 'Installer package provisioning helper is absent.' }
$fixture = Join-Path ([IO.Path]::GetTempPath()) ('autoclip-winget-fixture-' + [guid]::NewGuid().ToString('N'))
$oldPath = $env:Path
try {
    New-Item -ItemType Directory -Path $fixture | Out-Null
    $record = Join-Path $fixture 'winget-args.txt'
    [IO.File]::WriteAllText((Join-Path $fixture 'winget.cmd'), "@echo off`r`necho %* > `"$record`"`r`nexit /b 0`r`n")
    $env:Path = "$fixture;$oldPath"
    function Update-ProcessPath { }
    Invoke-Expression $helper.Extent.Text
    Install-WingetPackage 'Git.Git' '2.55.0.3'
    $arguments = Get-Content -LiteralPath $record -Raw
    foreach ($required in @('--exact', '--id Git.Git', '--version 2.55.0.3', '--architecture x64', '--source winget')) {
        if (-not $arguments.Contains($required)) { throw "Pinned winget argument missing: $required" }
    }
    if ($installer -notmatch 'if \(\$InstallNvidiaGpu\) \{\s*\. \(Join-Path \$PSScriptRoot ''cuda-prerequisites.ps1''\)\s*\$CudaRoot = Ensure-CudaPrerequisites') {
        throw 'CUDA toolkit preflight is no longer gated by the NVIDIA switch.'
    }
    Write-Output 'Pinned package invocation and optional NVIDIA prerequisite guard passed.'
} finally {
    $env:Path = $oldPath
    if (Test-Path -LiteralPath $fixture) { Remove-Item -LiteralPath $fixture -Recurse -Force }
}

$builder = Get-Content -LiteralPath (Join-Path $repoRoot 'build-native-from-source.ps1') -Raw
$builderAst = [System.Management.Automation.Language.Parser]::ParseInput($builder, [ref]$tokens, [ref]$errors)
if ($errors) { throw $errors[0] }
$checked = $builderAst.Find({ param($node) $node -is [System.Management.Automation.Language.FunctionDefinitionAst] -and $node.Name -eq 'Invoke-Checked' }, $true)
if (-not $checked) { throw 'Native build checked command helper is absent.' }
Invoke-Expression $checked.Extent.Text
$returned = @(Invoke-Checked 'cmd.exe' @('/c', 'echo', 'git-progress'))
if ($returned.Count) { throw 'Checked command progress contaminated a source path return value.' }
Write-Output 'Native checked command keeps progress out of return values.'
