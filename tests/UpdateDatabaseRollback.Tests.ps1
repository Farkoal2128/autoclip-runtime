param(
    [Parameter(Mandatory)][string]$InstalledRoot,
    [Parameter(Mandatory)][string]$FixtureRoot
)

$ErrorActionPreference = 'Stop'
$installed = [IO.Path]::GetFullPath($InstalledRoot)
$fixture = [IO.Path]::GetFullPath($FixtureRoot)
if (-not (Test-Path -LiteralPath (Join-Path $installed '.venv\Scripts\python.exe') -PathType Leaf)) {
    throw 'Supply a completed installed runtime.'
}
if (Test-Path -LiteralPath $fixture) { throw 'Use a new fixture directory.' }
$repoRoot = Split-Path -Parent $PSScriptRoot
$updater = Join-Path $repoRoot 'update.ps1'
$python = Join-Path $installed '.venv\Scripts\python.exe'
$manifestHash = (Get-FileHash -LiteralPath (Join-Path $installed 'release-manifest.json') -Algorithm SHA256).Hash.ToLowerInvariant()
$schema = [int](& $python -c 'from autoclip.db.schema import SCHEMA_VERSION; print(SCHEMA_VERSION)')
if ($LASTEXITCODE -ne 0 -or $schema -lt 1) { throw 'Cannot read installed app schema.' }

