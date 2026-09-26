$ErrorActionPreference = 'Stop'
$repoRoot = Split-Path -Parent (Split-Path -Parent $PSScriptRoot)
$root = Join-Path ([IO.Path]::GetTempPath()) ('autoclip-missing-release-' + [guid]::NewGuid().ToString('N'))
$installRoot = Join-Path $root 'new-runtime'
New-Item -ItemType Directory -Path $root | Out-Null
$state = Join-Path $root 'active.json'
$launcher = Join-Path $root 'Start-AutoClip.ps1'
[IO.File]::WriteAllText($state, 'previous runtime remains active')
[IO.File]::WriteAllText($launcher, 'previous launcher remains active')
function Invoke-WebRequest {
    param($Uri, $OutFile)
    [IO.File]::WriteAllText($OutFile, 'partial download')
    throw [System.Net.WebException]::new('The remote server returned an error: (404) Not Found.', $null, [System.Net.WebExceptionStatus]::ProtocolError, $null)
}
try {
    try {
        & (Join-Path $repoRoot 'install.ps1') -InstallRoot $installRoot
        throw 'Missing release unexpectedly installed.'
    } catch {
        if ($_.Exception.Message -notlike '*release asset*not published*') { throw }
    }
    $partial = Join-Path ([IO.Path]::GetTempPath()) "autoclip-v11-gpu-runtime-$PID.zip"
    if (Test-Path -LiteralPath $partial) { throw 'Partial release archive was not removed.' }
    if (Test-Path -LiteralPath $installRoot) { throw 'Missing release created an install root.' }
    if ([IO.File]::ReadAllText($state) -ne 'previous runtime remains active' -or
        [IO.File]::ReadAllText($launcher) -ne 'previous launcher remains active') {
        throw 'Missing release changed active state or launcher.'
    }
    Remove-Item Function:\Invoke-WebRequest
    function Invoke-WebRequest {
        param($Uri, $OutFile)
        throw 'simulated network outage'
    }
    try {
        & (Join-Path $repoRoot 'install.ps1') -InstallRoot $installRoot
        throw 'Network failure unexpectedly installed.'
    } catch {
        if ($_.Exception.Message -notlike '*Network error: simulated network outage*') { throw }
    }
    if (Test-Path -LiteralPath $installRoot) { throw 'Network failure created an install root.' }
    Write-Output 'Missing public release leaves the previous runtime selected and removes partial bytes.'
} finally {
    Remove-Item -LiteralPath $root -Recurse -Force
}
