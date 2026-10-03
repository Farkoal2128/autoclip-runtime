param([string]$IsccPath = 'D:\AutoClip-Inno-Migration\InnoSetup7\ISCC.exe', [string]$ExportRoot, [switch]$ExportOnly)
$ErrorActionPreference = 'Stop'
$repo = Split-Path -Parent $PSScriptRoot
if ((Get-FileHash $IsccPath).Hash -ne 'd06ebd38f38e3cee60a3c50cc45bd449d77e0bc6a5cabc607ea9886808e4de1a') { throw 'Exact Inno compiler fixture differs.' }
$root = Join-Path $env:TEMP ('autoclip-python-wizard-' + [guid]::NewGuid().ToString('N'))
if ($ExportOnly -and -not $ExportRoot) { throw 'ExportOnly requires ExportRoot.' }
if ($ExportRoot) {
    $root = [IO.Path]::GetFullPath($ExportRoot)
    if (-not $root.StartsWith('D:\AutoClip-Inno-Migration\python-wizard-diag-', [StringComparison]::OrdinalIgnoreCase) -or (Test-Path -LiteralPath $root)) { throw 'Export requires a new bounded diagnostic directory.' }
    $ancestor = Split-Path -Parent $root
    while ($ancestor) { if ((Get-Item -LiteralPath $ancestor -Force).Attributes -band [IO.FileAttributes]::ReparsePoint) { throw 'Reparse export ancestor.' }; $ancestor = Split-Path -Parent $ancestor }
}
[IO.Directory]::CreateDirectory($root) | Out-Null
$oldCase = $env:AUTOCLIP_PYTHON_DIAG_CASE; $oldResult = $env:AUTOCLIP_PYTHON_DIAG_RESULT
try {
    $producerTokens = $null; $producerErrors = $null
    $producerAst = [Management.Automation.Language.Parser]::ParseFile((Join-Path $repo 'installer/install-python.ps1'), [ref]$producerTokens, [ref]$producerErrors)
    if ($producerErrors) { throw 'Actual Python receipt producer parse failed.' }
    $producer = @($producerAst.FindAll({ param($n) $n -is [Management.Automation.Language.FunctionDefinitionAst] -and
        $n.Name -in @('Assert-AutoClipPythonPath', 'Install-AutoClipPython') }, $false) | ForEach-Object { $_.Extent.Text }) -join "`r`n"
    $native = @'
param([string]$ManifestPath, [string]$CheckIdentity, [string]$InstallerPath, [string]$LogDirectory, [switch]$AcceptPythonTerms)
$ErrorActionPreference = 'Stop'
if (-not [Environment]::Is64BitProcess) { throw 'Diagnostic native child must be 64 bit.' }
$fixture = Get-Content -LiteralPath $ManifestPath -Raw | ConvertFrom-Json
if ($fixture.diagnostic -ne 'no-vendor-installation') { throw 'Invalid diagnostic manifest.' }
$m = [pscustomobject]@{ scenario = $env:AUTOCLIP_PYTHON_DIAG_CASE; trace = $env:AUTOCLIP_PYTHON_DIAG_RESULT + '.trace'; registered = (Join-Path (Split-Path -Parent $ManifestPath) 'registered.txt'); state = (Join-Path (Split-Path -Parent $ManifestPath) 'fixture-state\python-reboot-pending.txt') }
PRODUCERFUNCTIONS
function Get-AutoClipPythonCandidates { @() }
function Get-AutoClipPythonTarget { Join-Path (Split-Path -Parent $ManifestPath) 'absent-python' }
function Get-AuthenticodeSignature { [pscustomobject]@{Status='Valid';SignerCertificate=[pscustomobject]@{Subject='CN=Python Software Foundation'}} }
function Start-Process { [pscustomobject]@{ExitCode=3010} }
function Test-AutoClipPython { throw 'Pending receipt must not probe capability.' }
if ($CheckIdentity) {
 [IO.File]::AppendAllText($m.trace, "check`n")
 if ($CheckIdentity -ne 'Python') { exit 98 }
 if ($m.scenario -eq 'reuse' -or (Test-Path $m.registered)) { exit 0 }
 exit 2
}
if (-not $AcceptPythonTerms -or -not [IO.Path]::IsPathRooted($InstallerPath) -or [IO.Path]::GetFileName($InstallerPath) -ne 'python-3.11.9-amd64.exe' -or -not (Test-Path $InstallerPath)) { exit 99 }
[IO.File]::AppendAllText($m.trace, "install`n")
switch ($m.scenario) {
 'cancel' { exit 1602 }
 'failure' { exit 25 }
 'postcheck' { exit 0 }
 'pending' { $code = 3010 }
 'rebooted' { $code = 3010 }
 'state-write-fail' { $code = 3010 }
 default { $code = 0 }
}
[IO.File]::WriteAllText($m.registered, 'fixture registered capability')
if ($code -eq 3010) {
 if ($LogDirectory -ne (Join-Path (Split-Path -Parent $ManifestPath) 'fixture-python-logs')) { throw 'Diagnostic receipt path escaped private staging.' }
 $pending = Install-AutoClipPython -InstallerPath $InstallerPath -ManifestPath $ManifestPath -LogDirectory $LogDirectory -AcceptPythonTerms:$AcceptPythonTerms
 if ($pending.ExitCode -ne 3010) { throw ('Actual receipt producer failed: ' + $pending.Message) }
}
exit $code
'@
    $native = $native.Replace('PRODUCERFUNCTIONS', $producer)
    foreach ($name in @('install-python.ps1', 'preflight.ps1')) { [IO.File]::WriteAllText((Join-Path $root $name), $native) }
    $manifest = Join-Path $root 'installer-dependencies-v1.json'
    $inertBytes = [Text.Encoding]::ASCII.GetBytes('fixture never executed as a vendor installer')
    $sha = [Security.Cryptography.SHA256]::Create()
    try { $inertHash = [BitConverter]::ToString($sha.ComputeHash($inertBytes)).Replace('-', '').ToLowerInvariant() }
    finally { $sha.Dispose() }
    @{schema_version=1;diagnostic='no-vendor-installation';build_prerequisites=@(@{
        identity='Python';version='3.11.9';architecture='x64';delivery_classification='DIRECT_RECIPIENT_DOWNLOAD'
        url='https://www.python.org/ftp/python/3.11.9/python-3.11.9-amd64.exe';bytes=$inertBytes.Length;sha256=$inertHash
    })} | ConvertTo-Json -Depth 5 | Set-Content -LiteralPath $manifest -Encoding UTF8
    $manifestHash = (Get-FileHash $manifest).Hash.ToLowerInvariant()
    $nativeHash = (Get-FileHash (Join-Path $root 'install-python.ps1')).Hash.ToLowerInvariant()
    $source = Get-Content (Join-Path $repo 'installer/AutoClip.iss') -Raw
    $blocks = @()
    foreach ($name in @('VerifyHelper', 'ToolAvailable', 'PythonRebootStatus', 'ShouldSkipPage', 'PreparePython')) {
        $match = [regex]::Match($source, '(?ms)^(?:function|procedure) ' + $name + '\b.*?(?=^(?:function|procedure) |\z)')
        if (-not $match.Success) { throw "Python wizard behavioral entry point missing: $name" }
        # Only the native process boundary is redirected; Pascal decision bodies are unchanged.
        $blocks += $match.Value.Replace('ExecWithNativeSysDir(', 'FixtureExec(')
    }
    $header = @'
#define PythonHelperSha256 "NATIVEHASH"
#define PreflightSha256 "NATIVEHASH"
#define PythonSha256 "5ee42c4eee1e6b4464bb23722f90b45303f79442df63083f05322f1785f5fdde"
#define DependencyManifestSha256 "MANIFESTHASH"
[Setup]
AppId=AutoClipPythonDiagnosticOnly
AppName=AutoClip Python diagnostic only
AppVersion=1
DefaultDirName={tmp}\never-installed
CreateAppDir=no
Uninstallable=no
PrivilegesRequired=lowest
ArchitecturesAllowed=x64os
OutputBaseFilename=python-wizard-diagnostic
[Files]
Source: "install-python.ps1"; Flags: dontcopy
Source: "preflight.ps1"; Flags: dontcopy
Source: "installer-dependencies-v1.json"; Flags: dontcopy
[Code]
var
 PythonConsentPage: TInputOptionWizardPage;
 DownloadPage: TOutputMarqueeProgressWizardPage;
 PythonRestartPending: Boolean;
 FixtureCase, FixtureResult, FixtureTrace, FixtureBoot: String;
 NativeCalls, Downloads: Integer;
function PythonStatePath: String;
begin Result := ExpandConstant('{tmp}\fixture-state\python-reboot-pending.txt'); end;
function PythonLogDirectory: String;
begin Result := ExpandConstant('{tmp}\fixture-python-logs'); end;
function FixtureExec(const Filename, Params, WorkingDir: String; const ShowCmd: Integer; const Wait: TExecWait; var ResultCode: Integer): Boolean;
var P: String;
begin
 P := Params;
 if Pos(' -Command ', P) > 0 then begin
   StringChangeEx(P, '(Get-CimInstance Win32_OperatingSystem)', '([pscustomobject]@{LastBootUpTime=[datetime]::new(' + FixtureBoot + ',[DateTimeKind]::Utc)})', True);
   if (FixtureCase = 'state-write-fail') and (Pos('$mark = $true', P) > 0) then begin ResultCode := 2; Result := True; Exit; end;
 end else begin
   NativeCalls := NativeCalls + 1;
   if (FixtureCase = 'launch-fail') and (Pos(' -InstallerPath ', P) > 0) then begin Result := False; ResultCode := 5; Exit; end;
 end;
 SaveStringToFile(FixtureResult + '.native', Filename + #13#10 + P + #13#10, True);
 Result := ExecWithNativeSysDir(Filename, P, WorkingDir, SW_HIDE, Wait, ResultCode);
 SaveStringToFile(FixtureResult + '.native', 'launched=' + IntToStr(Ord(Result)) + ';exit=' + IntToStr(ResultCode) + #13#10, True);
end;
function DownloadArtifact(Identity, FileName, ExpectedHash: String): Boolean;
begin
 if (Identity <> 'Python') or (FileName <> 'python-3.11.9-amd64.exe') or (ExpectedHash <> '{#PythonSha256}') then RaiseException('Wrong Python acquisition identity.');
 Downloads := Downloads + 1;
 SaveStringToFile(FixtureTrace, 'download' + #13#10, True);
 Result := FixtureCase <> 'download-fail';
 if Result then Result := SaveStringToFile(ExpandConstant('{tmp}\') + FileName, 'fixture never executed as a vendor installer', False);
end;
'@
    $tail = @'
procedure InitializeWizard;
var
 Outcome, FirstOutcome: String;
 Contents: AnsiString;
 NeedsRestart, FirstRestart, Skip: Boolean;
begin
 FixtureCase := ExpandConstant('{param:CASE|decline}');
 FixtureResult := ExpandConstant('{param:RESULT|}');
 FixtureTrace := FixtureResult + '.trace';
 FixtureBoot := '638000000000000000';
 ExtractTemporaryFile('installer-dependencies-v1.json');
 PythonConsentPage := CreateInputOptionPage(wpWelcome, 'Fixture consent only', 'Not vendor acceptance', 'Diagnostic boolean input only.', False, False);
 PythonConsentPage.Add('Fixture declaration');
 PythonConsentPage.Values[0] := (FixtureCase <> 'decline') and (FixtureCase <> 'reuse');
 DownloadPage := CreateOutputMarqueeProgressPage('Fixture download', 'No network or vendor installer');
 ExtractTemporaryFile('preflight.ps1');
 ExtractTemporaryFile('install-python.ps1');
 if FixtureCase = 'foreign-state' then begin ForceDirectories(ExtractFileDir(PythonStatePath)); SaveStringToFile(PythonStatePath, 'foreign preserved', False); end;
 Skip := ShouldSkipPage(PythonConsentPage.ID);
 NeedsRestart := False;
 Outcome := PreparePython(NeedsRestart);
 FirstOutcome := Outcome;
 FirstRestart := NeedsRestart;
 if (FixtureCase = 'pending') or (FixtureCase = 'rebooted') or (FixtureCase = 'state-write-fail') then begin
   PythonRestartPending := False; { model a fresh setup process using only durable state }
   PythonConsentPage.Values[0] := False;
   if FixtureCase = 'rebooted' then FixtureBoot := '640000000000000000';
   NeedsRestart := False;
   Outcome := PreparePython(NeedsRestart);
 end;
 Contents := '';
 if FileExists(PythonStatePath) then LoadStringFromFile(PythonStatePath, Contents);
 SaveStringToFile(FixtureResult, IntToStr(Downloads) + #13#10 + IntToStr(NativeCalls) + #13#10 + IntToStr(Ord(Skip)) + #13#10 + IntToStr(Ord(NeedsRestart)) + #13#10 + FirstOutcome + #13#10 + Outcome + #13#10 + Contents, False);
 Abort; { never enter installation }
end;
'@
    [IO.File]::WriteAllText((Join-Path $root 'diagnostic.iss'), $header.Replace('NATIVEHASH', $nativeHash).Replace('MANIFESTHASH', $manifestHash) + "`n" + ($blocks -join "`n") + "`n" + $tail)
    $nativeErrors = $ErrorActionPreference
    try {
        $ErrorActionPreference = 'Continue'
        $compileOutput = & $IsccPath ('--output-dir=' + $root) (Join-Path $root 'diagnostic.iss') 2>&1 | Out-String
    } finally { $ErrorActionPreference = $nativeErrors }
    if ($LASTEXITCODE -ne 0) { throw "Diagnostic ISCC failed: $compileOutput" }
    [IO.File]::WriteAllText((Join-Path $root 'compile.log'), $compileOutput)
    Copy-Item -LiteralPath (Join-Path $repo 'installer/AutoClip.iss') -Destination (Join-Path $root 'production-AutoClip.iss')
    $testSource = Get-Content -LiteralPath $PSCommandPath -Raw
    $runnerStart = $testSource.IndexOf("    foreach (`$scenario in @('reuse'")
    $runnerEnd = $testSource.IndexOf("`n} finally {", $runnerStart)
    $runner = 'param([string]$root = $PSScriptRoot)' + "`n`$ErrorActionPreference = 'Stop'`n" + $testSource.Substring($runnerStart, $runnerEnd - $runnerStart)
    [IO.File]::WriteAllText((Join-Path $root 'run-diagnostic.ps1'), $runner)
    $files = Get-ChildItem -LiteralPath $root -File | ForEach-Object { @{name=$_.Name;sha256=(Get-FileHash -LiteralPath $_.FullName).Hash.ToLowerInvariant();size=$_.Length} }
    @{schema_version=1;status='DIAGNOSTIC_ONLY_NOT_SETUP_APPROVAL';compiler_sha256=(Get-FileHash $IsccPath).Hash.ToLowerInvariant();files=@($files);boundaries='Actual Pascal decisions and Python pending-receipt producer; inert acquisition, registry discovery, target path, signature and vendor process outcomes; private temporary state/log paths and substituted boot read; no vendor installation or consent.'} | ConvertTo-Json -Depth 5 | Set-Content -LiteralPath (Join-Path $root 'export-receipt.json') -Encoding UTF8
    if ($ExportOnly) { Write-Output ('Exported diagnostic: ' + $root); return }
    foreach ($scenario in @('reuse', 'decline', 'success', 'postcheck', 'cancel', 'failure', 'download-fail', 'launch-fail', 'pending', 'rebooted', 'state-write-fail', 'foreign-state')) {
        $result = Join-Path $root ($scenario + '.txt')
        $env:AUTOCLIP_PYTHON_DIAG_CASE = $scenario; $env:AUTOCLIP_PYTHON_DIAG_RESULT = $result
        $process = Start-Process -FilePath (Join-Path $root 'python-wizard-diagnostic.exe') -ArgumentList @('/VERYSILENT','/SUPPRESSMSGBOXES','/NORESTART',('/CASE=' + $scenario),('/RESULT=' + $result)) -WindowStyle Hidden -PassThru
        if (-not $process.WaitForExit(30000)) { $process.Kill(); throw "Diagnostic timed out: $scenario" }
        if (-not (Test-Path $result)) { throw "Diagnostic produced no behavioral result: $scenario" }
        $lines = [IO.File]::ReadAllText($result).Split(@("`r`n"), [StringSplitOptions]::None)
        $trace = if (Test-Path ($result + '.trace')) { [IO.File]::ReadAllText($result + '.trace') } else { '' }
        $success = $scenario -in @('reuse', 'success', 'rebooted')
        if (($lines[5] -eq '') -ne $success) { throw "Incorrect diagnostic outcome $scenario`: $($lines -join '|') $trace" }
        if ($lines[3] -ne '0') { throw 'Silent diagnostic must never request automatic restart.' }
        if ($scenario -in @('reuse','decline','foreign-state') -and ($lines[0] -ne '0' -or $trace -match 'install')) { throw "Acquisition occurred without need/consent: $scenario" }
        if ($scenario -eq 'reuse' -and $lines[2] -ne '1') { throw 'Compatible registered Python must skip its consent page.' }
        if ($scenario -ne 'reuse' -and $lines[2] -ne '0') { throw "Missing Python must show separate consent: $scenario" }
        if ($scenario -in @('pending','rebooted','state-write-fail') -and ([regex]::Matches($trace, '(?m)^install').Count -ne 1 -or $lines[0] -ne '1' -or -not $lines[4])) { throw "Pending retry reacquired or lost state: $scenario" }
        if ($scenario -eq 'foreign-state' -and $lines[6] -ne 'foreign preserved') { throw 'Foreign reboot state was changed.' }
        if ($scenario -eq 'rebooted' -and $lines[6]) { throw 'Owned marker was not cleared after changed boot and capability check.' }
    }
    'Compiled Python wizard: actual Pascal decisions/native PS children, conditional consent, exact acquisition identity, decline/cancellation/failure/postcheck, durable same/new-boot retry, atomic/foreign state and silent no-restart PASS'
} finally {
    $env:AUTOCLIP_PYTHON_DIAG_CASE = $oldCase; $env:AUTOCLIP_PYTHON_DIAG_RESULT = $oldResult
    if (-not $ExportRoot -and (Test-Path -LiteralPath $root)) { Remove-Item -LiteralPath $root -Recurse -Force }
}
