$ErrorActionPreference = 'Stop'
$repo = Split-Path -Parent (Split-Path -Parent $PSScriptRoot)
$workflow = [IO.File]::ReadAllText((Join-Path $repo '.github/workflows/release-check.yml'))

function Get-Job([string]$Name) {
    $pattern = '(?ms)^  ' + [regex]::Escape($Name) + ':\r?\n(?<body>.*?)(?=^  [a-z][a-z0-9-]*:|\z)'
    $match = [regex]::Match($workflow, $pattern)
    if (-not $match.Success) { throw "Missing release workflow job: $Name" }
    return $match.Groups['body'].Value
}

$v11 = Get-Job 'windows-release-smoke'
if ($v11 -notmatch "refs/tags/v0\.1\.0-dev0-windows-v11-20260926-notice-correction") {
    throw 'V11 install/GPU/updater smoke is not restricted to the V11 tag.'
}
if ($v11 -notmatch 'GpuRuntime.Tests.ps1' -or $v11 -notmatch 'Update.Tests.ps1') {
    throw 'The scoped V11 smoke lost its historical regression checks.'
}

$v40 = Get-Job 'windows-source-build-release-identity'
if ($v40 -notmatch 'refs/tags/v0\.1\.0-dev0-windows-source-v40-20260928' -or
    $v40 -notmatch 'verify-public-release.ps1' -or
    $v40 -notmatch 'SourceBuildPublicPin.Tests.ps1') {
    throw 'V40 release does not verify its exact public archive, manifest and pin.'
}
if ($v40 -match 'GpuRuntime.Tests.ps1|Update.Tests.ps1|install.ps1 -InstallRoot') {
    throw 'V40 metadata check incorrectly claims a remote install or V11 GPU/updater validation.'
}

Write-Output 'Release workflow routes V11 smoke to V11 and v40 public identity to v40.'
