function Assert-NativeWheelHash([string]$Path, $Wheel) {
    if (-not (Test-Path -LiteralPath $Path -PathType Leaf) -or
        (Get-Item -LiteralPath $Path).Length -ne [long]$Wheel.bytes -or
        (Get-FileHash -LiteralPath $Path -Algorithm SHA256).Hash.ToLowerInvariant() -ne [string]$Wheel.sha256) {
        throw "Cached native wheel differs from its build receipt: $($Wheel.filename)"
    }
}

function Save-NativeWheelCache([string]$BuildRoot, [string]$Wheelhouse, [array]$Wheels) {
    $cache = Join-Path $BuildRoot 'native-wheels'
    [IO.Directory]::CreateDirectory($cache) | Out-Null
    foreach ($wheel in $Wheels) {
        if ([string]$wheel.filename -notmatch '^(av-18\.1\.0|ctranslate2-4\.8\.2)-[A-Za-z0-9._-]+\.whl$') {
            throw 'Invalid native wheel filename in build receipt.'
        }
        $source = Join-Path $Wheelhouse ([string]$wheel.filename)
        Assert-NativeWheelHash $source $wheel
        $destination = Join-Path $cache ([string]$wheel.filename)
        Copy-Item -LiteralPath $source -Destination $destination -Force
        Assert-NativeWheelHash $destination $wheel
    }
}

function Restore-NativeWheelCache([string]$BuildRoot, [string]$Wheelhouse, [array]$Wheels) {
    $cache = Join-Path $BuildRoot 'native-wheels'
    [IO.Directory]::CreateDirectory($Wheelhouse) | Out-Null
    foreach ($wheel in $Wheels) {
        if ([string]$wheel.filename -notmatch '^(av-18\.1\.0|ctranslate2-4\.8\.2)-[A-Za-z0-9._-]+\.whl$') {
            throw 'Invalid native wheel filename in build receipt.'
        }
        $source = Join-Path $cache ([string]$wheel.filename)
        Assert-NativeWheelHash $source $wheel
        $destination = Join-Path $Wheelhouse ([string]$wheel.filename)
        Copy-Item -LiteralPath $source -Destination $destination -Force
        Assert-NativeWheelHash $destination $wheel
    }
}
