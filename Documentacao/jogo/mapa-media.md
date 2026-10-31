# Mapa do `media/` — onde fica o quê

Índice de localização de `PZ/media/`. Responde "onde procuro X" e "qual é o exemplo canônico de X"
sem varredura. Alias `PZ/` = `C:\Program Files (x86)\Steam\steamapps\common\ProjectZomboid\`
(ver [../index.md](../index.md)). **Somente leitura.**

## Números

| Pasta | Arquivos | Observação |
|---|---|---|
| `media/lua` | 2.680 no total | 1.395 `.lua`, 1.248 `.json` (traduções), 37 outros |
| `media/scripts` | 1.004 | todos `.txt` |
| `media/AnimSets` | 2.949 | `.xml` de animação |
| `media/ui` | 1.538 | texturas de UI |
| `media/sound` | 686 | |

O grosso do trabalho de mod está em `lua/` e `scripts/`. `AnimSets/` só importa para mod de animação.

## `media/lua` — as três raízes

Só existem três pastas: `client/`, `server/`, `shared/`. Elas não são sugestão de organização — o
motor as trata de forma diferente em multiplayer:

| Raiz | `.lua` | Roda em |
|---|---|---|
| `client/` | 728 | só no cliente — UI, input, render, menu de contexto |
| `server/` | 294 | só no servidor (e no host do singleplayer) — mundo, spawn, lógica autoritativa |
| `shared/` | 373 | ambos — definições, utilidades, TimedActions, traduções |

Um mod que só mexe em item/receita muitas vezes não precisa de `.lua` nenhum.

### `client/` — as pastas que importam

| Pasta | `.lua` | O que tem |
|---|---|---|
| `ISUI/` | 265 | **toda a UI do jogo.** Base de qualquer janela/botão/painel de mod |
| `DebugUIs/` | 152 | painéis de debug; útil como exemplo de UI complexa, não como código de produção |
| `Entity/` | 62 | UI e lógica cliente do sistema de entidades do B42 (bancadas, fornos) |
| `OptionScreens/` | 51 | telas de opção, criação de personagem |
| `Vehicles/` | 29 | UI de veículo |
| `RadioCom/` | 28 | rádio/TV |
| `TimedActions/` | 24 | ações temporizadas do lado cliente |
| `PZAPI/` | 20 | **API oficial para mods** — `ModOptions.lua` é o jeito suportado de dar opções ao seu mod |
| `Foraging/` | 11 | **só UI** da busca — janela, ícones, display de zona. Ver [coleta-foraging.md](coleta-foraging.md) |
| `Context/` | 8 | menu de contexto |

Restante (`Camping`, `Chat`, `Farming`, `Fishing`, `Fluids`, `Hotbar`, `JoyPad`, `LastStand`, `Map`,
`Mining`, `Moveables`, `Music`, `RainBarrel`, `RecordedMedia`, `Seasons`, `SurvivalGuide`, `Tests`,
`Traps`, `Tutorial`, `XpSystem`, `erosion`, `BuildingObjects`) tem 1–7 arquivos cada.

Solto na raiz: `ContextMenuCode.lua`, `ServerCommands.lua`, `gamepadBinding.lua`.

### `server/` — as pastas que importam

| Pasta | `.lua` | O que tem |
|---|---|---|
| `WorldGen/` | 133 | geração de **terreno** — bioma, estrada, veia de minério, prefab. **Não** tem loot |
| `BuildingObjects/` | 37 | construção |
| `Items/` | 31 | **pasta de dado gerado, não de lógica**: 13 arquivos são saída do TileZed ([tiles.md](tiles.md)) e 3 são a distribuição de loot ([distribuicao-loot.md](distribuicao-loot.md)) |
| `Map/` | 17 | zonas, salas |
| `Farming/` | 10 | plantio |

Solto na raiz: `ClientCommands.lua`, `ISBuildingBlueprintManager.lua`, `ISCoordConversion.lua`,
`ISObjectClickHandler.lua`, `TemplateReplacers.lua`, `TransactionProcessor.lua`,
`TutorialHelperFunctions.lua`.

`ClientCommands.lua` (server) e `ServerCommands.lua` (client) são o par que atende
`sendClientCommand`/`sendServerCommand` — o canal de comunicação cliente↔servidor de mod.

### `shared/` — as pastas que importam

| Pasta | Arquivos | O que tem |
|---|---|---|
| `TimedActions/` | 183 `.lua` | **maior pasta de `shared/`.** Toda ação com barra de progresso |
| `Definitions/` | 31 `.lua` | tabelas de definição declarativa (ver abaixo) |
| `Foraging/` | 30 `.lua` | motor + definições da busca, e uma **MODDING FAQ da IndieStone** em `forageSystem.lua:1-38`. Ver [coleta-foraging.md](coleta-foraging.md) |
| `Vehicles/` | 22 `.lua` | |
| `StashDescriptions/` | 11 `.lua` | anotações/mapas com marcação — o **dado** dos mapas anotados (`StashUtil.lua` monta a global `StashDescriptions`); o motor é Java. Ver [distribuicao-loot.md](distribuicao-loot.md), "O motor dos mapas anotados" |
| `Util/` | 9 `.lua` | helpers gerais |
| `Translate/` | 0 `.lua` | **só `.json`** — 29 idiomas. Ver [carregamento-de-mods.md](carregamento-de-mods.md) |

Arquivos soltos que valem conhecer:

- `PZ/media/lua/shared/luautils.lua` — utilidades usadas pelo jogo inteiro.
- `PZ/media/lua/shared/defines.lua` — constantes globais.
- `PZ/media/lua/shared/ISBaseObject.lua` — a classe base do esquema de OO em Lua do PZ
  (`ISBaseObject:derive("MinhaClasse")`). Toda UI e TimedAction herda daqui.
- `PZ/media/lua/shared/keyBinding.lua` — registro de teclas.
- `PZ/media/lua/shared/env.lua`, `ActionManager.lua`, `SpawnRegions.lua`,
  `VehicleZoneDefinition.lua`.

`PZ/media/lua/shared/Definitions/` é o padrão a copiar quando o mod precisa de configuração
declarativa em Lua: `AttachedWeaponDefinitions.lua`, `ClothingRecipesDefinitions.lua`,
`ContainerButtonIcons.lua`, `DamageModelDefinitions.lua`, `DefaultClothing.lua`,
`FitnessExercises.lua`, `MapSymbolDefinitions.lua`, `SmashedCarDefinitions.lua` e mais.

Os 13 arquivos, com o contrato de cada um, estão em [definitions-lua.md](definitions-lua.md). Duas
ressalvas que aquela página levanta e mudam o "padrão a copiar" acima: **a pasta não é gancho de
carregamento** (o que vale é o idioma da tabela, não o caminho — a maioria dos mods põe o arquivo
solto em `lua/shared/`), e **3 dos 13 usam `X = {}` cru**, que zera a entrada de um mod em vez de
somar.

### Sandbox

`PZ/media/lua/shared/Sandbox/` traz os presets como tabela Lua pura — `SandboxVars.lua` mais
`Apocalypse.lua`, `Extinction.lua`, `Outbreak.lua`, `Rising.lua`, `SixMonthsLater.lua`. Formato:
`return { Version = 6, Zombies = 4, ... }` (`PZ/media/lua/shared/Sandbox/Apocalypse.lua:1`).

## `media/scripts` — os `.txt`

Quatro pastas, nenhum `.txt` solto na raiz de `scripts/`:

| Pasta | Arquivos | O que tem |
|---|---|---|
| `generated/` | 753 | **quase tudo.** Itens, receitas, veículos, modelos, sons, fluidos |
| `entities/` | 183 | skins XUI das entidades, agrupadas por tema |
| `xui/` | 64 | configuração e skins base do sistema XUI |
| `ragdolls/` | 4 | |

### `generated/` — subpastas

| Caminho | Arquivos | Conteúdo |
|---|---|---|
| `generated/vehicles/` | 143 | um arquivo por veículo |
| `generated/recipes/` | 43 | receitas por tema (`recipes_carpentry.txt`, `recipes_cooking.txt`, …) |
| `generated/items/` | 15 | **um arquivo por `ItemType`** — ver abaixo |
| `generated/entities/` | 13 subpastas | definições `entity` de verdade (com `component`) |
| `generated/sounds/` | 10 | |
| `generated/characters/` | 2 | **traits e profissões** — `character_traits.txt` (97 blocos) e `character_professions.txt` (25). No B41 isso era Lua; ver [scripts-txt.md](scripts-txt.md) |
| `generated/physics/`, `weapons/`, `TEMPORARY_TESTING_new_items/` | 1 cada | |

`generated/items/` é o lugar mais importante do jogo para modding de item — o nome do arquivo é o
tipo: `alarmclock.txt`, `alarmclockclothing.txt`, `animal.txt`, `clothing.txt`, `container.txt`,
`drainable.txt`, `food.txt`, `key.txt`, `literature.txt`, `map.txt`, `moveable.txt`, `normal.txt`,
`radio.txt`, `weapon.txt`, `weaponpart.txt`.

Soltos em `generated/`: `evolvedrecipes.txt`, `fixing.txt`, `fluids.txt`, `fluids_Alcoholic.txt`,
`fluids_Beverages.txt`, `animations.txt`, `animations_meshes.txt`, `clocks.txt`, `energies.txt`,
`mannequins.txt`, `models_animals.txt`, `models_characters.txt`, `models_clothes.txt`,
`models_fish.txt`, `models_food.txt`, `models_isoobject.txt`.

### `entities/` — subpastas

`admin`, `agricultural`, `animals`, `appliances`, `barricades`, `blacksmith`, `fences_low`,
`furniture`, `misc`, `outdoors`, `stairs`, `walls`. Contêm sobretudo arquivos
`entity_*_xuiSkin.txt` — a *aparência* da entidade. A *definição* dela está em
`generated/entities/<tema>/`.

## Exemplo canônico por tipo de coisa

Tabela de atalho: quando precisar escrever algo de um tipo, copie a forma daqui.

| Preciso escrever | Exemplo canônico |
|---|---|
| item arma | `PZ/media/scripts/generated/items/weapon.txt:3` (`item SpadeHead`) |
| item comida | `PZ/media/scripts/generated/items/food.txt:3` (`item PanFriedVegetablesForged`) |
| item roupa | `PZ/media/scripts/generated/items/clothing.txt` |
| receita de craft | `PZ/media/scripts/generated/recipes/recipes_carving.txt:3` (`craftRecipe MakeStake`) |
| receita evolutiva | `PZ/media/scripts/generated/evolvedrecipes.txt:3` (`evolvedrecipe Soup`) |
| conserto de item | `PZ/media/scripts/generated/fixing.txt:3` (`fixing Fix Pistol`) |
| entidade / bancada | `PZ/media/scripts/generated/entities/admin/entity_piano.txt:3` |
| skin XUI de entidade | `PZ/media/scripts/entities/misc/entity_haybundles_xuiSkin.txt:3` |
| modelo 3D de item | `PZ/media/scripts/generated/models_weapons.txt:3` (`model SaucePan`) — objeto do mundo é `models_isoobject.txt:3` |
| som | `PZ/media/scripts/generated/sounds/` |
| veículo | `PZ/media/scripts/generated/vehicles/` |
| classe Lua com herança | `PZ/media/lua/shared/ISBaseObject.lua` |
| janela de UI | `PZ/media/lua/client/ISUI/ISCollapsableWindow.lua` |
| ação temporizada | `PZ/media/lua/shared/TimedActions/` |
| opção de mod | `PZ/media/lua/client/PZAPI/ModOptions.lua` |
| tradução | `PZ/media/lua/shared/Translate/EN/ItemName.json` |
| estrutura mínima de mod | `PZ/mods/examplemod/` |

## O que fica fora de `lua/` e `scripts/`

Vale saber que existem, para não procurar no lugar errado:

- **Animação** — `actiongroups/` (3.203 `.xml`, ver abaixo), `AnimSets/` (2.949 `.xml`),
  `animscript/`, `animstates/`, `anims_X/`, `animsold/`. A maior massa de `.xml` do jogo é
  `actiongroups/`, não `AnimSets/`; em terceiro vem `clothing/` (1.857).
- **Modelo 3D** — duas pastas, formatos diferentes: `models_X/` (3.935 malhas `.fbx`/`.x`/`.glb`, o
  que os mods usam) e `models/` (46 `.txt` que **não são script**: malha em formato-texto, cabeçalho
  `# Project Zomboid Mesh`). Ver [arte-e-modelos.md](arte-e-modelos.md).
