param(
  [string]$SkyMP = "$PSScriptRoot\skymp"
)

$ErrorActionPreference = 'Stop'

function Read-All([string]$Path) {
    return Get-Content -Path $Path -Raw
}

function Write-All([string]$Path, [string]$Content) {
    Set-Content -Path $Path -Value $Content -Encoding UTF8 -NoNewline
}

function Replace-Exact(
    [string]$Path,
    [string]$Old,
    [string]$New,
    [string]$Label
) {
    $content = Read-All $Path

    if ($content.Contains($New)) {
        Write-Host "Aventura RP: $Label ja aplicado." -ForegroundColor Yellow
        return
    }

    if (-not $content.Contains($Old)) {
        throw "Aventura RP: nao encontrei o trecho esperado para '$Label' em $Path"
    }

    $content = $content.Replace($Old, $New)
    Write-All $Path $content

    Write-Host "Aventura RP: $Label aplicado." -ForegroundColor Green
}


# ============================================================
# 0. Overlay CommonLibSSE-NG 7.5.4
# ============================================================

$overlay = Join-Path $PSScriptRoot 'overlay_ports\commonlibsse-ng-flatrim'
$target  = Join-Path $SkyMP 'overlay_ports\commonlibsse-ng-flatrim'

if (!(Test-Path (Join-Path $SkyMP 'CMakeLists.txt'))) {
    throw "SkyMP nao encontrado em $SkyMP"
}

if (!(Test-Path $overlay)) {
    throw "Overlay Aventura RP nao encontrado em $overlay"
}

if (Test-Path $target) {
    Remove-Item -Recurse -Force $target
}

New-Item -ItemType Directory -Force -Path (Split-Path $target) | Out-Null
Copy-Item -Recurse -Force $overlay $target

Write-Host "Aventura RP CommonLibSSE-NG 7.5.4 aplicado." -ForegroundColor Green


# ============================================================
# 1. SimpleIni
# ============================================================

$platformCmake = Join-Path $SkyMP `
    'skyrim-platform\src\platform_se\CMakeLists.txt'

Replace-Exact `
    -Path $platformCmake `
    -Old 'find_path(SIMPLEINI_INCLUDE_DIRS "ConvertUTF.c")' `
    -New 'find_path(SIMPLEINI_INCLUDE_DIRS NAMES SimpleIni.h REQUIRED)' `
    -Label 'SimpleIni atualizado para SimpleIni.h'


# ============================================================
# 2. TESQuestInitEvent
#
# A CommonLibSSE-NG atual ja possui RE::TESQuestInitEvent.
# O SkyrimPlatform antigo tambem declarava essa estrutura.
# Removemos a duplicacao e usamos formID.
# ============================================================

$eventsPath = Join-Path $SkyMP `
    'skyrim-platform\src\platform_se\skyrim_platform\game\Events.h'

$events = Read-All $eventsPath

$questStructPattern = `
    '(?ms)^struct TESQuestInitEvent\s*\{\s*RE::FormID questId;\s*\};\s*'

if ([regex]::IsMatch($events, $questStructPattern)) {

    $events = [regex]::Replace(
        $events,
        $questStructPattern,
        '',
        1
    )

    Write-All $eventsPath $events

    Write-Host `
        "Aventura RP: TESQuestInitEvent duplicado removido." `
        -ForegroundColor Green
}
else {

    Write-Host `
        "Aventura RP: TESQuestInitEvent local ja removido." `
        -ForegroundColor Yellow
}


$handlerCpp = Join-Path $SkyMP `
    'skyrim-platform\src\platform_se\skyrim_platform\EventHandler.cpp'

Replace-Exact `
    -Path $handlerCpp `
    -Old 'uint32_t questId = event->questId;' `
    -New 'uint32_t questId = event->formID;' `
    -Label 'TESQuestInitEvent atualizado para formID'


# ============================================================
# 3. PositionPlayerEvent / GetEventSource
#
# Em Skyrim 1.7.x PlayerCharacter possui offsets novos.
# Usamos o accessor versionado da CommonLib.
# ============================================================

