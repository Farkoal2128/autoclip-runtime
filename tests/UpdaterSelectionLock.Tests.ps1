$ErrorActionPreference = 'Stop'
$repo = Split-Path -Parent $PSScriptRoot
$powershell = Join-Path $env:SystemRoot 'System32/WindowsPowerShell/v1.0/powershell.exe'
$fixture = Join-Path $env:TEMP ('autoclip-selection-' + [guid]::NewGuid().ToString('N'))
$sid = [Security.Principal.WindowsIdentity]::GetCurrent().User
$acl = [Security.AccessControl.DirectorySecurity]::new()
$acl.SetOwner($sid); $acl.SetAccessRuleProtection($true, $false)
foreach ($id in @($sid.Value, 'S-1-5-18', 'S-1-5-32-544')) {
    $acl.AddAccessRule([Security.AccessControl.FileSystemAccessRule]::new([Security.Principal.SecurityIdentifier]::new($id), 'FullControl', 'ContainerInherit,ObjectInherit', 'None', 'Allow'))
}
[IO.Directory]::CreateDirectory($fixture, $acl) | Out-Null
Write-Host "Owned protected fixture: $fixture"
function Assert($condition, $message) { if (-not $condition) { throw $message } }
function Mutex-Name([string]$base) {
    $hash = [Security.Cryptography.SHA256]::Create()
    try { $key = [BitConverter]::ToString($hash.ComputeHash([Text.Encoding]::UTF8.GetBytes($sid.Value + "`n" + [IO.Path]::GetFullPath($base).TrimEnd('\').ToUpperInvariant()))).Replace('-', '').ToLowerInvariant() }
    finally { $hash.Dispose() }
    return 'Global\AutoClip.Selection.v1.' + $key
}
function New-Mutex([string]$name, [switch]$Unsafe) {
    $security = [Security.AccessControl.MutexSecurity]::new()
    $security.SetOwner($sid); $security.SetAccessRuleProtection($true, $false)
    $ids = if ($Unsafe) { @('S-1-1-0', $sid.Value) } else { @($sid.Value, 'S-1-5-18', 'S-1-5-32-544') }
    foreach ($id in $ids) { $security.AddAccessRule([Security.AccessControl.MutexAccessRule]::new([Security.Principal.SecurityIdentifier]::new($id), 'FullControl', 'Allow')) }
    $created = $false
    return [Threading.Mutex]::new($false, $name, [ref]$created, $security)
}
function Child([string]$code) {
    $code = '$ErrorActionPreference = ''Stop''; $ProgressPreference = ''SilentlyContinue''; ' + $code
    $info = [Diagnostics.ProcessStartInfo]::new($powershell)
    $info.Arguments = '-NoProfile -NonInteractive -EncodedCommand ' + [Convert]::ToBase64String([Text.Encoding]::Unicode.GetBytes($code))
    $info.UseShellExecute = $false; $info.CreateNoWindow = $true
    $info.RedirectStandardOutput = $true; $info.RedirectStandardError = $true
    $process = [Diagnostics.Process]::Start($info)
    try {
        if (-not $process.WaitForExit(20000)) { $process.Kill(); throw 'Owned child exceeded 20 seconds.' }
        return [pscustomobject]@{ Exit = $process.ExitCode; Output = $process.StandardOutput.ReadToEnd() + $process.StandardError.ReadToEnd() }
    } finally { $process.Dispose() }
}
$base = Join-Path $fixture 'base'
[IO.Directory]::CreateDirectory($base) | Out-Null
[IO.File]::WriteAllText((Join-Path $base 'active.json'), '{invalid state: must not read while held')
$mutex = New-Mutex (Mutex-Name $base)
$held = $mutex.WaitOne(0)
try {
    $failures = @()
    foreach ($script in @('update.ps1', 'update-app.ps1')) {
        foreach ($alias in @($base, ($base.ToUpperInvariant().Replace('\', '/') + '/'))) {
            $path = Join-Path $repo $script
            $result = Child "try { & '$path' -BaseRoot '$alias' -Rollback -NoShortcut; exit 2 } catch { Write-Output `$_.Exception.Message; exit 1 }"
            if ($result.Exit -ne 1 -or $result.Output -notlike '*AutoClip selection is busy*') { $failures += "$script reached state validation while held: $($result.Output.Trim())" }
        }
    }
    Assert ($failures.Count -eq 0) ($failures -join "`n")
} finally { if ($held) { $mutex.ReleaseMutex() }; $mutex.Dispose() }
Write-Host 'Actual runtime/app entry exclusion passed.'

# Load only the production lock function for API checks, without running an updater.
$sources = @{}
foreach ($script in @('update.ps1', 'update-app.ps1')) {
    $sources[$script] = [IO.File]::ReadAllText((Join-Path $repo $script))
    $tokens = $null; $errors = $null
    $ast = [Management.Automation.Language.Parser]::ParseInput($sources[$script], [ref]$tokens, [ref]$errors)
    Assert (-not $errors.Count) "$script parser failed."
    $lock = $ast.Find({ param($node) $node -is [Management.Automation.Language.FunctionDefinitionAst] -and $node.Name -eq 'Acquire-SelectionMutex' }, $true)
    Assert $lock "$script has no selection acquisition."
    if ($script -eq 'update.ps1') { $lockSource = $lock.Extent.Text }
    else { Assert ($lock.Extent.Text.Replace("`r", '') -ceq $lockSource.Replace("`r", '')) 'Standalone protocols differ.' }
}
. ([ScriptBlock]::Create($lockSource))
$mutex = Acquire-SelectionMutex $base
try {
    $other = Join-Path $fixture 'independent'
    [IO.Directory]::CreateDirectory($other) | Out-Null
    [IO.File]::WriteAllText((Join-Path $other 'active.json'), '{independent invalid state')
    foreach ($script in @('update.ps1', 'update-app.ps1')) {
        $path = Join-Path $repo $script
        $result = Child "try { & '$path' -BaseRoot '$other' -Rollback -NoShortcut; exit 2 } catch { Write-Output `$_.Exception.Message; exit 1 }"
        Assert ($result.Exit -eq 1 -and $result.Output -like '*Invalid object passed in*') "$script different base was blocked: $($result.Output)"
        # Normal entry must also exclude before local manifest or installer execution.
        $option = if ($script -eq 'update.ps1') { "-InstallerPath '$fixture/never-run.ps1'" } else { "-ManifestPath '$fixture/never-read.json'" }
        $result = Child "try { & '$path' -BaseRoot '$base' $option -NoShortcut; exit 2 } catch { Write-Output `$_.Exception.Message; exit 1 }"
        Assert ($result.Exit -eq 1 -and $result.Output -like '*AutoClip selection is busy*') "$script normal entry was not excluded."
    }
} finally { $mutex.ReleaseMutex(); $mutex.Dispose() }
Write-Host 'Different bases and actual normal-entry exclusion passed.'

$unsafe = New-Mutex (Mutex-Name $base) -Unsafe
try {
    foreach ($script in @('update.ps1', 'update-app.ps1')) {
        $path = Join-Path $repo $script
        $result = Child "try { & '$path' -BaseRoot '$base' -Rollback -NoShortcut; exit 2 } catch { Write-Output `$_.Exception.Message; exit 1 }"
        Assert ($result.Exit -eq 1 -and $result.Output -like '*Unsafe AutoClip selection mutex authority*') "$script accepted unsafe authority: $($result.Output)"
    }
} finally { $unsafe.Dispose() }
$alias = Join-Path $fixture 'reparse'
New-Item -ItemType Junction -Path $alias -Target $base | Out-Null
foreach ($script in @('update.ps1', 'update-app.ps1')) {
    $path = Join-Path $repo $script
    $result = Child "try { & '$path' -BaseRoot '$alias' -Rollback -NoShortcut; exit 2 } catch { Write-Output `$_.Exception.Message; exit 1 }"
    Assert ($result.Exit -eq 1 -and $result.Output -like '*reparse alias*') "$script accepted a reparse alias."
}
# Remove only the owned junction itself; never recursively follow its target.
[IO.Directory]::Delete($alias)
Write-Host 'Unsafe ACL and reparse authority refusal passed.'

function Assert-Free([string]$base) {
    $name = Mutex-Name $base
    $result = Child "$lockSource; `$m = Acquire-SelectionMutex '$base'; try { Write-Output 'FREE' } finally { `$m.ReleaseMutex(); `$m.Dispose() }"
    Assert ($result.Exit -eq 0 -and $result.Output -like '*FREE*') "Selection was not released: $($result.Output)"
}
foreach ($script in @('update.ps1', 'update-app.ps1')) {
    $failed = $false
    try { & (Join-Path $repo $script) -BaseRoot $base -Rollback -NoShortcut }
    catch { $failed = $_.Exception.Message -like '*Invalid object passed in*' }
    Assert $failed "$script failure fixture did not reach ordinary validation."
    Assert-Free $base
}
Write-Host 'Actual exception paths release selection passed.'

# Keep another handle open while an owned child exits holding the mutex,
# otherwise the kernel object vanishes and this would not test abandonment.
$abandonedBase = Join-Path $fixture 'abandoned'
[IO.Directory]::CreateDirectory($abandonedBase) | Out-Null
[IO.File]::WriteAllText((Join-Path $abandonedBase 'active.json'), '{abandoned invalid state')
$ready = Join-Path $fixture 'abandoned-ready'; $leave = Join-Path $fixture 'abandoned-leave'
$code = "$lockSource; `$m = Acquire-SelectionMutex '$abandonedBase'; [IO.File]::WriteAllText('$ready', 'held'); while (-not [IO.File]::Exists('$leave')) { Start-Sleep -Milliseconds 20 }; exit 0"
$info = [Diagnostics.ProcessStartInfo]::new($powershell)
$info.Arguments = '-NoProfile -NonInteractive -EncodedCommand ' + [Convert]::ToBase64String([Text.Encoding]::Unicode.GetBytes($code))
$info.UseShellExecute = $false; $info.CreateNoWindow = $true
$child = [Diagnostics.Process]::Start($info)
$observer = $null
try {
    $deadline = [DateTime]::UtcNow.AddSeconds(20)
    while (-not [IO.File]::Exists($ready) -and -not $child.HasExited -and [DateTime]::UtcNow -lt $deadline) { Start-Sleep -Milliseconds 20 }
    Assert ([IO.File]::Exists($ready)) 'Owned abandonment child did not acquire.'
    $observer = [Threading.Mutex]::OpenExisting((Mutex-Name $abandonedBase))
    [IO.File]::WriteAllText($leave, 'leave')
    Assert ($child.WaitForExit(20000) -and $child.ExitCode -eq 0) 'Owned abandonment child did not terminate.'
    $abandoned = $false
    try { [void]$observer.WaitOne(0) } catch [Threading.AbandonedMutexException] { $abandoned = $true }
    Assert $abandoned 'Fixture failed to create real abandoned ownership.'
    $observer.ReleaseMutex()
    # Create abandonment again while observer preserves the kernel object.
    [IO.File]::Delete($ready); [IO.File]::Delete($leave)
    $child.Dispose(); $child = [Diagnostics.Process]::Start($info)
    $deadline = [DateTime]::UtcNow.AddSeconds(20)
    while (-not [IO.File]::Exists($ready) -and -not $child.HasExited -and [DateTime]::UtcNow -lt $deadline) { Start-Sleep -Milliseconds 20 }
    Assert ([IO.File]::Exists($ready)) 'Second abandonment child did not acquire.'
    [IO.File]::WriteAllText($leave, 'leave')
    Assert ($child.WaitForExit(20000)) 'Second abandonment child did not terminate.'
    try { & (Join-Path $repo 'update.ps1') -BaseRoot $abandonedBase -Rollback -NoShortcut; throw 'Invalid state accepted.' }
    catch { Assert ($_.Exception.Message -like '*Invalid object passed in*') 'Abandoned ownership bypassed state validation.' }
    Assert-Free $abandonedBase
} finally {
    if (-not $child.HasExited) { $child.Kill(); [void]$child.WaitForExit(20000) }
    $child.Dispose(); if ($observer) { $observer.Dispose() }
}
Write-Host 'Real abandoned ownership retains ordinary validation passed.'

# These copied entry scripts preserve their transactions/state/writers. Only
# installed-payload/application validators are replaced with inert assertions.
# This proves updater lifetime, not application health or installer qualification.
$checks = [Collections.Generic.List[string]]::new()
function Assert-Held([string]$stage) {
    $name = Mutex-Name $transactionBase
    $result = Child "`$m = [Threading.Mutex]::OpenExisting('$name'); try { if (`$m.WaitOne(0)) { `$m.ReleaseMutex(); exit 3 }; Write-Output 'HELD' } finally { `$m.Dispose() }"
    Assert ($result.Exit -eq 0 -and $result.Output -like '*HELD*') "Selection not held at ${stage}: $($result.Output)"
    $checks.Add($stage)
    if ($injectStateFailure -and $stage -eq 'Write-AtomicText' -and $Path -like '*active.json') { throw 'Inert state commit failure.' }
}
function Adapt([string]$script, [hashtable]$replacements, [string[]]$writers) {
    $source = $sources[$script]
    $tokens = $null; $errors = $null
    $ast = [Management.Automation.Language.Parser]::ParseInput($source, [ref]$tokens, [ref]$errors)
    $functions = @($ast.FindAll({ param($node) $node -is [Management.Automation.Language.FunctionDefinitionAst] }, $true) | Sort-Object { $_.Extent.StartOffset } -Descending)
    foreach ($function in $functions) {
        if ($replacements.ContainsKey($function.Name)) {
            $source = $source.Substring(0, $function.Extent.StartOffset) + $replacements[$function.Name] + $source.Substring($function.Extent.EndOffset)
        } elseif ($function.Name -in $writers) {
            # Insert after parameters (including inline function parameters).
            $offset = $function.Body.Extent.StartOffset + 1
            if ($function.Body.ParamBlock) { $offset = $function.Body.ParamBlock.Extent.EndOffset }
            $source = $source.Insert($offset, "`nAssert-Held '$($function.Name)'`n")
        }
    }
    $path = Join-Path $fixture ('inert-' + $script)
    [IO.File]::WriteAllText($path, $source)
    return $path
}
$runtimeEntry = Adapt 'update.ps1' @{
    'Test-InstalledRelease' = 'function Test-InstalledRelease($Release) { Assert-Held runtime-payload; return (Join-Path $baseFull $Release.release_id) }'
    'Assert-UserDatabaseCompatible' = 'function Assert-UserDatabaseCompatible($Python, $ReleaseId) { Assert-Held runtime-database }'
    'Update-DesktopShortcut' = 'function Update-DesktopShortcut($Release) { Assert-Held runtime-shortcut; return $null }'
} @('Read-ActiveState', 'Select-Release', 'Write-StableLauncher', 'Write-AtomicText', 'Complete-UpdateProgress')
$installer = Join-Path $fixture 'inert-installer.ps1'
[IO.File]::WriteAllText($installer, @'
param([switch]$ReleaseInfo, [switch]$PrerequisitesOnly, [string]$InstallRoot)
Assert-Held installer-child
if ($ReleaseInfo) { [pscustomobject]@{ ReleaseId = 'fixture-current'; ArchiveSha256 = 'a' * 64; ManifestSha256 = 'b' * 64 } }
else { Assert-Held installer-terminal; [IO.Directory]::CreateDirectory($InstallRoot) | Out-Null }
'@)
$transactionBase = Join-Path $fixture 'runtime-transaction'
[IO.Directory]::CreateDirectory($transactionBase) | Out-Null
& $runtimeEntry -BaseRoot $transactionBase -InstallerPath $installer -NoShortcut
Assert-Free $transactionBase
& $runtimeEntry -BaseRoot $transactionBase -InstallerPath $installer -NoShortcut
Assert-Free $transactionBase
$state = Get-Content (Join-Path $transactionBase 'active.json') -Raw | ConvertFrom-Json
$state.previous = [pscustomobject]@{ release_id = 'fixture-previous'; archive_sha256 = 'c' * 64; manifest_sha256 = 'd' * 64 }
[IO.File]::WriteAllText((Join-Path $transactionBase 'active.json'), ($state | ConvertTo-Json -Depth 5))
& $runtimeEntry -BaseRoot $transactionBase -Rollback -NoShortcut
Assert-Free $transactionBase
Assert ((Get-Content (Join-Path $transactionBase 'active.json') -Raw | ConvertFrom-Json).current.release_id -eq 'fixture-previous') 'Runtime rollback writer was not exercised.'
foreach ($stage in @('Read-ActiveState', 'installer-child', 'installer-terminal', 'Select-Release', 'Write-AtomicText', 'Complete-UpdateProgress')) { Assert ($checks.Contains($stage)) "Runtime stage not observed: $stage" }
Write-Host 'Inert runtime normal/child/already-current/rollback writer lifetime passed.'

$appEntry = Adapt 'update-app.ps1' @{
    'Test-AppLayer' = 'function Test-AppLayer($App) { Assert-Held app-payload; return (Join-Path $baseFull "apps/site") }'
    'Test-AppHealth' = 'function Test-AppHealth($Python, $Site) { Assert-Held app-health }'
    'Assert-AppDatabaseCompatible' = 'function Assert-AppDatabaseCompatible($Python, $Site) { Assert-Held app-database }'
    'Update-DesktopShortcut' = 'function Update-DesktopShortcut { Assert-Held app-shortcut; return $null }'
} @('Read-RuntimeState', 'Read-AppManifest', 'Commit-AppState', 'Write-StableLauncher', 'Write-DesktopLauncher', 'Write-AtomicText')
$transactionBase = Join-Path $fixture 'app-transaction'
$runtimeRoot = Join-Path $transactionBase 'fixture-runtime'
[IO.Directory]::CreateDirectory((Join-Path $runtimeRoot '.venv/Scripts')) | Out-Null
[IO.File]::WriteAllText((Join-Path $runtimeRoot '.venv/Scripts/python.exe'), 'inert owned text, never execute')
[IO.File]::WriteAllText((Join-Path $runtimeRoot '.install-complete'), 'inert fixture')
[IO.File]::WriteAllText((Join-Path $runtimeRoot 'release-manifest.json'), '{}')
$runtimeHash = (Get-FileHash (Join-Path $runtimeRoot 'release-manifest.json')).Hash.ToLowerInvariant()
[IO.File]::WriteAllText((Join-Path $transactionBase 'active.json'), (@{ schema_version = 1; current = @{ release_id = 'fixture-runtime'; manifest_sha256 = $runtimeHash } } | ConvertTo-Json -Depth 5))
$appManifest = Join-Path $fixture 'inert-app-manifest.json'
$wheel = Join-Path $fixture 'inert.whl'
[IO.File]::WriteAllText($wheel, 'inert first-party wheel, retained fixture app avoids extraction')
$app = @{ app_id = 'fixture-app'; required_runtime = 'fixture-runtime'; wheel_sha256 = (Get-FileHash $wheel).Hash.ToLowerInvariant() }
$manifest = @{ schema_version = 1; app_id = $app.app_id; required_runtime = 'fixture-runtime'; runtime_manifest_sha256 = $runtimeHash; wheel_sha256 = $app.wheel_sha256; wheel_size = (Get-Item $wheel).Length }
[IO.File]::WriteAllText($appManifest, ($manifest | ConvertTo-Json -Depth 5))
[IO.Directory]::CreateDirectory((Join-Path $transactionBase 'apps/fixture-app')) | Out-Null
& $appEntry -BaseRoot $transactionBase -ManifestPath $appManifest -WheelPath $wheel -NoShortcut
Assert-Free $transactionBase
& $appEntry -BaseRoot $transactionBase -ManifestPath $appManifest -WheelPath $wheel -NoShortcut
Assert-Free $transactionBase
$appStatePath = Join-Path $transactionBase 'app-active.json'
$previous = @{ app_id = 'fixture-previous'; required_runtime = 'fixture-runtime'; wheel_sha256 = 'e' * 64 }
[IO.File]::WriteAllText($appStatePath, (@{ schema_version = 1; current = $app; previous = $previous } | ConvertTo-Json -Depth 5))
& $appEntry -BaseRoot $transactionBase -Rollback -NoShortcut
Assert-Free $transactionBase
Assert ((Get-Content $appStatePath -Raw | ConvertFrom-Json).current.app_id -eq 'fixture-previous') 'App rollback writer was not exercised.'
[IO.File]::WriteAllText($appStatePath, (@{ schema_version = 1; current = $app; previous = $null } | ConvertTo-Json -Depth 5))
& $appEntry -BaseRoot $transactionBase -Rollback -NoShortcut
Assert-Free $transactionBase
Assert (-not [IO.File]::Exists($appStatePath)) 'App rollback removal was not exercised.'
foreach ($stage in @('Read-RuntimeState', 'Read-AppManifest', 'Commit-AppState', 'Write-DesktopLauncher', 'app-database', 'app-health')) { Assert ($checks.Contains($stage)) "App stage not observed: $stage" }
Write-Host 'Inert app normal/already-current/rollback/removal writer lifetime passed.'

# Preserve real state-commit catch/finally behavior while replacing COM shortcut
# work with an inert owned file. Observe actual restoration Copy-Item under lock.
$failureEntry = Adapt 'update-app.ps1' @{
    'Test-AppLayer' = 'function Test-AppLayer($App) { Assert-Held app-payload; return "inert" }'
    'Test-AppHealth' = 'function Test-AppHealth($Python, $Site) { Assert-Held app-health }'
    'Assert-AppDatabaseCompatible' = 'function Assert-AppDatabaseCompatible($Python, $Site) { Assert-Held app-database }'
    'Update-DesktopShortcut' = 'function Update-DesktopShortcut { Assert-Held app-shortcut; $backup = $ShortcutPath + ".backup"; [IO.File]::WriteAllText($backup, "original inert shortcut"); [IO.File]::WriteAllText($ShortcutPath, "changed inert shortcut"); return $backup }'
} @('Read-RuntimeState', 'Commit-AppState', 'Write-StableLauncher', 'Write-DesktopLauncher', 'Write-AtomicText')
[IO.File]::WriteAllText($appStatePath, (@{ schema_version = 1; current = $app; previous = $previous } | ConvertTo-Json -Depth 5))
$before = (Get-FileHash $appStatePath).Hash
$shortcut = Join-Path $transactionBase 'inert-shortcut.lnk'
[IO.File]::WriteAllText($shortcut, 'original inert shortcut')
$injectStateFailure = $true
$breakpoint = Set-PSBreakpoint -Command Copy-Item -Script $failureEntry -Action { Assert-Held shortcut-restoration }
try {
    try { & $failureEntry -BaseRoot $transactionBase -Rollback -ShortcutPath $shortcut; throw 'Commit unexpectedly succeeded.' }
    catch { Assert ($_.Exception.Message -eq 'Inert state commit failure.') "Wrong commit failure: $($_.Exception.Message)" }
} finally { $injectStateFailure = $false; Remove-PSBreakpoint $breakpoint }
Assert ($checks.Contains('shortcut-restoration')) 'Actual shortcut restoration was not observed.'
Assert ((Get-FileHash $appStatePath).Hash -eq $before -and [IO.File]::ReadAllText($shortcut) -eq 'original inert shortcut' -and -not [IO.File]::Exists($shortcut + '.backup')) 'Commit failure did not preserve state/restore shortcut/retire backup.'
Assert-Free $transactionBase
Write-Host 'Inert commit failure holds through actual restoration and finally release passed.'
Write-Host 'Updater selection checks passed; fixture retained for evidence.'
