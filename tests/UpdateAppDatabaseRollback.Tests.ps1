param(
    [Parameter(Mandatory = $true)][string]$InstalledRoot,
    [Parameter(Mandatory = $true)][string]$FixtureRoot
)

$ErrorActionPreference = 'Stop'
$repoRoot = Split-Path -Parent $PSScriptRoot
$updater = Join-Path $repoRoot 'update-app.ps1'
$installedFull = [IO.Path]::GetFullPath($InstalledRoot).TrimEnd('\')
if (-not (Test-Path -LiteralPath (Join-Path $installedFull '.install-complete') -PathType Leaf)) {
    throw 'Supply a completed isolated AutoClip runtime install.'
}
if (Test-Path -LiteralPath $FixtureRoot) { throw "Fixture already exists: $FixtureRoot" }
$fixture = [IO.Path]::GetFullPath($FixtureRoot)
New-Item -ItemType Directory -Path $fixture | Out-Null
$oldHome = [Environment]::GetEnvironmentVariable('AUTOCLIP_HOME', 'Process')
$userData = Join-Path $fixture 'user-data'
New-Item -ItemType Directory -Path $userData | Out-Null
try {
    $env:AUTOCLIP_HOME = $userData
    $releaseId = 'fixture-runtime'
    $runtime = Join-Path $fixture $releaseId
    New-Item -ItemType Junction -Path $runtime -Target $installedFull | Out-Null
    $manifestPath = Join-Path $runtime 'release-manifest.json'
    $python = Join-Path $runtime '.venv\Scripts\python.exe'
    if (-not (Test-Path -LiteralPath $manifestPath -PathType Leaf) -or
        -not (Test-Path -LiteralPath $python -PathType Leaf)) {
        throw 'The isolated runtime fixture is incomplete.'
    }
    $runtimeState = [ordered]@{
        schema_version = 1
        current = [ordered]@{
            release_id = $releaseId
            manifest_sha256 = (Get-FileHash -LiteralPath $manifestPath -Algorithm SHA256).Hash.ToLowerInvariant()
        }
    }
    [IO.File]::WriteAllText((Join-Path $fixture 'active.json'), ($runtimeState | ConvertTo-Json -Depth 5))
    $schema = [int](& $python -c 'from autoclip.db.schema import SCHEMA_VERSION; print(SCHEMA_VERSION)')
    if ($LASTEXITCODE -ne 0 -or $schema -lt 1) { throw 'Cannot read bundled app schema.' }
    $database = Join-Path $userData 'autoclip.db'
    & $python -c 'import sqlite3,sys; c=sqlite3.connect(sys.argv[1]); c.execute(sys.argv[2]); c.close()' $database ("PRAGMA user_version=" + ($schema + 1))
    if ($LASTEXITCODE -ne 0) { throw 'Cannot create the isolated future-schema fixture.' }

    $appStatePath = Join-Path $fixture 'app-active.json'
    $appState = [ordered]@{
        schema_version = 1
        current = [ordered]@{ app_id = 'newer-app'; required_runtime = $releaseId; wheel_sha256 = ('1' * 64) }
        previous = $null
    }
    $appStateText = $appState | ConvertTo-Json -Depth 5
    [IO.File]::WriteAllText($appStatePath, $appStateText)
    $databaseHash = (Get-FileHash -LiteralPath $database -Algorithm SHA256).Hash
    $rejected = $false
    try { & $updater -BaseRoot $fixture -Rollback -NoShortcut }
    catch {
        if ($_.Exception.Message -notlike '*database schema is newer*') { throw }
        $rejected = $true
    }
    if (-not $rejected) { throw 'Rollback removed the app layer and selected a bundled app that cannot read user data.' }
    if ([IO.File]::ReadAllText($appStatePath) -cne $appStateText) {
        throw 'Rejected app rollback changed app-active.json.'
    }
    if ((Get-FileHash -LiteralPath $database -Algorithm SHA256).Hash -ne $databaseHash) {
        throw 'Rejected app rollback changed the user database.'
    }

    $olderSite = Join-Path $fixture 'apps\older-app\site'
    $olderPackage = Join-Path $olderSite 'autoclip'
    New-Item -ItemType Directory -Path (Join-Path $olderPackage 'db') -Force | Out-Null
    [IO.File]::WriteAllText((Join-Path $olderPackage '__init__.py'), '')
    [IO.File]::WriteAllText((Join-Path $olderPackage 'app.py'), '')
    [IO.File]::WriteAllText((Join-Path $olderPackage 'paths.py'), "import os`nfrom pathlib import Path`ndef db_path(): return Path(os.environ['AUTOCLIP_HOME']) / 'autoclip.db'`n")
    [IO.File]::WriteAllText((Join-Path (Join-Path $olderPackage 'db') '__init__.py'), '')
    [IO.File]::WriteAllText((Join-Path (Join-Path $olderPackage 'db') 'schema.py'), "SCHEMA_VERSION = 1`n")
    $olderWheel = Join-Path (Join-Path $fixture 'apps\older-app') 'autoclip.whl'
    [IO.File]::WriteAllText($olderWheel, 'isolated rollback fixture')
    $appState.previous = [ordered]@{
        app_id = 'older-app'
        required_runtime = $releaseId
        wheel_sha256 = (Get-FileHash -LiteralPath $olderWheel -Algorithm SHA256).Hash.ToLowerInvariant()
    }
    $appStateText = $appState | ConvertTo-Json -Depth 5
    [IO.File]::WriteAllText($appStatePath, $appStateText)
    $rejected = $false
    try { & $updater -BaseRoot $fixture -Rollback -NoShortcut }
    catch {
        if ($_.Exception.Message -notlike '*database schema is newer*') { throw }
        $rejected = $true
    }
    if (-not $rejected) { throw 'Rollback selected an older app that cannot read user data.' }
    if ([IO.File]::ReadAllText($appStatePath) -cne $appStateText -or
        (Get-FileHash -LiteralPath $database -Algorithm SHA256).Hash -ne $databaseHash) {
        throw 'Rejected rollback to an older app changed the app state or user database.'
    }

    $appState.previous = $null
    [IO.File]::WriteAllText($appStatePath, ($appState | ConvertTo-Json -Depth 5))
    & $python -c 'import sqlite3,sys; c=sqlite3.connect(sys.argv[1]); c.execute(sys.argv[2]); c.close()' $database ("PRAGMA user_version=" + $schema)
    if ($LASTEXITCODE -ne 0) { throw 'Cannot create the compatible schema fixture.' }
    & $updater -BaseRoot $fixture -Rollback -NoShortcut
    if (Test-Path -LiteralPath $appStatePath) { throw 'Compatible rollback did not restore the bundled app.' }
    Write-Output 'App-only rollback rejects future user schemas before changing state and allows compatible bundled-app rollback.'
} finally {
    [Environment]::SetEnvironmentVariable('AUTOCLIP_HOME', $oldHome, 'Process')
    $junction = Join-Path $fixture $releaseId
    if ($releaseId -and (Test-Path -LiteralPath $junction)) { [IO.Directory]::Delete($junction) }
    if (Test-Path -LiteralPath $fixture) { Remove-Item -LiteralPath $fixture -Recurse -Force }
}
