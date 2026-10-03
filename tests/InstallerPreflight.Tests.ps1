param([string]$SetupExe)

$ErrorActionPreference = 'Stop'
$repo = Split-Path -Parent $PSScriptRoot
$preflight = Join-Path $repo 'installer/preflight.ps1'
$root = Join-Path $env:TEMP ('autoclip-preflight-' + [guid]::NewGuid().ToString('N'))
New-Item -ItemType Directory -Path $root | Out-Null
$originalBashEnv = $env:BASH_ENV
try {
    $script:msysFixtureRoot = Join-Path $root 'msys-fixture'
    New-Item -ItemType Directory -Path (Join-Path $script:msysFixtureRoot 'usr/bin') -Force | Out-Null
    [IO.File]::WriteAllText((Join-Path $script:msysFixtureRoot 'usr/bin/bash.exe'), 'inert bash fixture')
    [IO.File]::WriteAllText((Join-Path $script:msysFixtureRoot 'usr/bin/pacman.exe'), 'inert pacman fixture')
    $tokens = $null; $errors = $null
    $ast = [Management.Automation.Language.Parser]::ParseFile($preflight, [ref]$tokens, [ref]$errors)
    if ($errors) { throw 'Preflight parse failed.' }
    $probeFunction = $ast.FindAll({ param($node) $node -is [Management.Automation.Language.FunctionDefinitionAst] -and $node.Name -eq 'Test-BuildCapability' }, $false)[0]
    $probeSource = $probeFunction.Extent.Text.Replace('$PSScriptRoot', ("'" + (Join-Path $repo 'installer').Replace("'", "''") + "'"))
    $probeSource = $probeSource.Replace('& $powershell -NoProfile -NonInteractive -ExecutionPolicy Bypass -File $pythonHelper -CheckOnly', 'Invoke-PreflightPythonCheck $powershell $pythonHelper')
    $probeSource = $probeSource.Replace("'C:\msys64\usr\bin\bash.exe'", ("'" + (Join-Path $script:msysFixtureRoot 'usr/bin/bash.exe') + "'"))
    $probeSource = $probeSource.Replace("'C:\msys64'", ("'" + $script:msysFixtureRoot + "'"))
    $probeSource = $probeSource.Replace('& $bash ', 'Invoke-PreflightMsysProbe $bash ')
    Invoke-Expression $probeSource
    $script:registeredPython = Join-Path $root 'registered/python.exe'
    $script:pythonCheckCode = 0; $script:pythonCheckCalls = 0; $script:alias = $null
    function Find-Tool { param($Name) if ($Name -eq 'python.exe') { return $script:alias }; return $null }
    function Invoke-PreflightPythonCheck {
        param($NativePowerShell, $PythonHelper)
        if ($NativePowerShell -ne (Join-Path $env:WINDIR 'System32/WindowsPowerShell/v1.0/powershell.exe') -or
            $PythonHelper -ne (Join-Path $repo 'installer/install-python.ps1')) { throw 'Python probe did not use the absolute native PowerShell/sibling helper.' }
        $script:pythonCheckCalls++
        $global:LASTEXITCODE = $script:pythonCheckCode
        if ($script:pythonCheckCode -eq 0) { $script:registeredPython }
    }
    if (-not (Test-BuildCapability 'Python' '3.11.9') -or $script:pythonCheckCalls -ne 1) {
        throw 'Registered valid Python outside PATH must satisfy preflight through CheckOnly.'
    }
    $script:alias = Join-Path $root 'WindowsApps/python.exe'; $script:pythonCheckCode = 2
    $beforeProbe = @(Get-ChildItem -LiteralPath $root -Recurse -Force).Count
    if (Test-BuildCapability 'Python' '3.11.9') { throw 'WindowsApps alias must not satisfy preflight.' }
    if ($script:pythonCheckCalls -ne 2 -or @(Get-ChildItem -LiteralPath $root -Recurse -Force).Count -ne $beforeProbe) {
        throw 'Python preflight executed a PATH alias or mutated files instead of checking registered capability.'
    }
    'Python preflight: registered interpreter outside PATH, absolute read-only native helper, missing/alias rejection PASS'
    $script:msysCalls = @(); $script:msysExit = 0
    $selectedPackages = @('make', 'diffutils', 'pkgconf', 'mingw-w64-ucrt-x86_64-nasm', 'mingw-w64-ucrt-x86_64-zlib') | ForEach-Object {
        [pscustomobject]@{identity = $_; version = '1-1'; architecture = 'any'; filename = ($_ + '-1-1-any.pkg.tar.zst')}
    }
    $nativeProvenance = @('usr/bin/bash.exe', 'usr/bin/pacman.exe') | ForEach-Object {
        $path = Join-Path $script:msysFixtureRoot $_
        [pscustomobject]@{path = $_; bytes = (Get-Item $path).Length; sha256 = (Get-FileHash $path).Hash}
    }
    $msysEntry = [pscustomobject]@{identity = 'MSYS2'; packages = $selectedPackages; installed_files = $nativeProvenance}
    $script:msysOutput = @($selectedPackages | ForEach-Object { $_.identity + ' ' + $_.version })
    function Invoke-PreflightMsysProbe {
        $script:msysCalls += ,@($args)
        if ($env:BASH_ENV) { throw 'MSYS2 preflight inherited BASH_ENV startup script.' }
        $global:LASTEXITCODE = $script:msysExit
        $script:msysOutput
    }
    $fixtureBashEnv = Join-Path $root 'side-effect-profile.sh'
    $env:BASH_ENV = $fixtureBashEnv
    if (-not (Test-BuildCapability 'MSYS2' '20260611' $msysEntry)) { throw 'Exact MSYS2 version fixture was not detected.' }
    if ($env:BASH_ENV -ne $fixtureBashEnv) { throw 'MSYS2 preflight failed to restore the caller BASH_ENV.' }
    $expectedQuery = '/usr/bin/pacman -Q -- ' + (($selectedPackages | ForEach-Object identity) -join ' ')
    if ($script:msysCalls.Count -ne 1 -or
        ($script:msysCalls[0] -join '|') -ne ((Join-Path $script:msysFixtureRoot 'usr/bin/bash.exe') + '|--noprofile|--norc|-c|' + $expectedQuery)) {
        throw ('MSYS2 probe loaded profiles or used wrong query arguments: ' + (($script:msysCalls | ForEach-Object { $_ -join '|' }) -join '; '))
    }
    $originalMsysOutput = $script:msysOutput
    $script:msysCalls = @()
    $selectedRoot = Join-Path $root 'selected-msys-root'
    [IO.Directory]::CreateDirectory((Join-Path $selectedRoot 'usr/bin')) | Out-Null
    foreach ($name in @('bash.exe', 'pacman.exe')) {
        [IO.File]::Copy((Join-Path $script:msysFixtureRoot ('usr/bin/' + $name)), (Join-Path $selectedRoot ('usr/bin/' + $name)))
    }
    if (-not (Test-BuildCapability 'MSYS2' '20260611' $msysEntry -MsysRoot $selectedRoot) -or
        $script:msysCalls.Count -ne 1 -or $script:msysCalls[0][0] -ne (Join-Path $selectedRoot 'usr/bin/bash.exe')) {
        throw 'Preflight ignored the explicitly selected private MSYS2 root.'
    }
    $badMsysOutputs = @(
        @{lines = @($originalMsysOutput[0..3])}
        @{lines = @($originalMsysOutput + 'unknown 1-1')}
        @{lines = @($originalMsysOutput[0..3] + $originalMsysOutput[0])}
        @{lines = @('make 2-1') + @($originalMsysOutput[1..4])}
        @{lines = @('MAKE 1-1') + @($originalMsysOutput[1..4])}
    )
    foreach ($badOutput in $badMsysOutputs) {
        $script:msysOutput = $badOutput.lines
        if (Test-BuildCapability 'MSYS2' '20260611' $msysEntry) { throw 'MSYS2 wrong version, missing, duplicate or extra package was accepted.' }
    }
    $script:msysOutput = $originalMsysOutput
    $script:msysExit = 2
    if (Test-BuildCapability 'MSYS2' '20260611' $msysEntry) { throw 'Native package query failure was accepted.' }
    $script:msysExit = 0
    $script:msysCalls = @()
    if (Test-BuildCapability 'MSYS2' '20260611') { throw 'Legacy MSYS2 metadata absence must remain missing, not presence-only ready.' }
    $msysEntry.packages = @($selectedPackages + $selectedPackages[0])
    if (Test-BuildCapability 'MSYS2' '20260611' $msysEntry) { throw 'Duplicate manifest package was accepted.' }
    $msysEntry.packages = $selectedPackages
    $selectedPackages[0].identity = 'make; touch side-effect'
    if (Test-BuildCapability 'MSYS2' '20260611' $msysEntry) { throw 'Shell syntax in package identity was accepted.' }
    $selectedPackages[0].identity = 'make'
    $msysEntry.installed_files = @($nativeProvenance[0])
    if (Test-BuildCapability 'MSYS2' '20260611' $msysEntry) { throw 'Missing pacman provenance was accepted.' }
    $msysEntry.installed_files = @($nativeProvenance + $nativeProvenance[0])
    if (Test-BuildCapability 'MSYS2' '20260611' $msysEntry) { throw 'Duplicate provenance was accepted.' }
    $msysEntry.installed_files = $nativeProvenance
    $nativeProvenance[0].sha256 = '0' * 64
    if (Test-BuildCapability 'MSYS2' '20260611' $msysEntry) { throw 'Wrong MSYS2 native provenance was accepted.' }
    $nativeProvenance[0].sha256 = (Get-FileHash (Join-Path $script:msysFixtureRoot 'usr/bin/bash.exe')).Hash
    $nativeProvenance[0].path = '../escaped.exe'
    if (Test-BuildCapability 'MSYS2' '20260611' $msysEntry) { throw 'Escaping provenance path was accepted.' }
    $nativeProvenance[0].path = 'usr/bin/bash.exe'
    if ($script:msysCalls.Count) { throw 'Invalid/absent manifest metadata or provenance reached native MSYS2 boundary.' }
    'MSYS2 preflight: non-login native arguments, exact package map/count, read-only provenance and legacy metadata rejection PASS'
    $manifest = Join-Path $root 'fixture.json'
    @'
{"schema_version":1,"build_prerequisites":[{"identity":"fixture absent capability","version":"1.2","publisher":"Fixture Publisher","purpose":"Needed for CPU inference","profile":"both","url":"https://example.org/fixture.exe","bytes":12345,"elevation":"required","reboot_behavior":"may require restart","delivery_classification":"BLOCKED"},{"identity":"NVIDIA CUDA Toolkit build components","profile":"nvidia","delivery_classification":"DIRECT_RECIPIENT_DOWNLOAD"}],"external_assets":[{"identity":"NVIDIA cuBLAS 12.4.5.8 Windows x64 wheel","profile":"nvidia","delivery_classification":"BLOCKED"}]}
'@ | Set-Content -LiteralPath $manifest -Encoding Ascii
    $report = Join-Path $root 'report.txt'
    $cpu = & $preflight -ManifestPath $manifest -Profile cpu -ReportPath $report | ConvertFrom-Json
    if ($cpu.ready -or -not $cpu.blocked) { throw 'Absent blocked CPU build tools must stop installation.' }
    if (@($cpu.missing | Where-Object { $_.identity -eq 'fixture absent capability' -and $_.delivery_classification -eq 'BLOCKED' }).Count -ne 1) {
        throw 'Manifest blocked capability must be reported from the live probe.'
    }
    if (@($cpu.missing | Where-Object { $_.identity -eq 'NVIDIA CUDA Toolkit build components' }).Count) {
        throw 'CPU profile must not require CUDA.'
    }
    $summary = Get-Content -LiteralPath $report -Raw
    foreach ($detail in @('Fixture Publisher', 'Needed for CPU inference', '12345 bytes', 'required', 'may require restart', 'https://example.org/fixture.exe')) {
        if (-not $summary.Contains($detail)) { throw "Prerequisite summary omitted $detail" }
    }
    $before = @(Get-ChildItem -LiteralPath $root -Recurse -Force).Count
    $gpu = & $preflight -ManifestPath $manifest -Profile nvidia | ConvertFrom-Json
    if (@($gpu.missing | Where-Object { $_.identity -eq 'NVIDIA cuBLAS 12.4.5.8 Windows x64 wheel' }).Count -ne 1) {
        throw 'NVIDIA profile must report blocked cuBLAS.'
    }
    '{"schema_version":1,"build_prerequisites":[],"external_assets":[]}' | Set-Content -LiteralPath $manifest -Encoding Ascii
    $ready = & $preflight -ManifestPath $manifest -Profile cpu | ConvertFrom-Json
    if (-not $ready.ready -or $ready.blocked -or @($ready.missing).Count) {
        throw 'A manifest with no missing capabilities must be ready.'
    }
    if (@(Get-ChildItem -LiteralPath $root -Recurse -Force).Count -ne $before) {
        throw 'Preflight modified its probe root.'
    }
    '{"schema_version":1,"build_prerequisites":[{"identity":"fixture absent capability","profile":"both","delivery_classification":"DIRECT_RECIPIENT_DOWNLOAD"}],"external_assets":[]}' |
        Set-Content -LiteralPath $manifest -Encoding Ascii
    $direct = & $preflight -ManifestPath $manifest -Profile cpu | ConvertFrom-Json
    if ($direct.ready -or $direct.blocked) { throw 'Missing direct-download tool must be eligible but not ready.' }
    & powershell.exe -NoProfile -ExecutionPolicy Bypass -File $preflight -ManifestPath $manifest -Profile cpu -RequireNoBlocked | Out-Null
    if ($LASTEXITCODE -ne 0) { throw 'Allowed direct-download tool incorrectly blocked wizard.' }
    '{"schema_version":1,"build_prerequisites":[{"identity":"fixture absent system capability","profile":"nvidia","delivery_classification":"SYSTEM_PROVIDED"}],"external_assets":[]}' |
        Set-Content -LiteralPath $manifest -Encoding Ascii
    $gpuSystem = & $preflight -ManifestPath $manifest -Profile nvidia | ConvertFrom-Json
    $cpuSystem = & $preflight -ManifestPath $manifest -Profile cpu | ConvertFrom-Json
    if (-not $gpuSystem.blocked -or $cpuSystem.blocked) { throw 'Missing GPU system capability must block only NVIDIA.' }
    $toolDir = Join-Path $root 'tools'
    New-Item -ItemType Directory -Path $toolDir | Out-Null
    Add-Type -TypeDefinition 'public class UvFixture { public static void Main() { System.Console.WriteLine("uv 0.12.19"); } }' -OutputAssembly (Join-Path $toolDir 'uv.exe') -OutputType ConsoleApplication
    '{"schema_version":1,"build_prerequisites":[{"identity":"uv","version":"0.12.19","profile":"both","delivery_classification":"DIRECT_RECIPIENT_DOWNLOAD"}],"external_assets":[]}' |
        Set-Content -LiteralPath $manifest -Encoding Ascii
    $oldPath = $env:PATH
    try {
        $env:PATH = $toolDir + ';' + $oldPath
        $spoof = & $preflight -ManifestPath $manifest -Profile cpu | ConvertFrom-Json
        if ($spoof.ready -or @($spoof.missing | Where-Object identity -eq 'uv').Count -ne 1) {
            throw 'Unsigned executable that prints the expected uv version must not satisfy preflight.'
        }
    } finally { $env:PATH = $oldPath }
    if ($SetupExe) {
        if (-not (Test-Path -LiteralPath $SetupExe -PathType Leaf)) { throw 'Setup executable is missing.' }
        $log = Join-Path $root 'audit.log'
        $process = Start-Process -FilePath $SetupExe -ArgumentList @('/AUDIT', ('/LOG="' + $log + '"')) -WindowStyle Hidden -Wait -PassThru
        if ($process.ExitCode -ne 1) { throw "Audit must stop setup before installation; exit=$($process.ExitCode)." }
        $audit = @(Select-String -LiteralPath $log -Pattern 'AUDIT ([^ ]+) SHA256=([0-9a-f]{64})' | ForEach-Object {
            [pscustomobject]@{ name = $_.Matches[0].Groups[1].Value; sha256 = $_.Matches[0].Groups[2].Value }
        })
        $expected = @{
            'install.ps1' = Join-Path $repo 'install.ps1'
            'preflight.ps1' = $preflight
            'install-tool-archive.ps1' = Join-Path $repo 'installer/install-tool-archive.ps1'
            'download-artifact.ps1' = Join-Path $repo 'installer/download-artifact.ps1'
            'install-python.ps1' = Join-Path $repo 'installer/install-python.ps1'
            'install-msys2-base.ps1' = Join-Path $repo 'installer/install-msys2-base.ps1'
            'extract-msys2-base.py' = Join-Path $repo 'installer/extract-msys2-base.py'
            'install-msys2-packages.ps1' = Join-Path $repo 'installer/install-msys2-packages.ps1'
            'install-runtime-toolpath.ps1' = Join-Path $repo 'installer/install-runtime-toolpath.ps1'
            'run-source-build.ps1' = Join-Path $repo 'installer/run-source-build.ps1'
            'verify-installed-app.ps1' = Join-Path $repo 'installer/verify-installed-app.ps1'
            'installer-dependencies-v1.json' = Join-Path $repo 'release/manifests/installer-dependencies-v1.json'
            'inno-setup-7.1.0-LICENSE.txt' = Join-Path $repo 'release/notices/inno-setup-7.1.0-LICENSE.txt'
            'uv-0.12.19-LICENSE-MIT.txt' = Join-Path $repo 'release/notices/uv-0.12.19-LICENSE-MIT.txt'
            'uv-0.12.19-LICENSE-APACHE.txt' = Join-Path $repo 'release/notices/uv-0.12.19-LICENSE-APACHE.txt'
            'setup-tool-sources.md' = Join-Path $repo 'release/notices/setup-tool-sources.md'
        }
        if ($audit.Count -ne $expected.Count) { throw 'Audit did not report exactly the known embedded files.' }
        foreach ($item in $audit) {
            if (-not $expected.ContainsKey($item.name) -or
                $item.sha256 -ne (Get-FileHash -LiteralPath $expected[$item.name] -Algorithm SHA256).Hash.ToLowerInvariant()) {
                throw "Embedded file differs: $($item.name)"
            }
        }
        'Installer audit: exact EXE extracted-file hashes match source PASS'
    }
    'Installer preflight: blocked CPU tools, GPU separation, read-only probe PASS'
} finally {
    $env:BASH_ENV = $originalBashEnv
    $resolved = [IO.Path]::GetFullPath($root)
    $safeParent = [IO.Path]::GetFullPath($env:TEMP).TrimEnd('\') + '\'
    if (-not $resolved.StartsWith($safeParent, [StringComparison]::OrdinalIgnoreCase)) { throw 'Unsafe fixture cleanup path.' }
    Remove-Item -LiteralPath $resolved -Recurse -Force
}
