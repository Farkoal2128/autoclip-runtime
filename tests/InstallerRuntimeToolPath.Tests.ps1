param([string]$RealFFmpegArchive,[switch]$ConfigurationOnly)
$ErrorActionPreference = 'Stop'
$repo = Split-Path -Parent $PSScriptRoot
$helper = Join-Path $repo 'installer/install-runtime-toolpath.ps1'
if ($ConfigurationOnly) {
    $tokens=$null;$errors=$null
    $ast=[Management.Automation.Language.Parser]::ParseFile($helper,[ref]$tokens,[ref]$errors)
    if ($errors.Count) {throw 'Runtime helper parse failed.'}
    $guard=$ast.Find({param($node) $node -is [Management.Automation.Language.IfStatementAst] -and $node.Extent.Text.Contains('Runtime tool startup requires the expected isolated Python 3.11.9 venv.')},$true)
    if (!$guard) {throw 'Actual configuration guard missing.'}
    # Execute the actual first-party guard, with no Python or vendor bytes/code.
    $assignment=$ast.Find({param($node) $node -is [Management.Automation.Language.AssignmentStatementAst] -and $node.Left.Extent.Text -ceq '$configuration'},$true)
    if (!$assignment -or $assignment.Extent.EndOffset -gt $guard.Extent.StartOffset) {throw 'Actual configuration boundary missing.'}
    $source=[IO.File]::ReadAllText($helper)
    $actualGuard=[scriptblock]::Create($source.Substring($assignment.Extent.EndOffset,$guard.Extent.EndOffset-$assignment.Extent.EndOffset))
    $uv="home = C:\Users\autocliplab\AppData\Local\Programs\Python\Python311`nimplementation = CPython`nuv = 0.12.19`nversion_info = 3.11.9`ninclude-system-site-packages = false`n"
    foreach ($configuration in @($uv,"version = 3.11.9`r`ninclude-system-site-packages = false`r`n","version = 3.11.9`nversion_info = 3.11.9`ninclude-system-site-packages = false`n")) {& $actualGuard}
    foreach ($configuration in @(
        "version = 3.11.9`nversion = 3.11.9`ninclude-system-site-packages = false`n",
        "version_info = 3.11.9`nversion_info = 3.11.9`ninclude-system-site-packages = false`n",
        "version = 3.11.9`nversion_info = 3.12.0`ninclude-system-site-packages = false`n",
        "version = 3.11.9`ninclude-system-site-packages = true`n",
        "version = 3.11.9`ninclude-system-site-packages = false`ninclude-system-site-packages = false`n",
        "version = 3.11.9`n",
        "include-system-site-packages = false`n",
        "version_info = 3.11.10`ninclude-system-site-packages = false`n",
        "version_info = 3.11.9`ninclude-system-site-packages = false`nimplementation = PyPy`n",
        "version_info = 3.11.9`ninclude-system-site-packages = false`nimplementation = CPython`nimplementation = CPython`n",
        "version = 3.11.9`nVERSION = 3.11.9`ninclude-system-site-packages = false`n"
    )) {
        $rejected=$false;try {& $actualGuard} catch {$rejected=$true}
        if (!$rejected) {throw ('Ambiguous/incompatible configuration accepted: '+$configuration)}
    }
    'Runtime configuration PASS: actual uv and stdlib forms; missing/duplicate/conflicting/wrong version, isolation and implementation rejected.'
    exit 0
}
if (!$RealFFmpegArchive) {throw 'Supply -ConfigurationOnly for first-party checks or explicit -RealFFmpegArchive for opt-in vendor integration.'}
$python = (Get-Command python).Source
$root = Join-Path $env:TEMP ('autoclip-path-' + [guid]::NewGuid().ToString('N'))
$release = Join-Path $root ('release space ' + [char]0x00E9 + [char]::ConvertFromUtf32(0x1F680))
$managed = Join-Path $release 'tools/ffmpeg'
$bin = Join-Path $managed 'ffmpeg-9.0.1-essentials_build/bin'
$manifestPath = Join-Path $root 'manifest.json'
$oldPath = $env:PATH; $oldPythonPath = $env:PYTHONPATH
$userPath = [Environment]::GetEnvironmentVariable('PATH','User')
$machinePath = [Environment]::GetEnvironmentVariable('PATH','Machine')
function Assert-Rejected([scriptblock]$Action, [string]$Reason) {
    try { & $Action | Out-Null } catch { if ($_.Exception.Message -notmatch $Reason) { throw }; return }
    throw "Expected rejection: $Reason"
}
New-Item -ItemType Directory -Path $bin -Force | Out-Null
try {
    $version = & $python -I -c 'import sys; print(sys.version_info[:3])'
    if ($LASTEXITCODE -ne 0 -or $version -ne '(3, 11, 9)') { throw 'Disposable fixture requires Python 3.11.9.' }
    & $python -I -m venv --without-pip (Join-Path $release '.venv')
    if ($LASTEXITCODE -ne 0) { throw 'Disposable venv creation failed.' }
    Add-Type -AssemblyName System.IO.Compression.FileSystem
    $zip = [IO.Compression.ZipFile]::OpenRead([IO.Path]::GetFullPath($RealFFmpegArchive))
    try {
        foreach ($name in @('ffmpeg.exe','ffprobe.exe')) {
            $entry = $zip.GetEntry('ffmpeg-9.0.1-essentials_build/bin/' + $name)
            if (-not $entry) { throw 'Exact FFmpeg archive member missing.' }
            [IO.Compression.ZipFileExtensions]::ExtractToFile($entry, (Join-Path $bin $name))
        }
    } finally { $zip.Dispose() }
    $manifest = Get-Content (Join-Path $repo 'release/manifests/installer-dependencies-v1.json') -Raw | ConvertFrom-Json
    $ffmpeg = @($manifest.build_prerequisites | Where-Object identity -eq 'Gyan FFmpeg')[0]
    $ffmpeg.delivery_classification = 'DIRECT_RECIPIENT_DOWNLOAD'
    function Save-Manifest { $manifest | ConvertTo-Json -Depth 30 | Set-Content -LiteralPath $manifestPath -Encoding UTF8 }
    Save-Manifest
    $site = Join-Path $release '.venv/Lib/site-packages'
    $unrelated = Join-Path $site 'unrelated.pth'
    [IO.File]::WriteAllText($unrelated, "# unrelated preserved`n")
    $unrelatedHash = (Get-FileHash $unrelated).Hash
    $venvPython = Join-Path $release '.venv/Scripts/python.exe'
    $probe = Join-Path $root 'probe.py'
    $probeCode = @'
import json, os, pathlib, shutil, sys
result=dict(ffmpeg=shutil.which('ffmpeg'), ffprobe=shutil.which('ffprobe'), path=os.environ.get('PATH'), prefix=sys.prefix)
if len(sys.argv)>1 and sys.argv[1]=='overlay':
 import toolpath_overlay_marker
 result['overlay']=toolpath_overlay_marker.release
 print(json.dumps(result))
elif len(sys.argv)>1:
 pathlib.Path(sys.argv[1]).write_text(json.dumps(result),encoding='utf-8')
else:
 print(json.dumps(result))
'@
    [IO.File]::WriteAllText($probe, $probeCode)
    function Probe { (& $venvPython -I $probe | Out-String) | ConvertFrom-Json }
    $baseline = Probe
    if ($baseline.ffmpeg -eq (Join-Path $bin 'ffmpeg.exe')) { throw 'Fixture unexpectedly registered before test.' }
    function Register { & $helper -ReleaseRoot $release -ManagedToolRoot $managed -ManifestPath $manifestPath }
    if (Test-Path -LiteralPath $helper) { $receipt = Register }
    $result = Probe
    if ($result.ffmpeg -ne (Join-Path $bin 'ffmpeg.exe') -or $result.ffprobe -ne (Join-Path $bin 'ffprobe.exe')) {
        throw 'Isolated venv startup must discover the managed FFmpeg and FFprobe without launcher PATH changes.'
    }
    if ($result.path -ne ($bin + ';' + $oldPath)) { throw 'Startup must prepend only the managed bin to inherited process PATH.' }
    if ($result.prefix -ne (Join-Path $release '.venv')) { throw 'Probe must run in the expected release venv.' }
    if ($receipt.pth_sha256 -ne (Get-FileHash $receipt.pth_path).Hash.ToLowerInvariant()) { throw 'Startup registration receipt must bind exact content.' }
    $again = Register
    if ($again.pth_sha256 -ne $receipt.pth_sha256) { throw 'Exact owned registration must be idempotent.' }
    $windowResult = Join-Path $root 'pythonw-result.json'
    $process = Start-Process -FilePath (Join-Path $release '.venv/Scripts/pythonw.exe') -ArgumentList @('-I', ('"' + $probe + '"'), ('"' + $windowResult + '"')) -WindowStyle Hidden -Wait -PassThru
    if ($process.ExitCode -ne 0 -or -not (Test-Path $windowResult)) { throw 'Direct pythonw startup failed.' }
    $windowProbe = Get-Content $windowResult -Raw | ConvertFrom-Json
    if ($windowProbe.ffmpeg -ne $result.ffmpeg -or $windowProbe.ffprobe -ne $result.ffprobe) { throw 'Direct pythonw must retain managed tool discovery.' }
    $env:PYTHONPATH = Join-Path $root 'app-layer'
    New-Item -ItemType Directory -Path $env:PYTHONPATH | Out-Null
    [IO.File]::WriteAllText((Join-Path $env:PYTHONPATH 'toolpath_overlay_marker.py'), "release = 'probe-overlay'")
    $overlayProbe = (& $venvPython $probe overlay | Out-String) | ConvertFrom-Json
    if ($overlayProbe.overlay -ne 'probe-overlay' -or $overlayProbe.ffmpeg -ne $result.ffmpeg -or $overlayProbe.ffprobe -ne $result.ffprobe) { throw 'Separate app-layer PYTHONPATH must preserve runtime tool startup.' }
    $ffmpeg.delivery_classification = 'BLOCKED'; Save-Manifest
    Assert-Rejected { Register } 'DIRECT_RECIPIENT_DOWNLOAD'
    $ffmpeg.delivery_classification = 'DIRECT_RECIPIENT_DOWNLOAD'
    $ffmpeg.executable_pins[0].sha256 = '0' * 64; Save-Manifest
    Assert-Rejected { Register } 'executable pins'
    $ffmpeg.executable_pins[0].sha256 = '72a489eccd008c2ec2c0a5856c5c75bc3d8bbfa90166c4566865c246445e6aa3'; Save-Manifest
    Assert-Rejected { & $helper -ReleaseRoot $release -ManagedToolRoot (Join-Path $root 'foreign') -ManifestPath $manifestPath } 'managed'
    Assert-Rejected { & $helper -ReleaseRoot ($release + '\..\escape') -ManagedToolRoot $managed -ManifestPath $manifestPath } 'traversal'
    $junction = Join-Path $root 'release-junction'
    New-Item -ItemType Junction -Path $junction -Target $release | Out-Null
    try {
        Assert-Rejected { & $helper -ReleaseRoot $junction -ManagedToolRoot (Join-Path $junction 'tools/ffmpeg') -ManifestPath $manifestPath } 'reparse'
    } finally { [IO.Directory]::Delete($junction) }
    $cfg = Join-Path $release '.venv/pyvenv.cfg'
    $cfgBytes = [IO.File]::ReadAllBytes($cfg)
    [IO.File]::WriteAllText($cfg, 'version = 3.10.9')
    Assert-Rejected { Register } 'isolated Python'
    [IO.File]::WriteAllBytes($cfg, $cfgBytes)
    $executable = Join-Path $bin 'ffprobe.exe'
    $originalLength = (Get-Item -LiteralPath $executable).Length
    $stream = [IO.File]::OpenWrite($executable)
    try { $stream.Position = $originalLength; $stream.WriteByte(0) } finally { $stream.Dispose() }
    Assert-Rejected { Register } 'SHA-256'
    $stream = [IO.File]::OpenWrite($executable)
    try { $stream.SetLength($originalLength) } finally { $stream.Dispose() }
    [IO.File]::WriteAllText($receipt.pth_path, '# foreign content')
    $foreignHash = (Get-FileHash $receipt.pth_path).Hash
    Assert-Rejected { Register } 'foreign|different'
    if ((Get-FileHash $receipt.pth_path).Hash -ne $foreignHash) { throw 'Foreign startup content was overwritten.' }
    if ((Get-FileHash $unrelated).Hash -ne $unrelatedHash) { throw 'Unrelated startup file changed.' }
    if ($env:PATH -cne $oldPath -or [Environment]::GetEnvironmentVariable('PATH','User') -cne $userPath -or [Environment]::GetEnvironmentVariable('PATH','Machine') -cne $machinePath) { throw 'Parent, user or system PATH changed.' }
    'Runtime tool PATH PASS: real Python 3.11.9 isolated/pythonw/app-layer startup, Unicode/spaces, exact pins, idempotence and foreign file preservation; no global PATH change'
} finally {
    $env:PATH = $oldPath
    [Environment]::SetEnvironmentVariable('PYTHONPATH',$oldPythonPath,'Process')
    $resolved = [IO.Path]::GetFullPath($root)
    if (-not $resolved.StartsWith([IO.Path]::GetFullPath($env:TEMP).TrimEnd('\') + '\',[StringComparison]::OrdinalIgnoreCase)) { throw 'Unsafe fixture cleanup.' }
    Remove-Item -LiteralPath $resolved -Recurse -Force
}
