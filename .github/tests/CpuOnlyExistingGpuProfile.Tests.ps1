param(
    [Parameter(Mandatory = $true)][string]$BaseRoot,
    [Parameter(Mandatory = $true)][string]$InstallerPath
)

$ErrorActionPreference = 'Stop'
$repoRoot = Split-Path -Parent (Split-Path -Parent $PSScriptRoot)
$statePath = Join-Path $BaseRoot 'active.json'
$beforeText = Get-Content -LiteralPath $statePath -Raw
$before = $beforeText | ConvertFrom-Json
$releaseId = [string]$before.current.release_id
$receiptPath = Join-Path (Join-Path $BaseRoot $releaseId) 'native-build-receipt.json'
$receipt = Get-Content -LiteralPath $receiptPath -Raw | ConvertFrom-Json
if ([string]$receipt.profile -ne 'nvidia') { throw 'Fixture must select an NVIDIA source build.' }

try {
    try {
        & (Join-Path $repoRoot 'update.ps1') -BaseRoot $BaseRoot -InstallerPath $InstallerPath -CpuOnly -NoShortcut
        throw 'Updater selected an existing NVIDIA runtime for an explicit CPU request.'
    } catch {
        if ($_.Exception.Message -notlike '*profile*') { throw }
    }
    $after = Get-Content -LiteralPath $statePath -Raw | ConvertFrom-Json
    if ($after.current.release_id -ne $releaseId -or $after.current.manifest_sha256 -ne $before.current.manifest_sha256) {
        throw 'Profile mismatch changed the active runtime.'
    }
    Write-Output 'Updater rejected the existing NVIDIA runtime for an explicit CPU request.'
} finally {
    $now = Get-Content -LiteralPath $statePath -Raw | ConvertFrom-Json
    if ($now.current.release_id -ne $releaseId) {
        [IO.File]::WriteAllText($statePath, $beforeText)
    }
}