- **Textura** — `textures/` (6.140 `.png`), `ui/`, `geomTextures/`, `lightmaps/`, `depthmaps/`. Os
  ícones de item do jogo **não** estão aí: moram em `texturepacks/UI2.pack` — ver
  [arte-e-modelos.md](arte-e-modelos.md).
- **Tile/mapa** — `*.tiles` (binário) + `*.tiles.txt` (texto, e **os pares não são completos**) na
  raiz de `media/`, mais `texturepacks/*.pack`, `maps/`, `heightmaps/`, `binmap/`. Ver
  [tiles.md](tiles.md).
- **Som** — `sound/`, `music/`, `radio/`.
- **Roupa/aparência** — `clothing/`, `hairStyles/`, `voiceStyles/`.
- **Tags válidas da Workshop** — `PZ/media/WorkshopTags.txt` (31 tags; a Steam rejeita fora da lista).
- **Exemplos oficiais de Lua** — `PZ/media/luaexamples/` (`ISTimer.lua`, `testtimed.lua`, `ui/`).

### `actiongroups/` — a máquina de estados de animação, uma pasta por ator

3.203 `.xml`, **só `.xml`**, em 28 subpastas de 1º nível — e a chave é que cada subpasta é um **ator**,
não uma categoria: 21 de animal (`buck`, `doe`, `fawn`, `cow`, `cowcalf`, `ewe`, `ram`, `lamb`, `pig`,
`piglet`, `hen`, `chick`, `cockerel`, `turkey`, `turkeypoult`, `rabbit`, `rabkitten`, `mouse`, `rat`,
`raccoon`, `deerdead`), mais `player`, `player-avatar`, `player-editor`, `player-vehicle`, `zombie`,
`zombie-crawler` e `animal-editor`. É a maior massa de dado de animal do jogo — ver
[animais.md](animais.md).

