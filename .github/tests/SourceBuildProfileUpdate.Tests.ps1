param([Parameter(Mandatory = $true)][string]$BaseRoot)

$ErrorActionPreference = 'Stop'
$repoRoot = Split-Path -Parent (Split-Path -Parent $PSScriptRoot)
$state = Get-Content -LiteralPath (Join-Path $BaseRoot 'active.json') -Raw | ConvertFrom-Json
$receiptPath = Join-Path (Join-Path $BaseRoot $state.current.release_id) 'native-build-receipt.json'
$receipt = Get-Content -LiteralPath $receiptPath -Raw | ConvertFrom-Json
if ($receipt.profile -ne 'nvidia') { throw 'Fixture must have an active NVIDIA source build.' }

$fixture = Join-Path ([IO.Path]::GetTempPath()) ('autoclip-profile-update-' + [guid]::NewGuid().ToString('N'))
New-Item -ItemType Directory -Path $fixture | Out-Null
try {
    $installer = Join-Path $fixture 'installer.ps1'
    $marker = Join-Path $fixture 'received-gpu-flag.txt'
    [IO.File]::WriteAllText($installer, @'
param([switch]$ReleaseInfo, [switch]$PrerequisitesOnly, [string]$InstallRoot, [switch]$InstallNvidiaGpu)
if ($ReleaseInfo) {
    [pscustomobject]@{ ReleaseId='fixture-next-source-build'; ArchiveSha256=('a'*64); ManifestSha256=('b'*64) }
    return
}
[IO.File]::WriteAllText($env:AUTOCLIP_PROFILE_TEST_MARKER, [string][bool]$InstallNvidiaGpu)
throw 'Fixture stopped before installation.'
'@)
    $env:AUTOCLIP_PROFILE_TEST_MARKER = $marker
    try {
        & (Join-Path $repoRoot 'update.ps1') -BaseRoot $BaseRoot -InstallerPath $installer -NoShortcut
        throw 'Updater unexpectedly succeeded.'
    } catch {
        if ($_.Exception.Message -ne 'Fixture stopped before installation.') { throw }
    }
    if ((Get-Content -LiteralPath $marker -Raw).Trim() -ne 'True') {
        throw 'Updater did not preserve the active NVIDIA profile for the next source build.'
    }
    try {
        & (Join-Path $repoRoot 'update.ps1') -BaseRoot $BaseRoot -InstallerPath $installer -CpuOnly -NoShortcut
        throw 'Updater unexpectedly succeeded.'
    } catch {
        if ($_.Exception.Message -ne 'Fixture stopped before installation.') { throw }
    }
    if ((Get-Content -LiteralPath $marker -Raw).Trim() -ne 'False') {
        throw 'Explicit CPU selection did not override the active NVIDIA profile.'
    }
    $after = Get-Content -LiteralPath (Join-Path $BaseRoot 'active.json') -Raw | ConvertFrom-Json
    if ($after.current.release_id -ne $state.current.release_id) { throw 'Failed update changed the active release.' }
    Write-Output 'Updater preserved the NVIDIA profile, honored CPU override, and kept the active release.'
} finally {
    Remove-Item Env:AUTOCLIP_PROFILE_TEST_MARKER -ErrorAction SilentlyContinue
    Remove-Item -LiteralPath $fixture -Recurse -Force
}
