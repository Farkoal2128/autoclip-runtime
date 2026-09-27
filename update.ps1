param(
    [string]$BaseRoot,
    [string]$InstallerPath,
    [string]$ArchivePath,
    [string]$ShortcutPath,
    [string]$PreviousReleaseId,
    [switch]$Rollback,
    [switch]$NoShortcut
)

$ErrorActionPreference = 'Stop'
if (-not $IsWindows -and $PSVersionTable.PSEdition -eq 'Core') {
    throw 'This updater supports Windows x64 only.'
}
if (-not [Environment]::Is64BitOperatingSystem) {
    throw 'This updater requires 64-bit Windows.'
}
if (-not $BaseRoot) {
    $BaseRoot = Join-Path $env:LOCALAPPDATA 'AutoClip'
}
$baseFull = [IO.Path]::GetFullPath($BaseRoot).TrimEnd('\')
$statePath = Join-Path $baseFull 'active.json'
$launcherPath = Join-Path $baseFull 'Start-AutoClip.ps1'
$installerUrl = 'https://raw.githubusercontent.com/Farkoal2128/autoclip-runtime/main/install.ps1'

function Assert-AppStopped {
    $client = New-Object Net.Sockets.TcpClient
    $busy = $false
    try {
        $attempt = $client.BeginConnect('127.0.0.1', 8000, $null, $null)
        if ($attempt.AsyncWaitHandle.WaitOne(500)) {
            try {
                $client.EndConnect($attempt)
                $busy = $true
            } catch [Net.Sockets.SocketException] {
                # Connection refused: no app is listening on the default port.
            }
        }
    } finally {
        $client.Close()
    }
    if ($busy) {
        throw 'Local port 8000 is in use. Quit AutoClip (or the other service using that port), then rerun the updater.'
    }
}

Assert-AppStopped

function Assert-ReleaseId([string]$ReleaseId) {
    if ($ReleaseId -notmatch '^[A-Za-z0-9][A-Za-z0-9._-]*$') {
        throw "Invalid release identifier: $ReleaseId"
    }
}

function Get-ReleaseRoot([string]$ReleaseId) {
    Assert-ReleaseId $ReleaseId
    return Join-Path $baseFull $ReleaseId
}

function Write-AtomicText([string]$Path, [string]$Value) {
    $temporary = Join-Path (Split-Path -Parent $Path) ('.autoclip-write-' + [guid]::NewGuid().ToString('N'))
    try {
        [IO.File]::WriteAllText($temporary, $Value, (New-Object System.Text.UTF8Encoding($false)))
        if ([IO.File]::Exists($Path)) {
            $backup = $Path + '.backup-' + [guid]::NewGuid().ToString('N')
            [IO.File]::Replace($temporary, $Path, $backup)
            try { [IO.File]::Delete($backup) } catch {
                Write-Warning "Could not remove updater backup ${backup}: $($_.Exception.Message)"
            }
        } else {
            [IO.File]::Move($temporary, $Path)
        }
    } finally {
        if ([IO.File]::Exists($temporary)) { [IO.File]::Delete($temporary) }
    }
}

function Write-StableLauncher {
    $source = @'
$ErrorActionPreference = 'Stop'
$statePath = Join-Path $PSScriptRoot 'active.json'
if (-not (Test-Path -LiteralPath $statePath -PathType Leaf)) {
    throw 'No active AutoClip runtime is selected. Run update.ps1 first.'
}
$state = Get-Content -LiteralPath $statePath -Raw | ConvertFrom-Json
$releaseId = [string]$state.current.release_id
if ($releaseId -notmatch '^[A-Za-z0-9][A-Za-z0-9._-]*$') {
    throw 'The active AutoClip release identifier is invalid.'
}
$runtimeRoot = Join-Path $PSScriptRoot $releaseId
$appStatePath = Join-Path $PSScriptRoot 'app-active.json'
if (Test-Path -LiteralPath $appStatePath -PathType Leaf) {
    $appState = Get-Content -LiteralPath $appStatePath -Raw | ConvertFrom-Json
    $appId = [string]$appState.current.app_id
    if ($appState.schema_version -ne 1 -or $appId -notmatch '^[A-Za-z0-9][A-Za-z0-9._-]*$') {
        throw 'The active AutoClip app state is invalid.'
    }
    if ($appState.current.required_runtime -eq $releaseId) {
        $site = Join-Path (Join-Path (Join-Path $PSScriptRoot 'apps') $appId) 'site'
        if (-not (Test-Path -LiteralPath (Join-Path $site 'autoclip\app.py') -PathType Leaf)) {
            throw 'The active AutoClip app layer is missing.'
        }
        $env:PYTHONPATH = $site
        $env:AUTOCLIP_MANAGED_DESKTOP_LAUNCHER = Join-Path $PSScriptRoot 'Start-AutoClip-Desktop.ps1'
        & (Join-Path $runtimeRoot '.venv\Scripts\python.exe') -m autoclip.cli serve
        return
    }
}
$launcher = Join-Path $runtimeRoot 'Start-AutoClip.ps1'
if (-not (Test-Path -LiteralPath $launcher -PathType Leaf)) {
    throw "The active AutoClip runtime is missing: $launcher"
}
& $launcher
'@
    Write-AtomicText $launcherPath $source
}

function Read-ActiveState {
    if (-not (Test-Path -LiteralPath $statePath -PathType Leaf)) { return $null }
    $state = Get-Content -LiteralPath $statePath -Raw | ConvertFrom-Json
    if ($state.schema_version -ne 1 -or -not $state.current) {
        throw "Unsupported or incomplete active runtime state: $statePath"
    }
    Assert-ReleaseId ([string]$state.current.release_id)
    return $state
}

function Test-InstalledRelease($Release) {
    $releaseId = [string]$Release.release_id
    $expectedManifest = [string]$Release.manifest_sha256
    Assert-ReleaseId $releaseId
    if ($expectedManifest -notmatch '^[0-9a-fA-F]{64}$') {
        throw "Invalid manifest hash for $releaseId"
    }
    $root = Get-ReleaseRoot $releaseId
    $manifest = Join-Path $root 'release-manifest.json'
    $python = Join-Path $root '.venv\Scripts\python.exe'
    $versionLauncher = Join-Path $root 'Start-AutoClip.ps1'
    if (-not (Test-Path -LiteralPath $manifest -PathType Leaf) -or
        -not (Test-Path -LiteralPath $python -PathType Leaf) -or
        -not (Test-Path -LiteralPath $versionLauncher -PathType Leaf)) {
        throw "The $releaseId runtime is incomplete: $root"
    }
    $actualManifest = (Get-FileHash -LiteralPath $manifest -Algorithm SHA256).Hash
    if ($actualManifest -ne $expectedManifest) {
        throw "The $releaseId release manifest does not match its pinned hash."
    }

    $smokeHome = Join-Path ([IO.Path]::GetTempPath()) ('autoclip-update-check-' + [guid]::NewGuid().ToString('N'))
    $oldHome = [Environment]::GetEnvironmentVariable('AUTOCLIP_HOME', 'Process')
    try {
        $env:AUTOCLIP_HOME = $smokeHome
        & $python -c "import sys; from fastapi.testclient import TestClient; from autoclip.app import create_app; assert sys.version_info[:2] == (3, 11); c = TestClient(create_app()); c.__enter__(); assert c.get('/api/health').status_code == 200; assert c.get('/').status_code == 200; c.__exit__(None, None, None)"
        if ($LASTEXITCODE -ne 0) {
            throw "The $releaseId runtime failed its isolated health/home check."
        }
    } finally {
        [Environment]::SetEnvironmentVariable('AUTOCLIP_HOME', $oldHome, 'Process')
        if (Test-Path -LiteralPath $smokeHome) {
            $tempFull = [IO.Path]::GetFullPath([IO.Path]::GetTempPath())
            $smokeFull = [IO.Path]::GetFullPath($smokeHome)
            if (-not $smokeFull.StartsWith($tempFull, [StringComparison]::OrdinalIgnoreCase)) {
                throw 'Refusing to remove a smoke directory outside the temporary folder.'
            }
            Remove-Item -LiteralPath $smokeFull -Recurse -Force
        }
    }
    return $root
}

function Get-PreviousRelease([string]$NewReleaseId) {
    $priorId = $PreviousReleaseId
    if (-not $priorId) {
        $path = $ShortcutPath
        if (-not $path) {
            $desktop = [Environment]::GetFolderPath('DesktopDirectory')
            if ($desktop) { $path = Join-Path $desktop 'AutoClip.lnk' }
        }
        if (-not $path -or -not (Test-Path -LiteralPath $path -PathType Leaf)) {
            return $null
        }
        $shell = New-Object -ComObject WScript.Shell
        $target = [IO.Path]::GetFullPath([string]$shell.CreateShortcut($path).TargetPath)
        $prefix = $baseFull + '\'
        if (-not $target.StartsWith($prefix, [StringComparison]::OrdinalIgnoreCase)) {
            return $null
        }
        $relative = $target.Substring($prefix.Length)
        $parts = $relative.Split('\')
        if ($parts.Length -ne 4 -or
            $parts[1] -ne '.venv' -or $parts[2] -ne 'Scripts' -or
            $parts[3] -ne 'pythonw.exe') {
            return $null
        }
        $priorId = $parts[0]
    }
    Assert-ReleaseId $priorId
    if ($priorId -eq $NewReleaseId) { return $null }
    $manifest = Join-Path (Get-ReleaseRoot $priorId) 'release-manifest.json'
    if (-not (Test-Path -LiteralPath $manifest -PathType Leaf)) {
        if ($PreviousReleaseId) { throw "Previous release manifest is missing: $manifest" }
        Write-Warning "The prior desktop runtime has no release manifest: $manifest. It will remain installed but cannot be selected by automatic rollback."
        return $null
    }
    $prior = [ordered]@{
        release_id = $priorId
        archive_sha256 = $null
        manifest_sha256 = (Get-FileHash -LiteralPath $manifest -Algorithm SHA256).Hash.ToLowerInvariant()
    }
    try {
        [void](Test-InstalledRelease $prior)
    } catch {
        if ($PreviousReleaseId) { throw }
        Write-Warning "The prior desktop runtime did not pass an isolated check: $($_.Exception.Message). Its files remain in place."
        return $null
    }
    return $prior
}

function Update-DesktopShortcut($Release) {
    if ($NoShortcut) { return $null }
    $shortcutPath = $ShortcutPath
    if (-not $shortcutPath) {
        $desktop = [Environment]::GetFolderPath('DesktopDirectory')
        if (-not $desktop) { return $null }
        $shortcutPath = Join-Path $desktop 'AutoClip.lnk'
    }
    if (-not (Test-Path -LiteralPath $shortcutPath -PathType Leaf)) { return $null }
    $shell = New-Object -ComObject WScript.Shell
    $shortcut = $shell.CreateShortcut($shortcutPath)
    $target = [IO.Path]::GetFullPath([string]$shortcut.TargetPath)
    $managedDesktopLauncher = Join-Path $baseFull 'Start-AutoClip-Desktop.ps1'
    if (([string]$shortcut.Arguments).Contains($managedDesktopLauncher) -and
        (Test-Path -LiteralPath $managedDesktopLauncher -PathType Leaf)) {
        return $null
    }
    $managedPrefix = $baseFull + '\'
    if (-not $target.StartsWith($managedPrefix, [StringComparison]::OrdinalIgnoreCase)) {
        Write-Warning "The existing AutoClip desktop shortcut points outside $baseFull. It was not changed; recreate it from the new app's Settings."
        return $null
    }
    $backup = Join-Path ([IO.Path]::GetTempPath()) ('autoclip-shortcut-' + [guid]::NewGuid().ToString('N') + '.lnk')
    Copy-Item -LiteralPath $shortcutPath -Destination $backup
    try {
        $newRoot = Get-ReleaseRoot ([string]$Release.release_id)
        $pythonw = Join-Path $newRoot '.venv\Scripts\pythonw.exe'
        if (-not (Test-Path -LiteralPath $pythonw -PathType Leaf)) {
            throw "The selected runtime has no desktop launcher: $pythonw"
        }
        $oldIcon = [string]$shortcut.IconLocation
        $shortcut.TargetPath = $pythonw
        $shortcut.Arguments = '-m autoclip.desktop'
        $shortcut.WorkingDirectory = $newRoot
        if ($oldIcon.StartsWith($managedPrefix, [StringComparison]::OrdinalIgnoreCase)) {
            $shortcut.IconLocation = (Join-Path $newRoot '.venv\Scripts\autoclip.exe') + ',0'
        }
        $shortcut.Save()
        $newTarget = [IO.Path]::GetFullPath([string]$shell.CreateShortcut($shortcutPath).TargetPath)
        $newPrefix = $newRoot.TrimEnd('\') + '\'
        if (-not $newTarget.StartsWith($newPrefix, [StringComparison]::OrdinalIgnoreCase)) {
            throw 'The refreshed desktop shortcut does not target the selected runtime.'
        }
        return $backup
    } catch {
        Copy-Item -LiteralPath $backup -Destination $shortcutPath -Force
        Remove-Item -LiteralPath $backup
        throw
    }
}

function Select-Release($Release, $Previous) {
    [void](Test-InstalledRelease $Release)
    New-Item -ItemType Directory -Path $baseFull -Force | Out-Null
    Write-StableLauncher
    $shortcutBackup = Update-DesktopShortcut $Release
    try {
        $next = [ordered]@{
            schema_version = 1
            current = $Release
            previous = $Previous
        }
        Write-AtomicText $statePath ($next | ConvertTo-Json -Depth 5)
    } catch {
        if ($shortcutBackup) {
            $restorePath = $ShortcutPath
            if (-not $restorePath) {
                $restorePath = Join-Path ([Environment]::GetFolderPath('DesktopDirectory')) 'AutoClip.lnk'
            }
            Copy-Item -LiteralPath $shortcutBackup -Destination $restorePath -Force
        }
        throw
    } finally {
        if ($shortcutBackup -and (Test-Path -LiteralPath $shortcutBackup)) {
            Remove-Item -LiteralPath $shortcutBackup
        }
    }
    Write-Host "Active AutoClip runtime: $(Get-ReleaseRoot ([string]$Release.release_id))"
    Write-Host "Start with: & '$launcherPath'"
    if ($Previous) { Write-Host 'The previous runtime is retained. Run update.ps1 -Rollback to select it again.' }
}

$state = Read-ActiveState
if ($Rollback) {
    if (-not $state -or -not $state.previous) { throw 'No previous AutoClip runtime is recorded for rollback.' }
    Select-Release $state.previous $state.current
    return
}

$downloadedInstaller = $null
try {
    if (-not $InstallerPath) {
        $downloadedInstaller = Join-Path ([IO.Path]::GetTempPath()) ('autoclip-installer-' + [guid]::NewGuid().ToString('N') + '.ps1')
        Invoke-WebRequest -UseBasicParsing -Uri $installerUrl -OutFile $downloadedInstaller
        $InstallerPath = $downloadedInstaller
    }
    $info = & $InstallerPath -ReleaseInfo -PrerequisitesOnly
    if (@($info).Count -ne 1) { throw 'The current installer did not report one release identity.' }
    $releaseId = [string]$info.ReleaseId
    Assert-ReleaseId $releaseId
    if ([string]$info.ArchiveSha256 -notmatch '^[0-9a-fA-F]{64}$' -or
        [string]$info.ManifestSha256 -notmatch '^[0-9a-fA-F]{64}$') {
        throw 'The current installer did not report pinned archive and manifest hashes.'
    }
    $release = [ordered]@{
        release_id = $releaseId
        archive_sha256 = [string]$info.ArchiveSha256
        manifest_sha256 = [string]$info.ManifestSha256
    }
    $targetRoot = Get-ReleaseRoot $releaseId
    if ($state -and $state.current.release_id -eq $releaseId -and
        $state.current.archive_sha256 -eq $release.archive_sha256) {
        try {
            [void](Test-InstalledRelease $state.current)
            Write-StableLauncher
            $shortcutBackup = Update-DesktopShortcut $state.current
            if ($shortcutBackup) { Remove-Item -LiteralPath $shortcutBackup }
            Write-Host "AutoClip is already up to date: $releaseId"
            return
        } catch {
            Write-Warning "The active $releaseId runtime needs repair: $($_.Exception.Message)"
        }
    }
    $validExisting = $false
    if (Test-Path -LiteralPath (Join-Path $targetRoot '.venv\Scripts\python.exe')) {
        try {
            [void](Test-InstalledRelease $release)
            $validExisting = $true
        } catch {
            Write-Warning "The existing $releaseId runtime did not pass verification; attempting a safe installer retry: $($_.Exception.Message)"
        }
    }
    if (-not $validExisting) {
        $arguments = @{ InstallRoot = $targetRoot }
        if ($ArchivePath) { $arguments.ArchivePath = $ArchivePath }
        & $InstallerPath @arguments
    }
    $previous = if ($state -and $state.current.release_id -eq $releaseId) {
        $state.previous
    } elseif ($state) {
        $state.current
    } else {
        Get-PreviousRelease $releaseId
    }
    Select-Release $release $previous
} finally {
    if ($downloadedInstaller -and (Test-Path -LiteralPath $downloadedInstaller)) {
        Remove-Item -LiteralPath $downloadedInstaller
    }
}
