param(
    [string]$RuntimeRoot,
    [string]$WheelPath,
    [string]$IncompatibleWheelPath
)

$ErrorActionPreference = 'Stop'
$repoRoot = Split-Path -Parent (Split-Path -Parent $PSScriptRoot)
$updater = Join-Path $repoRoot 'update-app.ps1'
if (-not (Test-Path -LiteralPath $updater -PathType Leaf)) {
    throw 'The app-only updater is missing.'
}
if (-not $RuntimeRoot -or -not $WheelPath) {
    throw 'Supply a verified installed runtime and an AutoClip wheel.'
}
$fixture = Join-Path ([IO.Path]::GetTempPath()) ('autoclip-app-update-' + [guid]::NewGuid().ToString('N'))
New-Item -ItemType Directory -Path $fixture | Out-Null
try {
    $release = & (Join-Path $repoRoot 'install.ps1') -ReleaseInfo -PrerequisitesOnly
    $runtime = Join-Path $fixture $release.ReleaseId
    New-Item -ItemType Junction -Path $runtime -Target $RuntimeRoot | Out-Null
    $runtimeManifest = Join-Path $runtime 'release-manifest.json'
    if ((Get-FileHash -LiteralPath $runtimeManifest -Algorithm SHA256).Hash -ne $release.ManifestSha256) {
        throw 'Fixture runtime manifest differs from the pinned release.'
    }
    $active = [ordered]@{
        schema_version = 1
        current = [ordered]@{
            release_id = $release.ReleaseId
            archive_sha256 = $release.ArchiveSha256
            manifest_sha256 = $release.ManifestSha256
        }
        previous = $null
    }
    [IO.File]::WriteAllText((Join-Path $fixture 'active.json'), ($active | ConvertTo-Json -Depth 5))
    $manifest = [ordered]@{
        schema_version = 1
        app_id = 'fixture-app-v1'
        required_runtime = $release.ReleaseId
        runtime_manifest_sha256 = $release.ManifestSha256
        wheel_sha256 = (Get-FileHash -LiteralPath $WheelPath -Algorithm SHA256).Hash.ToLowerInvariant()
        wheel_size = (Get-Item -LiteralPath $WheelPath).Length
    }
    $manifestPath = Join-Path $fixture 'app-manifest.json'
    [IO.File]::WriteAllText($manifestPath, ($manifest | ConvertTo-Json -Depth 5))
    $shortcutPath = Join-Path $fixture 'AutoClip-test.lnk'
    $shell = New-Object -ComObject WScript.Shell
    $shortcut = $shell.CreateShortcut($shortcutPath)
    $shortcut.TargetPath = Join-Path $runtime '.venv\Scripts\pythonw.exe'
    $shortcut.Arguments = '-m autoclip.desktop'
    $shortcut.Save()
    & $updater -BaseRoot $fixture -ManifestPath $manifestPath -WheelPath $WheelPath -ShortcutPath $shortcutPath
    $shortcut = $shell.CreateShortcut($shortcutPath)
    if ([string]$shortcut.Arguments -notlike '*Start-AutoClip-Desktop.ps1*' -or
        [string]$shortcut.TargetPath -notlike '*powershell.exe') {
        throw 'The managed desktop shortcut did not follow the stable app launcher.'
    }
    $appState = Get-Content -LiteralPath (Join-Path $fixture 'app-active.json') -Raw | ConvertFrom-Json
    if ($appState.current.app_id -ne 'fixture-app-v1') { throw 'The app layer was not activated.' }
    if (-not (Test-Path -LiteralPath (Join-Path $fixture 'apps\fixture-app-v1\site\autoclip\app.py'))) {
        throw 'The exact app wheel was not staged separately from runtime.'
    }
    if (-not (Test-Path -LiteralPath (Join-Path $fixture 'Start-AutoClip-Desktop.ps1'))) {
        throw 'The stable desktop launcher is missing.'
    }
    if ((Get-FileHash -LiteralPath $runtimeManifest -Algorithm SHA256).Hash -ne $release.ManifestSha256) {
        throw 'The reused runtime manifest changed.'
    }
    & $updater -BaseRoot $fixture -ManifestPath $manifestPath -WheelPath (Join-Path $fixture 'missing.whl') -NoShortcut
    $manifest.app_id = 'fixture-app-v2'
    [IO.File]::WriteAllText($manifestPath, ($manifest | ConvertTo-Json -Depth 5))
    & $updater -BaseRoot $fixture -ManifestPath $manifestPath -WheelPath $WheelPath -NoShortcut
    $appState = Get-Content -LiteralPath (Join-Path $fixture 'app-active.json') -Raw | ConvertFrom-Json
    if ($appState.current.app_id -ne 'fixture-app-v2' -or $appState.previous.app_id -ne 'fixture-app-v1') {
        throw 'A second app release did not retain the prior app for rollback.'
    }
    $before = [IO.File]::ReadAllText((Join-Path $fixture 'app-active.json'))
    $missingDependencyWheel = Join-Path $fixture 'missing-dependency.whl'
    Copy-Item -LiteralPath $WheelPath -Destination $missingDependencyWheel
    Add-Type -AssemblyName System.IO.Compression.FileSystem
    $zip = [IO.Compression.ZipFile]::Open($missingDependencyWheel, 'Update')
    try {
        $metadataEntry = @($zip.Entries | Where-Object { $_.FullName -like '*.dist-info/METADATA' })
        if ($metadataEntry.Count -ne 1) { throw 'The fixture wheel needs one METADATA entry.' }
        $reader = [IO.StreamReader]::new($metadataEntry[0].Open())
        try { $metadata = $reader.ReadToEnd() }
        finally { $reader.Dispose() }
        if (-not $metadata.Contains('Requires-Dist: fastapi')) {
            throw 'The fixture wheel is missing its base dependency marker.'
        }
        $metadataEntry[0].Delete()
        $writer = [IO.StreamWriter]::new($zip.CreateEntry($metadataEntry[0].FullName).Open())
        try {
            $writer.Write($metadata.Replace('Requires-Dist: fastapi',
                "Requires-Dist: autoclip-runtime-guard-missing>=1`nRequires-Dist: fastapi"))
        } finally { $writer.Dispose() }
    } finally { $zip.Dispose() }
    $manifest.app_id = 'fixture-missing-dependency'
    $manifest.wheel_sha256 = (Get-FileHash -LiteralPath $missingDependencyWheel -Algorithm SHA256).Hash.ToLowerInvariant()
    $manifest.wheel_size = (Get-Item -LiteralPath $missingDependencyWheel).Length
    [IO.File]::WriteAllText($manifestPath, ($manifest | ConvertTo-Json -Depth 5))
    try {
        & $updater -BaseRoot $fixture -ManifestPath $manifestPath -WheelPath $missingDependencyWheel -NoShortcut
        throw 'An app wheel with a missing runtime dependency was activated.'
    } catch {
        if ($_.Exception.Message -notlike '*missing runtime dependency*') { throw }
    }
    if ([IO.File]::ReadAllText((Join-Path $fixture 'app-active.json')) -ne $before) {
        throw 'A missing-dependency update changed the active app.'
    }
    if ($IncompatibleWheelPath) {
        $manifest.app_id = 'fixture-real-incompatible-dependency'
        $manifest.wheel_sha256 = (Get-FileHash -LiteralPath $IncompatibleWheelPath -Algorithm SHA256).Hash.ToLowerInvariant()
        $manifest.wheel_size = (Get-Item -LiteralPath $IncompatibleWheelPath).Length
        [IO.File]::WriteAllText($manifestPath, ($manifest | ConvertTo-Json -Depth 5))
        try {
            & $updater -BaseRoot $fixture -ManifestPath $manifestPath -WheelPath $IncompatibleWheelPath -NoShortcut
            throw 'The incompatible candidate app wheel was activated.'
        } catch {
            if ($_.Exception.Message -notlike '*missing runtime dependency*') { throw }
        }
        if ([IO.File]::ReadAllText((Join-Path $fixture 'app-active.json')) -ne $before) {
            throw 'The incompatible candidate changed the active app.'
        }
    }
    $manifest.wheel_sha256 = (Get-FileHash -LiteralPath $WheelPath -Algorithm SHA256).Hash.ToLowerInvariant()
    $manifest.wheel_size = (Get-Item -LiteralPath $WheelPath).Length
    $manifest.app_id = 'fixture-bad-hash'
    $manifest.wheel_sha256 = ('0' * 64)
    [IO.File]::WriteAllText($manifestPath, ($manifest | ConvertTo-Json -Depth 5))
    try {
        & $updater -BaseRoot $fixture -ManifestPath $manifestPath -WheelPath $WheelPath -NoShortcut
        throw 'A wheel with a bad hash was accepted.'
    } catch {
        if ($_.Exception.Message -notlike '*size or SHA-256*') { throw }
    }
    if ([IO.File]::ReadAllText((Join-Path $fixture 'app-active.json')) -ne $before) {
        throw 'A rejected wheel changed the active app.'
    }
    $manifest.wheel_sha256 = (Get-FileHash -LiteralPath $WheelPath -Algorithm SHA256).Hash.ToLowerInvariant()
    $manifest.required_runtime = 'another-runtime'
    [IO.File]::WriteAllText($manifestPath, ($manifest | ConvertTo-Json -Depth 5))
    try {
        & $updater -BaseRoot $fixture -ManifestPath $manifestPath -WheelPath $WheelPath -NoShortcut
        throw 'An incompatible runtime was accepted.'
    } catch {
        if ($_.Exception.Message -notlike '*requires a different runtime*') { throw }
    }
    if ([IO.File]::ReadAllText((Join-Path $fixture 'app-active.json')) -ne $before) {
        throw 'An incompatible update changed the active app.'
    }
    $manifest.required_runtime = $release.ReleaseId
    $manifest.app_id = 'fixture-missing-download'
    $manifest.wheel_url = 'https://github.com/Farkoal2128/autoclip-runtime/releases/download/fixture/autoclip-fixture.whl'
    [IO.File]::WriteAllText($manifestPath, ($manifest | ConvertTo-Json -Depth 5))
    function Invoke-WebRequest { param($Uri, $OutFile) throw 'simulated HTTP 404' }
    try {
        try {
            & $updater -BaseRoot $fixture -ManifestPath $manifestPath -NoShortcut
            throw 'A missing app wheel was accepted.'
        } catch {
            if ($_.Exception.Message -ne 'simulated HTTP 404') { throw }
        }
    } finally { Remove-Item Function:Invoke-WebRequest }
    if ([IO.File]::ReadAllText((Join-Path $fixture 'app-active.json')) -ne $before) {
        throw 'A missing app wheel changed the active app.'
    }
    $corruptWheel = Join-Path $fixture 'corrupt.whl'
    [IO.File]::WriteAllText($corruptWheel, 'not a ZIP')
    $manifest.app_id = 'fixture-corrupt'
    $manifest.wheel_sha256 = (Get-FileHash -LiteralPath $corruptWheel -Algorithm SHA256).Hash.ToLowerInvariant()
    $manifest.wheel_size = (Get-Item -LiteralPath $corruptWheel).Length
    [IO.File]::WriteAllText($manifestPath, ($manifest | ConvertTo-Json -Depth 5))
    $rejected = $false
    try { & $updater -BaseRoot $fixture -ManifestPath $manifestPath -WheelPath $corruptWheel -NoShortcut }
    catch { $rejected = $true }
    if (-not $rejected -or [IO.File]::ReadAllText((Join-Path $fixture 'app-active.json')) -ne $before) {
        throw 'A corrupt app wheel was activated or changed the active app.'
    }
    $unhealthyWheel = Join-Path $fixture 'unhealthy.whl'
    Copy-Item -LiteralPath $WheelPath -Destination $unhealthyWheel
    Add-Type -AssemblyName System.IO.Compression.FileSystem
    $zip = [IO.Compression.ZipFile]::Open($unhealthyWheel, 'Update')
    try {
        $entry = $zip.GetEntry('autoclip/app.py')
        if (-not $entry) { throw 'The fixture app wheel is missing autoclip/app.py.' }
        $entry.Delete()
        $writer = [IO.StreamWriter]::new($zip.CreateEntry('autoclip/app.py').Open())
        try { $writer.Write("raise RuntimeError('unhealthy app fixture')`n") }
        finally { $writer.Dispose() }
    } finally { $zip.Dispose() }
    $manifest.app_id = 'fixture-unhealthy'
    $manifest.wheel_sha256 = (Get-FileHash -LiteralPath $unhealthyWheel -Algorithm SHA256).Hash.ToLowerInvariant()
    $manifest.wheel_size = (Get-Item -LiteralPath $unhealthyWheel).Length
    [IO.File]::WriteAllText($manifestPath, ($manifest | ConvertTo-Json -Depth 5))
    try {
        & $updater -BaseRoot $fixture -ManifestPath $manifestPath -WheelPath $unhealthyWheel -NoShortcut
        throw 'An unhealthy app was activated.'
    } catch {
        if ($_.Exception.Message -notlike '*failed isolated health/home*') { throw }
    }
    if ([IO.File]::ReadAllText((Join-Path $fixture 'app-active.json')) -ne $before) {
        throw 'A failed health check changed the active app.'
    }
    & $updater -BaseRoot $fixture -Rollback -NoShortcut
    $appState = Get-Content -LiteralPath (Join-Path $fixture 'app-active.json') -Raw | ConvertFrom-Json
    if ($appState.current.app_id -ne 'fixture-app-v1') {
        throw 'Rollback did not select the prior app.'
    }
    & $updater -BaseRoot $fixture -Rollback -NoShortcut
    $appState = Get-Content -LiteralPath (Join-Path $fixture 'app-active.json') -Raw | ConvertFrom-Json
    if ($appState.current.app_id -ne 'fixture-app-v2') {
        throw 'Repeated rollback did not select the retained app.'
    }
    $manifest.app_id = 'fixture-app-v1'
    $manifest.wheel_sha256 = (Get-FileHash -LiteralPath $WheelPath -Algorithm SHA256).Hash.ToLowerInvariant()
    $manifest.wheel_size = (Get-Item -LiteralPath $WheelPath).Length
    [IO.File]::WriteAllText($manifestPath, ($manifest | ConvertTo-Json -Depth 5))
    & $updater -BaseRoot $fixture -ManifestPath $manifestPath -WheelPath $WheelPath -NoShortcut
    $appState = Get-Content -LiteralPath (Join-Path $fixture 'app-active.json') -Raw | ConvertFrom-Json
    if ($appState.current.app_id -ne 'fixture-app-v1' -or $appState.previous.app_id -ne 'fixture-app-v2') {
        throw 'Reapplying a retained app after rollback did not restore its selection.'
    }
    $retainedWheel = Join-Path $fixture 'apps\fixture-app-v2\autoclip.whl'
    $retainedBytes = [IO.File]::ReadAllBytes($retainedWheel)
    $before = [IO.File]::ReadAllText((Join-Path $fixture 'app-active.json'))
    try {
        [IO.File]::WriteAllText($retainedWheel, 'damaged retained wheel')
        $manifest.app_id = 'fixture-app-v2'
        [IO.File]::WriteAllText($manifestPath, ($manifest | ConvertTo-Json -Depth 5))
        try {
            & $updater -BaseRoot $fixture -ManifestPath $manifestPath -WheelPath $WheelPath -NoShortcut
            throw 'A damaged retained app was activated.'
        } catch {
            if ($_.Exception.Message -notlike '*app layer wheel hash*') { throw }
        }
        if ([IO.File]::ReadAllText((Join-Path $fixture 'app-active.json')) -ne $before) {
            throw 'A damaged retained app changed active selection.'
        }
    } finally { [IO.File]::WriteAllBytes($retainedWheel, $retainedBytes) }
    $retainedPage = Join-Path $fixture 'apps\fixture-app-v2\site\autoclip\static\index.html'
    $pageBytes = [IO.File]::ReadAllBytes($retainedPage)
    try {
        [IO.File]::WriteAllText($retainedPage, 'changed retained page')
        try {
            & $updater -BaseRoot $fixture -ManifestPath $manifestPath -WheelPath $WheelPath -NoShortcut
            throw 'A modified retained app page was activated.'
        } catch {
            if ($_.Exception.Message -notlike '*app layer content differs*') { throw }
        }
        if ([IO.File]::ReadAllText((Join-Path $fixture 'app-active.json')) -ne $before) {
            throw 'A modified retained app page changed active selection.'
        }
    } finally { [IO.File]::WriteAllBytes($retainedPage, $pageBytes) }
    $oldHome = [Environment]::GetEnvironmentVariable('AUTOCLIP_HOME', 'Process')
    $futureHome = Join-Path $fixture 'future-user-data'
    New-Item -ItemType Directory -Path $futureHome | Out-Null
    try {
        $env:AUTOCLIP_HOME = $futureHome
        $python = Join-Path $runtime '.venv\Scripts\python.exe'
        $futureSchema = [int](& $python -c 'from autoclip.db.schema import SCHEMA_VERSION; print(SCHEMA_VERSION)') + 1
        & $python -c 'import sqlite3,sys; c=sqlite3.connect(sys.argv[1]); c.execute(sys.argv[2]); c.close()' (Join-Path $futureHome 'autoclip.db') ("PRAGMA user_version=" + $futureSchema)
        if ($LASTEXITCODE -ne 0) { throw 'Could not create the future-schema app fixture.' }
        $before = [IO.File]::ReadAllText((Join-Path $fixture 'app-active.json'))
        $manifest.app_id = 'fixture-app-v2'
        [IO.File]::WriteAllText($manifestPath, ($manifest | ConvertTo-Json -Depth 5))
        try {
            & $updater -BaseRoot $fixture -ManifestPath $manifestPath -WheelPath $WheelPath -NoShortcut
            throw 'A retained app incompatible with user data was activated.'
        } catch {
            if ($_.Exception.Message -notlike '*database schema is newer*') { throw }
        }
        if ([IO.File]::ReadAllText((Join-Path $fixture 'app-active.json')) -ne $before) {
            throw 'Rejected retained-app reactivation changed active selection.'
        }
    } finally { [Environment]::SetEnvironmentVariable('AUTOCLIP_HOME', $oldHome, 'Process') }
    $manifest.app_id = 'fixture-compatible-runtime'
    $manifest.required_runtime = 'another-runtime'
    $manifest.runtime_manifest_sha256 = ('0' * 64)
    $manifest['compatible_runtimes'] = @(@{
        release_id = $release.ReleaseId
        manifest_sha256 = $release.ManifestSha256
    })
    $manifest.wheel_sha256 = (Get-FileHash -LiteralPath $WheelPath -Algorithm SHA256).Hash.ToLowerInvariant()
    $manifest.wheel_size = (Get-Item -LiteralPath $WheelPath).Length
    [IO.File]::WriteAllText($manifestPath, ($manifest | ConvertTo-Json -Depth 5))
    & $updater -BaseRoot $fixture -ManifestPath $manifestPath -WheelPath $WheelPath -NoShortcut
    $appState = Get-Content -LiteralPath (Join-Path $fixture 'app-active.json') -Raw | ConvertFrom-Json
    if ($appState.current.app_id -ne 'fixture-compatible-runtime' -or
        $appState.current.required_runtime -ne $release.ReleaseId) {
        throw 'A compatible prior runtime was not retained as the active app runtime.'
    }
    Write-Output 'App-only stage, no-op, failure preservation and rollback passed.'
} finally {
    $junction = Join-Path $fixture $release.ReleaseId
    if ($release -and (Test-Path -LiteralPath $junction)) { [IO.Directory]::Delete($junction) }
    if (Test-Path -LiteralPath $fixture) { Remove-Item -LiteralPath $fixture -Recurse -Force }
}
