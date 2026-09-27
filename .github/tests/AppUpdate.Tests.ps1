param(
    [string]$RuntimeRoot,
    [string]$WheelPath
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
    Write-Output 'App-only stage, no-op, failure preservation and rollback passed.'
} finally {
    $junction = Join-Path $fixture $release.ReleaseId
    if ($release -and (Test-Path -LiteralPath $junction)) { [IO.Directory]::Delete($junction) }
    if (Test-Path -LiteralPath $fixture) { Remove-Item -LiteralPath $fixture -Recurse -Force }
}
