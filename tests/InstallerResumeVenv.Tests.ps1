$ErrorActionPreference = 'Stop'
$repo = Split-Path -Parent $PSScriptRoot
$tokens=$null; $errors=$null
$ast=[Management.Automation.Language.Parser]::ParseFile((Join-Path $repo 'install.ps1'),[ref]$tokens,[ref]$errors)
if($errors){throw 'Installer parse failed.'}
$node=$ast.Find({param($n) $n -is [Management.Automation.Language.IfStatementAst] -and $n.Extent.Text.StartsWith('if ($resumeIncomplete -and (Test-Path -LiteralPath $venv))')},$true)
if(!$node){throw 'Missing incomplete environment recovery branch.'}
$fixture=Join-Path $env:TEMP ('resume-venv-'+[guid]::NewGuid().ToString('N'))
[IO.Directory]::CreateDirectory($fixture)|Out-Null
$venv=$fixture
foreach($resumeIncomplete in @($true,$false)){
    $venvOptions=@()
    . ([scriptblock]::Create($node.Extent.Text))
    if($resumeIncomplete){
        if(($venvOptions -join '|') -cne '--clear|--force'){throw 'Matching incomplete non-venv directory cannot be recovered by uv.'}
    }elseif($venvOptions.Count){throw 'Completed or unproven roots received destructive uv options.'}
}
$resumeIncomplete=$true; $venv=Join-Path $fixture 'absent'; $venvOptions=@()
. ([scriptblock]::Create($node.Extent.Text))
if($venvOptions.Count){throw 'Absent environment received destructive options.'}
'GREEN actual recovery branch: clear+force only for existing matching incomplete environment.'
