$ErrorActionPreference = 'Stop'
. (Join-Path (Split-Path -Parent $PSScriptRoot) '..\native-wheel-cache.ps1')

$scratch = Join-Path $env:TEMP ('autoclip-native-cache-test-' + [guid]::NewGuid().ToString('N'))
$buildRoot = Join-Path $scratch 'build'
$firstWheelhouse = Join-Path $scratch 'first'
$secondWheelhouse = Join-Path $scratch 'second'
New-Item -ItemType Directory -Path $buildRoot, $firstWheelhouse, $secondWheelhouse -Force | Out-Null
try {
    $name = 'av-18.1.0-cp311-abi3-win_amd64.whl'
    $wheelPath = Join-Path $firstWheelhouse $name
    [IO.File]::WriteAllBytes($wheelPath, [byte[]](1, 2, 3, 4))
    $wheel = [pscustomobject]@{
        filename = $name
        bytes = 4
        sha256 = (Get-FileHash -LiteralPath $wheelPath -Algorithm SHA256).Hash.ToLowerInvariant()
    }
    Save-NativeWheelCache -BuildRoot $buildRoot -Wheelhouse $firstWheelhouse -Wheels @($wheel)
    Restore-NativeWheelCache -BuildRoot $buildRoot -Wheelhouse $secondWheelhouse -Wheels @($wheel)
    if ((Get-FileHash -LiteralPath (Join-Path $secondWheelhouse $name) -Algorithm SHA256).Hash.ToLowerInvariant() -ne $wheel.sha256) {
        throw 'A new install root did not receive the exact cached native wheel.'
    }
    [IO.File]::WriteAllBytes((Join-Path $buildRoot "native-wheels\$name"), [byte[]](9, 9, 9, 9))
    $rejected = $false
    try { Restore-NativeWheelCache -BuildRoot $buildRoot -Wheelhouse $secondWheelhouse -Wheels @($wheel) }
    catch { $rejected = $_.Exception.Message -match 'Cached native wheel differs' }
    if (-not $rejected) { throw 'Tampered cached native wheel was accepted.' }
    Write-Host 'Native wheels restore to a second wheelhouse and reject tampering.'
} finally {
    Remove-Item -LiteralPath $scratch -Recurse -Force
}
