$ErrorActionPreference='Stop'
function Assert($ok,$message){if(!$ok){throw $message}}
$repo=Split-Path -Parent $PSScriptRoot
$tokens=$null;$errors=$null;$ast=[Management.Automation.Language.Parser]::ParseFile((Join-Path $repo 'update-app.ps1'),[ref]$tokens,[ref]$errors)
$lock=$ast.Find({param($n)$n -is [Management.Automation.Language.FunctionDefinitionAst] -and $n.Name -eq 'Acquire-SelectionMutex'},$false)
. ([scriptblock]::Create($lock.Extent.Text))
$base=Join-Path $env:TEMP ('autoclip-owned-stop-'+[guid]::NewGuid().ToString('N'))
[IO.Directory]::CreateDirectory($base)|Out-Null
$root=Join-Path $base 'fixture-cpu';[IO.Directory]::CreateDirectory((Join-Path $root '.venv/Scripts'))|Out-Null
[IO.File]::WriteAllText((Join-Path $root '.venv/Scripts/python.exe'),'inert fixture, not executed')
[IO.File]::WriteAllText((Join-Path $root '.install-complete'),'fixture')
[IO.File]::WriteAllText((Join-Path $root 'release-manifest.json'),'{}')
$statePath=Join-Path $base 'active.json'
[IO.File]::WriteAllText($statePath,(@{schema_version=1;current=@{release_id='fixture-cpu';manifest_sha256=(Get-FileHash (Join-Path $root 'release-manifest.json')).Hash.ToLowerInvariant()}}|ConvertTo-Json))
$before=[IO.File]::ReadAllText($statePath)
$counter=@{called=0}
$stop={param($selectedRoot)
    Assert ($selectedRoot -ieq $root) 'Stop callback received another runtime.'
    $counter.called++
    # Another native process must observe the same mutex as busy while stopping.
    $mutex=Acquire-SelectionMutex $base
    try{
        $source=$lock.Extent.Text
        $code=$source+"`ntry { `$m=Acquire-SelectionMutex '"+$base+"'; `$m.ReleaseMutex(); `$m.Dispose(); exit 2 } catch { if(`$_.Exception.Message -like '*AutoClip selection is busy*'){exit 0};exit 3 }"
        $p=Start-Process -FilePath (Join-Path $env:SystemRoot 'System32/WindowsPowerShell/v1.0/powershell.exe') -ArgumentList @('-NoProfile','-NonInteractive','-EncodedCommand',[Convert]::ToBase64String([Text.Encoding]::Unicode.GetBytes($code))) -WindowStyle Hidden -PassThru -Wait
        Assert ($p.ExitCode -eq 0) 'Updater did not hold selection mutex across stopping.'
    }finally{$mutex.ReleaseMutex();$mutex.Dispose()}
    throw 'Unknown process uses the release; preserved.'
}
$failed=$false;try{& (Join-Path $repo 'update-app.ps1') -BaseRoot $base -Rollback -NoShortcut -StopOwnedApp $stop}catch{Write-Output $_.Exception.Message;$failed=$_.Exception.Message -like '*Unknown process uses the release*'}
Assert ($failed -and $counter.called -eq 1 -and [IO.File]::ReadAllText($statePath) -ceq $before) 'Stop refusal changed selection or bypassed callback.'
[IO.File]::Delete((Join-Path $root '.install-complete'))
$failed=$false;try{& (Join-Path $repo 'update-app.ps1') -BaseRoot $base -Rollback -NoShortcut -StopOwnedApp $stop}catch{$failed=$_.Exception.Message -like '*selected runtime is incomplete*'}
Assert ($failed -and $counter.called -eq 1) 'Owned stop executed before runtime identity validation.'
Write-Output ('PASS validated runtime, mutex-held stopping, unknown-process refusal '+$base)