$eventUtils = Join-Path $SkyMP `
    'skyrim-platform\src\platform_se\skyrim_platform\EventUtils.h'

$eventUtilsContent = Read-All $eventUtils


$oldSingleton = @'
template <class T, class E>
  requires SingletonSource<T, E>
inline RE::BSTEventSource<E>* GetEventSource()
{
  return T::GetSingleton();
}
'@

$newSingleton = @'
template <class T, class E>
  requires SingletonSource<T, E> && (!std::same_as<T, RE::PlayerCharacter>)
inline RE::BSTEventSource<E>* GetEventSource()
{
  return T::GetSingleton();
}
'@

if ($eventUtilsContent.Contains($oldSingleton)) {

    $eventUtilsContent =
        $eventUtilsContent.Replace(
            $oldSingleton,
            $newSingleton
        )
}
elseif (-not $eventUtilsContent.Contains($newSingleton)) {

    throw `
        "Aventura RP: nao encontrei o overload SingletonSource em EventUtils.h"
}


$oldPlayer = @'
#ifdef ENABLE_SKYRIM_AE
template <class T, class E>
  requires std::same_as<T, RE::PlayerCharacter>
inline RE::BSTEventSource<E>* GetEventSource()
{
  return nullptr;
}
#endif
'@

$newPlayer = @'
#ifdef ENABLE_SKYRIM_AE
template <class T, class E>
  requires std::same_as<T, RE::PlayerCharacter> &&
           std::same_as<E, RE::PositionPlayerEvent>
inline RE::BSTEventSource<E>* GetEventSource()
{
  auto* player = RE::PlayerCharacter::GetSingleton();

  return player
    ? player->AsPositionPlayerEventSource()
    : nullptr;
}
#endif
'@

