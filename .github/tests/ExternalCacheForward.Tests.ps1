$ErrorActionPreference = 'Stop'
$repoRoot = Split-Path -Parent (Split-Path -Parent $PSScriptRoot)
$fixture = Join-Path ([IO.Path]::GetTempPath()) ('autoclip-cache-forward-' + [guid]::NewGuid().ToString('N'))
New-Item -ItemType Directory -Path $fixture | Out-Null
try {
    $installer = Join-Path $fixture 'installer.ps1'
    [IO.File]::WriteAllText($installer, @'
param([switch]$ReleaseInfo, [switch]$PrerequisitesOnly, [string]$InstallRoot, [string]$ArchivePath, [string]$ExternalCache, [string]$NativeBuildRoot, [string]$MsysBash, [string]$CudaRoot)
if ($ReleaseInfo) {
    [pscustomobject]@{ ReleaseId='fixture'; ArchiveSha256=('a'*64); ManifestSha256=('b'*64); ArchiveUrl='' }
    return
}
if ($ExternalCache -ne 'publisher-cache-fixture') { throw "Publisher cache was not forwarded: $ExternalCache" }
if ($NativeBuildRoot -ne 'fixture-build') { throw 'Native build root was not forwarded.' }
if ($MsysBash -ne 'fixture-bash' -or $CudaRoot -ne 'fixture-cuda') { throw 'Native build prerequisites were not forwarded.' }
throw 'Publisher cache and native build prerequisites forwarded'
'@)
    try {
        & (Join-Path $repoRoot 'update.ps1') -BaseRoot (Join-Path $fixture 'runtime') -InstallerPath $installer -ArchivePath 'fixture.zip' -ExternalCache 'publisher-cache-fixture' -NativeBuildRoot 'fixture-build' -MsysBash 'fixture-bash' -CudaRoot 'fixture-cuda' -NoShortcut
        throw 'Updater unexpectedly succeeded.'
    } catch {
        if ($_.Exception.Message -ne 'Publisher cache and native build prerequisites forwarded') { throw }
    }
    Write-Output 'Updater forwarded the publisher cache path.'
} finally {
    Remove-Item -LiteralPath $fixture -Recurse -Force
}
