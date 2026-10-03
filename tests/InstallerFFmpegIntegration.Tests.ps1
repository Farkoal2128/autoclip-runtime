param(
    [string]$RealFfmpegArchive = 'D:\AutoClip-Inno-Migration\ffmpeg-9.0.1-essentials_build.zip',
    [string]$PythonPath = 'C:\Users\beilo\AppData\Local\Programs\Python\Python311\python.exe'
)
$ErrorActionPreference = 'Stop'
$repo = Split-Path -Parent $PSScriptRoot
$root = Join-Path $env:TEMP ('autoclip-ffmpeg-integration-' + [guid]::NewGuid().ToString('N'))
[IO.Directory]::CreateDirectory($root) | Out-Null
$originalPath = $env:PATH
$userPath = [Environment]::GetEnvironmentVariable('PATH', 'User')
$machinePath = [Environment]::GetEnvironmentVariable('PATH', 'Machine')
$ffmpegContext = $null
try {
    foreach ($name in @('install-tool-archive.ps1', 'install-runtime-toolpath.ps1')) {
        Copy-Item -LiteralPath (Join-Path $repo ('installer\' + $name)) -Destination (Join-Path $root $name)
    }
    $manifest = Get-Content (Join-Path $repo 'release/manifests/installer-dependencies-v1.json') -Raw | ConvertFrom-Json
    $ffmpegPin = @($manifest.build_prerequisites | Where-Object identity -eq 'Gyan FFmpeg')[0]
    $ffmpegPin.delivery_classification = 'DIRECT_RECIPIENT_DOWNLOAD' # Separate validation fixture only.
    $manifestPath = Join-Path $root 'manifest.json'
    function Save-Manifest {
        $manifest | ConvertTo-Json -Depth 35 | Set-Content -LiteralPath $manifestPath -Encoding UTF8
        $script:SecureAcquisition = [pscustomobject]@{ ManifestPath = $manifestPath; ManifestSha256 = (Get-FileHash $manifestPath).Hash }
    }
    Save-Manifest
    $archiveHelperHash = (Get-FileHash (Join-Path $root 'install-tool-archive.ps1')).Hash
    $runtimeHelperHash = (Get-FileHash (Join-Path $root 'install-runtime-toolpath.ps1')).Hash
    if ($runtimeHelperHash -ne 'c959d360a99155179262058ecc311edd9f36f14926b7edcdf239273e619e4f68') { throw 'Expected frozen runtime toolpath helper differs.' }
    $tokens = $null; $errors = $null
    $ast = [Management.Automation.Language.Parser]::ParseFile((Join-Path $repo 'install.ps1'), [ref]$tokens, [ref]$errors)
    if ($errors) { throw 'Installer parse failed.' }
    foreach ($name in @('Assert-AutoClipSecurePath', 'Read-AutoClipSecureInput', 'Initialize-AutoClipFfmpeg', 'Get-AutoClipFfmpegInventory', 'Retain-AutoClipFfmpeg', 'Register-AutoClipFfmpeg')) {
        $node = $ast.Find({ param($n) $n -is [Management.Automation.Language.FunctionDefinitionAst] -and $n.Name -eq $name }, $false)
        if ($node) { Invoke-Expression ($node.Extent.Text.Replace('$PSScriptRoot', ("'" + $root.Replace("'", "''") + "'"))) }
    }
    # Clean-guest boundary: no FFmpeg exists on the fixture process PATH.
    $env:PATH = Join-Path $env:WINDIR 'System32'
    if (Get-Command ffmpeg.exe -ErrorAction SilentlyContinue) { throw 'RED fixture unexpectedly has FFmpeg on PATH.' }
    if (Get-Command Initialize-AutoClipFfmpeg -ErrorAction SilentlyContinue) {
        # Inno's guest TEMP can contain an existing Windows 8.3 user-directory alias.
        $originalTemp = $env:TEMP
        $fileSystem = New-Object -ComObject Scripting.FileSystemObject
        $shortTemp = $fileSystem.GetFolder($root).ShortPath
        if ($shortTemp -eq [IO.Path]::GetFullPath($shortTemp)) { throw 'Short TEMP fixture must use a genuine Windows 8.3 alias.' }
        $env:TEMP = $shortTemp
        try {
            $ffmpegContext = Initialize-AutoClipFfmpeg -ArchivePath $RealFfmpegArchive -ArchiveHelperSha256 $archiveHelperHash -RuntimeHelperSha256 $runtimeHelperHash -SecureRoute
        } finally { $env:TEMP = $originalTemp }
        $env:PATH = $ffmpegContext.Bin + ';' + $env:PATH
    }
    $found = Get-Command ffmpeg.exe -ErrorAction SilentlyContinue
    $probeFound = Get-Command ffprobe.exe -ErrorAction SilentlyContinue
    if (-not $found -or -not $probeFound -or $found.Source -ne (Join-Path $ffmpegContext.Bin 'ffmpeg.exe')) {
        throw 'Guarded prerequisite checks must discover the verified FFmpeg/FFprobe without winget acquisition.'
    }
    $filters = & $found.Source -hide_banner -filters | Out-String
    $encoders = & $found.Source -hide_banner -encoders | Out-String
    if ($LASTEXITCODE -ne 0 -or $filters -notmatch '\bass\s' -or $filters -notmatch '\bsubtitles\s' -or $encoders -notmatch '\blibx264\s') { throw 'Actual FFmpeg media prerequisites failed.' }
    function Assert-Rejected([scriptblock]$Action, [string]$Message) {
        $failed = $false
        try { & $Action | Out-Null } catch { $failed = $true }
        if (-not $failed) { throw "Expected rejection: $Message" }
    }
    Assert-Rejected { Initialize-AutoClipFfmpeg -ArchivePath $RealFfmpegArchive -ArchiveHelperSha256 $archiveHelperHash -RuntimeHelperSha256 $runtimeHelperHash } 'unguarded helper inputs'
    Assert-Rejected { Initialize-AutoClipFfmpeg -SecureRoute } 'missing guarded FFmpeg inputs'
    Assert-Rejected { Initialize-AutoClipFfmpeg -ArchivePath $RealFfmpegArchive -SecureRoute } 'partial guarded FFmpeg inputs'
    if (Initialize-AutoClipFfmpeg) { throw 'Legacy route should not stage tools.' }
    Assert-Rejected { Retain-AutoClipFfmpeg -Context $ffmpegContext -ReleaseRoot (Join-Path $root 'release;delimiter') } 'PATH delimiter in retained root'
    $release = Join-Path $root 'release with spaces'
    [IO.Directory]::CreateDirectory($release) | Out-Null
    $managed = Retain-AutoClipFfmpeg -Context $ffmpegContext -ReleaseRoot $release
    $firstInventory = @(Get-AutoClipFfmpegInventory $managed)
    if (Compare-Object @(Get-AutoClipFfmpegInventory $ffmpegContext.ExtractionRoot) $firstInventory) { throw 'Retained tree altered or omitted original archive entries.' }
    if ((Retain-AutoClipFfmpeg -Context $ffmpegContext -ReleaseRoot $release) -ne $managed) { throw 'Matching owned rerun was not reused.' }
    $license = Join-Path $managed 'ffmpeg-9.0.1-essentials_build\LICENSE'
    if (-not (Test-Path $license -PathType Leaf)) { throw 'Original LICENSE was not retained.' }
    $licenseOriginal = [IO.File]::ReadAllBytes($license)
    [IO.File]::AppendAllText($license, 'changed')
    Assert-Rejected { Retain-AutoClipFfmpeg -Context $ffmpegContext -ReleaseRoot $release } 'altered supplier notice'
    [IO.File]::WriteAllBytes($license, $licenseOriginal)
    $stagedLicense = Join-Path $ffmpegContext.ExtractionRoot 'ffmpeg-9.0.1-essentials_build\LICENSE'
    [IO.File]::AppendAllText($stagedLicense, 'changed')
    Assert-Rejected { Retain-AutoClipFfmpeg -Context $ffmpegContext -ReleaseRoot $release } 'temporary verified tree changed'
    [IO.File]::WriteAllBytes($stagedLicense, $licenseOriginal)
    $foreignRelease = Join-Path $root 'foreign release'
    $foreignManaged = Join-Path $foreignRelease 'tools\ffmpeg'
    [IO.Directory]::CreateDirectory($foreignManaged) | Out-Null
    [IO.File]::WriteAllText((Join-Path $foreignManaged 'foreign.txt'), 'preserve')
    Assert-Rejected { Retain-AutoClipFfmpeg -Context $ffmpegContext -ReleaseRoot $foreignRelease } 'foreign tree'
    if ([IO.File]::ReadAllText((Join-Path $foreignManaged 'foreign.txt')) -ne 'preserve') { throw 'Foreign tool tree was changed.' }
    & $PythonPath -I -B -m venv --without-pip (Join-Path $release '.venv')
    if ($LASTEXITCODE -ne 0) { throw 'Disposable venv creation failed.' }
    $env:PATH = Join-Path $env:WINDIR 'System32'
    $venvPython = Join-Path $release '.venv\Scripts\python.exe'
    $pythonProbe = "import json,shutil; print(json.dumps([shutil.which('ffmpeg'),shutil.which('ffprobe')]))"
    $before = & $venvPython -I -B -c $pythonProbe | ConvertFrom-Json
    if ($LASTEXITCODE -ne 0 -or $before[0] -or $before[1]) { throw 'Pre-registration fixture unexpectedly discovers FFmpeg.' }
    $receipt = Register-AutoClipFfmpeg -Context $ffmpegContext -ReleaseRoot $release
    $after = & $venvPython -I -B -c $pythonProbe | ConvertFrom-Json
    $expectedBin = Join-Path $managed 'ffmpeg-9.0.1-essentials_build\bin'
    if ($LASTEXITCODE -ne 0 -or $after[0] -ne (Join-Path $expectedBin 'ffmpeg.exe') -or $after[1] -ne (Join-Path $expectedBin 'ffprobe.exe')) { throw 'Isolated disposable venv startup did not discover both retained tools.' }
    if ($receipt.managed_bin -ne $expectedBin -or -not (Test-Path $receipt.pth_path)) { throw 'Runtime tool registration receipt is missing.' }
    $receiptPath = Join-Path $release '.inno-runtime-tools.json'
    $receiptBytes = [IO.File]::ReadAllBytes($receiptPath)
    $persisted = [Text.Encoding]::UTF8.GetString($receiptBytes) | ConvertFrom-Json
    if ($persisted.status -ne 'configured' -or $persisted.toolpath.pth_sha256 -ne $receipt.pth_sha256) { throw 'Persistent configured-only runtime receipt is missing.' }
    Register-AutoClipFfmpeg -Context $ffmpegContext -ReleaseRoot $release | Out-Null
    if ([Convert]::ToBase64String($receiptBytes) -ne [Convert]::ToBase64String([IO.File]::ReadAllBytes($receiptPath))) { throw 'Idempotent registration changed receipt bytes.' }
    Retain-AutoClipFfmpeg -Context $ffmpegContext -ReleaseRoot $release | Out-Null
    if (-not $ffmpegContext.ExistingReceiptHash) { throw 'Owned rerun did not validate the existing receipt before retry allowance.' }
    $InstallRoot = $release; $rootFull = [IO.Path]::GetFullPath($release).TrimEnd('\') + '\'; $resumeIncomplete = $true
    $expectedFiles = New-Object 'System.Collections.Generic.HashSet[string]' ([StringComparer]::OrdinalIgnoreCase)
    $retry = $ast.Find({ param($n) $n -is [Management.Automation.Language.IfStatementAst] -and $n.Extent.Text.StartsWith('if ($resumeIncomplete)') -and $n.Extent.Text.Contains('Unexpected file in incomplete install') }, $true)
    if (-not $retry) { throw 'Installer retry inventory boundary is missing.' }
    Invoke-Expression $retry.Extent.Text
    [IO.File]::WriteAllText((Join-Path $release 'unrelated.txt'), 'preserve')
    Assert-Rejected { Invoke-Expression $retry.Extent.Text } 'unrelated incomplete-install file'
    [IO.File]::Delete((Join-Path $release 'unrelated.txt'))
    [IO.File]::WriteAllText($receiptPath, 'foreign receipt')
    Assert-Rejected { Register-AutoClipFfmpeg -Context $ffmpegContext -ReleaseRoot $release } 'foreign persistent receipt'
    if ([IO.File]::ReadAllText($receiptPath) -ne 'foreign receipt') { throw 'Foreign receipt was overwritten.' }
    [IO.File]::WriteAllBytes($receiptPath, $receiptBytes)
    [IO.File]::AppendAllText((Join-Path $root 'install-runtime-toolpath.ps1'), '# changed')
    Assert-Rejected { Register-AutoClipFfmpeg -Context $ffmpegContext -ReleaseRoot $release } 'changed runtime helper before registration'
    [IO.File]::AppendAllText((Join-Path $root 'install-tool-archive.ps1'), '# changed')
    Assert-Rejected { Initialize-AutoClipFfmpeg -ArchivePath $RealFfmpegArchive -ArchiveHelperSha256 $archiveHelperHash -RuntimeHelperSha256 $runtimeHelperHash -SecureRoute } 'changed archive helper'
    foreach ($name in @('install-tool-archive.ps1', 'install-runtime-toolpath.ps1')) { Copy-Item -LiteralPath (Join-Path $repo ('installer\' + $name)) -Destination (Join-Path $root $name) -Force }
    $ffmpegPin.delivery_classification = 'BLOCKED'; Save-Manifest
    Assert-Rejected { Initialize-AutoClipFfmpeg -ArchivePath $RealFfmpegArchive -ArchiveHelperSha256 $archiveHelperHash -RuntimeHelperSha256 $runtimeHelperHash -SecureRoute } 'BLOCKED production route'
    $source = Get-Content (Join-Path $repo 'install.ps1') -Raw
    $initPosition = $source.IndexOf('$ffmpegContext = Initialize-AutoClipFfmpeg')
    $retainPosition = $source.IndexOf('$managedFfmpeg = Retain-AutoClipFfmpeg')
    $registerPosition = $source.IndexOf('$ffmpegRuntimeReceipt = Register-AutoClipFfmpeg')
    $completePosition = $source.IndexOf("Write-AutoClipCompletionFile (Join-Path `$InstallRoot '.install-complete')")
    if ($initPosition -lt 0 -or $initPosition -gt $source.IndexOf("`$ffmpeg = Require-Tool") -or
        $retainPosition -lt $source.IndexOf('Expand-Archive -LiteralPath $ArchivePath') -or
        $completePosition -lt 0 -or $registerPosition -lt $source.IndexOf('& $uv.Source venv') -or $registerPosition -gt $completePosition) {
        throw 'FFmpeg staging, retention and registration must precede their dependent installer stages.'
    }
    if ([Environment]::GetEnvironmentVariable('PATH','User') -ne $userPath -or [Environment]::GetEnvironmentVariable('PATH','Machine') -ne $machinePath) { throw 'Global PATH changed.' }
    $cleanup = $ast.Find({ param($n) $n -is [Management.Automation.Language.TryStatementAst] -and $n.Finally -and $n.Finally.Extent.Text.Contains('Assert-AutoClipSecurePath $ffmpegContext.StageRoot') }, $true)
    if (-not $cleanup) { throw 'Owned FFmpeg process PATH/TEMP cleanup is missing.' }
    $ffmpegProcessPath = $originalPath
    & ([scriptblock]::Create($cleanup.Finally.Extent.Text.Trim().Substring(1).TrimEnd().TrimEnd('}')))
    if ($env:PATH -ne $originalPath -or (Test-Path $ffmpegContext.StageRoot)) { throw 'Actual installer cleanup did not restore PATH and remove owned TEMP.' }
    'FFmpeg integration: real exact ZIP/helper extraction, retained complete notices, owned rerun/foreign rejection, native venv startup, trusted helper inputs and stage ordering PASS'
} finally {
    $env:PATH = $originalPath
    if ($ffmpegContext -and (Test-Path $ffmpegContext.StageRoot)) { Remove-Item -LiteralPath $ffmpegContext.StageRoot -Recurse -Force }
    if (Test-Path $root) { Remove-Item -LiteralPath $root -Recurse -Force }
}
