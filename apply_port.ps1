param(
  [string]$SkyMP = "$PSScriptRoot\skymp"
)

$ErrorActionPreference = 'Stop'

$overlay = Join-Path $PSScriptRoot 'overlay_ports\commonlibsse-ng-flatrim'
$target  = Join-Path $SkyMP 'overlay_ports\commonlibsse-ng-flatrim'

if (!(Test-Path (Join-Path $SkyMP 'CMakeLists.txt'))) {
    throw "SkyMP não encontrado em $SkyMP"
}

if (Test-Path $target) {
    Remove-Item -Recurse -Force $target
}

New-Item -ItemType Directory -Force -Path (Split-Path $target) | Out-Null
Copy-Item -Recurse -Force $overlay $target

Write-Host "Aventura RP CommonLib 7.5.4 aplicado." -ForegroundColor Green

# Compatibilidade com SimpleIni atual do vcpkg.
$platformCmake = Join-Path $SkyMP 'skyrim-platform\src\platform_se\CMakeLists.txt'

$content = Get-Content $platformCmake -Raw

$old = 'find_path(SIMPLEINI_INCLUDE_DIRS "ConvertUTF.c")'
$new = 'find_path(SIMPLEINI_INCLUDE_DIRS NAMES SimpleIni.h REQUIRED)'

if ($content.Contains($old)) {
    $content = $content.Replace($old, $new)
    Set-Content -Path $platformCmake -Value $content -Encoding UTF8 -NoNewline

    Write-Host "Aventura RP: SimpleIni atualizado para SimpleIni.h." -ForegroundColor Green
}
elseif ($content.Contains($new)) {
    Write-Host "Aventura RP: patch SimpleIni já aplicado." -ForegroundColor Yellow
}
else {
    throw "Não encontrei a linha esperada do SimpleIni em $platformCmake"
}
