$ErrorActionPreference = 'Stop'
$helper = Join-Path (Split-Path -Parent $PSScriptRoot) 'installer/install-msys2-packages.ps1'
$source = [IO.File]::ReadAllText($helper)
$tokens = $null; $errors = $null
$ast = [Management.Automation.Language.Parser]::ParseInput($source, [ref]$tokens, [ref]$errors)
if ($errors.Count) { throw 'Helper syntax errors.' }
$convert = $ast.Find({ param($node) $node -is [Management.Automation.Language.FunctionDefinitionAst] -and $node.Name -eq 'ConvertTo-Msys2Path' }, $true)
. ([scriptblock]::Create($convert.Extent.Text))
# Execute the real allocation block without filesystem or native side effects.
$start = $source.IndexOf('$identity = [guid]')
$end = $source.IndexOf('$configFile =', $start)
$allocation = [scriptblock]::Create($source.Substring($start, $end - $start))
$root = 'C:\AutoClipMsysTar20261001\msys64'
$keyParent = Join-Path $root 'etc/pacman.d'
. $allocation
$first = $keyDirectory
if ([Text.Encoding]::UTF8.GetByteCount((ConvertTo-Msys2Path $keyDirectory) + '/S.gpg-agent.browser') + 1 -gt 108) {
    throw 'Supported guest root must fit all GnuPG socket names.'
}
if ($keyDirectory -notmatch '[a-z-]+[0-9a-f]{32}$') { throw 'Keep the full random identity.' }
. $allocation
if ($first -eq $keyDirectory) { throw 'Each keyring must be isolated.' }
$baseLength = [Text.Encoding]::UTF8.GetByteCount((ConvertTo-Msys2Path $keyDirectory) + '/S.gpg-agent.browser') + 1
foreach ($length in @(108,109)) {
    $padding = $length - $baseLength
    $keyParent = Join-Path ($root + ('x' * $padding)) 'etc/pacman.d'
    $rejected = $false
    try { . $allocation } catch {
        if ($_.Exception.Message -notmatch 'socket path') { throw }
        $rejected = $true
    }
    if ($rejected -ne ($length -gt 108)) { throw "Socket boundary $length was handled incorrectly." }
}
'MSYS2 real keyring allocation: guest root, full random isolation, 108-byte boundary and fail-closed overflow PASS'