if ($eventUtilsContent.Contains($oldPlayer)) {

    $eventUtilsContent =
        $eventUtilsContent.Replace(
            $oldPlayer,
            $newPlayer
        )
}
elseif (-not $eventUtilsContent.Contains($newPlayer)) {

    throw `
        "Aventura RP: nao encontrei o overload PlayerCharacter em EventUtils.h"
}


Write-All $eventUtils $eventUtilsContent

Write-Host `
    "Aventura RP: PositionPlayerEvent atualizado para accessor versionado." `
    -ForegroundColor Green


# ============================================================
# 4. MenuEventHandler para Skyrim 1.7.x
#
# Os Process* nao sao mais virtuais diretamente no
# MenuEventHandler multi-runtime.
#
# A CommonLib fornece MenuEventHandlerEx justamente para
# criar um vtable shim compativel com 1.7.x.
# ============================================================

$devApi = Join-Path $SkyMP `
    'skyrim-platform\src\platform_se\skyrim_platform\DevApi.cpp'


Replace-Exact `
    -Path $devApi `
    -Old 'class WrapperScreenShotEventHandler : public RE::MenuEventHandler' `
    -New 'class WrapperScreenShotEventHandler : public RE::MenuEventHandlerEx' `
    -Label 'WrapperScreenShotEventHandler migrado para MenuEventHandlerEx'


$devContent = Read-All $devApi


$oldHandlerCreate = @'
  RE::MenuEventHandler* handler =
    (RE::MenuEventHandler*)new WrapperScreenShotEventHandler(originalHandler);

  mc->RemoveHandler(originalHandler);
  mc->AddHandler(handler);
'@

$newHandlerCreate = @'
  auto* wrapper =
    new WrapperScreenShotEventHandler(originalHandler);

  RE::MenuEventHandler* handler =
    wrapper->Handler();

  mc->RemoveHandler(originalHandler);
  mc->AddHandler(handler);
'@


if ($devContent.Contains($oldHandlerCreate)) {

    $devContent =
        $devContent.Replace(
            $oldHandlerCreate,
            $newHandlerCreate
        )
}
elseif (-not $devContent.Contains($newHandlerCreate)) {

    throw `
        "Aventura RP: nao encontrei criacao do WrapperScreenShotEventHandler em DevApi.cpp"
}


Write-All $devApi $devContent

Write-Host `
    "Aventura RP: handler de screenshot adaptado ao vtable shim 1.7.x." `
    -ForegroundColor Green


# ============================================================
# 5. SkyrimVM
#
# Na CommonLib moderna o antigo:
#
# vm->impl
#
# passou para:
#
# vm->GetVMRuntimeData().impl
#
# O accessor aplica o offset correto para 1.7.104.
# ============================================================

$papyrus = Join-Path $SkyMP `
    'skyrim-platform\src\platform_se\skyrim_platform\PapyrusTESModPlatform.cpp'


$papyrusContent = Read-All $papyrus


$oldVmCheck = @'
  auto vm = RE::SkyrimVM::GetSingleton();
  if (!vm || !vm->impl) {
    return console->Print("VM was nullptr");
  }

  FunctionArguments args;
'@

$newVmCheck = @'
  auto vm = RE::SkyrimVM::GetSingleton();

  if (!vm) {
    return console->Print("VM was nullptr");
  }

  auto& vmRuntime =
    vm->GetVMRuntimeData();

  if (!vmRuntime.impl) {
    return console->Print(
      "VM implementation was nullptr");
  }

  FunctionArguments args;
'@


if ($papyrusContent.Contains($oldVmCheck)) {

    $papyrusContent =
        $papyrusContent.Replace(
            $oldVmCheck,
            $newVmCheck
        )
}
elseif (
    -not $papyrusContent.Contains(
        'auto& vmRuntime ='
    )
) {

    throw `
        "Aventura RP: nao encontrei verificacao antiga de SkyrimVM."
}


if (
    $papyrusContent.Contains(
        'vm->impl->DispatchStaticCall'
    )
) {

    $papyrusContent =
        $papyrusContent.Replace(
            'vm->impl->DispatchStaticCall',
            'vmRuntime.impl->DispatchStaticCall'
        )
}
elseif (
    -not $papyrusContent.Contains(
        'vmRuntime.impl->DispatchStaticCall'
    )
) {

    throw `
        "Aventura RP: nao encontrei DispatchStaticCall antigo de SkyrimVM."
}


Write-All $papyrus $papyrusContent

Write-Host `
    "Aventura RP: SkyrimVM migrado para GetVMRuntimeData().impl." `
    -ForegroundColor Green


# ============================================================
# 6. SKSE API
#
# SKSEAPI deixou de existir nessa versao da CommonLib.
# Em Windows x64 nao precisamos dele nesta funcao exportada.
# ============================================================

$mainCpp = Join-Path $SkyMP `
    'skyrim-platform\src\platform_se\skyrim_platform\main.cpp'


Replace-Exact `
    -Path $mainCpp `
    -Old 'DLLEXPORT bool SKSEAPI SKSEPlugin_Load_Impl(const SKSE::LoadInterface* skse)' `
    -New 'DLLEXPORT bool SKSEPlugin_Load_Impl(const SKSE::LoadInterface* skse)' `
    -Label 'SKSEPlugin_Load_Impl atualizado para API atual'


# ============================================================
# 7. MenuControls::screenshotHandler
#
# Na CommonLibSSE-NG atual screenshotHandler e um ponteiro cru.
# A versao antiga do SkyMP tentava chamar .get().
# ============================================================

$devApiContent = Read-All $devApi

$oldScreenshotHandler = @'
  RE::MenuEventHandler* originalHandler =
    (RE::MenuEventHandler*)mc->screenshotHandler.get();
'@

$newScreenshotHandler = @'
  RE::MenuEventHandler* originalHandler =
    (RE::MenuEventHandler*)mc->screenshotHandler;
'@

if ($devApiContent.Contains($oldScreenshotHandler)) {

    $devApiContent =
        $devApiContent.Replace(
            $oldScreenshotHandler,
            $newScreenshotHandler
        )

    Write-All $devApi $devApiContent

    Write-Host `
        "Aventura RP: screenshotHandler atualizado para ponteiro direto." `
        -ForegroundColor Green
}
elseif ($devApiContent.Contains($newScreenshotHandler)) {

    Write-Host `
        "Aventura RP: screenshotHandler ja atualizado." `
        -ForegroundColor Yellow
}
else {

    throw `
        "Aventura RP: nao encontrei screenshotHandler esperado em DevApi.cpp"
}


Write-Host ""
Write-Host `
    "======================================================" `
    -ForegroundColor Cyan

Write-Host `
    " Aventura RP - port SkyrimPlatform 1.7.104 aplicado" `
    -ForegroundColor Cyan

Write-Host `
    "======================================================" `
    -ForegroundColor Cyan
