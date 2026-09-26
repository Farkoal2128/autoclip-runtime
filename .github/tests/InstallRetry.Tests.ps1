param([Parameter(Mandatory)][string]$InstalledRoot)

$ErrorActionPreference = 'Stop'
$repoRoot = Split-Path -Parent (Split-Path -Parent $PSScriptRoot)
$installer = Join-Path $repoRoot 'install.ps1'
$fixture = Join-Path ([IO.Path]::GetTempPath()) ('autoclip-install-retry-' + [guid]::NewGuid().ToString('N'))
New-Item -ItemType Directory -Path (Join-Path $fixture '.venv') -Force | Out-Null
Copy-Item -LiteralPath (Join-Path $InstalledRoot 'release-manifest.json') -Destination $fixture
[IO.File]::WriteAllText((Join-Path $fixture '.venv\stale.txt'), 'interrupted environment')

# A verified extracted release with an interrupted virtual environment must
# reach archive validation on retry, rather than be refused as an existing install.
try {
    & $installer -InstallRoot $fixture -ArchivePath 'C:\missing-autoclip-release.zip'
    throw 'The missing archive unexpectedly installed.'
} catch {
    if ($_.Exception.Message -like 'Install path already exists:*') { throw }
    if ($_.Exception.Message -notlike '*missing-autoclip-release.zip*') { throw }
}

# A completed install must still be protected from an accidental overwrite.
try {
    & $installer -InstallRoot $InstalledRoot -ArchivePath 'C:\missing-autoclip-release.zip'
    throw 'The completed install was not protected.'
} catch {
    if ($_.Exception.Message -notlike 'Install path already exists:*') { throw }
}

Write-Output 'Interrupted-environment retry and completed-install protection passed.'
