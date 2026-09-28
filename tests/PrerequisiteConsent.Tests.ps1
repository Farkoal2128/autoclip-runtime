$ErrorActionPreference = 'Stop'
$repo = Split-Path -Parent $PSScriptRoot
. (Join-Path $repo 'cuda-prerequisites.ps1')
$root = Join-Path $env:TEMP ('autoclip-consent-' + [guid]::NewGuid().ToString('N'))
New-Item -ItemType Directory -Path $root | Out-Null
$script:downloads = 0
$script:installs = 0
function Confirm-PrerequisiteTerms { throw 'Recipient declined prerequisite terms.' }
try {
    $rejected = $false
    try {
        Ensure-CudaPrerequisites -CudaRoot $root -StandardRoot $root -CacheRoot $root -ProbeScript { $false } -DownloadScript { param($uri,$path) $script:downloads++; [IO.File]::WriteAllBytes($path,[byte[]](1,2,3)) } -InstallScript { param($file,$arguments) $script:installs++; return 0 } -InstallerSize 3 -InstallerSha256 '039058c6f2c0cb492c533b0a4d14ef77cc0f78abccced5287d84a1a2011cfb81' | Out-Null
    } catch { $rejected = $_.Exception.Message -eq 'Recipient declined prerequisite terms.' }
    if (-not $rejected -or $downloads -ne 0 -or $installs -ne 0) { throw "Declined CUDA consent must prevent acquisition and installation (downloads=$downloads, installs=$installs)." }
    $tokens=$null; $errors=$null
    $ast=[Management.Automation.Language.Parser]::ParseFile((Join-Path $repo 'install-source-build.ps1'),[ref]$tokens,[ref]$errors)
    $fn=$ast.Find({param($n) $n -is [Management.Automation.Language.FunctionDefinitionAst] -and $n.Name -eq 'Install-WingetPackage'},$true)
    Invoke-Expression $fn.Extent.Text
    function Update-ProcessPath { }
    $record=Join-Path $root 'winget-called'
    [IO.File]::WriteAllText((Join-Path $root 'winget.cmd'), "@echo off`r`necho called > `"$record`"`r`nexit /b 0`r`n")
    $oldPath=$env:Path; $env:Path="$root;$oldPath"
    $rejected=$false
    try { Install-WingetPackage 'Microsoft.VisualStudio.2022.BuildTools' '17.14.41' } catch { $rejected=$_.Exception.Message -eq 'Recipient declined prerequisite terms.' }
    if (-not $rejected -or (Test-Path $record)) { throw 'Declined Build Tools consent must prevent winget installation.' }
    $manifest=Join-Path $root 'manifest.json'
    @{schema_version=3;publisher_wheels=@();external_assets=@(@{kind='python_wheel';filename='nvidia_cublas_cu12-12.4.5.8-py3-none-win_amd64.whl';url='https://files.pythonhosted.org/fixture.whl';sha256='039058c6f2c0cb492c533b0a4d14ef77cc0f78abccced5287d84a1a2011cfb81';bytes=3})} | ConvertTo-Json -Depth 5 | Set-Content $manifest
    $rejected=$false
    try { & (Join-Path $repo 'Prepare-AutoClipOfflineCache.ps1') -ManifestPath $manifest -CacheRoot (Join-Path $root 'cublas') -InstallNvidiaGpu -DownloadScript {param($url,$path) $script:downloads++; [IO.File]::WriteAllBytes($path,[byte[]](1,2,3))} } catch { $rejected=$_.Exception.Message -eq 'Recipient declined prerequisite terms.' }
    if (-not $rejected -or $downloads -ne 0) { throw 'Declined cuBLAS consent must prevent publisher wheel acquisition.' }
    Write-Output 'Declined CUDA and Microsoft terms prevented all installer/acquisition side effects.'
} finally {
    if ($oldPath) { $env:Path=$oldPath }
    if (-not ([IO.Path]::GetFullPath($root).StartsWith([IO.Path]::GetFullPath($env:TEMP)))) { throw 'Unsafe fixture cleanup' }
    Remove-Item -LiteralPath $root -Recurse -Force
}
