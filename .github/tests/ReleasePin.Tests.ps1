$ErrorActionPreference = 'Stop'
$checker = Join-Path (Split-Path -Parent $PSScriptRoot) 'scripts\verify-public-release.ps1'
$fixture = Join-Path ([IO.Path]::GetTempPath()) ('autoclip-release-pin-' + [guid]::NewGuid().ToString('N'))
New-Item -ItemType Directory -Path $fixture | Out-Null
try {
    Add-Type -AssemblyName System.IO.Compression.FileSystem
    $archive = Join-Path $fixture 'candidate.zip'
    $manifestText = '{"files":[]}'
    $zip = [IO.Compression.ZipFile]::Open($archive, 'Create')
    try {
        $entry = $zip.CreateEntry('release-manifest.json')
        $writer = [IO.StreamWriter]::new($entry.Open())
        try { $writer.Write($manifestText) } finally { $writer.Dispose() }
    } finally { $zip.Dispose() }
    $archiveHash = (Get-FileHash -LiteralPath $archive -Algorithm SHA256).Hash.ToLowerInvariant()
    $sha = [Security.Cryptography.SHA256]::Create()
    try { $manifestHash = ([BitConverter]::ToString($sha.ComputeHash([Text.Encoding]::UTF8.GetBytes($manifestText)))).Replace('-', '').ToLowerInvariant() }
    finally { $sha.Dispose() }
    $installer = Join-Path $fixture 'installer.ps1'
    function Write-FixtureInstaller([string]$ArchiveHash, [string]$ManifestHash) {
        $content = @"
param([switch]`$ReleaseInfo, [switch]`$PrerequisitesOnly)
if (`$ReleaseInfo) {
    [pscustomobject]@{ ReleaseId = 'fixture'; ArchiveUrl = 'https://github.com/Farkoal2128/autoclip-runtime/releases/download/fixture/candidate.zip'; ArchiveSha256 = '$ArchiveHash'; ManifestSha256 = '$ManifestHash' }
}
"@
        [IO.File]::WriteAllText($installer, $content)
    }
    function Assert-Fails([scriptblock]$Action, [string]$Pattern) {
        try { & $Action; throw 'Unexpected success' } catch {
            if ($_.Exception.Message -notlike $Pattern) { throw }
        }
    }
    Write-FixtureInstaller $archiveHash $manifestHash
    & $checker -InstallerPath $installer -ArchivePath $archive | Out-Null
    Assert-Fails { & $checker -InstallerPath $installer -DownloadScript { param($url, $path) throw 'HTTP 404 Not Found' } } '*404*'
    Write-FixtureInstaller ('0' * 64) $manifestHash
    Assert-Fails { & $checker -InstallerPath $installer -ArchivePath $archive } '*archive SHA-256 mismatch*'
    Write-FixtureInstaller $archiveHash ('0' * 64)
    Assert-Fails { & $checker -InstallerPath $installer -ArchivePath $archive } '*manifest SHA-256 mismatch*'
    Write-Output 'Public release pin identity, 404, archive and manifest checks passed.'
} finally {
    Remove-Item -LiteralPath $fixture -Recurse -Force
}
