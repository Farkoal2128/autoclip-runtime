param([string]$RealMinGitArchive, [string]$RealUvArchive, [string]$RealFfmpegArchive)

$ErrorActionPreference = 'Stop'
$repo = Split-Path -Parent $PSScriptRoot
$helper = Join-Path $repo 'installer/install-tool-archive.ps1'
$root = Join-Path $env:TEMP ('autoclip-mingit-test-' + [guid]::NewGuid().ToString('N'))
New-Item -ItemType Directory -Path $root | Out-Null
try {
    $archive = Join-Path $root 'fixture.zip'
    Add-Type -AssemblyName System.IO.Compression
    Add-Type -AssemblyName System.IO.Compression.FileSystem
    $zip = [IO.Compression.ZipFile]::Open($archive, [IO.Compression.ZipArchiveMode]::Create)
    try {
        $entry = $zip.CreateEntry('../escaped.txt')
        $writer = New-Object IO.StreamWriter($entry.Open())
        try { $writer.Write('escape') } finally { $writer.Dispose() }
    } finally { $zip.Dispose() }
    $manifest = Join-Path $root 'manifest.json'
    $pin = [ordered]@{
        schema_version = 1
        build_prerequisites = @([ordered]@{
            identity = 'Git for Windows'
            version = '2.55.0.3'
            delivery_classification = 'DIRECT_RECIPIENT_DOWNLOAD'
            bytes = (Get-Item -LiteralPath $archive).Length
            sha256 = (Get-FileHash -LiteralPath $archive -Algorithm SHA256).Hash.ToLowerInvariant()
        })
    }
    $pin | ConvertTo-Json -Depth 5 | Set-Content -LiteralPath $manifest -Encoding UTF8
    $dest = Join-Path $root 'mingit'
    $rejected = $false
    try { & $helper -Identity 'Git for Windows' -ArchivePath $archive -ManifestPath $manifest -DestinationRoot $dest | Out-Null } catch { $rejected = $true }
    if (-not $rejected -or (Test-Path -LiteralPath $dest)) { throw 'Archive traversal must fail before extraction.' }
    if (Test-Path -LiteralPath (Join-Path $root 'escaped.txt')) { throw 'Archive escaped staging.' }

    $pin.build_prerequisites[0].sha256 = '0' * 64
    $pin | ConvertTo-Json -Depth 5 | Set-Content -LiteralPath $manifest -Encoding UTF8
    $rejected = $false
    try { & $helper -Identity 'Git for Windows' -ArchivePath $archive -ManifestPath $manifest -DestinationRoot $dest | Out-Null } catch { $rejected = $true }
    if (-not $rejected -or (Test-Path -LiteralPath $dest)) { throw 'Archive hash mismatch must fail closed.' }

    foreach ($unsafe in @(@('bad?.txt'), @('NUL.txt'), @('trailing./x'), @('same.txt', 'SAME.txt'), @('C:/escaped.txt'))) {
        $unsafeZip = Join-Path $root 'unsafe.zip'
        if (Test-Path -LiteralPath $unsafeZip) { Remove-Item -LiteralPath $unsafeZip }
        $zip = [IO.Compression.ZipFile]::Open($unsafeZip, [IO.Compression.ZipArchiveMode]::Create)
        try {
            foreach ($name in $unsafe) { $zip.CreateEntry($name) | Out-Null }
        } finally { $zip.Dispose() }
        $pin.build_prerequisites[0].bytes = (Get-Item -LiteralPath $unsafeZip).Length
        $pin.build_prerequisites[0].sha256 = (Get-FileHash -LiteralPath $unsafeZip).Hash
        $pin | ConvertTo-Json -Depth 5 | Set-Content -LiteralPath $manifest -Encoding UTF8
        $rejected = $false
        try { & $helper -Identity 'Git for Windows' -ArchivePath $unsafeZip -ManifestPath $manifest -DestinationRoot $dest | Out-Null }
        catch { $rejected = $_.Exception.Message -match 'Unsafe tool ZIP entry' }
        if (-not $rejected -or (Test-Path -LiteralPath $dest)) { throw "Unsafe ZIP path was not rejected before extraction: $($unsafe -join ', ')" }
    }

    if ($RealFfmpegArchive) {
        $ffmpegPin = [ordered]@{
            identity = 'Gyan FFmpeg'; version = '9.0.1'; architecture = 'x64'
            url = 'https://github.com/GyanD/codexffmpeg/releases/download/9.0.1/ffmpeg-9.0.1-essentials_build.zip'
            bytes = 111253802; sha256 = 'fec81ae03971d9dd4be3ebe02e263bd2ec1d789483f931bdba5f5715e65da2e9'
            delivery_classification = 'DIRECT_RECIPIENT_DOWNLOAD'
            executable_pins = @(
                @{ path = 'ffmpeg-9.0.1-essentials_build/bin/ffmpeg.exe'; sha256 = '72a489eccd008c2ec2c0a5856c5c75bc3d8bbfa90166c4566865c246445e6aa3' },
                @{ path = 'ffmpeg-9.0.1-essentials_build/bin/ffprobe.exe'; sha256 = '19202b23c0043f15ad1b7bce2344f406fd52bd6efd8f995ce02e7392a1cec52f' }
            )
        }
        [pscustomobject]@{ schema_version = 1; build_prerequisites = @($ffmpegPin) } |
            ConvertTo-Json -Depth 6 | Set-Content -LiteralPath $manifest -Encoding UTF8
        $ffmpegDest = Join-Path $root 'ffmpeg'
        $ffmpegPin.executable_pins[0].sha256 = '0' * 64
        [pscustomobject]@{ schema_version = 1; build_prerequisites = @($ffmpegPin) } |
            ConvertTo-Json -Depth 6 | Set-Content -LiteralPath $manifest -Encoding UTF8
        $rejected = $false
        try { & $helper -Identity 'Gyan FFmpeg' -ArchivePath $RealFfmpegArchive -ManifestPath $manifest -DestinationRoot $ffmpegDest | Out-Null }
        catch { $rejected = $_.Exception.Message -match 'executable pins differ' }
        if (-not $rejected -or (Test-Path -LiteralPath $ffmpegDest)) { throw 'Wrong FFmpeg extracted executable pin was accepted.' }
        $ffmpegPin.executable_pins[0].sha256 = '72a489eccd008c2ec2c0a5856c5c75bc3d8bbfa90166c4566865c246445e6aa3'
        $ffmpegPin.delivery_classification = 'BLOCKED'
        [pscustomobject]@{ schema_version = 1; build_prerequisites = @($ffmpegPin) } |
            ConvertTo-Json -Depth 6 | Set-Content -LiteralPath $manifest -Encoding UTF8
        $rejected = $false
        try { & $helper -Identity 'Gyan FFmpeg' -ArchivePath $RealFfmpegArchive -ManifestPath $manifest -DestinationRoot $ffmpegDest | Out-Null }
        catch { $rejected = $_.Exception.Message -match 'route is unavailable' }
        if (-not $rejected -or (Test-Path -LiteralPath $ffmpegDest)) { throw 'Blocked FFmpeg route was accepted.' }
        $ffmpegPin.delivery_classification = 'DIRECT_RECIPIENT_DOWNLOAD'
        [pscustomobject]@{ schema_version = 1; build_prerequisites = @($ffmpegPin) } |
            ConvertTo-Json -Depth 6 | Set-Content -LiteralPath $manifest -Encoding UTF8
        $ffmpeg = & $helper -Identity 'Gyan FFmpeg' -ArchivePath $RealFfmpegArchive -ManifestPath $manifest -DestinationRoot $ffmpegDest
        $ffprobe = Join-Path (Split-Path -Parent $ffmpeg) 'ffprobe.exe'
        $licenseRoot = Split-Path -Parent (Split-Path -Parent $ffmpeg)
        foreach ($file in @('LICENSE', 'README.txt', 'doc/ffmpeg.html', 'doc/ffprobe.html')) {
            if (-not (Test-Path -LiteralPath (Join-Path $licenseRoot $file) -PathType Leaf)) { throw "FFmpeg original notice/document missing: $file" }
        }
        if ((Get-FileHash -LiteralPath (Join-Path $licenseRoot 'LICENSE')).Hash -ne '8ceb4b9ee5adedde47b31e975c1d90c73ad27b6b165a1dcd80c7c545eb65b903' -or
            (Get-FileHash -LiteralPath (Join-Path $licenseRoot 'README.txt')).Hash -ne '1c8c50e4df1623673ec236bafe774f3c4ee41a1e6b0cde05e31b7d89b31efa06') { throw 'FFmpeg original notices were modified.' }
        $ass = @'
[Script Info]
ScriptType: v4.00+
PlayResX: 320
PlayResY: 180
[V4+ Styles]
Format: Name, Fontname, Fontsize, PrimaryColour, SecondaryColour, OutlineColour, BackColour, Bold, Italic, Underline, StrikeOut, ScaleX, ScaleY, Spacing, Angle, BorderStyle, Outline, Shadow, Alignment, MarginL, MarginR, MarginV, Encoding
Style: Default,Arial,30,&H00FFFFFF,&H00FFFFFF,&H00000000,&H00000000,0,0,0,0,100,100,0,0,1,1,0,2,10,10,10,1
[Events]
Format: Layer, Start, End, Style, Name, MarginL, MarginR, MarginV, Effect, Text
Dialogue: 0,0:00:00.00,0:00:01.00,Default,,0,0,0,,AutoClip probe
'@
        Set-Content -LiteralPath (Join-Path $root 'probe.ass') -Value $ass -Encoding ASCII
        Push-Location $root
        try {
            & $ffmpeg -y -hide_banner -loglevel error -f lavfi -i 'color=c=black:s=320x180:r=10:d=1' -f lavfi -i 'sine=frequency=440:duration=1' -vf 'ass=probe.ass' -c:v libx264 -pix_fmt yuv420p -c:a aac -shortest probe.mp4
            if ($LASTEXITCODE -ne 0) { throw 'FFmpeg actual ASS/x264/AAC render failed.' }
            $probe = & $ffprobe -v error -show_streams -of json probe.mp4 | Out-String | ConvertFrom-Json
            if ($LASTEXITCODE -ne 0 -or @($probe.streams | Where-Object codec_name -eq 'h264').Count -ne 1 -or
                @($probe.streams | Where-Object codec_name -eq 'aac').Count -ne 1) { throw 'FFprobe did not verify rendered video/audio.' }
            & $ffmpeg -y -hide_banner -loglevel error -i probe.mp4 -frames:v 1 -f rawvideo -pix_fmt rgb24 frame.rgb
            if ($LASTEXITCODE -ne 0) { throw 'FFmpeg output decode failed.' }
            $frame = [IO.File]::ReadAllBytes((Join-Path $root 'frame.rgb'))
            if ($frame.Length -ne 172800 -or -not @($frame | Where-Object { $_ -ne 0 }).Count) { throw 'ASS text did not render on the black source.' }
        } finally { Pop-Location }
        'Installer FFmpeg: exact essentials hashes, preserved notices/docs, ASS/x264/AAC render, FFprobe and decoded text PASS'
    }
    if ($RealMinGitArchive) {
        $actualManifest = Get-Content -LiteralPath (Join-Path $repo 'release/manifests/installer-dependencies-v1.json') -Raw | ConvertFrom-Json
        $gitPin = @($actualManifest.build_prerequisites | Where-Object identity -eq 'Git for Windows')[0]
        $gitPin.delivery_classification = 'DIRECT_RECIPIENT_DOWNLOAD'
        [pscustomobject]@{ schema_version = 1; build_prerequisites = @($gitPin) } |
            ConvertTo-Json -Depth 5 | Set-Content -LiteralPath $manifest -Encoding UTF8
        & $helper -Identity 'Git for Windows' -ArchivePath $RealMinGitArchive -ManifestPath $manifest -DestinationRoot $dest
        $git = Join-Path $dest 'cmd/git.exe'
        if (-not (Test-Path -LiteralPath $git -PathType Leaf)) { throw 'MinGit executable missing.' }
        if ((& $git --version) -ne 'git version 2.55.0.windows.3') { throw 'MinGit version mismatch.' }
    }
    if ($RealUvArchive) {
        $actualManifest = Get-Content -LiteralPath (Join-Path $repo 'release/manifests/installer-dependencies-v1.json') -Raw | ConvertFrom-Json
        $uvPin = @($actualManifest.build_prerequisites | Where-Object identity -eq 'uv')[0]
        $uvPin.delivery_classification = 'DIRECT_RECIPIENT_DOWNLOAD'
        [pscustomobject]@{ schema_version = 1; build_prerequisites = @($uvPin) } |
            ConvertTo-Json -Depth 5 | Set-Content -LiteralPath $manifest -Encoding UTF8
        $uvDest = Join-Path $root 'uv'
        & $helper -Identity uv -ArchivePath $RealUvArchive -ManifestPath $manifest -DestinationRoot $uvDest
        if ((& (Join-Path $uvDest 'uv.exe') --version) -notmatch '^uv 0\.12\.19\b') {
            throw 'Pinned uv executable version mismatch.'
        }
    }
    if ($RealMinGitArchive -and $RealUvArchive) {
        & (Join-Path $repo 'install.ps1') -PrerequisitesOnly -NoPrerequisiteAcquisition -GitExePath (Join-Path $dest 'cmd/git.exe') -UvExePath (Join-Path $uvDest 'uv.exe') | Out-Null
        $rejected = $false
        try {
            & (Join-Path $repo 'install.ps1') -PrerequisitesOnly -NoPrerequisiteAcquisition -GitExePath (Join-Path $dest 'cmd/git.exe') -UvExePath (Join-Path $env:WINDIR 'System32/cmd.exe') | Out-Null
        } catch { $rejected = $_.Exception.Message -match 'uv executable signature' }
        if (-not $rejected) { throw 'Selected uv executable with wrong signer must be rejected.' }
        'Installer tool archives: traversal, hash rejection, exact MinGit and uv extraction PASS (recipient downloads untested)'
    } else {
        'Installer tool archives: traversal and hash rejection PASS'
    }
} finally {
    $resolved = [IO.Path]::GetFullPath($root)
    $safeParent = [IO.Path]::GetFullPath($env:TEMP).TrimEnd('\') + '\'
    if (-not $resolved.StartsWith($safeParent, [StringComparison]::OrdinalIgnoreCase)) { throw 'Unsafe fixture cleanup path.' }
    Remove-Item -LiteralPath $resolved -Recurse -Force
}
