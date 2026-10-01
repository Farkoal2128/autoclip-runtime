$ErrorActionPreference = 'Stop'
$repo = Split-Path -Parent $PSScriptRoot
$source = Get-Content -LiteralPath (Join-Path $repo 'release/scripts/build-native-from-source.ps1') -Raw
$tokens = $null
$errors = $null
$ast = [Management.Automation.Language.Parser]::ParseInput($source, [ref]$tokens, [ref]$errors)
if ($errors.Count) { throw 'Native build script parse failed.' }

$progress = $ast.Find({
    param($node)
    $node -is [Management.Automation.Language.FunctionDefinitionAst] -and
        $node.Name -eq 'Show-NativeBuildProgress'
}, $true)
if (-not $progress) { throw 'Native build progress function is missing.' }
$complete = $ast.Find({
    param($node)
    $node -is [Management.Automation.Language.FunctionDefinitionAst] -and
        $node.Name -eq 'Complete-NativeBuildProgress'
}, $true)
if (-not $complete) { throw 'Native build progress completion is missing.' }

$events = New-Object System.Collections.ArrayList
function Write-Progress {
    param([int]$Id, [string]$Activity, [string]$Status, [int]$PercentComplete, [switch]$Completed)
    [void]$events.Add(@{ Id = $Id; Activity = $Activity; Status = $Status; Percent = $PercentComplete; Completed = [bool]$Completed })
}
. ([ScriptBlock]::Create($progress.Extent.Text))
. ([ScriptBlock]::Create($complete.Extent.Text))
Show-NativeBuildProgress -Stage 'Building CTranslate2' -Percent 75
Complete-NativeBuildProgress
if ($events.Count -ne 2 -or $events[0].Id -ne 2 -or
    $events[0].Activity -ne 'Native source build' -or
    $events[0].Status -ne 'Building CTranslate2' -or
    $events[0].Percent -ne 75 -or -not $events[1].Completed) {
    throw 'Native build progress did not emit and clear expected activity.'
}
foreach ($stage in @('Preparing source and build tools', 'Building FFmpeg',
                    'Building PyAV', 'Building oneDNN', 'Building CTranslate2',
                    'Verifying native wheels', 'Reusing verified native wheels')) {
    if (-not $source.Contains($stage)) { throw "Native build progress stage is missing: $stage" }
}
Write-Host 'Native build progress stages and completion passed.'
