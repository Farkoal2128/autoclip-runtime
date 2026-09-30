$ErrorActionPreference = 'Stop'
$repo = Split-Path -Parent $PSScriptRoot
$tokens = $null
$errors = $null
$ast = [Management.Automation.Language.Parser]::ParseFile((Join-Path $repo 'install.ps1'), [ref]$tokens, [ref]$errors)
if ($errors.Count) { throw 'Installer parse failed.' }
$function = $ast.Find({
    param($node)
    $node -is [Management.Automation.Language.FunctionDefinitionAst] -and
        $node.Name -eq 'Confirm-PrerequisiteTerms'
}, $true)
if (-not $function) { throw 'Installer consent helper is missing.' }

$root = Join-Path $env:TEMP ('autoclip-inline-install-' + [guid]::NewGuid().ToString('N'))
New-Item -ItemType Directory -Path $root | Out-Null
try {
    $bytes = [Text.Encoding]::UTF8.GetBytes('Fixture terms only')
    $sha = ([BitConverter]::ToString([Security.Cryptography.SHA256]::Create().ComputeHash($bytes))).Replace('-', '').ToLowerInvariant()
    $script:EmbeddedPrerequisiteTerms = @{
        schema_version = 1
        terms = @(@{
            id = 'cuda'; title = 'Fixture'; version = 'test'; url = 'https://example.org/fixture'
            extension = 'txt'; sha256 = $sha; content_base64 = [Convert]::ToBase64String($bytes)
        })
    } | ConvertTo-Json -Depth 5
    $inline = [ScriptBlock]::Create(@"
param([string]`$ReceiptRoot)
$($function.Extent.Text)
if (`$PSScriptRoot) { throw 'Fixture must run without a script root.' }
Confirm-PrerequisiteTerms -Id cuda -ReceiptRoot `$ReceiptRoot -Accepted -NonInteractive
"@)
    & $inline $root
    $copies = @(Get-ChildItem -LiteralPath (Join-Path $root 'terms') -Filter 'cuda-*.txt')
    $receipts = @(Get-ChildItem -LiteralPath (Join-Path $root 'terms') -Filter 'cuda-acceptance-*.json')
    if ($copies.Count -ne 1 -or $receipts.Count -ne 1) {
        throw 'Inline installer did not preserve the exact terms and acceptance receipt.'
    }
    Write-Output 'Inline installer consent uses embedded terms without a script root.'
} finally {
    $script:EmbeddedPrerequisiteTerms = $null
    if (-not ([IO.Path]::GetFullPath($root).StartsWith([IO.Path]::GetFullPath($env:TEMP)))) {
        throw 'Unsafe fixture cleanup.'
    }
    Remove-Item -LiteralPath $root -Recurse -Force
}
