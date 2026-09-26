$ErrorActionPreference = 'Stop'
$exe = Join-Path $PSScriptRoot '.venv\Scripts\autoclip.exe'
if (-not (Test-Path -LiteralPath $exe)) {
    throw "AutoClip is not installed at $PSScriptRoot. Run install.ps1 first."
}
& $exe serve
