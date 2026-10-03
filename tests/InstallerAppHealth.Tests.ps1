$ErrorActionPreference='Stop'
$repo=Split-Path -Parent $PSScriptRoot
$helper=Join-Path $repo 'installer/verify-installed-app.ps1'
if (!(Test-Path $helper)) {throw 'RED: installed health/home gate absent.'}
$tokens=$null;$errors=$null
$ast=[Management.Automation.Language.Parser]::ParseFile($helper,[ref]$tokens,[ref]$errors)
if ($errors.Count) {throw 'Health helper parse failed.'}
foreach ($node in $ast.FindAll({param($n) $n -is [Management.Automation.Language.FunctionDefinitionAst]},$true)) {. ([scriptblock]::Create($node.Extent.Text))}
$codeAssignment=$ast.Find({param($n) $n -is [Management.Automation.Language.AssignmentStatementAst] -and $n.Left.Extent.Text -ceq '$script:AppHealthProbe'},$true)
Invoke-Expression $codeAssignment.Extent.Text
$fixedCode=$script:AppHealthProbe
$python=(Get-Command python).Source
$version=@(& $python -I -B -c 'import sys; print(sys.version_info[:3]); print(sys.prefix)')
if ($LASTEXITCODE -ne 0 -or $version[0] -cne '(3, 11, 9)') {throw 'Host fixture requires actual normal Python3.11.9.'}
$fixture=New-AppHealthStage
$modules=Join-Path $fixture 'modules';$null=[IO.Directory]::CreateDirectory((Join-Path $modules 'autoclip'))
[IO.File]::WriteAllText((Join-Path $modules 'autoclip/__init__.py'),'')
$libraries='D:/Projects/myAutoclip/.venv/Lib/site-packages'
$bootstrap="import sys; sys.path.insert(0, '$($modules.Replace('\','/'))'); sys.path.append('$libraries')`n"
$script:AppHealthProbe=$bootstrap+$fixedCode
$fixtureCode=@'
import contextlib, os
from pathlib import Path
from fastapi import FastAPI
from fastapi.responses import HTMLResponse, JSONResponse
@contextlib.asynccontextmanager
async def lifespan(app):
 home=Path(os.environ['AUTOCLIP_HOME']); home.mkdir(parents=True,exist_ok=True)
 (home/'lifespan.txt').write_text('ordinary isolated startup',encoding='utf-8')
 assert os.environ['AUTOCLIP_STORAGE_HOME']==os.environ['AUTOCLIP_HOME']
 assert 'PYTHONPATH' not in os.environ and 'PYTHONHOME' not in os.environ
 yield
 (home/'shutdown.txt').write_text('lifespan closed',encoding='utf-8')
def create_app():
 app=FastAPI(lifespan=lifespan)
 @app.get('/api/health')
 async def health(): return JSONResponse({'status':'ok'},status_code=HEALTH_STATUS)
 if HOME_STATUS != 0:
  @app.get('/')
  async def home(): return HTMLResponse('<html>installed frontend</html>',status_code=HOME_STATUS)
 return app
