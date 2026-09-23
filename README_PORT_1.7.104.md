# Aventura RP — SkyrimPlatform port para Skyrim 1.7.104

## Por que este port existe

O SkyMP atual fixa uma CommonLibSSE-NG antiga (commit b93280e8, setembro de 2024). Essa versão classifica apenas Skyrim 1.6.x como AE. Skyrim 1.7.104 é interpretado incorretamente como SE, fazendo o SkyrimPlatformImpl.dll procurar `Data/SKSE/Plugins/version-1-7-104-0.bin`.

A Address Library atual para Skyrim 1.7.x usa `versionlib-1-7-104-0.bin` e formato binário 5. A CommonLib antiga não suporta esse formato. Portanto copiar/renomear o arquivo não é correção válida.

Este kit troca somente a CommonLib usada pela compilação do SkyrimPlatform por `alandtse/CommonLibSSE-NG v7.5.4` (commit `c5424463bba9af0d75cde8640ba7ddd4cacb9e39`). Essa linha contém:

- classificação de minor version >= 6 como AE, incluindo 1.7.104;
- Address Library format 5;
- ajustes de layout para Skyrim 1.7.x;
- compatibilidade anterior às grandes quebras de API da linha v8/v9.

## Patches preservados do SkyMP

O SkyrimPlatform depende de quatro acessos que o overlay oficial do SkyMP já expõe na CommonLib antiga. Este kit reaplica esses acessos sobre a 7.5.4 por uma etapa determinística de edição da fonte (`patch_source.cmake`):

1. `TESObjectREFR::MoveTo_Impl` público;
2. membros `BSScript::Variable::varType/value` públicos;
3. `StackFrame::args[0]` exposto;
4. internals de `ExtraDataList` usados pelo projeto públicos.

O patch de ExtraDataList foi adaptado; não replica as antigas alterações de destrutor, porque a CommonLib 7.5.4 já possui tratamento próprio para layouts SE/AE/VR.

## Build local

Requer Windows x64, Visual Studio 2022 com C++ Desktop, Git, CMake, Node.js/Corepack e espaço para vcpkg/dependências.

Abra PowerShell no diretório do kit e execute:

```powershell
Set-ExecutionPolicy -Scope Process Bypass
.\build_port.ps1
```

Saída esperada:

`OUTPUT_ClientCore_1.7.104\...`

O build precisa conter `SkyrimPlatform.dll` e `SkyrimPlatformImpl.dll` antes de entrar no Client Core do launcher.

## GitHub Actions

O arquivo `.github/workflows/build-skyrimplatform-1.7.104.yml` faz a mesma compilação em `windows-2022` e publica o client como artifact. Basta colocar o conteúdo deste kit em um repositório e executar o workflow manualmente.

## Critério para entrar no launcher

Não marque o core como compatível apenas porque compilou. Antes de substituir o Client Core do Aventura RP, testar em Skyrim 1.7.104 que:

- não aparece `failed to open address library file`;
- não aparece `Unsupported address library format: 5`;
- `SkyrimPlatformImpl.dll` carrega;
- `Data/Platform/Plugins/skymp5-client.js` é iniciado;
- o cliente chega à tentativa real de conexão com o servidor;
- o jogo permanece aberto após o handoff do SKSE.
