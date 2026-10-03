$ErrorActionPreference = 'Stop'
$install = Join-Path $PSScriptRoot '../install.ps1'
$tokens = $null; $errors = $null
$ast = [Management.Automation.Language.Parser]::ParseFile($install, [ref]$tokens, [ref]$errors)
if ($errors.Count) { throw 'Installer parse failed.' }
$boundary = @($ast.FindAll({ param($node)
    $node -is [Management.Automation.Language.IfStatementAst] -and
    $node.Clauses.Count -eq 1 -and $node.Clauses[0].Item1.Extent.Text -ceq '$microsoft' -and
    $node.Extent.Text.Contains('Start-Process')
}, $true))
if ($boundary.Count -ne 1) { throw 'Actual Microsoft runtime execution boundary is absent or ambiguous.' }
$action = [scriptblock]::Create($boundary[0].Extent.Text + "`n`$script:continued = `$true")
$microsoft = 'C:\inert-first-party-fixture\VC_redist.x64.exe'
function Start-Process {
    param($FilePath, $ArgumentList, [switch]$Wait, [switch]$PassThru, $Verb, $WindowStyle)
    if ($FilePath -cne $microsoft -or ($ArgumentList -join '|') -cne '/install|/norestart' -or
        -not $Wait -or -not $PassThru -or $Verb -cne 'RunAs' -or $WindowStyle -cne 'Normal') {
        throw 'Vendor execution arguments or wait behavior changed.'
    }
    $script:calls++
    if ($script:uacDenied) { throw [ComponentModel.Win32Exception]::new(1223) }
    return [pscustomobject]@{ ExitCode = $script:vendorCode }
}
foreach ($code in @(0, 3010, 1603, 1223)) {
    $script:vendorCode = $code; $script:uacDenied = $false
    $script:continued = $false; $script:calls = 0; $failure = $null
    try { & $action } catch { $failure = $_ }
    if ($script:calls -ne 1) { throw 'Actual runtime boundary did not invoke the process boundary once.' }
    if ($code -eq 0) {
        if ($failure -or -not $script:continued) { throw 'Successful runtime installation cannot continue.' }
    } elseif ($code -eq 3010) {
        if (-not $failure -or $script:continued -or $failure.Exception.Message -notlike '*requires a reboot*') {
            throw 'RED: VC runtime reboot request allowed source building to continue.'
        }
    } elseif (-not $failure -or $script:continued -or $failure.Exception.Message -notlike "*failed: $code*") {
        throw "VC runtime failure $code was swallowed or allowed source building."
    }
}
$script:uacDenied = $true; $script:continued = $false
$failure = $null
try { & $action } catch { $failure = $_ }
if (-not $failure -or $script:continued -or $failure.Exception.NativeErrorCode -ne 1223) {
    throw 'UAC cancellation did not stop the actual runtime boundary.'
}
'PASS actual VC execution boundary: success continues; reboot, failure and UAC cancellation stop'
'Inert process boundary only: no vendor installer, VM or generated setup/uninstaller executed.'
