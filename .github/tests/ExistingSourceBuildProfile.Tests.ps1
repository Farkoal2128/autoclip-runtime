param(
    [Parameter(Mandatory = $true)][string]$BaseRoot,
    [Parameter(Mandatory = $true)][string]$InstallerPath
)

$ErrorActionPreference = 'Stop'
$repoRoot = Split-Path -Parent (Split-Path -Parent $PSScriptRoot)
$statePath = Join-Path $BaseRoot 'active.json'
$beforeText = Get-Content -LiteralPath $statePath -Raw
$before = $beforeText | ConvertFrom-Json
if ($before.current.release_id -notlike '*notice-correction*') { throw 'Fixture must select corrected V11.' }

try {
    try {
        & (Join-Path $repoRoot 'update.ps1') -BaseRoot $BaseRoot -InstallerPath $InstallerPath -InstallNvidiaGpu -NoShortcut
        throw 'Updater selected an existing CPU runtime for an NVIDIA request.'
    } catch {
        if ($_.Exception.Message -notlike '*profile*') { throw }
    }
    $after = Get-Content -LiteralPath $statePath -Raw | ConvertFrom-Json
    if ($after.current.release_id -ne $before.current.release_id) { throw 'Profile mismatch changed the active runtime.' }
    Write-Output 'Updater rejected the existing CPU runtime for an NVIDIA request.'
} finally {
    $now = Get-Content -LiteralPath $statePath -Raw | ConvertFrom-Json
    if ($now.current.release_id -ne $before.current.release_id) {
        [IO.File]::WriteAllText($statePath, $beforeText)
    }
}
