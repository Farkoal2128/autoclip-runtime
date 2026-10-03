param([string]$HelperPath)
$ErrorActionPreference = 'Stop'
$helper = if ($HelperPath) { $HelperPath } else { Join-Path $PSScriptRoot '../installer/install-vc-runtime.ps1' }
if (-not (Test-Path -LiteralPath $helper)) { throw 'RED: manifest-bound VC preparation helper missing; durable pending state cannot protect a fresh invocation.' }
$tokens = $null; $errors = $null
$ast = [Management.Automation.Language.Parser]::ParseFile($helper, [ref]$tokens, [ref]$errors)
if ($errors.Count) { throw 'VC helper parse failed.' }
foreach ($node in $ast.FindAll({param($n) $n -is [Management.Automation.Language.FunctionDefinitionAst]}, $false)) { Invoke-Expression $node.Extent.Text }
if (-not (Get-Command Invoke-AutoClipVcRuntime -ErrorAction SilentlyContinue)) { throw 'RED: VC preparation decision function missing.' }
# Exercise the real launch boundary without a vendor or UAC: a guaranteed
# nonexistent executable must retain its native Win32 error, not localized text.
$missingVendor=Join-Path $env:TEMP ('autoclip-vc-missing-'+[guid]::NewGuid().ToString('N')+'.exe')
if(Test-Path -LiteralPath $missingVendor){throw 'Missing launcher fixture unexpectedly exists.'}
$launchFailure=$null
try{Start-AutoClipVcVendor $missingVendor @('/install','/norestart')|Out-Null}
catch [ComponentModel.Win32Exception]{$launchFailure=$_.Exception}
catch{$launchFailure=$_.Exception}
if($launchFailure -isnot [ComponentModel.Win32Exception] -or $launchFailure.NativeErrorCode-ne2){
    throw ('Real launcher discarded native Win32 launch error: '+$launchFailure.GetType().FullName)
}
$sid = [Security.Principal.WindowsIdentity]::GetCurrent().User.Value
$sandbox = Join-Path $env:TEMP ('autoclip-vc-inert-' + [guid]::NewGuid().ToString('N'))
# The host TEMP has foreign write ACEs. Tests provision their own protected parent;
# production still rejects that unsafe authority rather than accepting the host ACL.
$acl=New-Object Security.AccessControl.DirectorySecurity
$acl.SetAccessRuleProtection($true,$false)
$acl.SetOwner([Security.Principal.SecurityIdentifier]::new($sid))
foreach ($id in @($sid,'S-1-5-18','S-1-5-32-544')) {
    $acl.AddAccessRule([Security.AccessControl.FileSystemAccessRule]::new([Security.Principal.SecurityIdentifier]::new($id),'FullControl','ContainerInherit,ObjectInherit','None','Allow'))
}
[IO.Directory]::CreateDirectory($sandbox,$acl) | Out-Null
$root = Join-Path $sandbox 'files'
Initialize-AutoClipVcStateDirectory $root $sid
function Assert-Vc { param([bool]$Condition, [string]$Message) if (-not $Condition) { throw $Message } }
$source = Get-Content -LiteralPath $helper -Raw
$functionEnd = ($ast.FindAll({param($n) $n -is [Management.Automation.Language.FunctionDefinitionAst]}, $false) | ForEach-Object {$_.Extent.EndOffset} | Measure-Object -Maximum).Maximum
$fixture = Join-Path $root 'fixture-helper.ps1'
$configPath = Join-Path $root 'native-boundaries.json'
$manifestPath = Join-Path $root 'manifest.json'
$vendorPath = Join-Path $root 'inert-vendor.txt'
$worker = Join-Path $root 'ordinary-child.ps1'
[IO.File]::WriteAllText($vendorPath, 'first-party inert input')
[IO.File]::WriteAllText($worker, 'param([int]$Code, [int]$Delay) Start-Sleep -Milliseconds $Delay; exit $Code')
$pin = [ordered]@{kind='microsoft_vc_redist_x64';version='14.44.35211.0';architecture='x64';delivery_classification='DIRECT_RECIPIENT_DOWNLOAD';signature_publisher='Microsoft Corporation';bytes=(Get-Item $vendorPath).Length;sha256=(Get-FileHash $vendorPath).Hash.ToLowerInvariant();installer_arguments=@('/install','/norestart');success_exit_codes=@(0,3010)}
Write-AutoClipVcRecord $manifestPath @{schema_version=1;external_assets=@($pin)}
$manifestHash = (Get-FileHash $manifestPath).Hash.ToLowerInvariant()
$boundaries = @'
function Get-AutoClipVcContext {
    $script:fixture = Get-Content -LiteralPath (Join-Path $PSScriptRoot 'native-boundaries.json') -Raw | ConvertFrom-Json
    [pscustomobject]@{Sid=[Security.Principal.WindowsIdentity]::GetCurrent().User.Value; Boot=$script:fixture.boot}
}
function Test-AutoClipVcCapability {
    param([version]$MinimumVersion)
    [IO.File]::AppendAllText((Join-Path $PSScriptRoot 'capability-calls.txt'), 'probe' + [Environment]::NewLine)
    [bool]$script:fixture.capability
}
function Get-AuthenticodeSignature {
    param([string]$LiteralPath)
    [pscustomobject]@{Status=$script:fixture.signature; SignerCertificate=[pscustomobject]@{Subject=('CN='+$script:fixture.publisher+', O='+$script:fixture.publisher)}}
}
function Get-AutoClipVcVersion { param([string]$Path) [version]$script:fixture.version }
function Start-AutoClipVcVendor {
    param([string]$Path, [string[]]$Arguments)
    if (($Arguments -join '|') -cne '/install|/norestart') { throw 'Vendor agreement arguments changed.' }
    $record = Get-Content -LiteralPath (Join-Path $StateDirectory 'vc-state.json') -Raw | ConvertFrom-Json
    if ($record.status -ne 'in_progress') { throw 'Prelaunch state was not durable.' }
    $blocked = $false
    try { $write = [IO.File]::Open($Path, 'Open', 'Write', 'ReadWrite'); $write.Dispose() } catch { $blocked = $true }
    if (-not $blocked) { throw 'Vendor input was not held against writes.' }
    [IO.File]::AppendAllText((Join-Path $PSScriptRoot 'launches.txt'), 'launch' + [Environment]::NewLine)
    if ($script:fixture.uac) { throw [ComponentModel.Win32Exception]::new(1223) }
    if ($script:fixture.launchFailure) { throw [ComponentModel.Win32Exception]::new(2) }
    if ($script:fixture.noHandle) { return $null }
    if ($script:fixture.publicationFailure) {
        # An actual first-party filesystem collision prevents receipt publication, without mocking record handling.
        [IO.Directory]::CreateDirectory((Join-Path $StateDirectory ($record.attempt_id + '.json'))) | Out-Null
    }
    if ($script:fixture.postCapability) { $script:fixture.capability=$true }
    $p=Start-Process -FilePath (Join-Path $env:WINDIR 'System32/WindowsPowerShell/v1.0/powershell.exe') -ArgumentList @('-NoProfile','-NonInteractive','-File',('"' + (Join-Path $PSScriptRoot 'ordinary-child.ps1') + '"'),'-Code',$script:fixture.code,'-Delay',$script:fixture.delay) -PassThru -WindowStyle Hidden
    if ($script:fixture.observationFailure -or $script:fixture.waitFailure) {
        $wrapper=[pscustomobject]@{Child=$p}
        if ($script:fixture.waitFailure) {
            $wrapper | Add-Member ScriptProperty Handle { $this.Child.Handle }
            $wrapper | Add-Member ScriptMethod WaitForExit { throw 'Inert process wait failure.' }
        } else {
            $wrapper | Add-Member ScriptProperty Handle { throw 'Inert native handle observation failure.' }
            $wrapper | Add-Member ScriptMethod WaitForExit { $this.Child.WaitForExit() }
        }
        $wrapper | Add-Member ScriptMethod Dispose { $this.Child.Dispose() }
        return $wrapper
    }
    $p
}
'@
[IO.File]::WriteAllText($fixture, $source.Substring(0, $functionEnd) + "`r`n" + $boundaries + "`r`n" + $source.Substring($functionEnd))
function Set-VcBoundary {
    param([int]$Code=3010, [bool]$Capability=$false, [string]$Boot='boot-A', [bool]$Uac=$false, [string]$Signature='Valid', [string]$Publisher='Microsoft Corporation', [string]$Version='14.44.35211.0', [int]$Delay=0, [bool]$NoHandle=$false, [bool]$PostCapability=$false, [bool]$PublicationFailure=$false, [bool]$ObservationFailure=$false, [bool]$WaitFailure=$false, [bool]$LaunchFailure=$false)
    Write-AutoClipVcRecord $configPath @{code=$Code;capability=$Capability;boot=$Boot;uac=$Uac;signature=$Signature;publisher=$Publisher;version=$Version;delay=$Delay;noHandle=$NoHandle;postCapability=$PostCapability;publicationFailure=$PublicationFailure;observationFailure=$ObservationFailure;waitFailure=$WaitFailure;launchFailure=$LaunchFailure}
}
function Invoke-VcFixture {
    param([string]$State, [switch]$Check, [switch]$Consent, [string]$Hash=$manifestHash)
    $arguments = @('-NoProfile','-NonInteractive','-File',$fixture,'-ManifestPath',$manifestPath,'-ManifestSha256',$Hash,'-StateDirectory',$State)
    if ($Check) { $arguments += '-CheckOnly' } else { $arguments += @('-InstallerPath',$vendorPath); if ($Consent) { $arguments += '-AcceptMicrosoftTerms' } }
    $output = & powershell.exe @arguments | Out-String
    $nativeCode = $LASTEXITCODE
    $result = $output | ConvertFrom-Json
    Assert-Vc ($nativeCode -eq $result.exit_code) 'JSON and native exit code differ.'
    $result
}
function Get-VcLaunchCount { if (Test-Path (Join-Path $root 'launches.txt')) { @(Get-Content (Join-Path $root 'launches.txt')).Count } else { 0 } }
try {
    Set-VcBoundary
    $state = Join-Path $root 'pending'
    $r = Invoke-VcFixture $state -Consent
    Assert-Vc ($r.status -eq 'pending_reboot' -and $r.exit_code -eq 3010 -and $r.vendor_exit_code -eq 3010) ('Pending vendor result was not retained: ' + ($r | ConvertTo-Json -Compress))
    $before = (Get-FileHash (Join-Path $state 'vc-state.json')).Hash
    $probeCount = @(Get-Content (Join-Path $root 'capability-calls.txt')).Count
    Set-VcBoundary -Capability $true
    $r = Invoke-VcFixture $state -Check
    Assert-Vc ($r.exit_code -eq 3010 -and (Get-VcLaunchCount) -eq 1) 'Fresh same-boot invocation bypassed pending state.'
    Assert-Vc (@(Get-Content (Join-Path $root 'capability-calls.txt')).Count -eq $probeCount) 'Same-boot pending attempted capability reuse.'
    Assert-Vc ((Get-FileHash (Join-Path $state 'vc-state.json')).Hash -eq $before) 'CheckOnly modified pending state.'
    Set-VcBoundary -Capability $false -Boot 'boot-B'
    Assert-Vc ((Invoke-VcFixture $state -Check).status -eq 'unresolved') 'Post-reboot missing capability retired pending state.'
    Set-VcBoundary -Capability $true -Boot 'boot-B'
    Assert-Vc ((Invoke-VcFixture $state -Check).exit_code -eq 0) 'Fresh post-reboot capability failed.'
    Assert-Vc ((Get-FileHash (Join-Path $state 'vc-state.json')).Hash -eq $before) 'CheckOnly retired owned pending state.'
    Assert-Vc ((Invoke-VcFixture $state).exit_code -eq 0 -and -not (Test-Path (Join-Path $state 'vc-state.json'))) 'Install mode did not retire verified post-reboot state.'
    Set-VcBoundary
    $r = Invoke-VcFixture (Join-Path $root 'decline')
    Assert-Vc ($r.status -eq 'declined' -and (Get-VcLaunchCount) -eq 1) 'Consent decline launched vendor.'
    $missing = Join-Path $root 'check-missing'
    Assert-Vc ((Invoke-VcFixture $missing -Check).exit_code -eq 2 -and -not (Test-Path $missing)) 'Missing CheckOnly mutated storage.'
    Assert-Vc ((Invoke-VcFixture (Join-Path $root 'bad-manifest') -Consent -Hash ('0'*64)).exit_code -eq 21) 'Bad setup manifest pin accepted.'
    foreach ($case in @('NotSigned','publisher','version','bytes','hash','arguments')) {
        Set-VcBoundary
        if ($case -eq 'NotSigned') { Set-VcBoundary -Signature 'NotSigned' }
        if ($case -eq 'publisher') { Set-VcBoundary -Publisher 'Foreign Publisher' }
        if ($case -eq 'version') { Set-VcBoundary -Version '14.44.35210.0' }
        if ($case -eq 'bytes') { $pin.bytes++ }
        if ($case -eq 'hash') { $pin.sha256='0'*64 }
        if ($case -eq 'arguments') { $pin.installer_arguments=@('/quiet','/norestart') }
        Write-AutoClipVcRecord $manifestPath @{schema_version=1;external_assets=@($pin)}
        $caseHash=(Get-FileHash $manifestPath).Hash.ToLowerInvariant()
        Assert-Vc ((Invoke-VcFixture (Join-Path $root ('bad-'+$case)) -Consent -Hash $caseHash).exit_code -eq 21 -and (Get-VcLaunchCount) -eq 1) ('Invalid '+$case+' launched vendor.')
        $pin.bytes=(Get-Item $vendorPath).Length; $pin.sha256=(Get-FileHash $vendorPath).Hash.ToLowerInvariant(); $pin.installer_arguments=@('/install','/norestart')
    }
    Write-AutoClipVcRecord $manifestPath @{schema_version=1;external_assets=@($pin)}
    $manifestHash=(Get-FileHash $manifestPath).Hash.ToLowerInvariant()
    foreach ($code in @(1603,1602,-2147023294)) {
        Set-VcBoundary -Code $code
        $r=Invoke-VcFixture (Join-Path $root ('native-'+$code)) -Consent
        Assert-Vc ($r.vendor_exit_code -eq $code -and $r.exit_code -ne 0) 'Vendor failure/cancellation reported ready.'
        Assert-Vc (Test-Path $r.receipt_path) 'Native outcome receipt missing.'
    }
    Set-VcBoundary -Uac $true
    $r=Invoke-VcFixture (Join-Path $root 'uac') -Consent
    Assert-Vc ($r.status -eq 'cancelled' -and $r.exit_code -eq 1223) 'UAC denial was not distinguished.'
    foreach($path in @($r.receipt_path,(Join-Path $root 'uac/vc-state.json'))){
        $cancelled=Get-Content -LiteralPath $path -Raw|ConvertFrom-Json
        Assert-Vc ($cancelled.status-eq'cancelled' -and $null-eq$cancelled.vendor_exit_code) 'Cancellation did not persist terminal state without a vendor exit.'
    }
    Set-VcBoundary -LaunchFailure $true
    $launchState=Join-Path $root 'launch-failure'
    $r=Invoke-VcFixture $launchState -Consent
    Assert-Vc ($r.status-eq'unresolved' -and $r.exit_code-eq23 -and $null-eq$r.vendor_exit_code) 'Non-cancellation launch failure reported a terminal vendor outcome.'
    $launchRecord=Get-Content -LiteralPath (Join-Path $launchState 'vc-state.json') -Raw|ConvertFrom-Json
    Assert-Vc ($launchRecord.status-eq'in_progress' -and $null-eq$launchRecord.vendor_exit_code) 'Unknown launch failure lost conservative prelaunch state.'
    $launches=Get-VcLaunchCount
    Assert-Vc ((Invoke-VcFixture $launchState -Consent).status-eq'unresolved' -and (Get-VcLaunchCount)-eq$launches) 'Unknown launch failure retried the vendor.'
    Set-VcBoundary -Code 0
    Assert-Vc ((Invoke-VcFixture (Join-Path $root 'zero-missing') -Consent).status -eq 'failed') 'Vendor zero alone qualified capability.'
    Set-VcBoundary -Code 0 -PostCapability $true
    Assert-Vc ((Invoke-VcFixture (Join-Path $root 'zero-ready') -Consent).exit_code -eq 0) 'Vendor zero with post-install capability did not qualify.'
    Set-VcBoundary -PublicationFailure $true
    $publication=Join-Path $root 'publication-failure'
    Assert-Vc ((Invoke-VcFixture $publication -Consent).status -eq 'unresolved') 'Failed outcome publication reported ready/pending.'
    $prelaunch=Get-Content (Join-Path $publication 'vc-state.json') -Raw | ConvertFrom-Json
    Assert-Vc ($prelaunch.status -eq 'in_progress' -and $null -eq $prelaunch.vendor_exit_code) 'Publication failure lost prelaunch safety state.'
    Assert-Vc ((Invoke-VcFixture $publication -Consent).status -eq 'unresolved') 'Publication failure allowed same-boot retry.'
    Set-VcBoundary -NoHandle $true
    $interrupted=Join-Path $root 'interrupted'
    Assert-Vc ((Invoke-VcFixture $interrupted -Consent).status -eq 'unresolved') 'Unknown native handle was accepted.'
    $launches=Get-VcLaunchCount
    Assert-Vc ((Invoke-VcFixture $interrupted -Consent).status -eq 'unresolved' -and (Get-VcLaunchCount) -eq $launches) 'Same-boot interrupted state retried vendor.'
    Set-VcBoundary -Boot 'boot-B'
    Assert-Vc ((Invoke-VcFixture $interrupted -Check).status -eq 'unresolved') 'Post-reboot interrupted attempt ignored missing capability.'
    Set-VcBoundary -Boot 'boot-B' -Capability $true
    Assert-Vc ((Invoke-VcFixture $interrupted -Check).exit_code -eq 0) 'Post-reboot interrupted attempt did not verify fresh capability.'
    $record=Get-Content (Join-Path $interrupted 'vc-state.json') -Raw | ConvertFrom-Json
    $record.recipient_sid='S-1-5-21-foreign'
    Write-AutoClipVcRecord (Join-Path $interrupted 'vc-state.json') $record
    $before=(Get-FileHash (Join-Path $interrupted 'vc-state.json')).Hash
    Assert-Vc ((Invoke-VcFixture $interrupted -Consent).status -eq 'failed' -and (Get-FileHash (Join-Path $interrupted 'vc-state.json')).Hash -eq $before) 'Foreign state overwritten.'
    Set-VcBoundary -Delay 2400
    $concurrent=Join-Path $root 'concurrent'
    $out=Join-Path $root 'concurrent.json'
    $childArgs=@('-NoProfile','-NonInteractive','-File',('"'+$fixture+'"'),'-ManifestPath',('"'+$manifestPath+'"'),'-ManifestSha256',$manifestHash,'-StateDirectory',('"'+$concurrent+'"'),'-InstallerPath',('"'+$vendorPath+'"'),'-AcceptMicrosoftTerms')
    $child=Start-Process powershell.exe -ArgumentList $childArgs -PassThru -WindowStyle Hidden -RedirectStandardOutput $out
    try {
        $deadline=[DateTime]::UtcNow.AddSeconds(10)
        while (-not (Test-Path (Join-Path $concurrent 'vc-state.json')) -and [DateTime]::UtcNow -lt $deadline) { Start-Sleep -Milliseconds 30 }
        Assert-Vc (Test-Path (Join-Path $concurrent 'vc-state.json')) 'Concurrent child did not publish prelaunch state.'
        Assert-Vc ((Invoke-VcFixture $concurrent -Consent).exit_code -eq 1618) 'Actual concurrent invocation was not excluded.'
    } finally { $child.WaitForExit(); $child.Dispose() }
    Assert-Vc ((Get-Content $out -Raw | ConvertFrom-Json).exit_code -eq 3010) 'Serialized child outcome failed.'
    Set-VcBoundary -Delay 2400 -ObservationFailure $true
    $observed=Join-Path $root 'observation-failure'
    $out=Join-Path $root 'observation-result.json'
    $childArgs=@('-NoProfile','-NonInteractive','-File',('"'+$fixture+'"'),'-ManifestPath',('"'+$manifestPath+'"'),'-ManifestSha256',$manifestHash,'-StateDirectory',('"'+$observed+'"'),'-InstallerPath',('"'+$vendorPath+'"'),'-AcceptMicrosoftTerms')
    $child=Start-Process powershell.exe -ArgumentList $childArgs -PassThru -WindowStyle Hidden -RedirectStandardOutput $out
    try {
        $deadline=[DateTime]::UtcNow.AddSeconds(10)
        while (-not (Test-Path (Join-Path $observed 'vc-state.json')) -and [DateTime]::UtcNow -lt $deadline) { Start-Sleep -Milliseconds 30 }
        Assert-Vc (Test-Path (Join-Path $observed 'vc-state.json')) 'Observation fixture did not publish prelaunch state.'
        Assert-Vc ((Invoke-VcFixture $observed -Consent).exit_code -eq 1618) 'Observation failure released lock over live owned child.'
    } finally { $child.WaitForExit(); $child.Dispose() }
    $r=Get-Content $out -Raw | ConvertFrom-Json
    Assert-Vc ($r.status -eq 'unresolved' -and $r.exit_code -eq 23) 'Handle observation failure reported known vendor outcome.'
    Assert-Vc ((Invoke-VcFixture $observed -Consent).status -eq 'unresolved') 'Observation failure allowed automatic retry.'
    Set-VcBoundary -Delay 2200 -WaitFailure $true
    $timer=[Diagnostics.Stopwatch]::StartNew()
    $r=Invoke-VcFixture (Join-Path $root 'wait-failure') -Consent
    $timer.Stop()
    Assert-Vc ($r.status -eq 'unresolved' -and $timer.ElapsedMilliseconds -ge 2200) 'Native wait fallback released a live owned process or reported success.'
    'PASS: protected files; durable3010; fresh same-boot and reboot decisions; no-consent/no-launch; pins/signature/publisher/version; vendor/UAC failures; interrupted/foreign state; real process lock exclusion.'
    'Inert boundaries only: no vendor, system DLL load, acquisition, VM, setup, agreement acceptance or production qualification.'
} finally {
    $resolved=[IO.Path]::GetFullPath($sandbox)
    if (-not $resolved.StartsWith([IO.Path]::GetFullPath($env:TEMP).TrimEnd('\')+'\') -or [IO.Path]::GetFileName($resolved) -notlike 'autoclip-vc-inert-*') { throw 'Unsafe fixture cleanup target.' }
    Remove-Item -LiteralPath $resolved -Recurse -Force
}
