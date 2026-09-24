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


# ============================================================
# 1. Compatibilidade com SimpleIni atual
# ============================================================

$platformCmake = Join-Path $SkyMP 'skyrim-platform\src\platform_se\CMakeLists.txt'

$content = Get-Content $platformCmake -Raw

$old = 'find_path(SIMPLEINI_INCLUDE_DIRS "ConvertUTF.c")'
$new = 'find_path(SIMPLEINI_INCLUDE_DIRS NAMES SimpleIni.h REQUIRED)'

if ($content.Contains($old)) {

    $content = $content.Replace($old, $new)

    Set-Content `
        -Path $platformCmake `
        -Value $content `
        -Encoding UTF8 `
        -NoNewline

    Write-Host "Aventura RP: SimpleIni atualizado para SimpleIni.h." -ForegroundColor Green
}
elseif ($content.Contains($new)) {

    Write-Host "Aventura RP: patch SimpleIni já aplicado." -ForegroundColor Yellow
}
else {

    throw "Não encontrei a linha esperada do SimpleIni em $platformCmake"
}


# ============================================================
# 2. TESQuestInitEvent
#
# CommonLibSSE-NG moderna já possui RE::TESQuestInitEvent.
# O SkyMP antigo mantinha uma cópia própria da struct.
# Removemos a definição duplicada.
# ============================================================

$eventsPath = Join-Path $SkyMP `
    'skyrim-platform\src\platform_se\skyrim_platform\game\Events.h'

$events = Get-Content $eventsPath -Raw

$oldQuestStruct = @'
struct TESQuestInitEvent
{
  RE::FormID questId;
};

'@

if ($events.Contains($oldQuestStruct)) {

    $events = $events.Replace($oldQuestStruct, '')

    Set-Content `
        -Path $eventsPath `
        -Value $events `
        -Encoding UTF8 `
        -NoNewline

    Write-Host "Aventura RP: TESQuestInitEvent duplicado removido." -ForegroundColor Green
}
else {

    Write-Host "Aventura RP: TESQuestInitEvent local já não está presente." -ForegroundColor Yellow
}


# ============================================================
# 3. CommonLib moderna chama o campo de formID,
#    enquanto o SkyMP antigo utilizava questId.
# ============================================================

$handlerPath = Join-Path $SkyMP `
    'skyrim-platform\src\platform_se\skyrim_platform\EventHandler.cpp'

$handler = Get-Content $handlerPath -Raw

$oldQuestAccess = @'
EventResult EventHandler::ProcessEvent(
  const RE::TESQuestInitEvent* event,
  RE::BSTEventSource<RE::TESQuestInitEvent>*)
{
  if (!event) {
    return EventResult::kContinue;
  }

  uint32_t questId = event->questId;
'@

$newQuestAccess = @'
EventResult EventHandler::ProcessEvent(
  const RE::TESQuestInitEvent* event,
  RE::BSTEventSource<RE::TESQuestInitEvent>*)
{
  if (!event) {
    return EventResult::kContinue;
  }

  uint32_t questId = event->formID;
'@

if ($handler.Contains($oldQuestAccess)) {

    $handler = $handler.Replace($oldQuestAccess, $newQuestAccess)

    Set-Content `
        -Path $handlerPath `
        -Value $handler `
        -Encoding UTF8 `
        -NoNewline

    Write-Host "Aventura RP: TESQuestInitEvent atualizado para formID." -ForegroundColor Green
}
elseif ($handler.Contains('uint32_t questId = event->formID;')) {

    Write-Host "Aventura RP: TESQuestInitEvent/formID já atualizado." -ForegroundColor Yellow
}
else {

    throw "Não encontrei o handler esperado de TESQuestInitEvent."
}


Write-Host ""
Write-Host "==========================================" -ForegroundColor Cyan
Write-Host " Aventura RP port 1.7.104 aplicado" -ForegroundColor Cyan
Write-Host "==========================================" -ForegroundColor Cyan
