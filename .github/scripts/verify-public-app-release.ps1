param(
    [string]$ManifestPath = (Join-Path (Split-Path -Parent (Split-Path -Parent $PSScriptRoot)) 'app-release.json'),
    [string]$UpdaterPath = (Join-Path (Split-Path -Parent (Split-Path -Parent $PSScriptRoot)) 'update-app.ps1'),
    [string]$InstallerPath = (Join-Path (Split-Path -Parent (Split-Path -Parent $PSScriptRoot)) 'install.ps1')
)

$ErrorActionPreference = 'Stop'
$manifest = Get-Content -LiteralPath $ManifestPath -Raw | ConvertFrom-Json
$installer = & $InstallerPath -ReleaseInfo -PrerequisitesOnly
$runtimeMatches = ($manifest.required_runtime -eq $installer.ReleaseId -and
    $manifest.runtime_manifest_sha256 -eq $installer.ManifestSha256)
foreach ($compatible in @($manifest.compatible_runtimes)) {
    if ($compatible -and $compatible.release_id -eq $installer.ReleaseId -and
        $compatible.manifest_sha256 -eq $installer.ManifestSha256) {
        $runtimeMatches = $true
    }
}
if ($manifest.schema_version -ne 1 -or -not $runtimeMatches) {
    throw 'The app manifest does not identify the pinned runtime.'
}
$manifestHash = (Get-FileHash -LiteralPath $ManifestPath -Algorithm SHA256).Hash.ToLowerInvariant()
$updater = [IO.File]::ReadAllText($UpdaterPath)
if (-not $updater.Contains("expectedManifestSha256 = '$manifestHash'")) {
    throw 'The app updater does not pin the exact manifest bytes.'
}
$url = [string]$manifest.wheel_url
if ($url -notmatch '^https://github\.com/Farkoal2128/autoclip-runtime/releases/download/[^/]+/autoclip-[^/]+\.whl$') {
    throw 'The app wheel URL is not an immutable release URL.'
}
$wheel = Join-Path ([IO.Path]::GetTempPath()) ('autoclip-public-app-' + [guid]::NewGuid().ToString('N') + '.whl')
try {
    Invoke-WebRequest -UseBasicParsing -Uri $url -OutFile $wheel
    if ((Get-Item -LiteralPath $wheel).Length -ne [long]$manifest.wheel_size -or
        (Get-FileHash -LiteralPath $wheel -Algorithm SHA256).Hash -ne $manifest.wheel_sha256) {
        throw 'The public app wheel size or SHA-256 does not match the manifest.'
    }
    Add-Type -AssemblyName System.IO.Compression.FileSystem
    $zip = [IO.Compression.ZipFile]::OpenRead($wheel)
    try {
        $names = @($zip.Entries | ForEach-Object FullName)
        if ($names -notcontains 'autoclip/app.py' -or
            $names -notcontains 'autoclip/desktop.py') {
            throw 'The public app wheel is missing expected application files.'
        }
        foreach ($entry in $zip.Entries) {
            $stream = $entry.Open()
            try { $stream.CopyTo([IO.Stream]::Null) } finally { $stream.Dispose() }
        }
    } finally { $zip.Dispose() }
    Write-Output "Public app wheel verified: $url ($($manifest.wheel_size) bytes, $($manifest.wheel_sha256))"
} finally {
    if (Test-Path -LiteralPath $wheel) { Remove-Item -LiteralPath $wheel }
}
