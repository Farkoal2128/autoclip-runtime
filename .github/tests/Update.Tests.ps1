param(
    [string]$ArchivePath,
    [string]$BaseRoot
)

$ErrorActionPreference = 'Stop'
$repoRoot = Split-Path -Parent (Split-Path -Parent $PSScriptRoot)
$installer = Join-Path $repoRoot 'install.ps1'
$updater = Join-Path $repoRoot 'update.ps1'

$release = & $installer -ReleaseInfo -PrerequisitesOnly
if ($release.ReleaseId -ne 'v11-20260926-app-refresh' -or
    $release.ArchiveSha256 -ne '5308c1fa34e967b38c4386970f123a3e67a2ea5532c1e144db577b95c56afdf0') {
    throw 'Installer did not report the pinned release identity.'
}
if (-not (Test-Path -LiteralPath $updater -PathType Leaf)) {
    throw 'The PowerShell updater is missing.'
}

if (-not $BaseRoot) {
    $BaseRoot = Join-Path ([IO.Path]::GetTempPath()) ('autoclip-updater-test-' + [guid]::NewGuid().ToString('N'))
}
$targetRoot = Join-Path $BaseRoot $release.ReleaseId
if (-not (Test-Path -LiteralPath (Join-Path $targetRoot '.venv\Scripts\python.exe')) -and -not $ArchivePath) {
    throw 'Supply -ArchivePath for a fresh updater test, or -BaseRoot with the release already installed.'
}
$arguments = @{ BaseRoot = $BaseRoot; InstallerPath = $installer; NoShortcut = $true }
if ($ArchivePath) { $arguments.ArchivePath = $ArchivePath }
& $updater @arguments
$statePath = Join-Path $BaseRoot 'active.json'
$state = Get-Content -LiteralPath $statePath -Raw | ConvertFrom-Json
if ($state.current.release_id -ne $release.ReleaseId -or
    -not (Test-Path -LiteralPath (Join-Path $BaseRoot 'Start-AutoClip.ps1'))) {
    throw 'The updater did not select the verified release and create a stable launcher.'
}

$previousRoot = Join-Path $BaseRoot 'previous-runtime'
New-Item -ItemType Junction -Path $previousRoot -Target $targetRoot | Out-Null
$state.previous = [pscustomobject]@{
    release_id = 'previous-runtime'
    archive_sha256 = $release.ArchiveSha256
    manifest_sha256 = $release.ManifestSha256
}
[IO.File]::WriteAllText($statePath, ($state | ConvertTo-Json -Depth 5))
& $updater -BaseRoot $BaseRoot -Rollback -NoShortcut
$state = Get-Content -LiteralPath $statePath -Raw | ConvertFrom-Json
if ($state.current.release_id -ne 'previous-runtime') {
    throw 'Rollback did not restore the previous verified runtime.'
}

