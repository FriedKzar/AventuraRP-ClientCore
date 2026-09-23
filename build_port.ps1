param(
  [string]$WorkDir = "$PSScriptRoot\work",
  [string]$SkyMPCommit = "f926944b18e3aed4bc3864ce668626c05ec2545f"
)
$ErrorActionPreference = 'Stop'

function Need($cmd, $help) {
  if (-not (Get-Command $cmd -ErrorAction SilentlyContinue)) { throw "$cmd não encontrado. $help" }
}
Need git   'Instale Git for Windows.'
Need cmake 'Instale CMake.'
Need node  'Instale Node.js LTS.'

if (-not (Get-Command yarn -ErrorAction SilentlyContinue)) {
  if (Get-Command corepack -ErrorAction SilentlyContinue) {
    corepack enable
  }
}
Need yarn 'Ative o Corepack ou instale Yarn.'

New-Item -ItemType Directory -Force -Path $WorkDir | Out-Null
$repo = Join-Path $WorkDir 'skymp'
if (!(Test-Path $repo)) {
  git clone --recursive https://github.com/skyrim-multiplayer/skymp.git $repo
}
Push-Location $repo
try {
  git fetch --all --tags
  git checkout $SkyMPCommit
  git submodule update --init --recursive

  & "$PSScriptRoot\apply_port.ps1" -SkyMP $repo

  $build = Join-Path $repo 'build'
  if (Test-Path $build) { Remove-Item -Recurse -Force $build }
  New-Item -ItemType Directory -Force -Path $build | Out-Null

  # Build only the client-side platform. No Skyrim install is required for this compilation.
  cmake -S $repo -B $build -G "Visual Studio 17 2022" -A x64 `
    -DBUILD_UNIT_TESTS=OFF `
    -DBUILD_GAMEMODE=OFF `
    -DBUILD_FRONT=OFF `
    -DBUILD_CLIENT=OFF `
    -DBUILD_SKYRIM_PLATFORM=ON `
    -DBUILD_SCRIPTS=OFF `
    -DINSTALL_CLIENT_DIST=OFF `
    -DGENERATE_CLIENT_SETTINGS=OFF `
    -DPREPARE_NEXUS_ARCHIVES=OFF `
    -DOFFLINE_MODE=ON

  cmake --build $build --config Release --target skyrim-platform -- /m

  $dist = Join-Path $build 'dist\client'
  if (!(Test-Path $dist)) { throw "Build terminou, mas $dist não foi gerado." }
  $out = Join-Path $PSScriptRoot 'OUTPUT_ClientCore_1.7.104'
  if (Test-Path $out) { Remove-Item -Recurse -Force $out }
  Copy-Item -Recurse -Force $dist $out
  Write-Host "BUILD CONCLUÍDO: $out" -ForegroundColor Green
} finally {
  Pop-Location
}
