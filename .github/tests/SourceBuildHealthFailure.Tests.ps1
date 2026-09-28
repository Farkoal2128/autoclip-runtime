param(
    [Parameter(Mandatory)][string]$BaseRoot,
    [Parameter(Mandatory)][string]$InstallerPath
)

$ErrorActionPreference = 'Stop'
$repoRoot = Split-Path -Parent (Split-Path -Parent $PSScriptRoot)
$statePath = Join-Path $BaseRoot 'active.json'
$before = (Get-FileHash -LiteralPath $statePath -Algorithm SHA256).Hash
$fixture = Join-Path ([IO.Path]::GetTempPath()) ('autoclip-health-failure-' + [guid]::NewGuid().ToString('N'))
$oldPythonPath = [Environment]::GetEnvironmentVariable('PYTHONPATH', 'Process')
New-Item -ItemType Directory -Path (Join-Path $fixture 'autoclip') | Out-Null
try {
    [IO.File]::WriteAllText((Join-Path $fixture 'autoclip/__init__.py'), '')
    [IO.File]::WriteAllText((Join-Path $fixture 'autoclip/app.py'), "def create_app():`n    raise RuntimeError('controlled candidate health failure')`n")
    $env:PYTHONPATH = $fixture
    $rejected = $false
    try {
        & (Join-Path $repoRoot 'update.ps1') -BaseRoot $BaseRoot -InstallerPath $InstallerPath -NoShortcut
    } catch {
        # An existing complete candidate first fails health, then its installer
        # safely refuses to overwrite that completed target during retry.
        if ($_.Exception.Message -notlike '*runtime failed its isolated health/home check*' -and
            $_.Exception.Message -notlike 'Install path already exists:*Choose another -InstallRoot to preserve existing data.') { throw }
        $rejected = $true
    }
    if (-not $rejected) { throw 'Candidate health failure was accepted.' }
    if ((Get-FileHash -LiteralPath $statePath -Algorithm SHA256).Hash -ne $before) {
        throw 'Candidate health failure changed the active selector.'
    }
    Write-Output 'Controlled candidate health failure was rejected; selector stayed byte-identical.'
} finally {
    [Environment]::SetEnvironmentVariable('PYTHONPATH', $oldPythonPath, 'Process')
    $resolved = [IO.Path]::GetFullPath($fixture)
    $tempRoot = [IO.Path]::GetFullPath([IO.Path]::GetTempPath()).TrimEnd('\') + '\'
    if (-not $resolved.StartsWith($tempRoot, [StringComparison]::OrdinalIgnoreCase)) {
        throw 'Fixture cleanup is outside the temporary directory.'
    }
    Remove-Item -LiteralPath $resolved -Recurse -Force
}
