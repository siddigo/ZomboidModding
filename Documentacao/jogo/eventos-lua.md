# Eventos Lua e pontos de hook

Como um mod se enxerta no jogo. O motor é Java; o Lua se conecta a ele registrando callbacks em
`Events.<Nome>.Add(funcao)`. Não existe assinatura publicada — o que segue foi levantado do uso real
em `PZ/media/lua` (1.395 arquivos `.lua`).

Alias `PZ/` = `C:\Program Files (x86)\Steam\steamapps\common\ProjectZomboid\`.

## O padrão de registro

```lua
local function minhaFuncao()
    -- ...
end

Events.OnGameStart.Add(minhaFuncao)
```

Canônico: `PZ/media/lua/client/Chat/ISChat.lua:1186`
(`Events.OnGameStart.Add(ISChat.createChat);`).

- **O registro roda no carregamento do arquivo**, não dentro de função. Fica no fim do `.lua`.
- **`.Remove(funcao)` desregistra** — `PZ/media/lua/client/DebugUIs/ISFastTeleportMove.lua:24`. Só
  funciona com a *mesma referência* de função; closure anônima registrada não pode ser removida.
- **A tabela `Events` é global e já existe** — não precisa de `require`.
- Ponto-e-vírgula final é opcional; o jogo usa os dois estilos no mesmo diretório.

**A assinatura de cada evento não está documentada em lugar nenhum.** O jeito de descobrir os
parâmetros é abrir um consumidor real do evento no `media/lua` e ler a função registrada. Toda spec
que use um evento deve citar `caminho:linha` de um consumidor.

### Assinaturas levantadas

Tabela incremental — só entra evento cujos parâmetros foram lidos num consumidor real. É **uso
observado**, não contrato declarado: nada impede o Java de passar argumento a mais que o consumidor
ignora.

| Evento | Parâmetros | Consumidor |
|---|---|---|
| `OnHitZombie` | `(zombie, wielder, bodyPart, weapon)` | `PZ/media/lua/shared/Definitions/DamageModelDefinitions.lua:24`, registrado em `:69` |
| `OnFillContainer` | `(roomType, containerType, container)` — **`container` nem sempre é `ItemContainer`** | `PZ/media/lua/server/Items/LootLog.lua:7`, registrado em `:34` |

`OnHitZombie` é o gancho de "efeito ao acertar com a arma X": o consumidor vanilla usa `weapon` para
escolher textura de dano e `zombie:addVisualDamage(...)` para aplicá-la. Um mod que queira efeito
próprio por arma filtra por `weapon:getType()` ali.

`OnFillContainer` é o caso que mostra o limite de "uso observado": o consumidor vanilla trata o 3º
argumento como `ItemContainer` e chama `getItems()` nele, mas em 3 dos 10 disparos o Java passa a
**definição** de distribuição, que não tem esse método — e a chamada estoura. O consumidor não
denuncia porque está atrás de um gate desligado. Contrato completo, com a guarda `instanceof`, em
[distribuicao-loot.md](distribuicao-loot.md) → "`OnFillContainer` — o gancho por contêiner".

## Os eventos que servem de ponto de entrada de mod

Ordem aproximada do ciclo de vida, do mais cedo ao mais tarde:

| Evento | Quando | Uso típico em mod |
|---|---|---|
| `OnGameBoot` | jogo abriu, antes do menu | ajustar o que os `.txt` já carregaram — **não** registrar trait/profissão (ver abaixo) |
| `OnMainMenuEnter` | menu principal | |
| `OnInitWorld` | mundo montado | |
| `OnInitGlobalModData` | ModData pronta | criar/ler a tabela persistente do mod; reescrever receita (ver abaixo) |
| `OnNewGame` | partida nova criada | estado inicial do mundo |
| `OnGameStart` | partida carregada, jogador existe | **o gancho mais usado** — UI, keybind, init geral |
| `OnCreatePlayer` | jogador instanciado | |
| `OnPlayerUpdate` / `OnTick` | todo frame/tick | evitar; custo alto |
| `EveryOneMinute`, `EveryTenMinutes`, `EveryHours`, `EveryDays` | tempo de jogo | tarefa periódica barata |
| `OnPostSave` | após salvar | |
| `OnPlayerDeath` | | |
| `OnResetLua` | Lua recarregada | limpar estado global |

**`OnInitWorld` → `OnInitGlobalModData` → `OnNewGame` é ordem medida, não inferida**
`[levantado 2026-11-01]`: os três disparam dentro de `zombie.iso.IsoWorld.init()` (bytecode de
`projectzomboid.jar`, `javap -c`), nos offsets 2102 (`OnInitWorld`), 2820 (`GlobalModData.instance.init()`,
que é quem chama `triggerEvent("OnInitGlobalModData", …)`) e 4673/5492 (`OnNewGame`). Entre os dois
últimos, no offset 2926/2932, vêm `WorldDictionary.init()` e `ScriptManager.PostWorldDictionaryInit()` —
o passo que resolve os itens de cada linha de receita. Por isso receita reescrita em
`OnInitWorld`/`OnInitGlobalModData` tem as linhas novas resolvidas pelo motor; depois disso, nada
foi visto re-resolvendo (a confirmar, ver pendências) (ver [scripts-txt.md](scripts-txt.md), "Reescrever a receita em runtime").

### `OnGameStart` tem duas armadilhas que não aparecem em singleplayer

A tabela acima descreve o ciclo do **cliente**. Duas coisas quebram fora dele, e as duas falham em
silêncio — sem erro, sem log, só o mod não fazendo nada:

**1. Em servidor dedicado `OnGameStart` nunca dispara.** A string `OnGameStart` aparece em duas
classes do `.jar`: `zombie.Lua.LuaEventManager` (o registro do evento) e `zombie.gameStates.IngameState`
(o único disparo). `IngameState` é **estado de cliente** — `zombie.network.GameServer` não a instancia
e não dispara o evento. Os eventos que o `GameServer` de fato dispara são só cinco:

| Evento | Também no cliente? |
|---|---|
| `OnGameBoot` | sim (`Core`, `GameWindow`, `IngameState`) |
| `OnGameTimeLoaded` | sim (`GameLoadingState`, e `ConnectedPacket` no cliente MP) |
| `OnServerStarted` | não — só servidor |
| `OnClientCommand` | não — é o canal de comando |
| `OnReceiveItemListNet` | — |

Ou seja: **init de mod pendurado em `OnGameStart` simplesmente não roda em servidor dedicado.** Para
init que precisa valer nos dois lados, o par é `OnGameBoot` (antes do mundo) e `OnGameTimeLoaded`
(save carregado).

**2. Mesmo no cliente, ele dispara DEPOIS do primeiro preenchimento de contêiner.** Dentro de
`IngameState.enter()`, na ordem do bytecode:

| Offset | O que acontece |
|---|---|
| 92 | `IsoChunkMap.processAllLoadGridSquare()` — carrega os chunks iniciais, e é daí que sai a cadeia `fillContainer` → `OnFillContainer` |
| 199 | `triggerEvent("OnGameStart")` |
| 205 | `triggerEvent("OnLoad")` |

Consequência para mod de loot: **todo contêiner no raio de chunks do spawn é preenchido antes de o
`OnGameStart` do mod rodar.** Um mod que monta tabela/índice em `OnGameStart` e a consome em
`OnFillContainer` acerta os contêineres que o jogador encontrar depois, e erra justamente os
primeiros — o que in-game parece azar de sorteio, não bug. O refill de loot pelo menu de debug
mascara isso, porque re-dispara `OnFillContainer` muito depois.

**A saída não é trocar de evento, é não depender de ordem:** montar a estrutura na primeira
necessidade, memoizada, dentro do próprio handler. Vale igual em singleplayer, coop e dedicado.

`OnGameBoot` roda **antes** de existir jogador ou mundo. O jogo pendura 9 callbacks nele, em
`PZ/media/lua/shared/NPCs/MainCreationMethods.lua:6364-6372` (`DoTraits`, `DoProfessions`,
`DoSpawnPoint`, `DoObservations`, `DoSurname`, `DoFemaleForename`, `DoMaleForename`,
`DoTrouserColor`, `DoHairColor`).

**[mudou 42] Trait e profissão não se registram mais aqui.** No B41 o padrão era chamar
`TraitFactory.addTrait(...)` dentro de um callback de `OnGameBoot`. No B42 esse caminho está morto:
`TraitFactory.` e `ProfessionFactory.` têm **zero** ocorrências em todo o `PZ/media/lua`. As
definições passaram para `.txt`, nos blocos `character_trait_definition` e
`character_profession_definition` de `PZ/media/scripts/generated/characters/` — ver
[scripts-txt.md](scripts-txt.md).

O que `DoTraits` faz hoje é **só cosmético**: itera `CharacterTraitDefinition.getTraits()` — a lista
que o motor já montou a partir do `.txt` — e chama `SetTraitDescription` para concatenar os
`XPBoosts` na descrição que a UI mostra (`MainCreationMethods.lua:103-111`, e a montagem da string
em `:113-135`). `DoProfessions` é o espelho disso (`:155-165`). Ou seja: o gancho continua útil para
**mexer** numa definição existente, e é inútil para **criar** uma.

`ObservationFactory` sobreviveu e ainda cria de verdade em Lua (`MainCreationMethods.lua:137-153`) —
não generalize a morte do `TraitFactory` para todos os `*Factory`.

`OnGameStart` é o mais frequente de todos — 36 registros no `media/lua`.

## Menu de contexto

Os dois ganchos mais úteis para mod de interação:

| Evento | Alvo |
|---|---|
| `OnFillWorldObjectContextMenu` | clique direito em objeto do mundo |
| `OnFillInventoryObjectContextMenu` | clique direito em item do inventário |

Canônico: `PZ/media/lua/client/BuildingObjects/ISUI/ISInventoryBuildMenu.lua:123` e
`PZ/media/lua/client/DebugUIs/ISRemoveItemTool.lua:372`.

**O de objeto do mundo recebe `(player, context, worldobjects, test)`** — disparado em
`PZ/media/lua/client/ISUI/ISWorldObjectContextMenu.lua:213`, e `player` é o **índice** do jogador,
não o objeto. `[levantado 2026-09-30]` Quatro idiomas que o handler precisa:

- **`test` é a sondagem do controle**: quando vem `true`, não se monta menu — se houver o que
  acrescentar, devolve-se `ISWorldObjectContextMenu.setTest()` (`:122-128`, com o comentário do jogo).
- **`worldobjects` é o que foi clicado, não o que está no tile.** Para achar um objeto em cima de um
  móvel, percorra `getSquare():getObjects()` de cada um. Identificar o objeto por propriedade do
  sprite está em [tiles.md](tiles.md).
- **`context:addGetUpOption(text, target, onSelect, …)`**
  (`PZ/media/lua/client/ISUI/ISContextMenu.lua:1038`) é o `addOption` que levanta o personagem
  sentado antes; o callback recebe `target` e depois os extras.
- **Opção cinza com motivo**: `notAvailable = true` + `toolTip = ISWorldObjectContextMenu.addToolTip()`
  (`:2595`). O exemplo do jogo é também o idioma de "tem energia?" — gerador ao alcance **ou** rede
  ligada dentro de cômodo: `square:haveElectricity() or (square:hasGridPower() and square:getRoom())`
  (`:460-466`).

### O par `OnPreFill…`/`OnFill…` não é "cedo e tarde" — é antes e depois das opções do jogo

Os dois disparam na mesma função (`ISInventoryPaneContextMenu.createMenu`, `:26`), mas em pontos
opostos dela: `OnPreFillInventoryObjectContextMenu` em
`PZ/media/lua/client/ISUI/ISInventoryPaneContextMenu.lua:374` e
`OnFillInventoryObjectContextMenu` em `:935`. Entre os dois roda **todo o menu vanilla** — as
~560 linhas que criam as opções e decidem quais ficam cinza.

Para acrescentar opção, tanto faz. A diferença aparece quando o mod precisa **mudar o estado do
item antes que o jogo o inspecione**, porque várias opções são liberadas ou não conforme o item:

```lua
elseif not editable and tests.canBeWrite:isEmptyPages() then
    note.notAvailable = true;               -- ISInventoryPaneContextMenu.lua:584