Dentro de cada ator, um `actionGroup.xml` declara o estado inicial, um `defaultTransitions.xml` traz
as transições globais, e cada estado é uma pasta com o próprio `.xml` mais um `to_<destino>.xml` por
saída. A condição é declarativa (`PZ/media/actiongroups/buck/defaultTransitions.xml:2-14`):

```xml
<transition>
    <transitionTo>falldown</transitionTo>
    <conditions>
        <isTrue>bDead</isTrue>
        <isFalse>bOnFloor</isFalse>
    </conditions>
</transition>
```

**Zero referência a `actiongroups` em todo o `media/lua`** — o consumo é Java, como o do `AnimSets/`.

### As outras duas pastas não mapeadas

- **`media/basement_access/`** — 147 `.pzby`, nada além disso. Mesma extensão de `binmap/` (365
  `.pzby`), o que a coloca como dado binário de mapa e não como sistema próprio. Também sem nenhuma
  citação em `media/lua` — **mas o sistema que a consome tem entrada em Lua**:
  `Basements.getAPIv1():registerBasementSpawnLocation(...)`, chamado a partir do `objects.lua` de um
  mapa (`lua/server/metazones/metazoneHandler.lua:10-12`), com a API em
  `lua/shared/ProceduralBasements/`. Ver [mapas-e-zonas.md](mapas-e-zonas.md).
