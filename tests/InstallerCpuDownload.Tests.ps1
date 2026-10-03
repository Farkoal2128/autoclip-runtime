$ErrorActionPreference = 'Stop'
. (Join-Path $PSScriptRoot '../installer/download-artifact.ps1')
$fixture=Join-Path $env:TEMP ('cpu-download-'+[guid]::NewGuid().ToString('N'))
[IO.Directory]::CreateDirectory($fixture)|Out-Null
$manifestPath=Join-Path $fixture 'manifest.json'
$destination=Join-Path $fixture 'cpu.zip'
[IO.File]::WriteAllText($destination,'first-party fixture')
$pin=[pscustomobject]@{identity='cpu-test';runtime_id='cpu-test';profile='cpu';filename='cpu.zip';url='https://github.com/example/runtime/releases/download/test/cpu.zip';redirect_hosts=@('github.com','release-assets.githubusercontent.com');bytes=(Get-Item $destination).Length;sha256=(Get-FileHash $destination).Hash;delivery_classification='DIRECT_RECIPIENT_DOWNLOAD'}
$manifest=[pscustomobject]@{schema_version=1;cpu_native_artifact=$pin;build_prerequisites=@();external_assets=@();native_build_assets=@()}
function Save-Manifest { $manifest|ConvertTo-Json -Depth 8|Set-Content -LiteralPath $manifestPath -Encoding UTF8 }
function Get-InstallerDownloadResponse { throw 'Verified-cache selection requested network.' }
Save-Manifest
foreach($id in @('cpu-test','cpu.zip')){
    $resolved=Resolve-InstallerArtifact -ManifestPath $manifestPath -Identity $id
    if($resolved.sha256 -ne $pin.sha256){throw 'CPU native selection changed pins.'}
    $result=Get-InstallerArtifact -ManifestPath $manifestPath -Identity $id -DestinationPath $destination
    if($result -ne $destination){throw 'Verified CPU cache was not reused.'}
}
foreach($case in @('blocked','ambiguous','corrupt')){
    $pin.delivery_classification='DIRECT_RECIPIENT_DOWNLOAD';$manifest.external_assets=@()
    if($case -eq 'blocked'){$pin.delivery_classification='BLOCKED'}
    if($case -eq 'ambiguous'){$manifest.external_assets=@($pin)}
    if($case -eq 'corrupt'){[IO.File]::WriteAllText($destination,'corrupt')}
    Save-Manifest
    $rejected=$false
    try { Get-InstallerArtifact -ManifestPath $manifestPath -Identity 'cpu-test' -DestinationPath $destination|Out-Null }catch{$rejected=$true}
    if(!$rejected){throw "CPU native boundary accepted $case"}
}
'GREEN actual CPU downloader resolution, exact pins, verified cache and blocked/ambiguous/corrupt rejection.'