```

Um mod que escreva a página do caderno em `OnFill…` chega tarde: a opção "Ler" já foi criada
desabilitada. Em `OnPreFill…` chega a tempo. O mesmo raciocínio vale para qualquer campo lido
dentro do bloco `tests`, montado em `:47-346`.

**O `items` do argumento não é uma lista de `InventoryItem`.** Ele mistura item solto com pilha
agrupada, e a pilha traz um primeiro elemento duplicado que precisa ser pulado. O jogo já dá o
achatador: `ISInventoryPane.getActualItems(items)`
(`PZ/media/lua/client/ISUI/ISInventoryPane.lua:908`). Iterar direto com `ipairs` pega objeto que
não é item e não avisa.

## Entrada do jogador

`OnKeyPressed` (35 registros), `OnKeyStartPressed`, `OnKeyKeepPressed`, `OnMouseDown`,
`OnMouseWheel`, `OnRightMouseDown`, `OnObjectLeftMouseButtonDown/Up`,
`OnObjectRightMouseButtonDown/Up`, `OnPressWalkTo`, `OnContextKey`.

Registro de tecla propriamente dito: `PZ/media/lua/shared/keyBinding.lua`.

## Comunicação cliente ↔ servidor

O par que faz mod funcionar em multiplayer:

- Cliente chama `sendClientCommand(player, "modulo", "comando", args)` —
  `PZ/media/lua/client/DebugUIs/BrushTool/FireBrushUI.lua:261`.
- Servidor recebe em `Events.OnClientCommand.Add(fn)` —
  `PZ/media/lua/server/Foraging/forageServer.lua:68`. O despachante geral do jogo está em
  `PZ/media/lua/server/ClientCommands.lua:1260`.
- Caminho inverso: `sendServerCommand` → `Events.OnServerCommand`, atendido do lado cliente em
  `PZ/media/lua/client/ServerCommands.lua`.

Esse é o motivo de a separação `client/` vs `server/` importar: código em `client/` não roda no
servidor dedicado, e vice-versa.

## Dados persistentes

`ModData.getOrCreate("chave")` devolve a tabela persistida do mod. Canônico:
`PZ/media/lua/client/Foraging/forageClient.lua:7`, com o init amarrado em
`Events.OnInitGlobalModData.Add(forageClient.init)` na linha 9 do mesmo arquivo.

Alternativa por objeto: `getGameTime():getModData()["chave"]` —
`PZ/media/lua/server/Seasons/season.lua:207`.

## Lista completa — 182 eventos

Levantados por varredura de `Events.<Nome>` em `PZ/media/lua`. **Isto é o que o jogo usa, não
necessariamente tudo que o motor expõe** — o registro real vive no Java (`LuaEventManager`), fora
do alcance de leitura aqui.

**O padrão precisa ser ancorado.** `Events\.[A-Za-z_]\w*` cru devolve **189** nomes distintos; os 7
excedentes (`font`, `selected`, `itemheight`, `doDrawItem`, `drawBorder`, `joypadParent`,
`onmousedown`) não são eventos — são campos de um objeto de lista chamado `pvpEvents`, todos no
mesmo arquivo (`PZ/media/lua/client/ISUI/AdminPanel/ISPVPLogToolUI.lua:18-24`), e o `Events.` casou
dentro de `pvpEvents.`. Exigindo que o `E` não venha precedido de `[A-Za-z0-9_]`, o censo dá 182 —
o número desta seção. Recontagem:

```sh
{ grep -rhoE "[^A-Za-z0-9_]Events\.[A-Za-z_][A-Za-z0-9_]*" media/lua --include=*.lua | sed 's/^.//'
  grep -rhoE "^Events\.[A-Za-z_][A-Za-z0-9_]*"             media/lua --include=*.lua
} | sed 's/Events\.//' | sort -u | wc -l
```

(`grep -P` não serve: o Git Bash do Windows responde *"-P supports only unibyte and UTF-8 locales"*
e devolve **0** sem falhar — resultado silenciosamente errado, do tipo que esta árvore existe para
evitar.)

Dois nomes em minúscula **sobrevivem** ao filtro e são eventos de verdade, ambos da UI de coleta:
`onEnableSearchMode` (`client/Foraging/ISSearchWindow.lua:314`, com `LuaEventManager.AddEvent`
próprio) e `onUpdateIcon` (`client/Foraging/ISSearchManager.lua:1528`, sem `AddEvent` no `media/` —
registro Java). Inicial minúscula não é critério de descarte.

<details>
<summary>Ciclo de vida, mundo e tempo</summary>

`OnGameBoot` `OnGameStart` `OnGameStateEnter` `OnGameTimeLoaded` `OnMainMenuEnter` `OnNewGame`
`OnInitWorld` `OnInitGlobalModData` `OnInitSeasons` `OnInitRecordedMedia` `OnCreatePlayer`
`OnCreateSurvivor` `OnPlayerUpdate` `OnPlayerMove` `OnPlayerDeath` `OnPlayerAttackFinished`
`OnTick` `OnRenderTick` `OnSleepingTick` `EveryOneMinute` `EveryTenMinutes` `EveryHours` `EveryDays`
`OnResetLua` `OnPostSave` `OnLoad` `OnLoadGridsquare`/`LoadGridsquare` `OnLoadMapZones`
`OnLoadedMapZones` `OnLoadSoundBanks` `OnLoadRadioScripts` `OnDistributionMerge`
`OnPreDistributionMerge` `OnPostDistributionMerge` `OnCGlobalObjectSystemInit`
`OnSGlobalObjectSystemInit` `OnClimateManagerInit` `OnClimateTickDebug` `OnModsModified`
`OnTemplateTextInit`
</details>

<details>
<summary>Interação, itens e crafting</summary>

`OnFillWorldObjectContextMenu` `OnFillInventoryObjectContextMenu` `OnFillContainer`
`OnContainerUpdate` `OnMakeItem` `OnItemFound` `OnDynamicMovableRecipe` `OnMovingObjectCrop`
`OnProcessAction` `OnProcessTransaction` `OnClothingUpdated` `OnEquipPrimary` `OnEquipSecondary`
`SetDragItem` `MngInvReceiveItems` `OnObjectAdded` `OnObjectAboutToBeRemoved`
`OnDestroyIsoThumpable` `OnDoTileBuilding2` `OnDoTileBuilding3` `OnMechanicActionDone`
`OnWaterAmountChange` `AddXP` `LevelPerk` `OnWeaponHitXp` `OnWeaponHitTree` `OnWeaponSwingHitPoint`
`OnHitZombie` `OnZombieDead` `OnDeadBodySpawn` `OnAnimalTracks` `OnClickedAnimalForContext`
`OnForagePool` `OnForageSpot` `OnForageRequestZone` `OnOverrideSearchManager` `onEnableSearchMode`
`OnPressRackButton` `OnPressReloadButton` `OnPressWalkTo` `OnDesignationZoneUpdatedNetwork`
</details>

<details>
<summary>Entrada, UI e joypad</summary>

`OnKeyPressed` `OnKeyStartPressed` `OnKeyKeepPressed` `OnMouseDown` `OnMouseWheel`
`OnRightMouseDown` `OnObjectLeftMouseButtonDown` `OnObjectLeftMouseButtonUp`
`OnObjectRightMouseButtonDown` `OnObjectRightMouseButtonUp` `OnContextKey` `OnPreUIDraw`
`OnPostUIDraw` `RenderOpaqueObjectsInWorld` `OnResolutionChange` `OnSetDefaultTab` `OnTabAdded`
`OnTabRemoved` `DoSpecialTooltip` `OnChatWindowInit` `SwitchChatStream` `OnAddMessage`
`OnAlertMessage` `OnAdminMessage` `OnDeviceText` `doDrawItem` `drawBorder` `font` `itemheight`
`joypadParent` `onmousedown` `onUpdateIcon` `selected` `OnGamepadConnect` `OnGamepadDisconnect`
`OnJoypadActivate` `OnJoypadActivateUI` `OnJoypadBeforeActivate`/`OnJoypadBeforeDeactivate`
`OnJoypadBeforeReactivate` `OnJoypadDeactivate` `OnJoypadReactivate` `OnJoypadRenderUI`
`OnJoypadDebugRenderUIOptionSet` `OptionGamepadBindingPresetChanged`
`OptionControllerButtonStyleChanged` `RefreshCheats`
</details>

<details>
<summary>Rede, servidor e Steam</summary>

`OnClientCommand` `OnServerCommand` `OnServerStarted` `OnServerStartSaving` `OnServerFinishSaving`
`OnConnected` `OnConnectFailed` `OnConnectionStateChanged` `OnDisconnect` `OnNetworkUsersReceived`
`OnReceiveUserlog` `OnRolesReceived` `OnSafehousesChanged` `OnScoreboardUpdate`
`OnMiniScoreboardUpdate` `OnChallengeQuery` `ServerPinged` `OnCoopJoinFailed` `OnCoopServerMessage`
`OnAcceptInvite` `AcceptedFactionInvite` `AcceptedSafehouseInvite` `AcceptedMedicalCheck`
`AcceptedTrade` `ReceiveFactionInvite` `ReceiveSafehouseInvite` `RequestMedicalCheck` `RequestTrade`
`SyncFaction` `TradingUIAddItem` `TradingUIRemoveItem` `TradingUIUpdateState` `ViewTickets`
`ViewBannedIPs` `ViewBannedSteamIDs` `OnGoogleAuthRequest` `OnQRReceived`
`OnSteamFriendStatusChanged` `OnSteamGameJoin` `OnSteamRefreshInternetServers`
`OnSteamRulesRefreshComplete` `OnSteamServerResponded` `OnSteamServerResponded2`
`OnSteamServerFailedToRespond2` `OnServerWorkshopItems` `OnSteamWorkshopItemCreated`
`OnSteamWorkshopItemNotCreated` `OnSteamWorkshopItemUpdated` `OnSteamWorkshopItemNotUpdated`
`OnFishingActionMPUpdate`
</details>

<details>
<summary>Veículo e clima</summary>

`OnEnterVehicle` `OnExitVehicle` `OnUseVehicle` `OnSwitchVehicleSeat` `OnVehicleHorn`
`OnVehicleDamageTexture` `OnSpawnVehicleStart` `OnThunderEvent` `OnWeatherPeriodStart`
`OnWeatherPeriodStage` `OnWeatherPeriodComplete` `OnWarUpdate`
</details>

### Não existe evento de dano em estrutura `[levantado 2026-11-01, javap no .jar]`

Zumbi batendo em porta, janela ou objeto construído não dispara evento Lua: `Thump` de
`zombie.iso.objects.IsoDoor`/`IsoWindow`/`IsoThumpable` só mexe na vida, toca som e, em porta e
thumpable, chama `sync()`. O único evento ligado a dano em estrutura é `OnWeaponHitThumpable`, cuja
string aparece em `IsoDoor`, `IsoWindow`, `IsoThumpable` e `IsoBarricade` — golpe de **arma do
jogador**, não de zumbi. Mod que precisa reagir à vida de estrutura faz varredura periódica
(`EveryOneMinute`) em volta do jogador.

`OnPostWallSquareDraw` e `OnPostTilesSquareDraw` estão declarados em `zombie.Lua.LuaEventManager`,
mas nenhuma outra classe do `.jar` contém a string: **são declarados e nunca disparados**. Registrar
neles não dá erro e não roda nada.

## Os 19 eventos que a lista dos 182 não enxerga

A lista acima foi montada varrendo `Events.<nome>`, e por construção ela só vê evento que **alguém
escuta**. Existe uma segunda população: nomes que o jogo **dispara** por `triggerEvent("<nome>")` e
que não aparecem em nenhum `Events.` de todo o `media/lua`.

O censo dos dois conjuntos:

```sh
cd "PZ/media"
grep -rhoE 'triggerEvent\("[A-Za-z_][A-Za-z0-9_]*"' lua/ | sed 's/triggerEvent("//;s/"//' | sort -u > trig.txt
grep -rhoE '[^A-Za-z0-9_]Events\.[A-Za-z_][A-Za-z0-9_]*' lua/ | sed 's/^.//;s/Events\.//' | sort -u > ev.txt
grep -rhoE '^Events\.[A-Za-z_][A-Za-z0-9_]*'            lua/ | sed 's/Events\.//'           | sort -u >> ev.txt
sort -u ev.txt -o ev.txt
comm -23 trig.txt ev.txt
```

São **34 nomes disparados**, **182 nomes escutados** (o segundo número confirma, por um caminho
independente, o total da seção anterior) e **19 disparados sem nenhum `Events.` correspondente**:

| Grupo | Nomes |
|---|---|
| Coleta | `preAddForageDefs` `preAddSkillDefs` `preAddCatDefs` `preAddZoneDefs` `preAddItemDefs` `onAddForageDefs` |
| Menu de contexto | `OnPreFillWorldObjectContextMenu` `OnPreFillInventoryObjectContextMenu` `OnFillInventoryContextMenuNoItems` `OnPreFillInventoryContextMenuNoItems` |
| Modo de busca | `onToggleSearchMode` `onDisableSearchMode` `onFillSearchIconContextMenu` |
| Tempo e clima | `OnDawn` `OnDusk` `OnChangeWeather` |
| Inventário | `OnRefreshInventoryWindowContainers` |
| Spawn | `OnSpawnRegionsLoaded` |
| Dev | `OnSourceWindowFileReload` |

Três coisas que isso muda:

- **A classe não é peculiaridade do foraging.** Aparece em seis subsistemas independentes, e inclui
  nomes que qualquer mod quereria — `OnDawn`, `OnDusk`, `OnChangeWeather` e os quatro `Pre*` de menu
  de contexto, que são exatamente os ganchos "antes de montar o menu".
- **O nome não distingue as duas classes.** Treze dos 19 seguem a convenção `On*` dos eventos
  registrados; só os do foraging e do modo de busca começam em minúscula. Não dá para olhar um nome
  e saber em qual população ele está.
- **Ausência da lista dos 182 não é ausência do evento.** Se você procurou um gancho e não achou,
  verifique aqui antes de concluir que ele não existe.

Se `Events.<nome>.Add(...)` funciona para esses 19 é a mesma pendência aberta em
[coleta-foraging.md](coleta-foraging.md), e ela vale para os 19 de uma vez.

**O censo é exato, não um piso.** Não há `triggerEvent('…')` com aspas simples (zero ocorrências), e
as únicas chamadas não-literais são `self:triggerEvent(…)` — que é outro mecanismo, ver abaixo.

## `self:triggerEvent` é um terceiro mecanismo, sem relação com `Events`

Fácil de confundir pelo nome, e a confusão custa caro porque as duas coisas não se comunicam. Além
do `Events.<Nome>.Add` global e do `triggerEvent("<Nome>")` global, existe um sistema de listener
**por objeto**, definido em `PZ/media/lua/shared/ISBaseObject.lua`:

- `ISBaseObject:addEventListener(_event, _callback, _target)` / `:removeEventListener(...)` (`:70`)
- `ISBaseObject:triggerEvent(_event, ...)` (`:80`)

O estado vive em `self.__eventListeners[_event]`, uma tabela do próprio objeto — nada é registrado
globalmente, e `Events.` não vê esses nomes nem o contrário. O `_event` sequer é string nos usos do
jogo: é **referência de função** usada como chave, por exemplo
`self:triggerEvent(ISCraftInputItems.updateContainers, self)`
(`client/Entity/ISUI/CraftRecipe/ISCraftInputItems.lua:17`).

**Limite de 12 parâmetros**, e ele avisa (`:83-85`):

```lua
local p = {...};
if p[13]~=nil then
    print("ISBaseObject.triggerEvent -> param overload");
