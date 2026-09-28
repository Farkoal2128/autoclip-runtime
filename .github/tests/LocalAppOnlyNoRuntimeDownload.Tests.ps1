param(
    [Parameter(Mandatory = $true)][string]$BaseRoot,
    [Parameter(Mandatory = $true)][string]$WheelPath
)

$ErrorActionPreference = 'Stop'
$repoRoot = Split-Path -Parent (Split-Path -Parent $PSScriptRoot)
$runtimeBefore = Get-Content -LiteralPath (Join-Path $BaseRoot 'active.json') -Raw
$appBefore = Get-Content -LiteralPath (Join-Path $BaseRoot 'app-active.json') -Raw | ConvertFrom-Json
$runtime = $runtimeBefore | ConvertFrom-Json
$runtimeRoot = Join-Path $BaseRoot $runtime.current.release_id
function Get-DependencyFingerprint {
    $venv = Join-Path $runtimeRoot '.venv'
    $prefix = [IO.Path]::GetFullPath($venv).TrimEnd('\') + '\'
    $rows = @(Get-ChildItem -LiteralPath $venv -Recurse -File -Force | ForEach-Object {
        $_.FullName.Substring($prefix.Length) + ':' + $_.Length + ':' +
        (Get-FileHash -LiteralPath $_.FullName -Algorithm SHA256).Hash
    } | Sort-Object)
    return ($rows -join "`n")
}
$dependencyBefore = Get-DependencyFingerprint
$legalPath = Join-Path $runtimeRoot 'notices-and-source/legal-index.json'
if (-not (Test-Path -LiteralPath $legalPath -PathType Leaf)) { throw 'Runtime legal index fixture is missing.' }
$legalHash = (Get-FileHash -LiteralPath $legalPath -Algorithm SHA256).Hash
$manifest = Join-Path ([IO.Path]::GetTempPath()) ('autoclip-app-local-' + [guid]::NewGuid().ToString('N') + '.json')
$appId = 'v23-app-only-network-proof-' + [guid]::NewGuid().ToString('N')
$wheel = Get-Item -LiteralPath $WheelPath
$shortcutPath = Join-Path $BaseRoot 'AutoClip-app-test.lnk'
$shell = New-Object -ComObject WScript.Shell
$shortcut = $shell.CreateShortcut($shortcutPath)
$shortcut.TargetPath = Join-Path $runtimeRoot '.venv\Scripts\pythonw.exe'
$shortcut.Arguments = '-m autoclip.desktop'
$shortcut.Save()
@{
    schema_version = 1
    app_id = $appId
    required_runtime = [string]$runtime.current.release_id
    runtime_manifest_sha256 = [string]$runtime.current.manifest_sha256
    wheel_url = ''
    wheel_sha256 = (Get-FileHash -LiteralPath $WheelPath -Algorithm SHA256).Hash.ToLowerInvariant()
    wheel_size = [long]$wheel.Length
} | ConvertTo-Json | Set-Content -LiteralPath $manifest -Encoding UTF8

$script:networkRequests = 0
function Invoke-WebRequest {
    $script:networkRequests++
    throw 'App-only update attempted a network download.'
}
try {
    & (Join-Path $repoRoot 'update-app.ps1') -BaseRoot $BaseRoot -ManifestPath $manifest -WheelPath $WheelPath -ShortcutPath $shortcutPath
    $shortcut = $shell.CreateShortcut($shortcutPath)
    if ([string]$shortcut.Arguments -notlike '*Start-AutoClip-Desktop.ps1*') {
        throw 'Managed shortcut did not follow the stable app launcher.'
    }
    $selected = Get-Content -LiteralPath (Join-Path $BaseRoot 'app-active.json') -Raw | ConvertFrom-Json
    if ($selected.current.app_id -ne $appId -or $selected.previous.app_id -ne $appBefore.current.app_id) {
        throw 'App-only update did not retain the previous app.'
    }
    if ($script:networkRequests -ne 0) { throw 'App-only update made a network request.' }
    if ((Get-Content -LiteralPath (Join-Path $BaseRoot 'active.json') -Raw) -ne $runtimeBefore) {
        throw 'App-only update changed the selected runtime.'
    }
    if ((Get-FileHash -LiteralPath $legalPath -Algorithm SHA256).Hash -ne $legalHash) {
        throw 'App-only update changed the runtime legal index.'
    }
    if ((Get-DependencyFingerprint) -ne $dependencyBefore) {
        throw 'App-only update changed the installed dependency environment.'
    }
    & (Join-Path $repoRoot 'update-app.ps1') -BaseRoot $BaseRoot -Rollback -ShortcutPath $shortcutPath
    $rolledBack = Get-Content -LiteralPath (Join-Path $BaseRoot 'app-active.json') -Raw | ConvertFrom-Json
    if ($rolledBack.current.app_id -ne $appBefore.current.app_id) { throw 'App rollback did not restore the previous app.' }
    if ($script:networkRequests -ne 0) { throw 'App rollback made a network request.' }
    if ((Get-DependencyFingerprint) -ne $dependencyBefore) {
        throw 'App rollback changed the installed dependency environment.'
    }
    Write-Output 'Local app update and rollback made zero network requests and retained runtime/legal/shortcut state.'
} finally {
    Remove-Item -LiteralPath $manifest -Force -ErrorAction SilentlyContinue
}