- **`media/newuitests/`** — **um** arquivo, `ClothingIcons_Torso.png`. Resíduo de teste de UI, sem
  citação em `media/lua`. Não é área.

### Arquivos soltos na raiz de `media/`

Fora dos `.tiles`/`.tiles.txt` (ver [tiles.md](tiles.md)) e das fontes (`.fnt` + `.png` de atlas),
sobram 10 arquivos na raiz. Metade deles é **script de bloco numa segunda família de sintaxe**, que
não é a de `media/scripts`:

| Arquivo | Tamanho | O que é |
|---|---|---|
| `tileGeometry.txt` | 6,1 MB | geometria por tile (`box`, …) — bloco `tileGeometry` |
| `tileDepthTextureAssignments.txt` | 1,7 MB | tile → textura de profundidade; mapa **plano** `chave = valor` |
| `seating.txt` | 220 KB | pontos de assento por tile — bloco `seating` |
| `spriteModels.txt` | 76 KB | tile → modelo 3D, via `modelScript` (232 ocorrências) — bloco `spriteModel` |
| `seams.txt` | 52 KB | costura de telhado por tile — bloco `seams` |
| `Bob_Sprint.txt` | 200 KB | **não é script**: malha animada em texto, `# Project Zomboid Animated Mesh` |
| `gamecontrollerdb.txt` | 580 KB | banco SDL de gamepads, de terceiro (`SDL_GameControllerDB`) |
| `WorkshopTags.txt` | 1 KB | as 31 tags, uma por linha |
| `fileGuidTable.xml` | 248 KB | caminho de arquivo → GUID, para os `.xml` de `clothing/` |
| `SpritePaddingSettings.xml` | 4 KB | parâmetros de render (padding de sprite por nível de zoom) |