end
```

O 13º argumento em diante é **descartado em silêncio** — o `print` é a única pista, e sai no log
comum, não como erro. É a UI de crafting do B42 que usa esse mecanismo; se você estende `ISBaseObject`
num mod, é este `triggerEvent` que você herda, não o global.

## Opções de mod — `PZAPI`

Para dar configuração ao seu mod, o caminho suportado é `PZ/media/lua/client/PZAPI/ModOptions.lua`,
não um menu próprio. É a única coisa em `media/lua` explicitamente nomeada como API para mods.

## Pontos a confirmar

- Assinatura (parâmetros) de cada evento — só se descobre lendo consumidor por consumidor. A tabela
  "Assinaturas levantadas" acima cobre **1 dos 182**; o resto segue aberto.
- Se `IsoZombie` aceita `setOnFire(true)`. Em `IsoAnimal` está confirmado
  (`PZ/media/lua/client/ISUI/Animal/ISAnimalContextMenu.lua:422`), e as duas classes descendem do
  mesmo `IsoGameCharacter` no Java, mas **não há chamada em zumbi no `media/lua`** — a extrapolação
  entre classes irmãs não é evidência. Importa para qualquer mod de arma incendiária via
  `OnHitZombie`.
- A lista definitiva de eventos do motor: `LuaEventManager` é Java, dentro de
  `PZ/projectzomboid.jar`, não lido aqui. Os 182 acima são os *usados* pelo jogo.
- Onde `OnGameBoot`, `OnMainMenuEnter` e `OnGameStart` caem em relação aos três de `IsoWorld.init()`
  — só `OnInitWorld` → `OnInitGlobalModData` → `OnNewGame` foi medido (ver logo após a tabela); o
  resto da tabela segue inferido do propósito de cada evento. Também a confirmar: se
  "reescrita em `OnGameStart` não resolve" se confirma in-game, ou se algo re-resolve depois.
- Se `Events.<nome>.Add(...)` funciona para os **19 eventos só-disparados** da seção acima. Vale para
  os 19 de uma vez e é a mesma pergunta aberta em [coleta-foraging.md](coleta-foraging.md).
- Quem escuta cada um dos 19 — a varredura prova que **ninguém no jogo** escuta, não o que o motor
  faz com o disparo. Pode ser gancho deixado para mod, pode ser código morto.
- **Se `LoadGridsquare` e `EveryOneMinute` disparam no servidor dedicado.** Indício forte, não
  medição: grep da string no `.jar` extraído (buildid 24909800, 2026-09-14) acha `"LoadGridsquare"` no
  constant pool de `IsoChunk`, `IsoChunkMap`, `WorldStreamer`, `LoadGridsquarePerformanceWorkaround`,
  `ErosionMain` e **`ServerMap$ServerCell`** — esta última só existe do lado servidor —, e
  `"EveryOneMinute"` em `zombie/GameTime.class`, o relógio do mundo. A string no constant pool não
  prova o `triggerEvent`. Único registro de `LoadGridsquare` em `PZ/media/lua`:
  `client/DebugUIs/DebugScenarios.lua:101`. *A confirmar in-game.*

> Última verificação: 2026-08-07 — PZ buildid 24574865 (branch public, atualizado 2026-08-07), media/.
