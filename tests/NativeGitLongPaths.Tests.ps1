$ErrorActionPreference = 'Stop'
$repo = Split-Path -Parent $PSScriptRoot
$path = Join-Path $repo 'release\scripts\build-native-from-source.ps1'
$source = Get-Content -LiteralPath $path -Raw
$tokens = $null
$parseErrors = $null
$ast = [Management.Automation.Language.Parser]::ParseInput($source, [ref]$tokens, [ref]$parseErrors)
if ($parseErrors.Count) { throw 'Native source recipe did not parse.' }
$function = $ast.Find({
    param($node)
    $node -is [Management.Automation.Language.FunctionDefinitionAst] -and
        $node.Name -eq 'Get-PinnedGitSource'
}, $true)
if (-not $function) { throw 'Pinned Git source function is missing.' }
$body = $function.Extent.Text
foreach ($operation in @('clone', 'checkout', 'submodule')) {
    $pattern = "(?s)Invoke-Checked 'git' @\('\-c', 'core\.longpaths=true'.*?'$operation'"
    if ($body -notmatch $pattern) {
        throw "Pinned Git source $operation does not enable long Windows paths."
    }
}
Write-Host 'Pinned native Git clone, checkout and submodules enable long Windows paths.'