**A segunda família de sintaxe.** `tileGeometry`, `seating`, `seams` e `spriteModels` compartilham
uma forma que **não existe em `media/scripts`** — sem `module`, com `VERSION`, e indexada por
tileset + coordenada em vez de por nome:

```
spriteModel
{
    VERSION = 1,

    tileset
    {
        name = appliances_radio_01,

        tile
        {
            xy = 0 0,
            modelScript = Base.RadioBlack_Ground,
```

(`PZ/media/spriteModels.txt:1-14`.) O contrato dela está em [tiles.md](tiles.md); o ponto aqui é que
**o censo de blocos de [scripts-txt.md](scripts-txt.md) não a cobre**, por escopo — aquele arquivo
documenta `media/scripts`. Note em `spriteModels.txt` a ponte entre os dois mundos: `modelScript`
aponta para um bloco `model` de `media/scripts` (`Base.RadioBlack_Ground`), que é o que liga um tile
do mapa a uma malha 3D — ver [arte-e-modelos.md](arte-e-modelos.md).

**Arquivo-raiz não é só na raiz de `media/`.** A família que o PZ-API-Docs indica inclui `MapInfo`, e
ele existe: `map.info` aparece uma vez por cidade em `PZ/media/maps/<Cidade>/map.info` (11 no build
atual). O padrão real é "arquivo de nome fixo na raiz de um escopo" — `media/` para os de cima,
a pasta do mapa para `map.info`, a pasta do mod para `mod.info` e `media/sandbox-options.txt` (ver
[sandbox-options.md](sandbox-options.md)).

## Pontos a confirmar

- A ordem de carregamento dentro de cada raiz de `lua/` parece ser alfabética — o arquivo
  `PZ/media/lua/shared/a_requires.lua` tem prefixo `a_` justamente para carregar primeiro, e o
  próprio comentário na linha 1 diz "Not sure what a_requires.lua is for". Não confirmado no motor.
- **`Blends`: resolvido — não é arquivo-raiz, é elemento XML.** `<Blends>` existe em
  `media/animstates/testanimstates.xml:2` e `testanimstates2.xml:2`, contendo as curvas de suavização
  das variáveis de animação (`MoveDelta`, `DeltaX`, `DeltaY`, `TurnAmount`). A busca anterior deu
  zero porque procurava **nome de arquivo**, e o nome nunca foi de arquivo. Ver
  [animacao.md](animacao.md).

  **`Rules` continua sem casamento** — zero ocorrências, inclusive em `animstates/`. Para ele a
  hipótese de legado B41 no índice da fonte segue de pé, e a busca não tem mais para onde ir sem o
  parser do Java. (`MapInfo` fechou como `maps/<Cidade>/map.info` e `SandboxOptions` como
  `media/sandbox-options.txt`.) Ver [fontes-externas.md](../fontes-externas.md), que já registra
  cobertura irregular do índice — e note que **a fonte listou como arquivo-raiz algo que é elemento
  XML**, o que é um modo de erro novo dela, não só cobertura faltando.
- **Se um mod pode substituir arquivo-raiz de `media/`.** Duas metades já fecharam: `sandbox-options.txt`
  é lido da pasta do mod, e os arquivos-satélite de tile **somam, não substituem** — ver
  [tiles.md](tiles.md), que traz a evidência. Continua aberto se a **substituição** é possível para
  algum nome de raiz, e por qual mecanismo a soma acontece.
- **O bloco `tileGeometry` do PZ-API-Docs vs o arquivo `tileGeometry.txt`.** Nomes iguais, mas a
  fonte lista o bloco no índice de `scripts`, e o arquivo está na raiz de `media/` com a sintaxe da
  segunda família. Se são o mesmo parser, não foi cruzado — ver
  [fontes-externas.md](../fontes-externas.md).

> Última verificação: 2026-08-07 — PZ buildid 24574865 (branch public, atualizado 2026-08-07), media/.
