function Get-PinnedUpstreamAsset {
    param(
        [Parameter(Mandatory)][string]$Uri,
        [Parameter(Mandatory)][string]$Sha256,
        [Parameter(Mandatory)][long]$Size,
        [Parameter(Mandatory)][string]$Destination,
        [scriptblock]$DownloadScript
    )

    if ($Uri -notmatch '^https://[^/?#]+/[^?#]+$' -or $Sha256 -notmatch '^[0-9a-fA-F]{64}$' -or $Size -le 0) {
        throw 'Invalid pinned upstream asset identity.'
    }
    if (Test-Path -LiteralPath $Destination) {
        $existing = Get-Item -LiteralPath $Destination
        $existingHash = (Get-FileHash -LiteralPath $Destination -Algorithm SHA256).Hash.ToLowerInvariant()
        if ($existing.Length -ne $Size -or $existingHash -ne $Sha256.ToLowerInvariant()) {
            throw "Pinned upstream asset hash or size mismatch: $Destination"
        }
        return $Destination
    }

    $directory = Split-Path -Parent $Destination
    New-Item -ItemType Directory -Path $directory -Force | Out-Null
    $temporary = Join-Path $directory ('.autoclip-download-' + [guid]::NewGuid().ToString('N'))
    if (-not $DownloadScript) {
        $DownloadScript = {
            param($url, $path)
            $curl = Get-Command curl.exe -ErrorAction SilentlyContinue
            if ($curl) {
                & $curl.Source --fail --location --retry 3 --silent --show-error --proto '=https' --proto-redir '=https' --output $path $url
                if ($LASTEXITCODE -ne 0) { throw "Publisher download failed: $url (curl exit $LASTEXITCODE)" }
            } else {
                Invoke-WebRequest -UseBasicParsing -Uri $url -OutFile $path
            }
        }
    }
    try {
        & $DownloadScript $Uri $temporary | Out-Null
        $downloaded = Get-Item -LiteralPath $temporary
        $actualHash = (Get-FileHash -LiteralPath $temporary -Algorithm SHA256).Hash.ToLowerInvariant()
        if ($downloaded.Length -ne $Size -or $actualHash -ne $Sha256.ToLowerInvariant()) {
            throw "Pinned upstream asset hash or size mismatch: $Uri"
        }
        Move-Item -LiteralPath $temporary -Destination $Destination
        return $Destination
    } finally {
        if (Test-Path -LiteralPath $temporary) { Remove-Item -LiteralPath $temporary -Force }
    }
}

function Get-ContentAddressedAsset {
    param(
        [Parameter(Mandatory)][string]$Uri,
        [Parameter(Mandatory)][string]$Sha256,
        [Parameter(Mandatory)][long]$Size,
        [Parameter(Mandatory)][string]$Filename,
        [Parameter(Mandatory)][string]$CacheRoot,
        [scriptblock]$DownloadScript
    )
    if ($Sha256 -notmatch '^[0-9a-fA-F]{64}$' -or
        $Filename -notmatch '^[A-Za-z0-9][A-Za-z0-9._+-]*$') {
        throw 'Invalid content-addressed asset identity.'
    }
    $destination = Join-Path (Join-Path (Join-Path $CacheRoot 'sha256') $Sha256.ToLowerInvariant()) $Filename
    if (Test-Path -LiteralPath $destination -PathType Leaf) {
        $actualSize = (Get-Item -LiteralPath $destination).Length
        $actualHash = (Get-FileHash -LiteralPath $destination -Algorithm SHA256).Hash.ToLowerInvariant()
        if ($actualSize -ne $Size -or $actualHash -ne $Sha256.ToLowerInvariant()) {
            Remove-Item -LiteralPath $destination -Force
        }
    }
    return Get-PinnedUpstreamAsset -Uri $Uri -Sha256 $Sha256 -Size $Size -Destination $destination -DownloadScript $DownloadScript
}

function Install-PinnedZipMember {
    param(
        [Parameter(Mandatory)][string]$Archive,
        [Parameter(Mandatory)][string]$Member,
        [Parameter(Mandatory)][string]$Sha256,
        [Parameter(Mandatory)][string]$Destination
    )

    if ($Member -notmatch '^[A-Za-z0-9][A-Za-z0-9._/-]*$' -or
        $Member -match '(^|/)\.\.(/|$)' -or
        $Sha256 -notmatch '^[0-9a-fA-F]{64}$') {
        throw 'Invalid pinned ZIP member identity.'
    }
    if (Test-Path -LiteralPath $Destination) {
        throw "Pinned ZIP member destination already exists: $Destination"
    }
    Add-Type -AssemblyName System.IO.Compression.FileSystem
    $directory = Split-Path -Parent $Destination
    New-Item -ItemType Directory -Path $directory -Force | Out-Null
    $temporary = Join-Path $directory ('.autoclip-member-' + [guid]::NewGuid().ToString('N'))
    $zip = [IO.Compression.ZipFile]::OpenRead($Archive)
    try {
        $entry = $zip.GetEntry($Member)
        if (-not $entry) { throw "Pinned ZIP member is missing: $Member" }
        $inputStream = $entry.Open()
        try {
            $outputStream = [IO.File]::Create($temporary)
            try { $inputStream.CopyTo($outputStream) }
            finally { $outputStream.Dispose() }
        } finally { $inputStream.Dispose() }
        $actual = (Get-FileHash -LiteralPath $temporary -Algorithm SHA256).Hash.ToLowerInvariant()
        if ($actual -ne $Sha256.ToLowerInvariant()) {
            throw "Pinned ZIP member SHA-256 mismatch: $Member"
        }
        Move-Item -LiteralPath $temporary -Destination $Destination
    } finally {
        $zip.Dispose()
        if (Test-Path -LiteralPath $temporary) { Remove-Item -LiteralPath $temporary -Force }
    }
}