New-Item -ItemType Directory -Path $fixture | Out-Null
New-Item -ItemType Junction -Path (Join-Path $fixture 'current-runtime') -Target $installed | Out-Null
New-Item -ItemType Junction -Path (Join-Path $fixture 'previous-runtime') -Target $installed | Out-Null
$statePath = Join-Path $fixture 'active.json'
$initialState = @{ schema_version = 1
    current = @{ release_id = 'current-runtime'; manifest_sha256 = $manifestHash; archive_sha256 = 'a' * 64 }
    previous = @{ release_id = 'previous-runtime'; manifest_sha256 = $manifestHash; archive_sha256 = 'a' * 64 }
} | ConvertTo-Json -Depth 5
$oldHome = [Environment]::GetEnvironmentVariable('AUTOCLIP_HOME', 'Process')
try {
    foreach ($dbName in @('autoclip.db', 'clipforge.db')) {
        $fixtureHome = Join-Path $fixture ('newer-' + $dbName)
        New-Item -ItemType Directory -Path $fixtureHome | Out-Null
        $database = Join-Path $fixtureHome $dbName
        & $python -c 'import sqlite3,sys; c=sqlite3.connect(sys.argv[1]); c.execute(sys.argv[2]); c.close()' $database ("PRAGMA user_version=" + ($schema + 1))
        if ($LASTEXITCODE -ne 0) { throw 'Could not create the test database.' }
        [IO.File]::WriteAllText($statePath, $initialState)
        $stateHash = (Get-FileHash -LiteralPath $statePath -Algorithm SHA256).Hash
        $dbHash = (Get-FileHash -LiteralPath $database -Algorithm SHA256).Hash
        $env:AUTOCLIP_HOME = $fixtureHome
        $rejected = $false
        try { & $updater -BaseRoot $fixture -Rollback -NoShortcut }
        catch {
            if ($_.Exception.Message -notlike '*database schema is newer*') { throw }
            $rejected = $true
        }
        if (-not $rejected) { throw 'Rollback selected an app that cannot open the user database.' }
        if ((Get-FileHash -LiteralPath $statePath -Algorithm SHA256).Hash -ne $stateHash -or
            (Get-FileHash -LiteralPath $database -Algorithm SHA256).Hash -ne $dbHash -or
            (Test-Path -LiteralPath (Join-Path $fixture 'Start-AutoClip.ps1'))) {
            throw 'Rejected rollback changed state, database, or launcher.'
        }
    }

    $appSchema = $schema + 1
    $appSite = Join-Path $fixture 'apps\fixture-app\site'
    $appPackage = Join-Path $appSite 'autoclip'
    New-Item -ItemType Directory -Path (Join-Path $appPackage 'db') -Force | Out-Null
    [IO.File]::WriteAllText((Join-Path $appPackage '__init__.py'), '')
    [IO.File]::WriteAllText((Join-Path $appPackage 'app.py'), '')
    [IO.File]::WriteAllText((Join-Path $appPackage 'paths.py'), "import os`nfrom pathlib import Path`ndef db_path(): return Path(os.environ['AUTOCLIP_HOME']) / 'autoclip.db'`n")
    [IO.File]::WriteAllText((Join-Path (Join-Path $appPackage 'db') '__init__.py'), '')
    [IO.File]::WriteAllText((Join-Path (Join-Path $appPackage 'db') 'schema.py'), "SCHEMA_VERSION = $appSchema`n")
    $appStatePath = Join-Path $fixture 'app-active.json'
    $appState = @{ schema_version = 1; current = @{ app_id = 'fixture-app'; required_runtime = 'previous-runtime' } } | ConvertTo-Json -Depth 4
    [IO.File]::WriteAllText($appStatePath, $appState)
    $fixtureHome = Join-Path $fixture 'selected-app-compatible'
    New-Item -ItemType Directory -Path $fixtureHome | Out-Null
    $database = Join-Path $fixtureHome 'autoclip.db'
    & $python -c 'import sqlite3,sys; c=sqlite3.connect(sys.argv[1]); c.execute(sys.argv[2]); c.close()' $database ("PRAGMA user_version=" + $appSchema)
    if ($LASTEXITCODE -ne 0) { throw 'Could not create the app-layer schema fixture.' }
    $env:AUTOCLIP_HOME = $fixtureHome
    [IO.File]::WriteAllText($statePath, $initialState)
    & $updater -BaseRoot $fixture -Rollback -NoShortcut
    $state = Get-Content -LiteralPath $statePath -Raw | ConvertFrom-Json
    if ($state.current.release_id -ne 'previous-runtime') {
        throw 'Rollback rejected the selected app layer even though it supports the current database schema.'
    }

    $fixtureHome = Join-Path $fixture 'selected-app-newer-database'
    New-Item -ItemType Directory -Path $fixtureHome | Out-Null
    $database = Join-Path $fixtureHome 'autoclip.db'
    & $python -c 'import sqlite3,sys; c=sqlite3.connect(sys.argv[1]); c.execute(sys.argv[2]); c.close()' $database ("PRAGMA user_version=" + ($appSchema + 1))
    if ($LASTEXITCODE -ne 0) { throw 'Could not create the app-layer future-schema fixture.' }
    $env:AUTOCLIP_HOME = $fixtureHome
    [IO.File]::WriteAllText($statePath, $initialState)
    $stateHash = (Get-FileHash -LiteralPath $statePath -Algorithm SHA256).Hash
    $dbHash = (Get-FileHash -LiteralPath $database -Algorithm SHA256).Hash
    $launcherPath = Join-Path $fixture 'Start-AutoClip.ps1'
    $launcherHash = (Get-FileHash -LiteralPath $launcherPath -Algorithm SHA256).Hash
    $rejected = $false
    try { & $updater -BaseRoot $fixture -Rollback -NoShortcut }
    catch {
        if ($_.Exception.Message -notlike '*database schema is newer*') { throw }
        $rejected = $true
    }
    if (-not $rejected) { throw 'Rollback selected an app layer that cannot open the user database.' }
    if ((Get-FileHash -LiteralPath $statePath -Algorithm SHA256).Hash -ne $stateHash -or
        (Get-FileHash -LiteralPath $database -Algorithm SHA256).Hash -ne $dbHash -or
        (Get-FileHash -LiteralPath $launcherPath -Algorithm SHA256).Hash -ne $launcherHash) {
        throw 'Rejected app-layer rollback changed state, database, or launcher.'
    }

    foreach ($hasDatabase in @($true, $false)) {
        $fixtureHome = Join-Path $fixture ('compatible-' + $hasDatabase)
        New-Item -ItemType Directory -Path $fixtureHome | Out-Null
        if ($hasDatabase) {
            & $python -c 'import sqlite3,sys; c=sqlite3.connect(sys.argv[1]); c.execute(sys.argv[2]); c.close()' (Join-Path $fixtureHome 'autoclip.db') ("PRAGMA user_version=" + $schema)
            if ($LASTEXITCODE -ne 0) { throw 'Could not create the compatible test database.' }
        }
        [IO.File]::WriteAllText($statePath, $initialState)
        $env:AUTOCLIP_HOME = $fixtureHome
        & $updater -BaseRoot $fixture -Rollback -NoShortcut
        $state = Get-Content -LiteralPath $statePath -Raw | ConvertFrom-Json
        if ($state.current.release_id -ne 'previous-runtime') {
            throw 'Compatible database rollback did not select the prior runtime.'
        }
    }
} finally {
    [Environment]::SetEnvironmentVariable('AUTOCLIP_HOME', $oldHome, 'Process')
}
Write-Output 'Read-only user-database rollback guard passed.'
