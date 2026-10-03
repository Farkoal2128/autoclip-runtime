param([string]$HelperPath)
$ErrorActionPreference='Stop'
$helper=if($HelperPath){$HelperPath}else{Join-Path $PSScriptRoot '../installer/install-vc-runtime.ps1'}
$tokens=$null;$errors=$null
$ast=[Management.Automation.Language.Parser]::ParseFile($helper,[ref]$tokens,[ref]$errors)
if($errors.Count){throw 'Capability helper does not parse.'}
foreach($name in @('Assert-AutoClipVcPath','Assert-AutoClipVcAuthority','Assert-AutoClipVcSignature','Get-AutoClipVcVersion','Test-AutoClipVcCapability')){
 $nodes=@($ast.FindAll({param($n)$n -is [Management.Automation.Language.FunctionDefinitionAst] -and $n.Name-ceq$name},$false))
 if($nodes.Count-ne1){throw "Actual capability function missing/ambiguous: $name"}
 . ([scriptblock]::Create($nodes[0].Extent.Text))
}
# Only the native loading boundary is inert. Files, headers, versions, ACLs and
# initial Authenticode observations are the actual installed system DLLs.
if('AutoClipVcLoader'-as[type]){throw 'Capability fixture requires a fresh PowerShell process.'}
Add-Type -TypeDefinition @'
using System;
using System.Collections.Generic;
public static class AutoClipVcLoader {
 public static readonly List<string> Paths=new List<string>();
 public static bool FailLoad;
 public static bool FailFree;
 public static IntPtr LoadLibraryEx(string path, IntPtr file, uint flags) {
  if(file!=IntPtr.Zero || flags!=0x1100) throw new Exception("Native loader arguments differ");
  Paths.Add(path);return FailLoad ? IntPtr.Zero : new IntPtr(1);
 }
 public static bool FreeLibrary(IntPtr module) {return !FailFree && module==new IntPtr(1);}
}
'@
$minimum=[version]'14.44.35211.0'
$names=@('vcruntime140.dll','vcruntime140_1.dll','msvcp140.dll','vcomp140.dll')
$expected=@($names|ForEach-Object{Join-Path ([Environment]::SystemDirectory) $_})
$realSignatures=@{}
foreach($path in $expected){
 if(!(Test-Path -LiteralPath $path -PathType Leaf)){throw "Host integration prerequisite missing: $path"}
 Assert-AutoClipVcAuthority $path '' -SystemFile
 if((Get-AutoClipVcVersion $path)-lt$minimum){throw "Host integration prerequisite version too old: $path"}
 $signature=Get-AuthenticodeSignature -LiteralPath $path
 if($signature.Status-ne'Valid' -or $signature.SignerCertificate.Subject-notmatch '(^|,\s*)CN=Microsoft Windows Software Compatibility Publisher(,|$)' -or
    $signature.SignerCertificate.Subject-notmatch '(^|,\s*)O=Microsoft Corporation(,|$)'){throw "Host integration prerequisite compatibility signature differs: $path"}
 $realSignatures[$path]=$signature
}
if(-not(Test-AutoClipVcCapability $minimum)){throw 'Actual capability rejected valid Microsoft compatibility-signed system DLLs.'}
if(([AutoClipVcLoader]::Paths.ToArray()-join'|')-cne($expected-join'|')){throw 'Capability omitted or changed one of the four fixed system DLL loads.'}
# Installed DLL acceptance must not broaden the downloaded vendor EXE rule.
$rejected=$false
try{Assert-AutoClipVcSignature $expected[0] 'Microsoft Corporation'}catch{$rejected=$true}
if(-not$rejected){throw 'Vendor EXE signer policy accepted compatibility publisher.'}
# Exercise native signature results through the actual capability and signature
# functions; never replace the entire capability decision with a boolean.
function Get-AuthenticodeSignature {
 param([string]$LiteralPath)
 if($LiteralPath-cne$expected[0]){return $realSignatures[$LiteralPath]}
 [pscustomobject]@{Status=$script:signatureStatus;SignerCertificate=$script:certificate}
}
foreach($case in @('corporation','compatibility','invalid','missing','foreign-cn','foreign-o','suffix-cn','suffix-o')){
 $script:signatureStatus='Valid';$subject='CN=Microsoft Windows Software Compatibility Publisher, O=Microsoft Corporation, C=US'
 if($case-eq'corporation'){$subject='CN=Microsoft Corporation, O=Microsoft Corporation, C=US'}
 if($case-eq'invalid'){$script:signatureStatus='HashMismatch'}
 if($case-eq'foreign-cn'){$subject='CN=Other Publisher, O=Microsoft Corporation, C=US'}
 if($case-eq'foreign-o'){$subject='CN=Microsoft Windows Software Compatibility Publisher, O=Other Corporation, C=US'}
 if($case-eq'suffix-cn'){$subject='CN=Microsoft Windows Software Compatibility Publisher Evil, O=Microsoft Corporation, C=US'}
 if($case-eq'suffix-o'){$subject='CN=Microsoft Windows Software Compatibility Publisher, O=Microsoft Corporation Evil, C=US'}
 $script:certificate=if($case-eq'missing'){$null}else{[pscustomobject]@{Subject=$subject}}
 [AutoClipVcLoader]::Paths.Clear()
 $result=Test-AutoClipVcCapability $minimum
 if($result-ne($case-in@('corporation','compatibility'))){throw "Actual installed-DLL signature decision differs: $case"}
 if(-not$result -and [AutoClipVcLoader]::Paths.Count-ne0){throw 'Rejected signature reached native load.'}
}
$script:certificate=[pscustomobject]@{Subject='CN=Microsoft Corporation, O=Microsoft Corporation, C=US'}
[AutoClipVcLoader]::Paths.Clear()
if(Test-AutoClipVcCapability ([version]'65535.0.0.0')){throw 'Below-minimum DLL capability accepted.'}
if([AutoClipVcLoader]::Paths.Count-ne0){throw 'Below-minimum DLL reached native load.'}
[AutoClipVcLoader]::FailLoad=$true
if(Test-AutoClipVcCapability $minimum){throw 'Failed native load accepted.'}
[AutoClipVcLoader]::FailLoad=$false;[AutoClipVcLoader]::FailFree=$true
if(Test-AutoClipVcCapability $minimum){throw 'Failed native loader cleanup accepted.'}
'PASS actual four-DLL capability path, real host metadata/signatures; strict vendor signer, installed signer negatives, version/load failures.'
'Native loader boundary inert; no vendor, actual DLL load, UAC, VM, Setup or release action.'
