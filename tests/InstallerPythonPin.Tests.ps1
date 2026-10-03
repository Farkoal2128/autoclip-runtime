$ErrorActionPreference = 'Stop'
$repo = Split-Path -Parent $PSScriptRoot
$tokens = $null
$parseErrors = $null
$ast = [Management.Automation.Language.Parser]::ParseFile((Join-Path $repo 'install.ps1'), [ref]$tokens, [ref]$parseErrors)
if ($parseErrors) { throw 'Installer parse failed.' }
$allCommands = @($ast.FindAll({
    param($node)
    $node -is [Management.Automation.Language.CommandAst] -and $node.Extent.Text -match '^& \$uv\.Source venv\b'
}, $true))
$commands = @($allCommands | Where-Object { $_.Extent.Text -match '--python 3\.11\.9(?:\s|$)' })
$publisherCommands = @($allCommands | Where-Object { $_.Extent.Text -match '--python \(\[string\]\$verifiedPython\[0\]\)' })
if ($allCommands.Count -ne 3 -or $publisherCommands.Count -ne 1 -or $publisherCommands[0].Extent.Text -notmatch '--no-managed-python --no-python-downloads') {
    throw 'Publisher CPU must use the verified absolute interpreter without managed Python or implicit downloads.'
}
if ($commands.Count -ne 2) { throw 'Expected initial and fallback uv venv calls.' }
$assignments = @($ast.FindAll({
    param($node)
    $node -is [Management.Automation.Language.AssignmentStatementAst] -and $node.Extent.Text -match '^\$pythonDownloadOption\s*='
}, $true))
if ($assignments.Count -ne 1) { throw 'Expected one actual Python download option assignment.' }
$root = Join-Path $env:TEMP ('autoclip-python-pin-' + [guid]::NewGuid().ToString('N'))
New-Item -ItemType Directory -Path $root | Out-Null
try {
    $log = Join-Path $root 'uv-args.txt'
    $fakeUv = Join-Path $root 'uv.cmd'
    [IO.File]::WriteAllText($fakeUv, "@echo off`r`necho %*>>`"$log`"`r`nexit /b 0`r`n", [Text.Encoding]::ASCII)
    $uv = [pscustomobject]@{ Source = $fakeUv }
    $venvOptions = @()
    $NoPrerequisiteAcquisition = $true
    Invoke-Expression $assignments[0].Extent.Text
    $venv = Join-Path $root 'venv'
    foreach ($command in $commands) { Invoke-Expression $command.Extent.Text }
    $calls = @(Get-Content -LiteralPath $log)
    if ($calls.Count -ne 2 -or @($calls | Where-Object { $_ -notmatch '--python 3\.11\.9(?:\s|$)' }).Count) {
        throw "uv venv did not pin Python 3.11.9 in both paths: $($calls -join '; ')"
    }
    if (@($calls | Where-Object { $_ -notmatch '--no-python-downloads' }).Count) {
        throw "Guarded uv option was not passed intact; native calls: $($calls -join '; ')"
    }
    if ($pythonDownloadOption -isnot [array] -or $pythonDownloadOption.Count -ne 1) {
        throw 'Guarded Python download option must remain a one-element splattable array.'
    }
    $NoPrerequisiteAcquisition = $false
    Invoke-Expression $assignments[0].Extent.Text
    if ($pythonDownloadOption -isnot [array] -or $pythonDownloadOption.Count -ne 0) {
        throw 'Ordinary Python download option must remain an empty splattable array.'
    }
    Invoke-Expression $commands[0].Extent.Text
    $ordinaryCall = @(Get-Content -LiteralPath $log)[-1]
    if ($ordinaryCall -match '--no-python-downloads' -or $ordinaryCall -notmatch '--python 3\.11\.9(?:\s|$)') {
        throw 'Ordinary uv initial call must retain Python pin without a guarded download option.'
    }
    'Installer Python: both uv venv calls pin 3.11.9 and disable implicit download PASS'
} finally {
    $resolved = [IO.Path]::GetFullPath($root)
    $safeParent = [IO.Path]::GetFullPath($env:TEMP).TrimEnd('\') + '\'
    if (-not $resolved.StartsWith($safeParent, [StringComparison]::OrdinalIgnoreCase)) { throw 'Unsafe fixture cleanup path.' }
    Remove-Item -LiteralPath $resolved -Recurse -Force
}
