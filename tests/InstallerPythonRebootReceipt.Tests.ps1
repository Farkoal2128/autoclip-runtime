param([string]$EvidenceRoot)
$ErrorActionPreference = 'Stop'
$repo = Split-Path -Parent $PSScriptRoot
$source = Get-Content (Join-Path $repo 'installer/AutoClip.iss') -Raw
$helper = Join-Path $repo 'installer/install-python.ps1'
$tokens = $null; $errors = $null
$ast = [Management.Automation.Language.Parser]::ParseFile($helper, [ref]$tokens, [ref]$errors)
if ($errors) { throw 'Python producer parse failed.' }
foreach ($node in $ast.FindAll({ param($n) $n -is [Management.Automation.Language.FunctionDefinitionAst] }, $false)) {
    Invoke-Expression $node.Extent.Text
}
$root = Join-Path $env:TEMP ('autoclip-python-receipt-' + [guid]::NewGuid().ToString('N'))
[IO.Directory]::CreateDirectory($root) | Out-Null
try {
    # Substitute local path boundaries; derive the producer directory from the actual wizard.
    $prepare = [regex]::Match($source, '(?ms)^function PreparePython\b.*?(?=^procedure )').Value
    $provider = [regex]::Match($source, '(?ms)^function PythonLogDirectory\b.*?(?=^function )').Value
    $pathSource = if ($provider) { $provider } else { $prepare }
    $logConstant = [regex]::Match($pathSource, "ExpandConstant\('\{localappdata\}([^']*PythonSetupLogs)'\)")
    if (-not $logConstant.Success) { throw 'Wizard Python log path is unavailable.' }
    $LogDirectory = $root + $logConstant.Groups[1].Value
    $StatePath = Join-Path $root 'AutoClip\Setup\python-reboot-pending.txt'
    $Mark = '$false'
    $artifact = Join-Path $root 'python-3.11.9-amd64.exe'
    [IO.File]::WriteAllText($artifact, 'inert receipt fixture, never executed')
    $manifest = Join-Path $root 'manifest.json'
    @{schema_version=1;build_prerequisites=@(@{
        identity='Python';version='3.11.9';architecture='x64';delivery_classification='DIRECT_RECIPIENT_DOWNLOAD'
        url='https://www.python.org/ftp/python/3.11.9/python-3.11.9-amd64.exe'
        bytes=(Get-Item $artifact).Length;sha256=(Get-FileHash $artifact).Hash
    })} | ConvertTo-Json -Depth 5 | Set-Content -LiteralPath $manifest -Encoding UTF8
    # Only registry discovery, target path, Authenticode and vendor process outcomes are inert.
    function Get-AutoClipPythonCandidates { @() }
    function Get-AutoClipPythonTarget { Join-Path $root 'absent-python' }
    function Get-AuthenticodeSignature { [pscustomobject]@{Status='Valid';SignerCertificate=[pscustomobject]@{Subject='CN=Python Software Foundation'}} }
    function Start-Process { [pscustomobject]@{ExitCode=3010} }
    function Test-AutoClipPython { throw 'Pending receipt must not invoke capability verification.' }
    $result = Install-AutoClipPython -InstallerPath $artifact -ManifestPath $manifest -LogDirectory $LogDirectory -AcceptPythonTerms
    $receipt = Get-Content -LiteralPath $result.ReceiptPath -Raw | ConvertFrom-Json
    if ($result.ExitCode -ne 3010 -or $receipt.status -ne 'pending_reboot' -or $receipt.vendor_exit_code -ne 3010 -or
        (Split-Path -Parent $result.ReceiptPath) -ne $LogDirectory) { throw 'Actual Python producer did not write a pending receipt to the wizard path.' }
    $receiptHash = (Get-FileHash $result.ReceiptPath).Hash
    $body = [regex]::Match($source, '(?ms)^function PythonRebootStatus\b.*?(?=^function )').Value
    $expression = [regex]::Match($body, '(?s)Command := (.*?);\s*Params :=').Groups[1].Value
    if (-not $expression) { throw 'Generated reboot command is missing.' }
    # Decode Pascal string concatenation; reject anything other than literals and path/boolean bindings.
    $pieces = [regex]::Matches($expression, "'(?:''|[^'])*'|\b(?:StatePath|LogDirectory|Mark)\b")
    $remainder = [regex]::Replace($expression, "'(?:''|[^'])*'|\b(?:StatePath|LogDirectory|Mark)\b|\+|\s", '')
    if ($remainder) { throw "Unrecognized Pascal command expression: $remainder" }
    $script:generated = ($pieces | ForEach-Object {
        if ($_.Value.StartsWith("'")) { $_.Value.Substring(1, $_.Value.Length-2).Replace("''", "'") }
        else { (Get-Variable $_.Value -ValueOnly).Replace("'", "''") }
    }) -join ''
    $script:generated = $script:generated.Replace('{#PythonHelperSha256}', (Get-FileHash $helper).Hash.ToLowerInvariant())
    function Check-RebootCommand([long]$Boot, [int]$Expected, [string]$Name, [bool]$MarkPending = $false) {
        $command = $script:generated.Replace('(Get-CimInstance Win32_OperatingSystem)', "([pscustomobject]@{LastBootUpTime=[datetime]::new($Boot,[DateTimeKind]::Utc)})")
        if ($MarkPending) { $command = $command.Replace('$mark = $false', '$mark = $true') }
        $parseTokens = $null; $parseErrors = $null
        $null = [Management.Automation.Language.Parser]::ParseInput($command, [ref]$parseTokens, [ref]$parseErrors)
        if ($parseErrors) { throw 'Generated reboot command parse failed.' }
        $encoded = [Convert]::ToBase64String([Text.Encoding]::Unicode.GetBytes($command))
        $nativePreference = $ErrorActionPreference
        try {
            $ErrorActionPreference = 'Continue'
            $output = & "$env:WINDIR\System32\WindowsPowerShell\v1.0\powershell.exe" -NoProfile -NonInteractive -EncodedCommand $encoded 2>&1 | Out-String
            $code = $LASTEXITCODE
        } finally { $ErrorActionPreference = $nativePreference }
        if ($code -ne $Expected) { throw "${Name}: expected $Expected, got ${code}: $output" }
        Write-Output "${Name}: exit $code PASS"
    }
    $timestamp = ([datetime]$receipt.timestamp_utc).ToUniversalTime().Ticks
    Check-RebootCommand ($timestamp-1) 3010 'Real producer receipt, same boot, absent durable marker'
    Check-RebootCommand ($timestamp+1) 0 'Real producer receipt, changed boot, normal verification eligible'
    Check-RebootCommand ($timestamp-1) 3010 'Atomic owned marker publication' $true
    $markerHash = (Get-FileHash $StatePath).Hash
    Check-RebootCommand ($timestamp-1) 3010 'Owned marker, same boot'
    if ((Get-FileHash $StatePath).Hash -ne $markerHash) { throw 'Same-boot marker was modified.' }
    Check-RebootCommand ($timestamp+1) 0 'Owned marker, changed boot'
    if (Test-Path -LiteralPath $StatePath) { throw 'Changed-boot owned marker was retained.' }
    if ((Get-FileHash $result.ReceiptPath).Hash -ne $receiptHash) { throw 'Pending receipt was modified.' }
    $invalid = Join-Path $LogDirectory 'python-invalid.json'
    [IO.File]::WriteAllText($invalid, 'invalid preserved receipt')
    Check-RebootCommand ($timestamp-1) 2 'Malformed receipt fails closed'
    if ([IO.File]::ReadAllText($invalid) -ne 'invalid preserved receipt') { throw 'Malformed receipt was modified.' }
    Remove-Item -LiteralPath $invalid
    [IO.Directory]::CreateDirectory((Split-Path -Parent $StatePath)) | Out-Null
    [IO.File]::WriteAllText($StatePath, 'foreign preserved state')
    Check-RebootCommand ($timestamp-1) 2 'Foreign marker fails closed'
    if ([IO.File]::ReadAllText($StatePath) -ne 'foreign preserved state') { throw 'Foreign marker was modified.' }
    Remove-Item -LiteralPath $StatePath
    $movedLogs = $LogDirectory + '-real'
    [IO.Directory]::Move($LogDirectory, $movedLogs)
    $null = New-Item -ItemType Junction -Path $LogDirectory -Target $movedLogs
    try { Check-RebootCommand ($timestamp-1) 2 'Reparse receipt directory fails closed' }
    finally { [IO.Directory]::Delete($LogDirectory); [IO.Directory]::Move($movedLogs, $LogDirectory) }
    $stateCheck = $prepare.IndexOf('State := PythonRebootStatus(False)')
    if ($stateCheck -lt 0 -or $prepare.IndexOf('if State <> 0') -lt $stateCheck -or
        $prepare.IndexOf("ToolAvailable('Python')") -lt $prepare.IndexOf('if State <> 0') -or
        $prepare.IndexOf('DownloadArtifact(') -lt $prepare.IndexOf("ToolAvailable('Python')")) { throw 'Python reboot guards no longer precede capability reuse and acquisition.' }
    if ($EvidenceRoot) {
        [IO.Directory]::CreateDirectory($EvidenceRoot) | Out-Null
        Copy-Item -LiteralPath $result.ReceiptPath -Destination (Join-Path $EvidenceRoot 'real-producer-pending-receipt.json')
        [IO.File]::WriteAllText((Join-Path $EvidenceRoot 'generated-reboot-command.ps1'), $script:generated)
    }
    'Python receipt handoff: real producer/generated consumer, boot boundaries, preserved invalid/reparse state PASS; Pascal caller order inspected, native execution unverified'
} finally {
    $resolved = [IO.Path]::GetFullPath($root)
    if (-not $resolved.StartsWith([IO.Path]::GetFullPath($env:TEMP).TrimEnd('\') + '\', [StringComparison]::OrdinalIgnoreCase)) { throw 'Unsafe fixture cleanup.' }
    Remove-Item -LiteralPath $resolved -Recurse -Force
}
