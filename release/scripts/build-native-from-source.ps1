param(
    [Parameter(Mandatory)][string]$BuildRoot,
    [Parameter(Mandatory)][string]$Wheelhouse,
    [Parameter(Mandatory)][string]$OpenBlasArchive,
    [Parameter(Mandatory)][string]$MsysBash,
    [string]$CudaRoot,
    [switch]$InstallNvidiaGpu,
    [Parameter(Mandatory)][string]$Python,
    [Parameter(Mandatory)][string]$Uv
)

$ErrorActionPreference = 'Stop'
. (Join-Path $PSScriptRoot 'upstream-assets.ps1')
. (Join-Path $PSScriptRoot 'native-wheel-cache.ps1')
$requiredMsysPackages = @('make', 'diffutils', 'pkgconf', 'mingw-w64-ucrt-x86_64-nasm')

function Invoke-Checked([string]$Program, [string[]]$Arguments) {
    & $Program @Arguments | Out-Host
    if ($LASTEXITCODE -ne 0) { throw "$Program failed with exit code $LASTEXITCODE" }
}

function Convert-ToMsysPath([string]$Path) {
    $full = [IO.Path]::GetFullPath($Path)
    if ($full -notmatch '^([A-Za-z]):\\(.*)$') { throw "Expected an absolute drive path: $full" }
    return '/' + $Matches[1].ToLowerInvariant() + '/' + $Matches[2].Replace('\', '/')
}

function Convert-ToCmakePath([string]$Path) {
    return [IO.Path]::GetFullPath($Path).Replace('\', '/')
}

function Get-VerifiedSource([string]$Name, [string]$Url, [long]$Size, [string]$Sha256) {
    $file = Join-Path $BuildRoot $Name
    Get-PinnedUpstreamAsset -Uri $Url -Size $Size -Sha256 $Sha256 -Destination $file | Out-Null
    return $file
}

function Get-PinnedGitSource([string]$Name, [string]$Url, [string]$Commit) {
    $folder = Join-Path $BuildRoot $Name
    if (-not (Test-Path -LiteralPath (Join-Path $folder '.git'))) {
        Invoke-Checked 'git' @('clone', '--recurse-submodules', $Url, $folder)
    }
    & git -C $folder cat-file -e ($Commit + '^{commit}') 2>$null
    if ($LASTEXITCODE -ne 0) { Invoke-Checked 'git' @('-C', $folder, 'fetch', 'origin', $Commit) }
    $current = (& git -C $folder rev-parse HEAD).Trim().ToLowerInvariant()
    if ($LASTEXITCODE -ne 0) { throw "Could not read Git source identity: $Name" }
    if ($current -ne $Commit) { Invoke-Checked 'git' @('-C', $folder, 'checkout', '--detach', $Commit) }
    Invoke-Checked 'git' @('-C', $folder, 'submodule', 'update', '--init', '--recursive')
    $head = (& git -C $folder rev-parse HEAD).Trim().ToLowerInvariant()
    if ($LASTEXITCODE -ne 0 -or $head -ne $Commit) { throw "Git source identity mismatch: $Name" }
    $dirty = & git -C $folder status --porcelain --untracked-files=no
    if ($LASTEXITCODE -ne 0 -or $dirty) { throw "Git source has modified tracked files: $Name" }
    return $folder
}

foreach ($path in @($MsysBash, $Python, $OpenBlasArchive)) {
    if (-not (Test-Path -LiteralPath $path)) { throw "Native build prerequisite missing: $path" }
}
if (-not (Get-Command cl.exe -ErrorAction SilentlyContinue)) {
    $vswhere = Join-Path ${env:ProgramFiles(x86)} 'Microsoft Visual Studio\Installer\vswhere.exe'
    if (-not (Test-Path -LiteralPath $vswhere)) { throw 'Visual Studio 2022 C++ Build Tools are required.' }
    $vsRoot = (& $vswhere -latest -products '*' -requires Microsoft.VisualStudio.Component.VC.Tools.x86.x64 -property installationPath | Select-Object -First 1)
    if (-not $vsRoot) { throw 'Visual Studio 2022 x64 C++ environment is missing.' }
    $vcvars = Join-Path $vsRoot 'VC\Auxiliary\Build\vcvars64.bat'
    if (-not (Test-Path -LiteralPath $vcvars)) { throw 'Visual Studio 2022 x64 C++ environment is missing.' }
    $variables = & cmd.exe /c "call `"$vcvars`" >nul && set"
    if ($LASTEXITCODE -ne 0) { throw 'Could not initialize the Visual Studio x64 C++ environment.' }
    foreach ($line in $variables) {
        if ($line -match '^([^=]+)=(.*)$') { [Environment]::SetEnvironmentVariable($Matches[1], $Matches[2], 'Process') }
    }
}
if (-not (Get-Command cl.exe -ErrorAction SilentlyContinue)) {
    throw 'Run from an x64 Visual Studio 2022 developer environment with cl.exe available.'
}
if (-not (Get-Command nasm.exe -ErrorAction SilentlyContinue)) {
    $msysRoot = Split-Path -Parent (Split-Path -Parent (Split-Path -Parent $MsysBash))
    $env:Path = (Join-Path $msysRoot 'ucrt64\bin') + ';' + $env:Path
}
if (-not (Get-Command nasm.exe -ErrorAction SilentlyContinue)) { throw 'NASM is required for codec-free FFmpeg.' }
if ($InstallNvidiaGpu) {
    . (Join-Path $PSScriptRoot 'cuda-prerequisites.ps1')
    if (-not (Test-CudaBuildRoot $CudaRoot)) { throw 'NVIDIA GPU build requires complete CUDA toolkit 12.8 build inputs.' }
}
$openblasHash = (Get-FileHash -LiteralPath $OpenBlasArchive -Algorithm SHA256).Hash.ToLowerInvariant()
if ($openblasHash -ne '8b04387766efc05c627e26d24797ec0d4ed4c105ec14fa7400aa84a02db22b66') {
    throw 'Pinned OpenBLAS archive hash mismatch.'
}

[IO.Directory]::CreateDirectory($BuildRoot) | Out-Null
[IO.Directory]::CreateDirectory($Wheelhouse) | Out-Null
$ffmpegArchive = Get-VerifiedSource 'ffmpeg-8.1.2.tar.xz' 'https://ffmpeg.org/releases/ffmpeg-8.1.2.tar.xz' 11710924 '464beb5e7bf0c311e68b45ae2f04e9cc2af88851abb4082231742a74d97b524c'
$pyavArchive = Get-VerifiedSource 'av-18.1.0.tar.gz' 'https://files.pythonhosted.org/packages/8d/f4/f22114d30d3435e38c6af2b4870f37b864403dca6ae7af747a289ce0a18e/av-18.1.0.tar.gz' 4451061 '47bfc286e1bc9de7ab4681fc2b575cd2460a66919d31ffe1bd5aa54fae531a28'
$ffmpegSource = Join-Path $BuildRoot 'ffmpeg-8.1.2'
$pyavSource = Join-Path $BuildRoot 'av-18.1.0'
$windowsTar = Join-Path $env:SystemRoot 'System32\tar.exe'
if (-not (Test-Path -LiteralPath $windowsTar -PathType Leaf)) { throw 'Windows tar.exe is required for native source extraction.' }
if (-not (Test-Path -LiteralPath $ffmpegSource)) { Invoke-Checked $windowsTar @('-xf', $ffmpegArchive, '-C', $BuildRoot) }
if (-not (Test-Path -LiteralPath $pyavSource)) { Invoke-Checked $windowsTar @('-xf', $pyavArchive, '-C', $BuildRoot) }
$oneDnnSource = Get-PinnedGitSource 'onednn-v3.1.1-source' 'https://github.com/uxlfoundation/oneDNN.git' '64f6bcbcbab628e96f33a62c3e975f8535a7bde4'
$ct2Source = Get-PinnedGitSource 'ctranslate2-v4.8.2-source' 'https://github.com/OpenNMT/CTranslate2.git' 'd44d2d069eb88c7b7804da864c10c201501cb4a9'
$openblasRoot = Join-Path $BuildRoot 'openblas-0.3.30'
if (-not (Test-Path -LiteralPath (Join-Path $openblasRoot 'lib\libopenblas.lib'))) {
    Expand-Archive -LiteralPath $OpenBlasArchive -DestinationPath $openblasRoot
}

$buildVenv = Join-Path $BuildRoot 'build-venv'
if (-not (Test-Path -LiteralPath (Join-Path $buildVenv 'Scripts\python.exe'))) {
    Invoke-Checked $Uv @('venv', '--python', $Python, $buildVenv)
}
$buildPython = Join-Path $buildVenv 'Scripts\python.exe'
$buildWheelCache = Join-Path $BuildRoot 'pinned-build-wheels'
$buildWheelAssets = @(
    @('setuptools-80.9.0-py3-none-any.whl', 'https://files.pythonhosted.org/packages/a3/dc/17031897dae0efacfea57dfd3a82fdd2a2aeb58e0ff71b77b87e44edc772/setuptools-80.9.0-py3-none-any.whl', 1201486, '062d34222ad13e0cc312a4c02d73f059e86a4acbfbdea8f8f76b28c99f306922'),
    @('cython-3.1.4-cp311-cp311-win_amd64.whl', 'https://files.pythonhosted.org/packages/6d/58/7d9ae7944bcd32e6f02d1a8d5d0c3875125227d050e235584127f2c64ffd/cython-3.1.4-cp311-cp311-win_amd64.whl', 2713755, '60d2f192059ac34c5c26527f2beac823d34aaa766ef06792a3b7f290c18ac5e2'),
    @('wheel-0.45.1-py3-none-any.whl', 'https://files.pythonhosted.org/packages/0b/2c/87f3254fd8ffd29e4c02732eee68a83a1d3c346ae39bc6822dcbcb697f2b/wheel-0.45.1-py3-none-any.whl', 72494, '708e7481cc80179af0e556bbf0cc00b8444c7321e2700b8d8580231d13017248'),
    @('delvewheel-1.11.2-py3-none-any.whl', 'https://files.pythonhosted.org/packages/58/44/ba50aa4c7c70b802a4335d43b6053101736a2597bbe1c10d1202600357e1/delvewheel-1.11.2-py3-none-any.whl', 59935, '0e7fcd24d4cefb3285e1e40b9873e9164ebd310f7e2597015d3b6adbd1605d01'),
    @('pefile-2024.8.26-py3-none-any.whl', 'https://files.pythonhosted.org/packages/54/16/12b82f791c7f50ddec566873d5bdd245baa1491bac11d15ffb98aecc8f8b/pefile-2024.8.26-py3-none-any.whl', 74766, '76f8b485dcd3b1bb8166f1128d395fa3d87af26360c2358fb75b80019b957c6f'),
    @('cmake-4.4.3-py3-none-win_amd64.whl', 'https://files.pythonhosted.org/packages/90/8c/e872d51e4cc7cd3fc159bd273baf5faab2de5a4f290e2728d14d551e0029/cmake-4.4.3-py3-none-win_amd64.whl', 42324327, '708ad6b662ee89d3eb2eac02a1afba20ca653139cbe769fed046124d0c6bc050'),
    @('pybind11-3.1.0-py3-none-any.whl', 'https://files.pythonhosted.org/packages/33/fd/8762f7ee3e4e4be6d1d846cffb4916dd9bb02b2f800d3603718a0efe494c/pybind11-3.1.0-py3-none-any.whl', 319402, 'b8488090f8acffbcb6b5d6a85571a6827a0a2981ffb75e5a0b27b87c4a6b7dd0')
)
foreach ($asset in $buildWheelAssets) {
    Get-PinnedUpstreamAsset -Uri $asset[1] -Sha256 $asset[3] -Size ([long]$asset[2]) -Destination (Join-Path $buildWheelCache $asset[0]) | Out-Null
}
Invoke-Checked $Uv @('pip', 'install', '--python', $buildPython, '--offline', '--no-index', '--find-links', $buildWheelCache, 'setuptools==80.9.0', 'Cython==3.1.4', 'wheel==0.45.1', 'delvewheel==1.11.2', 'pefile==2024.8.26', 'cmake==4.4.3', 'pybind11==3.1.0')
$cmake = Join-Path $buildVenv 'Scripts\cmake.exe'
$delvewheel = Join-Path $buildVenv 'Scripts\delvewheel.exe'
$verifier = Join-Path $PSScriptRoot 'verify-native-source-wheels.py'
if (-not (Test-Path -LiteralPath $verifier)) { $verifier = Join-Path $PSScriptRoot 'scripts\verify-native-source-wheels.py' }
$receiptPath = Join-Path $BuildRoot 'native-build-receipt.json'
if (Test-Path -LiteralPath $receiptPath -PathType Leaf) {
    $cachedReceipt = Get-Content -LiteralPath $receiptPath -Raw | ConvertFrom-Json
    if ($cachedReceipt.ffmpeg_source_sha256 -ne '464beb5e7bf0c311e68b45ae2f04e9cc2af88851abb4082231742a74d97b524c' -or
        $cachedReceipt.pyav_source_sha256 -ne '47bfc286e1bc9de7ab4681fc2b575cd2460a66919d31ffe1bd5aa54fae531a28' -or
        $cachedReceipt.onednn_commit -ne '64f6bcbcbab628e96f33a62c3e975f8535a7bde4' -or
        $cachedReceipt.ctranslate2_commit -ne 'd44d2d069eb88c7b7804da864c10c201501cb4a9' -or
        @($cachedReceipt.wheels).Count -ne 2 -or
        -not $cachedReceipt.PSObject.Properties['install_nvidia_gpu'] -or
        [bool]$cachedReceipt.install_nvidia_gpu -ne [bool]$InstallNvidiaGpu -or
        [string]$cachedReceipt.profile -ne $(if ($InstallNvidiaGpu) { 'nvidia' } else { 'cpu' })) {
        throw 'Cached native build receipt does not match the pinned source recipe.'
    }
    Restore-NativeWheelCache -BuildRoot $BuildRoot -Wheelhouse $Wheelhouse -Wheels @($cachedReceipt.wheels)
    $config = Join-Path $BuildRoot 'ffmpeg-config.mak'
    if ((Get-FileHash -LiteralPath $config -Algorithm SHA256).Hash.ToLowerInvariant() -ne [string]$cachedReceipt.ffmpeg_config_sha256) {
        throw 'Cached FFmpeg configuration differs from its build receipt.'
    }
    Invoke-Checked $buildPython @($verifier, $Wheelhouse, $config)
    Write-Host 'Reusing two verified wheels built from pinned source on this machine.'
    return
}
$ffmpegScript = Join-Path $PSScriptRoot 'build-v11-codec-free-ffmpeg.sh'
if (-not (Test-Path -LiteralPath $ffmpegScript)) { throw 'Codec-free FFmpeg build recipe is missing.' }
$env:MSYS2_PATH_TYPE = 'inherit'
$env:Path = (Split-Path -Parent $MsysBash) + ';' + $env:Path
$env:AUTOCLIP_BUILD_ROOT = Convert-ToMsysPath $BuildRoot
$env:AUTOCLIP_FFMPEG_SCRIPT = Convert-ToMsysPath $ffmpegScript
if (-not (Test-Path -LiteralPath (Join-Path $BuildRoot 'ffmpeg-install\bin\avcodec-62.dll'))) {
    Invoke-Checked $MsysBash @('-c', 'bash "$AUTOCLIP_FFMPEG_SCRIPT" "$AUTOCLIP_BUILD_ROOT"')
}
$ffmpegInstall = Join-Path $BuildRoot 'ffmpeg-install'

if (-not @(Get-ChildItem -LiteralPath $Wheelhouse -Filter 'av-18.1.0-*.whl').Count) {
    Push-Location $pyavSource
    try {
        Invoke-Checked $buildPython @('setup.py', 'bdist_wheel', "--ffmpeg-dir=$ffmpegInstall")
        $rawPyav = @(Get-ChildItem -LiteralPath (Join-Path $pyavSource 'dist') -Filter 'av-18.1.0-*.whl')
        if ($rawPyav.Count -ne 1) { throw 'Expected exactly one locally built PyAV wheel.' }
        Invoke-Checked $delvewheel @('repair', '--add-path', (Join-Path $ffmpegInstall 'bin'), '--wheel-dir', $Wheelhouse, $rawPyav[0].FullName)
    } finally { Pop-Location }
}

$oneDnnBuild = Join-Path $BuildRoot 'onednn-build'
$oneDnnInstall = Join-Path $BuildRoot 'onednn-install'
Invoke-Checked $cmake @('-S', $oneDnnSource, '-B', $oneDnnBuild, '-G', 'Visual Studio 17 2022', '-A', 'x64', '-DCMAKE_POLICY_VERSION_MINIMUM=3.5', '-DDNNL_LIBRARY_TYPE=STATIC', '-DDNNL_CPU_RUNTIME=SEQ', '-DDNNL_GPU_RUNTIME=NONE', '-DDNNL_BUILD_TESTS=OFF', '-DDNNL_BUILD_EXAMPLES=OFF', "-DPYTHON_EXECUTABLE=$(Convert-ToCmakePath $buildPython)", "-DCMAKE_INSTALL_PREFIX=$(Convert-ToCmakePath $oneDnnInstall)")
Invoke-Checked $cmake @('--build', $oneDnnBuild, '--config', 'Release', '--parallel', '8')
Invoke-Checked $cmake @('--install', $oneDnnBuild, '--config', 'Release')

$ct2Build = Join-Path $BuildRoot 'ctranslate2-build'
$ct2Install = Join-Path $BuildRoot 'ctranslate2-install'
$ct2Args = @('-S', $ct2Source, '-B', $ct2Build, '-G', 'Visual Studio 17 2022', '-A', 'x64', '-DCMAKE_POLICY_VERSION_MINIMUM=3.5', '-DWITH_CUDA=OFF', '-DWITH_OPENBLAS=ON', '-DOPENMP_RUNTIME=COMP', '-DWITH_MKL=OFF', '-DWITH_DNNL=ON', '-DWITH_RUY=OFF', '-DWITH_CUDNN=OFF', '-DWITH_FLASH_ATTN=OFF', "-DOPENBLAS_INCLUDE_DIR=$(Convert-ToCmakePath (Join-Path $openblasRoot 'include'))", "-DOPENBLAS_LIBRARY=$(Convert-ToCmakePath (Join-Path $openblasRoot 'lib\libopenblas.lib'))", "-DDNNL_INCLUDE_DIR=$(Convert-ToCmakePath (Join-Path $oneDnnInstall 'include'))", "-DDNNL_LIBRARY=$(Convert-ToCmakePath (Join-Path $oneDnnInstall 'lib\dnnl.lib'))", "-DCMAKE_INSTALL_PREFIX=$(Convert-ToCmakePath $ct2Install)")
if ($InstallNvidiaGpu) {
    $ct2Args = @($ct2Args | Where-Object { $_ -ne '-DWITH_CUDA=OFF' })
    $ct2Args += @('-DWITH_CUDA=ON', '-DCUDA_ARCH_LIST=Common', '-DCUDA_DYNAMIC_LOADING=ON', '-DCUDA_NVCC_FLAGS=-Xfatbin=-compress-all;-gencode;arch=compute_120,code=sm_120', "-DCUDA_TOOLKIT_ROOT_DIR=$(Convert-ToCmakePath $CudaRoot)")
}
Invoke-Checked $cmake $ct2Args
Invoke-Checked $cmake @('--build', $ct2Build, '--config', 'Release', '--parallel', '8')
Invoke-Checked $cmake @('--install', $ct2Build, '--config', 'Release')
$ct2Python = Join-Path $ct2Source 'python'
Copy-Item -LiteralPath (Join-Path $ct2Source 'README.md') -Destination (Join-Path $ct2Python 'README.md')
Copy-Item -LiteralPath (Join-Path $ct2Install 'bin\ctranslate2.dll') -Destination (Join-Path $ct2Python 'ctranslate2\ctranslate2.dll')
$env:CTRANSLATE2_ROOT = $ct2Install
Push-Location $ct2Python
try {
    Invoke-Checked $buildPython @('setup.py', 'bdist_wheel', '--dist-dir', $Wheelhouse)
} finally { Pop-Location }

$wheels = @(Get-ChildItem -LiteralPath $Wheelhouse -Filter '*.whl' | Where-Object { $_.Name -match '^(av-18\.1\.0|ctranslate2-4\.8\.2)-' })
if ($wheels.Count -ne 2) { throw 'Native source build did not produce both controlled wheels.' }
Invoke-Checked $buildPython @($verifier, $Wheelhouse, (Join-Path $BuildRoot 'ffmpeg-config.mak'))
$receipt = [ordered]@{
    profile = if ($InstallNvidiaGpu) { 'nvidia' } else { 'cpu' }
    built_at_utc = [DateTime]::UtcNow.ToString('o')
    ffmpeg_source_sha256 = '464beb5e7bf0c311e68b45ae2f04e9cc2af88851abb4082231742a74d97b524c'
    pyav_source_sha256 = '47bfc286e1bc9de7ab4681fc2b575cd2460a66919d31ffe1bd5aa54fae531a28'
    onednn_commit = '64f6bcbcbab628e96f33a62c3e975f8535a7bde4'
    ctranslate2_commit = 'd44d2d069eb88c7b7804da864c10c201501cb4a9'
    install_nvidia_gpu = [bool]$InstallNvidiaGpu
    cmake_arguments = @($ct2Args)
    build_prerequisites = [ordered]@{
        git = ((& git --version) | Out-String).Trim()
        cmake = ((& $cmake --version | Select-Object -First 1) | Out-String).Trim()
        nasm = ((& nasm -v) | Out-String).Trim()
        msvc = (Get-Item -LiteralPath (Get-Command cl.exe).Source).VersionInfo.ProductVersion
        msys2_packages = @($requiredMsysPackages | ForEach-Object { & $MsysBash -lc "pacman -Q $_" })
    }
    ffmpeg_config_sha256 = (Get-FileHash -LiteralPath (Join-Path $BuildRoot 'ffmpeg-config.mak') -Algorithm SHA256).Hash.ToLowerInvariant()
    wheels = @($wheels | ForEach-Object { [ordered]@{ filename = $_.Name; bytes = $_.Length; sha256 = (Get-FileHash -LiteralPath $_.FullName -Algorithm SHA256).Hash.ToLowerInvariant() } })
}
Save-NativeWheelCache -BuildRoot $BuildRoot -Wheelhouse $Wheelhouse -Wheels @($receipt.wheels)
$receipt | ConvertTo-Json -Depth 5 | Set-Content -LiteralPath (Join-Path $BuildRoot 'native-build-receipt.json') -Encoding UTF8
Write-Host "Built PyAV and CTranslate2 from pinned source in $Wheelhouse"
