param(
    [string]$ManifestPath = (Join-Path (Split-Path -Parent (Split-Path -Parent $PSScriptRoot)) 'app-release.json'),
    [string]$UpdaterPath = (Join-Path (Split-Path -Parent (Split-Path -Parent $PSScriptRoot)) 'update-app.ps1'),
    [string]$InstallerPath = (Join-Path (Split-Path -Parent (Split-Path -Parent $PSScriptRoot)) 'install.ps1')
)

$ErrorActionPreference = 'Stop'
$manifest = Get-Content -LiteralPath $ManifestPath -Raw | ConvertFrom-Json
$installer = & $InstallerPath -ReleaseInfo -PrerequisitesOnly
if ($manifest.schema_version -ne 1 -or
    $manifest.required_runtime -ne $installer.ReleaseId -or
    $manifest.runtime_manifest_sha256 -ne $installer.ManifestSha256) {
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
