param(
    [string]$InstallerPath = (Join-Path (Split-Path -Parent (Split-Path -Parent $PSScriptRoot)) 'install.ps1'),
    [string]$ArchivePath,
    [scriptblock]$DownloadScript
)

$ErrorActionPreference = 'Stop'
$release = & $InstallerPath -ReleaseInfo -PrerequisitesOnly
if (@($release).Count -ne 1 -or
    [string]$release.ReleaseId -notmatch '^[A-Za-z0-9][A-Za-z0-9._-]*$' -or
    [string]$release.ArchiveSha256 -notmatch '^[a-fA-F0-9]{64}$' -or
    [string]$release.ManifestSha256 -notmatch '^[a-fA-F0-9]{64}$' -or
    [string]$release.ArchiveUrl -notmatch '^https://github\.com/[^/]+/[^/]+/releases/download/[^/]+/[^/?#]+\.zip$') {
    throw 'Installer -ReleaseInfo returned an invalid pinned release identity.'
}

$downloaded = $false
try {
    if (-not $ArchivePath) {
        $ArchivePath = Join-Path ([IO.Path]::GetTempPath()) ('autoclip-public-release-' + [guid]::NewGuid().ToString('N') + '.zip')
        $downloaded = $true
        if (-not $DownloadScript) {
            $DownloadScript = { param($url, $path) Invoke-WebRequest -UseBasicParsing -Uri $url -OutFile $path }
        }
        try { & $DownloadScript $release.ArchiveUrl $ArchivePath | Out-Null }
        catch { throw "Pinned public release download failed for $($release.ReleaseId): $($_.Exception.Message)" }
    }
    if (-not (Test-Path -LiteralPath $ArchivePath -PathType Leaf)) {
        throw "Pinned release archive is missing: $ArchivePath"
    }
    $actualArchive = (Get-FileHash -LiteralPath $ArchivePath -Algorithm SHA256).Hash.ToLowerInvariant()
    if ($actualArchive -ne [string]$release.ArchiveSha256) {
        throw "Pinned public archive SHA-256 mismatch for $($release.ReleaseId): $actualArchive"
    }
    Add-Type -AssemblyName System.IO.Compression.FileSystem
    $zip = [IO.Compression.ZipFile]::OpenRead($ArchivePath)
    try {
        $entry = $zip.GetEntry('release-manifest.json')
        if (-not $entry) { throw 'Pinned public archive has no release-manifest.json.' }
        $stream = $entry.Open()
        try {
            $sha = [Security.Cryptography.SHA256]::Create()
            try { $actualManifest = ([BitConverter]::ToString($sha.ComputeHash($stream))).Replace('-', '').ToLowerInvariant() }
            finally { $sha.Dispose() }
        } finally { $stream.Dispose() }
    } finally { $zip.Dispose() }
    if ($actualManifest -ne [string]$release.ManifestSha256) {
        throw "Pinned public manifest SHA-256 mismatch for $($release.ReleaseId): $actualManifest"
    }
    Write-Output "Pinned release verified: $($release.ReleaseId); archive $actualArchive; manifest $actualManifest"
} finally {
    if ($downloaded -and (Test-Path -LiteralPath $ArchivePath)) {
        Remove-Item -LiteralPath $ArchivePath -Force
    }
}