$shortcutPath = Join-Path $BaseRoot 'AutoClip-test.lnk'
$shell = New-Object -ComObject WScript.Shell
$shortcut = $shell.CreateShortcut($shortcutPath)
$shortcut.TargetPath = Join-Path $previousRoot '.venv\Scripts\pythonw.exe'
$shortcut.Arguments = '-m autoclip.desktop'
$shortcut.Save()
& $updater -BaseRoot $BaseRoot -InstallerPath $installer -ShortcutPath $shortcutPath
$newTarget = [IO.Path]::GetFullPath([string]$shell.CreateShortcut($shortcutPath).TargetPath)
if (-not $newTarget.StartsWith(([IO.Path]::GetFullPath($targetRoot).TrimEnd('\') + '\'), [StringComparison]::OrdinalIgnoreCase)) {
    throw 'The managed desktop shortcut still points to the old runtime.'
}

& $updater -BaseRoot $BaseRoot -InstallerPath $installer -ArchivePath 'C:\missing-archive.zip' -NoShortcut
$state = Get-Content -LiteralPath $statePath -Raw | ConvertFrom-Json
if ($state.current.release_id -ne $release.ReleaseId) {
    throw 'Repeating the updater changed the selected release.'
}
$staleLink = $shell.CreateShortcut($shortcutPath)
$staleLink.TargetPath = Join-Path $previousRoot '.venv\Scripts\pythonw.exe'
$staleLink.Save()
& $updater -BaseRoot $BaseRoot -InstallerPath $installer -ShortcutPath $shortcutPath
$refreshedTarget = [IO.Path]::GetFullPath([string]$shell.CreateShortcut($shortcutPath).TargetPath)
if (-not $refreshedTarget.StartsWith(([IO.Path]::GetFullPath($targetRoot).TrimEnd('\') + '\'), [StringComparison]::OrdinalIgnoreCase)) {
    throw 'Repeating an update did not repair a managed shortcut to the current runtime.'
}

$mockInstaller = Join-Path $BaseRoot 'failing-installer.ps1'
[IO.File]::WriteAllText($mockInstaller, @'
param([switch]$ReleaseInfo, [switch]$PrerequisitesOnly, [string]$InstallRoot)
if ($ReleaseInfo) {
    [pscustomobject]@{
        ReleaseId = 'simulated-next'
        ArchiveSha256 = 'aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa'
        ManifestSha256 = 'bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb'
    }
    return
}
throw 'simulated installation failure'
'@)
$failed = $false
try {
    & $updater -BaseRoot $BaseRoot -InstallerPath $mockInstaller -NoShortcut
} catch {
    if ($_.Exception.Message -ne 'simulated installation failure') { throw }
    $failed = $true
}
if (-not $failed) { throw 'A failed installer was treated as a successful update.' }
$state = Get-Content -LiteralPath $statePath -Raw | ConvertFrom-Json
if ($state.current.release_id -ne $release.ReleaseId) {
    throw 'A failed update replaced the selected release.'
}
$unhealthyInstaller = Join-Path $BaseRoot 'unhealthy-installer.ps1'
[IO.File]::WriteAllText($unhealthyInstaller, @'
param([switch]$ReleaseInfo, [switch]$PrerequisitesOnly, [string]$InstallRoot)
if ($ReleaseInfo) {
    [pscustomobject]@{
        ReleaseId = 'simulated-unhealthy'
        ArchiveSha256 = 'cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc'
        ManifestSha256 = 'dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd'
    }
    return
}
New-Item -ItemType Directory -Path $InstallRoot -Force | Out-Null
'@)
$rejected = $false
try {
    & $updater -BaseRoot $BaseRoot -InstallerPath $unhealthyInstaller -NoShortcut
} catch {
    if ($_.Exception.Message -notlike 'The simulated-unhealthy runtime is incomplete*') { throw }
    $rejected = $true
}
if (-not $rejected) { throw 'An incomplete candidate was selected.' }
$state = Get-Content -LiteralPath $statePath -Raw | ConvertFrom-Json
if ($state.current.release_id -ne $release.ReleaseId) {
    throw 'An incomplete update replaced the selected release.'
}

$importBase = Join-Path ([IO.Path]::GetTempPath()) ('autoclip-update-import-' + [guid]::NewGuid().ToString('N'))
New-Item -ItemType Directory -Path $importBase | Out-Null
New-Item -ItemType Junction -Path (Join-Path $importBase $release.ReleaseId) -Target $targetRoot | Out-Null
$importPrevious = Join-Path $importBase 'previous-runtime'
New-Item -ItemType Junction -Path $importPrevious -Target $targetRoot | Out-Null
$importShortcut = Join-Path $importBase 'AutoClip-test.lnk'
$link = $shell.CreateShortcut($importShortcut)
$link.TargetPath = Join-Path $importPrevious '.venv\Scripts\pythonw.exe'
$link.Arguments = '-m autoclip.desktop'
$link.Save()
& $updater -BaseRoot $importBase -InstallerPath $installer -ShortcutPath $importShortcut
$importState = Get-Content -LiteralPath (Join-Path $importBase 'active.json') -Raw | ConvertFrom-Json
if ($importState.previous.release_id -ne 'previous-runtime') {
    throw 'The updater did not record the existing managed desktop runtime for rollback.'
}
& $updater -BaseRoot $importBase -Rollback -ShortcutPath $importShortcut
$importState = Get-Content -LiteralPath (Join-Path $importBase 'active.json') -Raw | ConvertFrom-Json
if ($importState.current.release_id -ne 'previous-runtime') {
    throw 'The imported prior runtime could not be selected for rollback.'
}

$explicitBase = Join-Path ([IO.Path]::GetTempPath()) ('autoclip-update-explicit-' + [guid]::NewGuid().ToString('N'))
New-Item -ItemType Directory -Path $explicitBase | Out-Null
New-Item -ItemType Junction -Path (Join-Path $explicitBase $release.ReleaseId) -Target $targetRoot | Out-Null
New-Item -ItemType Junction -Path (Join-Path $explicitBase 'previous-runtime') -Target $targetRoot | Out-Null
& $updater -BaseRoot $explicitBase -InstallerPath $installer -PreviousReleaseId 'previous-runtime' -NoShortcut
$explicitState = Get-Content -LiteralPath (Join-Path $explicitBase 'active.json') -Raw | ConvertFrom-Json
if ($explicitState.previous.release_id -ne 'previous-runtime') {
    throw 'An explicitly supplied prior release was not recorded for rollback.'
}

if ($ArchivePath) {
    $fixtureInstaller = Join-Path $BaseRoot 'next-version-installer.ps1'
    $installerSource = [IO.File]::ReadAllText($installer)
    $nextSource = $installerSource.Replace(
        "releaseId = 'v11-20260926-app-refresh'",
        "releaseId = 'v11-update-fixture'"
    )
    if ($nextSource -eq $installerSource) { throw 'Could not prepare the next-version fixture.' }
    [IO.File]::WriteAllText($fixtureInstaller, $nextSource)
    & $updater -BaseRoot $BaseRoot -InstallerPath $fixtureInstaller -ArchivePath $ArchivePath -NoShortcut
    $fixtureState = Get-Content -LiteralPath $statePath -Raw | ConvertFrom-Json
    if ($fixtureState.current.release_id -ne 'v11-update-fixture' -or
        $fixtureState.previous.release_id -ne $release.ReleaseId) {
        throw 'A new pinned release did not replace the active runtime.'
    }
    & $updater -BaseRoot $BaseRoot -Rollback -NoShortcut
    $fixtureState = Get-Content -LiteralPath $statePath -Raw | ConvertFrom-Json
    if ($fixtureState.current.release_id -ne $release.ReleaseId) {
        throw 'The updater could not roll back from a newly installed version.'
    }
}

$originalState = Get-Content -LiteralPath $statePath -Raw
$fixtureRoot = Join-Path $BaseRoot 'launcher-fixture'
$fixtureLauncher = Join-Path $fixtureRoot 'Start-AutoClip.ps1'
$marker = Join-Path $BaseRoot 'launcher-ran.txt'
New-Item -ItemType Directory -Path $fixtureRoot | Out-Null
[IO.File]::WriteAllText($fixtureLauncher, "Set-Content -LiteralPath '$marker' -Value 'selected runtime'")
try {
    $fixtureState = $originalState | ConvertFrom-Json
    $fixtureState.current.release_id = 'launcher-fixture'
    [IO.File]::WriteAllText($statePath, ($fixtureState | ConvertTo-Json -Depth 5))
    & (Join-Path $BaseRoot 'Start-AutoClip.ps1')
    if (-not (Test-Path -LiteralPath $marker -PathType Leaf)) {
        throw 'The stable launcher did not start the selected runtime.'
    }
} finally {
    [IO.File]::WriteAllText($statePath, $originalState)
}

$listener = [Net.Sockets.TcpListener]::new([Net.IPAddress]::Loopback, 8000)
$listener.Start()
try {
    $busyRejected = $false
    try {
        & $updater -BaseRoot $BaseRoot -InstallerPath $installer -NoShortcut
    } catch {
        if ($_.Exception.Message -notlike '*port 8000*') { throw }
        $busyRejected = $true
    }
    if (-not $busyRejected) { throw 'The updater switched while AutoClip could still be running.' }
} finally {
    $listener.Stop()
}

Write-Output "Updater install, rollback, shortcut, no-op and failure checks passed: $BaseRoot"
