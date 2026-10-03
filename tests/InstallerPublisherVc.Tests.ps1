$ErrorActionPreference = 'Stop'
$repo = Split-Path -Parent $PSScriptRoot
$tokens=$null; $errors=$null
$ast=[Management.Automation.Language.Parser]::ParseFile((Join-Path $repo 'install.ps1'),[ref]$tokens,[ref]$errors)
if($errors){throw 'Bootstrap parse failed.'}
$node=$ast.Find({param($n)$n -is [Management.Automation.Language.FunctionDefinitionAst] -and $n.Name -eq 'Invoke-AutoClipPublisherVc'},$false)
if(-not $node){throw 'Missing protected publisher CPU VC preparation behavior.'}
. ([scriptblock]::Create($node.Extent.Text.Replace('$PSScriptRoot','$repo')))
$fixture=Join-Path $env:TEMP ('publisher-vc-'+[guid]::NewGuid().ToString('N'))
[IO.Directory]::CreateDirectory($fixture)|Out-Null
$fixtureHelperPath=Join-Path $fixture 'vc-fixture.ps1'
[IO.File]::WriteAllText($fixtureHelperPath,@'
param($ManifestPath,$ManifestSha256,$StateDirectory,[switch]$CheckOnly,$InstallerPath,[switch]$AcceptMicrosoftTerms)
$ErrorActionPreference='Stop'
if($ManifestPath -ne 'C:\exact-manifest.json' -or $ManifestSha256 -ne ('a'*64) -or $StateDirectory -ne 'C:\owned-vc-state'){throw 'Bound arguments changed.'}
if(!$CheckOnly -and (!$AcceptMicrosoftTerms -or $InstallerPath -ne 'C:\pinned-VC.exe')){throw 'Install declaration or exact vendor path missing.'}
[IO.File]::AppendAllText($env:AUTOCLIP_VC_FIXTURE_TRACE,([string]$CheckOnly)+'|'+([string]$AcceptMicrosoftTerms)+[Environment]::NewLine)
$case=$env:AUTOCLIP_VC_FIXTURE_CASE
if($case -eq 'ready'){$code=0;$status='ready'}elseif($case -eq 'missing'){$code=2;$status='missing'}elseif($case -eq 'reboot'){$code=3010;$status='pending_reboot'}elseif($case -eq 'busy'){$code=1618;$status='busy'}else{$code=0;$status='pending_reboot'}
@{schema_version=1;status=$status;exit_code=$code;vendor_exit_code=$null;receipt_path=$null;message='first-party fixture'}|ConvertTo-Json -Compress
exit $code
'@)
$expected=(Get-FileHash -LiteralPath $fixtureHelperPath).Hash
function Invoke-AutoClipPinnedHelper($Path,$Pin,$Action){if($Pin -ne $expected){throw 'Helper substituted.'};& $Action $fixtureHelperPath}
$SecureAcquisition=[pscustomobject]@{ManifestPath='C:\exact-manifest.json';ManifestSha256=('a'*64)}
$VcRuntimeHelperSha256=$expected
$ExternalCache='C:\parent'
$AcceptMicrosoftTerms=$true
$oldCase=$env:AUTOCLIP_VC_FIXTURE_CASE; $oldTrace=$env:AUTOCLIP_VC_FIXTURE_TRACE
try{
 $env:AUTOCLIP_VC_FIXTURE_TRACE=Join-Path $fixture 'calls.txt'
 foreach($case in @('ready','missing','reboot','busy','contradictory')){
  $env:AUTOCLIP_VC_FIXTURE_CASE=$case
  if($case -in @('ready','missing')){
   $r=Invoke-AutoClipPublisherVc -StateDirectory 'C:\owned-vc-state' -CheckOnly
   if($r.status -ne $case){throw 'Valid CheckOnly result changed.'}
  }else{
   $rejected=$false;try{Invoke-AutoClipPublisherVc -StateDirectory 'C:\owned-vc-state' -CheckOnly|Out-Null}catch{$rejected=$true}
   if(!$rejected){throw "Unready VC result accepted: $case"}
  }
 }
 $env:AUTOCLIP_VC_FIXTURE_CASE='ready'
 $r=Invoke-AutoClipPublisherVc -StateDirectory 'C:\owned-vc-state' -InstallerPath 'C:\pinned-VC.exe'
 if($r.status -ne 'ready'){throw 'Valid vendor-terminal capability result rejected.'}
 $VcRuntimeHelperSha256='bad'
 $rejected=$false;try{Invoke-AutoClipPublisherVc -StateDirectory 'C:\owned-vc-state' -CheckOnly|Out-Null}catch{$rejected=$true}
 if(!$rejected){throw 'Missing or substituted helper pin accepted.'}
 $lines=[IO.File]::ReadAllLines($env:AUTOCLIP_VC_FIXTURE_TRACE)
 if($lines.Count -ne 6 -or $lines[5] -ne 'False|True'){throw 'Unexpected vendor/CheckOnly call composition.'}
 'GREEN protected VC handoff, paired pins, capability/reboot/busy rejection; inert first-party child only.'
}finally{$env:AUTOCLIP_VC_FIXTURE_CASE=$oldCase;$env:AUTOCLIP_VC_FIXTURE_TRACE=$oldTrace}
