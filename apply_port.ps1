param(
  [string]$SkyMP = "$PSScriptRoot\skymp"
)
$ErrorActionPreference = 'Stop'
$overlay = Join-Path $PSScriptRoot 'overlay_ports\commonlibsse-ng-flatrim'
$target  = Join-Path $SkyMP 'overlay_ports\commonlibsse-ng-flatrim'
if (!(Test-Path (Join-Path $SkyMP 'CMakeLists.txt'))) { throw "SkyMP não encontrado em $SkyMP" }
if (Test-Path $target) { Remove-Item -Recurse -Force $target }
New-Item -ItemType Directory -Force -Path (Split-Path $target) | Out-Null
Copy-Item -Recurse -Force $overlay $target
Write-Host "Aventura RP CommonLib 7.5.4 port aplicado em $target" -ForegroundColor Green
