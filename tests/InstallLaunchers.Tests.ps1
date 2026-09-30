$ErrorActionPreference = 'Stop'
$repo = Split-Path -Parent $PSScriptRoot
$tokens = $null
$errors = $null
$ast = [Management.Automation.Language.Parser]::ParseFile((Join-Path $repo 'install.ps1'), [ref]$tokens, [ref]$errors)
if ($errors.Count) { throw 'Installer parse failed.' }
$function = $ast.Find({
    param($node)
    $node -is [Management.Automation.Language.FunctionDefinitionAst] -and
        $node.Name -eq 'Install-AutoClipLaunchers'
}, $true)
if (-not $function) { throw 'Installer launcher helper is missing.' }
$calls = @($ast.FindAll({
    param($node)
    $node -is [Management.Automation.Language.CommandAst] -and
        $node.GetCommandName() -eq 'Install-AutoClipLaunchers'
}, $true))
$completionMarker = (Get-Content -LiteralPath (Join-Path $repo 'install.ps1') -Raw).LastIndexOf("'.install-complete'")
if ($calls.Count -ne 1 -or $completionMarker -lt 0 -or
    $calls[0].Extent.StartOffset -lt $completionMarker) {
    throw 'Fresh installation must create launchers only after recording a complete install.'
}
Invoke-Expression $function.Extent.Text

$root = Join-Path $env:TEMP ('autoclip-launcher-test-' + [guid]::NewGuid().ToString('N'))
$install = Join-Path $root 'runtime'
$desktop = Join-Path $root 'desktop'
New-Item -ItemType Directory -Path (Join-Path $install '.venv\Scripts'), $desktop -Force | Out-Null
try {
    $pythonw = Join-Path $install '.venv\Scripts\pythonw.exe'
    [IO.File]::WriteAllBytes($pythonw, [byte[]](1, 2, 3))
    [IO.File]::WriteAllText((Join-Path $install 'Start-AutoClip.ps1'), 'fixture')

    Install-AutoClipLaunchers -InstallRoot $install -DesktopDirectory $desktop
    $folderLink = Join-Path $install 'AutoClip.lnk'
    $desktopLink = Join-Path $desktop 'AutoClip.lnk'
    foreach ($path in @($folderLink, $desktopLink)) {
        if (-not (Test-Path -LiteralPath $path -PathType Leaf)) { throw "Launcher is missing: $path" }
        $link = (New-Object -ComObject WScript.Shell).CreateShortcut($path)
        $resolvedTarget = (Get-Item -LiteralPath $link.TargetPath).FullName
        $resolvedPythonw = (Get-Item -LiteralPath $pythonw).FullName
        $resolvedWorkingDirectory = (Get-Item -LiteralPath $link.WorkingDirectory).FullName
        $resolvedInstall = (Get-Item -LiteralPath $install).FullName
        if ($resolvedTarget -ne $resolvedPythonw -or $link.Arguments -ne '-m autoclip.desktop' -or
            $resolvedWorkingDirectory -ne $resolvedInstall) {
            throw "Launcher does not target the installed AutoClip desktop entry: $path"
        }
    }

    $existing = Join-Path $root 'existing-desktop'
    New-Item -ItemType Directory -Path $existing | Out-Null
    [IO.File]::WriteAllText((Join-Path $existing 'AutoClip.lnk'), 'existing user shortcut')
    Install-AutoClipLaunchers -InstallRoot $install -DesktopDirectory $existing
    if ([IO.File]::ReadAllText((Join-Path $existing 'AutoClip.lnk')) -ne 'existing user shortcut') {
        throw 'Installer replaced an existing desktop shortcut.'
    }
    Write-Output 'Install-folder and desktop launchers target the verified local app; existing shortcut preserved.'
} finally {
    if (-not ([IO.Path]::GetFullPath($root).StartsWith([IO.Path]::GetFullPath($env:TEMP)))) {
        throw 'Unsafe fixture cleanup.'
    }
    Remove-Item -LiteralPath $root -Recurse -Force
}
