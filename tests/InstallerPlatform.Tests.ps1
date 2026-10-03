$ErrorActionPreference = 'Stop'
$preflight = Join-Path (Split-Path -Parent $PSScriptRoot) 'installer/preflight.ps1'
$root = Join-Path $env:TEMP ('autoclip-platform-test-' + [guid]::NewGuid().ToString('N'))
New-Item -ItemType Directory -Path $root | Out-Null
try {
    $manifest = Join-Path $root 'manifest.json'
    '{"schema_version":1,"build_prerequisites":[],"external_assets":[]}' | Set-Content $manifest -Encoding UTF8
    $harness = Join-Path $root 'native-boundary.ps1'
    @'
param($PreflightPath, $ManifestPath, $PlatformPath, $ReportPath)
$ErrorActionPreference = 'Stop'
$global:LASTEXITCODE = 0
$global:platformFixture = Get-Content $PlatformPath -Raw | ConvertFrom-Json
function Get-CimInstance {
    [CmdletBinding()]
    param([string]$ClassName)
    if ($global:platformFixture.fail) { throw 'Fixture native platform unavailable.' }
    switch ($ClassName) {
        'Win32_OperatingSystem' { $global:platformFixture.os }
        'Win32_Processor' { $global:platformFixture.cpu }
        default { throw 'Unexpected native platform query.' }
    }
}
& $PreflightPath -ManifestPath $ManifestPath -ReportPath $ReportPath
exit $LASTEXITCODE
'@ | Set-Content $harness -Encoding UTF8
    $desktop = [pscustomobject]@{ProductType = 1; BuildNumber = '22000'}
    $x64 = [pscustomobject]@{Architecture = 9}
    $cases = @(
        @{name = 'ARM64'; os = @($desktop); cpu = @([pscustomobject]@{Architecture = 12}); supported = $false}
        @{name = 'Server'; os = @([pscustomobject]@{ProductType = 3; BuildNumber = '26100'}); cpu = @($x64); supported = $false}
        @{name = 'DomainController'; os = @([pscustomobject]@{ProductType = 2; BuildNumber = '26100'}); cpu = @($x64); supported = $false}
        @{name = 'X86'; os = @($desktop); cpu = @([pscustomobject]@{Architecture = 0}); supported = $false}
        @{name = 'PreWindows10'; os = @([pscustomobject]@{ProductType = 1; BuildNumber = '9600'}); cpu = @($x64); supported = $false}
        @{name = 'Windows10'; os = @([pscustomobject]@{ProductType = 1; BuildNumber = '19045'}); cpu = @($x64); supported = $true}
        @{name = 'Windows11'; os = @($desktop); cpu = @($x64); supported = $true}
        @{name = 'AbsentProcessor'; os = @($desktop); cpu = @(); supported = $false}
        @{name = 'AbsentOS'; os = @(); cpu = @($x64); supported = $false}
        @{name = 'MixedProcessor'; os = @($desktop); cpu = @($x64, [pscustomobject]@{Architecture = 12}); supported = $false}
        @{name = 'AmbiguousOS'; os = @($desktop, $desktop); cpu = @($x64); supported = $false}
        @{name = 'MalformedBuild'; os = @([pscustomobject]@{ProductType = 1; BuildNumber = '22000junk'}); cpu = @($x64); supported = $false}
        @{name = 'OverflowBuild'; os = @([pscustomobject]@{ProductType = 1; BuildNumber = '99999999999999999999'}); cpu = @($x64); supported = $false}
        @{name = 'MalformedCPU'; os = @($desktop); cpu = @([pscustomobject]@{Architecture = '9junk'}); supported = $false}
        @{name = 'MissingProductType'; os = @([pscustomobject]@{BuildNumber = '22000'}); cpu = @($x64); supported = $false}
        @{name = 'NativeFailure'; os = @($desktop); cpu = @($x64); fail = $true; supported = $false}
    )
    $failures = @()
    foreach ($case in $cases) {
        $platformPath = Join-Path $root ($case.name + '.json')
        $case | ConvertTo-Json -Depth 5 | Set-Content $platformPath -Encoding UTF8
        $report = Join-Path $root ($case.name + '.txt')
        $output = & powershell -NoProfile -ExecutionPolicy Bypass -File $harness -PreflightPath $preflight -ManifestPath $manifest -PlatformPath $platformPath -ReportPath $report
        $exitCode = $LASTEXITCODE
        $result = $output | ConvertFrom-Json
        if ($case.supported) {
            if ($exitCode -ne 0 -or -not $result.ready -or $result.blocked) { $failures += "$($case.name): native x64 desktop rejected." }
        } elseif ($exitCode -ne 2 -or $result.ready -or -not $result.blocked -or
            (Get-Content $report -Raw) -notmatch 'native Windows 10 or 11 x64 desktop') {
            $failures += "$($case.name): unsupported native platform accepted or not reported (exit=$exitCode ready=$($result.ready) blocked=$($result.blocked))."
        }
    }
    if ($failures.Count) { throw ($failures -join "`n") }
    'Installer platform native-boundary tests PASS: Windows10/11 x64, ARM64/server/older rejection, absent/mixed/malformed/failure rejection.'
} finally {
    $resolved = [IO.Path]::GetFullPath($root)
    if (-not $resolved.StartsWith([IO.Path]::GetFullPath($env:TEMP).TrimEnd('\') + '\', [StringComparison]::OrdinalIgnoreCase)) { throw 'Unsafe platform fixture cleanup.' }
    Remove-Item -LiteralPath $resolved -Recurse -Force
}
