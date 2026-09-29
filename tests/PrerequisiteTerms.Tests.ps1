$ErrorActionPreference='Stop'
. (Join-Path $PSScriptRoot '..\release\scripts\prerequisite-terms.ps1')
$root=Join-Path $env:TEMP ('autoclip-terms-test-'+[guid]::NewGuid().ToString('N'))
New-Item -ItemType Directory -Path $root | Out-Null
try {
    $bytes=[Text.Encoding]::UTF8.GetBytes('Fixture terms only')
    $hash=([BitConverter]::ToString([Security.Cryptography.SHA256]::Create().ComputeHash($bytes))).Replace('-','').ToLowerInvariant()
    $manifest=Join-Path $root 'terms.json'
    @{schema_version=1;terms=@(@{id='cuda';title='Fixture';version='test';url='https://example.org/fixture';extension='txt';sha256=$hash;content_base64=[Convert]::ToBase64String($bytes)})} | ConvertTo-Json -Depth 5 | Set-Content $manifest
    foreach ($answer in @('', 'accept', 'no')) {
        $declined=$false
        try { Confirm-PrerequisiteTerms -Id cuda -ReceiptRoot $root -TermsManifest $manifest -PromptScript {param($message) $answer} } catch { $declined=$_.Exception.Message -eq 'Recipient declined prerequisite terms.' }
        if (-not $declined) { throw 'Only exact affirmative ACCEPT is valid.' }
    }
    $declined=$false
    try { Confirm-PrerequisiteTerms -Id cuda -ReceiptRoot $root -TermsManifest $manifest -NonInteractive } catch { $declined=$_.Exception.Message -like 'Explicit prerequisite terms acceptance required:*' }
    if (-not $declined -or @(Get-ChildItem (Join-Path $root 'terms') -Filter '*acceptance*').Count) { throw 'Unattended or declined flow must not write acceptance.' }
    Confirm-PrerequisiteTerms -Id cuda -ReceiptRoot $root -TermsManifest $manifest -PromptScript { 'ACCEPT' }
    Confirm-PrerequisiteTerms -Id cuda -ReceiptRoot $root -TermsManifest $manifest -Accepted -NonInteractive
    $receipts=@(Get-ChildItem (Join-Path $root 'terms') -Filter '*acceptance*.json')
    if ($receipts.Count -ne 2) { throw 'Each explicit declaration must have its own receipt.' }
    foreach ($file in $receipts) {
        $r=Get-Content $file.FullName -Raw | ConvertFrom-Json
        if ($r.terms_sha256 -ne $hash -or $r.entitlement_independently_verified -ne $false -or -not $r.authority_and_use_rights_declared) { throw 'Receipt must bind exact terms without claiming verified entitlement.' }
    }
    $script:EmbeddedPrerequisiteTerms=Get-Content $manifest -Raw
    $child=Join-Path $root 'child.ps1'
    Set-Content $child "param([string]`$ReceiptRoot) Confirm-PrerequisiteTerms -Id cuda -ReceiptRoot `$ReceiptRoot -TermsManifest 'missing-manifest.json' -Accepted -NonInteractive"
    & $child -ReceiptRoot $root
    $script:EmbeddedPrerequisiteTerms=$null
    $m=Get-Content $manifest -Raw | ConvertFrom-Json; $m.terms[0].sha256='0'*64; $m | ConvertTo-Json -Depth 5 | Set-Content $manifest
    $rejected=$false
    try { Confirm-PrerequisiteTerms -Id cuda -ReceiptRoot $root -TermsManifest $manifest -Accepted } catch { $rejected=$_.Exception.Message -like '*hash mismatch*' }
    if (-not $rejected) { throw 'Changed terms bytes must fail before consent.' }
    Write-Output 'Terms decline, unattended guard, explicit acceptance receipts and hash-tamper checks passed.'
} finally {
    if (-not ([IO.Path]::GetFullPath($root).StartsWith([IO.Path]::GetFullPath($env:TEMP)))) { throw 'Unsafe fixture cleanup' }
    Remove-Item -LiteralPath $root -Recurse -Force
}