'@
$keys=@('AUTOCLIP_HOME','AUTOCLIP_STORAGE_HOME','PYTHONPATH','PYTHONHOME','PYTHONNOUSERSITE')
$saved=@{};foreach ($key in $keys) {$saved[$key]=[Environment]::GetEnvironmentVariable($key,'Process')}
$callerValues=@{}
foreach ($key in $keys) {$callerValues[$key]='caller-'+$key}
foreach ($key in @('AUTOCLIP_HOME','AUTOCLIP_STORAGE_HOME')) {
 $callerValues[$key]=Join-Path $fixture ('preserved-'+$key)
 $null=[IO.Directory]::CreateDirectory($callerValues[$key])
 [IO.File]::WriteAllText((Join-Path $callerValues[$key] 'sentinel.txt'),'recipient data preserved')
}
try {
 foreach ($key in $keys) {[Environment]::SetEnvironmentVariable($key,$callerValues[$key],'Process')}
 foreach ($case in @(@{health=200;home=200;pass=$true},@{health=503;home=200;pass=$false},@{health=200;home=503;pass=$false},@{health=200;home=0;pass=$false})) {
  [IO.File]::WriteAllText((Join-Path $modules 'autoclip/app.py'),($fixtureCode.Replace('HEALTH_STATUS',[string]$case.health).Replace('HOME_STATUS',[string]$case.home)),[Text.UTF8Encoding]::new($false))
  $stage=New-AppHealthStage;$failed=$false
  try {$result=Invoke-AppHealthProcess $python $version[1] $stage} catch {$failed=$true}
  if ($failed -eq $case.pass) {throw 'Real native ASGI health/home result disagrees with endpoint behavior.'}
  if ($case.pass -and ($result.receipt.health_status -ne 200 -or $result.receipt.home_status -ne 200 -or !(Test-Path (Join-Path $stage 'home/shutdown.txt')))) {throw 'Actual TestClient lifespan/health/home proof missing.'}
  foreach ($key in $keys) {if ([Environment]::GetEnvironmentVariable($key,'Process') -cne $callerValues[$key]) {throw 'Caller environment was not restored.'}}
  foreach ($key in @('AUTOCLIP_HOME','AUTOCLIP_STORAGE_HOME')) {if (@(Get-ChildItem $callerValues[$key] -Force).Count -ne 1 -or [IO.File]::ReadAllText((Join-Path $callerValues[$key] 'sentinel.txt')) -cne 'recipient data preserved') {throw 'Existing caller home/storage data changed.'}}
 }
 $manifest=Join-Path $fixture 'release-manifest.json';[IO.File]::WriteAllText($manifest,'{"schema_version":3,"files":[]}')
 $hash=(Get-FileHash $manifest).Hash.ToLowerInvariant();$pin=Open-AppHealthManifest $manifest $hash
 try {$failed=$false;try {[IO.File]::WriteAllText($manifest,'changed')} catch {$failed=$true};if (!$failed) {throw 'Manifest write allowed while validation lock held.'}} finally {$pin.stream.Dispose()}
 $failed=$false;try {$null=Open-AppHealthManifest $manifest ('0'*64)} catch {$failed=$true};if (!$failed) {throw 'Manifest hash tamper accepted.'}
 $resultFile=Join-Path $fixture 'owned-result.json';Write-AppHealthResult $resultFile @{status='first'}
 $originalResult=[IO.File]::ReadAllText($resultFile);$failed=$false;try {Write-AppHealthResult $resultFile @{status='changed'}} catch {$failed=$true}
 if (!$failed -or [IO.File]::ReadAllText($resultFile) -cne $originalResult) {throw 'Existing result was overwritten.'}
 [IO.File]::WriteAllText($manifest,'{"schema_version":4,"files":[]}');$futureHash=(Get-FileHash $manifest).Hash.ToLowerInvariant()
 $failed=$false;try {$null=Open-AppHealthManifest $manifest $futureHash} catch {$failed=$true};if (!$failed) {throw 'Future manifest schema accepted.'}
 foreach ($unsafe in @('relative/root','\\server\share\root',($fixture+'\..\escape'))) {$failed=$false;try {$null=Get-AppHealthPath $unsafe} catch {$failed=$true};if (!$failed) {throw 'Unsafe health path accepted.'}}
 foreach ($cfg in @("version = 3.11.9`ninclude-system-site-packages = false`n","implementation = CPython`nversion_info = 3.11.9`ninclude-system-site-packages = false`n")) {Assert-AppHealthConfiguration $cfg}
 foreach ($cfg in @("version = 3.11.9`nversion = 3.11.9`ninclude-system-site-packages = false`n","version = 3.11.9`nversion_info = 3.12.0`ninclude-system-site-packages = false`n","version = 3.11.9`ninclude-system-site-packages = true`n")) {$failed=$false;try {Assert-AppHealthConfiguration $cfg} catch {$failed=$true};if (!$failed) {throw 'Ambiguous/incompatible configuration accepted.'}}
 'GREEN: real native TestClient lifespan health/home success/failures, environment restore, isolated home, manifest lock/tamper and cfg identity.'
} finally {foreach ($key in $keys) {[Environment]::SetEnvironmentVariable($key,$saved[$key],'Process')};$script:AppHealthProbe=$fixedCode}
