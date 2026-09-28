param(
    [Parameter(Mandatory)][string]$ManifestPath,
    [string]$CacheRoot = (Join-Path (Join-Path $env:LOCALAPPDATA 'AutoClip') 'cache\artifacts'),
    [string]$StageWheelhouse,
    [switch]$Offline,
    [switch]$InstallNvidiaGpu,
    [scriptblock]$DownloadScript
)

$ErrorActionPreference = 'Stop'
. (Join-Path $PSScriptRoot 'upstream-assets.ps1')
$manifest = Get-Content -LiteralPath $ManifestPath -Raw | ConvertFrom-Json
if ($manifest.schema_version -ne 3 -or $null -eq $manifest.publisher_wheels) {
    throw 'Unsupported publisher-wheel manifest.'
}
$seen = New-Object 'System.Collections.Generic.HashSet[string]' ([StringComparer]::OrdinalIgnoreCase)
$items = @($manifest.publisher_wheels | ForEach-Object {
    [pscustomobject]@{ Wheel = $_; External = $false }
})
if ($InstallNvidiaGpu) {
    $items += @($manifest.external_assets | Where-Object { $_.kind -eq 'python_wheel' } | ForEach-Object {
        [pscustomobject]@{ Wheel = $_; External = $true }
    })
}
foreach ($selected in $items) {
    $item = $selected.Wheel
    $filename = [string]$item.filename
    if (-not $seen.Add($filename) -or
        $filename -notmatch '^[A-Za-z0-9][A-Za-z0-9._+-]*\.whl$' -or
        (-not $selected.External -and [string]$item.delivery_policy -ne 'publisher') -or
        [string]$item.url -notmatch '^https://files\.pythonhosted\.org/' -or
        [string]$item.sha256 -notmatch '^[0-9a-fA-F]{64}$' -or
        [long]$item.bytes -le 0 -or
        (-not $selected.External -and (-not $item.package -or -not $item.version -or -not $item.publisher_identity))) {
        throw "Invalid publisher wheel identity: $filename"
    }
    $hash = ([string]$item.sha256).ToLowerInvariant()
    $cached = Join-Path (Join-Path (Join-Path $CacheRoot 'sha256') $hash) $filename
    if ($Offline) {
        if (-not (Test-Path -LiteralPath $cached -PathType Leaf) -or
            (Get-Item -LiteralPath $cached).Length -ne [long]$item.bytes -or
            (Get-FileHash -LiteralPath $cached -Algorithm SHA256).Hash.ToLowerInvariant() -ne $hash) {
            throw "Offline cache is missing a verified publisher wheel: $filename"
        }
    } else {
        $cached = Get-ContentAddressedAsset -Uri ([string]$item.url) -Sha256 $hash -Size ([long]$item.bytes) -Filename $filename -CacheRoot $CacheRoot -DownloadScript $DownloadScript
    }
    if ($StageWheelhouse) {
        New-Item -ItemType Directory -Path $StageWheelhouse -Force | Out-Null
        $staged = Join-Path $StageWheelhouse $filename
        if ((Test-Path -LiteralPath $staged -PathType Leaf) -and
            (Get-Item -LiteralPath $staged).Length -eq [long]$item.bytes -and
            (Get-FileHash -LiteralPath $staged -Algorithm SHA256).Hash.ToLowerInvariant() -eq $hash) {
            continue
        }
        Copy-Item -LiteralPath $cached -Destination $staged -Force
        if ((Get-FileHash -LiteralPath $staged -Algorithm SHA256).Hash.ToLowerInvariant() -ne $hash) {
            throw "Staged publisher wheel hash mismatch: $filename"
        }
    }
}
