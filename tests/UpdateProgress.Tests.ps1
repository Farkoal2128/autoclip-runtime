$ErrorActionPreference = 'Stop'
$repo = Split-Path -Parent $PSScriptRoot
$source = Get-Content -LiteralPath (Join-Path $repo 'update.ps1') -Raw
$tokens = $null
$parseErrors = $null
$ast = [Management.Automation.Language.Parser]::ParseInput($source, [ref]$tokens, [ref]$parseErrors)
if ($parseErrors.Count) { throw 'Updater parse failed.' }

$progress = $ast.Find({
    param($node)
    $node -is [Management.Automation.Language.FunctionDefinitionAst] -and
        $node.Name -eq 'Show-UpdateProgress'
}, $true)
if (-not $progress) { throw 'Updater progress meter is missing.' }
$complete = $ast.Find({
    param($node)
    $node -is [Management.Automation.Language.FunctionDefinitionAst] -and
        $node.Name -eq 'Complete-UpdateProgress'
}, $true)
if (-not $complete) { throw 'Updater progress completion is missing.' }

$events = New-Object System.Collections.ArrayList
function Write-Progress {
    param([int]$Id, [string]$Activity, [string]$Status, [int]$PercentComplete, [switch]$Completed)
    [void]$events.Add(@{ Id = $Id; Activity = $Activity; Status = $Status; Percent = $PercentComplete; Completed = [bool]$Completed })
}
. ([ScriptBlock]::Create($progress.Extent.Text))
. ([ScriptBlock]::Create($complete.Extent.Text))
Show-UpdateProgress -Stage 'Preparing exact release' -Percent 15
Complete-UpdateProgress
if ($events.Count -ne 2 -or $events[0].Id -ne 0 -or $events[0].Activity -ne 'Updating AutoClip' -or
    $events[0].Status -ne 'Preparing exact release' -or $events[0].Percent -ne 15 -or
    -not $events[1].Completed) {
    throw 'Updater progress meter did not emit and clear expected activity.'
}
foreach ($stage in @('Checking installed release', 'Preparing exact release',
                    'Installing and verifying new runtime', 'Activating verified release')) {
    if (-not $source.Contains($stage)) { throw "Updater progress stage is missing: $stage" }
}
if ($source -notmatch '(?s)finally\s*\{\s*Complete-UpdateProgress') {
    throw 'Updater progress must clear on success and failure.'
}
Write-Host 'Updater progress stages and completion passed.'
