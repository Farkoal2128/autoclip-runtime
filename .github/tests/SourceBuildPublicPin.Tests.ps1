param([string]$ArchivePath)
$ErrorActionPreference = 'Stop'
$repo = Split-Path -Parent (Split-Path -Parent $PSScriptRoot)
$release = & (Join-Path $repo 'install.ps1') -ReleaseInfo -PrerequisitesOnly
$expectedId = 'v11-20260928-source-build-candidate-v40-provenance-continuity'
$expectedArchive = 'f2b3be779294bc55d6f5f56c2a780a2d6b863486f3af9bd7d19f30051961fc9f'
$expectedManifest = '7fbf72038be30522bc176002082fddd92fd4e057159765726e77806a296658e2'
$expectedUrl = 'https://github.com/Farkoal2128/autoclip-runtime/releases/download/v0.1.0-dev0-windows-source-v40-20260928/autoclip-source-build-v40-provenance-continuity.zip'
if ($release.ReleaseId -ne $expectedId -or
    $release.ArchiveSha256 -ne $expectedArchive -or
    $release.ManifestSha256 -ne $expectedManifest -or
    $release.ArchiveUrl -ne $expectedUrl) {
    throw 'Public source-build installer pin differs from reviewed v40 bytes.'
}
$app = Get-Content -LiteralPath (Join-Path $repo 'app-release.json') -Raw | ConvertFrom-Json
$matches = @($app.compatible_runtimes | Where-Object { $_.release_id -eq $expectedId })
if ($matches.Count -ne 1 -or $matches[0].manifest_sha256 -ne $expectedManifest) {
    throw 'Public app compatibility entry does not bind exact v40 manifest.'
}
if ($ArchivePath) {
    if (-not (Test-Path -LiteralPath $ArchivePath -PathType Leaf)) {
        throw 'Supplied v40 archive is missing.'
    }
    $actualArchive = (Get-FileHash -LiteralPath $ArchivePath -Algorithm SHA256).Hash.ToLowerInvariant()
    if ($actualArchive -ne $release.ArchiveSha256) {
        throw 'Public installer archive hash does not match local v40 bytes.'
    }
    Add-Type -AssemblyName System.IO.Compression.FileSystem
    $zip = [IO.Compression.ZipFile]::OpenRead($ArchivePath)
    try {
        $manifest = $zip.GetEntry('release-manifest.json')
        if (-not $manifest) { throw 'Public installer archive has no release manifest.' }
        $reader = [IO.StreamReader]::new($manifest.Open())
        try { $raw = $reader.ReadToEnd() } finally { $reader.Dispose() }
        $sha = [Security.Cryptography.SHA256]::Create()
        try { $actualManifest = ([BitConverter]::ToString($sha.ComputeHash([Text.Encoding]::UTF8.GetBytes($raw)))).Replace('-', '').ToLowerInvariant() }
        finally { $sha.Dispose() }
        if ($actualManifest -ne $release.ManifestSha256) {
            throw 'Public installer manifest hash does not match local v40 bytes.'
        }
    } finally { $zip.Dispose() }
}
if ($ArchivePath) {
    Write-Output 'Proposed v40 installer/app identity pins and local archive passed.'
} else {
    Write-Output 'Proposed v40 installer/app identity pins passed; local archive was not supplied.'
}
