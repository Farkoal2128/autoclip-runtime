param([string]$ExistingPythonPath, [string]$HelperPath)
$ErrorActionPreference = 'Stop'
$repo = Split-Path -Parent $PSScriptRoot
$helper = if ($HelperPath) { $HelperPath } else { Join-Path $repo 'installer/install-python.ps1' }
if (-not (Test-Path $helper)) { throw 'RED: Python prerequisite helper is missing.' }
$tokens = $null; $errors = $null
$ast = [Management.Automation.Language.Parser]::ParseFile($helper, [ref]$tokens, [ref]$errors)
if ($errors) { throw 'Python helper parse failed.' }
$sets = (Get-Command $helper).ParameterSets
$installParameters = @(($sets | Where-Object Name -eq 'Install').Parameters | Where-Object IsMandatory | Select-Object -ExpandProperty Name)
$checkParameters = @(($sets | Where-Object Name -eq 'Check').Parameters | Where-Object IsMandatory | Select-Object -ExpandProperty Name)
if ((Compare-Object $installParameters @('InstallerPath', 'ManifestPath', 'LogDirectory')) -or
    (Compare-Object $checkParameters @('CheckOnly')) -or
    (($sets | Where-Object Name -eq 'Check').Parameters.Name -contains 'AcceptPythonTerms')) {
    throw 'Install mandatory parameters and separate CheckOnly parameter set must be preserved.'
}
foreach ($node in $ast.FindAll({ param($n) $n -is [Management.Automation.Language.FunctionDefinitionAst] }, $false)) {
    Invoke-Expression $node.Extent.Text
}
if ($ExistingPythonPath) {
    if (-not (Test-AutoClipPython $ExistingPythonPath)) { throw 'Existing Python native capability check failed.' }
    if (Test-AutoClipPython ($ExistingPythonPath + '.missing')) { throw 'Missing interpreter passed native capability check.' }
    'Native existing Python identity/stdlib/headers/libraries PASS'
}
$root = Join-Path $env:TEMP ('autoclip-python-install-' + [guid]::NewGuid().ToString('N'))
[IO.Directory]::CreateDirectory($root) | Out-Null
try {
    $registeredRoot = Join-Path $root 'registered'
    $aliasRoot = Join-Path $root 'WindowsApps'
    [IO.Directory]::CreateDirectory($registeredRoot) | Out-Null
    [IO.Directory]::CreateDirectory($aliasRoot) | Out-Null
    [IO.File]::WriteAllText((Join-Path $registeredRoot 'python.exe'), 'registered fixture')
    [IO.File]::WriteAllText((Join-Path $aliasRoot 'python.exe'), 'unsigned alias fixture')
    $source = Get-Content -LiteralPath $helper -Raw
    $nativeProbe = '& $PythonPath -I'
    if (-not $source.Contains($nativeProbe)) { throw 'Expected Python native probe boundary is missing.' }
    $functionEnd = ($ast.FindAll({ param($n) $n -is [Management.Automation.Language.FunctionDefinitionAst] }, $false) |
        ForEach-Object { $_.Extent.EndOffset } | Measure-Object -Maximum).Maximum
    # Inject mocks only into temporary test copies; the production helper has no mock switches.
    $boundaries = @'
function Get-AutoClipPythonTarget { Join-Path $script:fixtureRoot 'absent' }
function Test-Path {
    param($LiteralPath, $PathType)
    if ($LiteralPath -like 'HK*') { return ($script:fixtureRegistered -and $LiteralPath -eq 'HKCU:\SOFTWARE\Python\PythonCore\3.11\InstallPath') }
    if ($PathType) { return Microsoft.PowerShell.Management\Test-Path -LiteralPath $LiteralPath -PathType $PathType }
    Microsoft.PowerShell.Management\Test-Path -LiteralPath $LiteralPath
}
function Get-Item {
    param($LiteralPath, [switch]$Force)
    if ($LiteralPath -like 'HK*') {
        return (New-Object PSObject | Add-Member -MemberType ScriptMethod -Name GetValue -Value { $script:fixtureRegisteredRoot } -PassThru)
    }
    Microsoft.PowerShell.Management\Get-Item -LiteralPath $LiteralPath -Force:$Force
}
function Get-AuthenticodeSignature {
    param($LiteralPath)
    $status = if ($LiteralPath -like '*\WindowsApps\*') { 'NotSigned' } else { 'Valid' }
    [pscustomobject]@{ Status = $status; SignerCertificate = [pscustomobject]@{ Subject = 'CN=Python Software Foundation, O=Python Software Foundation' } }
}
function Invoke-PythonFixture {
    param($PythonPath, [switch]$I, [switch]$B, $c)
    if ($PythonPath -like '*\WindowsApps\*') { [IO.File]::WriteAllText((Join-Path $script:fixtureRoot 'alias-executed'), 'failure') }
    if (-not $I -or -not $B -or -not $c) { throw 'Python capability check must isolate imports and disable bytecode writes.' }
    $global:LASTEXITCODE = 0
    'AUTOCLIP_PYTHON_3.11.9_X64_OK'
}
if (Test-AutoClipPython (Join-Path $script:fixtureRoot 'WindowsApps\python.exe')) { throw 'Unsigned WindowsApps alias was accepted.' }
'@
    $checkFixture = Join-Path $root 'check-python.ps1'
    foreach ($case in @(@('registered', $true, $registeredRoot, 0), @('missing', $false, $registeredRoot, 2), @('unsigned alias', $true, $aliasRoot, 2))) {
        $variables = "`r`n`$script:fixtureRoot = '" + $root.Replace("'", "''") + "'`r`n`$script:fixtureRegisteredRoot = '" + $case[2].Replace("'", "''") + "'`r`n`$script:fixtureRegistered = `$" + $case[1].ToString() + "`r`n"
        # Original AST offsets apply before replacing the native command boundary.
        $candidate = ($source.Substring(0, $functionEnd) + $variables + $boundaries + "`r`n" + $source.Substring($functionEnd)).Replace($nativeProbe, 'Invoke-PythonFixture $PythonPath -I')
        [IO.File]::WriteAllText($checkFixture, $candidate)
        $beforeFiles = @(Get-ChildItem -LiteralPath $root -Recurse -File | ForEach-Object { $_.FullName + ':' + (Get-FileHash -LiteralPath $_.FullName).Hash })
        $nativeErrors = $ErrorActionPreference
        try {
            $ErrorActionPreference = 'Continue'
            $found = & (Join-Path $env:WINDIR 'System32/WindowsPowerShell/v1.0/powershell.exe') -NoProfile -NonInteractive -ExecutionPolicy Bypass -File $checkFixture -CheckOnly 2>&1 | Out-String
        } finally { $ErrorActionPreference = $nativeErrors }
        if ($LASTEXITCODE -ne $case[3]) { throw "CheckOnly $($case[0]) expected exit $($case[3]), got ${LASTEXITCODE}: $found" }
        if ($case[3] -eq 0 -and $found.Trim() -ne (Join-Path $registeredRoot 'python.exe')) { throw 'CheckOnly did not select the registered interpreter outside PATH.' }
        if ($case[3] -eq 2 -and $found.Trim()) { throw 'Missing CheckOnly result returned unexpected output.' }
        $afterFiles = @(Get-ChildItem -LiteralPath $root -Recurse -File | ForEach-Object { $_.FullName + ':' + (Get-FileHash -LiteralPath $_.FullName).Hash })
        if (Compare-Object $beforeFiles $afterFiles) { throw 'CheckOnly changed files or executed the unsigned WindowsApps alias.' }
    }
    'Python CheckOnly: registry discovery outside PATH, signature before execution, missing/unsigned exit 2, no file changes PASS'
    $artifact = Join-Path $root 'python.exe'
    [IO.File]::WriteAllText($artifact, 'fixture')
    $manifestPath = Join-Path $root 'manifest.json'
    $pin = [ordered]@{ schema_version = 1; build_prerequisites = @([ordered]@{
        identity = 'Python'; version = '3.11.9'; architecture = 'x64'
        url = 'https://www.python.org/ftp/python/3.11.9/python-3.11.9-amd64.exe'
        delivery_classification = 'DIRECT_RECIPIENT_DOWNLOAD'
        bytes = (Get-Item $artifact).Length; sha256 = (Get-FileHash $artifact).Hash
    }) }
    function Save-Pin { $pin | ConvertTo-Json -Depth 6 | Set-Content $manifestPath -Encoding UTF8 }
    Save-Pin
    $script:signer = 'CN=Python Software Foundation, O=Python Software Foundation'
    $script:signatureStatus = 'Valid'
    $script:vendorCode = 0; $script:capable = $true; $script:calls = 0; $script:probes = 0
    function Get-AuthenticodeSignature { [pscustomobject]@{ Status = $script:signatureStatus; SignerCertificate = [pscustomobject]@{ Subject = $script:signer } } }
    function Get-AutoClipPythonCandidates { @() }
    function Get-AutoClipPythonTarget { Join-Path $root 'Python311' }
    function Test-AutoClipPython { param($PythonPath) $script:probes++; $script:capable }
    function Start-Process {
        param($FilePath, $ArgumentList, [switch]$Wait, [switch]$PassThru, $WindowStyle)
        $script:calls++
        foreach ($arg in @('/passive', '/norestart', 'InstallAllUsers=0', 'PrependPath=0', 'AppendPath=0', 'Include_dev=1', 'Include_launcher=0')) {
            if ($ArgumentList -notcontains $arg) { throw "Missing fixed argument $arg" }
        }
        [pscustomobject]@{ ExitCode = $script:vendorCode }
    }
    function Check-Result {
        param([int]$Expected, [bool]$Consent = $true)
        $before = $script:calls
        $result = Install-AutoClipPython -InstallerPath $artifact -ManifestPath $manifestPath -LogDirectory $root -AcceptPythonTerms:$Consent
        if ($result.ExitCode -ne $Expected) { throw "Expected $Expected, got $($result.ExitCode): $($result.Message)" }
        if ($Expected -in @(20,21,22,23,24) -and $script:calls -ne $before) { throw 'Rejected prerequisite executed vendor installer.' }
        if ($Expected -ne 0 -and $result.PythonPath) { throw 'Failure returned a successful Python selection.' }
        if (-not (Test-Path $result.ReceiptPath)) { throw 'Missing result receipt.' }
        $receipt = Get-Content $result.ReceiptPath -Raw | ConvertFrom-Json
        if ($receipt.exit_code -ne $Expected) { throw 'Receipt lost the result code.' }
        if ($Expected -eq 3010 -and $receipt.status -ne 'pending_reboot') { throw 'Reboot was not recorded as pending.' }
        if ($Expected -eq 0 -and -not [IO.Path]::IsPathRooted($result.PythonPath)) { throw 'Python selection is not absolute.' }
    }
    Check-Result 20 $false
    $pin.build_prerequisites[0].delivery_classification = 'BLOCKED'; Save-Pin; Check-Result 21
    $pin.build_prerequisites[0].delivery_classification = 'DIRECT_RECIPIENT_DOWNLOAD'
    $pin.build_prerequisites[0].sha256 = '0' * 64; Save-Pin; Check-Result 22
    $pin.build_prerequisites[0].sha256 = (Get-FileHash $artifact).Hash
    $pin.build_prerequisites[0].bytes++; Save-Pin; Check-Result 22
    $pin.build_prerequisites[0].bytes--; Save-Pin
    [IO.File]::WriteAllText((Join-Path $root 'unattend.xml'), '<Options/>'); Check-Result 22
    Remove-Item -LiteralPath (Join-Path $root 'unattend.xml')
    $script:signer = 'CN=Other Python Software Foundation'; Check-Result 23
    $script:signer = 'CN=Python Software Foundation, O=Python Software Foundation'
    $script:signatureStatus = 'NotSigned'; Check-Result 23; $script:signatureStatus = 'Valid'
    $script:vendorCode = 42; Check-Result 25
    $script:vendorCode = 1602; Check-Result 1602
    $script:vendorCode = 3010; $before = $script:probes; Check-Result 3010
    if ($script:probes -ne $before) { throw 'Pending reboot performed an early capability check.' }
    $script:vendorCode = 0; $script:capable = $false; Check-Result 26
    $script:capable = $true; Check-Result 0
    function Get-AutoClipPythonCandidates { @('C:\shared-python\python.exe') }
    $before = $script:calls; Check-Result 0
    if ($script:calls -ne $before) { throw 'Valid shared Python was modified.' }
    $script:capable = $false; Check-Result 24
    'Python install: consent, route, size/hash/signature, exit failure/cancellation/reboot, capability, reuse PASS'
} finally {
    $resolved = [IO.Path]::GetFullPath($root)
    if (-not $resolved.StartsWith([IO.Path]::GetFullPath($env:TEMP).TrimEnd('\') + '\', [StringComparison]::OrdinalIgnoreCase)) { throw 'Unsafe test cleanup.' }
    Remove-Item -LiteralPath $resolved -Recurse -Force
}
