# Explicit recipient authorization. Receipts are declarations, not entitlement verification.
function Confirm-PrerequisiteTerms {
    param(
        [Parameter(Mandatory)][ValidateSet('cuda','cublas','build-tools','vc-runtime')][string]$Id,
        [Parameter(Mandatory)][string]$ReceiptRoot,
        [switch]$Accepted,
        [switch]$NonInteractive,
        [scriptblock]$PromptScript,
        [string]$TermsManifest = (Join-Path $PSScriptRoot 'prerequisite-terms.json')
    )
    $embeddedTerms = Get-Variable -Name EmbeddedPrerequisiteTerms -ValueOnly -ErrorAction SilentlyContinue
    $manifest = if ($embeddedTerms) { $embeddedTerms | ConvertFrom-Json } else { Get-Content -LiteralPath $TermsManifest -Raw | ConvertFrom-Json }
    if ($manifest.schema_version -ne 1) { throw 'Unsupported prerequisite terms manifest.' }
    $terms = @($manifest.terms | Where-Object { $_.id -eq $Id })
    if ($terms.Count -ne 1) { throw "Missing exact prerequisite terms: $Id" }
    $term = $terms[0]
    $bytes = [Convert]::FromBase64String([string]$term.content_base64)
    $digest = [Security.Cryptography.SHA256]::Create()
    try { $hash = ([BitConverter]::ToString($digest.ComputeHash($bytes))).Replace('-','').ToLowerInvariant() } finally { $digest.Dispose() }
    if ($hash -ne $term.sha256) { throw "Prerequisite terms hash mismatch: $Id" }
    Write-Host "Review $($term.title) ($($term.version)): $($term.url)"
    Write-Host 'By accepting, you confirm you have read these terms, can accept them for yourself or your entity, and have the rights required for this use.'
    # Keep the exact presented copy available even when the user declines.
    $directory = Join-Path $ReceiptRoot 'terms'
    New-Item -ItemType Directory -Path $directory -Force | Out-Null
    $copy = Join-Path $directory ($Id + '-' + $hash + '.' + $term.extension)
    [IO.File]::WriteAllBytes($copy, $bytes)
    Write-Host "Exact terms copy: $copy"
    if (-not $Accepted) {
        if ($NonInteractive) { throw "Explicit prerequisite terms acceptance required: $Id. Review the displayed terms and rerun with the corresponding acceptance switch." }
        if (-not $PromptScript) { $PromptScript = { param($message) Read-Host $message } }
        $answer = & $PromptScript "Type ACCEPT to authorize $($term.title), or press Enter to cancel"
        if ($answer -cne 'ACCEPT') { throw 'Recipient declined prerequisite terms.' }
    }
    $receipt = [ordered]@{
        schema_version=1; id=$Id; version=$term.version; terms_url=$term.url; terms_sha256=$hash
        terms_copy=$copy; accepted_utc=[DateTime]::UtcNow.ToString('o')
        method= $(if ($Accepted) { 'explicit_cli_declaration' } else { 'interactive_ACCEPT' })
        authority_and_use_rights_declared=$true; entitlement_independently_verified=$false
    }
    $path = Join-Path $directory ($Id + '-acceptance-' + [guid]::NewGuid().ToString('N') + '.json')
    $receipt | ConvertTo-Json | Set-Content -LiteralPath $path -Encoding UTF8
}
